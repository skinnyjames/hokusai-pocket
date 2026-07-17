#ifndef MRB_HTTP
#define MRB_HTTP

#include <tlsuv/http.h>
#include <tlsuv/tlsuv.h>
#include <uv.h>
#include <stddef.h>
#include "patch.h"
#include "http.h"
#include <pocket.h>
#include "../mruby-uv/migrate.h"

typedef struct MRB_HTTPContext
{
  mrb_state* omrb;
  mrb_state* mrb;
  mrb_value self;
  mrb_value res;
  mrb_value reciever;
  mrb_value on_response;
  uv_async_t* handle;
} mrb_http_context;

typedef struct MRB_HTTPWrapper
{
  mrb_state* mrb;
  tlsuv_http_t* http;
  mrb_value url;
  mrb_value reciever;
  uv_async_t* handle;
  mrb_http_context ctx;
} mrb_http_wrapper;

typedef struct {
    mrb_state *mrb;
    tlsuv_http_srv_t server;
    mrb_value on_request_proc;
    uv_async_t async_handle;
    struct RClass *conn_klass;
    mrb_bool bound;
    int closing_handles;
} mrb_http_srv_wrapper;

typedef struct {
    mrb_state *omrb;
    mrb_http_srv_wrapper *server_wrap;
    tlsuv_http_srv_conn_t *conn;
    char *method;
    char *path;
    char *body;
    size_t body_len;
} mrb_http_srv_event;

static void mrb_http_srv_tcp_closed(uv_handle_t *handle) {
    tlsuv_http_srv_t *srv = (tlsuv_http_srv_t*)handle->data; // set by tlsuv_http_srv_init
    mrb_http_srv_wrapper *wrapper =
        (mrb_http_srv_wrapper*)((char*)srv - offsetof(mrb_http_srv_wrapper, server));
    if (--wrapper->closing_handles == 0) free(wrapper);
}

static void mrb_http_srv_async_closed(uv_handle_t *handle) {
    // async_handle.data gets overwritten per-request with the current
    // event, so we can't use it here -- recover wrapper via its known
    // offset within the struct instead.
    mrb_http_srv_wrapper *wrapper =
        (mrb_http_srv_wrapper*)((char*)handle - offsetof(mrb_http_srv_wrapper, async_handle));
    if (--wrapper->closing_handles == 0) free(wrapper);
}

// Garbage collection free function for the Ruby Server object
static void mrb_http_srv_type_free(mrb_state *mrb, void *payload) {
    mrb_http_srv_wrapper *wrapper = (mrb_http_srv_wrapper*)payload;
    if (!wrapper) return;

    wrapper->closing_handles = 0;

    if (wrapper->bound && !uv_is_closing((uv_handle_t*)&wrapper->server.tcp)) {
        wrapper->closing_handles++;
        uv_close((uv_handle_t*)&wrapper->server.tcp, mrb_http_srv_tcp_closed);
    }
    if (wrapper->bound && wrapper->async_handle.loop && !uv_is_closing((uv_handle_t*)&wrapper->async_handle)) {
        wrapper->closing_handles++;
        uv_close((uv_handle_t*)&wrapper->async_handle, mrb_http_srv_async_closed);
    }

    // If the server was never bound, there are no live libuv handles to
    // wait on -- safe to free immediately.
    if (wrapper->closing_handles == 0) free(wrapper);
}

static struct mrb_data_type mrb_http_srv_type = { "Server", mrb_http_srv_type_free };

static mrb_http_srv_wrapper* mrb_http_srv_get(mrb_state *mrb, mrb_value self) {
    mrb_http_srv_wrapper *wrapper = (mrb_http_srv_wrapper*)DATA_PTR(self);
    if (!wrapper) mrb_raise(mrb, E_ARGUMENT_ERROR, "uninitialized HTTP server");
    return wrapper;
}

static void hp_server_async_cb(uv_async_t *handle) {
    mrb_http_srv_event *ev = (mrb_http_srv_event*)handle->data;
    mrb_state *mrb = ev->omrb;

    // 1. Wrap the connection context so Ruby can call response methods on it later
    //    (class looked up once at server init and cached on the wrapper, rather
    //    than re-defined on every single request)
    mrb_value ruby_conn = mrb_obj_new(mrb, ev->server_wrap->conn_klass, 0, NULL);
    DATA_PTR(ruby_conn) = ev->conn; // Anchor the raw connection instance point

    // 2. Convert incoming C buffers to native Ruby objects
    mrb_value r_method = mrb_str_new_cstr(mrb, ev->method);
    mrb_value r_path = mrb_str_new_cstr(mrb, ev->path);
    mrb_value r_body;
    if (ev->body_len <= 0)
    {
      r_body = mrb_nil_value();
    }
    else
    {
       r_body = mrb_str_new(mrb, ev->body, ev->body_len);
    }

    // 3. Dispatch directly to the block argument registered in your Ruby script
    mrb_funcall(mrb, ev->server_wrap->on_request_proc, "call", 4, ruby_conn, r_method, r_path, r_body);
    // Clean transaction allocations
    free(ev->method);
    free(ev->path);
    free(ev->body);
    free(ev);
}

// Fired on the background libuv worker loop when parsing finishes
static void on_server_request_received(tlsuv_http_srv_conn_t *conn, const char *method, const char *path, void *ctx) {
    mrb_http_srv_wrapper *wrapper = (mrb_http_srv_wrapper*)ctx;

    mrb_http_srv_event *ev = malloc(sizeof(mrb_http_srv_event));
    ev->omrb = wrapper->mrb;
    ev->server_wrap = wrapper;
    ev->conn = conn;
    ev->method = strdup(method);
    ev->path = strdup(path);

    size_t blen;
    const char *bdata = tlsuv_http_srv_get_body(conn, &blen);
    ev->body = malloc(blen + 1);
    memcpy(ev->body, bdata, blen);
    ev->body[blen] = '\0';
    ev->body_len = blen;

    wrapper->async_handle.data = ev;
    uv_async_send(&wrapper->async_handle);
}

/*
 * Server.new
 *
 * Allocates the server and its uv_tcp_t, but does not bind or listen yet.
 * Call #certificate (optional, for HTTPS) and #on_request before #bind.
 */
static mrb_value mrb_http_srv_init(mrb_state *mrb, mrb_value self) {
    struct RClass* hokusai_module = mrb_module_get(mrb, "Hokusai");
    mrb_value worker = mrb_funcall(mrb, mrb_obj_value(hokusai_module), "worker", 0, NULL);
    mrb_uv_loop_wrapper *loopwrapper = mrb_uv_loop_get(mrb, worker);
    if (!loopwrapper || !loopwrapper->loop) {
        mrb_raise(mrb, E_RUNTIME_ERROR, "Event loop not initialized");
    }

    mrb_http_srv_wrapper *wrapper = malloc(sizeof(mrb_http_srv_wrapper));
    wrapper->mrb = mrb;
    wrapper->on_request_proc = mrb_nil_value();
    wrapper->bound = FALSE;
    wrapper->closing_handles = 0;

    struct RClass *http = mrb_module_get_under(mrb, hokusai_module, "HTTP");
    wrapper->conn_klass = mrb_define_class_under(mrb, http, "Connection", mrb->object_class);

    tlsuv_http_srv_init(loopwrapper->loop, &wrapper->server);

    mrb_data_init(self, wrapper, &mrb_http_srv_type);
    return self;
}

// server.certificate(cert: "path/to.crt", key: "path/to.key") -- optional, for HTTPS
static mrb_value mrb_http_srv_certificate(mrb_state *mrb, mrb_value self) {
    mrb_value opts;
    mrb_get_args(mrb, "H", &opts);

    mrb_http_srv_wrapper *wrapper = mrb_http_srv_get(mrb, self);
    if (wrapper->bound) mrb_raise(mrb, E_RUNTIME_ERROR, "certificate must be set before bind");

    mrb_value cert_v = mrb_hash_get(mrb, opts, mrb_symbol_value(mrb_intern_lit(mrb, "cert")));
    mrb_value key_v = mrb_hash_get(mrb, opts, mrb_symbol_value(mrb_intern_lit(mrb, "key")));
    if (mrb_nil_p(cert_v) || mrb_nil_p(key_v)) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "certificate requires :cert and :key paths");
    }

    char *cert_path = mrb_str_to_cstr(mrb, cert_v);
    char *key_path = mrb_str_to_cstr(mrb, key_v);

    int rc = tlsuv_http_srv_set_cert(&wrapper->server, cert_path, key_path);
    if (rc != 0) mrb_raise(mrb, E_RUNTIME_ERROR, "failed to load certificate/key");

    return self;
}

// server.on_request { |conn, method, path, body| ... }
static mrb_value mrb_http_srv_on_request(mrb_state *mrb, mrb_value self) {
    mrb_value block;
    mrb_get_args(mrb, "&", &block);
    if (mrb_nil_p(block)) mrb_raise(mrb, E_ARGUMENT_ERROR, "on_request requires a block");

    mrb_http_srv_wrapper *wrapper = mrb_http_srv_get(mrb, self);
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@on_request_proc"), block);

    wrapper->on_request_proc = block;

    // GC root: `block` only exists inside a malloc'd C struct otherwise,
    // which the collector can't see. Stashing it as an ivar keeps it alive
    // for as long as the server object itself is reachable. Without this,
    // on_request_proc is a dangling mrb_value waiting to be collected out
    // from under hp_server_async_cb's mrb_yield_argv call.

    return mrb_nil_value();
}

// server.bind(port) -- starts listening; requires #on_request to have been called first
static mrb_value mrb_http_srv_bind_method(mrb_state *mrb, mrb_value self) {
    mrb_int port;
    mrb_get_args(mrb, "i", &port);

    mrb_http_srv_wrapper *wrapper = mrb_http_srv_get(mrb, self);
    if (wrapper->bound) mrb_raise(mrb, E_RUNTIME_ERROR, "server is already bound");
    if (mrb_nil_p(wrapper->on_request_proc)) mrb_raise(mrb, E_RUNTIME_ERROR, "call on_request before bind");

    struct RClass* hokusai_module = mrb_module_get(mrb, "Hokusai");
    mrb_value worker = mrb_funcall(mrb, mrb_obj_value(hokusai_module), "worker", 0, NULL);
    mrb_uv_loop_wrapper *loopwrapper = mrb_uv_loop_get(mrb, worker);

    int rc = tlsuv_http_srv_bind(&wrapper->server, "0.0.0.0", (int)port);
    if (rc) mrb_raisef(mrb, E_RUNTIME_ERROR, "tlsuv_http_srv_bind failed: %S", mrb_str_new_cstr(mrb, uv_strerror(rc)));

    uv_async_init(loopwrapper->loop, &wrapper->async_handle, hp_server_async_cb);
    tlsuv_http_srv_listen(&wrapper->server, on_server_request_received, wrapper);

    wrapper->bound = TRUE;
    return self;
}

// conn.respond(status_code, status_message, body_string)
mrb_value mrb_http_srv_conn_respond(mrb_state *mrb, mrb_value self) {
    mrb_int status;
    char *msg;
    char *body;
    mrb_int msg_len;
    mrb_int body_len;
    mrb_get_args(mrb, "iss", &status, &msg, &msg_len, &body, &body_len);

    tlsuv_http_srv_conn_t *conn = (tlsuv_http_srv_conn_t*)DATA_PTR(self);
    if (conn) {
        tlsuv_http_srv_respond(conn, (int)status, msg, body, (size_t)body_len);
    }
    return mrb_nil_value();
}


mrb_http_wrapper* mrb_http_req_get(mrb_state* mrb, mrb_value self);

static uv_mutex_t am;
static void mrb_http_req_type_free(mrb_state* mrb, void* payload)
{
  mrb_http_wrapper* wrapper = (mrb_http_wrapper*) payload;
  // tlsuv_http_close(&wrapper->http, NULL);
  free(payload);
}

static struct mrb_data_type mrb_http_req_type = { "Request", mrb_http_req_type_free };

mrb_http_wrapper* mrb_http_req_get(mrb_state* mrb, mrb_value self)
{
  mrb_http_wrapper* wrapper = (mrb_http_wrapper*)DATA_PTR(self);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized req data") ;
  }
  
  return wrapper;
}

static void on_http_close(tlsuv_http_t* http)
{
  // mrb_http_wrapper* wrap = (mrb_http_wrapper*)(http->data);
  // 
}
static void hp_on_res_body(tlsuv_http_req_t* req, char* body, ssize_t len)
{
  mrb_http_context* ctx = req->data;
  mrb_value res_body = mrb_funcall(ctx->mrb, ctx->res, "body", 0, NULL);

  if (len == UV_EOF)
  {
    mrb_funcall(ctx->mrb, res_body, "finish", 0, NULL);
    int f = uv_async_send(ctx->handle);
  }
  else
  {
    int i = (int)len;
    mrb_value str = mrb_str_new(ctx->mrb, body, i);
    mrb_funcall(ctx->mrb, res_body, "write", 1, str);
  }
}

static void hp_http_finish(uv_async_t* handle)
{
  mrb_http_context* ctx = (mrb_http_context*)handle->data;
    // uv_mutex_lock(&am);

  mrb_value this = mrb_thread_migrate_value(ctx->mrb, ctx->res, ctx->omrb);

  mrb_value func = mrb_thread_migrate_value(ctx->mrb, ctx->on_response, ctx->omrb);
    // uv_mutex_unlock(&am);

  mrb_funcall_with_block(ctx->omrb, ctx->reciever, mrb_intern_lit(ctx->omrb, "instance_exec"), 1, &this, func);
}

static void hp_on_http_response(tlsuv_http_resp_t *resp, void* wctx) 
{
  // uv_mutex_lock(&am);
  mrb_http_context* ctx = (mrb_http_context*)wctx;
  mrb_funcall(ctx->mrb, ctx->res, "code=", 1, mrb_int_value(ctx->mrb, resp->code));
  mrb_funcall(ctx->mrb, ctx->res, "status=", 1, mrb_str_new_cstr(ctx->mrb, resp->status));
  // uv_mutex_unlock(&am);

}

mrb_value mrb_http_req_execute_get(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_value opts;
  mrb_value on_response;
  mrb_get_args(mrb, "So&", &path, &opts, &on_response);

  mrb_value method = mrb_str_new_cstr(mrb, "GET");
  return mrb_funcall(mrb, self, "execute", 4, method, path, opts, on_response);
}

int mrb_http_set_header(mrb_state* mrb, mrb_value key, mrb_value value, void* data)
{
  tlsuv_http_req_t* req = (tlsuv_http_req_t*)data;
  char* ckey = mrb_str_to_cstr(mrb, key);
  char* cvalue = mrb_str_to_cstr(mrb, value);

  tlsuv_http_req_header(req, ckey, cvalue);
}

mrb_value mrb_http_key_to_str(mrb_state* mrb, mrb_value self)
{
  mrb_value key;
  mrb_get_args(mrb, "o", &key);
  return mrb_funcall(mrb, key, "to_s", 0, NULL);
}

mrb_value mrb_http_req_execute(mrb_state* mrb, mrb_value self)
{
  // uv_mutex_lock(&rm);
  mrb_value path;
  mrb_value iopts;
  mrb_value on_response;

  mrb_get_args(mrb, "So&", &path, &iopts, &on_response);
  mrb_http_wrapper* wrapper = mrb_http_req_get(mrb, self);

  struct RProc* keys_proc = mrb_proc_new_cfunc(mrb, mrb_http_key_to_str);
  mrb_value opts = mrb_funcall_with_block(mrb, iopts, mrb_intern_lit(mrb, "transform_keys"), 0, NULL, mrb_obj_value(keys_proc));

  mrb_value method = mrb_hash_get(mrb, opts, mrb_str_new_cstr(mrb, "method"));
  char* cmethod = mrb_str_to_cstr(mrb, method);
  char* cpath = mrb_str_to_cstr(mrb, path);

  /* get our uv loop */
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  mrb_value worker = mrb_funcall(mrb, mrb_obj_value(hokusai), "worker", 0, NULL);
  mrb_uv_loop_wrapper* loopwrapper = mrb_uv_loop_get(mrb, worker);

  /* init an empty response */
  struct RClass* http = mrb_module_get_under(mrb, hokusai, "HTTP");
  struct RClass* response_klass = mrb_class_get_under(mrb, http, "Response");
  mrb_value res = mrb_obj_new(mrb, response_klass, 0, NULL);

  mrb_state* mrb2 = mrb_open();
  mrb_define_module(mrb2, "Hokusai");
  mrb_define_module(mrb2, "UV");
  mrb_define_uv_loop_class(mrb2);
  mrb_define_http_req_class(mrb2);
  mrb_f_global_variables(mrb, self);
  
  load_pocket(mrb2);

  mrb_value non_response = mrb_thread_migrate_value(mrb, on_response, mrb2);
  mrb_value nresponse = mrb_thread_migrate_value(mrb, res, mrb2);
  
  mrb_http_context* ctx = malloc(sizeof(mrb_http_context));
  ctx->omrb = mrb;
  ctx->reciever = wrapper->reciever;
  ctx->self = self;
  ctx->mrb = mrb2;
  ctx->res = nresponse;
  ctx->on_response = non_response;
  ctx->handle = wrapper->handle;
  ctx->handle->data = ctx;

  tlsuv_http_t* https = wrapper->http;
  tlsuv_http_req_t* req = tlsuv_http_req(https, cmethod, cpath, hp_on_http_response, (void*)ctx);
  req->resp.body_cb = hp_on_res_body;

  /* set headers */
  mrb_value headers = mrb_hash_fetch(mrb, opts, mrb_str_new_cstr(mrb, "headers"), mrb_hash_new(mrb));
  mrb_hash_foreach(mrb, RHASH(headers), mrb_http_set_header, (void*)req);

  // set body if there is one
  mrb_value body = mrb_hash_get(mrb, opts, mrb_str_new_cstr(mrb, "body"));
  if (!mrb_nil_p(body))
  {
    char* msg = mrb_str_to_cstr(mrb, body);
    tlsuv_http_req_data(req, msg, strlen(msg), NULL);
  }

  return mrb_nil_value();
}

mrb_value mrb_http_req_url(mrb_state* mrb, mrb_value self)
{
  mrb_http_wrapper* wrapper = mrb_http_req_get(mrb, self);
  return wrapper->url;
}

mrb_value mrb_http_req_init(mrb_state* mrb, mrb_value self)
{
  
  /* get the vars */
  mrb_value receiver;
  mrb_value url;
  mrb_get_args(mrb, "oS", &receiver, &url);
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  /* get our uv loop */
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  mrb_value worker = mrb_funcall(mrb, mrb_obj_value(hokusai), "worker", 0, NULL);
  mrb_uv_loop_wrapper* loopwrapper = mrb_uv_loop_get(mrb, worker);
  
  
  mrb_http_wrapper* http_wrapper = malloc(sizeof(mrb_http_wrapper));
  if (!http_wrapper) mrb_raise(mrb, E_STANDARD_ERROR, "no memory for request");
  
  char* c_url = mrb_str_to_cstr(mrb, url);
  
  tlsuv_http_t* http = malloc(sizeof(tlsuv_http_t));
  if (!http) mrb_raise(mrb, E_STANDARD_ERROR, "no memory for http");
  // tlsuv_http_t http;
  
  tlsuv_http_init(loopwrapper->loop, http, c_url);
  tlsuv_http_connect_timeout(http, 0);

  uv_async_t* async_handle = malloc(sizeof(uv_async_t));
  uv_async_init(loopwrapper->loop, async_handle, hp_http_finish);

  
  *http_wrapper = (mrb_http_wrapper){mrb, http, url, receiver, async_handle, NULL};
  mrb_data_init(obj, http_wrapper, &mrb_http_req_type);
  
  return obj;
}

mrb_value mrb_http_req_finish(mrb_state* mrb, mrb_value self)
{
  mrb_value reciever;
  mrb_value block;

  mrb_get_args(mrb, "oo", &reciever, &block);
  mrb_funcall_with_block(mrb, reciever, mrb_intern_lit(mrb, "instance_eval"), 0, NULL, block);
}

void mrb_define_http_req_class(mrb_state* mrb)
{
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  struct RClass *http = mrb_module_get_under(mrb, hokusai, "HTTP");
  struct RClass* request = mrb_define_class_under(mrb, hokusai, "Request", mrb->object_class);
  uv_mutex_init(&am);
  mrb_define_class_method(mrb, request, "init", mrb_http_req_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, request, "url", mrb_http_req_url, MRB_ARGS_NONE());
  mrb_define_method(mrb, request, "execute", mrb_http_req_execute, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, request, "get", mrb_http_req_execute_get, MRB_ARGS_REQ(3));

  struct RClass *server = mrb_define_class_under(mrb, http, "Server", mrb->object_class);
  MRB_SET_INSTANCE_TT(server, MRB_TT_DATA);
  mrb_define_method(mrb, server, "initialize", mrb_http_srv_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, server, "certificate", mrb_http_srv_certificate, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, server, "on_request", mrb_http_srv_on_request, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, server, "bind", mrb_http_srv_bind_method, MRB_ARGS_REQ(1));
  struct RClass *conn_klass = mrb_define_class_under(mrb, http, "Connection", mrb->object_class);
  MRB_SET_INSTANCE_TT(conn_klass, MRB_TT_DATA);
  mrb_define_method(mrb, conn_klass, "respond", mrb_http_srv_conn_respond, MRB_ARGS_REQ(3));

  MRB_SET_INSTANCE_TT(request, MRB_TT_DATA);
}

#endif
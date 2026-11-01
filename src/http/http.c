#ifndef MRB_HTTP
#define MRB_HTTP

#include <tlsuv/http.h>
#include <tlsuv/tlsuv.h>
#include <uv.h>
#include <string.h>
#include <stdlib.h>
#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/hash.h>
#include <mruby/proc.h>
#include <mruby/string.h>
#include <mruby/variable.h>
#include "http.h"
#include <pocket.h>

typedef struct MRB_HTTPContext
{
  mrb_state* mrb;
  mrb_value res;
  mrb_value receiver;
  mrb_value on_response;
  int has_block;
  char* method;
  char* path;
  char* body;
} mrb_http_context;

typedef struct MRB_HTTPWrapper
{
  mrb_state* mrb;
  tlsuv_http_t* http;
  mrb_value url;
  mrb_value receiver;
} mrb_http_wrapper;

mrb_http_wrapper* mrb_http_req_get(mrb_state* mrb, mrb_value self);

static void mrb_http_req_type_free(mrb_state* mrb, void* payload)
{
  mrb_http_wrapper* wrapper = (mrb_http_wrapper*) payload;
  mrb_gc_unregister(mrb, wrapper->url);
  mrb_gc_unregister(mrb, wrapper->receiver);
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

static void hp_ctx_free(mrb_http_context* ctx)
{
  mrb_gc_unregister(ctx->mrb, ctx->res);
  mrb_gc_unregister(ctx->mrb, ctx->on_response);
  mrb_gc_unregister(ctx->mrb, ctx->receiver);
  free(ctx->method);
  free(ctx->path);
  free(ctx->body);
  free(ctx);
}

static void hp_on_http_response(tlsuv_http_resp_t *resp, void* data) 
{
  mrb_http_context* ctx = (mrb_http_context*)data;
  mrb_state* mrb = ctx->mrb;
  int ai = mrb_gc_arena_save(mrb);

  mrb_funcall(mrb, ctx->res, "code=", 1, mrb_int_value(mrb, resp->code));
  mrb_funcall(mrb, ctx->res, "status=", 1, mrb_str_new_cstr(mrb, resp->status));

  if (mrb->exc) { mrb_print_error(mrb); mrb->exc = NULL; }
  mrb_gc_arena_restore(mrb, ai);
}

static void hp_on_res_body(tlsuv_http_req_t* req, char* body, ssize_t len)
{
  mrb_http_context* ctx = (mrb_http_context*)req->data;
  mrb_state* mrb = ctx->mrb;
  int ai = mrb_gc_arena_save(mrb);

  mrb_value res_body = mrb_funcall(mrb, ctx->res, "body", 0, NULL);

  if (len < 0)  /* UV_EOF or an error */
  {
    mrb_funcall(mrb, res_body, "finish", 0, NULL);

    if (ctx->has_block)
    {
      mrb_funcall_with_block(
        mrb,
        ctx->receiver,
        mrb_intern_lit(mrb, "instance_exec"),
        1,
        &ctx->res,
        ctx->on_response
      );
    }

    if (mrb->exc) { mrb_print_error(mrb); mrb->exc = NULL; }

    hp_ctx_free(ctx);
  }
  else
  {
    mrb_funcall(mrb, res_body, "write", 1, mrb_str_new(mrb, body, (mrb_int)len));
    if (mrb->exc) { mrb_print_error(mrb); mrb->exc = NULL; }
  }

  mrb_gc_arena_restore(mrb, ai);
}

int mrb_http_set_header(mrb_state* mrb, mrb_value key, mrb_value value, void* data)
{
  tlsuv_http_req_t* req = (tlsuv_http_req_t*)data;
  mrb_value k = mrb_obj_as_string(mrb, key);
  mrb_value v = mrb_obj_as_string(mrb, value);
  
  tlsuv_http_req_header(req, mrb_string_cstr(mrb, k), mrb_string_cstr(mrb, v));
  return 0;
}

mrb_value mrb_http_key_to_str(mrb_state* mrb, mrb_value self)
{
  mrb_value key;
  mrb_get_args(mrb, "o", &key);
  return mrb_funcall(mrb, key, "to_s", 0, NULL);
}

mrb_value mrb_http_req_execute(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_value iopts;
  mrb_value on_response;

  mrb_get_args(mrb, "So&", &path, &iopts, &on_response);
  mrb_http_wrapper* wrapper = mrb_http_req_get(mrb, self);

  struct RProc* keys_proc = mrb_proc_new_cfunc(mrb, mrb_http_key_to_str);
  mrb_value opts = mrb_funcall_with_block(mrb, iopts, mrb_intern_lit(mrb, "transform_keys"), 0, NULL, mrb_obj_value(keys_proc));

  mrb_value method = mrb_hash_get(mrb, opts, mrb_str_new_cstr(mrb, "method"));
  if (mrb_nil_p(method)) method = mrb_str_new_cstr(mrb, "GET");
  method = mrb_obj_as_string(mrb, method);

  char* cmethod = mrb_str_to_cstr(mrb, method);
  char* cpath = mrb_str_to_cstr(mrb, path);

  /* init an empty response */
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  struct RClass* http = mrb_module_get_under(mrb, hokusai, "HTTP");
  struct RClass* response_klass = mrb_class_get_under(mrb, http, "Response");
  mrb_value res = mrb_obj_new(mrb, response_klass, 0, NULL);

  /* per-request context */
  mrb_http_context* ctx = calloc(1, sizeof(mrb_http_context));
  if (!ctx) mrb_raise(mrb, E_STANDARD_ERROR, "no memory for request");

  ctx->mrb = mrb;
  ctx->res = res;
  ctx->on_response = on_response;
  ctx->has_block = !mrb_nil_p(on_response);
  ctx->receiver = wrapper->receiver;
  ctx->method = strdup(mrb_string_cstr(mrb, method));
  ctx->path = strdup(mrb_string_cstr(mrb, path));

  mrb_gc_register(mrb, ctx->res);
  mrb_gc_register(mrb, ctx->on_response);
  mrb_gc_register(mrb, ctx->receiver);

  /* body, copied with its real length */
  mrb_value body = mrb_hash_get(mrb, opts, mrb_str_new_cstr(mrb, "body"));
  mrb_int body_len = 0;
  if (!mrb_nil_p(body))
  {
    body = mrb_obj_as_string(mrb, body);
    body_len = RSTRING_LEN(body);
    ctx->body = malloc(body_len > 0 ? body_len : 1);
    memcpy(ctx->body, RSTRING_PTR(body), body_len);
  }

  tlsuv_http_req_t* req = tlsuv_http_req(wrapper->http, ctx->method, ctx->path, hp_on_http_response, (void*)ctx);
  req->resp.body_cb = hp_on_res_body;

  /* headers */
  mrb_value headers = mrb_hash_get(mrb, opts, mrb_str_new_cstr(mrb, "headers"));
  if (mrb_hash_p(headers))
  {
    mrb_hash_foreach(mrb, RHASH(headers), mrb_http_set_header, (void*)req);
  }

  if (ctx->body)
  {
    tlsuv_http_req_data(req, ctx->body, body_len, NULL);
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
  
  tlsuv_http_init(loopwrapper->loop, http, c_url);
  tlsuv_http_connect_timeout(http, 0);

  mrb_gc_register(mrb, url);
  mrb_gc_register(mrb, receiver);
  
  *http_wrapper = (mrb_http_wrapper){mrb, http, url, receiver };
  mrb_data_init(obj, http_wrapper, &mrb_http_req_type);
  
  return obj;
}

void mrb_define_http_req_class(mrb_state* mrb)
{
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  struct RClass* request = mrb_define_class_under(mrb, hokusai, "Request", mrb->object_class);

  MRB_SET_INSTANCE_TT(request, MRB_TT_DATA);

  mrb_define_class_method(mrb, request, "init", mrb_http_req_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, request, "url", mrb_http_req_url, MRB_ARGS_NONE());
  mrb_define_method(mrb, request, "execute", mrb_http_req_execute, MRB_ARGS_REQ(2) | MRB_ARGS_BLOCK());
}

#endif
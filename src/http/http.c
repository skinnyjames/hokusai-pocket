#ifndef MRB_HTTP
#define MRB_HTTP

#include <tlsuv/http.h>
#include <tlsuv/tlsuv.h>
#include <uv.h>
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

mrb_value mrb_http_req_execute(mrb_state* mrb, mrb_value self)
{
  // uv_mutex_lock(&rm);
  mrb_value path;
  mrb_value opts;
  mrb_value on_response;

  
  mrb_get_args(mrb, "So&", &path, &opts, &on_response);
  mrb_http_wrapper* wrapper = mrb_http_req_get(mrb, self);

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
  struct RClass* request = mrb_define_class_under(mrb, hokusai, "Request", mrb->object_class);
  uv_mutex_init(&am);
  mrb_define_class_method(mrb, request, "init", mrb_http_req_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, request, "url", mrb_http_req_url, MRB_ARGS_NONE());
  mrb_define_method(mrb, request, "execute", mrb_http_req_execute, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, request, "get", mrb_http_req_execute_get, MRB_ARGS_REQ(3));
  MRB_SET_INSTANCE_TT(request, MRB_TT_DATA);

}

#endif
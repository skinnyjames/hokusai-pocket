#ifndef MRB_UV_UDP
#define MRB_UV_UDP

#include "udp.h"
#include "loop.h"
#include <uv.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <string.h>
#include <stdio.h>

static void mrb_uv_udp_on_close(uv_handle_t* handle)
{
  free(handle);
}

static void mrb_uv_udp_type_free(mrb_state* mrb, void* payload)
{
  mrb_uv_udp_wrapper* wrapper = (mrb_uv_udp_wrapper*)payload;

  if (wrapper->handle && !wrapper->closed)
  {
    wrapper->closed = TRUE;
    uv_close((uv_handle_t*)wrapper->handle, mrb_uv_udp_on_close);
  }

  free(wrapper);
}

static struct mrb_data_type mrb_uv_udp_type = { "UDP", mrb_uv_udp_type_free };

static mrb_uv_udp_wrapper* mrb_uv_udp_get(mrb_state* mrb, mrb_value self)
{
  mrb_uv_udp_wrapper* wrapper = (mrb_uv_udp_wrapper*)DATA_PTR(self);
  if (!wrapper) mrb_raise(mrb, E_ARGUMENT_ERROR, "uninitialized udp socket");
  return wrapper;
}

static uv_loop_t* mrb_uv_udp_shared_loop(mrb_state* mrb)
{
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  mrb_value worker = mrb_funcall(mrb, mrb_obj_value(hokusai), "worker", 0, NULL);
  mrb_uv_loop_wrapper* loopwrapper = mrb_uv_loop_get(mrb, worker);
  return (uv_loop_t*)loopwrapper->loop;
}

static void mrb_uv_udp_alloc(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf)
{
  mrb_uv_udp_wrapper* wrapper = (mrb_uv_udp_wrapper*)handle->data;
  buf->base = malloc(wrapper->buffer_size);
  buf->len = wrapper->buffer_size;
}


static void mrb_uv_udp_on_read(uv_udp_t* handle, ssize_t nread, const uv_buf_t* buf,
                                const struct sockaddr* addr, unsigned flags)
{
  mrb_uv_udp_wrapper* wrapper = (mrb_uv_udp_wrapper*)handle->data;

  if (nread <= 0 || !addr)
  {
    free(buf->base);
    return;
  }

  if (flags & UV_UDP_PARTIAL)
  {
    fprintf(stderr, "UV::UDP: dropped oversized datagram (buffer_size too small)\n");
    free(buf->base);
    return;
  }

  char sender_ip[17] = { 0 };
  int sender_port = 0;
  if (addr->sa_family == AF_INET)
  {
    struct sockaddr_in* addr_in = (struct sockaddr_in*)addr;
    uv_ip4_name(addr_in, sender_ip, sizeof(sender_ip) - 1);
    sender_port = ntohs(addr_in->sin_port);
  }

  mrb_state* mrb = wrapper->mrb;
  mrb_value data = mrb_str_new(mrb, buf->base, nread);
  mrb_value ip = mrb_str_new_cstr(mrb, sender_ip);
  mrb_value port = mrb_fixnum_value(sender_port);

  mrb_value args[] = { data, ip, port };
  mrb_value cb = mrb_iv_get(mrb, wrapper->self, mrb_intern_lit(mrb, "@message_cb"));
  if (!mrb_nil_p(cb))
  {
    mrb_funcall(mrb, cb, "call", 3, data, ip, port);
  }

  if (mrb->exc) mrb_print_error(mrb);
  free(buf->base);
}

static mrb_value mrb_uv_udp_init(mrb_state* mrb, mrb_value self)
{
  mrb_int buffer_size = 2048;
  mrb_get_args(mrb, "|i", &buffer_size);

  if (buffer_size <= 0) mrb_raise(mrb, E_ARGUMENT_ERROR, "buffer_size must be positive");

  uv_loop_t* loop = mrb_uv_udp_shared_loop(mrb);

  uv_udp_t* handle = malloc(sizeof(uv_udp_t));
  if (!handle) mrb_raise(mrb, E_STANDARD_ERROR, "Could not allocate uv_udp_t");
  uv_udp_init(loop, handle);

  mrb_uv_udp_wrapper* wrapper = malloc(sizeof(mrb_uv_udp_wrapper));
  wrapper->handle = handle;
  wrapper->mrb = mrb;
  wrapper->self = self;
  wrapper->closed = FALSE;
  wrapper->buffer_size = (size_t)buffer_size;
  handle->data = (void*)wrapper;

  mrb_data_init(self, wrapper, &mrb_uv_udp_type);
  return self;
}

static mrb_value mrb_uv_udp_bind(mrb_state* mrb, mrb_value self)
{
  mrb_int port;
  mrb_value host_val = mrb_nil_value();
  mrb_get_args(mrb, "i|S", &port, &host_val);

  const char* host = mrb_nil_p(host_val) ? "0.0.0.0" : mrb_string_cstr(mrb, host_val);

  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);

  struct sockaddr_in addr;
  uv_ip4_addr(host, (int)port, &addr);

  int rc = uv_udp_bind(wrapper->handle, (const struct sockaddr*)&addr, UV_UDP_REUSEADDR);
  if (rc) mrb_raisef(mrb, E_STANDARD_ERROR, "uv_udp_bind failed: %S", mrb_str_new_cstr(mrb, uv_strerror(rc)));

  return self;
}

static mrb_value mrb_uv_udp_set_broadcast(mrb_state* mrb, mrb_value self)
{
  mrb_bool on;
  mrb_get_args(mrb, "b", &on);

  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);
  int rc = uv_udp_set_broadcast(wrapper->handle, on ? 1 : 0);
  if (rc) mrb_raisef(mrb, E_STANDARD_ERROR, "uv_udp_set_broadcast failed: %S", mrb_str_new_cstr(mrb, uv_strerror(rc)));

  return self;
}

static mrb_value mrb_uv_udp_recv_start(mrb_state* mrb, mrb_value self)
{
  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);
  int rc = uv_udp_recv_start(wrapper->handle, mrb_uv_udp_alloc, mrb_uv_udp_on_read);
  if (rc) mrb_raisef(mrb, E_STANDARD_ERROR, "uv_udp_recv_start failed: %S", mrb_str_new_cstr(mrb, uv_strerror(rc)));

  return self;
}

static mrb_value mrb_uv_udp_recv_stop(mrb_state* mrb, mrb_value self)
{
  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);
  uv_udp_recv_stop(wrapper->handle);
  return self;
}

typedef struct MrbUvUdpSendReq {
  uv_udp_send_t req;
  char* data;
} mrb_uv_udp_send_req;

static void mrb_uv_udp_on_send(uv_udp_send_t* req, int status)
{
  mrb_uv_udp_send_req* send_req = (mrb_uv_udp_send_req*)req;
  free(send_req->data);
  free(send_req);
}

static mrb_value mrb_uv_udp_send(mrb_state* mrb, mrb_value self)
{
  mrb_value data;
  char* host;
  mrb_int port;
  mrb_get_args(mrb, "Szi", &data, &host, &port);

  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);

  struct sockaddr_in addr;
  uv_ip4_addr(host, (int)port, &addr);

  mrb_int len = RSTRING_LEN(data);
  mrb_uv_udp_send_req* send_req = malloc(sizeof(mrb_uv_udp_send_req));
  send_req->data = malloc(len);
  memcpy(send_req->data, RSTRING_PTR(data), len);

  uv_buf_t buf = uv_buf_init(send_req->data, (unsigned int)len);

  int rc = uv_udp_send(&send_req->req, wrapper->handle, &buf, 1,
                        (const struct sockaddr*)&addr, mrb_uv_udp_on_send);

  if (rc)
  {
    free(send_req->data);
    free(send_req);
    mrb_raisef(mrb, E_STANDARD_ERROR, "uv_udp_send failed: %S", mrb_str_new_cstr(mrb, uv_strerror(rc)));
  }

  return self;
}

static mrb_value mrb_uv_udp_close(mrb_state* mrb, mrb_value self)
{
  mrb_uv_udp_wrapper* wrapper = mrb_uv_udp_get(mrb, self);
  if (!wrapper->closed)
  {
    wrapper->closed = TRUE;
    uv_close((uv_handle_t*)wrapper->handle, mrb_uv_udp_on_close);
  }
  return mrb_nil_value();
}

mrb_value mrb_uv_udp_on_message(mrb_state* mrb, mrb_value self)
{
  mrb_value proc;
  mrb_get_args(mrb, "&", &proc);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@message_cb"), proc);
  return mrb_nil_value();
}

void mrb_define_uv_udp_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "UV");
  struct RClass* klass = mrb_define_class_under(mrb, module, "UDP", mrb->object_class);
  MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

  mrb_define_method(mrb, klass, "initialize", mrb_uv_udp_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "bind", mrb_uv_udp_bind, MRB_ARGS_ARG(1, 1));
  mrb_define_method(mrb, klass, "on_message", mrb_uv_udp_on_message, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, klass, "broadcast", mrb_uv_udp_set_broadcast, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "listen", mrb_uv_udp_recv_start, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "stop", mrb_uv_udp_recv_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "write", mrb_uv_udp_send, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, klass, "close", mrb_uv_udp_close, MRB_ARGS_NONE());
}

#endif
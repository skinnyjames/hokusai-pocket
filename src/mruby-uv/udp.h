#ifndef MRB_UV_UDP_H
#define MRB_UV_UDP_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/string.h>
#include <stdlib.h>
#include <uv.h>

typedef struct MrbUvUdpWrapper {
  uv_udp_t* handle;
  mrb_state* mrb;
  mrb_value self;
  mrb_bool closed;
  size_t buffer_size;
} mrb_uv_udp_wrapper;

void mrb_define_uv_udp_class(mrb_state* mrb);

#endif

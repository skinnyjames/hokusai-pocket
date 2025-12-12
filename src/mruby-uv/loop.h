#ifndef MRB_UV_LOOP_H
#define MRB_UV_LOOP_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <stdlib.h>

typedef struct MrbUvLoopWrapper {
  void* loop;
} mrb_uv_loop_wrapper;

mrb_uv_loop_wrapper* mrb_uv_loop_get(mrb_state* mrb, mrb_value self);
void mrb_define_uv_loop_class(mrb_state* mrb);
void mrb_define_uv_work_class(mrb_state* mrb);
#endif
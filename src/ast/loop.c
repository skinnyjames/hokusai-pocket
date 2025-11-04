#ifndef HOKUSAI_POCKET_LOOP
#define HOKUSAI_POCKET_LOOP

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/variable.h>

mrb_value hp_loop_init(mrb_state* mrb, mrb_value self)
{
  mrb_value var;
  mrb_value method;

  mrb_get_args(mrb, "SS", &var, &method);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@var"), var);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@method"), method);

  return self;
}

mrb_value hp_loop_var(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@var"));
}

mrb_value hp_loop_method(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@method"));
}

void mrb_define_hokusai_loop_class(mrb_state* mrb, struct RClass* ast)
{
  struct RClass* loop_class = mrb_define_class_under(mrb, ast, "Loop", mrb->object_class);

  mrb_define_method(mrb, loop_class, "initialize", hp_loop_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, loop_class, "var", hp_loop_var, MRB_ARGS_NONE());
  mrb_define_method(mrb, loop_class, "method", hp_loop_method, MRB_ARGS_NONE());
}

#endif
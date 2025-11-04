#ifndef HOKUSAI_POCKET_FUNC
#define HOKUSAI_POCKET_FUNC

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/variable.h>

mrb_value hp_func_init(mrb_state* mrb, mrb_value self)
{
  mrb_value method;
  mrb_value args;

  mrb_get_args(mrb, "SA", &method, &args);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@args"), args);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@method"), method);

  return self;
}

mrb_value hp_func_args(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@args"));
}

mrb_value hp_func_method(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@method"));
}

void mrb_define_hokusai_func_class(mrb_state* mrb, struct RClass* ast)
{
  struct RClass* func_class = mrb_define_class_under(mrb, ast, "Func", mrb->object_class);

  mrb_define_method(mrb, func_class, "initialize", hp_func_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, func_class, "args", hp_func_args, MRB_ARGS_NONE());
  mrb_define_method(mrb, func_class, "method", hp_func_method, MRB_ARGS_NONE());
}

#endif
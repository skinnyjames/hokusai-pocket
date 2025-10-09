#ifndef HOKUSAI_POCKET_PROP
#define HOKUSAI_POCKET_PROP

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/variable.h>
#include <mruby/value.h>

mrb_value hp_prop_init(mrb_state* mrb, mrb_value self)
{
  mrb_bool computed;
  mrb_value name;
  mrb_value func;

  mrb_get_args(mrb, "bSo", &computed, &name, &func);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@computed"), mrb_bool_value(computed));
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@name"), name);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@func"), func);

  return self;
}

mrb_value hp_prop_is_computed(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@computed"));
}

mrb_value hp_prop_name(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@name"));
}

mrb_value hp_prop_func(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@func"));
}

void mrb_define_hokusai_prop_class(mrb_state* mrb, struct RClass* ast)
{
  struct RClass* prop_class = mrb_define_class_under(mrb, ast, "Prop", mrb->object_class);

  mrb_define_method(mrb, prop_class, "initialize", hp_prop_init, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, prop_class, "computed?", hp_prop_is_computed, MRB_ARGS_NONE());
  mrb_define_method(mrb, prop_class, "name", hp_prop_name, MRB_ARGS_NONE());
  mrb_define_method(mrb, prop_class, "value", hp_prop_func, MRB_ARGS_NONE());
}

#endif
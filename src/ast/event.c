#ifndef HOKUSAI_POCKET_EVENT
#define HOKUSAI_POCKET_EVENT

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/variable.h>

mrb_value hp_event_init(mrb_state* mrb, mrb_value self)
{
  mrb_value name;
  mrb_value func;

  mrb_get_args(mrb, "So", &name, &func);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@name"), name);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@func"), func);

  return self;
}

mrb_value hp_event_name(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@name"));
}

mrb_value hp_event_func(mrb_state* mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@func"));
}

void mrb_define_hokusai_event_class(mrb_state* mrb, struct RClass* ast)
{
  struct RClass* event_class = mrb_define_class_under(mrb, ast, "Event", mrb->object_class);

  mrb_define_method(mrb, event_class, "initialize", hp_event_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, event_class, "name", hp_event_name, MRB_ARGS_NONE());
  mrb_define_method(mrb, event_class, "value", hp_event_func, MRB_ARGS_NONE());
}

#endif
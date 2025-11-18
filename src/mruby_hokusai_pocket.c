#ifndef MRUBY_HOKUSAI_POCKET
#define MRUBY_HOKUSAI_POCKET

#include <mruby.h>
#include <fcntl.h>
#include "mruby_hokusai_pocket.h"

mrb_value mruby_hokusai_pocket_backend_run(mrb_state* mrb, mrb_value self)
{
  struct RClass* hokusai_module = mrb_module_get(mrb, "Hokusai");
  hp_backend_render_callbacks(mrb, hokusai_module);
  hp_backend_run(mrb, hokusai_module, self);

  return mrb_nil_value();
}

mrb_value hp_define_monotonic(mrb_state* mrb, mrb_value self)
{
  return mrb_float_value(mrb, monotonic_seconds());
}

void mrb_mruby_hokusai_pocket_gem_init(mrb_state* mrb)
{
  struct RClass* hokusai_module = mrb_define_module(mrb, "Hokusai");
  mrb_define_class_method(mrb, hokusai_module, "monotonic", hp_define_monotonic, MRB_ARGS_NONE());
  mrb_define_hokusai_ast_class(mrb);
  mrb_define_hokusai_style_class(mrb);
  mrb_define_hokusai_font_class(mrb);
  mrb_define_hokusai_texture_class(mrb);
  mrb_define_hokusai_image_class(mrb);
  mrb_define_hokusai_music_class(mrb);
  if (mrb->exc) mrb_print_error(mrb);

  struct RClass* hokusai_backend = mrb_class_get_under(mrb, hokusai_module, "Backend");
  mrb_define_method(mrb, hokusai_backend, "run", mruby_hokusai_pocket_backend_run, MRB_ARGS_NONE());
}

void mrb_mruby_hokusai_pocket_gem_final(mrb_state* mrb)
{

}

#endif
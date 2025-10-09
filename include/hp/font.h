#ifndef HOKUSAI_POCKET_FONT_H
#define HOKUSAI_POCKET_FONT_H

#include <mruby.h>
#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <raylib.h>

typedef struct HpFontWrapper
{
  Font font;
  int size;
} hp_font_wrapper;

hp_font_wrapper* hp_font_get(mrb_state* mrb, mrb_value self);

void mrb_define_hokusai_font_class(mrb_state* mrb);

#endif

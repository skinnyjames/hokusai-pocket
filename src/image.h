#ifndef HOKUSAI_POCKET_IMAGE_H
#define HOKUSAI_POCKET_IMAGE_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <raylib.h>

typedef struct HpImageWrapper
{
  Image image;
} hp_image_wrapper;

hp_image_wrapper* hp_image_get(mrb_state* mrb, mrb_value self);

void mrb_define_hokusai_image_class(mrb_state* mrb);

#endif

#ifndef HOKUSAI_POCKET_TEXTURE_H
#define HOKUSAI_POCKET_TEXTURE_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <raylib.h>
#include <stdlib.h>

typedef struct HpTextureWrapper
{
  RenderTexture2D texture;
} hp_texture_wrapper;

hp_texture_wrapper* hp_texture_get(mrb_state* mrb, mrb_value self);

void mrb_define_hokusai_texture_class(mrb_state* mrb);

#endif

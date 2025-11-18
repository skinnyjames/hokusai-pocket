#ifndef HOKUSAI_POCKET_MUSIC_H
#define HOKUSAI_POCKET_MUSIC_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <raylib.h>
#include <stdlib.h>

typedef struct HpMusicWrapper
{
  Music music;
} hp_music_wrapper;

hp_music_wrapper* hp_music_get(mrb_state* mrb, mrb_value self);

void mrb_define_hokusai_music_class(mrb_state* mrb);

#endif

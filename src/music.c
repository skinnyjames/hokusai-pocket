#ifndef HOKUSAI_POCKET_MUSIC
#define HOKUSAI_POCKET_MUSIC

#include "music.h"


static void hp_music_type_free(mrb_state* mrb, void* payload)
{
  hp_music_wrapper* wrapper = (hp_music_wrapper*) payload;
  UnloadMusicStream(wrapper->music);
  free(payload);
}

static struct mrb_data_type hp_music_type = { "hp_music_wrapper", hp_music_type_free };

hp_music_wrapper* hp_music_get(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = (hp_music_wrapper*)DATA_PTR(self);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized music data") ;
  }
  
  return wrapper;
}

mrb_value hp_music_from_file(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_get_args(mrb, "S", &path);
  const char* file = mrb_str_to_cstr(mrb, path);

  Music stream = LoadMusicStream(file);
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  hp_music_wrapper* wrapper = malloc(sizeof(hp_music_wrapper));
  *wrapper = (hp_music_wrapper){stream};
  mrb_data_init(obj, wrapper, &hp_music_type);
  return obj;
}

mrb_value hp_music_pause(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  PauseMusicStream(wrapper->music);
 
  return mrb_nil_value();
}

mrb_value hp_music_resume(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  ResumeMusicStream(wrapper->music);
  return mrb_nil_value();
}

mrb_value hp_music_seek(mrb_state* mrb, mrb_value self)
{
  mrb_value fpos;
  mrb_get_args(mrb, "o", &fpos);
  float pos = mrb_float(fpos);

  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  SeekMusicStream(wrapper->music, pos);
  return mrb_nil_value();
}

mrb_value hp_music_set_volume(mrb_state* mrb, mrb_value self)
{
  mrb_value fvol;
  mrb_get_args(mrb, "o", &fvol);
  float vol = mrb_float(fvol);

  if (vol > 1.0)
  {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Volume must be between 0.0 and 1.0");
  }

  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  SetMusicVolume(wrapper->music, vol);
  return mrb_nil_value();
}

mrb_value hp_music_duration(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  float seconds = GetMusicTimeLength(wrapper->music);
  return mrb_float_value(mrb, seconds);
}

mrb_value hp_music_play(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  PlayMusicStream(wrapper->music);
  return mrb_nil_value();
}

mrb_value hp_music_is_playing(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  bool playing = IsMusicStreamPlaying(wrapper->music);
  return mrb_bool_value(playing);
}

mrb_value hp_music_update(mrb_state* mrb, mrb_value self)
{
  hp_music_wrapper* wrapper = hp_music_get(mrb, self);
  UpdateMusicStream(wrapper->music);
  return mrb_nil_value();
}

void mrb_define_hokusai_music_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* klass = mrb_define_class_under(mrb, module, "Music", mrb->object_class);
  MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

  mrb_define_class_method(mrb, klass, "from_file", hp_music_from_file, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "play", hp_music_play, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "playing?", hp_music_is_playing, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "pause", hp_music_pause, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "resume", hp_music_resume, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "seek", hp_music_seek, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "duration", hp_music_duration, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "update", hp_music_update, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "volume=", hp_music_set_volume, MRB_ARGS_REQ(1));
} 

#endif
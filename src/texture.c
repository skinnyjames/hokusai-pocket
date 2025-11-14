#ifndef HOKUSAI_POCKET_TEXTURE
#define HOKUSAI_POCKET_TEXTURE

#include "texture.h"

static void hp_texture_type_free(mrb_state* mrb, void* payload)
{
  hp_texture_wrapper* wrapper = (hp_texture_wrapper*) payload;
  UnloadRenderTexture(wrapper->texture);
  free(payload);
}

static struct mrb_data_type hp_texture_type = { "Texture", hp_texture_type_free };

hp_texture_wrapper* hp_texture_get(mrb_state* mrb, mrb_value self)
{
  hp_texture_wrapper* wrapper = (hp_texture_wrapper*)DATA_PTR(self);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized texture data") ;
  }
  
  return wrapper;
}

mrb_value hp_texture_from_dimensions(mrb_state* mrb, mrb_value self)
{
  mrb_value rwidth;
  mrb_value rheight;
  mrb_get_args(mrb, "oo", &rwidth, &rheight);
  int width = mrb_int(mrb, rwidth);
  int height = mrb_int(mrb, rheight);

  RenderTexture2D tex = LoadRenderTexture(width, height);  
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  hp_texture_wrapper* wrapper = malloc(sizeof(hp_texture_wrapper));
  *wrapper = (hp_texture_wrapper){tex};
  mrb_data_init(obj, wrapper, &hp_texture_type);

  return obj;
}

mrb_value hp_texture_width(mrb_state* mrb, mrb_value self)
{
  hp_texture_wrapper* wrap = hp_texture_get(mrb, self);
  return mrb_int_value(mrb, wrap->texture.texture.width);
}

mrb_value hp_texture_height(mrb_state* mrb, mrb_value self)
{
  hp_texture_wrapper* wrap = hp_texture_get(mrb, self);
  return mrb_int_value(mrb, wrap->texture.texture.height);
}

mrb_value hp_texture_clear(mrb_state* mrb, mrb_value self)
{
  hp_texture_wrapper* wrap = hp_texture_get(mrb, self);
  BeginTextureMode(wrap->texture);
  ClearBackground((Color){0, 0, 0, 0});
  EndTextureMode();
  return mrb_nil_value();
}

// applys an array of commands to this texture...
mrb_value hp_texture_apply(mrb_state* mrb, mrb_value self)
{
  mrb_value command_array;
  mrb_get_args(mrb, "o", &command_array);
  hp_texture_wrapper* wrap = hp_texture_get(mrb, self);
  BeginTextureMode(wrap->texture);

  mrb_int len = RARRAY_LEN(command_array);
  mrb_value command;

  for (int i=0; i<len; i++)
  {
    command = mrb_ary_entry(command_array, i);
    mrb_funcall(mrb, command, "draw", 0, NULL);
  }

  EndTextureMode();
  return mrb_nil_value();
}


void mrb_define_hokusai_texture_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* klass = mrb_define_class_under(mrb, module, "Texture", mrb->object_class);
  MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

  mrb_define_class_method(mrb, klass, "init", hp_texture_from_dimensions, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, klass, "width", hp_texture_width, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "height", hp_texture_height, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "apply", hp_texture_apply, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "clear", hp_texture_clear, MRB_ARGS_NONE());
}

#endif

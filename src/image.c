#ifndef HOKUSAI_POCKET_IMAGE
#define HOKUSAI_POCKET_IMAGE

#include "image.h"
#include "texture.h"
Color image_raylib_color(mrb_state* mrb, mrb_value color)
{
  int red = mrb_int(mrb, mrb_funcall_argv(mrb, color, mrb_intern_lit(mrb, "red"), 0, NULL));
  int blue = mrb_int(mrb, mrb_funcall_argv(mrb, color, mrb_intern_lit(mrb, "blue"), 0, NULL));
  int green = mrb_int(mrb, mrb_funcall_argv(mrb, color, mrb_intern_lit(mrb, "green"), 0, NULL));
  mrb_value alphad = mrb_funcall_argv(mrb, color, mrb_intern_lit(mrb, "alpha"), 0, NULL);
  int alpha;
  if (mrb_nil_p(alphad)){
    alpha = 255;
  }
  else
  {
    alpha = mrb_int(mrb,alphad);
  }

  Color rcolor = {.r=red, .g=green, .b=blue, .a=alpha};
  return rcolor;
}

static void hp_image_type_free(mrb_state* mrb, void* payload)
{
  hp_image_wrapper* wrapper = (hp_image_wrapper*) payload;
  UnloadImage(wrapper->image);
  free(payload);
}

static struct mrb_data_type hp_image_type = { "hp_image_wrapper", hp_image_type_free };

hp_image_wrapper* hp_image_get(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* wrapper = (hp_image_wrapper*)DATA_PTR(self);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized image data") ;
  }
  
  return wrapper;
}

mrb_value hp_image_copy(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* orig = hp_image_get(mrb, self);

  Image image = ImageCopy(orig->image);
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* klass = mrb_class_get_under(mrb, module, "Image");

  mrb_value obj = mrb_funcall(mrb, mrb_obj_value(klass), "new", 0, NULL);
  hp_image_wrapper* wrapper = malloc(sizeof(hp_image_wrapper));
  *wrapper = (hp_image_wrapper){image};
  mrb_data_init(obj, wrapper, &hp_image_type);

  return obj;
}

mrb_value hp_image_from_file(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_get_args(mrb, "S", &path);
  const char* file = mrb_str_to_cstr(mrb, path);
  Image image = LoadImage(file);

  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  hp_image_wrapper* wrapper = malloc(sizeof(hp_image_wrapper));
  *wrapper = (hp_image_wrapper){image};
  mrb_data_init(obj, wrapper, &hp_image_type);

  return obj;
}

mrb_value hp_image_from_texture(mrb_state* mrb, mrb_value self)
{
  mrb_value texture;
  mrb_get_args(mrb, "o", &texture);
  hp_texture_wrapper* wrap = hp_texture_get(mrb, texture);
  Image image = LoadImageFromTexture(wrap->texture.texture);

  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  hp_image_wrapper* wrapper = malloc(sizeof(hp_image_wrapper));
  *wrapper = (hp_image_wrapper){image};
  mrb_data_init(obj, wrapper, &hp_image_type);

  return obj;
}

mrb_value hp_image_init(mrb_state* mrb, mrb_value self)
{
  mrb_value rwidth;
  mrb_value rheight;
  mrb_value rtransparent;
  mrb_get_args(mrb, "ooo", &rwidth, &rheight, &rtransparent);
  int width = mrb_int(mrb, rwidth);
  int height = mrb_int(mrb, rheight);
  int transparent = mrb_bool(rtransparent);

  Color color = transparent ? (Color){255, 255, 255, 0} : (Color){255, 255, 255, 255};
  Image image = GenImageColor(width, height, color);
  
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  hp_image_wrapper* wrapper = malloc(sizeof(hp_image_wrapper));
  *wrapper = (hp_image_wrapper){image};
  mrb_data_init(obj, wrapper, &hp_image_type);

  return obj;
}

mrb_value hp_image_width(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* wrap = hp_image_get(mrb, self);
  return mrb_int_value(mrb, wrap->image.width);
}

mrb_value hp_image_height(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* wrap = hp_image_get(mrb, self);
  return mrb_int_value(mrb, wrap->image.height);
}

mrb_value hp_image_resize(mrb_state* mrb, mrb_value self)
{
  mrb_value rwidth;
  mrb_value rheight;
  mrb_get_args(mrb, "oo", &rwidth, &rheight);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);

  int width = mrb_int(mrb, rwidth);
  int height = mrb_int(mrb, rheight);
  
  ImageResize(&(wrapper->image), width, height);
  return mrb_nil_value();
}

mrb_value hp_image_flip_vertical(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);  
  ImageFlipVertical((&wrapper->image));
  return mrb_nil_value();
}

mrb_value hp_image_flip_horizontal(mrb_state* mrb, mrb_value self)
{
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);  
  ImageFlipHorizontal((&wrapper->image));
  return mrb_nil_value();
}

mrb_value hp_image_rotate(mrb_state* mrb, mrb_value self)
{
  mrb_value rdegrees;
  mrb_get_args(mrb, "o", &rdegrees);
  float deg = mrb_float(rdegrees);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);  

  ImageRotate(&(wrapper->image), deg);
  return mrb_nil_value();
}

mrb_value hp_image_contrast(mrb_state* mrb, mrb_value self)
{
  mrb_value value;
  mrb_get_args(mrb, "o", &value);
  float contrast = mrb_float(value);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);
  if (contrast > 100 || contrast < -100)
  {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "contrast must be between -100 and 100");
  }

  ImageColorContrast(&(wrapper->image), contrast);

  return mrb_nil_value();
}

mrb_value hp_image_brightness(mrb_state* mrb, mrb_value self)
{  
  mrb_value value;
  mrb_get_args(mrb, "o", &value);
  int bright = mrb_int(mrb, value);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);
  if (bright > 255 || bright < -255)
  {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "brightness must be between -255 and 255");
  }

  ImageColorBrightness(&(wrapper->image), bright);
  return mrb_nil_value();
}

mrb_value hp_image_replace_color(mrb_state* mrb, mrb_value self)
{
  mrb_value rcolor;
  mrb_value rreplace;
  mrb_get_args(mrb, "oo", &rcolor, &rreplace);

  Color color = image_raylib_color(mrb, rcolor);
  Color replace = image_raylib_color(mrb, rreplace);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);

  ImageColorReplace(&(wrapper->image), color, replace);

  return mrb_nil_value();
}

mrb_value hp_image_color_at(mrb_state* mrb, mrb_value self)
{
  mrb_value rx;
  mrb_value ry;
  mrb_get_args(mrb, "oo", &rx, &ry);
  int x = mrb_int(mrb, rx);
  int y = mrb_int(mrb, ry);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);
  Color color = GetImageColor(wrapper->image, x, y);

  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* klass = mrb_class_get_under(mrb, module, "Color");
  return mrb_funcall(mrb, mrb_obj_value(klass), "new", 4, mrb_fixnum_value(color.r), mrb_fixnum_value(color.g), mrb_fixnum_value(color.b), mrb_fixnum_value(color.a));
}

mrb_value hp_image_export(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_get_args(mrb, "o", &path);
  const char* file = mrb_str_to_cstr(mrb, path);
  hp_image_wrapper* wrapper = hp_image_get(mrb, self);
  bool res = ExportImage(wrapper->image, file);
  return mrb_bool_value(res);
}

void mrb_define_hokusai_image_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* klass = mrb_define_class_under(mrb, module, "Image", mrb->object_class);
  MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

  mrb_define_class_method(mrb, klass, "init", hp_image_init, MRB_ARGS_REQ(3));
  mrb_define_class_method(mrb, klass, "from_file", hp_image_from_file, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, klass, "from_texture", hp_image_from_texture, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "width", hp_image_width, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "height", hp_image_height, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "copy", hp_image_copy, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "resize", hp_image_resize, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, klass, "flip_horizontal", hp_image_flip_horizontal, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "flip_vertical", hp_image_flip_vertical, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "rotate", hp_image_rotate, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "set_contrast", hp_image_contrast, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "set_brightness", hp_image_brightness, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "color_replace", hp_image_replace_color, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, klass, "color_at", hp_image_color_at, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, klass, "export", hp_image_export, MRB_ARGS_REQ(1));
}

#endif

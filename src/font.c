#ifndef HOKUSAI_POCKET_FONT
#define HOKUSAI_POCKET_FONT

#include "font.h"
#include <mruby.h>
#include <mruby/hash.h>
#include <mruby/proc.h>

static char* default_codepoints = "–—‘’“”…\r\n\t 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%%^&*(),.?/\"\\[]-_=+|~`{}<>;:'\0";

static void hp_font_type_free(mrb_state* mrb, void* payload)
{
  mrb_free(mrb, payload);
}

static struct mrb_data_type hp_font_type = { "Font", hp_font_type_free };

hp_font_wrapper* hp_font_get(mrb_state* mrb, mrb_value self)
{
  hp_font_wrapper* wrapper;
  wrapper = DATA_GET_PTR(mrb, self, &hp_font_type, hp_font_wrapper);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized ast data") ;
  }
  
  return wrapper;
}

mrb_value hp_font_default(mrb_state* mrb, mrb_value self)
{
  hp_font_wrapper* wrapper;
  Font font = GetFontDefault();
  mrb_value obj = mrb_funcall_argv(mrb, self, mrb_intern_lit(mrb, "new"), 0, NULL);
  wrapper = (hp_font_wrapper*)DATA_PTR(obj);
  if (wrapper) mrb_free(mrb, wrapper);
  mrb_data_init(obj, NULL, &hp_font_type);

  wrapper = mrb_malloc(mrb, sizeof(hp_font_wrapper));
  wrapper->font = font;
  wrapper->size = 14;

  DATA_TYPE(obj) = &hp_font_type;
  DATA_PTR(obj) = wrapper;
  return obj;
}

mrb_value hp_font_from(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_get_args(mrb, "S", &path);
  char* cpath = mrb_str_to_cstr(mrb, path);

  hp_font_wrapper* wrapper;
  Font font = LoadFont(cpath);
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  wrapper = (hp_font_wrapper*)DATA_PTR(obj);
  if (wrapper) mrb_free(mrb, wrapper);
  mrb_data_init(obj, NULL, &hp_font_type);

  wrapper = mrb_malloc(mrb, sizeof(hp_font_wrapper));
  wrapper->font = font;
  wrapper->size = 14;

  DATA_TYPE(obj) = &hp_font_type;
  DATA_PTR(obj) = wrapper;
  return obj;
}

mrb_value hp_font_from_ext(mrb_state* mrb, mrb_value self)
{
  mrb_value path;
  mrb_value osize;
  mrb_value rcodepoint_str;
  char* codepoint_str;
  mrb_int argc = mrb_get_args(mrb, "So|S", &path, &osize, &rcodepoint_str);

  if (argc == 2)
  {
    codepoint_str = default_codepoints;
  }
  else
  {
    codepoint_str = mrb_str_to_cstr(mrb, rcodepoint_str);
  }

  int size = mrb_int(mrb, osize);
  char* cpath = mrb_str_to_cstr(mrb, path);
  int count;
  int* codepoints = LoadCodepoints(codepoint_str, &count);
  Font font = LoadFontEx(cpath, size, codepoints, count);
  SetTextureFilter(font.texture, TEXTURE_FILTER_BILINEAR);
  UnloadCodepoints(codepoints);

  hp_font_wrapper* wrapper;
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  wrapper = (hp_font_wrapper*)DATA_PTR(obj);
  if (wrapper) mrb_free(mrb, wrapper);
  mrb_data_init(obj, NULL, &hp_font_type);

  wrapper = mrb_malloc(mrb, sizeof(hp_font_wrapper));
  wrapper->font = font;
  wrapper->size = size;

  DATA_TYPE(obj) = &hp_font_type;
  DATA_PTR(obj) = wrapper;
  return obj;
}

float hp_font_spacing(int height, hp_font_wrapper* wrapper)
{
  int size = height;//wrapper->size;
  if (size < 10) size = 10;
  float hey = (1.0 * size) / (wrapper->size == 0 ? 1.0 : (1.0 * wrapper->size));
  return hey;
}

mrb_value hp_font_measure(mrb_state* mrb, mrb_value self)
{
  mrb_value str;
  mrb_value height;
  mrb_get_args(mrb, "So", &str, &height);

  mrb_value arr = mrb_ary_new_capa(mrb, 2);
  hp_font_wrapper* wrapper = hp_font_get(mrb, self);
  char* cstr = mrb_str_to_cstr(mrb, str);
  int h = mrb_int(mrb, height);

  Vector2 vec2 = MeasureTextEx(wrapper->font, cstr, h, hp_font_spacing(h, wrapper));

  mrb_ary_push(mrb, arr, mrb_float_value(mrb, vec2.x));
  mrb_ary_push(mrb, arr, mrb_float_value(mrb, vec2.y));
  return arr;
}

mrb_value hp_font_measure_char(mrb_state* mrb, mrb_value self)
{

  mrb_value chr;
  mrb_value size;
  mrb_get_args(mrb, "So", &chr, &size);

  hp_font_wrapper* wrapper = hp_font_get(mrb, self);

  mrb_value map;
  map = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@measure_map"));
  if (mrb_nil_p(map))
  {
    map = mrb_hash_new(mrb);
    for (int i=0; i<strlen(default_codepoints); i++)
    {
      char target[2];
      sprintf(target, "%c", default_codepoints[i]);
      float w;
      int bcount;
      int letter = GetCodepoint(target, &bcount);
      GlyphInfo info = GetGlyphInfo(wrapper->font, letter);
      
      if (info.advanceX > 0)
      {
        w = (1.0 * info.advanceX);
      }
      else
      {
        w = 1.0 * (info.image.width + info.offsetX);
      }

      float base_size = 1.0 * wrapper->size;
      mrb_value arr = mrb_ary_new(mrb);
      mrb_ary_set(mrb, arr, 0, mrb_float_value(mrb, base_size));
      mrb_ary_set(mrb, arr, 1, mrb_float_value(mrb, w));

      mrb_hash_set(mrb, map, mrb_str_new_cstr(mrb, target), arr);
    }
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@measure_map"), map);
  }
  
  mrb_value arr =  mrb_hash_get(mrb, map, chr);
  if (mrb_nil_p(arr)) return mrb_nil_value();

  float base_size = mrb_float(mrb_ary_entry(arr, 0));
  float w = mrb_float(mrb_ary_entry(arr, 1));
  int s = mrb_integer(size);
  return mrb_float_value(mrb,  ((1.0 * s) / base_size) * w + 1.0);
}

mrb_value hp_font_height(mrb_state* mrb, mrb_value self)
{
  hp_font_wrapper* wrapper = hp_font_get(mrb, self);
  return mrb_int_value(mrb, wrapper->size);
}

void mrb_define_hokusai_font_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* backend = mrb_define_class_under(mrb, module, "Backend", mrb->object_class);
  struct RClass* font_class = mrb_define_class_under(mrb, backend, "Font", mrb->object_class);
  MRB_SET_INSTANCE_TT(font_class, MRB_TT_DATA);

  mrb_define_class_method(mrb, font_class, "default", hp_font_default, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, font_class, "from", hp_font_from, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, font_class, "from_ext", hp_font_from_ext, MRB_ARGS_ARG(2, 1));

  mrb_define_method(mrb, font_class, "measure_char", hp_font_measure_char, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, font_class, "measure", hp_font_measure, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, font_class, "height", hp_font_height, MRB_ARGS_NONE());
}

#endif
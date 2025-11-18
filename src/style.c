#ifndef HOKUSAI_POCKET_STYLE
#define HOKUSAI_POCKET_STYLE

#include "style.h"
#include "error.h"
#include <mruby/array.h>

mrb_value style_parse_function(mrb_state* mrb, char* function, mrb_value value)
{
  mrb_value ret;
  struct RClass* hokusai_class = mrb_module_get(mrb, "Hokusai");

  if (strcmp(function, "rgb") == 0)
  {
    mrb_value color = mrb_obj_value(mrb_class_get_under(mrb, hokusai_class, "Color"));
    ret = mrb_funcall_argv(mrb, color, mrb_intern_lit(mrb, "convert"), 1, &value);
  }
  else if (strcmp(function, "outline") == 0)
  {
    mrb_value outline = mrb_obj_value(mrb_class_get_under(mrb, hokusai_class, "Outline"));
    ret = mrb_funcall(mrb, outline, "convert", 1, value);
  }
  else if (strcmp(function, "padding") == 0)
  {
    mrb_value padding = mrb_obj_value(mrb_class_get_under(mrb, hokusai_class, "Padding"));
    ret = mrb_funcall(mrb, padding, "convert", 1, value); 
  }
  else if (strcmp(function, "bounds") == 0)
  {
    mrb_value padding = mrb_obj_value(mrb_class_get_under(mrb, hokusai_class, "Boundary"));
    ret = mrb_funcall(mrb, padding, "convert", 1, value); 
  }
  else
  {
    struct RClass* exp = mrb_class_get_under(mrb, hokusai_class, "Error");
    mrb_raisef(mrb, exp, "Unknown style function %s", function);
  }

  hp_handle_error(mrb);

  return ret;
}

mrb_value style_parse_attributes(mrb_state* mrb, hoku_style* style)
{
  mrb_value attributes = mrb_hash_new(mrb);
  hoku_style_attribute* head = style->attributes;
  while (head != NULL)
  {
    mrb_value name = mrb_str_new_cstr(mrb, head->name);
    mrb_value valuestr = mrb_str_new_cstr(mrb, head->value);
    mrb_value value;
    switch (head->type)
    {
      case HOKU_STYLE_TYPE_INT: {
        value = mrb_str_to_integer(mrb, valuestr, 10, false);
        break;
      }
      case HOKU_STYLE_TYPE_FLOAT: {
        value = mrb_float_value(mrb, mrb_str_to_dbl(mrb, valuestr, false));
        break;
      }
      case HOKU_STYLE_TYPE_BOOL: {
        if (strcmp(head->value, "true") == 0)
        {
          value = mrb_bool_value(true);
        }
        else if (strcmp(head->value, "t") == 0)
        {
          value = mrb_bool_value(true);
        }
        else
        {
          value = mrb_bool_value(false);
        }
        break;
      }
      case HOKU_STYLE_TYPE_STRING: {
        value = valuestr;
        break;
      }
      case HOKU_STYLE_TYPE_FUNC: {
        value = style_parse_function(mrb, head->function_name, valuestr);
        break;
      }
    }

    mrb_hash_set(mrb, attributes, name, value);
    head = head->next;
  }

  hp_handle_error(mrb);
  return attributes;
}

mrb_value style_parse(mrb_state* mrb, mrb_value self)
{
  mrb_value templateval;
  hoku_style* style;
  mrb_get_args(mrb, "S", &templateval);
  char* template = mrb_str_to_cstr(mrb, templateval);
  if (hoku_style_from_template(&style, template) != 0)
  {
    mrb_raisef(mrb, E_STANDARD_ERROR, "Failed to parse style!\n");
  }
  
  mrb_value styles = mrb_hash_new(mrb);

  hoku_style* head = style;
  mrb_value style_event_name;
  // style = { "sometStyle" => { "default" => { "attr1" => value }}}
  while (head != NULL)
  {
    f_log(F_LOG_FINE, "walking head");
    if (head->event_name != NULL)
    {
      style_event_name = mrb_str_new_cstr(mrb, head->event_name);
    }
    else
    {
      style_event_name = mrb_str_new_cstr(mrb, "default");
    }

    mrb_value name = mrb_str_new_cstr(mrb, head->name);
    mrb_value evented_styles = mrb_hash_get(mrb, styles, name);
    if (mrb_nil_p(evented_styles)) evented_styles = mrb_hash_new(mrb);

    f_log(F_LOG_DEBUG, "parsing styles");
    mrb_value attrs = style_parse_attributes(mrb, head);
    mrb_hash_set(mrb, evented_styles, style_event_name, attrs);
    mrb_hash_set(mrb, styles, name, evented_styles);
    head = head->next;
  }

  f_log(F_LOG_INFO, "FREEING STYLE");
  hoku_style_free(style);
  f_log(F_LOG_INFO, "DONE FREE");

  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* style_class = mrb_class_get_under(mrb, module, "Style");
  return mrb_obj_new(mrb, style_class, 1, &styles);
}

mrb_value style_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_value styles;
  mrb_get_args(mrb, "H", &styles);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@elements"), styles);
  return self;
}

mrb_value style_keys(mrb_state* mrb, mrb_value self)
{
  mrb_value elements = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@elements"));
  return mrb_funcall(mrb, elements, "keys", 0, NULL);
}

mrb_value style_fetch(mrb_state* mrb, mrb_value self)
{
  mrb_value key;
  mrb_get_args(mrb, "S", &key);
  mrb_value elements = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@elements"));
  return mrb_funcall(mrb, elements, "[]", 1, key);
}

void mrb_define_hokusai_style_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* style_class = mrb_define_class_under(mrb, module, "Style", mrb->object_class);
  mrb_define_class_method(mrb, style_class, "parse", style_parse, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, style_class, "initialize", style_initialize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, style_class, "keys", style_keys, MRB_ARGS_NONE());
  mrb_define_method(mrb, style_class, "[]", style_fetch, MRB_ARGS_REQ(1));
}

#endif
#ifndef HOKUSAI_POCKET_BACKEND
#define HOKUSAI_POCKET_BACKEND

#include "backend.h"
// #include "monotonic_timer.h"

// SHADER_UNIFORM_FLOAT = 0      # Shader uniform type: float
// SHADER_UNIFORM_VEC2 = 1       # Shader uniform type: vec2 (2 float)
// SHADER_UNIFORM_VEC3 = 2       # Shader uniform type: vec3 (3 float)
// SHADER_UNIFORM_VEC4 = 3       # Shader uniform type: vec4 (4 float)
// SHADER_UNIFORM_INT = 4        # Shader uniform type: int
// SHADER_UNIFORM_IVEC2 = 5      # Shader uniform type: ivec2 (2 int)
// SHADER_UNIFORM_IVEC3 = 6      # Shader uniform type: ivec3 (3 int)
// SHADER_UNIFORM_IVEC4 = 7      # Shader uniform type: ivec4 (4 int)
// SHADER_UNIFORM_UINT = 8       # Shader uniform type: unsigned int
// SHADER_UNIFORM_UIVEC2 = 9     # Shader uniform type: uivec2 (2 unsigned int)
// SHADER_UNIFORM_UIVEC3 = 10    # Shader uniform type: uivec3 (3 unsigned int)
// SHADER_UNIFORM_UIVEC4 = 11    # Shader uniform type: uivec4 (4 unsigned int)


uint64_t char_cache_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	measure_cache* cache = (measure_cache*) item;
	return hashmap_sip(&(cache->letter), 1, seed0, seed1);
}

int char_cache_compare(const void* a, const void* b, void* udata)
{
  const measure_cache* prop_a = (measure_cache*) a;
	const measure_cache* prop_b = (measure_cache*) b;
	return prop_a->letter > prop_b->letter;
}

void font_free(font_cache* font)
{
  free(font->key);
}


int font_compare(const void* a, const void* b, void* udata)
{
	const font_cache* prop_a = (font_cache*) a;
	const font_cache* prop_b = (font_cache*) b;
	return strcmp(prop_a->key, prop_b->key);
}

uint64_t font_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	font_cache* font = (font_cache*) item;
	return hashmap_sip(font->key, strlen(font->key), seed0, seed1);
}

void texture_free(void* payload)
{
  texture_cache* texture = (texture_cache*)payload;
  free(texture->key);
}

int texture_compare(const void* a, const void* b, void* udata)
{
	const texture_cache* prop_a = (texture_cache*) a;
	const texture_cache* prop_b = (texture_cache*) b;
	return strcmp(prop_a->key, prop_b->key);
}

uint64_t texture_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	texture_cache* texture = (texture_cache*) item;
  UnloadTexture(texture->payload);
	return hashmap_sip(texture->key, strlen(texture->key), seed0, seed1);
}

void shader_free(void* payload)
{
  shader_cache* shader = (shader_cache*)payload;
  UnloadShader(shader->payload);
  free(shader->key);
}

int shader_compare(const void* a, const void* b, void* udata)
{
	const shader_cache* prop_a = (shader_cache*) a;
	const shader_cache* prop_b = (shader_cache*) b;
	return strcmp(prop_a->key, prop_b->key);
}

uint64_t shader_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	shader_cache* shader = (shader_cache*) item;
	return hashmap_sip(shader->key, strlen(shader->key), seed0, seed1);
}

Color raylib_color(mrb_state* mrb, mrb_value command, char* type)
{
  if (type == NULL) type = "color";
  mrb_value color = mrb_funcall_argv(mrb, command, mrb_intern_cstr(mrb, type), 0, NULL);
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

static int hp_current_scissor[5] = {0, 0, 0, 0, 0};

bool inside_scissor(float x, float y, float h)
{
  if (hp_current_scissor[4] == 0) return true;
  return y + h >= hp_current_scissor[1] && y <= hp_current_scissor[1] + hp_current_scissor[3];
}

bool inside_scissori(int x, int y, int h)
{
  if (hp_current_scissor[4] == 0)
  {
    return true;
  }

  return y + h >= hp_current_scissor[1] && y <= hp_current_scissor[1] + hp_current_scissor[3];
}

mrb_value on_draw_circle(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  float x = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "x"), 0, NULL));
  // hp_handle_error(mrb);

  float y = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "y"), 0, NULL));
  // hp_handle_error(mrb);

  float radius = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "radius"), 0, NULL));
  hp_handle_error(mrb);

  if (!inside_scissor(x, y, radius)) return mrb_nil_value();
  
  Color rcolor = raylib_color(mrb, command, "color");
  DrawCircle(x, y, radius, rcolor);
  return mrb_nil_value();
}

mrb_value on_draw_rect(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  mrb_value boundary = mrb_funcall(mrb, command, "background_boundary", 0, NULL);

  int x = mrb_int(mrb, mrb_ary_entry(boundary, 0));
  int y = mrb_int(mrb, mrb_ary_entry(boundary, 1));
  int w = mrb_int(mrb, mrb_ary_entry(boundary, 2));
  int h = mrb_int(mrb, mrb_ary_entry(boundary, 3));

  // int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, boundary, mrb_intern_lit(mrb, "x"), 0, NULL)));
  hp_handle_error(mrb);

  // // int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, boundary, mrb_intern_lit(mrb, "y"), 0, NULL)));
  // hp_handle_error(mrb);

  // // int w = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, boundary, mrb_intern_lit(mrb, "width"), 0, NULL)));
  // hp_handle_error(mrb);

  // // int h = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, boundary, mrb_intern_lit(mrb, "height"), 0, NULL)));
  // hp_handle_error(mrb);

  float rounding = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "rounding"), 0, NULL));
  // hp_handle_error(mrb);

  bool has_outline = mrb_bool(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "outline?"), 0, NULL));
  // hp_handle_error(mrb);

  if (!inside_scissori(x, y, h)) return mrb_nil_value();

  Color rcolor = raylib_color(mrb, command, "color");  
  if (rounding > 0.0)
  {
    Rectangle rect = {x, y, w, h};
    DrawRectangleRounded(rect, rounding, 50, rcolor);
  }
  else
  {
    DrawRectangle(x, y, w, h, rcolor);
  }

  if (has_outline)
  {
    bool outline_uniform = mrb_bool(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "outline_uniform?"), 0, NULL));
    mrb_value outline = mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "outline"), 0, NULL);
    Color outline_color = raylib_color(mrb, command, "outline_color");
    Rectangle rect = {x, y, w, h};

    if (outline_uniform && outline_color.a > 0)
    {
      float top = mrb_float(mrb_funcall_argv(mrb, outline, mrb_intern_lit(mrb, "top"), 0, NULL));
      if (rounding > 0.0)
      {
        DrawRectangleRoundedLinesEx(rect, rounding, 50, top, outline_color);
      }
      else
      {
        DrawRectangleLinesEx(rect, top, outline_color);
      }
    }
    else if (outline_color.a > 0)
    {
      float top = mrb_float(mrb_funcall_argv(mrb, outline, mrb_intern_lit(mrb, "top"), 0, NULL));
      float right = mrb_float(mrb_funcall_argv(mrb, outline, mrb_intern_lit(mrb, "right"), 0, NULL));
      float bottom = mrb_float(mrb_funcall_argv(mrb, outline, mrb_intern_lit(mrb, "bottom"), 0, NULL));
      float left = mrb_float(mrb_funcall_argv(mrb, outline, mrb_intern_lit(mrb, "left"), 0, NULL));

      if (top > 0)
      {
        DrawLineEx((Vector2){x, y}, (Vector2){x + w, y}, top, outline_color);
      }
      
      if (left > 0)
      {
        DrawLineEx((Vector2){x, y}, (Vector2){x, y + h}, left, outline_color);
      }

      if (right > 0)
      {
        DrawLineEx((Vector2){x + w, y}, (Vector2){x + w, y + h}, right, outline_color);
      }

      if (bottom > 0)
      {
        DrawLineEx((Vector2){x, y + h}, (Vector2){x + w, y + h}, bottom, outline_color);
      }
    }
  }

  return mrb_nil_value();
}

mrb_value on_draw_text(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  
  mrb_value used;
  mrb_value font = mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "font"), 0, NULL);
  if (mrb_nil_p(font))
  {  
    struct RClass* hok = mrb_module_get(mrb, "Hokusai");
    mrb_value fonts = mrb_funcall_argv(mrb, mrb_obj_value(hok), mrb_intern_lit(mrb, "fonts"), 0, NULL);
    mrb_value active = mrb_funcall_argv(mrb, fonts, mrb_intern_lit(mrb, "active"), 0, NULL);
    hp_handle_error(mrb);
    used = active;
  }
  else
  {
    used = font;
  }

  hp_font_wrapper* wrapper = hp_font_get(mrb, used);
  
  int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "x"), 0, NULL)));
  // hp_handle_error(mrb);

  int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "y"), 0, NULL)));
  // hp_handle_error(mrb);

  char* str = mrb_string_cstr(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "content"), 0, NULL));
  // hp_handle_error(mrb);

  int size = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "size"), 0, NULL)));
  hp_handle_error(mrb);

  if (!inside_scissori(x, y, size)) {
    return mrb_nil_value();
  }

  Color rcolor = raylib_color(mrb, command, "color");
  Vector2 vec2 = {x, y};

  DrawTextEx(wrapper->font, str, vec2, size, 1.0, rcolor);
  return mrb_nil_value();
}

mrb_value on_draw_scissor_begin(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  
  int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "x"), 0, NULL)));
  // hp_handle_error(mrb);

  int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "y"), 0, NULL)));
  // hp_handle_error(mrb);

  int width = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "width"), 0, NULL)));
  // hp_handle_error(mrb);

  int height = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "height"), 0, NULL)));
  hp_handle_error(mrb);

  BeginScissorMode(x, y, width, height);

  hp_current_scissor[0] = x;
  hp_current_scissor[1] = y;
  hp_current_scissor[2] = width;
  hp_current_scissor[3] = height;
  hp_current_scissor[4] = 1;

  return mrb_nil_value();
}

mrb_value on_draw_scissor_end(mrb_state* mrb, mrb_value self)
{
  EndScissorMode();

  hp_current_scissor[0] = 0;
  hp_current_scissor[1] = 0;
  hp_current_scissor[2] = 0;
  hp_current_scissor[3] = 0;
  hp_current_scissor[4] = 0;

  return mrb_nil_value();
}

mrb_value on_draw_image(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  
  Texture tex;
  
  char* source = mrb_string_cstr(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "source"), 0, NULL));
  // hp_handle_error(mrb);

  int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "x"), 0, NULL)));
  // hp_handle_error(mrb);

  int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "y"), 0, NULL)));
  // hp_handle_error(mrb);

  int width = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "width"), 0, NULL)));
  // hp_handle_error(mrb);

  int height = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "height"), 0, NULL)));
  hp_handle_error(mrb);

  if (!inside_scissori(x, y, height)) return mrb_nil_value();

  int len = strlen(source) + 100;
  char hash[len];
  sprintf(hash, "%s-%d-%d", source, width, height);
  const texture_cache* result = hashmap_get(textures, &(texture_cache){ .key=hash });
  if (result == NULL)
  {
    Image img = LoadImage(source);
    ImageResize(&img, width, height);
    Texture texture = LoadTextureFromImage(img);
    UnloadImage(img);
    GenTextureMipmaps(&texture);
    hashmap_set(textures, &(texture_cache){.key=strdup(hash), .payload=texture });
    tex = texture;
  }
  else
  {
    tex = result->payload;
  }

  DrawTexture(tex, x, y, WHITE);
  return mrb_nil_value();
}

int on_shader_uniform_foreach(mrb_state* mrb, mrb_value key, mrb_value value, void* data)
{
  Shader shad = *((Shader*)data);
  int type = mrb_int(mrb, mrb_ary_entry(value, 1));
  char* ckey = mrb_string_cstr(mrb, key);
  int location = GetShaderLocation(shad, ckey);
  mrb_value vec = mrb_ary_entry(value, 0);
  hp_handle_error(mrb);

  if (type == 0)
  {
    // value 0 is a float
    float values = mrb_float(vec);

    SetShaderValue(shad, location, &values, type);

  }
  else if (type == 4)
  {
    // value 0 is an int
    int values = mrb_int(mrb, vec);
    SetShaderValue(shad, location, &values, type);
  }
  else if (type == 8)
  {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Sorry, cannot do uint at this time for shader.");
    return 1;
  }
  else
  {
    // value 0 is an array...
    int len = mrb_int(mrb, mrb_funcall_argv(mrb, vec, mrb_intern_lit(mrb, "size"), 0, NULL));

    if (type < 4)
    {
      // floats
      float values[len];
      for (int i=0; i<len; i++)
      {
        values[i] = mrb_float(mrb_ary_entry(vec, i));
      }

      SetShaderValue(shad, location, values, type);
    }
    else if (type < 8)
    {
      // ints
      int values[len];
      for (int i=0; i<len; i++)
      {
        values[i] = mrb_int(mrb, mrb_ary_entry(vec, i));
      }
      
      SetShaderValue(shad, location, values, type);
    }
    else
    {
      // uints
      mrb_raise(mrb, E_ARGUMENT_ERROR, "Sorry, cannot do uint at this time for shader.");
      return 1;
    }

    return 0;
  }
}

mrb_value on_draw_shader_begin(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);

  mrb_value fragment_shader = mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "fragment_shader"), 0, NULL);
  // hp_handle_error(mrb);

  mrb_value vertex_shader = mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "vertex_shader"), 0, NULL);
  // hp_handle_error(mrb);

  mrb_value uniforms = mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "uniforms"), 0, NULL);
  hp_handle_error(mrb);

  Shader shad;
  int len = 0;
  char* fs = "";
  char* vs = "";
  char* f = NULL;
  char* v = NULL;

  if (!mrb_nil_p(fragment_shader))
  {
    fs = mrb_string_cstr(mrb, fragment_shader);
    f = fs;
    len += strlen(fs);
  }

  if (!mrb_nil_p(vertex_shader))
  {
    vs = mrb_string_cstr(mrb, vertex_shader);
    v = vs;
    len += strlen(vs);
  }

  char hash[len + 20];
  sprintf(hash, "%s-%s", fs, vs);
  
  const shader_cache* result = hashmap_get(shaders, &(shader_cache){ .key=hash });
  if (result == NULL)
  {
    Shader shader = LoadShaderFromMemory(v, f);
    hashmap_set(shaders, &(shader_cache){ .key=strdup(hash), .payload=shader});
    shad = shader;
  }
  else
  {
    shad = result->payload;
  }

  mrb_hash_foreach(mrb, RHASH(uniforms), on_shader_uniform_foreach, &shad);
  BeginShaderMode(shad);
  return mrb_nil_value();
}

mrb_value on_draw_shader_end(mrb_state* mrb, mrb_value self)
{
  EndShaderMode();

  return mrb_nil_value();
}

mrb_value on_draw_rotation_begin(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);

  float x = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"x"), 0, NULL));
  float y = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"y"), 0, NULL));
  float degrees = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"degrees"), 0, NULL));
  hp_handle_error(mrb);

  rlPushMatrix();
  rlTranslatef(x, y, 0);
  rlRotatef(degrees, 0, 0, 1);

  return mrb_nil_value();
}

mrb_value on_draw_rotation_end(mrb_state* mrb, mrb_value self)
{
  rlPopMatrix();
  return mrb_nil_value();
}

mrb_value on_draw_translation_begin(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);

  float x = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"x"), 0, NULL));
  float y = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"y"), 0, NULL));
  hp_handle_error(mrb);

  rlPushMatrix();
  rlTranslatef(x, y, 0);

  return mrb_nil_value();
}

mrb_value on_draw_translation_end(mrb_state* mrb, mrb_value self)
{
  rlPopMatrix();
  return mrb_nil_value();
}

mrb_value on_draw_scale_begin(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);

  float x = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"x"), 0, NULL));
  float y = mrb_float(mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb,"y"), 0, NULL));

  rlPushMatrix();
  rlScalef(x, y, 0.0);
  
  return mrb_nil_value();
}

mrb_value on_draw_scale_end(mrb_state* mrb, mrb_value self)
{
  rlPopMatrix();
  return mrb_nil_value();
}

mrb_value on_draw_texture(mrb_state* mrb, mrb_value self)
{
  mrb_value command;
  mrb_get_args(mrb, "o", &command);
  
  Texture tex;

  int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "x"), 0, NULL)));
  hp_handle_error(mrb);

  int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "y"), 0, NULL)));
  hp_handle_error(mrb);

  int width = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "width"), 0, NULL)));
  hp_handle_error(mrb);

  int height = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, command, mrb_intern_lit(mrb, "height"), 0, NULL)));
  hp_handle_error(mrb);

  char hash[200];
  sprintf(hash, "%d-%d-%d-%d", x, y, width, height);
  const texture_cache* result = hashmap_get(textures, &(texture_cache){ .key=hash });
  if (result == NULL)
  {
    Image img = GenImageColor(width, height, BLANK);
    Texture texture = LoadTextureFromImage(img);
    hashmap_set(textures, &(texture_cache){.key=strdup(hash), .payload=texture });
    tex = texture;
    UnloadImage(img);
  }
  else
  {
    tex = result->payload;
  }

  DrawTexture(tex, x, y, WHITE);
  return mrb_nil_value();
}

mrb_value on_cursor_set(mrb_state* mrb, mrb_value self)
{
  mrb_sym sym;
  mrb_get_args(mrb, "n", &sym);
  char* symbol = mrb_sym2name(mrb, sym);
  if (strcmp(symbol, "none") == 0 && !IsCursorHidden())
  {
    HideCursor();
  }
  else if(IsCursorHidden())
  {
    ShowCursor();
  }

  if (strcmp(symbol, "default") == 0)
  {
    SetMouseCursor(MOUSE_CURSOR_DEFAULT);
  }
  else if(strcmp(symbol, "arrow") == 0)
  {
    SetMouseCursor(MOUSE_CURSOR_ARROW);
  }
  else if(strcmp(symbol, "ibeam") == 0)
  {
    SetMouseCursor(MOUSE_CURSOR_IBEAM);
  }
  else if(strcmp(symbol, "crosshair") == 0)
  {
    SetMouseCursor(MOUSE_CURSOR_CROSSHAIR);
  }
  else if (strcmp(symbol, "pointer") == 0)
  {
    SetMouseCursor(MOUSE_CURSOR_POINTING_HAND);
  }
  else if (strcmp(symbol, "none") == 0)
  {
    //noop
  }
  else
  {
    mrb_raisef(mrb, E_ARGUMENT_ERROR, "Cursor %s not recognized (must also be a symbol)", symbol);
  }

  return mrb_nil_value();
}

mrb_value on_copy(mrb_state* mrb, mrb_value self)
{
  mrb_value t;
  mrb_get_args(mrb, "S", &t);
  const char* text = mrb_string_cstr(mrb, t);
  SetClipboardText(text);

  return mrb_nil_value();
}

mrb_value on_can_render(mrb_state* mrb, mrb_value self)
{
  mrb_value canvas;
  mrb_get_args(mrb, "o", &canvas);

  int x = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, canvas, mrb_intern_lit(mrb, "x"), 0, NULL)));
  hp_handle_error(mrb);

  int y = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, canvas, mrb_intern_lit(mrb, "y"), 0, NULL)));
  hp_handle_error(mrb);

  int height = mrb_int(mrb, mrb_float_to_integer(mrb, mrb_funcall_argv(mrb, canvas, mrb_intern_lit(mrb, "height"), 0, NULL)));
  hp_handle_error(mrb);

  if (inside_scissori(x, y, height))
  {
    return mrb_true_value();
  }

  return mrb_false_value();
}

void hp_backend_render_callbacks(mrb_state* mrb, struct RClass* module)
{
  /* Top level callbacks */
  struct RProc* set_cursor_proc = mrb_proc_new_cfunc(mrb, on_cursor_set);
  mrb_funcall_with_block(mrb, mrb_obj_value(module), mrb_intern_lit(mrb, "on_set_mouse_cursor"), 0, NULL, mrb_obj_value(set_cursor_proc));

  struct RProc* copy_proc = mrb_proc_new_cfunc(mrb, on_copy);
  mrb_funcall_with_block(mrb, mrb_obj_value(module), mrb_intern_lit(mrb, "on_copy"), 0, NULL, mrb_obj_value(copy_proc));

  struct RProc* can_render_proc = mrb_proc_new_cfunc(mrb, on_can_render);
  mrb_funcall_with_block(mrb, mrb_obj_value(module), mrb_intern_lit(mrb, "on_can_render"), 0, NULL, mrb_obj_value(can_render_proc));

  /* Render callbacks */
  struct RClass* com_class = mrb_class_get_under(mrb, module, "Commands");
  
  struct RClass* circle_class = mrb_class_get_under(mrb, com_class, "Circle");
  struct RProc* circle_proc = mrb_proc_new_cfunc(mrb, on_draw_circle);
  mrb_funcall_with_block(mrb, mrb_obj_value(circle_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(circle_proc));
  
  struct RClass* rect_class = mrb_class_get_under(mrb, com_class, "Rect");
  struct RProc* rect_proc = mrb_proc_new_cfunc(mrb, on_draw_rect);
  mrb_funcall_with_block(mrb, mrb_obj_value(rect_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(rect_proc));

  struct RClass* text_class = mrb_class_get_under(mrb, com_class, "Text");
  struct RProc* text_proc = mrb_proc_new_cfunc(mrb, on_draw_text);
  mrb_funcall_with_block(mrb, mrb_obj_value(text_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(text_proc));

  struct RClass* scissor_begin_class = mrb_class_get_under(mrb, com_class, "ScissorBegin");
  struct RProc* scissor_begin_proc = mrb_proc_new_cfunc(mrb, on_draw_scissor_begin);
  mrb_funcall_with_block(mrb, mrb_obj_value(scissor_begin_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(scissor_begin_proc));

  struct RClass* scissor_end_class = mrb_class_get_under(mrb, com_class, "ScissorEnd");
  struct RProc* scissor_end_proc = mrb_proc_new_cfunc(mrb, on_draw_scissor_end);
  mrb_funcall_with_block(mrb, mrb_obj_value(scissor_end_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(scissor_end_proc));

  struct RClass* image_class = mrb_class_get_under(mrb, com_class, "Image");
  struct RProc* image_proc = mrb_proc_new_cfunc(mrb, on_draw_image);
  mrb_funcall_with_block(mrb, mrb_obj_value(image_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(image_proc));

  struct RClass* shader_begin_class = mrb_class_get_under(mrb, com_class, "ShaderBegin");
  struct RProc* shader_begin_proc = mrb_proc_new_cfunc(mrb, on_draw_shader_begin);
  mrb_funcall_with_block(mrb, mrb_obj_value(shader_begin_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(shader_begin_proc));

  struct RClass* shader_end_class = mrb_class_get_under(mrb, com_class, "ShaderEnd");
  struct RProc* shader_end_proc = mrb_proc_new_cfunc(mrb, on_draw_shader_end);
  mrb_funcall_with_block(mrb, mrb_obj_value(shader_end_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(shader_end_proc));

  struct RClass* rotation_begin_class = mrb_class_get_under(mrb, com_class, "RotationBegin");
  struct RProc* rotation_begin_proc = mrb_proc_new_cfunc(mrb, on_draw_rotation_begin);
  mrb_funcall_with_block(mrb, mrb_obj_value(rotation_begin_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(rotation_begin_proc));

  struct RClass* rotation_end_class = mrb_class_get_under(mrb, com_class, "RotationEnd");
  struct RProc* rotation_end_proc = mrb_proc_new_cfunc(mrb, on_draw_rotation_end);
  mrb_funcall_with_block(mrb, mrb_obj_value(rotation_end_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(rotation_end_proc));

  struct RClass* translation_begin_class = mrb_class_get_under(mrb, com_class, "TranslationBegin");
  struct RProc* translation_begin_proc = mrb_proc_new_cfunc(mrb, on_draw_translation_begin);
  mrb_funcall_with_block(mrb, mrb_obj_value(translation_begin_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(translation_begin_proc));

  struct RClass* translation_end_class = mrb_class_get_under(mrb, com_class, "TranslationEnd");
  struct RProc* translation_end_proc = mrb_proc_new_cfunc(mrb, on_draw_translation_end);
  mrb_funcall_with_block(mrb, mrb_obj_value(translation_end_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(translation_end_proc));

  struct RClass* scale_begin_class = mrb_class_get_under(mrb, com_class, "ScaleBegin");
  struct RProc* scale_begin_proc = mrb_proc_new_cfunc(mrb, on_draw_scale_begin);
  mrb_funcall_with_block(mrb, mrb_obj_value(scale_begin_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(scale_begin_proc));

  struct RClass* scale_end_class = mrb_class_get_under(mrb, com_class, "ScaleEnd");
  struct RProc* scale_end_proc = mrb_proc_new_cfunc(mrb, on_draw_scale_end);
  mrb_funcall_with_block(mrb, mrb_obj_value(scale_end_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(scale_end_proc));

  struct RClass* texture_class = mrb_class_get_under(mrb, com_class, "Texture");
  struct RProc* texture_proc = mrb_proc_new_cfunc(mrb, on_draw_texture);
  mrb_funcall_with_block(mrb, mrb_obj_value(texture_class), mrb_intern_lit(mrb, "on_draw"), 0, NULL, mrb_obj_value(texture_proc));
}

static int keys[110] = {
  0, 39, 44, 45, 46, 47, 48,
  49, 50, 51, 52, 53, 54, 55, 56, 57, 59, 61,
  65, 66, 67, 68, 69, 70, 71, 72, 73,
  74, 75, 76, 77, 78, 79, 80, 81,
  82, 83, 84, 85, 86, 87, 88, 89, 90, 91,
  92, 93, 96, 32, 256, 257, 258, 259,
  260, 261, 262, 263, 264, 265, 266,
  267, 268, 269, 280, 281, 282, 283, 284,
  290, 291, 292, 293, 294, 295, 296, 297,
  298, 299, 300, 301, 340, 341, 342, 343,
  344, 345, 346, 347, 348, 320, 321, 322, 323,
  324, 325, 326, 327, 328, 329, 330, 331,
  332, 333, 334, 335, 336, 4, 5, 24, 25
};

static char* key_codes[110] = {
  "null", "apostrophe", "comma", "minus", "period",
  "slash", "zero", "one", "two", "three", "four",
  "five", "six", "seven", "eight", "nine", "semicolon", 
  "equal", "a", "b", "c", "d", "e", "f", "g", "h", 
  "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", 
  "s", "t", "u", "v", "w", "x", "y", "z", "left_bracket", 
  "backslash", "right_bracket", "grave", "space", "escape", 
  "enter", "tab", "backspace", "insert", "delete", "right", 
  "left", "down", "up", "page_up", "page_down", "home", "end", 
  "caps_lock", "scroll_lock", "num_lock", "print_screen", "pause", 
  "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", 
  "f9", "f10", "f11", "f12", "left_shift", "left_control", 
  "left_alt", "left_super", "right_shift", "right_control", "right_alt", 
  "right_super", "kb_menu", "kp_0", "kp_1", "kp_2", "kp_3", 
  "kp_4", "kp_5", "kp_6", "kp_7", "kp_8", "kp_9", "kp_decimal", 
  "kp_divide", "kp_multiply", "kp_subtract", "kp_add", "kp_enter", 
  "kp_equal", "back", "menu", "volume_up", "volume_down"
};

void hp_process_input(mrb_state* mrb, mrb_value input)
{
  mrb_value keyboard = mrb_funcall_argv(mrb, input, mrb_intern_lit(mrb, "keyboard"), 0, NULL);
  mrb_value mouse = mrb_funcall_argv(mrb, input, mrb_intern_lit(mrb, "mouse"), 0, NULL);

  // mrb_value input_keys = mrb_funcall_argv(mrb, keyboard, mrb_intern_lit(mrb, "keys"), 0, NULL);
  mrb_funcall_argv(mrb, keyboard, mrb_intern_lit(mrb, "reset"), 0, NULL);

  for (int i=109; i>0; i--)
  {
    mrb_value sym = mrb_symbol_value(mrb_intern_cstr(mrb, key_codes[i]));
    // mrb_value key = mrb_hash_get(mrb, input_keys, sym);
    mrb_value args[2] = {sym, mrb_bool_value(IsKeyDown(keys[i]))};
    mrb_funcall_argv(mrb, keyboard, mrb_intern_lit(mrb, "set"), 2, args);
  }

  mrb_value left = mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "left"), 0, NULL);
  mrb_value right = mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "right"), 0, NULL);
  mrb_value middle = mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "middle"), 0, NULL);

  mrb_value scroll = mrb_float_value(mrb, GetMouseWheelMove());
  mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "scroll="), 1, &scroll);

  mrb_value lclicked = mrb_bool_value(IsMouseButtonPressed(0));
  mrb_value ldown =  mrb_bool_value(IsMouseButtonDown(0));
  mrb_value lup = mrb_bool_value(IsMouseButtonUp(0));
  mrb_value lreleased = mrb_bool_value(IsMouseButtonReleased(0));

  mrb_funcall_argv(mrb, left, mrb_intern_lit(mrb, "clicked="), 1, &lclicked);
  mrb_funcall_argv(mrb, left, mrb_intern_lit(mrb, "down="), 1, &ldown);
  mrb_funcall_argv(mrb, left, mrb_intern_lit(mrb, "up="), 1, &lup);
  mrb_funcall_argv(mrb, left, mrb_intern_lit(mrb, "released="), 1, &lreleased);

  mrb_value posy = mrb_float_value(mrb, GetMouseY());
  mrb_value posx = mrb_float_value(mrb, GetMouseX());
  mrb_value pos = mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "pos"), 0, NULL);
  mrb_funcall_argv(mrb, pos, mrb_intern_lit(mrb, "y="), 1, &posy);
  mrb_funcall_argv(mrb, pos, mrb_intern_lit(mrb, "x="), 1, &posx);

  Vector2 d = GetMouseDelta();
  mrb_value deltay = mrb_float_value(mrb, d.y);
  mrb_value deltax = mrb_float_value(mrb, d.x);
  mrb_value delta = mrb_funcall_argv(mrb, mouse, mrb_intern_lit(mrb, "delta"), 0, NULL);
  mrb_funcall_argv(mrb, delta, mrb_intern_lit(mrb, "y="), 1, &deltay);
  mrb_funcall_argv(mrb, delta, mrb_intern_lit(mrb, "x="), 1, &deltax);
}

int hp_backend_run(mrb_state* mrb, struct RClass* hokusai_module, mrb_value backend)
{

  textures = hashmap_new(sizeof(texture_cache), 0, 0, 0, texture_hash, texture_compare, texture_free, NULL);
  shaders = hashmap_new(sizeof(shader_cache), 0, 0, 0, shader_hash, shader_compare, shader_free, NULL);
  // glue setup glue
  mrb_value config = mrb_funcall_argv(mrb, backend, mrb_intern_lit(mrb, "config"), 0, NULL);
  if (mrb->exc) mrb_print_error(mrb);

  mrb_value block = mrb_funcall_argv(mrb, backend, mrb_intern_lit(mrb, "app"), 0, NULL);
  if (mrb->exc) mrb_print_error(mrb);

  bool log = mrb_bool(mrb_funcall(mrb, config, "log", 0, NULL));
  if (log)
  {
    f_logger_set_level(F_LOG_FINE | F_LOG_DEBUG | F_LOG_INFO | F_LOG_WARN);
  }

  struct RClass* input_class = mrb_class_get_under(mrb, hokusai_module, "Input");
  struct RClass* painter_class = mrb_class_get_under(mrb, hokusai_module, "Painter");
  struct RClass* canvas_class = mrb_class_get_under(mrb, hokusai_module, "Canvas");
  mrb_value input = mrb_obj_new(mrb, input_class, 0, NULL);
  if (mrb->exc) mrb_print_error(mrb);
  // raylib stuff
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);

  int width = mrb_int(mrb, mrb_funcall_argv(mrb, config, mrb_intern_lit(mrb, "width"), 0, NULL));
  int height = mrb_int(mrb, mrb_funcall_argv(mrb, config, mrb_intern_lit(mrb, "height"), 0, NULL));
  char* title = mrb_string_cstr(mrb,  mrb_funcall_argv(mrb, config, mrb_intern_lit(mrb, "title"), 0, NULL));
  bool draw_fps = mrb_bool(mrb_funcall(mrb, config, "draw_fps", 0, NULL));
  bool resize = false;

  InitWindow(width, height, title);
  SetTargetFPS(60);

  mrb_value after_load_proc = mrb_funcall_argv(mrb, config, mrb_intern_lit(mrb, "after_load_cb"), 0, NULL);
  if(!mrb_nil_p(after_load_proc)) mrb_funcall_argv(mrb, after_load_proc, mrb_intern_lit(mrb, "call"), 0, NULL);
  
  // mrb_value cargs[] = { mrb_float_value(mrb, 400.0), mrb_float_value(mrb, 400.0), mrb_float_value(mrb, 0.0), mrb_float_value(mrb, 0.0) };
  // mrb_value canvas = mrb_obj_new(mrb, canvas_class, 4, cargs);
  while(!WindowShouldClose())
  {
    f_log(F_LOG_DEBUG, "begin drawing");
    if (IsWindowFocused())
    {
      f_log(F_LOG_DEBUG, "disable event wait");
      DisableEventWaiting();
    }
    else
    {
      EnableEventWaiting();
    }
    
    // EnableEventWaiting();
    BeginDrawing();
      // f_log(F_LOG_DEBUG, "proces input");
      hp_process_input(mrb, input);
      int render_width = GetScreenWidth();
      int render_height = GetScreenHeight();

      if (render_width != width || render_height != height)
      {
        resize = true;
        width = render_width;
        height = render_height;
      }
      else
      {
        resize = false;
      }

      mrb_value ccargs[] = { mrb_float_value(mrb, 1.0 * render_width), mrb_float_value(mrb, 1.0 * render_height), mrb_float_value(mrb, 0.0), mrb_float_value(mrb, 0.0) };
      mrb_value canvas = mrb_obj_new(mrb, canvas_class, 4, ccargs);

      ClearBackground(RAYWHITE);
        mrb_value pargs[2] = {block, input};
        mrb_value painter = mrb_obj_new(mrb, painter_class, 2, pargs);
        if (mrb->exc) mrb_print_error(mrb);

        mrb_value render_args[] = {canvas, mrb_bool_value(resize)};
        f_log(F_LOG_FINE, "render");
        mrb_funcall_argv(mrb, painter, mrb_intern_lit(mrb, "render"), 2, render_args);
        // if (mrb->exc) mrb_print_error(mrb);

        if (draw_fps)
        {
          DrawFPS(10, 10);
        }

      f_log(F_LOG_FINE, "update");
      mrb_funcall_argv(mrb, mrb_obj_value(hokusai_module), mrb_intern_lit(mrb, "update"), 1, &block);
      hp_handle_error(mrb);
      f_log(F_LOG_FINE, "after update");
    EndDrawing();
    f_log(F_LOG_FINE, "End drawing");
  }

  hashmap_free(textures);
  hashmap_free(shaders);
  return 0;
}
#endif
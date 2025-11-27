#ifndef HOKUSAI_POCKET_BACKEND_H
#define HOKUSAI_POCKET_BACKEND_H

#include "hashmap.h"
#include <nfd.h>
#include <mruby.h>
#include <mruby/proc.h>
#include <mruby/numeric.h>
#include <mruby/hash.h>
#include <mruby/array.h>
#include <raylib.h>
#include <rlgl.h>
#include "ast.h"
#include "style.h"
#include "error.h"
#include "font.h"
#include "texture.h"
#include "image.h"
#include "music.h"

/**
 * 
 *  Declare caches
 */
typedef struct TextureCache
{
  char* key;
  Texture payload;
} texture_cache;

typedef struct ShaderCache
{
  char* key;
  Shader payload;
} shader_cache;

typedef struct FontCache
{
  char* key;
  Font payload;
  struct hashmap* char_cache;
} font_cache;

typedef struct MeasureCache
{
  char letter;
  float width;
} measure_cache;

// static char default_chars[122] = "\x1b– —‘’“”…\r\n\t0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%%^&*(),.?/\\[]-_=+|~`{}<>;:\"'";
static struct hashmap* textures = NULL;
static struct hashmap* shaders = NULL;

int hp_backend_run(mrb_state* mrb, struct RClass* hokusai_module, mrb_value backend);
int hp_backend_run_str(mrb_state* mrb, char* code);
int hp_backend_run_irep(mrb_state* mrb, uint8_t* code);
void hp_backend_render_callbacks(mrb_state* mrb, struct RClass* module);
#endif
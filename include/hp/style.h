#ifndef HOKUSAI_POCKET_STYLE_H
#define HOKUSAI_POCKET_STYLE_H

#include <mruby.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/hash.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <ast/hml.h>

void mrb_define_hokusai_style_class(mrb_state* mrb);

#endif
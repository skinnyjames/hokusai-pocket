#ifndef HOKUSAI_POCKET_AST_H
#define HOKUSAI_POCKET_AST_H

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/hash.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <mruby/array.h>
#include "core-hml.h"
#include "hashmap.h"

/**
  defines Hokusai::Ast and related methods
  @param mrb the mrb vm
*/
void mrb_define_hokusai_ast_class(mrb_state* mrb);

#endif
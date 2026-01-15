#ifndef MRUBY_HOKUSAI_POCKET_H
#define MRUBY_HOKUSAI_POCKET_H

#if defined(_MSC_VER)
#include <time.h>
#endif

#include <mruby.h>
#include "backend.h"
#include "monotonic_timer.h"

void mrb_mruby_hokusai_pocket_gem_init(mrb_state* mrb);
void mrb_mruby_hokusai_pocket_gem_final(mrb_state* mrb);
#endif

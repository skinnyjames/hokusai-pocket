#ifndef HP_UV_MIGRATE_H
#define HP_UV_MIGRATE_H
#include <mruby.h>
#include <mruby/string.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <mruby/range.h>
#include <mruby/proc.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <mruby/dump.h>
#include <mruby/internal.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <time.h>

mrb_value mrb_thread_migrate_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2);

#endif
#ifndef MRB_HTTP_H
#define MRB_HTTP_H

#include <mruby.h>
#include <mruby/string.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/compile.h>
#include <mruby/proc.h>
#include <mruby/variable.h>
#include "../mruby-uv/loop.h"

void mrb_define_http_req_class(mrb_state* mrb);

#endif
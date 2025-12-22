#ifndef HOKUSAI_POCKET_BACKEND_ERROR_H
#define HOKUSAI_POCKET_BACKEND_ERROR_H

#include <mruby.h>

/**
  Exits if the mrb vm has an error
  @param mrb the mrb vm
*/
void hp_handle_error(mrb_state* mrb);

#endif
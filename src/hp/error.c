#ifndef HOKUSAI_POCKET_BACKEND_ERROR
#define HOKUSAI_POCKET_BACKEND_ERROR

#include <hp/error.h>
#include <stdlib.h>

void hp_handle_error(mrb_state* mrb)
{
  if (mrb->exc)
  {
    printf("Unhandled Exception:\n");
    mrb_print_error(mrb);
    exit(1);
  }
}

#endif
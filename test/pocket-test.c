#include "greatest.h"
#include "../src/ast/ast.c"
#include "../src/ast/style.c"
#include "../src/ast/hml.c"
#include "../src/ast/log.c"
#include "../src/ast/hashmap.c"
#include "../src/hp/ast.c"
#include "../src/hp/style.c"

bool hp_test_error(mrb_state* mrb)
{
  if (mrb->exc)
  {
    mrb_print_error(mrb);
    return false;
  }

  return true;
}

#include "../src/hp/font.c"
#include "../src/hp/error.c"
#include "../src/hp/font.c"
#include "../src/hp/backend.c"

bool hp_has_error(mrb_state* mrb)
{
  if (mrb->exc) {
    mrb_print_error(mrb);
    return true;
  }

  return false;
}

#include <raylib.h>

#include "style.c"
#include "ast.c"
#include "integration.c"

GREATEST_MAIN_DEFS();

int main(int argc, char** argv) {
  GREATEST_MAIN_BEGIN();

  // RUN_SUITE(hoku_ast_suite);
  // RUN_SUITE(hoku_style_suite);
  // RUN_SUITE(hoku_integration_suite);
  RUN_SUITE(hoku_e2e_suite);

  GREATEST_MAIN_END();
}
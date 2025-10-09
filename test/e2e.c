// #ifndef HOKUSAI_POCKET_INTEGRATION_TEST
// #define HOKUSAI_POCKET_INTEGRATION_TEST

// #include <hp/ast.h>
// #include <mruby.h>
// #include <ast/log.h>
// #include <mruby/compile.h>
// #include <mruby/irep.h>

// static const char* app_code = "\n"
//   "class Foobar < Hokusai::Block\n"
//   "  template <<~EOF\n"
//   "  [template]\n"
//   "    vblock\n"
//   "      toggle\n"
//   "   EOF\n"
//   "   uses(vblock: Hokusai::Blocks::Vblock, toggle: Hokusai::Blocks::Toggle)\n"
//   "end\n"
//   "obj = Foobar.mount; puts [obj.inspect].inspect\n";

// TEST test_integration_check(mrb_state* mrb)
// {
//   mrb_load_string(mrb, app_code);
//   if (mrb->exc) mrb_print_error(mrb);
//   PASS();
// }

// SUITE(hoku_integration_suite)
// {
//   // f_logger_set_level(F_LOG_FINE | F_LOG_DEBUG | F_LOG_INFO | F_LOG_WARN);
//   mrb_state* mrb = mrb_open();
//   struct RClass* hokusai_module = mrb_define_module(mrb, "Hokusai");
//   mrb_define_class_under(mrb, hokusai_module, "Error", E_STANDARD_ERROR);
//   mrb_define_hokusai_ast_class(mrb);
//   mrb_define_hokusai_style_class(mrb);
//   // mrb_load_irep(mrb, hokusai_pocket);
//   if (mrb->exc) mrb_print_error(mrb);

// 	RUN_TEST1(test_integration_check, mrb);

//   mrb_close(mrb);
// }

// #endif

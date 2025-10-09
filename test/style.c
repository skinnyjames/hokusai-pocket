#ifndef HOKUSAI_POCKET_STYLE_TEST
#define HOKUSAI_POCKET_STYLE_TEST

#include <hp/ast.h>
#include <string.h>
#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/irep.h>
#include <ast/log.h>

static const char* style_code = "\n"
  "$test_style = Hokusai::Style.parse(\""
  "[style]\n"
  "primitives {\n"
  "  string: \\\"strvalue\\\";\n"
  "  float: 23.0;\n"
  "  int: 12;\n"
  "  bool: false;\n"
  "}\n"
  "funcs {\n"
  "  color: rgb(1,2,3);\n"
  "  pad: padding(2.0, 1.0, 2.0, 1.2);\n"
  "  out: outline(1.1, 1.2, 1.3, 1.4);\n"
  "}\n"
  "funcs@hover {\n"
  "  color: rgb(1,2,3);\n"
  "}\n"
  "\")"
  "";

void test_hp_style_setup(mrb_state* mrb)
{
  mrb_load_string(mrb, style_code);
}

TEST test_hp_style_primitives(mrb_state* mrb)
{
  char* strclass = "$test_style['primitives']['default']['string'].class.to_s";
  char* strvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, strclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("String", strvalue);

  char* boolclass = "$test_style['primitives']['default']['bool'].class.to_s";
  char* boolvalue = mrb_string_cstr(mrb, mrb_load_string(mrb,  boolclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("FalseClass", boolvalue);

  char* floatclass = "$test_style['primitives']['default']['float'].class.to_s";
  char* floatvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, floatclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("Float", floatvalue);

  char* intclass = "$test_style['primitives']['default']['int'].class.to_s";
  char* intvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, intclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("Integer", intvalue);
  PASS();
}

TEST test_hp_style_funcs(mrb_state* mrb)
{
  char* colorclass = "$test_style['funcs']['default']['color'].class.to_s";
  char* colorvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, colorclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("Hokusai::Color", colorvalue);

  char* outclass = "$test_style['funcs']['default']['out'].class.to_s";
  char* outvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, outclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("Hokusai::Outline", outvalue);

  char* padclass = "$test_style['funcs']['default']['pad'].class.to_s";
  char* padvalue = mrb_string_cstr(mrb, mrb_load_string(mrb, padclass));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("Hokusai::Padding", padvalue);
  PASS();
}


SUITE(hoku_style_suite)
{
  f_logger_set_level(F_LOG_DEBUG | F_LOG_ERROR | F_LOG_FINE | F_LOG_INFO | F_LOG_WARN);
  mrb_state* mrb = mrb_open();
  struct RClass* hokusai_module = mrb_define_module(mrb, "Hokusai");
  // mrb_define_class_under(mrb, hokusai_module, "Error", E_STANDARD_ERROR);
  mrb_load_irep(mrb, hokusai_pocket);
  mrb_define_hokusai_style_class(mrb);
  test_hp_style_setup(mrb);

	RUN_TEST1(test_hp_style_primitives, mrb);
  RUN_TEST1(test_hp_style_funcs, mrb);

  mrb_close(mrb);
}

#endif
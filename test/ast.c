#ifndef HOKUSAI_POCKET_AST_TEST
#define HOKUSAI_POCKET_AST_TEST

#include <hp/ast.h>
#include <mruby.h>
#include <ast/log.h>
#include <mruby/compile.h>

static const char* ast_code = "\n"
  "$test_ast = Hokusai::Ast.parse(\""
  "[template]\n"
  "  parent#id.one.two.three { ...firstStyle ...secondStyle @click=\\\"eat\\\" @hover=\\\"what\\\" :computed=\\\"computed_value\\\" static=\\\"static_value\\\" }\n"
  "    [if=\\\"boo\\\"]\n"
  "      boooooo\n"
  "        virtual\n"
  "        gchild3\n"
  "          slot\n"
  "    [else]\n"
  "      gchild1\n"
  "  other { :gcevent=\\\"func(arg1, arg2)\\\" }\n"
  "    [for=\\\"hey in list\\\"]\n"
  "       loopchild\n"
  "  another\n"
  "\", \"root\")";

bool test_hp_ast_setup(mrb_state* mrb)
{
  mrb_load_string(mrb, ast_code);
}

TEST test_hp_ast_parse(mrb_state* mrb)
{ 
  test_hp_ast_setup(mrb);
  PASS();
}

TEST test_hp_ast_id(mrb_state* mrb)
{
  char* id_code = "$test_ast.children.first.id";

  mrb_value ret = mrb_load_string(mrb, id_code);
  if (hp_has_error(mrb)) FAIL();

  char* id = mrb_string_cstr(mrb, ret);
  ASSERT_STR_EQ("id", id);

  PASS();
}

TEST test_hp_ast_classes(mrb_state* mrb)
{
  char* code = "$test_ast.children.first.classes";

  mrb_value ret = mrb_load_string(mrb, code);
  if (hp_has_error(mrb)) FAIL();

  int len = mrb_int(mrb, mrb_funcall(mrb, ret, "size", 0, NULL));
  if (hp_has_error(mrb)) return NULL;

  ASSERT_EQ_FMT(3, len, "%d");

  char* stuff[] = {"one", "two", "three"};

  for(int i=0; i<len; i++)
  {
    ASSERT_STR_EQ(stuff[i], mrb_string_cstr(mrb, mrb_ary_entry(ret, i)));
  }

  PASS();
}

TEST test_hp_ast_type(mrb_state* mrb)
{
  char* code = "$test_ast.children.first.type";

  char* ret = mrb_string_cstr(mrb, mrb_load_string(mrb, code));
  if (hp_has_error(mrb)) FAIL();

  ASSERT_STR_EQ("parent", ret);
  PASS(); 
}

TEST test_hp_ast_virtual(mrb_state* mrb)
{
  char* code = "$test_ast.children[0].children[0].children[0].virtual?";

  bool b = mrb_bool(mrb_load_string(mrb, code));
  if (hp_has_error(mrb)) FAIL();
  PASS();
}

TEST test_hp_ast_if_condition(mrb_state* mrb)
{
  char* code = "$test_ast.children[0].children[0]";

  mrb_value node = mrb_load_string(mrb, code);
  if (hp_has_error(mrb)) FAIL();

  bool if_cond = mrb_bool(mrb_funcall(mrb, node, "has_if_condition?", 0, NULL));
  ASSERT_EQ_FMT(true, if_cond, "%d");

  bool else_cond = mrb_bool(mrb_funcall(mrb, node, "has_else_condition?", 0, NULL));
  ASSERT_EQ_FMT(true, else_cond, "%d");

  bool else_active = mrb_bool(mrb_funcall(mrb, node, "else_condition_active?", 0, NULL));
  ASSERT_EQ_FMT(false, else_active, "%d");

  mrb_funcall(mrb, node, "else_active=", 1, mrb_bool_value(true));

  bool else_active2 = mrb_bool(mrb_funcall(mrb, node, "else_condition_active?", 0, NULL));
  ASSERT_EQ_FMT(true, else_active2, "%d");

  mrb_value else_node = mrb_funcall(mrb, node, "else_ast", 0, NULL);
  char* type = mrb_string_cstr(mrb, mrb_funcall(mrb, else_node, "type", 0, NULL));
  ASSERT_STR_EQ("gchild1", type);

  PASS();
}

TEST test_hp_ast_slot(mrb_state* mrb)
{
  char* code = "$test_ast.children[0].children[0].children[1].children[0]";

  mrb_value node = mrb_load_string(mrb, code);
  if (hp_has_error(mrb)) FAIL();

  bool slot = mrb_bool(mrb_funcall(mrb, node, "slot?", 0, NULL));
  ASSERT_EQ_FMT(true, slot, "%d");
  PASS();
}

TEST test_hp_ast_props(mrb_state* mrb)
{
  mrb_value computed = mrb_load_string(mrb, "$test_ast.children[0].prop('computed')");
  if (hp_has_error(mrb)) FAIL();

  bool comp = mrb_bool(mrb_funcall(mrb, computed, "computed?", 0, NULL));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_EQ_FMT(true, comp, "%d");

  char* name = mrb_string_cstr(mrb, mrb_funcall(mrb, computed, "name", 0, NULL));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("computed", name);

  char* val = mrb_string_cstr(mrb, mrb_load_string(mrb, "$test_ast.children[0].prop('computed').value.method"));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("computed_value", val);

  PASS();
}

TEST test_hp_ast_prop_args(mrb_state* mrb)
{

  mrb_value ret = mrb_load_string(mrb, "$test_ast.children[1].prop('gcevent').value.args");
  if (hp_has_error(mrb)) FAIL();

  int len = mrb_int(mrb, mrb_funcall(mrb, ret, "size", 0, NULL));
  if (hp_has_error(mrb)) FAIL();

  ASSERT_EQ_FMT(2, len, "%d");

  char* stuff[] = {"arg1", "arg2" };

  for(int i=0; i<len; i++)
  {
    ASSERT_STR_EQ(stuff[i], mrb_string_cstr(mrb, mrb_ary_entry(ret, i)));
  }

  PASS();
}

TEST test_hp_ast_events(mrb_state* mrb)
{
  mrb_value ret = mrb_load_string(mrb, "$test_ast.children[0].event('click')");
  if (hp_has_error(mrb)) FAIL();
  ASSERT_EQ(false, mrb_nil_p(ret));

  char* name = mrb_string_cstr(mrb, mrb_funcall(mrb, ret, "name", 0, NULL));
  if (hp_has_error(mrb)) FAIL();

  ASSERT_STR_EQ("click", name);

  mrb_value func = mrb_funcall(mrb, ret, "value", 0, NULL);

  char* value = mrb_string_cstr(mrb, mrb_funcall(mrb, func, "method", 0, NULL));
  if (hp_has_error(mrb)) FAIL();

  ASSERT_STR_EQ("eat", value);
  PASS();
}

TEST test_hp_ast_loop(mrb_state* mrb)
{
  mrb_value ret = mrb_load_string(mrb, "$test_ast.children[1].children[0]");
  if (hp_has_error(mrb)) FAIL();
  ASSERT_EQ(false, mrb_nil_p(ret));

  bool isloop = mrb_bool(mrb_funcall(mrb, ret, "loop?", 0, NULL));
  if (hp_has_error(mrb)) FAIL();

  ASSERT_EQ_FMT(true, isloop, "%d");

  mrb_value loop = mrb_funcall(mrb, ret, "loop", 0, NULL);
  if (hp_has_error(mrb)) FAIL();

  char* var = mrb_string_cstr(mrb, mrb_funcall(mrb, loop, "var", 0, NULL));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("hey", var);

  char* method = mrb_string_cstr(mrb, mrb_funcall(mrb, loop, "method", 0, NULL));
  if (hp_has_error(mrb)) FAIL();
  ASSERT_STR_EQ("list", method);

  PASS();
}

TEST test_hp_ast_style_list(mrb_state* mrb)
{
  mrb_value ret = mrb_load_string(mrb, "$test_ast.children[0].style_list");
  if (hp_has_error(mrb)) FAIL();
  ASSERT_EQ(false, mrb_nil_p(ret));

  int len = mrb_int(mrb, mrb_funcall(mrb, ret, "size", 0, NULL));
  if (hp_has_error(mrb)) return NULL;

  ASSERT_EQ_FMT(2, len, "%d");

  char* stuff[] = {"firstStyle", "secondStyle"};

  for(int i=0; i<len; i++)
  {
    ASSERT_STR_EQ(stuff[i], mrb_string_cstr(mrb, mrb_ary_entry(ret, i)));
  }

  PASS();
}

TEST test_hp_ast_siblings(mrb_state* mrb)
{
  mrb_value ret = mrb_load_string(mrb, "$test_ast.children[0].siblings.map(&:type)");
  if (hp_has_error(mrb)) FAIL();
  ASSERT_EQ(false, mrb_nil_p(ret));

  int len = mrb_int(mrb, mrb_funcall(mrb, ret, "size", 0, NULL));
  if (hp_has_error(mrb)) return NULL;

  ASSERT_EQ_FMT(2, len, "%d");

  char* stuff[] = {"other", "another"};

  for(int i=0; i<len; i++)
  {
    ASSERT_STR_EQ(stuff[i], mrb_string_cstr(mrb, mrb_ary_entry(ret, i)));
  }

  PASS();
}

SUITE(hoku_ast_suite)
{
  // f_logger_set_level(F_LOG_FINE | F_LOG_DEBUG | F_LOG_INFO | F_LOG_WARN);
  mrb_state* mrb = mrb_open();
  struct RClass* hokusai_module = mrb_define_module(mrb, "Hokusai");
  // mrb_define_class_under(mrb, hokusai_module, "Error", E_STANDARD_ERROR);
  mrb_define_hokusai_ast_class(mrb);
  test_hp_ast_setup(mrb);

  RUN_TEST1(test_hp_ast_parse, mrb);
  RUN_TEST1(test_hp_ast_id, mrb);
  RUN_TEST1(test_hp_ast_classes, mrb);
  RUN_TEST1(test_hp_ast_type, mrb);
  RUN_TEST1(test_hp_ast_virtual, mrb);
  RUN_TEST1(test_hp_ast_if_condition, mrb);
  RUN_TEST1(test_hp_ast_slot, mrb);
  RUN_TEST1(test_hp_ast_props, mrb);
  RUN_TEST1(test_hp_ast_prop_args, mrb);
  RUN_TEST1(test_hp_ast_events, mrb);
  RUN_TEST1(test_hp_ast_loop, mrb);
  RUN_TEST1(test_hp_ast_style_list, mrb);
  RUN_TEST1(test_hp_ast_siblings, mrb);

  mrb_close(mrb);
}

#endif
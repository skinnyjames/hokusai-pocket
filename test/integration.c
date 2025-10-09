#ifndef HOKUSAI_POCKET_INTEGRATION_TEST
#define HOKUSAI_POCKET_INTEGRATION_TEST

#include <hp/ast.h>
#include <mruby.h>
#include <ast/log.h>
#include <mruby/compile.h>
#include <mruby/irep.h>
#include <mruby/proc.h>
#include <raylib.h>

static const char* app = "\n"
  "class Foobar < Hokusai::Block\n"
  "  template <<~EOF\n"
  "  [template]\n"
  "    colorp\n"
  "   EOF\n"
  "   uses(circle: Hokusai::Blocks::Circle, colorp: Demo, hblock: Hokusai::Blocks::Hblock, titlebar: Hokusai::Blocks::Titlebar::OSX, empty: Hokusai::Blocks::Empty)\n"
  "   def on_mounted\n"
  "    puts Hokusai.fonts.active\n"
  "   end\n"
  "end\n"
  "Hokusai::Backend.run(Foobar) do |config|\n"
  "  config.width = 500\n"
  "  config.height = 500\n"
  "  config.title = \"Fun!\"\n"
  "  config.after_load do\n"
  "    Hokusai.fonts.register 'default', Hokusai::Backend::Font.default\n"
  "    Hokusai.fonts.activate 'default'\n"
  "  end\n"
  "end\n";

TEST test_e2e_check()
{
  mrb_state* mrb = mrb_open();
  hp_backend_run_str(mrb, app);
  mrb_close(mrb);

  PASS();
}

SUITE(hoku_e2e_suite)
{
  RUN_TEST(test_e2e_check);
}

#endif

@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::SystemTest < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "system-test"

  def build : Nil
    block do
      # write to tmp file and rebuild
      File.write(File.join(vendor_dir, "ast", "hokusai-pocket-test.rb"), Hokusai::Pocket::Resolver.new("#{__DIR__}/../../ruby/hokusai.rb").code)
    end

    command("#{mrbc} -o#{include_dir}/hokusai-pocket.h -Bhokusai_pocket hokusai-pocket-test.rb", chdir: ast_dir)
    command("#{gcc} -I#{include_dir} -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -o#{output} #{entrypoint} #{grammar_files.join(" ")} #{File.join(lib_dir, "libmruby.a")} #{File.join(lib_dir, "libraylib.a")} #{tree_sitter}")
    command("./bin/pocket-test")
  end

  def ast_dir
    File.join(vendor_dir, "ast")
  end

  def mrbc
    File.join(bin_dir, "mrbc")
  end

  def output
    File.join(__DIR__, "..", "..", "bin", "pocket-test")
  end

  def entrypoint
    File.join(__DIR__, "..", "..", "test", "pocket-test.c")
  end

  def grammar_files
    %w[parser.c scanner.c].map do |file|
      File.join(__DIR__, "..", "..", "grammar", "src", file)
    end
  end

  def tree_sitter
    File.join(lib_dir, "libtree-sitter.a")
  end
end
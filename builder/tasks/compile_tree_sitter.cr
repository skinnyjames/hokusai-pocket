@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::CompileTreeSitter < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "compile-tree-sitter"

  def build : Nil
    command("make clean", chdir: build_dir)
    command("make all install AR=#{ar} PREFIX=#{dist_dir}", env: env, chdir: build_dir)
    command("make clean", chdir: build_dir)
  end

  def env
    {
      "CC" => gcc,
      "PREFIX" => dist_dir
    }
  end

  def build_dir : String
    File.join(vendor_dir, "tree-sitter")
  end
end
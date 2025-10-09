@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::TreeSitter < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "tree-sitter"

  def build : Nil
    mkdir(File.join(vendor_dir, "ast"), parents: true)

    fetch("tree-sitter", "https://github.com/tree-sitter/tree-sitter/archive/refs/heads/master.tar.gz")

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

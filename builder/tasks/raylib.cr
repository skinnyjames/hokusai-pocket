@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::Raylib < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "raylib"

  def build : Nil
    fetch("raylib", "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz")

    mkdir(build_dir, parents: true)
    command("make clean", chdir: build_dir)
    command("make PLATFORM=#{platform}", chdir: build_dir, env: env)
    copy("libraylib.a", lib_dir, chdir: build_dir)
    copy("*.h", include_dir, chdir: build_dir)
    command("make clean", chdir: build_dir)
  end

  def build_dir : String
    File.join(vendor_dir, "raylib", "src")
  end

  def platform
    case config.system
    when .web
      "PLATFORM_WEB"
    else
      "PLATFORM_DESKTOP"
    end
  end

  def env
    {
      "CC" => gcc
    }
  end
end

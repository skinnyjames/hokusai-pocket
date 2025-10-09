@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::CompileRaylib < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "compile-raylib"

  def build : Nil
    mkdir(build_dir, parents: true)
    command("make PLATFORM=#{platform} AR=#{ar}", chdir: build_dir, env: env)
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

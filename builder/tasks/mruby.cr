@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::MRuby < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  file("mruby_config", "#{__DIR__}/../templates/mruby_config.hbs")

  nametag "mruby"

  def build : Nil
    fetch("mruby", "https://github.com/mruby/mruby/archive/refs/tags/3.4.0.tar.gz")
    
    # build a default host version so we have mrbc..
    template(
      src: file("mruby_config"),
      dest: config_path,
      mode: File::Permissions.new(0o755),
      vars: Crinja.variables({
        "toolchain" => "default",
        "gems" => config.gems
      }),
      string: true
    )

    command("rake", chdir: build_dir, env: env)

    host = "host"
    sync(File.join(build_dir, "build", host, "bin"), bin_dir)
    sync(File.join(build_dir, "build", host, "include"), include_dir)
    copy(File.join(build_dir, "build", host, "lib", "libmruby.a"), File.join(lib_dir, "libmruby.a"))
    command("chmod 755 #{bin_dir}/*")

    command("rake clean", chdir: build_dir)
  end

  def build_dir : String
    File.join(vendor_dir, "mruby")
  end

  def config_path
    File.join(build_dir, "config.rb")
  end

  def env
    {
      "MRUBY_CONFIG" => config_path
    }
  end
end

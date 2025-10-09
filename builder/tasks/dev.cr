@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::Dev < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task

  nametag "dev"

  def build : Nil
    mkdir(tmp_dir, parents: true)
    # resolve the user program
    code = Hokusai::Pocket::Resolver.new(config.app_target).code
    
    # write the program to a tmp file
    block do
      File.write(File.join(tmp_dir, "hp-app.rb"), code)
    end

    # compile it
    command("#{mrbc} -o#{include_dir}/hp-app.h -Bhp_app ./hp-app.rb", chdir: tmp_dir)

    # write an entrypoint?
    block do
      code = <<-C
      #ifndef HP_USER_APP
      #define HP_USER_APP
      
      #include <mruby.h>
      #include <hp/backend.h>
      #include <hp-app.h>

      int main()
      {
        mrb_state* mrb = mrb_open();
        hp_backend_run_irep(mrb, hp_app);
        if (mrb->exc) mrb_print_error(mrb);
        mrb_close(mrb);

        return 0;
      }
      #endif
      C

      File.write(entrypoint, code)
    end

    mkdir(File.join(config.directory, "dist"), parents: true)
    mkdir(File.join(config.directory, "dist", config.system.to_s, "assets"), parents: true)

    command("#{gcc} -O3 -I#{include_dir} #{frameworks} -o#{output} #{entrypoint} #{File.join(lib_dir, "libpocket.a")} #{File.join(lib_dir, "libtree-sitter.a")} #{File.join(lib_dir, "libmruby.a")} #{File.join(lib_dir, "libraylib.a")}")
    case config.system
    when .web
      command("emrun index.html", chdir: File.join(config.directory, "dist", config.system.to_s))
    else
      command(output)
    end
  end

  def web_output
    File.join(config.directory, "dist", config.system.to_s, "index.html")
  end

  def output
    return web_output if config.system.web

    File.join(config.directory, "dist", config.system.to_s, config.app_name.gsub(/\.\w+$/, ""))
  end

  def entrypoint
    File.join(tmp_dir, "app.c")
  end

  def frameworks
    if config.system.web
      return "-L#{lib_dir} -s USE_GLFW=3 -s ASYNCIFY -DPLATFORM_WEB"
    end

    libs = ""
    if macos?
      libs = "-framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
    else
      libs = "-lGL -lm -lpthread -ldl -lrt -lX11"
    end
    libs
  end

  def tmp_dir
    File.join(config.directory, "tmp") 
  end
end

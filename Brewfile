def top
  binding
end

spec("hokusai-pocket") do |config|
  NFD_LIB = Barista.os == "Windows" ? "nfd.lib" : "libnfd.a"

  puts ["NFD LIB #{NFD_LIB}"]

  task "setup" do
    def build
      command("mkdir vendor; touch vendor/.keep") unless Dir.exists?("vendor")
      command("git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib")
      command("git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      command("git clone --branch stable --depth 1 https://github.com/mruby/mruby.git vendor/mruby")
      command("git clone https://github.com/mlabbe/nativefiledialog.git vendor/nfd")
    end
  end

  task "clean" do
    def build
      command("rm -Rf vendor")
    end
  end

  task "raylib" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def platform(args)
      case args[:platform]
      when "sdl"
        "PLATFORM_SDL" # to be supported
      else
        "PLATFORM_DESKTOP"
      end
    end

    def build
      command("make clean", chdir: "vendor/raylib/src")
      command("make -j 5 PLATFORM=#{platform(args)}", chdir: "vendor/raylib/src")
    end
  end

  task "tree-sitter" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      command("mkdir -p vendor/tree-sitter/build")
      command("make -j 5 all install PREFIX=build CC=#{config.cc.gcc} AR=#{config.cc.ar}", chdir: "vendor/tree-sitter")
    end
  end

  task "nfd" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      if mac?
        folder = "build/gmake_macosx"
      elsif windows?
        folder = "build/gmake_windows"
      else
        folder = "build/gmake_linux_zenity"
      end
      
      if windows?
        command("make config=release_x64", chdir: "vendor/nfd/#{folder}")
      else
        command("make config=release_x64 all", chdir: "vendor/nfd/#{folder}")
      end
    end
  end

  task "mruby" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      gem_config = args[:gem_config].nil? ? "" : File.read(args[:gem_config])

      ruby do
        File.open("vendor/mruby/cli_build_config.rb", "w") do |io|
          str = <<-RUBY
            MRuby::Build.new do |conf|
              if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
                toolchain :visualcpp
              else
                toolchain :gcc
              end

              conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
              conf.gem github: "skinnyjames/mruby-bin-barista", branch: "main"

              #{gem_config}
              conf.gembox "default"
            end
          RUBY

          io << str
        end
      end

      command("rake MRUBY_CONFIG=cli_build_config.rb", chdir: "vendor/mruby")
    end
  end

  task "hokusai-github" do |args|
    dependency "raylib" do
      files "vendor/raylib/src/libraylib.a"
    end
    
    dependency "tree-sitter" do
      files "vendor/tree-sitter/build/lib/libtree-sitter.a"
    end
    
    dependency "mruby" do
      files "vendor/mruby/build/host/lib/libmruby.a"
    end

    dependency "nfd" do
      files "vendor/nfd/build/lib/Release/x64/#{NFD_LIB}"
    end
    
    def includes
      %w[
          vendor/tree-sitter/build/include 
          vendor/raylib/src 
          vendor/mruby/include
          vendor/hp/grammar/tree_sitter
          vendor/hp/src
          vendor/nfd/src/include
        ]
    end

    def links
      %w[
        vendor/hp/grammar/src/parser.c
        vendor/hp/grammar/src/scanner.c
        vendor/hokusai-pocket/libhokusai.a
        vendor/mruby/build/platform/lib/libmruby.a 
        vendor/raylib/src/libraylib.a
        vendor/tree-sitter/build/lib/libtree-sitter.a
      ].join(" ")
    end

    def h_includes
      includes.map { |file| "-I../../#{file}" }.join(" ")
    end

    def sources
      Dir.glob("vendor/hp/src/*.c")
    end

    def h_sources
      sources.map do |file|
        "../../#{file}"
      end.join(" ")
    end

    def objs
      Dir.glob("vendor/hokusai-pocket/*.o").map do |file|
        File.basename(file)
      end.join(" ")
    end

    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

    def build
      command("git clone --branch main --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp") unless Dir.exists?("vendor/hp")
      ruby do
        code = ruby_file("vendor/hp/ruby/hokusai.rb")
        File.open("vendor/hp/mrblib/hokusai.rb", "w") do |io|
          io << code
        end
      end

      unless Dir.exists?("vendor/hokusai-pocket")
        mkdir("vendor/hokusai-pocket")
      end
      command("#{mrbc} -o vendor/hokusai-pocket/pocket.h -Bpocket ./vendor/hp/mrblib/hokusai.rb")

      ruby do
        command("#{config.cc.gcc} -O3 -Wall #{h_includes} -c #{h_sources}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute

        command("#{config.cc.ar} r libhokusai.a #{objs}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
      end
    end
  end

  task "hokusai" do |args|
    dependency "raylib" do
      files "vendor/raylib/src/libraylib.a"
    end
    
    dependency "tree-sitter" do
      files "vendor/tree-sitter/build/lib/libtree-sitter.a"
    end
    
    dependency "mruby" do
      files "vendor/mruby/build/host/lib/libmruby.a"
    end

    dependency "nfd" do
      files "vendor/nfd/build/lib/Release/x64/#{NFD_LIB}"
    end

    def sources
      glob(File.join(path, "src", "*.c"))
    end

    def objs
      glob(File.join(path, "vendor", "hokusai-pocket", "*.o"))
    end

    def glob(path)
      Dir.glob(path)
    end

    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

    def build
      ruby do
        code = ruby_file("ruby/hokusai.rb")
        File.open("mrblib/hokusai.rb", "w") do |io|
          io << code
        end
        # Resolver.write_to_file("ruby/hokusai.rb", "mrblib/hokusai.rb")
      end

      unless Dir.exists?("vendor/hokusai-pocket")
        mkdir("vendor/hokusai-pocket")
      end
      command("#{mrbc} -o vendor/hokusai-pocket/pocket.h -Bpocket ./mrblib/hokusai.rb")
      command("#{config.cc.gcc} -O3 -Wall -I../../vendor/tree-sitter/build/include -I../../vendor/raylib/src -I../../vendor/mruby/include -I../../vendor/nfd/src/include -I../../grammar/tree_sitter -I../../src -I. -c #{sources.map { |s| "../../#{s}" }.join(" ")}", chdir: "vendor/hokusai-pocket")
      ruby do
        command("#{config.cc.ar} r libhokusai.a #{objs.map{ |s| "../../#{s}" }.join(" ")}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
      end
    end
  end

  module Helpers
    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

    def includes
      %w[vendor/raylib/src vendor/tree-sitter/build/include vendor/mruby/include vendor/cli vendor/hokusai-pocket vendor/nfd/src/include src].map do |file|
        "-I#{file}"
      end
    end

    def frameworks(args)
      case detected_os
      when "MacOS"
        "-framework CoreVideo -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
      when "Windows"
        # add -mwindows after figuring out why apps don't launch... 
        "-lgdi32 -lwinmm -lws2_32 -lcomctl32 -lcomdlg32 -lole32 -luuid"
      when "Linux"
        "-lGL -lm -lpthread -ldl -lrt -lX11"
      else
        ""
      end
    end

    def links
      %w[
          grammar/src/parser.c
          grammar/src/scanner.c
          vendor/hokusai-pocket/libhokusai.a
          vendor/mruby/build/host/lib/libmruby.a 
          vendor/raylib/src/libraylib.a
          vendor/tree-sitter/build/lib/libtree-sitter.a
        ] + ["vendor/nfd/build/lib/Release/x64/#{NFD_LIB}"]
    end
  end

  task "cli" do |args|
    include Helpers
    dependency "hokusai"

    def build
      mkdir("vendor/cli") unless Dir.exists?("vendor/cli")
      mkdir("bin") unless Dir.exists?("bin")
      command("#{mrbc} -o vendor/cli/pocket-cli.h -Bpocket_cli Brewfile")

      ruby do
        File.open("vendor/cli/hokusai-pocket.c", "w") do |io|
          str = <<~C
          #ifndef POCKET_ENTRYPOINT
          #define POCKET_ENTRYPOINT
          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <pocket-cli.h>
          #define OPTPARSE_IMPLEMENTATION
          #define OPTPARSE_API static
          #include <optparse.h>

          int main(int argc, char* argv[])
          {
            int ai;
            mrb_state* mrb = mrb_open();
            ai = mrb_gc_arena_save(mrb);
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            mrb_load_irep(mrb, pocket);
            mrb_gc_arena_restore(mrb, ai);

            struct optparse options;
            optparse_init(&options, argv);
            char *arg;
            mrb_value ary = mrb_ary_new(mrb);
            while ((arg = optparse_arg(&options)))
            {
              mrb_ary_push(mrb, ary, mrb_str_new_cstr(mrb, arg));
            }

            if (mrb->exc)
            {
              mrb_print_error(mrb);
              return 1;
            }
            ai = mrb_gc_arena_save(mrb);
            mrb_value gemspec = mrb_load_irep(mrb, pocket_cli);
            mrb_gc_arena_restore(mrb, ai);

            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            }

            mrb_funcall(mrb, gemspec, "execute", 1, mrb_ary_join(mrb, ary, mrb_str_new_cstr(mrb, " ")));
            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            }

            mrb_close(mrb);
            
          }
          #endif
          C

          io << str
        end
      end

      command("#{config.cc.gcc} -O3 -Wall #{includes.join(" ")} -o bin/hokusai-pocket vendor/cli/hokusai-pocket.c -L. #{links.join(" ")} #{frameworks(args)}")
    end
  end

  task "run" do |args|
    def build
      out = args[:target]
      raise "Need to supply an application! (ex: hokusai-pocket run:target=some-app.rb)" if out.nil?

      code = ruby_file(out)

      eval code, top
    end
  end

  task "build" do |args|
    include Helpers
    dependency "hokusai-github" do
      files "vendor/hokusai-pocket/libhokusai.a"
    end

    def includes
      %w[vendor/raylib/src vendor/tree-sitter/build/include vendor/mruby/include vendor/tmp vendor/hokusai-pocket vendor/hp/src].map do |file|
        "-I#{file}"
      end
    end

    def links
      %w[
          vendor/hp/grammar/src/parser.c
          vendor/hp/grammar/src/scanner.c
          vendor/hokusai-pocket/libhokusai.a
          vendor/mruby/build/host/lib/libmruby.a 
          vendor/raylib/src/libraylib.a
          vendor/tree-sitter/build/lib/libtree-sitter.a
        ] + ["vendor/nfd/build/lib/Release/x64/#{NFD_LIB}"]
    end

    def build
      out = args[:target] || "app.rb"
      code = ruby_file(out)
      fname = File.basename(out).gsub(/\.rb$/, "")
      dir = Pathname.new(out).parent.to_s

      mkdir("vendor/tmp") unless Dir.exists?("vendor/tmp")
      ruby do
        File.open("vendor/tmp/papp.rb", "w") do |io|
          io << code
        end
      end

      command("vendor/mruby/build/host/bin/mrbc -o vendor/tmp/papp.h -Bpocket_app vendor/tmp/papp.rb")
      
      ruby do
        File.open("vendor/tmp/#{fname}.c", "w") do |io|
          str = <<~C
          #ifndef POCKET_ENTRYPOINT
          #define POCKET_ENTRYPOINT
          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <papp.h>

          int main(int argc, char* argv[])
          {
            mrb_state* mrb = mrb_open();
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            mrb_load_irep(mrb, pocket);

            int ai = mrb_gc_arena_save(mrb);
            mrb_value gemspec = mrb_load_irep(mrb, pocket_app);
            mrb_gc_arena_restore(mrb, ai);

            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            } 
            mrb_mruby_hokusai_pocket_gem_final(mrb);
            mrb_close(mrb);
          }
          #endif
          C

          io << str
        end
      end

      mkdir("bin") unless Dir.exists?("bin")
      command("#{config.cc.gcc} -O3 -Wall #{includes.join(" ")} -o bin/#{fname} vendor/tmp/#{fname}.c -L. #{links.join(" ")} #{frameworks(args)}")
    end
  end

  task "publish" do |args|
    def build
      raise "Need target" if args[:target].nil?
      platforms = args[:platforms]&.split(",") || %w[osx linux windows]

      command("mkdir build") unless Dir.exists?("build")
      app_name = File.basename(args[:target]).gsub(/\.rb$/, "")

      ruby do
        code = ruby_file(args[:target])
        File.open("build/pocket-app.rb", "w") do |io|
          io << code
        end

        extras = args[:extras]&.split(",") || []
        assets = args[:assets_path]
        gem_config = args[:gem_config] ? File.read(args[:gem_config]) : ""

        platforms.each do |platform|
          deps = platform == "linux" ? "libasound2-dev libgl1-mesa-dev libglu1-mesa-dev libx11-dev libxi-dev libxrandr-dev mesa-common-dev xorg-dev" : ""

          processed = erb(
            Hokusai.docker_template, 
            string: true, 
            vars: {
              deps: deps,
              extras: extras,
              assets_path: assets,
              gem_config: gem_config,
              os: platform,
              outfile: app_name
            }
          )

          File.open("build/Dockerfile.#{platform}", "w") {|io| io << processed }
        end
      end

      platforms.each do |platform|
        command("docker build --output platforms/#{platform} --file build/Dockerfile.#{platform} .")
      end
    end
  end
end

def top
  binding
end

spec("hokusai-pocket") do |config|
  NFD_LIB = Barista.os == "Windows" ? "nfd.lib" : "libnfd.a"
  LIBUV_LIB = "build/libuv.a"

  task "setup" do
    def build
      command("mkdir vendor; touch vendor/.keep") unless Dir.exists?("vendor")
      command("git clone --branch release-3.4.4 --depth 1 https://github.com/libsdl-org/SDL.git vendor/sdl3")
      command("git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib")
      command("git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      command("git clone --branch 3.4.0 --depth 1 https://github.com/mruby/mruby.git vendor/mruby")
      command("git clone --branch devel --depth 1 https://github.com/mlabbe/nativefiledialog.git vendor/nfd")
      command("git clone https://github.com/libuv/libuv vendor/libuv")
    end
  end

  task "clean" do
    def build
      command("rm -Rf vendor")
    end
  end

  task "sdl3" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      command("mkdir -p build", chdir: "vendor/sdl3")
      command("cmake -S . -B build -DBUILD_SHARED_LIBS=OFF", chdir: "vendor/sdl3")
      command("cmake --build build", chdir: "vendor/sdl3")
    end
  end

  task "raylib" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    dependency "sdl3" do
      if args[:platform] == "sdl"
        files "vendor/sdl3/build/libSDL3.a"
      end
    end

    def opengl
      case args[:opengl]
      when "es"
        "GRAPHICS_API_OPENGL_ES2"
      else
        "GRAPHICS_API_OPENGL_33"
      end
    end
    
    def platform
      case args[:platform]
      when "sdl"
        "PLATFORM_DESKTOP_SDL" # to be supported
      else
        "PLATFORM_DESKTOP"
      end
    end

    def includes
      if args[:platform] == "sdl"
        %w[sdl3/include/SDL3 sdl3/include].map do |path|
          "../../#{path}"
        end.join(":")
      end
    end

    def build
      command("make clean", chdir: "vendor/raylib/src")
      command("make -j 5 PLATFORM=#{platform} GRAPHICS=#{opengl} C_INCLUDE_PATH=#{includes}", chdir: "vendor/raylib/src")
    end
  end

  task "libuv" do
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      if windows?
        command("mkdir build", chdir: "vendor/libuv")
        command("cmake -B build -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='cmake-toolchains/cross-mingw32.cmake'", chdir: "vendor/libuv")
      else
        command("mkdir -p build", chdir: "vendor/libuv")
        command("cmake -B build", chdir: "vendor/libuv")
      end

      command("cmake --build build", chdir: "vendor/libuv")
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
      platform = args[:arm64] ? "arm64" : "x64"      

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
        command("make config=release_#{platform} all", chdir: "vendor/nfd/#{folder}")
      end

      command("cp build/lib/Release/#{platform}/#{NFD_LIB} build/#{NFD_LIB}", chdir: "vendor/nfd")
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

              conf.gem github: "skinnyjames/mruby-bin-theorem", branch: "main"
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

    dependency "libuv" do
      files "vendor/libuv/#{LIBUV_LIB}"
    end
    
    def includes
      %w[
          vendor/tree-sitter/build/include 
          vendor/raylib/src 
          vendor/mruby/include
          vendor/hp/grammar/tree_sitter
          vendor/hp/src
          vendor/nfd/src/include
          vendor/libuv/include
        ]
    end

    def links
      (%w[
        vendor/hp/grammar/src/parser.c
        vendor/hp/grammar/src/scanner.c
        vendor/hokusai-pocket/libhokusai.a
        vendor/mruby/build/platform/lib/libmruby.a 
        vendor/raylib/src/libraylib.a
        vendor/tree-sitter/build/lib/libtree-sitter.a
      ] + ["vendor/libuv/#{LIBUV_LIB}"]).join(" ")
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
      files "vendor/nfd/build/#{NFD_LIB}"
    end

    dependency "libuv" do
      files "vendor/libuv/#{LIBUV_LIB}"
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

    def includes
      %w[vendor/mruby/build/host/include vendor/nfd/src/include vendor/tree-sitter/build/include grammar/tree_sitter vendor/raylib/src vendor/mruby/include vendor/hokusai-pocket vendor/libuv/include src src/mruby-uv].map do |file|
        "-I../../#{file}"
      end.join(" ")
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

      command("#{mrbc} -o src/pocket.c -Bpocket ./mrblib/hokusai.rb")

      ruby do
        code = File.read("src/pocket.c")

        File.open("src/pocket.c", "w") do |io|
          io.puts "#include <stdint.h>"
          io.puts "#include <pocket.h>"
          io.puts "#include <mruby.h>"
          io.puts "#include <mruby/irep.h>"
          io.puts "void load_pocket(mrb_state* mrb) {"
          io.puts code
          io.puts "mrb_load_irep(mrb, pocket);"
          io.puts "}"
        end

        File.open("vendor/hokusai-pocket/pocket.h", "w") do |io|
          io.puts "#ifndef MRB_HPOCKET_LIB"
          io.puts "#define MRB_HPOCKET_LIB"
          io.puts "#include <mruby.h>"
          io.puts "void load_pocket(mrb_state* mrb);"
          io.puts "#endif"
        end
      end
      
      command("#{config.cc.gcc} -O3 -Wall #{includes} -c ../../src/mruby-uv/loop.c", chdir: "vendor/hokusai-pocket")

      ruby do
        command("#{config.cc.gcc} -O3 -Wall #{includes} -I. -c #{sources.map { |s| "../../#{s}" }.join(" ")}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
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
      %w[vendor/mruby/build/host/include vendor/raylib/src vendor/tree-sitter/build/include vendor/mruby/include vendor/cli vendor/hokusai-pocket vendor/nfd/src/include vendor/libuv/include src src/mruby-uv].map do |file|
        "-I#{file}"
      end
    end

    def frameworks(args)
      case detected_os
      when "MacOS"
        if args[:platform] == "sdl"
          extras = "-framework CoreGraphics -framework UniformTypeIdentifiers -framework QuartzCore -framework Metal -framework GameController -framework AudioToolbox -framework AVFoundation -framework Foundation -framework CoreHaptics -framework CoreMedia -framework Carbon -framework ForceFeedback"
        end
        "-framework CoreVideo -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL #{extras}"
      when "Windows"
        # add -mwindows after figuring out why apps don't launch... 
        "-lgdi32 -lwinmm -lws2_32 -lcomctl32 -lcomdlg32 -lole32 -luuid -ldbghelp -luserenv -liphlpapi"
      when "Linux"
        "-lGL -lm -lpthread -ldl -lrt -lX11"
      else
        ""
      end
    end

    def links
      links = %w[
          grammar/src/parser.c
          grammar/src/scanner.c
          vendor/hokusai-pocket/libhokusai.a
          vendor/mruby/build/host/lib/libmruby.a 
          vendor/raylib/src/libraylib.a
          vendor/tree-sitter/build/lib/libtree-sitter.a
        ] + ["vendor/nfd/build/#{NFD_LIB}", "vendor/libuv/#{LIBUV_LIB}"]

      if args[:platform] == "sdl"
        links << "vendor/sdl3/build/libSDL3.a"
      end

      links
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
          
          #include <pocket.h>
          #include <mruby_hokusai_pocket.h>
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

      command("#{config.cc.gcc} -O2 -Wall -g #{includes.join(" ")} -o bin/hokusai-pocket vendor/cli/hokusai-pocket.c -L. #{links.join(" ")} #{frameworks(args)}")
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
          if platform == "linux"
            deps = %w[
              libasound2-dev
              libgl1-mesa-dev
              libglu1-mesa-dev
              libx11-dev
              libxi-dev
              libxrandr-dev
              mesa-common-dev
              xorg-dev

              ninja-build
              gnome-desktop-testing
              libasound2-dev
              libpulse-dev
              libaudio-dev
              libfribidi-dev
              libjack-dev
              libsndio-dev
              libxext-dev 
              libxcursor-dev 
              libxfixes-dev 
              libxss-dev 
              libxtst-dev 
              libxkbcommon-dev 
              libdrm-dev 
              libgbm-dev 
              libgl1-mesa-dev 
              libgles2-mesa-dev 
              libegl1-mesa-dev 
              libdbus-1-dev 
              libibus-1.0-dev 
              libudev-dev 
              libthai-dev
            ].join(" ")
          else
            deps = ""
          end

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

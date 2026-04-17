def top
  binding
end

# Helpers for path resolution of dependency
# libs, includes, and frameworks
module BuildHelpers
  def mrbc
    "vendor/mruby/build/host/bin/mrbc"
  end

  def brewfile(args)
    args[:remote] ? "vendor/hp/Brewfile" : "Brewfile"
  end

  def includes(args)
    prefix = args[:remote] ? "vendor/hp" : path
    paths = %w[
        vendor/mruby/build/host/include 
        vendor/nfd/src/include
        vendor/tree-sitter/build/include 
        vendor/raylib/src 
        vendor/mruby/include 
        vendor/hokusai-pocket 
        vendor/libuv/include
    ]

    paths.concat [
      "#{prefix}/grammar/tree_sitter",
      "#{prefix}/src",
      "#{prefix}/src/mruby-uv",
    ]

    if args[:http]
      paths << "vendor/llhttp/include"
      paths << "vendor/tlsuv/deps/uv_link_t/include"
      paths << "vendor/tlsuv/build/generated"
      paths << "vendor/tlsuv/include"
      paths << "vendor/zlib"
      paths << "#{prefix}/src/http"
    end

    list = paths.map do |dir|
      "-I../../#{dir}"
    end

    list.join(" ")
  end

  def frameworks(args)
    list = case detected_os
    when "MacOS"
      if args[:platform] == "sdl"
        extras = "-framework CoreGraphics -framework UniformTypeIdentifiers -framework QuartzCore -framework Metal -framework GameController -framework AudioToolbox -framework AVFoundation -framework Foundation -framework CoreHaptics -framework CoreMedia -framework Carbon -framework ForceFeedback"
      end
      "-framework CoreVideo -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL #{extras}"
    when "Windows"
      # add -mwindows after figuring out why apps don't launch... 
      "-lgdi32 -lwinmm -lws2_32 -lcomctl32 -lcomdlg32 -lole32 -luuid -ldbghelp -luserenv -liphlpapi -lmsvcr90"
    when "Linux"
      "-lGL -lm -lpthread -ldl -lrt -lX11"
    else
      ""
    end

    if args[:http]
      list += " -framework Security " if detected_os == "MacOS"
    end

    list
  end

  def links(args)
    prefix = args[:remote] ? "vendor/hp" : path
    links = ["#{prefix}/grammar/src/parser.c", "#{prefix}/grammar/src/scanner.c"]
    links.concat %w[
      vendor/hokusai-pocket/libhokusai.a
      vendor/mruby/build/host/lib/libmruby.a 
      vendor/raylib/src/libraylib.a
      vendor/tree-sitter/build/lib/libtree-sitter.a
    ]

    links << "vendor/nfd/build/#{NFD_LIB}"

    if args[:platform] == "sdl"
      links << "vendor/sdl3/build/libSDL3.a"
    end

    if args[:http]
      links << "vendor/tlsuv/build/#{TLSUV_LIB}"
      links << "vendor/llhttp/dist/lib/#{LLHTTP_LIB}"

      MBEDTLS_LIBS.each do |lib|
        links << "vendor/mbedtls/build/dist/lib/#{lib}"
      end

      links << "vendor/zlib/build/#{ZLIB_LIB}"
    end

    links << "vendor/libuv/#{LIBUV_LIB}"

    links.map! do |link|
      "../../#{link}"
    end
    
    links.join(" ")
  end
end

module Mingw
  def patchmingw(folder)
    ruby do
      patch = File.read("support/mingw32.cmake")
      File.open("#{folder}/mingw32.cmake", "w") { |io| io << patch }
    end
  end
end

spec("hokusai-pocket") do |config|
  recipe "desktop", "cli,hokusai:http=true"
  recipe "mobile", "cli,raylib,nfd,hokusai:http=true:arm64=true:platform=sdl:opengl=es"
  recipe "rebuild", "cli,hokusai:http=true:remote=true mruby:gem_config=./gems"

  NFD_LIB = Barista.os == "Windows" ? "nfd.lib" : "libnfd.a"
  LIBUV_LIB = "build/dist/lib/libuv.a"

  LLHTTP_LIB = "libllhttp.a"
  # TLSUV_LIB =  "libtlsuv.a"
  MBEDTLS_LIBS = %w[libmbedtls.a libmbedcrypto.a libmbedx509.a]
  ZLIB_LIB = Barista.os == "Windows" ? "libzs.a" : "libz.a"

  # LLHTTP_LIB = Barista.os == "Windows" ? "llhttp.lib" : "libllhttp.a"
  TLSUV_LIB = Barista.os == "Windows" ? "Release/tlsuv.lib" : "libtlsuv.a"
  # MBEDTLS_LIBS = Barista.os == "Windows" ? %w[mbedtls.lib mbedcrypto.lib mbedx509.lib] : %w[libmbedtls.a libmbedcrypto.a libmbedx509.a]
  # ZLIB_LIB = Barista.os == "Windows" ? "Release/zs.lib" : "libz.a"

  # Task: setup
  # Download all dependencies and puts them in /vendor
  # output: "vendor/.keep"
  task "setup" do
    def build
      command("mkdir vendor; touch vendor/.keep") unless Dir.exists?("vendor")
      command("git clone --branch release-3.4.4 --depth 1 https://github.com/libsdl-org/SDL.git vendor/sdl3")
      command("git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib")
      command("git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      command("git clone --branch 3.4.0 --depth 1 https://github.com/mruby/mruby.git vendor/mruby")
      command("git clone --branch devel --depth 1 https://github.com/mlabbe/nativefiledialog.git vendor/nfd")
      command("git clone https://github.com/libuv/libuv vendor/libuv")
      command("git clone https://github.com/openziti/tlsuv.git vendor/tlsuv")
    end
  end

  # Task: clean
  # Remove vendor directory
  # output: <none>
  task "clean" do
    def build
      command("rm -Rf vendor")
    end
  end

  # Task: sdl3
  # builds sdl3 - used when args[:sdl] = true
  # output: vendor/sdl3/build/libSDL3.a
  task "sdl3" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      command("mkdir -p build", chdir: "vendor/sdl3")
      command("cmake -S . -B build -DBUILD_SHARED_LIBS=OFF -DSDL_X11_XSCRNSAVER=OFF", chdir: "vendor/sdl3")
      command("cmake --build build", chdir: "vendor/sdl3")
    end
  end

  # Task: raylib
  # builds raylib
  # output: vendor/raylib/src/libraylib.a
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

  # Task: libuv
  # Builds libuv
  # output: vendor/libuv/build/libuv.a
  task "libuv" do
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      if windows?
        command("mkdir build", chdir: "vendor/libuv")
        command("cmake -S . -B build -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='cmake-toolchains/cross-mingw32.cmake' -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=build/dist", chdir: "vendor/libuv")
        command("cmake --build build", chdir: "vendor/libuv")
        command("cmake --install build", chdir: "vendor/libuv")
      else
        command("mkdir -p build", chdir: "vendor/libuv")
        command("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=build/dist", chdir: "vendor/libuv")
        command("cmake --build build", chdir: "vendor/libuv")

        dest = windows? ? "build/Release" : "build"

        command("cmake --install #{dest}", chdir: "vendor/libuv")
      end
    end
  end

  task "llhttp" do |args|
    include Mingw

    def fetch
      command("wget -O vendor/llhttp.tar.gz https://github.com/nodejs/llhttp/archive/refs/tags/release/v9.3.1.tar.gz")
      command("tar -xvf llhttp.tar.gz", chdir: "vendor")
      command("mv vendor/llhttp-release-v9.3.1 vendor/llhttp")
    end

    def build
      fetch unless Dir.exists?("vendor/llhttp")
      patchmingw("vendor/llhttp")

      command("mkdir vendor/llhttp/build")
      command("mkdir vendor/llhttp/dist")

      if windows?
        command("cmake -S . -B build -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='mingw32.cmake' -DCMAKE_BUILD_TYPE=Release -DLLHTTP_BUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=dist", chdir: "vendor/llhttp")
      else
        command("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLHTTP_BUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=dist", chdir: "vendor/llhttp")
      end

      command("cmake --build build --config Release", chdir: "vendor/llhttp")
      command("cmake --install build --verbose ", chdir: "vendor/llhttp")
    end
  end

  task "mbedtls" do |args|
    include Mingw

    def fetch
      command("wget -O vendor/mbedtls.tar.bz2 https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.6/mbedtls-3.6.6.tar.bz2")
      command("tar -xvf mbedtls.tar.bz2", chdir: "vendor")
      command("mv vendor/mbedtls-3.6.6 vendor/mbedtls")
    end

    def build
      fetch unless Dir.exists?("vendor/mbedtls")
      patchmingw("vendor/mbedtls")

      command("mkdir build", chdir: "vendor/mbedtls") unless Dir.exists?("vendor/mbedtls/build")

      if windows?
        command("cmake -S . -B build -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='mingw32.cmake' -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/dist -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF", chdir: "vendor/mbedtls")
      else
        command("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/dist -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF", chdir: "vendor/mbedtls")
      end

      command("cmake --build build --config Release", chdir: "vendor/mbedtls")
      command("cmake --install build", chdir: "vendor/mbedtls")
    end
  end

  task "zlib" do |args|
    include Mingw

    def fetch
      command("git clone https://github.com/madler/zlib.git vendor/zlib")
    end
  
    def build
      fetch unless Dir.exists?("vendor/zlib")
      patchmingw("vendor/zlib")

      command("mkdir build", chdir: "vendor/zlib") unless Dir.exists?("vendor/zlib")
      if windows?
        command("cmake -S . -B build -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='mingw32.cmake' -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_SHARED=OFF -DZLIB_INSTALL=OFF", chdir: "vendor/zlib")
      else
        command("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_SHARED=OFF -DZLIB_INSTALL=OFF", chdir: "vendor/zlib")
      end
      command("cmake --build build --config Release", chdir: "vendor/zlib")
    end
  end

  # The build for this software is incredibly brittle
  # But it's a good project.
  # TODO: Find another way
  task "tlsuv" do |args|
    include Mingw

    dependency "setup" do
      files "vendor/.keep"
    end

    dependency "llhttp" do
      files "vendor/llhttp/dist/lib/#{LLHTTP_LIB}"
    end

    dependency "mbedtls" do
      files "vendor/mbedtls/build/dist/lib/#{MBEDTLS_LIBS.first}"
    end

    dependency "libuv" do
      files "vendor/libuv/#{LIBUV_LIB}"
    end

    dependency "zlib" do
      files "vendor/zlib/build/#{ZLIB_LIB}"
    end

    def fetch
      command("wget -O vendor/tlsuv.tar.gz https://github.com/openziti/tlsuv/archive/refs/tags/v0.41.1.tar.gz")
      command("tar -xvf tlsuv.tar.gz", chdir: "vendor")
      command("mv vendor/tlsuv-0.41.1 vendor/tlsuv")
    end

    def patch
      # this is ridiculous.
      # the build expects absolute paths to actual installs
      # makes no sense for an embdedded solution. 
      ruby do
        patch = File.read("support/tlsuv/FindMbedTLS.cmake")
        File.open("vendor/tlsuv/cmake/FindMbedTLS.cmake", "w") {|io| io << patch }
      end

      ruby do
        patch = File.read("support/tlsuv/mbedtls/CMakeLists.txt")
        File.open("vendor/tlsuv/src/mbedtls/CMakeLists.txt", "w") {|io| io << patch}
      end

      ruby do
        patch = File.read("support/tlsuv/uv_link/CMakeLists.txt")
        File.open("vendor/tlsuv/deps/CMakeLists.txt", "w") { |io|  io << patch }
      end

      ruby do
        patch = File.read("support/tlsuv/CMakeLists.txt")
        File.open("vendor/tlsuv/CMakeLists.txt", "w") { |io| io << patch }
        puts "patched"
      end
    end

    def build
      fetch unless Dir.exists?("vendor/tlsuv")
      patchmingw("vendor/tlsuv")

      patch

      opts = %w[
        -DMBEDCRYPTO_LIBRARY='../../vendor/mbedtls/build/dist/libmbedcrypto.a'
        -DMBEDTLS_INCLUDE_DIRS='../../vendor/mbedtls/build/dist/include'
        -DMBEDTLS_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedtls.a'
        -DMBEDX509_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedx509.a'
        -DBUILD_SHARED_LIBS=OFF 
        -DCMAKE_BUILD_TYPE=Release
        -DTLSUV_HTTP=ON 
        -DTLSUV_TLSLIB=mbedtls
        -DZLIB_INCLUDE='../../vendor/zlib'
      ]
       
      opts << "-DCMAKE_CFLAGS='-DNOGDI -DWIN32_LEAN_AND_MEAN'" if windows?
      opts << "-DZLIB_LIB='../../vendor/zlib/build/#{ZLIB_LIB}'"
      opts << "-DLLHTTP_LIB='../../vendor/llhtp/dist/lib/#{LLHTTP_LIB}'"
      opts << "-DLLHTTP_INCLUDE='../../vendor/llhttp/dist/include'"
      opts << "-DTLSUV_LIBUV_LIB='../../vendor/libuv/build/dist/lib/#{LIBUV_LIB}'"
      opts << "-DTLSUV_LIBUV_INCLUDE='../../vendor/libuv/build/dist/include'"
      opts << "-DMBEDTLS_INCLUDE='../../vendor/mbedtls/build/dist/include/'"

      opts = opts.join(" ")

      # cmake is hot garbage.
      command("mkdir build", chdir: "vendor/tlsuv") unless Dir.exists?("vendor/tlsuv/build")

      # if windows?
      #   command("cmake -S vendor/tlsuv -B vendor/tlsuv/build  -G Ninja -DHOST_ARCH=x86_64 -DCMAKE_TOOLCHAIN_FILE='mingw32.cmake' #{opts}")
      # else
        command("cmake -S vendor/tlsuv -B vendor/tlsuv/build #{opts}")
      # end

      command("cmake --build . --config Release --verbose", chdir: "vendor/tlsuv/build")
      command("ls build/Release", chdir: "vendor/tlsuv") if windows?
    end
  end

  # Task: tree-sitter
  # Builds a static lib for tree-sitter
  # output: vendor/tree-sitter/build/lib/libtree-sitter.a
  task "tree-sitter" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      command("mkdir -p vendor/tree-sitter/build")
      command("make -j 5 all install PREFIX=build CC=#{config.cc.gcc} AR=#{config.cc.ar}", chdir: "vendor/tree-sitter")
    end
  end


  # Task nfd
  # Builds a file dialog library
  # output: build/libnfd.a|nfd.lib
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

  # Task: mruby
  # Compiles MRuby with gems
  # Arg: <gem_config> a snippet that is embedded in mrb's build_config
  # output: vendor/mruby/build/host/lib/libmruby.a
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

  # Task: hokusai
  # builds libhokusai.a from the hokusai-pocket codebase
  # Arg <remote:bool> whether to fetch hokusai-pocket from github or build against a local installation
  # output vendor/hokusai-pocket/libhokusai-pocket.a
  task "hokusai" do |args|
    include BuildHelpers

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

    dependency "tlsuv" do
      if args[:http]
        files "vendor/tlsuv/build/#{TLSUV_LIB}"
      end
    end

    # The hokusai C sources
    # If remote, pull from vendor/hp instead of the current directory
    def sources
      files = if args[:remote]
        glob(File.join(path, "vendor", "hp", "src", "*.c"))
      else
        glob(File.join(path, "src", "*.c"))
      end

      list = files.map do |file|
        "../../#{file}"
      end

      list.join(" ")
    end

    def objs
      list = glob(File.join(path, "vendor", "hokusai-pocket", "*.o")).map do |obj|
        "../../#{obj}"
      end

      list.join(" ")
    end

    def glob(path)
      Dir.glob(path)
    end

    def build
      prefix = args[:remote] ? "vendor/hp" : path
      if args[:remote] && !Dir.exists?("vendor/hp")
        command("git clone --branch main --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp")
      end

      ruby do
        code = ruby_file("#{prefix}/ruby/hokusai.rb")
        File.open("#{prefix}/mrblib/hokusai.rb", "w") do |io|
          io << code
        end
      end

      unless Dir.exists?("vendor/hokusai-pocket")
        mkdir("vendor/hokusai-pocket")
      end

      command("#{mrbc} -o #{prefix}/src/pocket.c -Bpocket #{prefix}/mrblib/hokusai.rb")

      ruby do
        code = File.read("#{prefix}/src/pocket.c")

        File.open("#{prefix}/src/pocket.c", "w") do |io|
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

      command("#{config.cc.gcc} -O3 -Wall #{includes(args)} -c ../../#{prefix}/src/mruby-uv/loop.c", chdir: "vendor/hokusai-pocket")
      
      defs = ""

      if args[:http]
        command("#{config.cc.gcc} -O3 -Wall  -DNOGDI -DWIN32_LEAN_AND_MEAN -DNOUSER #{includes(args)} -c ../../#{prefix}/src/http/http.c", chdir: "vendor/hokusai-pocket")

        defs = "-DHP_HTTP"
      end
      
      ruby do
        command("#{config.cc.gcc} -O3 -Wall #{defs} #{includes(args)} -I. -c #{sources}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
        command("#{config.cc.ar} r libhokusai.a #{objs}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
      end
    end
  end

  # Task cli
  # Builds the hokusai-pocket binary
  # output: bin/hokusai-pocket
  task "cli" do |args|
    include BuildHelpers

    dependency "hokusai"

    def build
      mkdir("vendor/cli") unless Dir.exists?("vendor/cli")
      mkdir("bin") unless Dir.exists?("bin")
      command("#{mrbc} -o vendor/cli/pocket-cli.h -Bpocket_cli #{brewfile(args)}")

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

      command("#{config.cc.gcc} -O2 -Wall #{ENV["CFLAGS"]} -g #{includes(args)} -I. -o ../../bin/hokusai-pocket hokusai-pocket.c -L. #{links(args)} #{ENV["LDFLAGS"]} #{frameworks(args)}", chdir: "vendor/cli")
    end
  end

  ######################
  # Below are commands that belong to the 
  # artifact produced by the cli task
  #
  # They are meant to be called from `hokusai-pocket`
  # not `barista`
  #######################

  # Task: run
  # Run a hokusai application
  # Arg: <target:string> the ruby file to run
  # output: <none>
  task "run" do |args|
    def build
      out = args[:target]
      raise "Need to supply an application! (ex: hokusai-pocket run:target=some-app.rb)" if out.nil?

      code = ruby_file(out)

      begin
        eval code, top
      rescue => e
        puts "An error occurred: #{e.message}"
        puts "Error backtrace: #{e.backtrace.join("\n")}"
      end
    end
  end


  # Task: publish
  # Builds a hokusai app as a standalone executable
  # Arg: <target:string> the ruby file to run
  # Arg: <platform:string> a comma delimited list of platforms <os,linux,windows>
  # Arg: <extras:string> a comma delimited list of files/folders to add to the resulting project
  # Arg: <assets_path:string> a path to assets that get stored under <project/assets>
  # Arg: <gem_config:string> a snippet representing extra MRuby gems
  # Output: platforms/<platform>/<target>
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
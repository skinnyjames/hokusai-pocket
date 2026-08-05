def top
  binding
end

def mingw?
  !!ENV["MINGW"]
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
    list = if detected_os == "MacOS"
      if args[:platform] == "sdl"
        extras = "-framework CoreGraphics -framework UniformTypeIdentifiers -framework QuartzCore -framework Metal -framework GameController -framework AudioToolbox -framework AVFoundation -framework Foundation -framework CoreHaptics -framework CoreMedia -framework Carbon -framework ForceFeedback"
      end
      "-framework CoreVideo -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL #{extras}"
    elsif detected_os == "Windows" || mingw?
      # add -mwindows after figuring out why apps don't launch... 
      "-lgdi32 -lwinmm -lws2_32 -lcomctl32 -lcomdlg32 -lole32 -luuid -ldbghelp -luserenv -liphlpapi -lbcrypt -lcrypt32 -static -lwinpthread -lsynchronization"
    elsif detected_os == "Linux"
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
      vendor/tree-sitter/build/lib/libtree-sitter.a
    ]

    links << "vendor/nfd/build/#{NFD_LIB}"
    links << "vendor/raylib/build/raylib/#{RAYLIB_LIB}"
    
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

  def cmake(str, **args)
    cmake = ENV["CMAKE"] || "cmake"

    command("#{cmake} #{str}", **args)
  end

  def make(str, **args)
    make = ENV["MAKE"] || "make"

    command("#{make} #{str}", **args)
  end

  def gcc(str, **args)
    gcc = ENV["GCC"] || "gcc"

    command("#{gcc} #{str}", **args)
  end

  def ar(str, **args)
    ar = ENV["AR"] || "ar"

    command("#{ar} #{str}", **args)
  end
end

spec("hokusai-pocket") do |config|
  recipe "desktop", "cli,hokusai:http=true"
  recipe "build", "cli,hokusai:http=true:remote=true"
  recipe "mobile", "cli,raylib,nfd,hokusai:http=true:arm64=true:platform=sdl:opengl=es"
  recipe "mobile-rebuild", "cli,raylib,nfd,hokusai:http=true:remote=true:arm64=true:platform=sdl:opengl=es"
  recipe "rebuild", "cli,hokusai:http=true:remote=true mruby:gem_config=./gems"

  NFD_LIB = mingw? ? "nfd.lib" : "libnfd.a"
  LIBUV_LIB = "build/dist/lib/libuv.a"
  LLHTTP_LIB = "libllhttp.a"
  TLSUV_LIB =  "libtlsuv.a"
  MBEDTLS_LIBS = %w[libmbedtls.a libmbedx509.a libmbedcrypto.a]
  ZLIB_LIB = mingw? ? "libzs.a" : "libz.a"
  RAYLIB_LIB = "libraylib.a"

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
    include Mingw

    def fetch
      unless Dir.exists?("vendor/sdl3")
        command("git clone --branch release-3.4.4 --depth 1 https://github.com/libsdl-org/SDL.git vendor/sdl3")
      end
    end

    def build
      fetch

      command("mkdir -p build", chdir: "vendor/sdl3")
      cmake("-S . -B build -DBUILD_SHARED_LIBS=OFF -DSDL_X11_XSCRNSAVER=OFF", chdir: "vendor/sdl3")
      make("-j 5 all", chdir: "vendor/sdl3/build")
    end
  end

  # Task: raylib
  # builds raylib
  # output: vendor/raylib/src/libraylib.a
  task "raylib" do |args|
    include Mingw

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

    def cmake_platform
      case args[:platform]
      when "sdl"
        "SDL"
      else
        "Desktop"
      end
    end

    def includes
      incs = %w[sdl3/include/SDL3 sdl3/include].map do |path|
        "-I../../#{path}"
      end
      incs.join(" ")
    end

    def cincs
      incs = %w[sdl3/include/SDL3 sdl3/include].map do |path|
        "../../#{path}"
      end
      incs.join(":")
    end

    def fetch
      unless Dir.exists?("vendor/raylib")
        command("git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib")
      end
    end

    def patch
      command("git apply ../../../../support/raylib/sdl.patch", chdir: "vendor/raylib/src/platforms")
    end

    def patch_remote
      ruby do
        File.open("vendor/raylib/src/platforms/sdl.patch", "w") do |io|
          io << Hokusai::Patches.sdl_patch
        end
      end

      command("git apply sdl.patch", chdir: "vendor/raylib/src/platforms")
    end

    def build
      fetch

      incs = ""
      if args[:platform] == "sdl"
        args[:remote] ? patch_remote : patch
        incs = "-DCMAKE_C_FLAGS='#{includes}' -DSDL3_DIR=../../sdl3"
      end

      make("clean", chdir: "vendor/raylib/src")
      command("mkdir -p build", chdir: "vendor/raylib/src")
      # have to do a test here because cmake sucks, and so does github ci
      if mingw?
        # fails on arm64 github ci... why? who fucking knows.
        cmake("-S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DPLATFORM=#{cmake_platform} -DGRAPHICS=#{opengl} #{incs}", chdir: "vendor/raylib")
        make("-j 5", chdir: "vendor/raylib/build")
      else
        command("mkdir -p build/raylib", chdir: "vendor/raylib")
        command("make -j 5 PLATFORM=#{platform} GRAPHICS=#{opengl} C_INCLUDE_PATH=#{cincs}", chdir: "vendor/raylib/src")
        command("mv vendor/raylib/src/libraylib.a vendor/raylib/build/raylib/.")
      end
    end
  end

  # Task: libuv
  # Builds libuv
  # output: vendor/libuv/build/libuv.a
  task "libuv" do
    include Mingw

    def fetch
      unless Dir.exists?("vendor/libuv")
        command("git clone https://github.com/libuv/libuv vendor/libuv")
      end
    end

    def build
      fetch

      command("mkdir -p build", chdir: "vendor/libuv")
      cmake("-S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=build/dist", chdir: "vendor/libuv")
      make("-j 5 all install", chdir: "vendor/libuv/build")
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

      command("mkdir -p vendor/llhttp/build")
      command("mkdir -p vendor/llhttp/dist")

      cmake("-S . -B build -DCMAKE_BUILD_TYPE=Release -DLLHTTP_BUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=dist", chdir: "vendor/llhttp")
      make("install", chdir: "vendor/llhttp/build")
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
      command("mkdir -p build", chdir: "vendor/mbedtls") unless Dir.exists?("vendor/mbedtls/build")

      cmake("-S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/dist -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF", chdir: "vendor/mbedtls")
      make("-j 5 install", chdir: "vendor/mbedtls/build")
    end
  end

  task "zlib" do |args|
    include Mingw

    def fetch
      command("git clone https://github.com/madler/zlib.git vendor/zlib")
    end
  
    def build
      fetch unless Dir.exists?("vendor/zlib")
      
      command("mkdir -p build", chdir: "vendor/zlib")
      cmake("-S . -B build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_SHARED=OFF -DZLIB_INSTALL=OFF", chdir: "vendor/zlib")
      make("-j 5 all", chdir: "vendor/zlib/build")
    end
  end

  # The build for this software is incredibly brittle
  # But it's a good project.
  # TODO: Find another way
  task "tlsuv" do |args|
    include Mingw

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
      command("git init", chdir: "vendor/tlsuv")
      command("git add . ", chdir: "vendor/tlsuv")
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

      command("git apply ../../support/tlsuv/mbedtls.patch", chdir: "vendor/tlsuv")
      command("git diff > tlsuv.patch", chdir: "vendor/tlsuv")
    end

    def patch_remote
      ruby do
        File.open("vendor/tlsuv/tlsuv.patch", "w") do |io|
          io << Hokusai::Patches.tlsuv_patch
        end
      end

      command("git init", chdir: "vendor/tlsuv")
      command("git add . ", chdir: "vendor/tlsuv")
      command("git apply tlsuv.patch", chdir: "vendor/tlsuv")
    end

    def build
      fetch unless Dir.exists?("vendor/tlsuv")
      args[:remote] ? patch_remote : patch

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
       
      opts << "-DCMAKE_CFLAGS='-DNOGDI -DWIN32_LEAN_AND_MEAN'" if windows? || mingw?
      opts << "-DZLIB_LIB='../../vendor/zlib/build/#{ZLIB_LIB}'"
      opts << "-DLLHTTP_LIB='../../vendor/llhtp/dist/lib/#{LLHTTP_LIB}'"
      opts << "-DLLHTTP_INCLUDE='../../vendor/llhttp/dist/include'"
      opts << "-DTLSUV_LIBUV_LIB='../../vendor/libuv/#{LIBUV_LIB}'"
      opts << "-DTLSUV_LIBUV_INCLUDE='../../vendor/libuv/build/dist/include'"
      opts << "-DMBEDTLS_INCLUDE='../../vendor/mbedtls/build/dist/include/'"

      opts = opts.join(" ")

      # cmake is hot garbage.
      command("mkdir -p build", chdir: "vendor/tlsuv")
      cmake("-S vendor/tlsuv -B vendor/tlsuv/build #{opts}")
      make("-j 5 all", chdir: "vendor/tlsuv/build")
    end
  end

  # Task: tree-sitter
  # Builds a static lib for tree-sitter
  # output: vendor/tree-sitter/build/lib/libtree-sitter.a
  task "tree-sitter" do |args|
    include Mingw

    def fetch
      unless Dir.exists?("vendor/tree-sitter")
        command("git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      end
    end

    def build
      fetch

      command("mkdir -p vendor/tree-sitter/build")

      if mingw?
        command("make -j 5 all install PREFIX=build LD=x86_64-w64-mingw32-ld CC=x86_64-w64-mingw32-gcc-posix", chdir: "vendor/tree-sitter")
      else
        make("-j 5 all install PREFIX=build", chdir: "vendor/tree-sitter")
      end
    end
  end


  # Task nfd
  # Builds a file dialog library
  # output: build/libnfd.a|nfd.lib
  task "nfd" do |args|
    include Mingw

    def fetch
      command("git clone --branch devel --depth 1 https://github.com/mlabbe/nativefiledialog.git vendor/nfd")
    end

    def build
      fetch unless Dir.exists?("vendor/nfd")
      platform = args[:arm64] ? "arm64" : "x64"      

      if mac?
        folder = "build/gmake_macosx"
      elsif windows? || mingw?
        folder = "build/gmake_windows"
      else
        folder = "build/gmake_linux_zenity"
      end

      if mingw?
        command("make config=release_#{platform} verbose=1 all LD=x86_64-w64-mingw32-ld CC=x86_64-w64-mingw32-g++", chdir: "vendor/nfd/#{folder}")
      else
        make("config=release_#{platform} all", chdir: "vendor/nfd/#{folder}")
      end
      command("cp build/lib/Release/#{platform}/#{NFD_LIB} build/#{NFD_LIB}", chdir: "vendor/nfd")
    end
  end

  # Task: mruby
  # Compiles MRuby with gems
  # Arg: <gem_config> a snippet that is embedded in mrb's build_config
  # output: vendor/mruby/build/host/lib/libmruby.a
  task "mruby" do |args|
    def fetch
      command("git clone --branch 3.4.0 --depth 1 https://github.com/mruby/mruby.git vendor/mruby")
    end

    def build
      fetch unless Dir.exists?("vendor/mruby")
      gem_config = args[:gem_config].nil? ? "" : File.read(args[:gem_config])

      ruby do
        File.open("vendor/mruby/cli_build_config.rb", "w") do |io|
          if mingw?
            str = <<-RUBY
            MRuby::CrossBuild.new("mingw") do |conf|
              conf.toolchain :gcc

              conf.cc.flags += %w[-DMRB_ARY_LENGTH_MAX=0 -DMRB_STR_LENGTH_MAX=0]

              conf.host_target = "x86_64-w64-mingw32"  # required for `for_windows?` used by `mruby-socket` gem

              conf.cc.command = "\#{conf.host_target}-gcc-posix"
              conf.cc.flags += %w[-O2]
              conf.linker.command = conf.cc.command
              conf.archiver.command = "\#{conf.host_target}-gcc-ar"
              conf.exts.executable = ".exe"

              conf.cc.flags = ['-static']
              conf.linker.flags += ['-static', '-lpthread']

              conf.gem github: "skinnyjames/mruby-bin-theorem", branch: "main"
              conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
              conf.gem github: "skinnyjames/mruby-bin-barista", branch: "main"

              #{gem_config}
              conf.gembox "default"
            end
            RUBY
          else
            str = <<-RUBY
              MRuby::Build.new do |conf|
                conf.toolchain :gcc

                conf.gem github: "skinnyjames/mruby-bin-theorem", branch: "main"
                conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
                conf.gem github: "skinnyjames/mruby-bin-barista", branch: "main"

                #{gem_config}
                conf.gembox "default"
              end
            RUBY
          end

          puts str

          io << str
        end
      end

      command("unset LD && unset CC && unset CXX && unset AR && rake MRUBY_CONFIG=cli_build_config.rb", chdir: "vendor/mruby")

      if mingw?
        command("mv vendor/mruby/build/mingw/lib/libmruby.a vendor/mruby/build/host/lib/libmruby.a")
      end
    end
  end

  # Task: hokusai
  # builds libhokusai.a from the hokusai-pocket codebase
  # Arg <remote:bool> whether to fetch hokusai-pocket from github or build against a local installation
  # output vendor/hokusai-pocket/libhokusai-pocket.a
  task "hokusai" do |args|
    include BuildHelpers
    include Mingw

    dependency "raylib" do
      files "vendor/raylib/build/raylib/#{RAYLIB_LIB}"
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
        command("git clone --branch feature/networking --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp")
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

      gcc(" -O3 -Wall #{includes(args)} -c ../../#{prefix}/src/mruby-uv/loop.c", chdir: "vendor/hokusai-pocket")
      
      defs = ""

      if args[:http]
        gcc("-O3 -Wall  -DNOGDI -DWIN32_LEAN_AND_MEAN -DNOUSER #{includes(args)} -c ../../#{prefix}/src/http/http.c", chdir: "vendor/hokusai-pocket")

        defs = "-DHP_HTTP"
      end
      
      ruby do
        gcc("-O3 -Wall #{defs} #{includes(args)} -I. -c #{sources}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
        ar("r libhokusai.a #{objs}", chdir: "vendor/hokusai-pocket")
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
    include Mingw

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

      gcc("-O2 -Wall #{ENV["CFLAGS"]} -g #{includes(args)} -I. -o ../../bin/hokusai-pocket hokusai-pocket.c -L. #{links(args)} #{ENV["LDFLAGS"]} #{frameworks(args)}", chdir: "vendor/cli")
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
        lines = code.split("\n")
        puts "An error occurred: #{e.message}"
        puts "Error backtrace: #{e.backtrace.join("\n")}"

        e.backtrace.each_with_index do |trace, idx|
          ev, lineno, func = trace.split(":")

          puts "#{func}"
          puts "#{lines[(lineno.to_i)]}"
          if idx.zero?
            puts "#{lines[(lineno.to_i + 1)..(lineno.to_i + 5)].join("\n")}"
          end
        end

      end
    end
  end



  # For compiling the app down into a single executable
  # Used in the docker cross-compilation process
  task "build" do |args|
    include BuildHelpers
    include Mingw

    dependency "hokusai"

    def build
      raise "Need target" if args[:target].nil?
      outfile = File.basename(args[:target]).gsub(/\.rb$/, "")

      command("mkdir -p vendor/build")
      command("mkdir -p dist/#{outfile}")

      extras = args[:extras]&.split(",") || []
      assets = args[:assets_path]
      
      ruby do
        code = ruby_file(args[:target])
        File.open("vendor/build/pocket-app.rb", "w") do |io|
          io << code
        end
      end

      # build the app
      command("../../#{mrbc} -o pocket-app.h -Bpocket_app pocket-app.rb", chdir: "vendor/build")
      ruby do
        File.open("vendor/build/#{outfile}.c", "w") do |io|
          str = <<~C          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <pocket-app.h>

          int main(int argc, char* argv[])
          {
            mrb_state* mrb = mrb_open();
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            } 

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
          C

          io << str
        end
      end

      gcc("-O2 -Wall #{ENV["CFLAGS"]} -g #{includes(args)} -I. -o ../../dist/#{outfile}/#{outfile} #{outfile}.c -L. #{links(args)} #{ENV["LDFLAGS"]} #{frameworks(args)}", chdir: "vendor/build")
      command("cp -Rf #{assets} dist/#{outfile}/#{assets}") unless assets.nil?
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

              bzip2
              cmake
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
            deps = "cmake bzip2"
          end

          processed = erb(
            Hokusai.docker_template, 
            string: true, 
            vars: {
              target: args[:target],
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
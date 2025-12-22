# Depends on docker for cross-compilation
# All cross-compilation is done on linux
#
# Template for cross platform docker builds
# os : <osx|windows|linux>
# target: <app.rb>
module Hokusai
  def self.docker_template
    <<~EOF
FROM skinnyjames/mruby-cross-<%= os %> as cross
    
RUN apt update -y && apt-get install -y wget <%= deps %>

WORKDIR /temp
RUN wget https://github.com/skinnyjames/mruby-bin-barista/releases/download/0.2.4/barista-linux-x86.tar.gz && \
    tar -xvf barista-linux-x86.tar.gz && \
    chmod 755 barista-linux/barista && \
    cp barista-linux/barista /usr/bin/.

WORKDIR /app

RUN git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib
RUN git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter
RUN git clone --branch stable --depth 1 https://github.com/mruby/mruby.git vendor/mruby
RUN git clone --branch feature/libuv --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp
RUN git clone https://github.com/mlabbe/nativefiledialog.git vendor/nfd
RUN git clone https://github.com/libuv/libuv vendor/libuv

# build mruby
WORKDIR /app/vendor/mruby

<% if os == "osx" %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = "x86_64-apple-darwin20.4-clang"
    cc.flags += %w[-O2 -mmacosx-version-min=10.11 -stdlib=libc++]
  end
  conf.cc.flags += %w[-DMRB_ARY_LENGTH_MAX=0 -DMRB_STR_LENGTH_MAX=0]

  conf.cxx.command = "x86_64-apple-darwin20.4-clang++"
  conf.archiver.command = "x86_64-apple-darwin20.4-ar"

  conf.build_target = "x86_64-pc-linux-gnu"
  conf.host_target = "x86_64-apple-darwin20.4"
  
  conf.gembox "stdlib"
  conf.gembox "stdlib-ext"
  conf.gembox "stdlib-io"
  conf.gembox "math"
  conf.gembox "metaprog"

  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  # Generate mrbc command
  conf.gem :core => "mruby-bin-mrbc"
end
EOT
<% elsif os == "windows" %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  conf.toolchain :gcc

  conf.cc.flags += %w[-DMRB_ARY_LENGTH_MAX=0 -DMRB_STR_LENGTH_MAX=0]

  conf.host_target = "x86_64-w64-mingw32"  # required for `for_windows?` used by `mruby-socket` gem

  conf.cc.command = "\#{conf.host_target}-gcc-posix"
  conf.cc.flags += %w[-O2]
  conf.linker.command = conf.cc.command
  conf.archiver.command = "\#{conf.host_target}-gcc-ar"
  conf.exts.executable = ".exe"

  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  conf.gembox "default"
end
EOT
<% else %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  conf.gembox "default"
end
EOT
<% end %>

RUN rake MRUBY_CONFIG=build_config.rb

# Raylib patch
COPY <<EOT /app/vendor/raylib/tweaks.patch
diff --git a/src/Makefile b/src/Makefile
index 7dde52fb..666fe315 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -270,10 +270,22 @@ CC = gcc
 AR = ar
 
 ifeq ($(TARGET_PLATFORM),PLATFORM_DESKTOP_GLFW)
-    ifeq ($(PLATFORM_OS),OSX)
-        # OSX default compiler
-        CC = clang
-        GLFW_OSX = -x objective-c
+    ifeq ($(CROSS),MINGW)
+        CC = x86_64-w64-mingw32-gcc
+        AR = x86_64-w64-mingw32-ar
+        CFLAGS += -static-libgcc -lopengl32 -lgdi32 -lwinmm
+    endif
+    ifeq ($(CROSS),OSX_INTEL)
+      CC = x86_64-apple-darwin20.4-clang
+      AR = x86_64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
+    endif
+    ifeq ($(CROSS),OSX_APPLE)
+      CC = arm64-apple-darwin20.4-clang
+      AR = arm64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
     endif
     ifeq ($(PLATFORM_OS),BSD)
         # FreeBSD, OpenBSD, NetBSD, DragonFly default compiler
diff --git a/src/config.h b/src/config.h
index e3749c56..b271a525 100644
--- a/src/config.h
+++ b/src/config.h
@@ -165,14 +165,14 @@
 //------------------------------------------------------------------------------------
 // Selecte desired fileformats to be supported for image data loading
 #define SUPPORT_FILEFORMAT_PNG      1
-//#define SUPPORT_FILEFORMAT_BMP      1
+#define SUPPORT_FILEFORMAT_BMP      1
 //#define SUPPORT_FILEFORMAT_TGA      1
-//#define SUPPORT_FILEFORMAT_JPG      1
+#define SUPPORT_FILEFORMAT_JPG      1
 #define SUPPORT_FILEFORMAT_GIF      1
 #define SUPPORT_FILEFORMAT_QOI      1
 //#define SUPPORT_FILEFORMAT_PSD      1
 #define SUPPORT_FILEFORMAT_DDS      1
-//#define SUPPORT_FILEFORMAT_HDR      1
+#define SUPPORT_FILEFORMAT_HDR      1
 //#define SUPPORT_FILEFORMAT_PIC          1
 //#define SUPPORT_FILEFORMAT_KTX      1
 //#define SUPPORT_FILEFORMAT_ASTC     1
diff --git a/src/raylib.h b/src/raylib.h
index a26b8ce6..798d7bd0 100644
--- a/src/raylib.h
+++ b/src/raylib.h
@@ -1360,7 +1360,7 @@ RLAPI void ImageAlphaPremultiply(Image *image);
 RLAPI void ImageBlurGaussian(Image *image, int blurSize);                                                // Apply Gaussian blur using a box blur approximation
 RLAPI void ImageKernelConvolution(Image *image, const float *kernel, int kernelSize);                    // Apply custom square convolution kernel to image
 RLAPI void ImageResize(Image *image, int newWidth, int newHeight);                                       // Resize image (Bicubic scaling algorithm)
-RLAPI void ImageResizeNN(Image *image, int newWidth,int newHeight);                                      // Resize image (Nearest-Neighbor scaling algorithm)
+RLAPI void ImageResizeNN(Image *image, int newWidth, int newHeight);                                     // Resize image (Nearest-Neighbor scaling algorithm)
 RLAPI void ImageResizeCanvas(Image *image, int newWidth, int newHeight, int offsetX, int offsetY, Color fill); // Resize canvas and fill with color
 RLAPI void ImageMipmaps(Image *image);                                                                   // Compute all mipmap levels for a provided image
 RLAPI void ImageDither(Image *image, int rBpp, int gBpp, int bBpp, int aBpp);                            // Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
EOT

<% if os == "windows" %>
ENV CC=x86_64-w64-mingw32-gcc-posix
ENV AR=x86_64-w64-mingw32-gcc-ar
<% elsif os == "osx" %>
ENV CC=x86_64-apple-darwin20.4-clang
ENV AR=x86_64-apple-darwin20.4-ar
<% else %>
ENV CC=gcc
ENV AR=ar
<% end %>

WORKDIR /app/vendor/raylib
RUN git apply tweaks.patch

WORKDIR /app/vendor/raylib/src

# build raylib
<% if os == "windows" %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS CROSS=MINGW
<% elsif os == "osx" %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=OSX CROSS=OSX_INTEL
<% else %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP
<% end %>

# build tree-sitter
RUN mkdir -p /app/vendor/tree-sitter/build
WORKDIR /app/vendor/tree-sitter
RUN make -j 5 all install PREFIX=build CC=$CC AR=$AR

# build nfd
WORKDIR /app/vendor/nfd
<% if os == "windows" %>
# RUN apt install -y  g++-mingw-w64-ucrt64 gcc-mingw-w64-ucrt64
ENV CPATH=/usr/x86_64-w64-mingw32/include:$CPATH
ENV CC=x86_64-w64-mingw32-gcc
ENV CXX=x86_64-w64-mingw32-g++

RUN cd build/gmake_windows && make clean
RUN cd build/gmake_windows && make config=release_x64 verbose=1
<% elsif os == "osx" %>
RUN cd build/gmake_macosx && make config=release_x64
<% else %>
RUN cd build/gmake_linux_zenity && make config=release_x64
<% end %>

# build libuv
WORKDIR /app/vendor/libuv
RUN apt update -y && apt install -y automake libtool
<% if os == "osx" %>
RUN ./autogen.sh && ./configure --host=x86_64-apple-darwin20.4 && make
<% elsif os == "windows" %>
RUN ./autogen.sh && ./configure --host=x86_64-w64-mingw32 && make
<% else %>
RUN ./autogen.sh && ./configure && make
<% end %>

WORKDIR /app
RUN mkdir -p /app/vendor/hokusai-pocket

COPY <<EOT /app/Brewfile
spec("hokusai-pocket-app") do
  task "build" do |args|
    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

<% if os.eql?("windows")%>
    def nfd
      "nfd.lib"
    end
<% else %>
    def nfd
      "libnfd.a"
    end
<% end %>

<% if os.eql?("windows") %>
    def libs
      "-lws2_32 -lgdi32 -lwinmm -lcomctl32 -lcomdlg32 -lole32 -luuid -lpthread -ldbghelp -liphlpapi -luserenv"
    end
<% elsif os.eql?("osx") %>
    def libs
      "-framework CoreVideo -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
    end
<% else %>
    def libs
      "-lGL -lm -lpthread -ldl -lrt -lX11"
    end
<% end %>
    def includes
      %w[
          vendor/tree-sitter/build/include 
          vendor/raylib/src 
          vendor/mruby/include
          vendor/hp/grammar/tree_sitter
          vendor/hp/src
          vendor/hp/src/mruby-uv
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
        vendor/libuv/.libs/libuv.a
      ] + ["vendor/nfd/build/lib/Release/x64/\#{nfd}"]).join(" ")
    end

    def h_includes
      includes.map { |file| "-I../../\#{file}" }.join(" ")
    end

    def sources
      Dir.glob("vendor/hp/src/*.c")
    end

    def h_sources
      sources.map do |file|
        "../../\#{file}"
      end.join(" ")
    end

    def objs
      Dir.glob("vendor/hokusai-pocket/*.o").map do |file|
        File.basename(file)
      end.join(" ")
    end

    def build
      # build hokusai ruby proper...
      File.open("vendor/hp/mrblib/hokusai.rb", "w") { |io| io << ruby_file("vendor/hp/ruby/hokusai.rb") }
      mkdir("vendor/hokusai-pocket")

      command("\#{mrbc} -o vendor/hp/src/pocket.c -Bpocket ./vendor/hp/mrblib/hokusai.rb")

      ruby do
        code = File.read("vendor/hp/src/pocket.c")

        File.open("vendor/hp/src/pocket.c", "w") do |io|
          io.puts "#include <stdint.h>"
          io.puts "#include <pocket.h>"
          io.puts "#include <mruby.h>"
          io.puts "#include <mruby/irep.h>"
          io.puts "void load_pocket(mrb_state* mrb) {"
          io.puts code
          io.puts "mrb_load_irep(mrb, pocket);"
          io.puts "}"
        end

        File.open("vendor/hp/src/pocket.h", "w") do |io|
          io.puts "#ifndef MRB_HPOCKET_LIB"
          io.puts "#define MRB_HPOCKET_LIB"
          io.puts "#include <mruby.h>"
          io.puts "void load_pocket(mrb_state* mrb);"
          io.puts "#endif"
        end
      end

      # ugh, need separate libuv/raylib compilation units because of windows.h collisions
      loop_includes = %w[
        vendor/mruby/include
        vendor/libuv/include
        vendor/tree-sitter/build/include
        vendor/hp/src
        vendor/hp/grammar/tree_sitter
      ].map { |inc| "-I../../\#{inc}" }.join(" ")

      command("${CC:-gcc} -O3 -Wall \#{loop_includes} -c ../../vendor/hp/src/mruby-uv/loop.c", chdir: "vendor/hokusai-pocket")
      # end building loop.o

      ruby do
        command("${CC:-gcc} -O3 -Wall \#{h_includes} -c #\{h_sources}", chdir: "vendor/hokusai-pocket")
        .forward_output(&on_output)
        .execute

        command("${AR:-ar} r libhokusai.a \#{objs}", chdir: "vendor/hokusai-pocket")
        .forward_output(&on_output)
        .execute
      end

      # build the app
      command("\#{mrbc} -o pocket-app.h -Bpocket_app pocket-app.rb")
      ruby do
        File.open("<%= outfile %>.c", "w") do |io|
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

      app_includes = %w[
        vendor/raylib/src
        vendor/tree-sitter/build/include 
        vendor/mruby/include
        .
        vendor/hokusai-pocket
        vendor/hp/src
        vendor/hp/src/mruby-uv
        vendor/nfd/src/include
        vendor/libuv/include
      ].map { |file| "-I\#{file}" }.join(" ")

      mkdir("bin")
      command("${CC:-gcc} -O3 -Wall \#{app_includes} -o bin/<%= outfile %> <%= outfile %>.c \#{links} \#{libs}")
    end
  end
end
EOT

WORKDIR /app

ADD build/pocket-app.rb .

<% if !extras.empty? %>
  <% extras.each do |extra| %>
    ADD <%= extra %> /app/<% extra %>
  <% end %>
<% end %>

<% if assets_path %>
  ADD <%= assets_path %> /app/bin/assets
<% end %>


RUN barista build

# export
FROM scratch
COPY --from=cross /app/bin/ /<%= outfile %>
EOF
  end
end
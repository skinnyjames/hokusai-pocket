# Depends on docker for cross-compilation
# All cross-compilation is done on linux
#
# Template for cross platform docker builds
# os : <osx|windows|linux>
# target: <app.rb>
module Hokusai
  def self.sherpa_download_template
    <<~TEMPLATE
#!/bin/sh

mkdir -p tmp
mkdir -p assets/models
wget --no-config --quiet --show-progress -O tmp/vits-piper.tar.bz2 https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-low.tar.bz2
cd tmp && tar -xvf vits-piper.tar.bz2

mv vits-piper-en_US-amy-low ../assets/models/vits-piper
cd ..
rm -Rf tmp
  TEMPLATE
  end

  # Internal: Shell script for downloading Whisper models
  def self.whisper_download_template
    <<~TEMPLATE
#!/bin/sh
mkdir -p assets/models

# This script downloads Whisper model files that have already been converted to ggml format.
# This way you don't have to convert them yourself.

#src="https://ggml.ggerganov.com"
#pfx="ggml-model-whisper"

src="https://huggingface.co/ggerganov/whisper.cpp"
pfx="resolve/main/ggml"

BOLD="\033[1m"
RESET='\033[0m'

# get the path of this script
get_script_path() {
    if [ -x "$(command -v realpath)" ]; then
        dirname "$(realpath "$0")"
    else
        _ret="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P)"
        echo "$_ret"
    fi
}

models_path="${2:-$(get_script_path)}"

# Whisper models
models="tiny
tiny.en
tiny-q5_1
tiny.en-q5_1
base
base.en
base-q5_1
base.en-q5_1
small
small.en
small.en-tdrz
small-q5_1
small.en-q5_1
medium
medium.en
medium-q5_0
medium.en-q5_0
large-v1
large-v2
large-v2-q5_0
large-v3
large-v3-q5_0
large-v3-turbo
large-v3-turbo-q5_0"

# list available models
list_models() {
    printf "\n"
    printf "Available models:"
    model_class=""
    for model in $models; do
        this_model_class="${model%%[.-]*}"
        if [ "$this_model_class" != "$model_class" ]; then
            printf "\n "
            model_class=$this_model_class
        fi
        printf " %s" "$model"
    done
    printf "\n\n"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf "Usage: %s <model> [models_path]\n" "$0"
    list_models
    printf "___________________________________________________________\n"
    printf "${BOLD}.en${RESET} = english-only ${BOLD}-q5_[01]${RESET} = quantized ${BOLD}-tdrz${RESET} = tinydiarize\n"

    exit 1
fi

model=$1

if ! echo "$models" | grep -q -w "$model"; then
    printf "Invalid model: %s\n" "$model"
    list_models

    exit 1
fi

# check if model contains `tdrz` and update the src and pfx accordingly
if echo "$model" | grep -q "tdrz"; then
    src="https://huggingface.co/akashmjn/tinydiarize-whisper.cpp"
    pfx="resolve/main/ggml"
fi

echo "$model" | grep -q '^"tdrz"*$'

# download ggml model

printf "Downloading ggml model %s from '%s' ...\n" "$model" "$src"

cd "$models_path" || exit

if [ -f "ggml-$model.bin" ]; then
    printf "Model %s already exists. Skipping download.\n" "$model"
    exit 0
fi

if [ -x "$(command -v wget2)" ]; then
    wget2 --no-config --progress bar -O ggml-"$model".bin $src/$pfx-"$model".bin
elif [ -x "$(command -v wget)" ]; then
    wget --no-config --quiet --show-progress -O ggml-"$model".bin $src/$pfx-"$model".bin
elif [ -x "$(command -v curl)" ]; then
    curl -L --output ggml-"$model".bin $srcls/$pfx-"$model".bin
else
    printf "Either wget or curl is required to download models.\n"
    exit 1
fi

if [ $? -ne 0 ]; then
    printf "Failed to download ggml model %s \n" "$model"
    printf "Please try again later or download the original Whisper model files and convert them yourself.\n"
    exit 1
fi

printf "Done! Model '%s' saved in '%s/ggml-%s.bin'\n" "$model" "$models_path" "$model"
printf "You can now use it like this:\n\n"
printf "  $ ./main -m %s/ggml-%s.bin -f samples/jfk.wav\n" "$models_path" "$model"
printf "\n"

pwd
mv ggml-tiny.bin ../assets/models/ggml-tiny.bin
TEMPLATE
  end


  # Internal: Docker templates that get written to disk by binary
  #           during cross platform publishing
  def self.docker_template
    <<~HELL
FROM skinnyjames/mruby-cross-<%= os %> as cross
    
RUN apt update -y && apt-get install -y wget <%= deps %>

WORKDIR /temp
RUN wget https://github.com/skinnyjames/mruby-bin-barista/releases/download/0.3.1/barista-linux-x86.tar.gz && \
    tar -xvf barista-linux-x86.tar.gz && \
    chmod 755 barista-linux-x86/barista && \
    cp barista-linux-x86/barista /usr/bin/.

WORKDIR /app

RUN git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib
RUN git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter
RUN git clone --branch stable --depth 1 https://github.com/mruby/mruby.git vendor/mruby
RUN git clone --branch main --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp
RUN git clone https://github.com/mlabbe/nativefiledialog.git vendor/nfd
RUN git clone https://github.com/libuv/libuv vendor/libuv

# fetch http deps
RUN wget -O vendor/llhttp.tar.gz https://github.com/nodejs/llhttp/archive/refs/tags/release/v9.3.1.tar.gz && \
    cd vendor && tar -xvf llhttp.tar.gz && mv llhttp-release-v9.3.1 llhttp

RUN wget -O vendor/mbedtls.tar.bz2 https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.6/mbedtls-3.6.6.tar.bz2 && \
    cd vendor && tar -xvf mbedtls.tar.bz2 && mv mbedtls-3.6.6 mbedtls

RUN git clone https://github.com/madler/zlib.git vendor/zlib

RUN wget -O vendor/tlsuv.tar.gz https://github.com/openziti/tlsuv/archive/refs/tags/v0.41.1.tar.gz && \
    cd vendor && tar -xvf tlsuv.tar.gz && mv tlsuv-0.41.1 tlsuv
    

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
  conf.gem :github => 'iij/mruby-env'
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
  conf.gem :github => 'iij/mruby-env'
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
  conf.gem :github => 'iij/mruby-env'
  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  conf.gembox "default"
end
EOT
<% end %>

RUN unset LD && unset CC && unset CXX && unset AR && rake MRUBY_CONFIG=build_config.rb

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

RUN apt update -y && apt install -y gpg

# Source - https://stackoverflow.com/a/56690743
# Posted by Liu Hao Cheng, modified by community. See post 'Timeline' for change history
# Retrieved 2026-05-18, License - CC BY-SA 4.0
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null
RUN apt-get update -y && apt-get install -y cmake

<% if os == "windows" %>
# Create the mingw64-cmake wrapper
RUN echo '#!/bin/sh\\nexec cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV CC=x86_64-w64-mingw32-gcc-posix
ENV AR=x86_64-w64-mingw32-gcc-ar
ENV ZLIBA="libzs.a"
<% elsif os == "osx" %>
RUN echo '#!/bin/sh\\nexec cmake -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_C_COMPILER=x86_64-apple-darwin20.4-clang -DCMAKE_CXX_COMPILER=x86_64-apple-darwin20.4-clang++ -DCMAKE_FIND_ROOT_PATH=/opt/osxcross/target "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV OSXCROSS_ROOT=/opt/osxcross/target
ENV OSXCROSS_HOST=x86_64-linux-gnu
ENV OSXCROSS_TARGET_DIR=/opt/osxcross/target
ENV OSXCROSS_TARGET=x86_64-apple-darwin20.4
ENV OSXCROSS_SDK_DIR=$OSXCROSS_TARGET_DIR/SDK
ENV OSXCROSS_SDK="MacOSX11.3.sdk"
ENV CC=x86_64-apple-darwin20.4-clang
ENV AR=x86_64-apple-darwin20.4-ar
ENV ZLIBA="libz.a"
<% else %>
RUN echo '#!/bin/sh\\nexec cmake "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV CC=gcc
ENV AR=ar
ENV ZLIBA="libz.a"
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
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=build/dist
RUN cd build && make -j 5 all install

# build llhttp
WORKDIR /app/vendor/llhttp
RUN mkdir -p build
RUN mkdir -p dist
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLHTTP_BUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=dist
RUN cd build && make -j 5 install

# build mbedtls
WORKDIR /app/vendor/mbedtls
RUN mkdir -p build
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/dist -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF
RUN cd build && make -j 5 install

# build zlib
WORKDIR /app/vendor/zlib
RUN mkdir -p build
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_SHARED=OFF -DZLIB_INSTALL=OFF
RUN cd build && make -j 5

# build tlsuv
WORKDIR /app/vendor/tlsuv
COPY <<'FUCK' tlsuv.patch
#{Hokusai::Patches.tlsuv_patch}
FUCK

RUN git init
RUN git add .
RUN git apply tlsuv.patch

RUN cmake-wrap -S . -B build DMBEDCRYPTO_LIBRARY='../../vendor/mbedtls/build/dist/libmbedcrypto.a' \
  -DMBEDTLS_INCLUDE_DIRS='../../vendor/mbedtls/build/dist/include' \
  -DMBEDTLS_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedtls.a' \
  -DMBEDX509_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedx509.a' \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DTLSUV_HTTP=ON \
  -DTLSUV_TLSLIB=mbedtls \
  -DZLIB_INCLUDE='../../vendor/zlib' \
  -DZLIB_LIB="../../vendor/zlib/build/$ZLIBA" \
  -DLLHTTP_LIB='../../vendor/llhtp/dist/lib/libllhttp.a' \
  -DLLHTTP_INCLUDE='../../vendor/llhttp/dist/include' \
  -DTLSUV_LIBUV_LIB='../../vendor/libuv/libuv.a' \
  -DTLSUV_LIBUV_INCLUDE='../../vendor/libuv/build/dist/include' \
<% if os == "osx" %>\
  -DCMAKE_FRAMEWORK_PATH='/opt/osxcross/target/SDK/MacOSX11.3.sdk/System/Library/Frameworks' \
  -DCMAKE_EXE_LINKER_FLAGS='-framework Security'\
<% end %>\
  -DMBEDTLS_INCLUDE='../../vendor/mbedtls/build/dist/include/' 

RUN cd build && make -j 5 all 

WORKDIR /app
RUN mkdir -p /app/vendor/hokusai-pocket

COPY <<EOT /app/Brewfile
spec("hokusai-pocket-app") do
  task "build" do |args|
    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

<% if os.eql?("windows")%>
    def zlib
      "libzs.a"
    end

    def nfd
      "nfd.lib"
    end
<% else %>
    def zlib
      "libz.a"
    end

    def nfd
      "libnfd.a"
    end
<% end %>

<% if os.eql?("windows") %>
    def libs
      "-lws2_32 -lgdi32 -lwinmm -lcomctl32 -lcomdlg32 -lole32 -luuid -ldbghelp -liphlpapi -luserenv -lbcrypt -lcrypt32 -static -lwinpthread  -lsynchronization"
    end
<% elsif os.eql?("osx") %>
    def libs
      "-framework CoreVideo -framework Security -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
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
          vendor/mruby/build/host/include
          vendor/hp/grammar/tree_sitter
          vendor/hp/src
          vendor/hp/src/mruby-uv
          vendor/nfd/src/include
          vendor/libuv/include
          vendor/llhttp/include
          vendor/tlsuv/deps/uv_link_t/include
          vendor/tlsuv/build/generated
          vendor/tlsuv/include
          vendor/zlib
          vendor/hp/src/http
        ]
    end

    def mbedtls_libs
      %w[libmbedtls.a libmbedx509.a libmbedcrypto.a]
    end

    def links
      ln = %w[
        vendor/hp/grammar/src/parser.c
        vendor/hp/grammar/src/scanner.c
        vendor/hokusai-pocket/libhokusai.a
        vendor/mruby/build/platform/lib/libmruby.a 
        vendor/raylib/src/libraylib.a
        vendor/tree-sitter/build/lib/libtree-sitter.a
        vendor/libuv/build/dist/lib/libuv.a
      ] + ["vendor/nfd/build/lib/Release/x64/\#{nfd}"]

      ln << "vendor/tlsuv/build/libtlsuv.a"
      ln << "vendor/llhttp/dist/lib/libllhttp.a"

      mbedtls_libs.each do |lib|
        ln << "vendor/mbedtls/build/dist/lib/\#{lib}"
      end

      ln << "vendor/zlib/build/\#{zlib}"
      ln.join(" ")
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
        vendor/mruby/build/host/include
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
        vendor/mruby/build/host/include
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
HELL
  end
end
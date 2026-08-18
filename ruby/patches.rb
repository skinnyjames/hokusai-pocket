module Hokusai
  # Internal: Compile time patches for various sources
  module Patches
    # Internal: Patch for SDL Touch handling
    #           affects build using SDL/ARM64 architecture
    def self.sdl_patch
      <<~BAD
diff --git a/src/platforms/rcore_desktop_sdl.c b/src/platforms/rcore_desktop_sdl.c
index a201f2c..3d0e4a1 100644
--- a/src/platforms/rcore_desktop_sdl.c
+++ b/src/platforms/rcore_desktop_sdl.c
@@ -1342,10 +1342,17 @@ void PollInputEvents(void)
     }
 
     // Register previous touch states
-    for (int i = 0; i < MAX_TOUCH_POINTS; i++) CORE.Input.Touch.previousTouchState[i] = CORE.Input.Touch.currentTouchState[i];
+    for (int i = 0; i < MAX_TOUCH_POINTS; i++)
+    {
+      CORE.Input.Touch.previousTouchState[i] = CORE.Input.Touch.currentTouchState[i];
+      // todo clear touch position?
+      // CORE.Input.Touch.position[i].x = -1;
+      // CORE.Input.Touch.position[i].y = -1;
+      // CORE.Input.Touch.pointId[i] = -1;
+    }
 
-    // Map touch position to mouse position for convenience
-    CORE.Input.Touch.position[0] = CORE.Input.Mouse.currentPosition;
+    // // Map touch position to mouse position for convenience
+    // CORE.Input.Touch.position[0] = CORE.Input.Mouse.currentPosition;
 
     int touchAction = -1;       // 0-TOUCH_ACTION_UP, 1-TOUCH_ACTION_DOWN, 2-TOUCH_ACTION_MOVE
     bool realTouch = false;     // Flag to differentiate real touch gestures from mouse ones
@@ -1583,13 +1590,19 @@ void PollInputEvents(void)
             } break;
             case SDL_FINGERUP:
             {
+                int count = CORE.Input.Touch.pointCount;
                 UpdateTouchPointsSDL(event.tfinger);
+                CORE.Input.Touch.pointCount = count;
+
                 touchAction = 0;
                 realTouch = true;
             } break;
             case SDL_FINGERMOTION:
             {
+                int count = CORE.Input.Touch.pointCount;
                 UpdateTouchPointsSDL(event.tfinger);
+                CORE.Input.Touch.pointCount = count;
+
                 touchAction = 2;
                 realTouch = true;
             } break;
@@ -1738,28 +1751,42 @@ void PollInputEvents(void)
         {
             // Process mouse events as touches to be able to use mouse-gestures
             GestureEvent gestureEvent = { 0 };
-
             // Register touch actions
             gestureEvent.touchAction = touchAction;
 
-            // Assign a pointer ID
-            gestureEvent.pointId[0] = 0;
-
-            // Register touch points count
-            gestureEvent.pointCount = 1;
-
-            // Register touch points position, only one point registered
-            if (touchAction == 2 || realTouch) gestureEvent.position[0] = CORE.Input.Touch.position[0];
-            else gestureEvent.position[0] = GetMousePosition();
-
-            // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
-            gestureEvent.position[0].x /= (float)GetScreenWidth();
-            gestureEvent.position[0].y /= (float)GetScreenHeight();
+            if (realTouch)
+            {
+              // Register touch points count
+              gestureEvent.pointCount = CORE.Input.Touch.pointCount;
+
+              // we want to track every touch.
+              for (int i = 0; i < CORE.Input.Touch.pointCount; i++)
+              {
+                gestureEvent.pointId[i] = i;
+                gestureEvent.position[i].x = CORE.Input.Touch.position[i].x / (float)GetScreenWidth();
+                gestureEvent.position[i].y = CORE.Input.Touch.position[i].y / (float)GetScreenWidth();
+              }
+            }
+            else
+            {
+              // Register touch points count
+              gestureEvent.pointCount = 1;
+              // Assign a pointer ID
+              gestureEvent.pointId[0] = 0;
+              // Register touch points position, only one point registered
+              if (touchAction == 2 || realTouch) gestureEvent.position[0] = CORE.Input.Touch.position[0];
+              else gestureEvent.position[0] = GetMousePosition();
+
+              // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
+              gestureEvent.position[0].x /= (float)GetScreenWidth();
+              gestureEvent.position[0].y /= (float)GetScreenHeight();
+            }
 
             // Gesture data is sent to gestures-system for processing
             ProcessGestureEvent(gestureEvent);
 
             touchAction = -1;
+            realTouch = false;
         }
 #endif
     }

BAD
    end

    # Internal: Patch for raylib to compile against different sources
    #           Thanks to the [Taylor](https://taylormadetech.dev/) project for this
    def self.raylib_patch
      <<~BAD

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

BAD
    end

    # Internal: A bunch of patches for TLSUV
    #           TODO: Remove dependency
    def self.tlsuv_patch
      <<-BAD
diff --git a/CMakeLists.txt b/CMakeLists.txt
index b7e81c5..acb182f 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -100,6 +100,8 @@ if (TARGET libuv::uv)
     message(NOTICE "upstream project set libuv target")
     set(TLSUV_LIBUV_LIB libuv::uv)
     set(libuv_FOUND TRUE)
+elseif(TLSUV_LIBUV_LIB)
+  message(NOTICE, "Setting from cli")
 else ()
     find_package(libuv CONFIG QUIET)
     # newer libuv versions (via VCPKG) have proper namespacing
@@ -114,11 +116,6 @@ else ()
     endif()
 endif ()
 
-if (NOT libuv_FOUND)
-    pkg_check_modules(libuv REQUIRED IMPORTED_TARGET libuv)
-    set(TLSUV_LIBUV_LIB PkgConfig::libuv)
-endif()
-
 add_library(tlsuv STATIC
         ${tlsuv_sources}
         )
@@ -134,6 +131,10 @@ target_include_directories(tlsuv
         $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated>
         PRIVATE
         ${CMAKE_CURRENT_SOURCE_DIR}/src
+        ${CMAKE_CURRENT_SOURCE_DIR}/${TLSUV_LIBUV_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${LLHTTP_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${MBEDTLS_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${ZLIB_INCLUDE}
 )
 
 target_compile_definitions(tlsuv PRIVATE
@@ -179,18 +180,22 @@ if (TLSUV_HTTP)
     add_subdirectory(deps)
     target_link_libraries(tlsuv PUBLIC uv_link)
 
-    find_package(ZLIB 1 REQUIRED)
-    target_link_libraries(tlsuv PRIVATE ZLIB::ZLIB)
+    message(NOTICE "${CMAKE_CURRENT_SOURCE_DIR}/../../${ZLIB_LIB}")
+    target_link_libraries(tlsuv PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${ZLIB_LIB}")
 
-    find_package(llhttp CONFIG REQUIRED)
-    message(NOTICE "llhttp = ${llhttp_CONFIG}")
-    if (TARGET llhttp::llhttp_static)
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp_static)
-    elseif (TARGET llhttp::llhttp_shared)
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp_shared)
+    if (LLHTTP_LIB)
+      target_link_libraries(tlsuv PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${LLHTTP_LIB}")
     else ()
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp)
-    endif ()
+
+      message(NOTICE "llhttp = ${llhttp_CONFIG}")
+      if (TARGET llhttp::llhttp_static)
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp_static)
+      elseif (TARGET llhttp::llhttp_shared)
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp_shared)
+      else ()
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp)
+      endif ()
+    endif (LLHTTP_LIB)
 
 endif (TLSUV_HTTP)
 
diff --git a/cmake/FindMbedTLS.cmake b/cmake/FindMbedTLS.cmake
index 7dd4e32..132ef2a 100644
--- a/cmake/FindMbedTLS.cmake
+++ b/cmake/FindMbedTLS.cmake
@@ -1,17 +1,23 @@
-find_path(MBEDTLS_INCLUDE_DIRS mbedtls/ssl.h)
+ find_path(${CMAKE_CURRENT_SOURCE_DIR}/MBEDTLS_INCLUDE_DIRS mbedtls/ssl.h)
 
 # mbedtls-3.0 changed headers files, and we need to ifdef'out a few things
-find_path(MBEDTLS_VERSION_GREATER_THAN_3 mbedtls/build_info.h)
+find_path(MBEDTLS_VERSION_GREATER_THAN_3 ${CMAKE_CURRENT_SOURCE_DIR}/../MBEDTLS_INCLUDE_DIRS mbedtls/build_info.h)
 message("MBEDTLS_VERSION_GREATER_THAN_3 = ${MBEDTLS_VERSION_GREATER_THAN_3}")
+if (true)
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
 
-find_library(MBEDTLS_LIBRARY mbedtls)
-find_library(MBEDX509_LIBRARY mbedx509)
-find_library(MBEDCRYPTO_LIBRARY mbedcrypto)
+endif()
+
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}" mbedtls)
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDX509_LIBRARY}" mbedx509)
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDCRYPTO_LIBRARY}" mbedcrypto)
 
 set(MBEDTLS_LIBRARIES "${MBEDTLS_LIBRARY}" "${MBEDX509_LIBRARY}" "${MBEDCRYPTO_LIBRARY}")
 
-include(FindPackageHandleStandardArgs)
-find_package_handle_standard_args(MbedTLS DEFAULT_MSG
-    MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
+# include(FindPackageHandleStandardArgs)
+# find_package_handle_standard_args(MbedTLS DEFAULT_MSG
+#     MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
 
-mark_as_advanced(MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
+mark_as_advanced(MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
\\ No newline at end of file
diff --git a/deps/CMakeLists.txt b/deps/CMakeLists.txt
index 2279051..3d74473 100644
--- a/deps/CMakeLists.txt
+++ b/deps/CMakeLists.txt
@@ -1,2 +1,17 @@
+set(uvl_src ${CMAKE_CURRENT_SOURCE_DIR}/uv_link_t)
+add_library(uv_link OBJECT
+        ${uvl_src}/src/uv_link_t.c
+        ${uvl_src}/src/uv_link_source_t.c
+        ${uvl_src}/src/uv_link_observer_t.c
+        ${uvl_src}/src/defaults.c)
 
-include(uv_link.cmake)
\\ No newline at end of file
+target_include_directories(uv_link
+        PUBLIC ${uvl_src}/include
+        PRIVATE ${uvl_src}
+        PUBLIC
+        ${CMAKE_CURRENT_SOURCE_DIR}/../${TLSUV_LIBUV_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/../${LLHTTP_INCLUDE}
+)
+
+set_target_properties(uv_link PROPERTIES POSITION_INDEPENDENT_CODE ON)
+target_link_libraries(uv_link ${TLSUV_LIBUV_LIB})
diff --git a/src/mbedtls/CMakeLists.txt b/src/mbedtls/CMakeLists.txt
index 323f500..85aed28 100644
--- a/src/mbedtls/CMakeLists.txt
+++ b/src/mbedtls/CMakeLists.txt
@@ -1,14 +1,25 @@
 find_package(MbedTLS REQUIRED)
 
 add_library(mbedtls-impl OBJECT
-        engine.c
-        keys.c
-        keys.h
+      engine.c
+      keys.c
+      keys.h
+)
+
+if (true)
+      message(NOTICE "Found:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}")
+endif()
+include_directories(mbedtls-impl
+      PRIVATE ${PROJECT_SOURCE_DIR}/include
+      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..
+      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}
 )
 
 target_include_directories(mbedtls-impl
-        PRIVATE ${PROJECT_SOURCE_DIR}/include
-        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..
-        PRIVATE $<BUILD_INTERFACE:${MBEDTLS_INCLUDE_DIRS}>
+  PUBLIC
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${TLSUV_LIBUV_INCLUDE}"
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${LLHTTP_INCLUDE}"
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE}"
 )
-target_link_libraries(mbedtls-impl PRIVATE ${MBEDTLS_LIBRARIES})
+
+target_link_libraries(mbedtls-impl PRIVATE MBEDTLS_LIBRARIES)
\\ No newline at end of file
diff --git a/src/mbedtls/engine.c b/src/mbedtls/engine.c
index 3d9e2f9..6dc6dad 100644
--- a/src/mbedtls/engine.c
+++ b/src/mbedtls/engine.c
@@ -91,7 +91,7 @@ struct mbedtls_engine {
     mbedtls_ssl_session *session;
 
     io_ctx io;
-    uv_os_fd_t io_fd;
+    uv_os_sock_t io_fd;
     io_read read_f;
     io_write write_f;
 
@@ -111,7 +111,7 @@ static int mbedtls_set_own_cert(tls_context *ctx, tlsuv_private_key_t key, tlsuv
 tlsuv_engine_t new_mbedtls_engine(tls_context *ctx, const char *host);
 
 static void mbedtls_set_io(tlsuv_engine_t, io_ctx , io_read , io_write );
-static void mbedtls_set_fd(tlsuv_engine_t, uv_os_fd_t );
+static void mbedtls_set_fd(tlsuv_engine_t, uv_os_sock_t );
 
 static tls_handshake_state mbedtls_hs_state(tlsuv_engine_t engine);
 static tls_handshake_state
@@ -720,7 +720,7 @@ static void mbedtls_set_io(tlsuv_engine_t e, io_ctx io, io_read read_f, io_write
     mbedtls_ssl_set_bio(eng->ssl, eng, engine_io_write, engine_io_read, NULL);
 }
 
-static void mbedtls_set_fd(tlsuv_engine_t e, uv_os_fd_t fd) {
+static void mbedtls_set_fd(tlsuv_engine_t e, uv_os_sock_t fd) {
     struct mbedtls_engine *eng = (struct mbedtls_engine *) e;
     assert(eng->io == NULL);
     eng->io_fd = fd;
diff --git a/src/apple/keychain.c b/src/apple/keychain.c
index 24fe128..42dd256 100644
--- a/src/apple/keychain.c
+++ b/src/apple/keychain.c
@@ -1,6 +1,6 @@
 
-#include <security/SecKey.h>
-#include <security/Security.h>
+#include <Security/SecKey.h>
+#include <Security/Security.h>
 
 #include "../keychain.h"
 #include "um_debug.h"
BAD
    end
  end
end

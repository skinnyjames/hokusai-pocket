find_package(MbedTLS REQUIRED)

add_library(mbedtls-impl OBJECT
      engine.c
      keys.c
      keys.h
)

if (true)
      message(NOTICE "Found:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}")
endif()
include_directories(mbedtls-impl
      PRIVATE ${PROJECT_SOURCE_DIR}/include
      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..
      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}
)

target_include_directories(mbedtls-impl
  PUBLIC         
  "${CMAKE_CURRENT_SOURCE_DIR}/../../${TLSUV_LIBUV_INCLUDE}"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../${LLHTTP_INCLUDE}"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE}"
)

target_link_libraries(mbedtls-impl PRIVATE MBEDTLS_LIBRARIES)
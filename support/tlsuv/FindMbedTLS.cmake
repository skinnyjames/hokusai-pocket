 find_path(${CMAKE_CURRENT_SOURCE_DIR}/MBEDTLS_INCLUDE_DIRS mbedtls/ssl.h)

# mbedtls-3.0 changed headers files, and we need to ifdef'out a few things
find_path(MBEDTLS_VERSION_GREATER_THAN_3 ${CMAKE_CURRENT_SOURCE_DIR}/../MBEDTLS_INCLUDE_DIRS mbedtls/build_info.h)
message("MBEDTLS_VERSION_GREATER_THAN_3 = ${MBEDTLS_VERSION_GREATER_THAN_3}")
if (true)
      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")

endif()

find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}" mbedtls)
find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDX509_LIBRARY}" mbedx509)
find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDCRYPTO_LIBRARY}" mbedcrypto)

set(MBEDTLS_LIBRARIES "${MBEDTLS_LIBRARY}" "${MBEDX509_LIBRARY}" "${MBEDCRYPTO_LIBRARY}")

# include(FindPackageHandleStandardArgs)
# find_package_handle_standard_args(MbedTLS DEFAULT_MSG
#     MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)

mark_as_advanced(MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
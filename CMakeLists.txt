cmake_minimum_required(VERSION 3.16)
project(openssl_wasm_crypto VERSION 1.0.0)

# Ensure we're using Emscripten
if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "This project must be built with Emscripten. Please use emcmake cmake ...")
endif()

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Project directories
set(OPENSSL_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/openssl")
set(OPENSSL_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/openssl_build")
set(OPENSSL_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/openssl_install")

# Check if OpenSSL source exists
if(NOT EXISTS "${OPENSSL_SOURCE_DIR}/Configure")
    message(FATAL_ERROR "OpenSSL source not found at ${OPENSSL_SOURCE_DIR}. Please run the setup script first.")
endif()

# Build OpenSSL for WebAssembly
include(ExternalProject)
ExternalProject_Add(openssl_build
    SOURCE_DIR ${OPENSSL_SOURCE_DIR}
    BINARY_DIR ${OPENSSL_BUILD_DIR}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        CC=${CMAKE_C_COMPILER}
        CXX=${CMAKE_CXX_COMPILER}
        AR=${CMAKE_AR}
        RANLIB=${CMAKE_RANLIB}
        ${OPENSSL_SOURCE_DIR}/Configure
        linux-generic32
        no-shared
        no-dso
        no-engine
        no-unit-test
        no-ui-console
        no-tests
        --prefix=${OPENSSL_INSTALL_DIR}
        --openssldir=${OPENSSL_INSTALL_DIR}
    BUILD_COMMAND make -j4
    INSTALL_COMMAND make install_sw
    BUILD_BYPRODUCTS 
        ${OPENSSL_INSTALL_DIR}/lib/libssl.a
        ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
        ${OPENSSL_INSTALL_DIR}/include/openssl/opensslconf.h
)

# Main executable - define it first
add_executable(${PROJECT_NAME} src/main.cpp)

# Add dependency on OpenSSL build
add_dependencies(${PROJECT_NAME} openssl_build)

# Set include directories and link libraries after the target is created
target_include_directories(${PROJECT_NAME} PRIVATE ${OPENSSL_INSTALL_DIR}/include)
target_link_libraries(${PROJECT_NAME} 
    ${OPENSSL_INSTALL_DIR}/lib/libssl.a
    ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
)

# Emscripten-specific settings
set_target_properties(${PROJECT_NAME} PROPERTIES
    LINK_FLAGS "--bind -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s EXPORTED_RUNTIME_METHODS=['ccall','cwrap'] -s MODULARIZE=1 -s EXPORT_NAME='OpenSSLModule' --shell-file ${CMAKE_CURRENT_SOURCE_DIR}/template/shell.html"
)

# Set output names
set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "openssl_crypto"
)
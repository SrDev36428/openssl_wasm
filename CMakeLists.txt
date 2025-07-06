cmake_minimum_required(VERSION 3.16)
project(openssl_wasm_crypto VERSION 1.0.0)

# Ensure we're using Emscripten - Updated detection logic
if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "This project must be built with Emscripten. Please use 'emcmake cmake ...' or run activate_and_build.bat")
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
    message(FATAL_ERROR "OpenSSL source not found at ${OPENSSL_SOURCE_DIR}. Please run setup_openssl.bat first.")
endif()

# Create install directory early
file(MAKE_DIRECTORY ${OPENSSL_INSTALL_DIR})
file(MAKE_DIRECTORY ${OPENSSL_INSTALL_DIR}/lib)
file(MAKE_DIRECTORY ${OPENSSL_INSTALL_DIR}/include)

# Build OpenSSL for WebAssembly using custom commands
add_custom_command(
    OUTPUT ${OPENSSL_INSTALL_DIR}/lib/libssl.a ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${OPENSSL_SOURCE_DIR} ${OPENSSL_BUILD_DIR}
    COMMAND ${CMAKE_COMMAND} -E chdir ${OPENSSL_BUILD_DIR}
        ${CMAKE_COMMAND} -E env
        CC=${CMAKE_C_COMPILER}
        CXX=${CMAKE_CXX_COMPILER}
        AR=${CMAKE_AR}
        RANLIB=${CMAKE_RANLIB}
        perl Configure
        linux-generic32
        no-shared
        no-dso
        no-engine
        no-unit-test
        no-ui-console
        no-tests
        no-asm
        no-threads
        --prefix=${OPENSSL_INSTALL_DIR}
        --openssldir=${OPENSSL_INSTALL_DIR}
    COMMAND ${CMAKE_COMMAND} -E chdir ${OPENSSL_BUILD_DIR} emmake make -j1
    COMMAND ${CMAKE_COMMAND} -E chdir ${OPENSSL_BUILD_DIR} emmake make install_sw
    DEPENDS ${OPENSSL_SOURCE_DIR}/Configure
    COMMENT "Building OpenSSL for WebAssembly"
    VERBATIM
)

# Create a custom target for OpenSSL
add_custom_target(openssl_build_target
    DEPENDS ${OPENSSL_INSTALL_DIR}/lib/libssl.a ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
)

# Main executable
add_executable(${PROJECT_NAME} src/main.cpp)

# Add dependency on OpenSSL build
add_dependencies(${PROJECT_NAME} openssl_build_target)

# Set include directories and link libraries
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
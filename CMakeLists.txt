cmake_minimum_required(VERSION 3.8)
project(dapware_crypto VERSION 0.1.0)

# Require Emscripten
if(NOT EMSCRIPTEN)
  message(FATAL_ERROR "This project must be built with Emscripten")
endif()

# Set OpenSSL include and lib paths (adjust to your environment)
set(OPENSSL_ROOT "path/to/openssl")
include_directories(${OPENSSL_ROOT}/include)
link_directories(${OPENSSL_ROOT}/lib)

set(SOURCES main.cpp)

add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(${PROJECT_NAME} 
  ssl
  crypto
)

# Emscripten link flags without modularize
set_target_properties(${PROJECT_NAME} PROPERTIES
  LINK_FLAGS "--bind -s WASM=1 -s ALLOW_MEMORY_GROWTH=1"
)

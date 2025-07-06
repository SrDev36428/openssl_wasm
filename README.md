Job Title:

Build OpenSSL Encrypt/Decrypt to WebAssembly (Emscripten + CMake, Windows/VS)


Description:

I have C++ functions for `encrypt` and `decrypt` using OpenSSL (AES-256-CBC + SHA256). I need them compiled to WebAssembly using Emscripten, built with CMake, on Windows using Visual Studio.

You’ll export the functions to JavaScript using `embind`, and provide a simple HTML demo that encrypts and decrypts a string using the WebAssembly module.


Requirements:

 Use OpenSSL only (no other crypto libraries)
 Build on Windows with Visual Studio + Emscripten
 Use CMake for building
 Export `encrypt` and `decrypt` via embind
 Provide a simple HTML+JS demo to show usage

Deliverables:

 CMake-based build system
 WebAssembly output (`.wasm` + JS glue)
 Simple working HTML demo
 README with clear Windows build steps

Timeline:

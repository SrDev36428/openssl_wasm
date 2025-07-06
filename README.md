# OpenSSL WebAssembly Crypto Demo

A complete WebAssembly implementation of OpenSSL encryption/decryption using AES-256-CBC with PBKDF2 key derivation.

## 🚀 Features

- **AES-256-CBC Encryption**: Industry-standard symmetric encryption
- **PBKDF2 Key Derivation**: Secure password-based key derivation with 10,000 iterations
- **WebAssembly Performance**: Native-speed cryptography in the browser
- **Self-Contained Build**: No external dependencies or system libraries required
- **Visual Studio Compatible**: Built with CMake and Emscripten on Windows

## 📋 Prerequisites

### Required Software

1. **Visual Studio 2019 or later** (Community Edition is fine)
   - Install "Desktop development with C++" workload
   - Ensure MSVC compiler and CMake are installed

2. **Emscripten SDK**
   ```bash
   # Download and install Emscripten
   git clone https://github.com/emscripten-core/emsdk.git C:\emsdk
   cd C:\emsdk
   emsdk install latest
   emsdk activate latest
   ```

3. **Git** (for downloading dependencies)

### System Requirements

- Windows 10 or later (for tar extraction support)
- At least 2GB free disk space
- Internet connection (for downloading OpenSSL source)

## 🛠️ Build Instructions

### Quick Start (Recommended)

1. **Clone the Project**
   ```bash
   git clone <your-repo-url>
   cd openssl-wasm-crypto
   ```

2. **Setup OpenSSL Source**
   ```bash
   scripts\setup_openssl.bat
   ```

3. **Build Everything (with automatic Emscripten activation)**
   ```bash
   # If emsdk is installed at C:\emsdk (default)
   scripts\activate_and_build.bat
   
   # If emsdk is installed elsewhere
   scripts\activate_and_build.bat "C:\path\to\your\emsdk"
   ```

4. **Test the Demo**
   ```bash
   scripts\serve.bat
   ```
   Then open http://localhost:8000 in your browser.

### Manual Build Process

If you prefer to activate Emscripten manually:

1. **Open Developer Command Prompt for VS**

2. **Activate Emscripten**
   ```bash
   cd C:\emsdk
   emsdk_env.bat
   ```

3. **Setup OpenSSL** (if not done already)
   ```bash
   cd C:\path\to\your\project
   scripts\setup_openssl.bat
   ```

4. **Build the Project**
   ```bash
   scripts\build.bat
   ```

## 📁 Project Structure

```
openssl-wasm-crypto/
├── src/
│   └── main.cpp                    # Main C++ source with crypto functions
├── template/
│   └── shell.html                  # HTML template for the demo
├── scripts/
│   ├── setup_openssl.bat           # OpenSSL download and setup
│   ├── activate_and_build.bat      # Build with automatic Emscripten activation
│   ├── build.bat                   # Build script (requires manual activation)
│   └── serve.bat                   # Local web server for testing
├── third_party/
│   └── openssl/                    # OpenSSL source (created by setup script)
├── build/                          # CMake build directory
├── dist/                           # Final output files
│   ├── index.html                  # Demo page
│   ├── openssl_crypto.js           # JavaScript glue code
│   └── openssl_crypto.wasm         # WebAssembly binary
├── CMakeLists.txt                  # CMake configuration
└── README.md                       # This file
```

## 🔧 Technical Details

### Encryption Specifications

- **Algorithm**: AES-256-CBC
- **Key Derivation**: PBKDF2 with SHA-256
- **Iterations**: 10,000 (OWASP recommended minimum)
- **IV Generation**: SHA-256 of salt (first 16 bytes)
- **Padding**: PKCS#7 (automatic with OpenSSL)

### WebAssembly Integration

- **Binding**: Emscripten Embind for C++ to JavaScript
- **Module Type**: Modularized (not global)
- **Memory**: Dynamic growth enabled
- **Exports**: `encrypt()`, `decrypt()`, `getVersion()` functions

### Build Configuration

- **Compiler**: Emscripten (emcc/em++)
- **Build System**: CMake with ExternalProject
- **OpenSSL Config**: Static libraries, no shared objects
- **Optimization**: Release mode with size optimization

## 🧪 Usage Examples

### JavaScript API

```javascript
// Wait for module to load
OpenSSLModule().then(module => {
    // Encrypt data
    const encrypted = module.encrypt("Hello World", "password123", "salt456");
    
    // Decrypt data
    const decrypted = module.decrypt(encrypted, "password123", "salt456");
    
    console.log("Original:", "Hello World");
    console.log("Decrypted:", decrypted);
});
```

### HTML Integration

```html
<script src="openssl_crypto.js"></script>
<script>
    OpenSSLModule().then(crypto => {
        // Use crypto.encrypt() and crypto.decrypt()
    });
</script>
```

## 🔍 Troubleshooting

### Common Issues

1. **"Emscripten not found"**
   - Use `activate_and_build.bat` instead of `build.bat`
   - Or manually activate: `cd C:\emsdk && emsdk_env.bat`

2. **"OpenSSL source not found"**
   - Run `scripts\setup_openssl.bat` first
   - Check internet connection

3. **"CMake configuration failed"**
   - Ensure Visual Studio C++ tools are installed
   - Use Developer Command Prompt for VS
   - Try the automatic activation script

4. **"Build failed"**
   - Check that all prerequisites are installed
   - Ensure sufficient disk space (2GB+)
   - Try building with single thread (script will retry automatically)

5. **"WebAssembly module failed to load"**
   - Serve files from a web server (not file://)
   - Check browser console for detailed errors

### Environment Verification

To check if Emscripten is properly activated, run:
```bash
emcc --version
echo %EMSCRIPTEN%
echo %EMSDK%
```

You should see version information and paths to your emsdk installation.

### Build Verification

After a successful build, you should have:
- `dist/openssl_crypto.wasm` (~2-3MB)
- `dist/openssl_crypto.js` (~100KB)
- `dist/index.html` (demo page)

## 🚀 Deployment

The `dist/` directory contains all files needed for deployment:

1. **Static Hosting**: Upload all files to any web server
2. **CDN**: Host WASM and JS files on a CDN
3. **Integration**: Include in existing web applications

### CORS Considerations

When hosting on a different domain, ensure proper CORS headers for `.wasm` files:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type
```

## 📝 License

This project uses OpenSSL, which is licensed under the Apache License 2.0.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review build logs in the `build/` directory
3. Open an issue with detailed error messages

---

**Built with ❤️ using OpenSSL, Emscripten, and CMake**
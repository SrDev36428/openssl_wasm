@echo off
setlocal enabledelayedexpansion

echo OpenSSL WebAssembly Build Script
echo ================================

:: Check if Emscripten is available
where emcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Emscripten not found in PATH
    echo Please install and activate Emscripten SDK first
    echo.
    echo To activate Emscripten:
    echo 1. Open Developer Command Prompt for VS
    echo 2. Navigate to your emsdk directory
    echo 3. Run: emsdk activate latest
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

:: Verify Emscripten environment
echo Checking Emscripten environment...
echo EMSCRIPTEN: %EMSCRIPTEN%
echo EMSDK: %EMSDK%

if "%EMSCRIPTEN%"=="" (
    echo Error: EMSCRIPTEN environment variable not set
    echo Please run 'emsdk activate latest' first
    pause
    exit /b 1
)

:: Set up directories
set PROJECT_ROOT=%~dp0..
set BUILD_DIR=%PROJECT_ROOT%\build
set DIST_DIR=%PROJECT_ROOT%\dist

echo Project root: %PROJECT_ROOT%
echo Build directory: %BUILD_DIR%
echo Distribution directory: %DIST_DIR%

:: Check if OpenSSL source exists
if not exist "%PROJECT_ROOT%\third_party\openssl\Configure" (
    echo Error: OpenSSL source not found
    echo Please run setup_openssl.bat first
    pause
    exit /b 1
)

:: Clean and create build directory
echo Cleaning build directory...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

:: Clean and create dist directory
echo Cleaning distribution directory...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"

:: Configure with CMake
echo Configuring with CMake...
cd /d "%BUILD_DIR%"

:: Use emcmake to ensure proper Emscripten environment
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"

if %errorlevel% neq 0 (
    echo.
    echo CMake configuration failed!
    echo.
    echo Common solutions:
    echo 1. Make sure you're using Developer Command Prompt for VS
    echo 2. Ensure Emscripten is properly activated: emsdk activate latest
    echo 3. Check that OpenSSL source was downloaded: scripts\setup_openssl.bat
    echo.
    pause
    exit /b 1
)

:: Build the project
echo.
echo Building project...
echo This may take several minutes as OpenSSL is being compiled from source...
echo.

:: Use emmake to ensure proper Emscripten build environment
emmake make -j4

if %errorlevel% neq 0 (
    echo.
    echo Build failed!
    echo Check the error messages above for details.
    echo.
    pause
    exit /b 1
)

:: Copy output files to dist directory
echo.
echo Copying output files...
if exist "openssl_crypto.wasm" (
    copy "openssl_crypto.wasm" "%DIST_DIR%\" >nul
    echo ✓ Copied openssl_crypto.wasm
) else (
    echo ✗ openssl_crypto.wasm not found
)

if exist "openssl_crypto.js" (
    copy "openssl_crypto.js" "%DIST_DIR%\" >nul
    echo ✓ Copied openssl_crypto.js
) else (
    echo ✗ openssl_crypto.js not found
)

if exist "openssl_crypto.html" (
    copy "openssl_crypto.html" "%DIST_DIR%\index.html" >nul
    echo ✓ Copied index.html
) else (
    echo ✗ openssl_crypto.html not found
)

:: Verify critical files were created
if not exist "%DIST_DIR%\openssl_crypto.wasm" (
    echo.
    echo Error: WASM file was not created!
    echo The build may have failed. Check the output above for errors.
    pause
    exit /b 1
)

if not exist "%DIST_DIR%\openssl_crypto.js" (
    echo.
    echo Error: JavaScript file was not created!
    echo The build may have failed. Check the output above for errors.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Output directory: %DIST_DIR%
echo.
echo Files created:
for %%f in ("%DIST_DIR%\*") do echo   %%~nxf
echo.
echo To test the demo:
echo   1. Run: scripts\serve.bat
echo   2. Open http://localhost:8000 in your browser
echo.
echo Or manually start a web server in the dist directory:
echo   cd dist
echo   python -m http.server 8000
echo.
pause
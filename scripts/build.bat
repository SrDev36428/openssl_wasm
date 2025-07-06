@echo off
setlocal enabledelayedexpansion

echo OpenSSL WebAssembly Build Script
echo ================================

:: Check if Emscripten is available
where emcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Emscripten not found in PATH
    echo Please install and activate Emscripten SDK first
    echo Visit: https://emscripten.org/docs/getting_started/downloads.html
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
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"

if %errorlevel% neq 0 (
    echo CMake configuration failed
    pause
    exit /b 1
)

:: Build the project
echo Building project...
echo This may take several minutes as OpenSSL is being compiled...
emmake make -j4

if %errorlevel% neq 0 (
    echo Build failed
    pause
    exit /b 1
)

:: Copy output files to dist directory
echo Copying output files...
if exist "openssl_crypto.wasm" copy "openssl_crypto.wasm" "%DIST_DIR%\" >nul
if exist "openssl_crypto.js" copy "openssl_crypto.js" "%DIST_DIR%\" >nul
if exist "openssl_crypto.html" copy "openssl_crypto.html" "%DIST_DIR%\index.html" >nul

:: Verify files were created
if not exist "%DIST_DIR%\openssl_crypto.wasm" (
    echo Error: WASM file was not created
    echo Check build output above for errors
    pause
    exit /b 1
)

if not exist "%DIST_DIR%\openssl_crypto.js" (
    echo Error: JS file was not created
    echo Check build output above for errors
    pause
    exit /b 1
)

echo Build completed successfully!
echo Output files are in: %DIST_DIR%
echo.
echo Files created:
dir "%DIST_DIR%" /b
echo.
echo To test the demo:
echo 1. Run: scripts\serve.bat
echo 2. Open http://localhost:8000 in your browser
echo.
pause
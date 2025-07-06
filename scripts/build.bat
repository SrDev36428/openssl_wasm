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
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release

if %errorlevel% neq 0 (
    echo CMake configuration failed
    pause
    exit /b 1
)

:: Build the project
echo Building project...
emmake make -j4

if %errorlevel% neq 0 (
    echo Build failed
    pause
    exit /b 1
)

:: Copy output files to dist directory
echo Copying output files...
copy "openssl_crypto.wasm" "%DIST_DIR%\" >nul
copy "openssl_crypto.js" "%DIST_DIR%\" >nul
copy "openssl_crypto.html" "%DIST_DIR%\index.html" >nul

echo Build completed successfully!
echo Output files are in: %DIST_DIR%
echo.
echo To test the demo:
echo 1. Start a local web server in the dist directory
echo 2. Open index.html in your browser
echo.
echo Example using Python:
echo   cd dist
echo   python -m http.server 8000
echo   Open http://localhost:8000 in your browser
echo.
pause
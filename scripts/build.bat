@echo off
setlocal enabledelayedexpansion

echo OpenSSL WebAssembly Build Script
echo ================================

:: Check if we're in the right directory
if not exist "%~dp0..\CMakeLists.txt" (
    echo Error: CMakeLists.txt not found. Please run this script from the scripts directory.
    pause
    exit /b 1
)

:: Check if Emscripten is available
where emcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Emscripten not found in PATH
    echo.
    echo Please use activate_and_build.bat instead, or manually activate Emscripten:
    echo 1. cd C:\emsdk
    echo 2. emsdk_env.bat
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

:: Check for required Emscripten tools
where em++ >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: em++ not found in PATH
    echo Please ensure Emscripten is properly activated
    pause
    exit /b 1
)

where emcmake >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: emcmake not found in PATH
    echo Please ensure Emscripten is properly activated
    pause
    exit /b 1
)

:: Display Emscripten info
echo Emscripten detected:
emcc --version | findstr "emcc"
echo.

:: Set up directories
set PROJECT_ROOT=%~dp0..
set BUILD_DIR=%PROJECT_ROOT%\build
set DIST_DIR=%PROJECT_ROOT%\dist

echo Project root: %PROJECT_ROOT%
echo Build directory: %BUILD_DIR%
echo Distribution directory: %DIST_DIR%
echo.

:: Check if OpenSSL source exists
if not exist "%PROJECT_ROOT%\third_party\openssl\Configure" (
    echo Error: OpenSSL source not found
    echo Please run setup_openssl.bat first
    echo.
    pause
    exit /b 1
)

:: Clean and create build directory
echo Cleaning build directory...
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%" 2>nul
    if exist "%BUILD_DIR%" (
        echo Warning: Could not completely clean build directory
        echo Some files may be in use. Continuing anyway...
    )
)
mkdir "%BUILD_DIR%" 2>nul

:: Clean and create dist directory
echo Cleaning distribution directory...
if exist "%DIST_DIR%" (
    rmdir /s /q "%DIST_DIR%" 2>nul
)
mkdir "%DIST_DIR%" 2>nul

:: Configure with CMake using emcmake
echo Configuring with emcmake...
cd /d "%BUILD_DIR%"

:: Configure with emcmake
echo Attempting configuration...
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release

if %errorlevel% neq 0 (
    echo.
    echo CMake configuration failed!
    echo.
    echo Debug information:
    echo EMSCRIPTEN: %EMSCRIPTEN%
    echo EMSDK: %EMSDK%
    echo.
    echo Emscripten tools found:
    where emcc 2>nul || echo emcc: NOT FOUND
    where em++ 2>nul || echo em++: NOT FOUND
    where emcmake 2>nul || echo emcmake: NOT FOUND
    echo.
    pause
    exit /b 1
)

:: Build the project
echo.
echo Building project...
echo This will take several minutes as OpenSSL is compiled from source...
echo Please be patient...
echo.

:: Use emmake make instead of just make
emmake make -j4

if %errorlevel% neq 0 (
    echo.
    echo Build failed!
    echo.
    echo Trying with single thread...
    emmake make

    if %errorlevel% neq 0 (
        echo.
        echo Build failed even with single thread!
        echo Check the output above for specific error messages.
        echo.
        pause
        exit /b 1
    )
)

:: Verify and copy output files
echo.
echo Verifying build outputs...

set FILES_COPIED=0

if exist "openssl_crypto.wasm" (
    copy "openssl_crypto.wasm" "%DIST_DIR%\" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ Copied openssl_crypto.wasm
        set /a FILES_COPIED+=1
    ) else (
        echo ✗ Failed to copy openssl_crypto.wasm
    )
) else (
    echo ✗ openssl_crypto.wasm not found
)

if exist "openssl_crypto.js" (
    copy "openssl_crypto.js" "%DIST_DIR%\" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ Copied openssl_crypto.js
        set /a FILES_COPIED+=1
    ) else (
        echo ✗ Failed to copy openssl_crypto.js
    )
) else (
    echo ✗ openssl_crypto.js not found
)

if exist "openssl_crypto.html" (
    copy "openssl_crypto.html" "%DIST_DIR%\index.html" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ Copied index.html
        set /a FILES_COPIED+=1
    ) else (
        echo ✗ Failed to copy index.html
    )
) else (
    echo ✗ openssl_crypto.html not found
)

:: Check if we got the essential files
if %FILES_COPIED% lss 2 (
    echo.
    echo Error: Essential files were not created!
    echo Expected: openssl_crypto.wasm and openssl_crypto.js
    echo.
    echo Files in build directory:
    dir /b *.wasm *.js *.html 2>nul
    echo.
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
dir /b "%DIST_DIR%"
echo.
echo To test the demo:
echo   1. Run: scripts\serve.bat
echo   2. Open http://localhost:8000 in your browser
echo.
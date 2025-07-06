@echo off
setlocal enabledelayedexpansion

echo OpenSSL WebAssembly Build with Emscripten Activation
echo ====================================================

:: Check if EMSDK path is provided as argument or try to find it
set EMSDK_PATH=%1
if "%EMSDK_PATH%"=="" (
    :: Try common locations
    if exist "C:\emsdk\emsdk_env.bat" (
        set EMSDK_PATH=C:\emsdk
    ) else if exist "%USERPROFILE%\emsdk\emsdk_env.bat" (
        set EMSDK_PATH=%USERPROFILE%\emsdk
    ) else (
        echo Error: Could not find emsdk installation
        echo.
        echo Please provide the path to your emsdk directory:
        echo Usage: %0 "C:\path\to\emsdk"
        echo.
        echo Or install emsdk to C:\emsdk
        echo.
        pause
        exit /b 1
    )
)

echo Using EMSDK at: %EMSDK_PATH%

:: Check if emsdk_env.bat exists
if not exist "%EMSDK_PATH%\emsdk_env.bat" (
    echo Error: emsdk_env.bat not found at %EMSDK_PATH%
    echo Please check your emsdk installation
    pause
    exit /b 1
)

:: Activate Emscripten
echo Activating Emscripten...
call "%EMSDK_PATH%\emsdk_env.bat"

if %errorlevel% neq 0 (
    echo Error: Failed to activate Emscripten
    pause
    exit /b 1
)

:: Verify activation
echo.
echo Verifying Emscripten activation...
where emcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: emcc not found after activation
    echo Please check your emsdk installation
    pause
    exit /b 1
)

:: Show version info
echo Emscripten activated successfully:
emcc --version | findstr "emcc"
echo.

:: Now run the build
echo Starting build process...
echo.
call "%~dp0build.bat"

echo.
echo Build process completed.
pause
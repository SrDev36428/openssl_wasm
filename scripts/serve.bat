@echo off
setlocal

set DIST_DIR=%~dp0..\dist

if not exist "%DIST_DIR%\index.html" (
    echo Error: Built files not found in dist directory
    echo Please run build.bat first
    pause
    exit /b 1
)

echo Starting local web server...
echo Open http://localhost:8000 in your browser
echo Press Ctrl+C to stop the server
echo.

cd /d "%DIST_DIR%"

:: Try different methods to start a web server
where python >nul 2>&1
if %errorlevel% equ 0 (
    python -m http.server 8000
    goto :end
)

where python3 >nul 2>&1
if %errorlevel% equ 0 (
    python3 -m http.server 8000
    goto :end
)

where node >nul 2>&1
if %errorlevel% equ 0 (
    npx http-server -p 8000
    goto :end
)

echo Error: No suitable web server found
echo Please install Python or Node.js to run the demo
pause

:end
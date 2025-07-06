@echo off
setlocal enabledelayedexpansion

echo Setting up OpenSSL for WebAssembly build...

set OPENSSL_VERSION=1.1.1w
set OPENSSL_URL=https://www.openssl.org/source/old/1.1.1/openssl-%OPENSSL_VERSION%.tar.gz
set THIRD_PARTY_DIR=%~dp0..\third_party
set OPENSSL_DIR=%THIRD_PARTY_DIR%\openssl

echo Creating third_party directory...
if not exist "%THIRD_PARTY_DIR%" mkdir "%THIRD_PARTY_DIR%"

echo Checking if OpenSSL source already exists...
if exist "%OPENSSL_DIR%\Configure" (
    echo OpenSSL source already exists at %OPENSSL_DIR%
    echo Skipping download...
    goto :end
)

echo Downloading OpenSSL %OPENSSL_VERSION%...
cd /d "%THIRD_PARTY_DIR%"

:: Download using PowerShell (available on Windows 7+)
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%OPENSSL_URL%' -OutFile 'openssl.tar.gz'}"

if not exist "openssl.tar.gz" (
    echo Failed to download OpenSSL
    exit /b 1
)

echo Extracting OpenSSL...
:: Extract using tar (available in Windows 10+) or 7-zip if available
tar -xzf openssl.tar.gz 2>nul || (
    echo Tar extraction failed, trying 7-zip...
    7z x openssl.tar.gz -so | 7z x -aoa -si -ttar || (
        echo Failed to extract OpenSSL. Please install 7-zip or use Windows 10+
        exit /b 1
    )
)

:: Rename extracted directory
for /d %%i in (openssl-*) do (
    if exist "%%i" (
        move "%%i" "openssl" >nul
        break
    )
)

:: Clean up
del openssl.tar.gz

:end
echo OpenSSL setup completed successfully!
echo Source location: %OPENSSL_DIR%
pause
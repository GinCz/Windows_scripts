@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] PLEASE RUN AS ADMINISTRATOR TO INSTALL SOFTWARE AND RUN TESTS.
    pause
    exit /b 1
)

:: Enable ANSI colors
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[37m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

:: 1. ARCHITECTURE DETECTION & AUTO-INSTALL
set "INSTALL_DIR=C:\Program Files\7-Zip"
set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"

if not exist "!INSTALL_PATH!" (
    echo %Y%[!] 7-Zip NOT detected. Preparing installation...%X%

    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
        set "ARCH=x64"
        set "DL_URL=https://www.7-zip.org/a/7z2601-x64.exe"
    ) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        set "ARCH=arm64"
        set "DL_URL=https://www.7-zip.org/a/7z2601-arm64.exe"
    ) else (
        set "ARCH=x86"
        set "DL_URL=https://www.7-zip.org/a/7z2601.exe"
        set "INSTALL_DIR=C:\Program Files (x86)\7-Zip"
        set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"
    )

    echo %W%[-] Detected Architecture: !ARCH!%X%
    echo %W%[-] Downloading: !DL_URL!%X%
    curl -L -o "%TEMP%\7z_setup.exe" "!DL_URL!"

    if not exist "%TEMP%\7z_setup.exe" (
        echo %R%[!] DOWNLOAD FAILED. Check internet connection.%X%
        pause
        exit /b 1
    )

    echo %W%[-] Installing silently...%X%
    start /wait "" "%TEMP%\7z_setup.exe" /S
    del "%TEMP%\7z_setup.exe"

    if exist "!INSTALL_PATH!" (
        echo %G%[OK] 7-Zip installed: !INSTALL_PATH!%X%
    ) else (
        echo %R%[!] INSTALLATION FAILED. Please install manually from 7-zip.org%X%
        pause
        exit /b 1
    )
    echo.
) else (
    echo %G%[OK] 7-Zip found: !INSTALL_PATH!%X%
    echo.
)

:: 2. HARDWARE STRESS TEST
echo %Y%================================================================================%X%
echo %B%  HARDWARE DIAGNOSTIC: RAM ^& CPU STRESS TEST v2026-05-05%X%
echo %Y%================================================================================%X%
echo.
echo %W%  CPU Target : 4 Threads%X%
echo %W%  RAM Stress : Dictionary 256MB (Uses ~4-5 GB RAM)%X%
echo.

for /L %%i in (1,1,10) do (
    echo %Y%[ PASS %%i / 10 ] - %TIME%%X%
    "!INSTALL_PATH!" b -mmt4 -md=256m

    if !errorlevel! neq 0 (
        echo.
        echo %R%[FATAL ERROR] HARDWARE INSTABILITY DETECTED AT PASS %%i!%X%
        echo %W%  Compression error found. RAM or CPU may be faulty or overheating.%X%
        pause
        exit /b 1
    )
    echo %G%[ OK ] Pass %%i finished without errors.%X%
    echo.
)

echo.
echo %Y%================================================================================%X%
echo %G%  DIAGNOSTIC COMPLETE: YOUR HARDWARE IS STABLE%X%
echo %Y%================================================================================%X%
echo.
echo = Rooted by VladiMIR ^| AI =
pause

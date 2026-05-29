@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: ==========================================================================================
:: FILE    : MemTest_7z.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   RAM and CPU hardware stress test using the 7-Zip built-in benchmark.
::   Automatically detects system architecture (x64, ARM64, x86).
::   If 7-Zip is not installed, downloads and installs it silently.
::   Runs 10 benchmark passes with a 256MB dictionary on 4 threads.
::   A drop in performance between passes may indicate RAM instability,
::   overheating, or CPU throttling issues.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11
::   - Active internet connection (if 7-Zip not installed)
::   - Must be run as Administrator
::
:: USAGE:
::   1. Right-click MemTest_7z.bat -> Run as administrator
::   2. 7-Zip is auto-installed if not found
::   3. Benchmark runs 10 passes automatically
::   4. Review output for performance consistency across passes
::
:: INTERPRETING RESULTS:
::   - Consistent MIPS scores across all 10 passes = hardware is stable
::   - Dropping scores over time = possible thermal throttling or RAM errors
::   - Immediate crash / freeze = severe hardware instability detected
:: ==========================================================================================

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b 1
)

:: Enable ANSI colors
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[37m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

:: HEADER
echo %Y%================================================================================%X%
echo %B%       MemTest_7z.bat  ^|  RAM ^& CPU Hardware Stress Test%X%
echo %W%       = Rooted by VladiMIR ^| AI =  ^|  v2026.05.29d%X%
echo %Y%================================================================================%X%
echo.

:: 1. REAL ARCHITECTURE DETECTION
::    PROCESSOR_ARCHITEW6432 only exists in WOW64 (32-bit CMD on 64-bit OS)
set "REAL_ARCH=x86"
if defined PROCESSOR_ARCHITEW6432 (
    if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "REAL_ARCH=x64"
    if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "REAL_ARCH=arm64"
) else (
    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "REAL_ARCH=x64"
    if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "REAL_ARCH=arm64"
)

:: 2. FIND 7-Zip (x64 first, then x86)
set "INSTALL_PATH=C:\Program Files\7-Zip\7z.exe"
if not exist "!INSTALL_PATH!" set "INSTALL_PATH=C:\Program Files (x86)\7-Zip\7z.exe"

if not exist "!INSTALL_PATH!" (
    echo %Y%[!] 7-Zip NOT detected. Preparing installation...%X%

    if "!REAL_ARCH!"=="x64" (
        set "DL_URL=https://www.7-zip.org/a/7z2601-x64.exe"
        set "INSTALL_PATH=C:\Program Files\7-Zip\7z.exe"
    ) else if "!REAL_ARCH!"=="arm64" (
        set "DL_URL=https://www.7-zip.org/a/7z2601-arm64.exe"
        set "INSTALL_PATH=C:\Program Files\7-Zip\7z.exe"
    ) else (
        set "DL_URL=https://www.7-zip.org/a/7z2601.exe"
        set "INSTALL_PATH=C:\Program Files (x86)\7-Zip\7z.exe"
    )

    set "TMP_SETUP=%TEMP%\7z_setup_memtest.exe"
    echo %W% Downloading 7-Zip for !REAL_ARCH!...%X%
    powershell -NoProfile -Command "(New-Object System.Net.WebClient).DownloadFile('!DL_URL!', '!TMP_SETUP!')"

    if not exist "!TMP_SETUP!" (
        echo %R%[!] Download failed. Cannot proceed.%X%
        pause
        exit /b 1
    )

    echo %W% Installing 7-Zip silently...%X%
    start /wait "" "!TMP_SETUP!" /S
    del /f /q "!TMP_SETUP!" 2>nul

    if not exist "!INSTALL_PATH!" (
        echo %R%[!] 7-Zip installation failed.%X%
        pause
        exit /b 1
    )
    echo %G%[OK] 7-Zip installed successfully.%X%
    echo.
)

echo %G%[OK] 7-Zip found: !INSTALL_PATH!%X%
echo %W% Architecture: !REAL_ARCH!%X%
echo.

:: 3. RUN BENCHMARK
echo %B% Starting RAM ^& CPU stress test...%X%
echo %W% Parameters: 10 passes | 256MB dictionary | 4 threads%X%
echo.

"!INSTALL_PATH!" b -mmt4 -md256m 10

echo.
echo %G%[DONE] Stress test completed.%X%
echo %W% Review MIPS scores above for consistency across all 10 passes.%X%
echo %Y% Inconsistent scores may indicate RAM or CPU stability issues.%X%
echo.
echo %Y% = Rooted by VladiMIR ^| AI =%X%
echo.
pause
endlocal

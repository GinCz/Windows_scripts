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

:: ---------------------------------------------------------------
:: 1. ARCHITECTURE DETECTION & AUTO-INSTALL 7-Zip
:: ---------------------------------------------------------------
set "INSTALL_DIR=C:\Program Files\7-Zip"
set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"

:: Prefer x64 path, fallback to x86
if not exist "!INSTALL_PATH!" (
    set "INSTALL_DIR=C:\Program Files (x86)\7-Zip"
    set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"
)

if not exist "!INSTALL_PATH!" (
    echo %Y%[!] 7-Zip NOT detected. Preparing installation...%X%

    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
        set "ARCH=x64"
        set "DL_URL=https://www.7-zip.org/a/7z2601-x64.exe"
        set "INSTALL_DIR=C:\Program Files\7-Zip"
    ) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        set "ARCH=arm64"
        set "DL_URL=https://www.7-zip.org/a/7z2601-arm64.exe"
        set "INSTALL_DIR=C:\Program Files\7-Zip"
    ) else (
        set "ARCH=x86"
        set "DL_URL=https://www.7-zip.org/a/7z2601.exe"
        set "INSTALL_DIR=C:\Program Files (x86)\7-Zip"
    )
    set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"

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

:: ---------------------------------------------------------------
:: 2. DETECT AVAILABLE RAM -> choose dictionary size automatically
::
::   RAM < 4 GB  -> 32m  (safe for 2 GB machines, ~800 MB usage)
::   RAM < 8 GB  -> 64m  (~1.6 GB usage on 4 threads)
::   RAM < 16 GB -> 128m (~3.2 GB usage on 4 threads)
::   RAM >= 16GB -> 256m (~6.5 GB usage on 4 threads)
:: ---------------------------------------------------------------
echo %W%[-] Detecting RAM...%X%

for /f "skip=1 tokens=2" %%M in ('wmic OS get TotalVisibleMemorySize') do (
    if not defined RAM_KB set "RAM_KB=%%M"
)
set /a RAM_MB=RAM_KB/1024

if !RAM_MB! LSS 4096 (
    set "DICT=32m"
    set "RAM_NOTE=!RAM_MB! MB (LOW) - safe 32m dictionary"
) else if !RAM_MB! LSS 8192 (
    set "DICT=64m"
    set "RAM_NOTE=!RAM_MB! MB - 64m dictionary"
) else if !RAM_MB! LSS 16384 (
    set "DICT=128m"
    set "RAM_NOTE=!RAM_MB! MB - 128m dictionary"
) else (
    set "DICT=256m"
    set "RAM_NOTE=!RAM_MB! MB - full 256m dictionary"
)

:: Detect logical CPU thread count, cap at 8
for /f "skip=1" %%C in ('wmic cpu get NumberOfLogicalProcessors') do (
    if not defined CPU_THREADS if not "%%C"=="" set "CPU_THREADS=%%C"
)
if not defined CPU_THREADS set "CPU_THREADS=4"
if !CPU_THREADS! GTR 8 set "CPU_THREADS=8"

:: ---------------------------------------------------------------
:: 3. HARDWARE STRESS TEST - 10 passes
:: ---------------------------------------------------------------
echo %Y%================================================================================%X%
echo %B%  HARDWARE DIAGNOSTIC: RAM ^& CPU STRESS TEST v2026-05-05%X%
echo %Y%================================================================================%X%
echo.
echo %W%  CPU Threads : !CPU_THREADS!%X%
echo %W%  RAM         : !RAM_NOTE!%X%
echo %W%  Dictionary  : !DICT! per thread%X%
echo.

for /L %%i in (1,1,10) do (
    echo %Y%[ PASS %%i / 10 ] - %TIME%%X%
    "!INSTALL_PATH!" b -mmt!CPU_THREADS! -md=!DICT!

    if !errorlevel! neq 0 (
        echo.
        echo %R%[FATAL ERROR] HARDWARE INSTABILITY DETECTED AT PASS %%i!%X%
        echo %W%  Compression error. RAM or CPU may be faulty or overheating.%X%
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

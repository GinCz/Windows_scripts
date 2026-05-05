:: ============================================================
:: FILE: MemTest_7z.bat
:: DESC: RAM & CPU Hardware Stress Test via 7-Zip benchmark
:: AUTH: = Rooted by VladiMIR | AI =
:: DATE: v2026-05-05
:: REPO: github.com/GinCz/Windows_scripts
:: ============================================================
@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

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

:: ---------------------------------------------------------------
:: HEADER
:: ---------------------------------------------------------------
echo %Y%================================================================================%X%
echo %B%       MemTest_7z.bat  ^|  RAM ^& CPU Hardware Stress Test%X%
echo %W%       = Rooted by VladiMIR ^| AI =  ^|  v2026-05-05%X%
echo %Y%================================================================================%X%
echo.

:: ---------------------------------------------------------------
:: 1. REAL ARCHITECTURE DETECTION
::    PROCESSOR_ARCHITEW6432 only exists in WOW64 (32-bit CMD on 64-bit OS)
:: ---------------------------------------------------------------
set "REAL_ARCH=x86"
if defined PROCESSOR_ARCHITEW6432 (
    if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "REAL_ARCH=x64"
    if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "REAL_ARCH=arm64"
) else (
    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "REAL_ARCH=x64"
    if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "REAL_ARCH=arm64"
)

:: ---------------------------------------------------------------
:: 2. FIND 7-Zip (x64 first, then x86)
:: ---------------------------------------------------------------
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

    echo %W%[-] Real OS Architecture : %Y%!REAL_ARCH!%X%
    echo %W%[-] Downloading          : !DL_URL!%X%
    curl -L -o "%TEMP%\7z_setup.exe" "!DL_URL!"

    if not exist "%TEMP%\7z_setup.exe" (
        echo %R%[!] DOWNLOAD FAILED.%X%
        pause & exit /b 1
    )

    start /wait "" "%TEMP%\7z_setup.exe" /S
    del "%TEMP%\7z_setup.exe" >nul 2>&1

    set "INSTALL_PATH=C:\Program Files\7-Zip\7z.exe"
    if not exist "!INSTALL_PATH!" set "INSTALL_PATH=C:\Program Files (x86)\7-Zip\7z.exe"

    if not exist "!INSTALL_PATH!" (
        echo %R%[!] INSTALLATION FAILED. Install manually: https://www.7-zip.org%X%
        pause & exit /b 1
    )
    echo %G%[OK] 7-Zip installed: !INSTALL_PATH!%X%
    echo.
) else (
    echo %G%[OK] 7-Zip found: !INSTALL_PATH!%X%
    echo.
)

:: ---------------------------------------------------------------
:: 3. DETECT RAM via 7-Zip probe (no WMI/PowerShell/systeminfo)
::    Runs a quick 1-thread 1m-dict benchmark, parses "RAM size:" line
::    Works on ANY Windows machine regardless of policies
:: ---------------------------------------------------------------
echo %W%[-] Detecting RAM via 7-Zip probe...%X%
set "RAM_MB=0"
set "PROBE_OUT=%TEMP%\mtest_probe.txt"

"!INSTALL_PATH!" b -mmt1 -md=1m 1>"!PROBE_OUT!" 2>nul

for /f "tokens=1,2,3" %%A in ('findstr /i "RAM size" "!PROBE_OUT!" 2^>nul') do (
    set "RAM_MB=%%C"
)
del "!PROBE_OUT!" >nul 2>&1

set "RAM_MB=!RAM_MB:,=!"

if "!RAM_MB!"=="0" (
    echo %R%[!] RAM detection failed - using safe fallback 3800 MB%X%
    set "RAM_MB=3800"
) else (
    echo %G%[OK] RAM detected: !RAM_MB! MB%X%
)

:: ---------------------------------------------------------------
:: 4. DETECT CPU THREADS
::    NUMBER_OF_PROCESSORS is always present in Windows
:: ---------------------------------------------------------------
set "CPU_THREADS=%NUMBER_OF_PROCESSORS%"
if "!CPU_THREADS!"=="" set "CPU_THREADS=2"
if !CPU_THREADS! GTR 8 set "CPU_THREADS=8"

:: ---------------------------------------------------------------
:: 5. CHOOSE DICTIONARY SIZE based on detected RAM
::
::   RAM < 4 GB  -> 32m  (~800 MB  on 4 threads)
::   RAM < 8 GB  -> 64m  (~1.6 GB on 4 threads)
::   RAM < 16 GB -> 128m (~3.2 GB on 4 threads)
::   RAM >= 16GB -> 256m (~6.5 GB on 4 threads)
:: ---------------------------------------------------------------
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

:: ---------------------------------------------------------------
:: 6. HARDWARE STRESS TEST - 10 passes
:: ---------------------------------------------------------------
echo.
echo %Y%================================================================================%X%
echo %B%       MemTest_7z.bat  ^|  RAM ^& CPU Hardware Stress Test%X%
echo %W%       = Rooted by VladiMIR ^| AI =  ^|  v2026-05-05%X%
echo %Y%================================================================================%X%
echo.
echo %W%  7-Zip Path  : !INSTALL_PATH!%X%
echo %W%  OS Arch     : !REAL_ARCH!%X%
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

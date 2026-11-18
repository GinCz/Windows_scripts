@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: ULTARIX s.r.o. - Server Setup & Directory Initializer
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.1.0 (2026-11)
:: Target  : ULPS1 Server (192.168.33.128) / Admin PC
:: ============================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c pushd \"\"%~dp0\"\" && \"\"%~f0\"\" admin' -Verb RunAs"
    exit /b
)

title ULTARIX - Inicializace monitoringu na serveru [VladiMIR + Antigravity]

pushd "%~dp0" 2>nul

echo ================================================================================
echo       ULTARIX s.r.o. - Priprava slozky UTIL pro monitoring na serveru
echo ================================================================================
echo.

:: Detect UTIL directory path
set "UTIL_DIR="
if exist "D:\UTIL" set "UTIL_DIR=D:\UTIL\UltarixMonitor"
if not defined UTIL_DIR if exist "\\ULPS1\Sdílené Data\UTIL" set "UTIL_DIR=\\ULPS1\Sdílené Data\UTIL\UltarixMonitor"
if not defined UTIL_DIR if exist "\\ULPS1\ULTARIX\UTIL" set "UTIL_DIR=\\ULPS1\ULTARIX\UTIL\UltarixMonitor"
if not defined UTIL_DIR if exist "\\ULPS1\UTIL" set "UTIL_DIR=\\ULPS1\UTIL\UltarixMonitor"
if not defined UTIL_DIR if exist "E:\UTIL" set "UTIL_DIR=E:\UTIL\UltarixMonitor"
if not defined UTIL_DIR if exist "S:\UTIL" set "UTIL_DIR=S:\UTIL\UltarixMonitor"
if not defined UTIL_DIR set "UTIL_DIR=%~dp0"

echo [*] Cilova slozka monitoringu: %UTIL_DIR%

:: Create logs directory
if not exist "%UTIL_DIR%\logs" mkdir "%UTIL_DIR%\logs" >nul 2>&1

:: Copy dashboard.html if present locally
if exist "%~dp0dashboard.html" (
    copy /y "%~dp0dashboard.html" "%UTIL_DIR%\dashboard.html" >nul 2>&1
    echo [OK] Soubor dashboard.html zkopirovan do %UTIL_DIR%\dashboard.html
)

:: Set permissions on logs directory so all PCs can append logs
icacls "%UTIL_DIR%\logs" /grant Everyone:(OI)(CI)M /t /c /q >nul 2>&1
icacls "%UTIL_DIR%\logs" /grant "Everyone":(OI)(CI)F /t /c /q >nul 2>&1

echo [OK] Pristupova prava pro zapis logu ze vsech pocitacu nastavena.
echo.
echo ================================================================================
echo       SERVER JE PRIPRAVEN! ULOZISTE PRO PC-09 A OSTATNI PC AKTIVNI.
echo ================================================================================
echo.
popd 2>nul
timeout /t 5 >nul
exit /b 0

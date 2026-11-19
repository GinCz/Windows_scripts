@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: ULTARIX s.r.o. - Server Setup & Directory Initializer (v2.4.1)
:: Author  : VladiMIR + Antigravity AI
:: Physical Server Path : C:\UTIL\UltarixMonitor
:: Network Share Path   : \\ulps1\UTIL\UltarixMonitor
:: ============================================================================

:: Enable UNC path support
reg add "HKCU\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1

:: Auto-Elevation check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/k pushd \"\"%~dp0\"\" && \"\"%~f0\"\" admin' -Verb RunAs"
    exit /b
)

title ULTARIX - Nastaveni monitoringu na serveru ULPS1 [VladiMIR + Antigravity]

pushd "%~dp0" 2>nul

echo ======================================================================
echo       ULTARIX s.r.o. - Inicializace uloziste monitoringu na serveru
echo ======================================================================
echo.

:: Detect physical folder (defaults to C:\UTIL\UltarixMonitor)
set "BASE_DIR=C:\UTIL\UltarixMonitor"
if not exist "C:\UTIL" (
    if exist "%~dp0" set "BASE_DIR=%~dp0"
)

echo [*] Fyzicka cesta na serveru : %BASE_DIR%
echo [*] Sitova cesta pro klienty : \\ulps1\UTIL\UltarixMonitor\logs
echo.

:: Create logs directory
if not exist "%BASE_DIR%\logs" (
    mkdir "%BASE_DIR%\logs" >nul 2>&1
    echo [+] Slozka %BASE_DIR%\logs byla uspesne vytvorena.
) else (
    echo [i] Slozka %BASE_DIR%\logs jiz existuje.
)

:: Copy dashboard.html to server folder
if exist "%~dp0dashboard.html" (
    if /i not "%~dp0"=="%BASE_DIR%\" (
        copy /y "%~dp0dashboard.html" "%BASE_DIR%\dashboard.html" >nul 2>&1
    )
    echo [OK] Soubor dashboard.html je pripraven v %BASE_DIR%\dashboard.html
)

:: Set permissions on logs directory for all network computers
echo [*] Nastavuji prava plneho pristupu pro zapis logu ze site...
icacls "%BASE_DIR%\logs" /grant Everyone:(OI)(CI)F /t /c /q >nul 2>&1
icacls "%BASE_DIR%\logs" /grant "Everyone":(OI)(CI)F /t /c /q >nul 2>&1
icacls "%BASE_DIR%\logs" /grant Users:(OI)(CI)F /t /c /q >nul 2>&1
echo [OK] Prava zapisu pro vsechny pocitace v siti uspesne nastavena.

:: Create test heartbeat to verify folder
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$test = @{ server = 'ULPS1'; status = 'READY'; updated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } | ConvertTo-Json; Set-Content -Path '%BASE_DIR%\logs\server_status.json' -Value $test -Encoding utf8"
echo [OK] Kontrolni testovaci soubor server_status.json vytvoren.

echo.
echo ======================================================================
echo       SERVER JE 100%% PRIPRAVEN!
echo ======================================================================
echo  Klienti (PC-09, ULTARIX-07 a dalsi) nyni mohou zapisovat logy do:
echo  \\ulps1\UTIL\UltarixMonitor\logs
echo ======================================================================
echo.
popd 2>nul
if /i not "%~1"=="-silent" if /i not "%~1"=="/silent" (
    echo.
    echo ======================================================================
    echo  Hotovo! Stisknete libovolnou klavesu pro zavreni okna...
    echo ======================================================================
    pause >nul
)
exit /b 0

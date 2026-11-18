@echo off
setlocal

:: ============================================================================
:: ULTARIX s.r.o. - Executive Monitoring Dashboard Launcher (PC-02 Ulyana)
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.0.0 (2026-11)
:: Target  : PC-02 (Director / Chief Accountant Workstation)
:: Server  : ULPS1 (192.168.33.128)
:: ============================================================================

title ULTARIX - Monitoring Dashboard [PC-02 Ulyana]

echo ================================================================================
echo       ULTARIX s.r.o. - Otevreni panelu kontroly pocitacu (PC-02)
echo ================================================================================
echo.

set "SERVER_DIR=\\ULPS1\ULTARIX\Monitoring"
set "LOCAL_DASH=%~dp0dashboard.html"

:: Check if server share is accessible and copy fresh dashboard if needed
if exist "%SERVER_DIR%" (
    if exist "%LOCAL_DASH%" (
        copy /y "%LOCAL_DASH%" "%SERVER_DIR%\dashboard.html" >nul 2>&1
    )
    echo [*] Server ULPS1 je dostupny. Oteviram sitovy panel...
    start "" "%SERVER_DIR%\dashboard.html"
) else (
    echo [*] Oteviram mistni panel sledovani...
    start "" "%LOCAL_DASH%"
)

echo.
echo [OK] Panel byl uspesne otevren v prohlizeci.
echo     Muzete si tuto stranku pridat do oblibenych (Zalozek) v prohlizeci!
echo.
timeout /t 3 >nul
exit /b 0

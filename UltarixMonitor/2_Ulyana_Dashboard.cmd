@echo off
setlocal

:: ============================================================================
:: ULTARIX s.r.o. - Executive Dashboard Launcher (PC-02 Ulyana)
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.1.0 (2026-11)
:: Target  : PC-02 (Ulyana / Director PC)
:: ============================================================================

title ULTARIX - Prehled aktivity pocitacu [Ulyana / PC-02]

echo ================================================================================
echo       ULTARIX s.r.o. - Otevreni panelu kontroly pro Ulyanou (PC-02)
echo ================================================================================
echo.

set "TARGET_HTML=%~dp0dashboard.html"

:: Check server share paths
if not exist "%TARGET_HTML%" (
    if exist "\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\dashboard.html"
    if exist "\\ULPS1\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=\\ULPS1\UTIL\UltarixMonitor\dashboard.html"
    if exist "D:\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=D:\UTIL\UltarixMonitor\dashboard.html"
    if exist "E:\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=E:\UTIL\UltarixMonitor\dashboard.html"
    if exist "S:\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=S:\UTIL\UltarixMonitor\dashboard.html"
)

echo [*] Oteviram dashboard: %TARGET_HTML%
start "" "%TARGET_HTML%"

echo.
echo ================================================================================
echo  DOPORUCENI PRO ULYANU:
echo  Stisknete klavesovou zkratku CTRL + D v prohlizeci a pridejte stranku
echo  do OBLIBENYCH (Zalozeck), abyste ji mela vzdy po ruce jednim kliknutim!
echo ================================================================================
echo.
timeout /t 5 >nul
exit /b 0

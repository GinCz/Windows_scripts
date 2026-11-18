@echo off
setlocal

:: ============================================================================
:: ULTARIX s.r.o. - Executive Dashboard Launcher (Server ULPS1 & PC-02 Ulyana)
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.2.0 (2026-11)
:: ============================================================================

title ULTARIX - Prehled aktivity pocitacu [Ulyana / PC-02 / ULPS1]

echo ================================================================================
echo       ULTARIX s.r.o. - Otevreni panelu kontroly pocitacu
echo ================================================================================
echo.

set "TARGET_HTML="
if exist "C:\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=C:\UTIL\UltarixMonitor\dashboard.html"
if not defined TARGET_HTML if exist "%~dp0dashboard.html" set "TARGET_HTML=%~dp0dashboard.html"
if not defined TARGET_HTML if exist "\\ulps1\UTIL\UltarixMonitor\dashboard.html" set "TARGET_HTML=\\ulps1\UTIL\UltarixMonitor\dashboard.html"
if not defined TARGET_HTML set "TARGET_HTML=\\ulps1\UTIL\UltarixMonitor\dashboard.html"

echo [*] Spoustim dashboard: %TARGET_HTML%
start "" "%TARGET_HTML%"

echo.
echo ================================================================================
echo  DOPORUCENI:
echo  Stisknete CTRL + D v prohlizeci a pridejte si tuto stranku do OBLIBENYCH
echo  (Zalozek) v prohlizeci. Budete ji mit vzdy po ruce na jeden klik!
echo ================================================================================
echo.
timeout /t 5 >nul
exit /b 0

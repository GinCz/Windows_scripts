@echo off
setlocal
title ULTARIX - Prohlizeni aktivity PC-09 [Ulyana / PC-02]

echo ================================================================================
echo       ULTARIX s.r.o. - Kontrola a prehled aktivity PC-09
echo ================================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get_Ultarix_Report.ps1" -TargetComputer "PC-09" -Days 60 -OpenReport

echo.
pause

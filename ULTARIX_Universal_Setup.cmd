@echo off
setlocal
title ULTARIX Setup Launcher

echo ================================================================================
echo       ULTARIX s.r.o. - Optimalizace a stabilizace pocitace
echo ================================================================================
echo.
echo [*] Pripravuji spousteni konfigurace...
echo.

set "SCRIPT_URL=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/ULTARIX_Setup.ps1"
set "FALLBACK_URL=http://152.53.182.222/ULTARIX_Setup.ps1"
set "LOCAL_PS=%TEMP%\ULTARIX_Setup.ps1"

:: Stazeni nejnovejsiho skriptu z GitHubu do docasne slozky TEMP
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; try { (New-Object Net.WebClient).DownloadFile('%SCRIPT_URL%', '%LOCAL_PS%') } catch { (New-Object Net.WebClient).DownloadFile('%FALLBACK_URL%', '%LOCAL_PS%') }"

if not exist "%LOCAL_PS%" (
    echo [CHYBA] Nepodarilo se stahnout konfiguracni skript.
    echo Zkontrolujte pripojeni k internetu a zkuste to znovu.
    echo.
    pause
    exit /b 1
)

echo [*] Spoustim PowerShell jako Administrator...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%LOCAL_PS%\"\"' -Verb RunAs"

exit

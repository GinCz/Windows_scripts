@echo off
setlocal

:: Auto-Elevation check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c pushd \"\"%~dp0\"\" && \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

title ULTARIX - Install Activity Monitor Agent [VladiMIR + Antigravity]
echo ================================================================================
echo       ULTARIX s.r.o. - Instalace ticheho agenta monitoringu pocitace
echo ================================================================================
echo Pocitac: %COMPUTERNAME% ^| Cil: Automaticky start pri prihlaseni
echo ================================================================================
echo.

set "TARGET_DIR=%ProgramData%\UltarixMonitor"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >nul 2>&1

:: Copy agent script
copy /y "%~dp0Ultarix_Agent.ps1" "%TARGET_DIR%\Ultarix_Agent.ps1" >nul 2>&1
if not exist "%TARGET_DIR%\Ultarix_Agent.ps1" (
    echo [!] CHYBA: Nelze zkopirovat Ultarix_Agent.ps1 do %TARGET_DIR%
    pause
    exit /b 1
)

echo [*] Soubory agenta uspesne zkopirovany do %TARGET_DIR%

:: Stop and remove old scheduled task if present
schtasks /delete /tn "UltarixMonitor" /f >nul 2>&1

:: Create scheduled task triggered at logon of any user, running hidden with highest privileges
schtasks /create /tn "UltarixMonitor" /tr "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TARGET_DIR%\Ultarix_Agent.ps1\"" /sc ONLOGON /rl HIGHEST /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [*] Uloha planovace "UltarixMonitor" uspesne zaregistrovana (ONLOGON, HIGHEST).
) else (
    echo [!] Varovani: Registrace ulohy planovace selhala.
)

:: Also add registry Run fallback for absolute guarantee
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "UltarixMonitor" /t REG_SZ /d "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TARGET_DIR%\Ultarix_Agent.ps1\"" /f >nul 2>&1

:: Start task now
schtasks /run /tn "UltarixMonitor" >nul 2>&1
echo [*] Agent monitoringu byl spusten na pozadi.
echo.
echo ================================================================================
echo       INSTALACE USPESNE DOKONCENA!
echo ================================================================================
echo.
timeout /t 5 >nul
exit /b 0

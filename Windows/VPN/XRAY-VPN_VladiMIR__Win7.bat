@echo off
chcp 65001 >nul
cls
echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7
echo        GitHub: https://github.com/GinCz/Windows_scripts
echo        Path:   Windows/VPN/
echo ====================================================================
echo.

:: Проверка прав администратора (метод net session, Win7-совместимый)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -Wait"
    exit /b
)
echo [+] Running with Administrator privileges!
echo.

:: Сброс прокси
netsh winhttp reset proxy >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo [+] Proxy cleared.

:: Скачиваем и запускаем основной установщик VPN
echo [*] Downloading and running VPN installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object Net.WebClient).DownloadString('http://prodvig-saita.ru/vpn/install.ps1'))"

:: Скачиваем tray_tooltip_helper.ps1 с GitHub
echo.
echo [*] Downloading tray tooltip helper from GitHub...
set "TRAY_DIR=C:\XRAY_VPN"
set "TRAY_PS1=%TRAY_DIR%\tray_tooltip_helper.ps1"
set "GITHUB_RAW=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/VPN/tray_tooltip_helper.ps1"

if not exist "%TRAY_DIR%" mkdir "%TRAY_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "(New-Object Net.WebClient).DownloadFile('%GITHUB_RAW%', '%TRAY_PS1%')"

if exist "%TRAY_PS1%" (
    echo [+] Tray helper ready: %TRAY_PS1%
) else (
    echo [!] WARNING: tray helper not downloaded. Check internet.
)

:: Ярлык автозапуска в Common Startup
echo [*] Creating autostart shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=New-Object -ComObject WScript.Shell; $lnk=$s.CreateShortcut([Environment]::GetFolderPath('CommonStartup')+'\XrayVPN_Tray.lnk'); $lnk.TargetPath='powershell.exe'; $lnk.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\XRAY_VPN\tray_tooltip_helper.ps1""'; $lnk.WorkingDirectory='C:\XRAY_VPN'; $lnk.Description='Xray VPN Tray'; $lnk.Save()"
echo [+] Autostart shortcut created.

:: Запускаем трей прямо сейчас
if exist "%TRAY_PS1%" (
    echo [*] Launching tray icon...
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TRAY_PS1%"
    echo [+] Tray icon running!
)

echo.
echo ====================================================================
echo  [OK] Installation complete! (Windows 7 edition)
echo.
echo  Hover over tray icon to see:  VPN IP / Original IP / Username
echo  GREEN=Connected  ORANGE=Connecting  GREY=Off  RED=Error
echo.
echo  Next: paste VLESS key into C:\XRAY_VPN\link.txt, then run Start_VPN
echo ====================================================================
pause
@echo off
chcp 65001 >nul
cls
echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7
echo        GitHub: https://github.com/GinCz/Windows_scripts
echo        Path:   Windows/VPN/
echo ====================================================================
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -Wait"
    exit /b
)
echo [+] Running with Administrator privileges!
echo.
netsh winhttp reset proxy >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo [+] Proxy cleared.
echo [*] Downloading and running VPN installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object Net.WebClient).DownloadString('http://prodvig-saita.ru/vpn/install.ps1'))"
echo.
echo [*] Updating tray with IP-tooltip version...
echo     Forcing TLS 1.2 - required for Windows 7 + GitHub HTTPS
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Enum]::ToObject([Net.SecurityProtocolType],3072); (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/VPN/tray_tooltip_helper.ps1','C:\XRAY_VPN\TrayVPN.ps1')"
if exist "C:\XRAY_VPN\TrayVPN.ps1" (
    echo [+] Tray helper updated OK
    echo [*] Restarting tray icon with IP tooltip...
    taskkill /f /fi "WINDOWTITLE eq Xray*" >nul 2>&1
    timeout /t 1 /nobreak >nul
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\XRAY_VPN\TrayVPN.ps1"
    echo [+] Tray restarted!
) else (
    echo [!] WARNING: GitHub download failed.
    echo [!] Fix: install .NET 4.5 or apply KB3140245 (TLS 1.2 for Win7)
)
echo [*] Creating autostart shortcut - AllUsersStartup (Win7-compatible)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$wsh=New-Object -ComObject WScript.Shell; $dir=$wsh.SpecialFolders('AllUsersStartup'); $lnk=$wsh.CreateShortcut($dir+'\XrayVPN_Tray.lnk'); $lnk.TargetPath='powershell.exe'; $lnk.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\XRAY_VPN\TrayVPN.ps1'; $lnk.WorkingDirectory='C:\XRAY_VPN'; $lnk.Description='Xray VPN Tray'; $lnk.Save()"
echo [+] Autostart shortcut created.
echo.
echo ====================================================================
echo  [OK] Installation complete! (Windows 7 edition)
echo.
echo  Hover over tray icon:   VPN IP / Original IP / Username
echo  Double-click tray icon: Balloon with full IP info
echo  GREEN=Connected  ORANGE=Connecting  GREY=Off  RED=Error
echo.
echo  Next: paste VLESS key into C:\XRAY_VPN\link.txt then run Start_VPN
echo  GitHub: https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN
echo ====================================================================
pause

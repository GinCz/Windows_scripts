@echo off
chcp 65001 >nul
cls

echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7 / 10 / 11
echo ====================================================================
echo.

:: 1. Self-elevation via Shell.Application (most reliable Win7+10+11 method)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    echo Set UAC = CreateObject("Shell.Application") > "%temp%\elevate_xray.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate_xray.vbs"
    cscript //nologo "%temp%\elevate_xray.vbs"
    del "%temp%\elevate_xray.vbs" >nul 2>&1
    exit /b
)

echo [+] Running with Administrator privileges!
echo [*] Resetting proxy and launching installer...

:: 2. Reset stuck proxy (safety measure)
netsh winhttp reset proxy >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Download and run installer from HTTP server (no TLS issues on Win7)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object Net.WebClient).DownloadString('http://prodvig-saita.ru/vpn/install.ps1'))"

echo.
echo ====================================================================
echo  [OK] Done! Paste your VLESS key into Notepad and Save.
echo  Then double-click Start_VPN in C:\XRAY_VPN folder.
echo ====================================================================
pause

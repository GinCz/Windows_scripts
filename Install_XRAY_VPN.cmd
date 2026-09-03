@echo off
chcp 65001 >nul
cls

echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7 (CMD)             
echo ====================================================================
echo.

:: 1. Self-elevation to Administrator via UAC
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo [+] Running with Administrator privileges!
echo [*] Installing XRAY_VPN into C:\XRAY_VPN...

:: 2. Setup directory
if not exist "C:\XRAY_VPN" mkdir "C:\XRAY_VPN"

:: 3. Migrate xray.exe and link.txt if available from C:\Xray or search disk
if exist "C:\Xray\xray.exe" copy /y "C:\Xray\xray.exe" "C:\XRAY_VPN\xray.exe" >nul
if exist "C:\Xray\link.txt" copy /y "C:\Xray\link.txt" "C:\XRAY_VPN\link.txt" >nul
if not exist "C:\XRAY_VPN\xray.exe" (
    echo [*] Searching for xray.exe on computer...
    for /r "%USERPROFILE%" %%i in (xray.exe) do @if exist "%%i" copy /y "%%i" "C:\XRAY_VPN\xray.exe" >nul
)
if not exist "C:\XRAY_VPN\link.txt" type nul > "C:\XRAY_VPN\link.txt"

:: 4. Deploy all scripts, VBS wrappers, and shortcuts via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d='C:/XRAY_VPN'; [System.IO.File]::WriteAllBytes('$d/Start_VPN.vbs',[Convert]::FromBase64String('U2V0IFdzaFNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXU2NyaXB0LlNoZWxsIikKV3NoU2hlbGwuUnVuICJwb3dlcnNoZWxsIC1XaW5kb3dTdHlsZSBIaWRkZW4gLU5vUHJvZmlsZSAtRXhlY3V0aW9uUG9saWN5IEJ5cGFzcyAtRmlsZSAiIkM6XFhSQVlfVlBOXFN0YXJ0X1ZQTi5wczEiIiIsIDAsIEZhbHNlCg==')); [System.IO.File]::WriteAllBytes('$d/Stop_VPN.vbs',[Convert]::FromBase64String('U2V0IFdzaFNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXU2NyaXB0LlNoZWxsIikKV3NoU2hlbGwuUnVuICJwb3dlcnNoZWxsIC1XaW5kb3dTdHlsZSBIaWRkZW4gLU5vUHJvZmlsZSAtRXhlY3V0aW9uUG9saWN5IEJ5cGFzcyAtRmlsZSAiIkM6XFhSQVlfVlBOXFN0b3BfVlBOLnBzMSIiIiwgMCwgRmFsc2UK')); if(Test-Path 'C:/Xray/Start_VPN.ps1'){(Get-Content 'C:/Xray/Start_VPN.ps1') -replace 'C:\\Xray','C:\XRAY_VPN'|Set-Content '$d/Start_VPN.ps1'}; if(Test-Path 'C:/Xray/Stop_VPN.ps1'){(Get-Content 'C:/Xray/Stop_VPN.ps1') -replace 'C:\\Xray','C:\XRAY_VPN'|Set-Content '$d/Stop_VPN.ps1'}; if(Test-Path 'C:/Xray/TrayVPN.ps1'){(Get-Content 'C:/Xray/TrayVPN.ps1') -replace 'C:\\Xray','C:\XRAY_VPN'|Set-Content '$d/TrayVPN.ps1'}; $w=New-Object -ComObject WScript.Shell; $s1=$w.CreateShortcut('$d/Start_VPN.lnk'); $s1.TargetPath='wscript.exe'; $s1.Arguments='\"C:\XRAY_VPN\Start_VPN.vbs\"'; $s1.WorkingDirectory='C:\XRAY_VPN'; $s1.IconLocation='shell32.dll,137'; $s1.Save(); $s2=$w.CreateShortcut('$d/Stop_VPN.lnk'); $s2.TargetPath='wscript.exe'; $s2.Arguments='\"C:\XRAY_VPN\Stop_VPN.vbs\"'; $s2.WorkingDirectory='C:\XRAY_VPN'; $s2.IconLocation='shell32.dll,27'; $s2.Save(); Start-Process 'explorer.exe' -ArgumentList 'C:\XRAY_VPN'; Start-Process 'notepad.exe' -ArgumentList 'C:\XRAY_VPN\link.txt'"

echo.
echo ====================================================================
echo  [OK] INSTALLATION COMPLETED! Folder: C:\XRAY_VPN
echo  1. Paste your VLESS key into the opened Notepad and save (Ctrl+S).
echo  2. Double-click Start_VPN in C:\XRAY_VPN folder.
echo.
echo  The window will automatically close in 10 seconds...
echo ====================================================================
timeout /t 10
exit
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
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c ""%~f0""' -Verb RunAs"
    exit /b
)

echo [+] Running with Administrator privileges!
echo [*] Deploying XRAY_VPN components into C:\XRAY_VPN...

:: 2. Execute PowerShell setup
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=[System.IO.File]::ReadAllText('%~f0'); $i=$c.IndexOf('###PS_PAYLOAD###'); if($i -ge 0){ Invoke-Expression $c.Substring($i+16) }"

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

###PS_PAYLOAD###
# Setup script for XRAY_VPN
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dir = 'C:\XRAY_VPN'
if (-not (Test-Path $dir)) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }

# 1. Base64 VBS wrappers
$b1 = 'U2V0IFdzaFNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXU2NyaXB0LlNoZWxsIikKV3NoU2hlbGwuUnVuICJwb3dlcnNoZWxsIC1XaW5kb3dTdHlsZSBIaWRkZW4gLU5vUHJvZmlsZSAtRXhlY3V0aW9uUG9saWN5IEJ5cGFzcyAtRmlsZSAiIkM6XFhSQVlfVlBOXFN0YXJ0X1ZQTi5wczEiIiIsIDAsIEZhbHNlCg=='
$b2 = 'U2V0IFdzaFNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXU2NyaXB0LlNoZWxsIikKV3NoU2hlbGwuUnVuICJwb3dlcnNoZWxsIC1XaW5kb3dTdHlsZSBIaWRkZW4gLU5vUHJvZmlsZSAtRXhlY3V0aW9uUG9saWN5IEJ5cGFzcyAtRmlsZSAiIkM6XFhSQVlfVlBOXFN0b3BfVlBOLnBzMSIiIiwgMCwgRmFsc2UK'
[System.IO.File]::WriteAllBytes("$dir\Start_VPN.vbs", [Convert]::FromBase64String($b1))
[System.IO.File]::WriteAllBytes("$dir\Stop_VPN.vbs", [Convert]::FromBase64String($b2))

# 2. Migrate or Deploy core files
if (Test-Path 'C:\Xray\Start_VPN.ps1') { (Get-Content 'C:\Xray\Start_VPN.ps1') -replace 'C:\\Xray', 'C:\XRAY_VPN' | Set-Content "$dir\Start_VPN.ps1" }
if (Test-Path 'C:\Xray\Stop_VPN.ps1') { (Get-Content 'C:\Xray\Stop_VPN.ps1') -replace 'C:\\Xray', 'C:\XRAY_VPN' | Set-Content "$dir\Stop_VPN.ps1" }
if (Test-Path 'C:\Xray\TrayVPN.ps1') { (Get-Content 'C:\Xray\TrayVPN.ps1') -replace 'C:\\Xray', 'C:\XRAY_VPN' | Set-Content "$dir\TrayVPN.ps1" }
if (Test-Path 'C:\Xray\xray.exe') { Copy-Item 'C:\Xray\xray.exe' $dir -Force }
if (Test-Path 'C:\Xray\link.txt') { Copy-Item 'C:\Xray\link.txt' $dir -Force }
if (-not (Test-Path "$dir\link.txt")) { [System.IO.File]::WriteAllText("$dir\link.txt", '', [System.Text.Encoding]::UTF8) }

# Search for xray.exe if still missing
if (-not (Test-Path "$dir\xray.exe")) {
    $f = Get-ChildItem -Path $env:USERPROFILE -Filter 'xray.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($f) { Copy-Item $f.FullName "$dir\xray.exe" -Force }
}

# 3. Create Shortcuts
$w = New-Object -ComObject WScript.Shell
$s1 = $w.CreateShortcut("$dir\Start_VPN.lnk")
$s1.TargetPath = 'wscript.exe'
$s1.Arguments = '"C:\XRAY_VPN\Start_VPN.vbs"'
$s1.WorkingDirectory = $dir
$s1.IconLocation = 'shell32.dll,137'
$s1.Save()

$s2 = $w.CreateShortcut("$dir\Stop_VPN.lnk")
$s2.TargetPath = 'wscript.exe'
$s2.Arguments = '"C:\XRAY_VPN\Stop_VPN.vbs"'
$s2.WorkingDirectory = $dir
$s2.IconLocation = 'shell32.dll,27'
$s2.Save()

Start-Process 'explorer.exe' -ArgumentList $dir
Start-Process 'notepad.exe' -ArgumentList "$dir\link.txt"
Write-Host "[OK] Installation completed successfully!" -ForegroundColor Green

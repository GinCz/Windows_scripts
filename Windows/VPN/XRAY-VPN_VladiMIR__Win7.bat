@echo off
chcp 65001 >nul
cls
echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7
echo        GitHub: https://github.com/GinCz/Windows_scripts
echo ====================================================================
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"'+'%~f0'+'\"\"' -Verb RunAs -Wait"
    exit /b
)
echo [+] Running with Administrator privileges!
netsh winhttp reset proxy >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo [+] Proxy cleared.
echo [*] Installing VPN...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object Net.WebClient).DownloadString('http://prodvig-saita.ru/vpn/install.ps1'))"
echo.
echo [*] Patching tray tooltip (adding IP addresses + username)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0',[System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PATCH'))"
echo.
echo [OK] Done! Paste your VLESS key into C:\XRAY_VPN\link.txt and run Start_VPN.
pause
exit /b

##PATCH
$tray = "C:\XRAY_VPN\TrayVPN.ps1"
if (-not (Test-Path $tray)) { Write-Host "[!] TrayVPN.ps1 not found - skipping patch"; exit }
$content = Get-Content $tray -Raw
# ?? ?????? ??????
if ($content -match "_ipt") { Write-Host "[i] Already patched."; $alreadyPatched = $true } else { $alreadyPatched = $false }
if (-not $alreadyPatched) {
    # ???????? ???????????? IP (HTTP - ??? TLS, ???????? ?? Win7)
    $oip = try { (New-Object Net.WebClient).DownloadString("http://api.ipify.org").Trim() } catch { "Unknown" }
    $usr = $env:USERNAME
    # ?????????? ??? ?????????? NotifyIcon ? ???????????? TrayVPN.ps1
    $niVar = if ($content -match "(\`$\w+)\s*=\s*New-Object System\.Windows\.Forms\.NotifyIcon") { $matches[1] } else { "`$notifyIcon" }
    $runLine = "[System.Windows.Forms.Application]::Run()"
    if ($content.Contains($runLine)) {
        $patch = "`r`n# === IP Tooltip Patch ===`r`n`$_oip='$oip'; `$_usr='$usr'`r`n`$_ipt=New-Object System.Windows.Forms.Timer; `$_ipt.Interval=5000`r`n`$_ipt.add_Tick({`r`n  `$on=`$null -ne (Get-Process -Name xray,v2ray,wintun -EA SilentlyContinue)`r`n  if(`$on){`$ip=try{(New-Object Net.WebClient).DownloadString('http://api.ipify.org').Trim()}catch{'?'};`$t=`"Xray VPN: Connected | VPN: `$ip | Orig: `$_oip | `$_usr`"}`r`n  else{`$t=`"Xray VPN: Off | Orig: `$_oip | `$_usr`"}`r`n  if(`$t.Length -gt 63){`$t=`$t.Substring(0,60)+'...'}; $niVar.Text=`$t`r`n})`r`n`$_ipt.Start()`r`n# === End Patch ===`r`n"
        Set-Content $tray ($content.Replace($runLine, $patch + $runLine)) -Encoding UTF8 -Force
        Write-Host "[+] TrayVPN.ps1 patched: IP tooltip added!" -ForegroundColor Green
    } else { Write-Host "[!] Application::Run not found in TrayVPN.ps1" }
}
# ????????????? ???? ? ????????? ???????
Get-Process powershell -EA SilentlyContinue | ForEach-Object {
    try { $c=(Get-WmiObject Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine; if($c -match "TrayVPN"){Stop-Process -Id $_.Id -Force -EA SilentlyContinue} } catch {} }
Start-Sleep 1
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tray`"" -WindowStyle Hidden
Write-Host "[+] Tray restarted with IP tooltip!" -ForegroundColor Green
# ????? ??????????? ????? ProgramData (??? SpecialFolders - ???????? Win7+10+11)
$sd = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
if(-not(Test-Path $sd)){New-Item -Path $sd -ItemType Directory -Force|Out-Null}
$wsh=$wsh=New-Object -ComObject WScript.Shell; $lnk=$wsh.CreateShortcut("$sd\XrayVPN_Tray.lnk"); $lnk.TargetPath="powershell.exe"; $lnk.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tray`""; $lnk.WorkingDirectory="C:\XRAY_VPN"; $lnk.Save()
Write-Host "[+] Autostart shortcut: $sd\XrayVPN_Tray.lnk" -ForegroundColor Green

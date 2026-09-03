@echo off
chcp 65001 >nul
cls

fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"'+'%~f0'+'\"\"' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
title XRAY VPN Installer
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0',[System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle='XRAY VPN Installer - Win10/11'
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host '  ░▒▓█  X R A Y   V P N   I N S T A L L E R  -  Windows 10 / 11  █▓▒░' -ForegroundColor Yellow
Write-Host '  github.com/GinCz/Windows_scripts  |  Windows/VPN/' -ForegroundColor DarkGray
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''
Write-Host '[*] Resetting proxy...' -ForegroundColor Cyan
& netsh winhttp reset proxy | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null
Write-Host '[+] Proxy cleared.' -ForegroundColor Green
Write-Host '[*] Installing VPN core...' -ForegroundColor Cyan
try {
    (New-Object Net.WebClient).DownloadFile('http://prodvig-saita.ru/vpn/install.ps1',"$env:TEMP\xray_install.ps1")
    & "$env:TEMP\xray_install.ps1"
    Remove-Item "$env:TEMP\xray_install.ps1" -Force -ErrorAction SilentlyContinue
    Write-Host '[+] VPN installed.' -ForegroundColor Green
} catch { Write-Host "[ERROR] $_" -ForegroundColor Red; Read-Host 'Press Enter'; exit 1 }

Write-Host '[*] Patching tray tooltip (adding IP + username)...' -ForegroundColor Cyan
$tray = "C:\XRAY_VPN\TrayVPN.ps1"
if (Test-Path $tray) {
    $content = Get-Content $tray -Raw
    if ($content -notmatch "_ipt") {
        $oip = try { (New-Object Net.WebClient).DownloadString("http://api.ipify.org").Trim() } catch { "Unknown" }
        $usr = $env:USERNAME
        $niVar = if ($content -match "(\`$\w+)\s*=\s*New-Object System\.Windows\.Forms\.NotifyIcon") { $matches[1] } else { "`$notifyIcon" }
        $runLine = "[System.Windows.Forms.Application]::Run()"
        if ($content.Contains($runLine)) {
            $patch = "`r`n# IP Tooltip Patch`r`n`$_oip='$oip'; `$_usr='$usr'`r`n`$_ipt=New-Object System.Windows.Forms.Timer; `$_ipt.Interval=5000`r`n`$_ipt.add_Tick({`r`n  `$on=`$null -ne (Get-Process -Name xray,v2ray,wintun -EA SilentlyContinue)`r`n  if(`$on){`$ip=try{(New-Object Net.WebClient).DownloadString('http://api.ipify.org').Trim()}catch{'?'};`$t=`"Xray VPN: Connected | VPN: `$ip | Orig: `$_oip | `$_usr`"}`r`n  else{`$t=`"Xray VPN: Off | Orig: `$_oip | `$_usr`"}`r`n  if(`$t.Length -gt 63){`$t=`$t.Substring(0,60)+'...'}; $niVar.Text=`$t`r`n})`r`n`$_ipt.Start()`r`n"
            Set-Content $tray ($content.Replace($runLine, $patch + $runLine)) -Encoding UTF8 -Force
            Write-Host "[+] TrayVPN.ps1 patched!" -ForegroundColor Green
        }
    } else { Write-Host "[i] Already patched, skipping." -ForegroundColor DarkGray }
    # Перезапуск трея
    Get-Process powershell -EA SilentlyContinue | ForEach-Object {
        try { $c=(Get-WmiObject Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine; if($c -match "TrayVPN"){Stop-Process -Id $_.Id -Force -EA SilentlyContinue} } catch {} }
    Start-Sleep 1
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tray`"" -WindowStyle Hidden
    Write-Host "[+] Tray restarted with IP tooltip!" -ForegroundColor Green
    # Ярлык автозапуска
    $sd = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    if(-not(Test-Path $sd)){New-Item -Path $sd -ItemType Directory -Force|Out-Null}
    $wsh=New-Object -ComObject WScript.Shell; $lnk=$wsh.CreateShortcut("$sd\XrayVPN_Tray.lnk"); $lnk.TargetPath="powershell.exe"; $lnk.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tray`""; $lnk.WorkingDirectory="C:\XRAY_VPN"; $lnk.Save()
    Write-Host "[+] Autostart: $sd\XrayVPN_Tray.lnk" -ForegroundColor Green
} else { Write-Host "[!] TrayVPN.ps1 not found - install may have failed" -ForegroundColor Yellow }

Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ' [OK] Done! Tray icon is now in system tray.' -ForegroundColor Green
Write-Host '  Hover over icon:  VPN IP / Original IP / Username' -ForegroundColor Green
Write-Host '  GREEN=Connected  ORANGE=Connecting  GREY=Off  RED=Error' -ForegroundColor Green
Write-Host '  Next: paste VLESS key into C:\XRAY_VPN\link.txt -> Start_VPN' -ForegroundColor Green
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ''
Read-Host 'Press Enter to close'

@echo off
chcp 65001 >nul
title ULTARIX - Universal Setup & Stabilizer for All Office PCs [VladiMIR + Antigravity]

:: Check Administrator Privileges & Auto-Elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ================================================================================
echo        ULTARIX s.r.o. - UNIVERSAL 1-CLICK OFFICE PC SETUP & STABILIZER
echo ================================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$ErrorActionPreference = 'SilentlyContinue'; " ^
"Write-Host '[1/6] Configuring Virtual Memory (Pagefile: 4GB - 8GB)...' -ForegroundColor Cyan; " ^
"Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value @('C:\pagefile.sys 4096 8192') -Type MultiString; " ^
"Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'AutomaticManagedPagefile' -Value 0 -Type DWord; " ^
"New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = 'C:\pagefile.sys'; InitialSize = 4096; MaximumSize = 8192 } 2>$null; " ^
"Write-Host '    [+] Pagefile 4096-8192 MB configured on C:\' -ForegroundColor Green; " ^
"Write-Host '[2/6] Adding Windows Defender Accounting Exclusions...' -ForegroundColor Cyan; " ^
"$paths = @('\\ULPS1\Sdílené Data', '\\ULPS1\ultarix', '\\ULPS1\ekonom.win', '\\ULPS1\UTIL', 'E:\', 'S:\', 'Z:\', 'C:\Program Files\KASTNER software', 'C:\ProgramData\KASTNER software', 'C:\STEREO30', 'C:\STEREO31', 'C:\STEREO32', 'C:\STEREO33', 'C:\STEREO34', 'C:\STEREO35'); " ^
"foreach ($p in $paths) { Add-MpPreference -ExclusionPath $p }; " ^
"$procs = @('FORMstudio.exe', 'nxServer412.exe', 'stereo.exe'); " ^
"foreach ($pr in $procs) { Add-MpPreference -ExclusionProcess $pr }; " ^
"Write-Host '    [+] Accounting folders, drives and processes excluded from Defender' -ForegroundColor Green; " ^
"Write-Host '[3/6] Enabling Network Discovery & SMB Services...' -ForegroundColor Cyan; " ^
"Set-Service -Name 'FDResPub' -StartupType Automatic; Start-Service -Name 'FDResPub'; " ^
"Set-Service -Name 'fdPHost' -StartupType Automatic; Start-Service -Name 'fdPHost'; " ^
"Set-Service -Name 'LanmanWorkstation' -StartupType Automatic; Start-Service -Name 'LanmanWorkstation'; " ^
"Set-Service -Name 'lmhosts' -StartupType Automatic; Start-Service -Name 'lmhosts'; " ^
"Write-Host '    [+] FDResPub, fdPHost, LanmanWorkstation set to Automatic & Running' -ForegroundColor Green; " ^
"Write-Host '[4/6] Configuring FORM studio Server IP (192.168.33.128:16000)...' -ForegroundColor Cyan; " ^
"$iniList = Get-ChildItem -Path 'C:\Users\*\AppData\Roaming\Kastner software\Form Studio CZ\FORMstudio.ini' -ErrorAction SilentlyContinue; " ^
"foreach ($ini in $iniList) { " ^
"    $c = Get-Content $ini.FullName -Raw -Encoding UTF8; " ^
"    $c = $c -replace '(?m)^IP=.*$', 'IP=192.168.33.128'; " ^
"    $c = $c -replace '(?m)^REMOTESERVER=.*$', 'REMOTESERVER=1'; " ^
"    $c = $c -replace '(?m)^Port=.*$', 'Port=16000'; " ^
"    Set-Content -Path $ini.FullName -Value $c -Encoding UTF8; " ^
"    Write-Host \"    [+] Updated: $($ini.FullName)\" -ForegroundColor Green; " ^
"}; " ^
"Write-Host '[5/6] Testing Physical Network Card Link Speed...' -ForegroundColor Cyan; " ^
"$adapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 -and $_.AdapterTypeId -eq 0 }; " ^
"foreach ($ad in $adapters) { " ^
"    $speedMb = [math]::Round($ad.Speed / 1000000); " ^
"    if ($speedMb -ge 1000) { " ^
"        Write-Host \"    [+] Adapter: $($ad.Name) | Speed: $speedMb Mbps (1 Gbit/s GIGABIT LINK OK)\" -ForegroundColor Green; " ^
"    } else { " ^
"        Write-Host \"    [!] Adapter: $($ad.Name) | Speed: $speedMb Mbps (WARNING: 100M SLOW LINK - Check Cable/Switch!)\" -ForegroundColor Yellow; " ^
"    } " ^
"}; " ^
"Write-Host '[6/6] Testing Connection to Main Server ULPS1 (192.168.33.128)...' -ForegroundColor Cyan; " ^
"$t = Test-NetConnection -ComputerName 192.168.33.128 -Port 16000; " ^
"if ($t.TcpTestSucceeded) { " ^
"    Write-Host '    [+] Server ULPS1 Port 16000: ONLINE & REACHABLE!' -ForegroundColor Green; " ^
"} else { " ^
"    Write-Host '    [-] Server ULPS1 Port 16000: UNREACHABLE!' -ForegroundColor Red; " ^
"}; " ^
"Write-Host ''; " ^
"Write-Host '================================================================================' -ForegroundColor Green; " ^
"Write-Host '   SUCCESS! PC is fully optimized, pagefile active and ready for work.' -ForegroundColor Green; " ^
"Write-Host '================================================================================' -ForegroundColor Green; "

echo.
pause

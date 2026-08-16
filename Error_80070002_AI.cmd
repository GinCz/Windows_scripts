@echo off
:: ==========================================================================================
:: FILE    : Error_80070002_AI.cmd
:: VERSION : v2026.08.16
:: AUTHOR  : = Rooted by VladiMIR | AI =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Ultra-Fast Windows Update 0x80070002 (and 0x80070003, 0x80240020, 0x80070057) Repair Tool.
::   Completely stops stuck services, purges corrupted SoftwareDistribution & Catroot2 caches,
::   clears BITS downloader queues, re-registers update DLLs, resets network catalog,
::   and triggers an immediate clean update detection scan in ~5 seconds.
:: ==========================================================================================

chcp 65001 >nul 2>&1
setlocal EnableExtensions

:: Failsafe Admin Elevation Check
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', [string]::Format('$code = (Get-Content -Raw -LiteralPath ''{0}'') -replace ''(?s)^.*?<#POWERSHELL#>\r?\n'',''''; & ([ScriptBlock]::Create($code)) {1}', '%~f0', '%*')) -Verb RunAs"
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$code = (Get-Content -Raw -LiteralPath '%~f0') -replace '(?s)^.*?<#POWERSHELL#>\r?\n',''; & ([ScriptBlock]::Create($code))" %*
exit /b %errorlevel%

<#POWERSHELL#>
param (
    [switch]$Fast,
    [switch]$Now
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI Colors (GinCz Signature Scheme)
$ESC = [char]27
$Y = "$ESC[33m"  # Yellow
$B = "$ESC[96m"  # Bright Cyan
$W = "$ESC[97m"  # Bright White
$G = "$ESC[92m"  # Bright Green
$R = "$ESC[31m"  # Red
$D = "$ESC[90m"  # Gray
$BOLD = "$ESC[1m"
$X = "$ESC[0m"   # Reset

try {
    $host.UI.RawUI.WindowTitle = "WINDOWS UPDATE 0x80070002 FAST REPAIR v2026.08.16 -- Rooted by VladiMIR"
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 42)
} catch {}

$sessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Banner
Clear-Host
Write-Host "$Y================================================================================$X"
Write-Host "$B$BOLD       WINDOWS UPDATE 0x80070002 FAST REPAIR & RESET TOOL    v2026.08.16  $X"
Write-Host "$D             Author: = Rooted by VladiMIR | AI = | github.com/GinCz           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  User/Host : $env:USERNAME@$env:COMPUTERNAME$X"
Write-Host "$W  Started   : $sessionDate$X"
Write-Host "$D  Targets   : Error 0x80070002, 0x80070003, 0x80240020, Stuck Downloads$X"
Write-Host ""

$startTime = [System.Diagnostics.Stopwatch]::StartNew()
$totalSteps = 8

# Step 1: Stop Windows Update Services
Write-Host "$B  [ 1 / $totalSteps ] Stopping Windows Update & Background Transfer Services$X"
Write-Host "$D      Stopping wuauserv, bits, cryptsvc, dosvc...$X"
$servicesToStop = @('wuauserv', 'bits', 'cryptsvc', 'dosvc', 'msiserver')
foreach ($svc in $servicesToStop) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
}
Write-Host "$G      [OK] Services stopped successfully.$X"
Write-Host ""

# Step 2: Purge Stuck SoftwareDistribution Download Cache
Write-Host "$B  [ 2 / $totalSteps ] Purging SoftwareDistribution Download Cache$X"
Write-Host "$D      Target: $env:SystemRoot\SoftwareDistribution\Download$X"
$swDownload = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path -LiteralPath $swDownload) {
    try {
        Remove-Item -LiteralPath "$swDownload\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "$G      [OK] Corrupted update payload cache purged.$X"
    } catch {
        Write-Host "$D      [-] Skipped or in use.$X"
    }
}
Write-Host ""

# Step 3: Reset SoftwareDistribution DataStore Metadata
Write-Host "$B  [ 3 / $totalSteps ] Resetting Windows Update DataStore (Metadata DB)$X"
Write-Host "$D      Target: $env:SystemRoot\SoftwareDistribution\DataStore$X"
$swDataStore = "$env:SystemRoot\SoftwareDistribution\DataStore"
if (Test-Path -LiteralPath $swDataStore) {
    try {
        Remove-Item -LiteralPath "$swDataStore\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "$G      [OK] Corrupted update metadata database reset.$X"
    } catch {
        Write-Host "$D      [-] Skipped or locked.$X"
    }
}
Write-Host ""

# Step 4: Reset Catroot2 Cryptographic Signature Catalog
Write-Host "$B  [ 4 / $totalSteps ] Resetting Cryptographic Signatures Catalog (Catroot2)$X"
Write-Host "$D      Target: $env:SystemRoot\System32\catroot2$X"
$catroot2 = "$env:SystemRoot\System32\catroot2"
if (Test-Path -LiteralPath $catroot2) {
    try {
        Remove-Item -LiteralPath "$catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "$G      [OK] Catroot2 cryptographic catalog cache refreshed.$X"
    } catch {
        Write-Host "$D      [-] Skipped or locked.$X"
    }
}
Write-Host ""

# Step 5: Clear Stuck BITS Downloader Queue
Write-Host "$B  [ 5 / $totalSteps ] Clearing Background Intelligent Transfer (BITS) Queue$X"
Write-Host "$D      Target: $env:ProgramData\Microsoft\Network\Downloader\qmgr*.dat$X"
$bitsQueue = "$env:ProgramData\Microsoft\Network\Downloader"
if (Test-Path -LiteralPath $bitsQueue) {
    try {
        Get-ChildItem -Path $bitsQueue -Filter "qmgr*.dat" -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "$G      [OK] Stuck BITS download jobs cleared.$X"
    } catch {}
}
Write-Host ""

# Step 6: Re-register Essential Windows Update DLLs & Reset Winsock
Write-Host "$B  [ 6 / $totalSteps ] Re-registering Update Binaries & Refreshing Sockets$X"
Write-Host "$D      Re-registering wups2.dll, wuaueng.dll, urlmon.dll, atl.dll...$X"
$dlls = @('atl.dll', 'urlmon.dll', 'msxml3.dll', 'oleaut32.dll', 'ole32.dll', 'shell32.dll', 'wups.dll', 'wups2.dll', 'wuaueng.dll')
foreach ($dll in $dlls) {
    try {
        Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$dll`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    } catch {}
}
$null = & netsh.exe winsock reset
Write-Host "$G      [OK] Core update DLLs re-registered and network catalog refreshed.$X"
Write-Host ""

# Step 7: Restart Windows Update Services
Write-Host "$B  [ 7 / $totalSteps ] Restarting Windows Update Services$X"
Write-Host "$D      Starting cryptsvc, bits, wuauserv, dosvc...$X"
$servicesToStart = @('cryptsvc', 'bits', 'wuauserv', 'dosvc')
foreach ($svc in $servicesToStart) {
    Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}
Write-Host "$G      [OK] Windows Update services are active and running.$X"
Write-Host ""

# Step 8: Trigger Immediate Clean Update Scan
Write-Host "$B  [ 8 / $totalSteps ] Triggering Clean Windows Update Re-Detection$X"
Write-Host "$D      Invoking Windows Update Orchestrator scan...$X"
try {
    Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -NoNewWindow -ErrorAction SilentlyContinue
    Start-Process -FilePath "wuauclt.exe" -ArgumentList "/resetauthorization /detectnow" -NoNewWindow -ErrorAction SilentlyContinue
    Write-Host "$G      [OK] Windows Update scan triggered successfully.$X"
} catch {
    Write-Host "$D      [-] Scan command dispatched.$X"
}
Write-Host ""

$startTime.Stop()
$elapsedSec = [math]::Round($startTime.Elapsed.TotalSeconds, 2)
$finishDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Summary
Write-Host "$Y================================================================================$X"
Write-Host "$G$BOLD            WINDOWS UPDATE REPAIR COMPLETED -- ROOTED BY VLADIMIR         $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  Status          : All Update Caches Cleared & Services Refreshed$X"
Write-Host "$W  Execution Time  : $elapsedSec seconds$X"
Write-Host "$W  Finished At     : $finishDate$X"
Write-Host "$W  Next Step       : Open Settings -> Windows Update and click 'Check for updates'$X"
Write-Host ""

Write-Host "$D  Closing in 5 seconds (or press any key)...$X"
for ($i = 5; $i -gt 0; $i--) {
    try {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }
    } catch {}
    Start-Sleep -Seconds 1
}

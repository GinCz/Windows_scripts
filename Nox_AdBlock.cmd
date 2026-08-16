@echo off
:: ==========================================================================================
:: FILE    : Nox_AdBlock.cmd
:: VERSION : v2026.08.16
:: AUTHOR  : = Rooted by VladiMIR | AI =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   NoxPlayer AdBlock & Telemetry Purge Tool.
::   Blocks advertising, sponsored game distribution, promotional banners, and tracking servers
::   in Windows HOSTS without breaking Google Play Services, internet access, or app installs.
::   Patches Nox configuration (conf.ini) and purges all cached promo images and notices.
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
    $host.UI.RawUI.WindowTitle = "NOXPLAYER ADBLOCK & PRIVACY TOOL v2026.08.16 -- Rooted by VladiMIR"
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 42)
} catch {}

$sessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Banner
Clear-Host
Write-Host "$Y================================================================================$X"
Write-Host "$B$BOLD         NOXPLAYER ADBLOCK & TELEMETRY PURGE TOOL             v2026.08.16  $X"
Write-Host "$D             Author: = Rooted by VladiMIR | AI = | github.com/GinCz           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  User/Host : $env:USERNAME@$env:COMPUTERNAME$X"
Write-Host "$W  Started   : $sessionDate$X"
Write-Host "$D  Scope     : Blocks Nox ads, popups, and telemetry; Google Play remains 100% OK$X"
Write-Host ""

$startTime = [System.Diagnostics.Stopwatch]::StartNew()

# Step 1: Add BigNox ad server blocklist to HOSTS
Write-Host "$B  [ 1 / 3 ] Updating Windows HOSTS DNS Sinkhole$X"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content -LiteralPath $hostsPath -Raw

$adBlockComment = "# [GinCz] Block Nox Player Ads & Telemetry"
$domains = @(
    "api.bignox.com",
    "res06.bignox.com",
    "advert.bignox.com",
    "hotgames.bignox.com",
    "huodong.bignox.com",
    "gamestore.bignox.com",
    "stat.bignox.com",
    "nlog.bignox.com",
    "log.bignox.com",
    "feedback.bignox.com",
    "service.bignox.com",
    "ad.duapps.com",
    "track.adform.net"
)

if ($hostsContent -notmatch "\[GinCz\] Block Nox Player Ads") {
    $blockEntries = "`r`n$adBlockComment`r`n" + (($domains | ForEach-Object { "0.0.0.0 $_" }) -join "`r`n")
    Add-Content -LiteralPath $hostsPath -Value $blockEntries -Encoding ASCII
    Write-Host "$G      [OK] Added 13 BigNox ad & telemetry domains to HOSTS.$X"
} else {
    Write-Host "$G      [OK] HOSTS ad blocklist already active.$X"
}

$null = & ipconfig.exe /flushdns
Write-Host "$D      DNS Resolver Cache flushed.$X"
Write-Host ""

# Step 2: Patch Nox conf.ini
Write-Host "$B  [ 2 / 3 ] Disabling Ad Prompts & Telemetry in Nox Configuration$X"
$confPath = "$env:LOCALAPPDATA\Nox\conf.ini"
if (Test-Path -LiteralPath $confPath) {
    $conf = Get-Content -LiteralPath $confPath -Raw
    $conf = $conf -replace 'app_notice_enable=true', 'app_notice_enable=false'
    $conf = $conf -replace 'collect_behavior_enable=true', 'collect_behavior_enable=false'
    $conf = $conf -replace 'loadingpage_show=true', 'loadingpage_show=false'
    $conf | Set-Content -LiteralPath $confPath -Encoding UTF8 -Force
    Write-Host "$G      [OK] conf.ini patched (notices, telemetry, loading ads disabled).$X"
} else {
    Write-Host "$D      [-] conf.ini not found in %LOCALAPPDATA%\Nox (skipped).$X"
}
Write-Host ""

# Step 3: Purge cached promo files and images
Write-Host "$B  [ 3 / 3 ] Purging Cached Promo Images & Notice Databases$X"
$adFolders = @(
    "$env:LOCALAPPDATA\Nox\app_notice_list",
    "$env:LOCALAPPDATA\Nox\app_images",
    "$env:LOCALAPPDATA\Nox\loading",
    "$env:LOCALAPPDATA\Nox\preview",
    "$env:LOCALAPPDATA\Nox\app_conf_list",
    "$env:LOCALAPPDATA\Nox\app_limit_list",
    "$env:LOCALAPPDATA\Nox\app_pass_list"
)

$deletedCount = 0
foreach ($folder in $adFolders) {
    if (Test-Path -LiteralPath $folder) {
        $files = Get-ChildItem -LiteralPath $folder -Recurse -File -Force -ErrorAction SilentlyContinue
        if ($files) {
            $deletedCount += $files.Count
            Remove-Item -LiteralPath "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "$G      [OK] Purged $deletedCount cached promotional files.$X"
Write-Host ""

$startTime.Stop()
$elapsedSec = [math]::Round($startTime.Elapsed.TotalSeconds, 2)
$finishDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Summary
Write-Host "$Y================================================================================$X"
Write-Host "$G$BOLD              NOXPLAYER ADBLOCK COMPLETED -- ROOTED BY VLADIMIR           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  Status          : Ad Blocking Active (Google Play & APK installs functional)$X"
Write-Host "$W  Execution Time  : $elapsedSec seconds$X"
Write-Host "$W  Finished At     : $finishDate$X"
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

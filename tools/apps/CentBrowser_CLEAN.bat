@echo off
:: ==========================================================================================
:: FILE    : CentBrowser_CLEAN.bat
:: VERSION : v2026.08.16
:: AUTHOR  : = Rooted by VladiMIR | AI =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   High-performance universal multi-profile cache cleaner for CentBrowser & Chromium.
::   Dynamically scans, detects, and purges all junk from 1 to 500+ client profiles in:
::   - D:\UTIL\N E T\CHROME_temp
::   - %LOCALAPPDATA%\CentBrowser\User Data
::   - %LOCALAPPDATA%\Google\Chrome\User Data
::   - %LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data
::   - %LOCALAPPDATA%\Microsoft\Edge\User Data
::   - %LOCALAPPDATA%\Yandex\YandexBrowser\User Data
::
:: SAFETY GUARANTEE:
::   Preserves all logins, passwords, cookies, bookmarks, history, and extensions!
::   Only removes transient render caches (Disk Cache, Code Cache, GPUCache, Service Workers).
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
    $host.UI.RawUI.WindowTitle = "CENTBROWSER MULTI-PROFILE CLEANER v2026.08.16 -- Rooted by VladiMIR"
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 42)
} catch {}

$sessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Banner
Clear-Host
Write-Host "$Y================================================================================$X"
Write-Host "$B$BOLD       CENTBROWSER & CHROMIUM MULTI-PROFILE CACHE CLEANER     v2026.08.16 $X"
Write-Host "$D             Author: = Rooted by VladiMIR | AI = | github.com/GinCz           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  User/Host : $env:USERNAME@$env:COMPUTERNAME$X"
Write-Host "$W  Started   : $sessionDate$X"
Write-Host ""

# Check running browser processes
$runningBrowsers = Get-Process -Name "chrome", "centbrowser", "brave", "msedge" -ErrorAction SilentlyContinue
if ($runningBrowsers) {
    Write-Host "$Y  [!] NOTE: Browser processes are currently active.$X"
    Write-Host "$D      Active files will be safely skipped. For 100% deep cleaning, close browsers.$X"
    Write-Host ""
}

$startTime = [System.Diagnostics.Stopwatch]::StartNew()
$script:totalFilesDeleted = 0
$script:totalBytesFreed = 0
$script:totalProfilesCleaned = 0

# Candidate Root Directories containing client profiles
$profileRoots = @(
    "D:\UTIL\N E T\CHROME_temp",
    "$env:LOCALAPPDATA\CentBrowser\User Data",
    "$env:LOCALAPPDATA\Google\Chrome\User Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data"
)

$targetCacheFolders = @(
    "Cache",
    "Cache_Data",
    "Code Cache",
    "GPUCache",
    "GrShaderCache",
    "GraphiteDawnCache",
    "Service Worker\CacheStorage",
    "Service Worker\ScriptCache",
    "Media Cache",
    "Crashpad\reports",
    "blob_storage"
)

$rootIndex = 0

foreach ($root in $profileRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    $rootIndex++
    Write-Host "$B  [ Container $rootIndex ] $root$X"

    # Discover profiles in root
    $profiles = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -match '^(Default|Profile \d+|System Profile)$' -or (Test-Path (Join-Path $_.FullName "Preferences")) }

    if (-not $profiles -or $profiles.Count -eq 0) {
        Write-Host "$D      No profile directories found in this container.$X"
        Write-Host ""
        continue
    }

    Write-Host "$W      Found $($profiles.Count) profiles. Purging temporary caches...$X"

    $containerFiles = 0
    $containerBytes = 0

    foreach ($profile in $profiles) {
        $script:totalProfilesCleaned++

        foreach ($sub in $targetCacheFolders) {
            $cachePath = Join-Path $profile.FullName $sub
            if (Test-Path -LiteralPath $cachePath) {
                try {
                    $items = Get-ChildItem -LiteralPath $cachePath -Recurse -File -Force -ErrorAction SilentlyContinue
                    if ($items) {
                        foreach ($f in $items) {
                            $containerBytes += $f.Length
                            $containerFiles++
                        }
                    }
                    Remove-Item -LiteralPath "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }
    }

    $script:totalFilesDeleted += $containerFiles
    $script:totalBytesFreed += $containerBytes
    $mbFreed = [math]::Round($containerBytes / 1MB, 2)

    Write-Host "$G      [OK] Cleaned $($profiles.Count) profiles: $containerFiles files (~$mbFreed MB freed)$X"
    Write-Host ""
}

$startTime.Stop()
$elapsedSec = [math]::Round($startTime.Elapsed.TotalSeconds, 2)
$totalMb = [math]::Round($script:totalBytesFreed / 1MB, 2)
$finishDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Summary
Write-Host "$Y================================================================================$X"
Write-Host "$G$BOLD                 BROWSER CACHE CLEANUP COMPLETE -- ROOTED BY VLADIMIR    $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  Total Profiles Processed : $script:totalProfilesCleaned$X"
Write-Host "$W  Total Cache Files Cleared: $script:totalFilesDeleted$X"
Write-Host "$W  Total Disk Space Freed   : $totalMb MB$X"
Write-Host "$W  Execution Time           : $elapsedSec seconds$X"
Write-Host "$W  Finished At              : $finishDate$X"
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

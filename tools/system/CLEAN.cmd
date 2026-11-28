@echo off
:: ==========================================================================================
:: FILE    : CLEAN.cmd
:: VERSION : v2026.11.14
:: AUTHOR  : = Rooted by VladiMIR | AI =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Ultimate High-Performance Windows System Cleanup & Security Sweeper.
::   Synchronized with Dism++ Deep Cleanup Standard & GIN-Win-Optimizer v047.
::   Self-contained polyglot script that automatically elevates to Administrator.
::
:: SCOPE (Dism++ Complete Alignment):
::   - User, System & WinSxS Temp directories
::   - Windows Installer baseline patch cache (`$PatchCache`$) & temporary installer files
::   - Microsoft Office setup sources (MSOCache) & Office 365/2016 download caches
::   - Hardware driver package caches (NVIDIA C:\NVIDIA, Downloader; Realtek)
::   - Windows Update download caches & Delivery Optimization fragments
::   - Windows Event Logs & Service Traces (CBS, DISM, Panther)
::   - Application crash dumps, WER queues & Kernel BSOD Minidumps
::   - Windows Defender Protection History cleanup
::   - DirectX, GPU shader (AMD, NVIDIA, Intel) & RDP Terminal Server bitmap caches
::   - Superseded Chrome / Edge / Cent Browser old version backup directories
::   - Windows Prefetch, .NET assembly logs, Java & Adobe runtime caches
::   - Windows Explorer thumbnail databases (thumbcache_*.db, iconcache_*.db)
::   - Package Cache & Dism++ temporary unpacking folders
::   - System Recycle Bins across all drives
::   - Known malware & rogue drop persistence (wendos, wuauclt1, svchost1, disguised scripts)
::   * Note: Active Windows Installer database (.msi/.msp) and user browser profiles,
::     bookmarks, passwords, and sessions are safely preserved.
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
    [switch]$Startup,
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
    $host.UI.RawUI.WindowTitle = "GINCZ ULTIMATE SYSTEM CLEANUP v2026.11.14 -- Rooted by VladiMIR"
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 44)
} catch {}

$sessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Banner
Clear-Host
Write-Host "$Y================================================================================$X"
Write-Host "$B$BOLD       GINCZ ULTIMATE SYSTEM CLEANUP & SECURITY SWEEPER      v2026.11.14  $X"
Write-Host "$D             Author: = Rooted by VladiMIR | AI = | github.com/GinCz           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  User/Host : $env:USERNAME@$env:COMPUTERNAME$X"
Write-Host "$W  Started   : $sessionDate$X"
Write-Host ""

# Startup Delay (15 seconds for background Windows boot tasks to settle)
if ($Startup -and -not ($Fast -or $Now)) {
    Write-Host "$Y  [*] Startup mode: Waiting 15 seconds for Windows services to settle...$X"
    Write-Host "$D      (Press any key to start cleanup immediately)$X"
    Write-Host ""
    
    for ($i = 15; $i -gt 0; $i--) {
        Write-Host -NoNewline "$D`r      Starting in $i seconds... $X"
        try {
            if ([Console]::KeyAvailable) {
                $null = [Console]::ReadKey($true)
                break
            }
        } catch {}
        Start-Sleep -Seconds 1
    }
    Write-Host "`r                                                   `r"
}

$startTime = [System.Diagnostics.Stopwatch]::StartNew()
$script:totalFilesDeleted = 0
$script:totalBytesFreed = 0

function Clean-TargetItems {
    param (
        [int]$Step,
        [int]$TotalSteps,
        [string]$Title,
        [string]$Description,
        [string[]]$Targets,
        [string]$Filter = ""
    )

    Write-Host "$B  [ $Step / $TotalSteps ] $Title$X"
    Write-Host "$D  Description: $Description$X"

    $stepFiles = 0
    $stepBytes = 0

    foreach ($target in $Targets) {
        if ([string]::IsNullOrWhiteSpace($target)) { continue }

        if ($target.Contains("*") -or $target.Contains("?")) {
            # Target is a wildcard pattern
            try {
                $dir = Split-Path -Path $target -Parent
                $leaf = Split-Path -Path $target -Leaf
                if (Test-Path -LiteralPath $dir) {
                    $found = Get-ChildItem -LiteralPath $dir -Filter $leaf -Force -ErrorAction SilentlyContinue
                    foreach ($f in $found) {
                        try {
                            if ($f.PSIsContainer) {
                                $subFiles = Get-ChildItem -LiteralPath $f.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                                if ($subFiles) {
                                    foreach ($sf in $subFiles) {
                                        $stepBytes += $sf.Length
                                        $stepFiles++
                                    }
                                }
                                Remove-Item -LiteralPath $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
                            } else {
                                $stepBytes += $f.Length
                                $stepFiles++
                                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                            }
                        } catch {}
                    }
                }
            } catch {}
        }
        elseif (Test-Path -LiteralPath $target) {
            # Target is a direct path
            try {
                $item = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
                if ($item.PSIsContainer) {
                    # Clean contents inside folder
                    $items = if ([string]::IsNullOrWhiteSpace($Filter)) {
                        Get-ChildItem -LiteralPath $target -Force -ErrorAction SilentlyContinue
                    } else {
                        Get-ChildItem -LiteralPath $target -Filter $Filter -Force -ErrorAction SilentlyContinue
                    }
                    foreach ($sub in $items) {
                        try {
                            if ($sub.PSIsContainer) {
                                $subFiles = Get-ChildItem -LiteralPath $sub.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                                if ($subFiles) {
                                    foreach ($sf in $subFiles) {
                                        $stepBytes += $sf.Length
                                        $stepFiles++
                                    }
                                }
                                Remove-Item -LiteralPath $sub.FullName -Recurse -Force -ErrorAction SilentlyContinue
                            } else {
                                $stepBytes += $sub.Length
                                $stepFiles++
                                Remove-Item -LiteralPath $sub.FullName -Force -ErrorAction SilentlyContinue
                            }
                        } catch {}
                    }
                } else {
                    # Single file
                    $stepBytes += $item.Length
                    $stepFiles++
                    Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    }

    $script:totalFilesDeleted += $stepFiles
    $script:totalBytesFreed += $stepBytes
    $mbFreed = [math]::Round($stepBytes / 1MB, 2)

    Write-Host "$G  [OK] Cleaned $stepFiles items (~$mbFreed MB)$X`n"
}

function Clean-BrowserOldVersions {
    param (
        [int]$Step,
        [int]$TotalSteps
    )

    Write-Host "$B  [ $Step / $TotalSteps ] Superseded Browser Backup Copies$X"
    Write-Host "$D  Description: Removes superseded version backups in Chrome, Edge & Cent Browser.$X"

    $stepFiles = 0
    $stepBytes = 0

    $browserDirs = @(
        "C:\Program Files\Google\Chrome\Application",
        "C:\Program Files (x86)\Google\Chrome\Application",
        "$env:LOCALAPPDATA\Google\Chrome\Application",
        "C:\Program Files\CentBrowser\Application",
        "C:\Program Files (x86)\CentBrowser\Application",
        "$env:LOCALAPPDATA\CentBrowser\Application",
        "C:\Program Files (x86)\Microsoft\Edge\Application",
        "C:\Program Files\Microsoft\Edge\Application"
    )

    foreach ($bDir in $browserDirs) {
        if (-not (Test-Path -LiteralPath $bDir)) { continue }
        try {
            $verDirs = Get-ChildItem -LiteralPath $bDir -Directory -Force -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -match '^[0-9]+(\.[0-9]+)+' } | 
                Sort-Object { try { [version]($_.Name -replace '[^0-9.].*$', '') } catch { $_.Name } }

            if ($verDirs.Count -gt 1) {
                # Keep strictly the newest active version; remove older superseded rollback folders
                $oldDirs = $verDirs[0..($verDirs.Count - 2)]
                foreach ($od in $oldDirs) {
                    $subFiles = Get-ChildItem -LiteralPath $od.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                    if ($subFiles) {
                        foreach ($sf in $subFiles) {
                            $stepBytes += $sf.Length
                            $stepFiles++
                        }
                    }
                    Remove-Item -LiteralPath $od.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "$R  Purged old version backup: $($od.FullName)$X"
                }
            }
        } catch {}
    }

    $script:totalFilesDeleted += $stepFiles
    $script:totalBytesFreed += $stepBytes
    $mbFreed = [math]::Round($stepBytes / 1MB, 2)
    Write-Host "$G  [OK] Browser backups cleaned: $stepFiles items (~$mbFreed MB)$X`n"
}

function Clear-WindowsEventLogs {
    param (
        [int]$Step,
        [int]$TotalSteps
    )

    Write-Host "$B  [ $Step / $TotalSteps ] Windows Event Logs & Service Traces$X"
    Write-Host "$D  Description: Clears system, application, security, and setup event logs.$X"

    $cleared = 0
    try {
        $logs = wevtutil.exe el 2>$null
        foreach ($l in $logs) {
            if ($l) {
                wevtutil.exe cl "$l" 2>$null
                $cleared++
            }
        }
    } catch {}

    # Also clean CBS, DISM, and Panther logs
    $logPaths = @(
        "$env:SystemRoot\Logs\CBS",
        "$env:SystemRoot\Logs\DISM",
        "$env:SystemRoot\Panther"
    )
    foreach ($lp in $logPaths) {
        if (Test-Path -LiteralPath $lp) {
            Get-ChildItem -LiteralPath $lp -Recurse -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "$G  [OK] Cleared $cleared Event Log channels and trace folders$X`n"
}

function Clear-SystemRecycleBins {
    param (
        [int]$Step,
        [int]$TotalSteps
    )

    Write-Host "$B  [ $Step / $TotalSteps ] Empty System Recycle Bins$X"
    Write-Host "$D  Description: Empties Recycle Bin across all local and connected drives.$X"

    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "$G  [OK] Recycle Bins emptied successfully$X`n"
    } catch {
        Write-Host "$D  [SKIP] Recycle Bin empty or already cleared$X`n"
    }
}

$totalSteps = 16

# 1. User Temporary Files
Clean-TargetItems -Step 1 -TotalSteps $totalSteps `
    -Title "User Temporary Files" `
    -Description "Cleans application runtime cache and temporary files in User Temp." `
    -Targets @(
        "$env:LOCALAPPDATA\Temp",
        "$env:USERPROFILE\AppData\Local\Temp",
        "$env:USERPROFILE\Local Settings\Temp"
    )

# 2. Windows System & WinSxS Temporary Files
Clean-TargetItems -Step 2 -TotalSteps $totalSteps `
    -Title "Windows System & WinSxS Temporary Files" `
    -Description "Cleans system service temporary files in C:\Windows\Temp and WinSxS\Temp." `
    -Targets @(
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\WinSxS\Temp",
        "$env:SystemRoot\CbsTemp"
    )

# 3. Windows Installer Baseline & Patch Cache
Clean-TargetItems -Step 3 -TotalSteps $totalSteps `
    -Title "Windows Installer Baseline & Patch Cache" `
    -Description "Removes baseline patch cache (`$PatchCache`$) and temporary installer files without touching active MSIs." `
    -Targets @(
        "$env:SystemRoot\Installer\`$PatchCache`$",
        "$env:SystemRoot\Installer\*.tmp"
    )

# 4. Microsoft Office Setup Source & Update Cache
Clean-TargetItems -Step 4 -TotalSteps $totalSteps `
    -Title "Microsoft Office Setup Source & Update Cache" `
    -Description "Cleans MSOCache and Office 365/2016 downloaded update installers." `
    -Targets @(
        "C:\MSOCache",
        "$env:ProgramFiles\Microsoft Office\Updates\Download",
        "${env:ProgramFiles(x86)}\Microsoft Office\Updates\Download"
    )

# 5. Hardware Driver Package Installer Caches (NVIDIA, Realtek)
Clean-TargetItems -Step 5 -TotalSteps $totalSteps `
    -Title "Hardware Driver Installer Caches (NVIDIA & Realtek)" `
    -Description "Purges extracted setup packages and downloaded installers from NVIDIA and Realtek." `
    -Targets @(
        "C:\NVIDIA",
        "$env:ProgramData\NVIDIA Corporation\Downloader",
        "$env:ProgramData\NVIDIA Corporation\NetService\*.exe",
        "C:\Realtek",
        "$env:ProgramData\Realtek"
    )

# 6. Windows Update Cache & Delivery Optimization
Clean-TargetItems -Step 6 -TotalSteps $totalSteps `
    -Title "Windows Update Cache & Delivery Optimization" `
    -Description "Purges downloaded update packages and peer-to-peer Windows update download fragments." `
    -Targets @(
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\SoftwareDistribution\DataStore\Logs",
        "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
    )

# 7. Windows Event Logs & Service Traces
Clear-WindowsEventLogs -Step 7 -TotalSteps $totalSteps

# 8. Application Crash Dumps, WER Reports & BSOD Minidumps
Clean-TargetItems -Step 8 -TotalSteps $totalSteps `
    -Title "Application Crash Dumps, WER & Kernel BSOD Minidumps" `
    -Description "Removes leftover memory crash dumps, queued telemetry, and blue-screen minidump traces." `
    -Targets @(
        "$env:LOCALAPPDATA\CrashDumps",
        "$env:SystemRoot\Minidump",
        "$env:SystemRoot\MEMORY.DMP",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportArchive",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\Temp",
        "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
        "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
        "$env:ProgramData\Microsoft\Windows\WER\Temp"
    )

# 9. Windows Defender Protection History
Clean-TargetItems -Step 9 -TotalSteps $totalSteps `
    -Title "Windows Defender Protection History" `
    -Description "Clears stale detection history and scan results to remove stuck security alerts." `
    -Targets @(
        "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory",
        "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Results\Quick",
        "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Results\Resource"
    )

# 10. DirectX, GPU Shader & Terminal Server Client Cache
Clean-TargetItems -Step 10 -TotalSteps $totalSteps `
    -Title "DirectX, GPU Shaders & Terminal Server Client Cache" `
    -Description "Cleans stale GPU shader caches (AMD, NVIDIA, Intel, D3D) and RDP client bitmap caches." `
    -Targets @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\AMD\DxCache",
        "$env:LOCALAPPDATA\Intel\ShaderCache",
        "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache"
    )

# 11. Superseded Browser Backup Copies
Clean-BrowserOldVersions -Step 11 -TotalSteps $totalSteps

# 12. Windows Prefetch, .NET Caches & Runtime Temp
Clean-TargetItems -Step 12 -TotalSteps $totalSteps `
    -Title "Windows Prefetch, .NET Caches & Runtime Temp" `
    -Description "Cleans Windows Prefetch files, .NET ngen logs, Java Deployment cache, and Adobe temp." `
    -Targets @(
        "$env:SystemRoot\Prefetch",
        "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\cache",
        "$env:USERPROFILE\AppData\LocalLow\Oracle\Java\Deployment\cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\DC\Cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\2020\Cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\2024\Cache",
        "$env:USERPROFILE\Local Settings\Application Data\Adobe\Updater6\Install",
        "$env:SystemRoot\Microsoft.NET\Framework\v*\ngen.log",
        "$env:SystemRoot\Microsoft.NET\Framework64\v*\ngen.log"
    )

# 13. Windows Explorer Thumbnail & Icon Caches
Clean-TargetItems -Step 13 -TotalSteps $totalSteps `
    -Title "Windows Explorer Thumbnail & Icon Caches" `
    -Description "Cleans thumbnail and icon databases (thumbcache_*.db, iconcache_*.db)." `
    -Targets @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db"
    )

# 14. Package Cache & Dism++ Temporary Files
Clean-TargetItems -Step 14 -TotalSteps $totalSteps `
    -Title "Package Cache & Dism++ Temporary Components" `
    -Description "Cleans Dism++ temporary extraction artifacts and Package Cache installer remnants." `
    -Targets @(
        "$env:TEMP\Dism++*",
        "$env:LOCALAPPDATA\Temp\Dism++*",
        "$env:ProgramData\Package Cache\*.tmp"
    )

# 15. Empty System Recycle Bins
Clear-SystemRecycleBins -Step 15 -TotalSteps $totalSteps

# 16. Known Malware & Rogue Drop Artifacts Purge
Clean-TargetItems -Step 16 -TotalSteps $totalSteps `
    -Title "Malware & Rogue Persistence Sweeper" `
    -Description "Purges known rogue drops: wendos trojan, wuauclt1/svchost1 miners, and disguised scripts." `
    -Targets @(
        "$env:SystemRoot\System32\wendos",
        "$env:SystemRoot\SysWOW64\wendos",
        "$env:SystemRoot\System32\wuauclt1.exe",
        "$env:SystemRoot\SysWOW64\wuauclt1.exe",
        "$env:SystemRoot\System32\svchost1.exe",
        "$env:SystemRoot\SysWOW64\svchost1.exe",
        "$env:SystemRoot\System32\spoolsv1.exe",
        "$env:SystemRoot\System32\rundll321.exe",
        "$env:SystemRoot\ERDNT",
        "$env:SystemRoot\Debug\wendos",
        "$env:APPDATA\Microsoft\Windows\Templates\*.vbs",
        "$env:APPDATA\Microsoft\Windows\Templates\*.exe",
        "$env:LOCALAPPDATA\Temp\*.vbe",
        "$env:LOCALAPPDATA\Temp\*.jse"
    )

$startTime.Stop()
$elapsedSec = [math]::Round($startTime.Elapsed.TotalSeconds, 2)
$totalMb = [math]::Round($script:totalBytesFreed / 1MB, 2)
$finishDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Summary
Write-Host "$Y================================================================================$X"
Write-Host "$G$BOLD                    CLEANUP COMPLETE -- ROOTED BY VLADIMIR              $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  Total Files Deleted : $script:totalFilesDeleted$X"
Write-Host "$W  Total Space Freed   : $totalMb MB$X"
Write-Host "$W  Execution Time      : $elapsedSec seconds$X"
Write-Host "$W  Finished At         : $finishDate$X"
Write-Host ""

if ($Startup) {
    Write-Host "$D  Startup mode complete. Closing in 3 seconds...$X"
    Start-Sleep -Seconds 3
} else {
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
}

@echo off
:: ==========================================================================================
:: FILE    : CLEAN.cmd
:: VERSION : v2026.08.16
:: AUTHOR  : = Rooted by VladiMIR | AI =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Ultimate High-Performance Windows System Cleanup & Security Sweeper.
::   Self-contained polyglot script that automatically elevates to Administrator.
::
:: SCOPE:
::   - User & Windows System Temp directories
::   - Known malware & rogue drop persistence (wendos, wuauclt1, svchost1, disguised scripts)
::   - Application crash dumps & Windows Error Reporting (WER) queues
::   - Windows Update download caches & Delivery Optimization fragments
::   - DirectX, AMD, NVIDIA & Intel GPU shader caches
::   - Java Runtime & Adobe Acrobat temp caches
::   - Windows BSOD Minidumps, ERDNT & Debug logs
::   - Diagnostic & DISM temporary logs
::   * Note: Recycle Bins and user browser client profiles are safely preserved.
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
    $host.UI.RawUI.WindowTitle = "GINCZ ULTIMATE SYSTEM CLEANUP v2026.08.16 -- Rooted by VladiMIR"
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 42)
} catch {}

$sessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

# Banner
Clear-Host
Write-Host "$Y================================================================================$X"
Write-Host "$B$BOLD       GINCZ ULTIMATE SYSTEM CLEANUP & SECURITY SWEEPER      v2026.08.16  $X"
Write-Host "$D             Author: = Rooted by VladiMIR | AI = | github.com/GinCz           $X"
Write-Host "$Y================================================================================$X"
Write-Host ""
Write-Host "$W  User/Host : $env:USERNAME@$env:COMPUTERNAME$X"
Write-Host "$W  Started   : $sessionDate$X"
Write-Host ""

# Startup Delay (30 seconds for background Windows boot tasks to settle)
if ($Startup -and -not ($Fast -or $Now)) {
    Write-Host "$Y  [*] Startup mode: Waiting 30 seconds for Windows services to settle...$X"
    Write-Host "$D      (Press any key to start cleanup immediately)$X"
    Write-Host ""
    
    for ($i = 30; $i -gt 0; $i--) {
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

function Clean-DirectoryTarget {
    param (
        [int]$Step,
        [int]$TotalSteps,
        [string]$Title,
        [string]$Description,
        [string[]]$Paths
    )

    Write-Host "$B  [ $Step / $TotalSteps ] $Title$X"
    Write-Host "$D  Description: $Description$X"

    $stepFiles = 0
    $stepBytes = 0

    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
            continue
        }

        try {
            $items = Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    if ($item.PSIsContainer) {
                        $subFiles = Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                        if ($subFiles) {
                            foreach ($sf in $subFiles) {
                                $stepBytes += $sf.Length
                                $stepFiles++
                            }
                        }
                        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        $stepBytes += $item.Length
                        $stepFiles++
                        Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        } catch {}
    }

    $script:totalFilesDeleted += $stepFiles
    $script:totalBytesFreed += $stepBytes
    $mbFreed = [math]::Round($stepBytes / 1MB, 2)

    Write-Host "$G  [OK] Cleaned $stepFiles files (~$mbFreed MB)$X"
    Write-Host ""
}

function Clean-SpecificThreats {
    param (
        [int]$Step,
        [int]$TotalSteps,
        [string]$Title,
        [string]$Description,
        [string[]]$Targets
    )

    Write-Host "$B  [ $Step / $TotalSteps ] $Title$X"
    Write-Host "$D  Description: $Description$X"

    $stepFiles = 0
    $stepBytes = 0

    foreach ($target in $Targets) {
        if ($target.Contains("*")) {
            try {
                $dir = Split-Path -Path $target -Parent
                $leaf = Split-Path -Path $target -Leaf
                if (Test-Path -LiteralPath $dir) {
                    $found = Get-ChildItem -Path $dir -Filter $leaf -File -Force -ErrorAction SilentlyContinue
                    foreach ($f in $found) {
                        $stepBytes += $f.Length
                        $stepFiles++
                        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                        Write-Host "$R  Purged rogue drop: $($f.FullName)$X"
                    }
                }
            } catch {}
        } else {
            if (Test-Path -LiteralPath $target) {
                try {
                    $item = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
                    if ($item.PSIsContainer) {
                        $subFiles = Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue
                        if ($subFiles) {
                            foreach ($sf in $subFiles) {
                                $stepBytes += $sf.Length
                                $stepFiles++
                            }
                        }
                        Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "$R  Purged rogue dir: $target$X"
                    } else {
                        $stepBytes += $item.Length
                        $stepFiles++
                        Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
                        Write-Host "$R  Purged rogue file: $target$X"
                    }
                } catch {}
            }
        }
    }

    $script:totalFilesDeleted += $stepFiles
    $script:totalBytesFreed += $stepBytes
    $mbFreed = [math]::Round($stepBytes / 1MB, 2)

    Write-Host "$G  [OK] Threats & Persistence purged: $stepFiles items (~$mbFreed MB)$X"
    Write-Host ""
}

$totalSteps = 10

# 1. User Temp
Clean-DirectoryTarget -Step 1 -TotalSteps $totalSteps `
    -Title "User Temporary Files" `
    -Description "Cleans application runtime cache and temporary files in User Temp." `
    -Paths @("$env:LOCALAPPDATA\Temp", "$env:USERPROFILE\AppData\Local\Temp")

# 2. Windows System Temp
Clean-DirectoryTarget -Step 2 -TotalSteps $totalSteps `
    -Title "Windows System Temp" `
    -Description "Cleans system service temporary files in C:\Windows\Temp." `
    -Paths @("$env:SystemRoot\Temp")

# 3. Known Malware & Rogue Drop Persistence Purge
Clean-SpecificThreats -Step 3 -TotalSteps $totalSteps `
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

# 4. Application Crash Dumps & Windows Error Reporting (WER)
Clean-DirectoryTarget -Step 4 -TotalSteps $totalSteps `
    -Title "Application Crash Dumps & Windows Error Reporting (WER)" `
    -Description "Removes leftover memory crash dumps, queued telemetry, and diagnostic logs." `
    -Paths @(
        "$env:LOCALAPPDATA\CrashDumps",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportArchive",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\Temp",
        "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
        "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
        "$env:ProgramData\Microsoft\Windows\WER\Temp"
    )

# 5. Windows Update Installer Cache & Delivery Optimization
Clean-DirectoryTarget -Step 5 -TotalSteps $totalSteps `
    -Title "Windows Update Cache & Delivery Optimization" `
    -Description "Purges downloaded update packages and peer-to-peer Windows update download fragments." `
    -Paths @(
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
    )

# 6. Windows INetCache & System Web Runtime Temp
Clean-DirectoryTarget -Step 6 -TotalSteps $totalSteps `
    -Title "System INetCache & Web Runtime Temp" `
    -Description "Cleans IE/Edge runtime background web cache." `
    -Paths @(
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\IE",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\Low\IE"
    )

# 7. Software & Runtime Caches (Java, Adobe)
Clean-DirectoryTarget -Step 7 -TotalSteps $totalSteps `
    -Title "Software & Runtime Caches (Java VM, Adobe Acrobat)" `
    -Description "Cleans temporary runtime caches for Java VM and Adobe Acrobat." `
    -Paths @(
        "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\cache",
        "$env:USERPROFILE\AppData\LocalLow\Oracle\Java\Deployment\cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\DC\Cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\2020\Cache",
        "$env:LOCALAPPDATA\Adobe\Acrobat\2024\Cache",
        "$env:USERPROFILE\Local Settings\Application Data\Adobe\Updater6\Install"
    )

# 8. GPU & DirectX Shader Caches
Clean-DirectoryTarget -Step 8 -TotalSteps $totalSteps `
    -Title "DirectX & GPU Shader Cache" `
    -Description "Cleans stale compiled shaders for AMD, NVIDIA, Intel, and D3D." `
    -Paths @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\AMD\DxCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\Intel\ShaderCache"
    )

# 9. Kernel BSOD Minidumps, ERDNT & Debug Logs
Clean-DirectoryTarget -Step 9 -TotalSteps $totalSteps `
    -Title "Kernel BSOD Minidumps & Windows Debug Logs" `
    -Description "Cleans blue-screen memory dump logs and debug trace files." `
    -Paths @(
        "$env:SystemRoot\Minidump",
        "$env:SystemRoot\Debug"
    )

# 10. System Diagnostic & DISM Temp Logs
Clean-DirectoryTarget -Step 10 -TotalSteps $totalSteps `
    -Title "System Diagnostic & DISM Temp Logs" `
    -Description "Cleans temporary log archives in Windows Logs and Panther." `
    -Paths @(
        "$env:SystemRoot\Logs\DISM",
        "$env:SystemRoot\Panther"
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

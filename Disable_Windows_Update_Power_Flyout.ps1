# =============================================================================
# Execution Context : PowerShell (Run as Administrator)
# Target Server     : Windows 10 / Windows 11 / Windows Server
# Description       : Suppress Windows Update shutdown flyout options via Orchestrator
# Author            : = Rooted by VladiMIR + AI | github.com/GinCz =
# Repository        : github.com/GinCz/Windows_scripts
# =============================================================================
cls

Write-Host ">>> Configuring ShutdownFlyoutOptions and EnhancedShutdown..." -ForegroundColor Cyan

# 1. Target registry keys for Update Orchestrator flyout control
$orchestratorKeys = @(
    "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator",
    "HKCU:\Software\Microsoft\WindowsUpdate\Orchestrator"
)

foreach ($keyPath in $orchestratorKeys) {
    if (-not (Test-Path $keyPath)) {
        New-Item -Path $keyPath -Force | Out-Null
    }

    # Set ShutdownFlyoutOptions to 0 (Disables 'Update and shut down' / 'Update and restart')
    Set-ItemProperty -Path $keyPath -Name "ShutdownFlyoutOptions" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $keyPath -Name "EnhancedShutdownEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $keyPath -Name "FlightedEnhancedShutdownEnabled" -Value 0 -Type DWord -Force

    Write-Host "[+] Configured standard flyout options (Value = 0) in: $keyPath" -ForegroundColor Green
}

# 2. Permanently disable the Update Orchestrator service in the registry to prevent reset
$serviceKeys = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc",
    "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc",
    "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv"
)

foreach ($svcKey in $serviceKeys) {
    if (Test-Path $svcKey) {
        Set-ItemProperty -Path $svcKey -Name "Start" -Value 4 -Type DWord -Force
        Write-Host "[+] Service permanently disabled (Start = 4): $(Split-Path $svcKey -Leaf)" -ForegroundColor Green
    }
}

# 3. Clear Session Manager pending file operations
$smPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$smProps = Get-ItemProperty -Path $smPath -ErrorAction SilentlyContinue
if ($smProps -and $smProps.PendingFileRenameOperations) {
    Remove-ItemProperty -Path $smPath -Name "PendingFileRenameOperations" -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Cleared PendingFileRenameOperations under Session Manager." -ForegroundColor Green
}
if ($smProps -and $smProps.PendingFileRenameOperations2) {
    Remove-ItemProperty -Path $smPath -Name "PendingFileRenameOperations2" -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Cleared PendingFileRenameOperations2 under Session Manager." -ForegroundColor Green
}

# 4. Restart Explorer to immediately rebuild the Win+X flyout menu
Write-Host "[*] Restarting Windows Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer.exe
}

# 5. Verify the active registry value
$verified = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator" -Name "ShutdownFlyoutOptions" -ErrorAction SilentlyContinue
Write-Host "`n>>> Done! Active ShutdownFlyoutOptions value: $($verified.ShutdownFlyoutOptions)" -ForegroundColor Cyan

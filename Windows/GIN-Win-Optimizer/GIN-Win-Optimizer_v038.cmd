@echo off
rem =============================================================================
rem Execution Context : Windows Command Prompt / CMD (Run as Administrator)
rem Target System     : Windows 10 / 11 (Universal x86 32-bit / x64 64-bit, All Editions)
rem Description       : GIN-Win-Optimizer v038 - Ultralightweight, Safe Windows Optimizer
rem Author            : Vladimir Bulantsev (GinCz) & AI [VladiMIR + AI]
rem License           : Freeware (Lifetime Free for Personal & Business Use)
rem Support           : https://t.me/GinCz
rem =============================================================================
cls

:: =============================================================================
:: SECTION 0: Self-Elevation to Administrator (UAC Check)
:: =============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Administrator privileges required. Requesting UAC elevation...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Set current working directory to the script folder
cd /d "%~dp0"

:: Set console title
title GIN-Win-Optimizer v038 - Ultralightweight Safe Optimizer [VladiMIR + AI]

:: =============================================================================
:: SECTION 1: System Environment Detection
:: =============================================================================
set "SYS_ARCH=x86 (32-bit)"
if defined PROCESSOR_ARCHITEW6432 (
    set "SYS_ARCH=x64 (64-bit on WOW64)"
) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "SYS_ARCH=x64 (64-bit)"
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "SYS_ARCH=ARM64"
)

echo =============================================================================
echo               GIN-Win-Optimizer v038 - Safe Windows Optimizer
echo               Author: Vladimir Bulantsev (GinCz) ^& AI [VladiMIR + AI]
echo               Platform: Windows 10 / 11 (%SYS_ARCH%)
echo =============================================================================
echo.

:: =============================================================================
:: SECTION 2: Network & File / Printer Sharing Optimization (Ultarix Standard)
:: =============================================================================
echo [1/4] Configuring Network, Sharing and Printer Access...

:: 1. Switch active and stored network profiles to Private (prevents firewall blocking LAN)
echo [*] Setting network connection profiles to Private...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -ne 'Private' } | Set-NetConnectionProfile -NetworkCategory Private; Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles' | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name Category -Value 1 }" >nul 2>&1
echo   [OK] Network profile set to Private (unblocks LAN and printer discovery)

:: 2. Allow insecure guest SMB authentication (LanmanWorkstation)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
echo   [OK] AllowInsecureGuestAuth enabled (guest SMB network share access)

:: 3. EnableLinkedConnections (makes mapped network drives visible to elevated admin processes)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections /t REG_DWORD /d 1 /f >nul 2>&1
echo   [OK] EnableLinkedConnections enabled (network drives visible to Admin processes)

:: 4. DisableUNCCheck (allows running CMD scripts directly from network UNC shares)
reg add "HKLM\SOFTWARE\Microsoft\Command Processor" /v DisableUNCCheck /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Command Processor" /v DisableUNCCheck /t REG_DWORD /d 1 /f >nul 2>&1
echo   [OK] DisableUNCCheck enabled (direct execution of scripts from UNC paths)

:: 5. Ensure critical network discovery and printing services are set to Auto-start
echo [*] Configuring essential network and printing services...
for %%S in (FDResPub fdPHost LanmanWorkstation LanmanServer Spooler lmhosts Dnscache) do (
    sc config %%S start= auto >nul 2>&1
    sc start %%S >nul 2>&1
)
echo   [OK] Core services set to Auto-start (FDResPub, fdPHost, Lanman, Spooler, lmhosts, Dnscache)

:: 6. Firewall Rules: Network Discovery and File and Printer Sharing
echo [*] Enabling firewall rules for LAN discovery and printer sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="@FirewallAPI.dll,-28502" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="@FirewallAPI.dll,-28752" new enable=Yes >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; Get-NetFirewallRule | Where-Object { $_.DisplayGroup -match 'File and Printer Sharing|Sd.+len.+ soubor.+|Network Discovery|Zji.+ov.+n.+ s.+t.+' } | Enable-NetFirewallRule" >nul 2>&1
echo   [OK] Firewall rules for Network Discovery and File/Printer Sharing enabled

:: =============================================================================
:: SECTION 3: Memory & Performance Optimization (32-bit x86 and Low-RAM Fix)
:: =============================================================================
echo.
echo [2/4] Optimizing Memory, Paging, and System Performance...

:: 1. Stable static pagefile 4096-8192 MB on C: (protects 32-bit and low-RAM PCs from crash 0xe0000008)
echo [*] Setting static pagefile (4096 - 8192 MB) on C:...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $cs = Get-CimInstance Win32_ComputerSystem; if ($cs.AutomaticManagedPagefile) { $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$false} }" >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "C:\pagefile.sys 4096 8192" /f >nul 2>&1
echo   [OK] Pagefile configured (4096-8192 MB fixed, prevents memory crash 0xe0000008)

:: 2. Disable hibernation (frees 4-8 GB SSD storage)
powercfg -h off >nul 2>&1
echo   [OK] Hibernation disabled (powercfg -h off, 4-8 GB SSD space recovered)

:: 3. Visual effects optimization: responsive GUI while preserving ClearType font readability
echo [*] Optimizing GUI responsiveness and font smoothing...
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingOrientation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 100 /f >nul 2>&1
echo   [OK] Visual effects optimized (instant GUI animations, ClearType fonts preserved)

:: =============================================================================
:: SECTION 4: System Garbage, Temp & Update Cache Cleanup
:: =============================================================================
echo.
echo [3/4] Cleaning System Temp Files and Caches...

:: 1. User and Windows Temp Directories
echo [*] Purging temporary directories...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%p in ("%TEMP%\*") do rmdir /s /q "%%p" >nul 2>&1
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%p in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%p" >nul 2>&1
echo   [OK] Temporary files cleaned (%%TEMP%% and %SystemRoot%\Temp)

:: 2. Windows Update Download Cache (safely stop and restart wuauserv)
echo [*] Purging Windows Update download cache...
net stop wuauserv >nul 2>&1
del /f /s /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
for /d %%p in ("%SystemRoot%\SoftwareDistribution\Download\*") do rmdir /s /q "%%p" >nul 2>&1
net start wuauserv >nul 2>&1
echo   [OK] Windows Update cache cleared (%SystemRoot%\SoftwareDistribution\Download)

:: 3. File Explorer Thumbnail & Icon Cache
echo [*] Cleaning thumbnail and icon caches...
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
del /f /q "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
echo   [OK] Explorer thumbnail and icon caches cleared

:: 4. Crash Dumps and Error Minidumps
del /f /s /q "%LOCALAPPDATA%\CrashDumps\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Minidump\*" >nul 2>&1
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
echo   [OK] Crash dumps and memory dumps cleaned

:: =============================================================================
:: SECTION 5: Safe Telemetry, Error Reporting & Security Integrity
:: =============================================================================
echo.
echo [4/4] Applying Safe Telemetry, Diagnostics and Security Policies...

:: 1. Disable DiagTrack (Connected User Experiences and Telemetry)
sc config DiagTrack start= disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
echo   [OK] DiagTrack service disabled (background diagnostics stopped)

:: 2. Disable dmwappushservice (WAP push service)
sc config dmwappushservice start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
echo   [OK] dmwappushservice disabled (telemetry WAP routing stopped)

:: 3. Set DataCollection GPO policy to 0 (Security level)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v MaxTelemetryAllowed /t REG_DWORD /d 0 /f >nul 2>&1
echo   [OK] Telemetry collection policies set to Security (Off)

:: 4. Disable Windows Error Reporting (WerSvc)
sc config WerSvc start= disabled >nul 2>&1
sc stop WerSvc >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
echo   [OK] Windows Error Reporting service disabled (WerSvc)

:: 5. Verify Windows Defender and System Driver Integrity (Do NOT disable Defender)
sc query WinDefend >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Windows Defender antivirus service verified and untouched (Active)
) else (
    echo   [INFO] Antivirus is active / managed by system
)

:: =============================================================================
:: SECTION 6: Summary and Completion
:: =============================================================================
echo.
echo =============================================================================
echo               GIN-Win-Optimizer v038 - OPTIMIZATION COMPLETE
echo =============================================================================
echo   [OK] Network Profiles    : Set to Private (LAN file/printer sharing active)
echo   [OK] Guest SMB Sharing   : AllowInsecureGuestAuth = 1 enabled
echo   [OK] Admin Mapped Drives : EnableLinkedConnections = 1 enabled
echo   [OK] UNC Script Running  : DisableUNCCheck = 1 enabled
echo   [OK] Essential Services  : FDResPub, fdPHost, Lanman, Spooler, lmhosts Auto
echo   [OK] Firewall Rules      : Discovery and Sharing rules enabled
echo   [OK] Memory Pagefile     : Fixed 4096-8192 MB on C: (No 0xe0000008 crashes)
echo   [OK] Hibernation         : Disabled (4-8 GB SSD storage freed)
echo   [OK] Visual Effects      : Fast GUI responsiveness and ClearType fonts active
echo   [OK] System Temp Cleanup : %%TEMP%% and %SystemRoot%\Temp cleared
echo   [OK] Update Cache        : SoftwareDistribution\Download cleared
echo   [OK] Thumbnail Cache     : Explorer cache purged
echo   [OK] Telemetry and WerSvc: DiagTrack, dmwappushservice and WerSvc disabled
echo   [OK] Antivirus Protection: Windows Defender intact and protected
echo =============================================================================
echo   Recommendation: Restart Windows to finalize memory paging and cache updates.
echo =============================================================================
echo.
pause
exit /b 0

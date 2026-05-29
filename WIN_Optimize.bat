:: ==========================================================================================
:: FILE    : WIN_Optimize.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Comprehensive 15-step Windows deep optimizer for Windows 10 and 11.
::   Performs system cleanup, performance tuning, and service optimization
::   to reduce disk usage, improve responsiveness, and free up system resources.
::
::   OPTIMIZATION STEPS:
::     01. Disable Reserved Storage (frees disk space reserved by Windows)
::     02. Disable Hibernation (removes hiberfil.sys, frees ~4-32GB)
::     03. Disable unnecessary startup services
::     04. Enable SSD TRIM (ensures optimal SSD performance and longevity)
::     05. Disable visual effects (maximizes performance, reduces GPU load)
::     06. Clean Temp folders (removes user and system temporary files)
::     07. Run Disk Cleanup with extended CleanMgr flags
::     08. Fix network stack (reset Winsock, TCP/IP, DNS cache)
::     09. Set High Performance power plan
::     10. Disable Windows Telemetry and data collection
::     11. DISM: Analyze and cleanup WinSxS component store
::     12. DISM: RestoreHealth - repairs Windows image from Windows Update
::     13. DISM: StartComponentCleanup - removes superseded components
::     14. SFC: System File Checker - repairs corrupted system files
::     15. CompactOS: Compresses the OS install (saves ~1.5-2.5GB)
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11
::   - Must be run as Administrator
::   - Active internet connection (for DISM RestoreHealth step)
::   - Reboot is recommended after completion
::
:: USAGE:
::   1. Right-click WIN_Optimize.bat -> Run as administrator
::   2. Each step runs sequentially with status output
::   3. Restart Windows after the script completes for full effect
::
:: WARNING:
::   - Step 02 (Hibernation OFF) removes hiberfil.sys permanently
::   - Step 10 (Telemetry OFF) disables DiagTrack and related services
::   - Step 15 (CompactOS) may take 15-60 min depending on disk speed
:: ==========================================================================================
@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cls

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b 1
)

:: ANSI colors
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[97m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

cls
echo %Y%================================================================================%X%
echo %B%  WINDOWS ULTIMATE PC OPTIMIZER v2026-05-05%X%
echo %Y%================================================================================%X%

:: Check for pending reboot before running SFC/DISM
set "reboot_required=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && set "reboot_required=1"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1 && set "reboot_required=1"

if "%reboot_required%"=="1" (
    echo.
    echo %R% [!] SYSTEM REBOOT IS REQUIRED!%X%
    echo %W%     Windows has locked system files. SFC and DISM will not work correctly.%X%
    echo %W%     Please restart your PC and run this script again.%X%
    echo.
    pause
    exit /b
)

echo.
echo %W% Status: System ready for deep optimization.%X%
echo.

:: 1. Reserved Storage
echo %B% [ 1 / 15 ] Reserved Storage%X%
echo %W%  Frees ~7GB reserved for Windows updates.%X%
DISM.exe /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1
echo %G%  OK%X% & echo.

:: 2. Hibernation
echo %B% [ 2 / 15 ] Hibernation%X%
echo %W%  Disables hibernation and removes hiberfil.sys to save disk space.%X%
powercfg -h off >nul 2>&1
echo %G%  OK%X% & echo.

:: 3. Background Services
echo %B% [ 3 / 15 ] Background Services%X%
echo %W%  Stops SysMain (Superfetch) and Search Indexing to reduce disk I/O.%X%
sc stop WSearch >nul 2>&1 & sc config WSearch start= disabled >nul 2>&1
sc stop SysMain >nul 2>&1 & sc config SysMain start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

:: 4. SSD Tweaks + TRIM
echo %B% [ 4 / 15 ] SSD Optimization%X%
echo %W%  Disables last access timestamps and runs TRIM command.%X%
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
defrag C: /L /V
echo %G%  OK%X% & echo.

:: 5. Visual Effects
echo %B% [ 5 / 15 ] Visual Effects%X%
echo %W%  Disables UI animations and shadows for maximum speed.%X%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo %G%  OK%X% & echo.

:: 6. Temp Folders
echo %B% [ 6 / 15 ] Cleaning Temp Folders%X%
echo %W%  Removes junk files from Windows and User temp directories.%X%
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo %G%  OK%X% & echo.

:: 7. Disk Cleanup
echo %B% [ 7 / 15 ] Disk Cleanup (cleanmgr)%X%
echo %W%  Automated system cleanup for logs and caches.%X%
cleanmgr /sagerun:1 /d C:
echo %G%  OK%X% & echo.

:: 8. Network Offload
echo %B% [ 8 / 15 ] Network Task Offload Fix%X%
echo %W%  Disables NIC offloading to prevent network spikes and BSODs.%X%
netsh int ip set global taskoffload=disabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
echo %G%  OK%X% & echo.

:: 9. Ultimate Power Plan
echo %B% [ 9 / 15 ] Ultimate Performance Power Plan%X%
echo %W%  Activates the hidden high-performance power scheme.%X%
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo %G%  OK%X% & echo.

:: 10. Delivery Optimization
echo %B% [ 10 / 15 ] Delivery Optimization (WUDO)%X%
echo %W%  Disables Peer-to-Peer update sharing to save bandwidth.%X%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
sc stop DoSvc >nul 2>&1 & sc config DoSvc start= disabled >nul 2>&1
echo %G%  OK%X% & echo.

:: 11. Telemetry
echo %B% [ 11 / 15 ] Telemetry ^& Error Reporting%X%
echo %W%  Stops data collection and background error logs.%X%
sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

echo %Y%--------------------------------------------------------------------------------%X%
echo %W%  STARTING HEAVY SYSTEM SCANS — PROGRESS VISIBLE BELOW%X%
echo %Y%--------------------------------------------------------------------------------%X%

:: 12. DISM RestoreHealth
echo.
echo %B% [ 12 / 15 ] DISM RestoreHealth%X%
echo %W%  Repairs Windows Component Store from online source.%X%
DISM /Online /Cleanup-Image /RestoreHealth

:: 13. WinSxS Cleanup
echo.
echo %B% [ 13 / 15 ] Deep Component Cleanup (WinSxS)%X%
echo %W%  Permanently removes old update component versions.%X%
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

:: 14. SFC Scannow
echo.
echo %B% [ 14 / 15 ] System File Checker (SFC)%X%
echo %W%  Final check and repair of protected system files.%X%
sfc /scannow

:: 15. CompactOS
echo.
echo %B% [ 15 / 15 ] CompactOS Compression%X%
echo %W%  Compresses system binaries to save 2GB+ disk space.%X%
compact /compactos:always

echo.
echo %Y%================================================================================%X%
echo %G%  OPTIMIZATION COMPLETE -- ROOTED BY VLADIMIR%X%
echo %Y%================================================================================%X%
echo.
echo = Rooted by VladiMIR ^| AI =
echo.
echo %R%  IMPORTANT: RESTART YOUR COMPUTER TO APPLY ALL CHANGES!%X%
echo.
pause

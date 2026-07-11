@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cls

rem = Rooted by VladiMIR + AI | v.2026.05.05 | github.com/GinCz =

rem Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b 1
)

rem Favorite Bright Colors Setup
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[97m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

cls
echo %Y%================================================================================%X%
echo %B%        WINDOWS ULTIMATE NEW PC OPTIMIZER              v2026-05-05%X%
echo %Y%================================================================================%X%

rem [!] CRITICAL REBOOT CHECK
set "reboot_required=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && set "reboot_required=1"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1 && set "reboot_required=1"

if "%reboot_required%"=="1" (
    echo.
    echo %R%  [!] SYSTEM REBOOT IS REQUIRED!%X%
    echo %W%  Windows has locked system files for update/repair.%X%
    echo %W%  SFC and DISM tasks will not execute properly until restart.%X%
    echo.
    pause
    exit /b
)

echo.
echo %W%  Status: System is ready for deep optimization.%X%
echo %W%  Step 15 is now Compact-OS Compression.%X%
echo.

rem 1. Reserved Storage
echo %B%  [ 1 / 15 ] Reserved Storage%X%
echo %W%  Description: Frees ~7GB of disk space reserved for Windows updates.%X%
echo %Y%  Command: DISM.exe /Online /Set-ReservedStorageState /State:Disabled%X%
DISM.exe /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1
echo %G%  OK%X% & echo.

rem 2. Hibernation
echo %B%  [ 2 / 15 ] Hibernation%X%
echo %W%  Description: Disables hibernation and removes hiberfil.sys to save disk space.%X%
echo %Y%  Command: powercfg -h off%X%
powercfg -h off >nul 2>&1
echo %G%  OK%X% & echo.

rem 3. Services
echo %B%  [ 3 / 15 ] Background Services%X%
echo %W%  Description: Stops SysMain (Superfetch) and Search Indexing to reduce disk I/O.%X%
echo %Y%  Command: sc stop WSearch ^& SysMain; sc config ... start= disabled%X%
sc stop WSearch >nul 2>&1 & sc config WSearch start= disabled >nul 2>&1
sc stop SysMain >nul 2>&1 & sc config SysMain start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

rem 4. SSD Tweaks + TRIM
echo %B%  [ 4 / 15 ] SSD Optimization%X%
echo %W%  Description: Disables last access timestamps and runs the TRIM command.%X%
echo %Y%  Command: fsutil behavior set ...; defrag C: /L /V%X%
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
defrag C: /L /V
echo %G%  OK%X% & echo.

rem 5. Visual Effects
echo %B%  [ 5 / 15 ] Visual Effects%X%
echo %W%  Description: Disables UI animations and shadows for maximum system speed.%X%
echo %Y%  Command: reg add VisualFXSetting /d 2%X%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo %G%  OK%X% & echo.

rem 6. Temp Folders
echo %B%  [ 6 / 15 ] Cleaning Temp Folders%X%
echo %W%  Description: Forcefully removes junk files from Windows and User temp directories.%X%
echo %Y%  Command: del /q /f /s "%%TEMP%%" ^& "C:\Windows\Temp"%X%
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo %G%  OK%X% & echo.

rem 7. Disk Cleanup
echo %B%  [ 7 / 15 ] Disk Cleanup (cleanmgr)%X%
echo %W%  Description: Runs automated system cleanup for logs and caches.%X%
echo %Y%  Command: cleanmgr /sagerun:1 /d C:%X%
cleanmgr /sagerun:1 /d C:
echo %G%  OK%X% & echo.

rem 8. Network Offload
echo %B%  [ 8 / 15 ] Network Task Offload Fix%X%
echo %W%  Description: Disables NIC offloading to prevent network spikes and BSODs.%X%
echo %Y%  Command: netsh int ip set global taskoffload=disabled%X%
netsh int ip set global taskoffload=disabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
echo %G%  OK%X% & echo.

rem 9. Ultimate Power Plan
echo %B%  [ 9 / 15 ] Ultimate Performance%X%
echo %W%  Description: Activates the hidden high-performance power scheme.%X%
echo %Y%  Command: powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61%X%
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo %G%  OK%X% & echo.

rem 10. Delivery Optimization
echo %B%  [ 10 / 15 ] Delivery Optimization (WUDO)%X%
echo %W%  Description: Disables Peer-to-Peer update sharing to save bandwidth.%X%
echo %Y%  Command: sc stop DoSvc; sc config DoSvc start= disabled%X%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
sc stop DoSvc >nul 2>&1 & sc config DoSvc start= disabled >nul 2>&1
echo %G%  OK%X% & echo.

rem 11. Telemetry
echo %B%  [ 11 / 15 ] Telemetry ^& Error Reporting%X%
echo %W%  Description: Stops data collection and background error logs.%X%
echo %Y%  Command: sc stop DiagTrack; reg add AllowTelemetry /d 0%X%
sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

echo %Y%--------------------------------------------------------------------------------%X%
echo %W%  STARTING HEAVY SYSTEM SCANS. PROGRESS WILL BE VISIBLE BELOW.%X%
echo %Y%--------------------------------------------------------------------------------%X%

rem 12. DISM RestoreHealth
echo.
echo %B%  [ 12 / 15 ] DISM RestoreHealth%X%
echo %W%  Description: Repairs the Windows Component Store from online source.%X%
echo %Y%  Command: DISM /Online /Cleanup-Image /RestoreHealth%X%
DISM /Online /Cleanup-Image /RestoreHealth

rem 13. WinSxS Cleanup
echo.
echo %B%  [ 13 / 15 ] Deep Component Cleanup (WinSxS)%X%
echo %W%  Description: Permanently removes old versions of update components.%X%
echo %Y%  Command: DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase%X%
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

rem 14. SFC Scannow
echo.
echo %B%  [ 14 / 15 ] System File Checker (SFC)%X%
echo %W%  Description: Final check and repair of protected system files.%X%
echo %Y%  Command: sfc /scannow%X%
sfc /scannow

rem 15. CompactOS
echo.
echo %B%  [ 15 / 15 ] CompactOS Compression%X%
echo %W%  Description: Compresses system binaries to save 2GB+ of disk space.%X%
echo %Y%  Command: compact /compactos:always%X%
compact /compactos:always

echo.
echo %Y%================================================================================%X%
echo %G%            OPTIMIZATION COMPLETE  --  ROOTED BY VLADIMIR%X%
echo %Y%================================================================================%X%
echo.
echo = Rooted by VladiMIR + AI | v.2026.05.05 | github.com/GinCz =
echo.
echo %R%  IMPORTANT: RESTART YOUR COMPUTER TO APPLY ALL CHANGES!%X%
echo.
pause

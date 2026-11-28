@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

rem = Rooted by VladiMIR + AI | v.2026.05.05 | github.com/GinCz =

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b 1
)

reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[97m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

cls
echo %Y%================================================================================%X%
echo %B%   Windows Ultimate PC Optimizer   ^|   Run as Administrator   ^|   CMD Script%X%
echo %Y%================================================================================%X%

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
echo.

echo %B%  [ 1 / 15 ] Reserved Storage%X%
echo %W%  Frees ~7GB of disk space reserved for Windows updates.%X%
DISM.exe /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 2 / 15 ] Hibernation%X%
echo %W%  Disables hibernation and removes hiberfil.sys to save disk space.%X%
powercfg -h off >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 3 / 15 ] Background Services%X%
echo %W%  Stops SysMain (Superfetch) and Search Indexing to reduce disk I/O.%X%
sc stop WSearch >nul 2>&1 & sc config WSearch start= disabled >nul 2>&1
sc stop SysMain >nul 2>&1 & sc config SysMain start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 4 / 15 ] SSD Optimization%X%
echo %W%  Disables last access timestamps and runs the TRIM command.%X%
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
defrag C: /L /V
echo %G%  OK%X% & echo.

echo %B%  [ 5 / 15 ] Visual Effects%X%
echo %W%  Disables UI animations and shadows for maximum system speed.%X%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 6 / 15 ] Cleaning Temp Folders%X%
echo %W%  Forcefully removes junk files from Windows and User temp directories.%X%
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 7 / 15 ] Disk Cleanup (cleanmgr)%X%
echo %W%  Runs automated system cleanup for logs and caches.%X%
cleanmgr /sagerun:1 /d C:
echo %G%  OK%X% & echo.

echo %B%  [ 8 / 15 ] Network Task Offload Fix%X%
echo %W%  Disables NIC offloading to prevent network spikes and BSODs.%X%
netsh int ip set global taskoffload=disabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 9 / 15 ] Ultimate Performance Power Plan%X%
echo %W%  Activates the hidden high-performance power scheme.%X%
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 10 / 15 ] Delivery Optimization (WUDO)%X%
echo %W%  Disables Peer-to-Peer update sharing to save bandwidth.%X%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
sc stop DoSvc >nul 2>&1 & sc config DoSvc start= disabled >nul 2>&1
echo %G%  OK%X% & echo.

echo %B%  [ 11 / 15 ] Telemetry ^& Error Reporting%X%
echo %W%  Stops data collection and background error logs.%X%
sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo %G%  OK%X% & echo.

echo %Y%--------------------------------------------------------------------------------%X%
echo %W%  STARTING HEAVY SYSTEM SCANS. PROGRESS WILL BE VISIBLE BELOW.%X%
echo %Y%--------------------------------------------------------------------------------%X%

echo.
echo %B%  [ 12 / 15 ] DISM RestoreHealth%X%
echo %W%  Repairs the Windows Component Store from online source.%X%
DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo %B%  [ 13 / 15 ] Deep Component Cleanup (WinSxS)%X%
echo %W%  Permanently removes old versions of update components.%X%
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

echo.
echo %B%  [ 14 / 15 ] System File Checker (SFC)%X%
echo %W%  Final check and repair of protected system files.%X%
sfc /scannow

echo.
echo %B%  [ 15 / 15 ] CompactOS Compression%X%
echo %W%  Compresses system binaries to save 2GB+ of disk space.%X%
compact /compactos:always

echo.
echo %Y%================================================================================%X%
echo %G%   OPTIMIZATION COMPLETE  --  Rooted by VladiMIR + AI | github.com/GinCz%X%
echo %Y%================================================================================%X%
echo.
echo %R%  IMPORTANT: RESTART YOUR COMPUTER TO APPLY ALL CHANGES!%X%
echo.
pause

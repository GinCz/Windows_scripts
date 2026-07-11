@echo off
cls
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==========================================================================================
:: FILE    : SMB_Connect.bat
:: VERSION : v2026.07.11
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Parallel mounting of all Samba shares for gincz.com infrastructure.
::   User: vlad / sa4434
::
::   CHANGES v2026.07.11:
::     - AWS_42 (3.79.14.42) replaced with AWS_12 (18.195.117.12)
::
::   CHANGES v2026.06.14b:
::     - Before each mount, net use X: /delete is executed — fixes the error
::       "drive already in use" on repeated runs (was the cause of [SKIP])
::     - [SKIP] now only if ping failed — server is unreachable
::     - Final table shows OK / SKIP / ERROR for each drive
::     - connection timeout increased to 8 sec, ping to 1500ms
::
::   Drives:
::     A: — AWS_12        18.195.117.12
::     E: — IONOS_38      82.223.116.38
::     I: — ILYA_176      146.103.110.176
::     N: — PILIK_33      195.63.138.33
::     O: — 4TON_237      144.124.228.237
::     Q: — SO_38         144.124.233.38
::     T: — TATRA_9       144.124.232.9
::     V: — SHAHIN_227    144.124.228.227
::     W: — STOLB_24      144.124.239.24
::     Y: — ALEX_47       109.234.38.47
:: ==========================================================================================

:: Color codes (requires ANSI support — Windows 10+ with VT enabled)
set "ESC="
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "WHITE=%ESC%[97m"

set "USER=vlad"
set "PASS=sa4434"
set "TMPDIR=%TEMP%\smb_mount"
if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo.
echo %YELLOW%=================================================================================%RESET%
echo %YELLOW%                  CONNECTING NETWORK SHARES (v.2026.07.11)                          %RESET%
echo %YELLOW%=================================================================================%RESET%
echo.

echo %YELLOW%[ STATUS ]%RESET% Saving credentials to the system...
cmdkey /add:18.195.117.12     /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:82.223.116.38     /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:146.103.110.176   /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:195.63.138.33     /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:144.124.228.237   /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:144.124.233.38    /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:144.124.232.9     /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:144.124.228.227   /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:144.124.239.24    /user:%USER% /pass:%PASS% >nul 2>&1
cmdkey /add:109.234.38.47     /user:%USER% /pass:%PASS% >nul 2>&1
echo %YELLOW%[ STATUS ]%RESET% Credentials saved.
echo %YELLOW%[ STATUS ]%RESET% Disconnecting old drives and starting parallel mount...
echo.

:: Each start /b cmd /c does:
::   1. net use DRIVE: /delete /yes  — disconnect if was connected (ignore error)
::   2. ping -n 1 -w 1500 IP         — check availability (1 packet, 1500ms timeout)
::   3. If ping OK -> net use        — mount the drive
::   4. If ping failed -> [SKIP]
::   5. Save result to %TMPDIR%\DRIVE.txt for the final table

start /b cmd /c "net use A: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 18.195.117.12 >nul 2>&1 && (net use A: \\18.195.117.12\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\A.txt\" || echo ERROR > \"%TMPDIR%\A.txt\") || echo SKIP > \"%TMPDIR%\A.txt\""

start /b cmd /c "net use E: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 82.223.116.38 >nul 2>&1 && (net use E: \\82.223.116.38\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\E.txt\" || echo ERROR > \"%TMPDIR%\E.txt\") || echo SKIP > \"%TMPDIR%\E.txt\""

start /b cmd /c "net use I: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 146.103.110.176 >nul 2>&1 && (net use I: \\146.103.110.176\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\I.txt\" || echo ERROR > \"%TMPDIR%\I.txt\") || echo SKIP > \"%TMPDIR%\I.txt\""

start /b cmd /c "net use N: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 195.63.138.33 >nul 2>&1 && (net use N: \\195.63.138.33\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\N.txt\" || echo ERROR > \"%TMPDIR%\N.txt\") || echo SKIP > \"%TMPDIR%\N.txt\""

start /b cmd /c "net use O: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.228.237 >nul 2>&1 && (net use O: \\144.124.228.237\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\O.txt\" || echo ERROR > \"%TMPDIR%\O.txt\") || echo SKIP > \"%TMPDIR%\O.txt\""

start /b cmd /c "net use Q: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.233.38 >nul 2>&1 && (net use Q: \\144.124.233.38\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\Q.txt\" || echo ERROR > \"%TMPDIR%\Q.txt\") || echo SKIP > \"%TMPDIR%\Q.txt\""

start /b cmd /c "net use T: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.232.9 >nul 2>&1 && (net use T: \\144.124.232.9\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\T.txt\" || echo ERROR > \"%TMPDIR%\T.txt\") || echo SKIP > \"%TMPDIR%\T.txt\""

start /b cmd /c "net use V: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.228.227 >nul 2>&1 && (net use V: \\144.124.228.227\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\V.txt\" || echo ERROR > \"%TMPDIR%\V.txt\") || echo SKIP > \"%TMPDIR%\V.txt\""

start /b cmd /c "net use W: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.239.24 >nul 2>&1 && (net use W: \\144.124.239.24\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\W.txt\" || echo ERROR > \"%TMPDIR%\W.txt\") || echo SKIP > \"%TMPDIR%\W.txt\""

start /b cmd /c "net use Y: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 109.234.38.47 >nul 2>&1 && (net use Y: \\109.234.38.47\vlad /user:%USER% %PASS% >nul 2>&1 && echo OK > \"%TMPDIR%\Y.txt\" || echo ERROR > \"%TMPDIR%\Y.txt\") || echo SKIP > \"%TMPDIR%\Y.txt\""

:: Wait for all background processes to finish (8 sec — buffer for slow servers)
timeout /t 8 /nobreak >nul

echo.
echo %YELLOW%=================================================================================%RESET%
echo %YELLOW%                            CONNECTION RESULTS                                         %RESET%
echo %YELLOW%=================================================================================%RESET%
echo.
echo %WHITE%  Drive  Server             IP                  Status%RESET%
echo %WHITE%  ─────────────────────────────────────────────────────────────────%RESET%

call :show_result A AWS_12      18.195.117.12
call :show_result E IONOS_38    82.223.116.38
call :show_result I ILYA_176    146.103.110.176
call :show_result N PILIK_33    195.63.138.33
call :show_result O 4TON_237    144.124.228.237
call :show_result Q SO_38       144.124.233.38
call :show_result T TATRA_9     144.124.232.9
call :show_result V SHAHIN_227  144.124.228.227
call :show_result W STOLB_24    144.124.239.24
call :show_result Y ALEX_47     109.234.38.47

echo.
echo %YELLOW%=================================================================================%RESET%
echo.

:: Clean up temporary folder
rmdir /s /q "%TMPDIR%" >nul 2>&1

pause
exit /b 0

:: ─────────────────────────────────────────────────────────────────────────────
:show_result
:: Reads result file and prints colored status line
:: Usage: call :show_result DRIVE LABEL IP
set "DRIVE=%1"
set "LABEL=%2"
set "IP=%3"
set "RESULT=WAITING"

if exist "%TMPDIR%\%DRIVE%.txt" (
    set /p RESULT=<"%TMPDIR%\%DRIVE%.txt"
    set "RESULT=!RESULT: =!"
)

if "!RESULT!"=="OK" (
    echo   %GREEN%[  OK  ]%RESET%  %DRIVE%:  %-12s%LABEL%  %IP%
) else if "!RESULT!"=="SKIP" (
    echo   %YELLOW%[SKIP   ]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(server unreachable^)
) else if "!RESULT!"=="ERROR" (
    echo   %RED%[ERROR  ]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(ping OK, SMB failed^)
) else (
    echo   %RED%[TIMEOUT]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(did not finish in 8 sec^)
)
exit /b

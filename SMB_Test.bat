@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

:: Admin check — auto-elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ANSI colors
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[36m" & set "W=%ESC%[37m" & set "G=%ESC%[32m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

cls
echo %Y%================================================================================%X%
echo %B%  NETWORK DIAGNOSTIC: LIVE SMB BENCHMARK v2026-05-05%X%
echo %Y%================================================================================%X%
echo.

:: 1. Path selection
echo %W% Select target SMB share:%X%
echo %G% [1] %X%\\p.gincz.com\soft\USER\SpeetTest_temp
echo %G% [2] %X%\\r.gincz.com\soft\user\SpeetTest_temp
echo %G% [3] %X%\\s.gincz.com\soft\user\SpeetTest_temp
echo %G% [4] %X%\\Ulps1\util\SpeetTest_temp
echo %Y% [5] %X%Enter custom network path...
echo.
set "P_CH=1"
set /p "P_CH=%B% Select [1-5, Default 1]: > %X%"

if "%P_CH%"=="1" set "F_PATH=\\p.gincz.com\soft\USER\SpeetTest_temp"
if "%P_CH%"=="2" set "F_PATH=\\r.gincz.com\soft\user\SpeetTest_temp"
if "%P_CH%"=="3" set "F_PATH=\\s.gincz.com\soft\user\SpeetTest_temp"
if "%P_CH%"=="4" set "F_PATH=\\Ulps1\util\SpeetTest_temp"
if "%P_CH%"=="5" (echo. & set /p "F_PATH=%B% Enter path: > %X%")
if "%F_PATH%"=="" set "F_PATH=\\p.gincz.com\soft\USER\SpeetTest_temp"

echo.
:: 2. Mode selection
echo %W% Select Mode:%X%
echo %G% [1] FAST %X%(50 MB)
echo %R% [2] DEEP %X%(5 GB)
echo.
set "M_CH=1"
set /p "M_CH=%B% Choose [1/2, Default 1]: > %X%"

if "%M_CH%"=="2" (
    set "B_VAL=5 GB"
    set "B_BYTES=5368709120"
) else (
    set "B_VAL=50 MB"
    set "B_BYTES=52428800"
)

cls
echo %Y%================================================================================%X%
echo %B%  MODE   : %B_VAL% TEST%X%
echo %B%  TARGET : %F_PATH%%X%
echo %Y%================================================================================%X%

set "PS_SMB=%TEMP%\smb_diag_v5.ps1"
if exist "%PS_SMB%" del "%PS_SMB%"

:: Build PowerShell script line by line
echo $E = [char]27 >> "%PS_SMB%"
echo $T = '%F_PATH%' >> "%PS_SMB%"
echo $TotalTimer = [System.Diagnostics.Stopwatch]::StartNew^() >> "%PS_SMB%"
echo try { $Root = New-Item -Path "$T\Stress_$(Get-Date -Format HHmm)" -ItemType Directory -Force -ErrorAction Stop } >> "%PS_SMB%"
echo catch { Write-Host "`n$E[31m [!] ERROR: Target path inaccessible!$E[0m"; pause; exit } >> "%PS_SMB%"
echo function Show-Prog($curr, $tot, $speed, $label) { >> "%PS_SMB%"
echo $pct = [math]::Min(100, [math]::Round(($curr / $tot) * 100)) >> "%PS_SMB%"
echo $bar = '#' * [math]::Round($pct / 2) + '-' * (50 - [math]::Round($pct / 2)) >> "%PS_SMB%"
echo Write-Host -NoNewline "`r $label [$bar] $pct%% | $speed MB/s " >> "%PS_SMB%"
echo } >> "%PS_SMB%"
echo try { >> "%PS_SMB%"
echo $L="$env:TEMP\bench.dat"; $R="$($Root.FullName)\bench.dat"; $L2="$env:TEMP\back.dat" >> "%PS_SMB%"
echo Write-Host "`n$E[36m [ 1 / 2 ] LIVE DATA TRANSFER TEST (%B_VAL%)$E[0m" >> "%PS_SMB%"
echo Write-Host " - Generating local file... " -NoNewline; $f=[System.IO.File]::Create($L); $f.SetLength(%B_BYTES%); $f.Close^(); Write-Host "$E[32mOK$E[0m" >> "%PS_SMB%"
echo $src=[System.IO.File]::OpenRead($L^); $dst=[System.IO.File]::OpenWrite($R^); $buf=New-Object byte[] 1MB; $total=0; $sw=[System.Diagnostics.Stopwatch]::StartNew^() >> "%PS_SMB%"
echo while(($read=$src.Read($buf,0,$buf.Length^)^) -gt 0^){ $dst.Write($buf,0,$read^); $total+=$read; Show-Prog $total %B_BYTES% ([math]::Round(($total/1MB)/$sw.Elapsed.TotalSeconds,2^)^) "UPLOAD %B_VAL% " } >> "%PS_SMB%"
echo $src.Close^(); $dst.Close^(); Write-Host "`n - Upload Finished" -Fore Green >> "%PS_SMB%"
echo $src=[System.IO.File]::OpenRead($R^); $dst=[System.IO.File]::OpenWrite($L2^); $total=0; $sw=[System.Diagnostics.Stopwatch]::StartNew^() >> "%PS_SMB%"
echo while(($read=$src.Read($buf,0,$buf.Length^)^) -gt 0^){ $dst.Write($buf,0,$read^); $total+=$read; Show-Prog $total %B_BYTES% ([math]::Round(($total/1MB)/$sw.Elapsed.TotalSeconds,2^)^) "DOWNLOAD %B_VAL%" } >> "%PS_SMB%"
echo $src.Close^(); $dst.Close^(); Write-Host "`n - Download Finished" -Fore Green >> "%PS_SMB%"
echo Write-Host "`n$E[36m [ 2 / 2 ] INTEGRITY ^& CLEANUP$E[0m" >> "%PS_SMB%"
echo Write-Host ' - Verifying MD5... ' -NoNewline; $h1=(Get-FileHash $L^).Hash; $h2=(Get-FileHash $L2^).Hash >> "%PS_SMB%"
echo if($h1 -eq $h2^){ Write-Host "$E[32mMATCHED$E[0m" } else { Write-Host "$E[31m[ CORRUPTION ]$E[0m"; throw 'Hash mismatch' } >> "%PS_SMB%"
echo } catch { >> "%PS_SMB%"
echo Write-Host "`n$E[31m [!] $($_.Exception.Message)$E[0m" >> "%PS_SMB%"
echo Read-Host "Press ENTER to cleanup and exit" >> "%PS_SMB%"
echo } finally { >> "%PS_SMB%"
echo Remove-Item $L, $L2, $Root -Recurse -Force -ErrorAction SilentlyContinue >> "%PS_SMB%"
echo Write-Host ' - Purging temporary files... OK' -Fore Green >> "%PS_SMB%"
echo $TotalTimer.Stop^(); Write-Host "`n$E[33m TOTAL EXECUTION TIME: $($TotalTimer.Elapsed.ToString('mm\:ss'))$E[0m" >> "%PS_SMB%"
echo } >> "%PS_SMB%"

:: Execute PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SMB%"
if exist "%PS_SMB%" del "%PS_SMB%"

echo.
echo %Y%================================================================================%X%
echo %G%  DIAGNOSTIC COMPLETE -- ROOTED BY VLADIMIR%X%
echo %Y%================================================================================%X%
echo.
echo = Rooted by VladiMIR ^| AI =
echo.
pause

@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: ULTARIX s.r.o. - Client Monitor Agent Installer (Windows 10 32-bit x86)
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.1.0 (2026-11)
:: Target  : Windows 10 Pro 32-bit (PC-09, PC-03, PC-04, PC-05...)
:: Software: STEREO (Jezek software), Ekonom.win, MS Office, Browsers
:: Server  : ULPS1 (192.168.33.128) - 0% CPU Passive Storage
:: ============================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c pushd \"\"%~dp0\"\" && \"\"%~f0\"\" admin' -Verb RunAs"
    exit /b
)

title ULTARIX - Instalace agenta monitoringu (Win10 32-bit) [PC-09]

pushd "%~dp0" 2>nul

echo ================================================================================
echo       ULTARIX s.r.o. - Tichy agent monitoringu pro Windows 10 (32-bit x86)
echo ================================================================================
echo Pocitac: %COMPUTERNAME% ^| Architektura: %PROCESSOR_ARCHITECTURE% (32-bit Win10)
echo ================================================================================
echo.

set "TARGET_DIR=%ProgramData%\UltarixMonitor"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >nul 2>&1

:: Detect server UTIL path
set "SERVER_LOGS="
if exist "\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\logs" set "SERVER_LOGS=\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\logs"
if not defined SERVER_LOGS if exist "\\ULPS1\UTIL\UltarixMonitor\logs" set "SERVER_LOGS=\\ULPS1\UTIL\UltarixMonitor\logs"
if not defined SERVER_LOGS if exist "D:\UTIL\UltarixMonitor\logs" set "SERVER_LOGS=D:\UTIL\UltarixMonitor\logs"
if not defined SERVER_LOGS if exist "E:\UTIL\UltarixMonitor\logs" set "SERVER_LOGS=E:\UTIL\UltarixMonitor\logs"
if not defined SERVER_LOGS if exist "S:\UTIL\UltarixMonitor\logs" set "SERVER_LOGS=S:\UTIL\UltarixMonitor\logs"
if not defined SERVER_LOGS if exist "\\ULPS1\ULTARIX\Monitoring" set "SERVER_LOGS=\\ULPS1\ULTARIX\Monitoring"
if not defined SERVER_LOGS set "SERVER_LOGS=\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\logs"

echo [*] Serverova slozka logu: %SERVER_LOGS%
echo [*] Generuji optimalizovany 32-bitovy skript agenta...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$code = @'" + [System.Environment]::NewLine + ^
"[CmdletBinding()]`n" + ^
"param(`n" + ^
"    [int]`$PollIntervalSec = 5,`n" + ^
"    [int]`$IdleThresholdSec = 60,`n" + ^
"    [int]`$RetentionDays = 90,`n" + ^
"    [string]`$ServerShare = '" + "%SERVER_LOGS%" + "'`n" + ^
")`n" + ^
"`$win32Code = @'`n" + ^
"using System;`n" + ^
"using System.Runtime.InteropServices;`n" + ^
"using System.Text;`n" + ^
"public class Win32x86 {`n" + ^
"    [DllImport(\"user32.dll\")]`n" + ^
"    public static extern IntPtr GetForegroundWindow();`n" + ^
"    [DllImport(\"user32.dll\", CharSet = CharSet.Auto, SetLastError = true)]`n" + ^
"    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);`n" + ^
"    [DllImport(\"user32.dll\", SetLastError = true)]`n" + ^
"    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);`n" + ^
"    [StructLayout(LayoutKind.Sequential)]`n" + ^
"    public struct LASTINPUTINFO {`n" + ^
"        public uint cbSize;`n" + ^
"        public uint dwTime;`n" + ^
"    }`n" + ^
"    [DllImport(\"user32.dll\")]`n" + ^
"    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);`n" + ^
"    public static uint GetIdleMillis() {`n" + ^
"        LASTINPUTINFO lii = new LASTINPUTINFO();`n" + ^
"        lii.cbSize = (uint)Marshal.SizeOf(lii);`n" + ^
"        if (GetLastInputInfo(ref lii)) {`n" + ^
"            uint curTick = unchecked((uint)Environment.TickCount);`n" + ^
"            return (curTick >= lii.dwTime) ? (curTick - lii.dwTime) : (curTick + (uint.MaxValue - lii.dwTime));`n" + ^
"        }`n" + ^
"        return 0;`n" + ^
"    }`n" + ^
"}`n" + ^
"'@`n" + ^
"Add-Type -TypeDefinition `$win32Code -ErrorAction SilentlyContinue`n" + ^
"`$comp = `$env:COMPUTERNAME`n" + ^
"`$user = `$env:USERNAME`n" + ^
"`$localData = \"`$env:ProgramData\UltarixMonitor\"`n" + ^
"`$localLogDir = \"`$localData\logs\`$comp\"`n" + ^
"`$null = New-Item -ItemType Directory -Path `$localLogDir -Force -ErrorAction SilentlyContinue`n" + ^
"`$remoteLogDir = \"`$ServerShare\`$comp\"`n" + ^
"function Log-Activity {`n" + ^
"    param(`$Start, `$End, `$Dur, `$Proc, `$Title, `$State)`n" + ^
"    if (`$Dur -le 0) { return }`n" + ^
"    `$dateStr = (Get-Date).ToString('yyyy-MM-dd')`n" + ^
"    `$csv = \"activity_`$dateStr.csv\"`n" + ^
"    `$locPath = \"`$localLogDir\`$csv\"`n" + ^
"    if (-not (Test-Path `$locPath)) {`n" + ^
"        'StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State' | Out-File -FilePath `$locPath -Encoding utf8`n" + ^
"    }`n" + ^
"    `$cleanTitle = `$Title -replace '\"', '\"\"'`n" + ^
"    `$line = \"`$Start,`$End,`$Dur,`$comp,`$user,`$Proc,`\"`$cleanTitle`\",`$State\"`n" + ^
"    `$line | Out-File -FilePath `$locPath -Encoding utf8 -Append`n" + ^
"    if (Test-Path `$remoteLogDir -ErrorAction SilentlyContinue) {`n" + ^
"        try {`n" + ^
"            `$remPath = \"`$remoteLogDir\`$csv\"`n" + ^
"            if (-not (Test-Path `$remPath)) {`n" + ^
"                'StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State' | Out-File -FilePath `$remPath -Encoding utf8`n" + ^
"            }`n" + ^
"            `$line | Out-File -FilePath `$remPath -Encoding utf8 -Append`n" + ^
"        } catch {}`n" + ^
"    }`n" + ^
"}`n" + ^
"function Save-Heartbeat {`n" + ^
"    param(`$Proc, `$Title, `$State, `$Dur, `$Idle)`n" + ^
"    `$hb = [PSCustomObject]@{`n" + ^
"        timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')`n" + ^
"        computer = `$comp; user = `$user; process = `$Proc; window = `$Title`n" + ^
"        state = `$State; duration_sec = `$Dur; idle_sec = `$Idle`n" + ^
"    }`n" + ^
"    `$json = `$hb | ConvertTo-Json -Compress`n" + ^
"    `$json | Set-Content -Path \"`$localData\current_status.json\" -Encoding utf8 -Force -ErrorAction SilentlyContinue`n" + ^
"    if (Test-Path `$remoteLogDir -ErrorAction SilentlyContinue) {`n" + ^
"        try { `$json | Set-Content -Path \"`$remoteLogDir\current_status.json\" -Encoding utf8 -Force -ErrorAction SilentlyContinue } catch {}`n" + ^
"    }`n" + ^
"}`n" + ^
"`$lastProc = ''; `$lastTitle = ''; `$lastState = 'ACTIVE'`n" + ^
"`$startT = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); `$dur = 0`n" + ^
"while (`$true) {`n" + ^
"    try {`n" + ^
"        if (-not (Test-Path `$remoteLogDir -ErrorAction SilentlyContinue)) {`n" + ^
"            `$null = New-Item -ItemType Directory -Path `$remoteLogDir -Force -ErrorAction SilentlyContinue`n" + ^
"        }`n" + ^
"        `$idleMs = [Win32x86]::GetIdleMillis()`n" + ^
"        `$idleSec = [math]::Floor(`$idleMs / 1000)`n" + ^
"        `$curState = if (`$idleSec -ge `$IdleThresholdSec) { 'IDLE' } else { 'ACTIVE' }`n" + ^
"        `$hWnd = [Win32x86]::GetForegroundWindow()`n" + ^
"        `$proc = 'Unknown'; `$title = ''`n" + ^
"        if (`$hWnd -ne [IntPtr]::Zero) {`n" + ^
"            `$sb = New-Object System.Text.StringBuilder 512`n" + ^
"            [void][Win32x86]::GetWindowText(`$hWnd, `$sb, `$sb.Capacity)`n" + ^
"            `$title = `$sb.ToString().Trim()`n" + ^
"            `$pidOut = 0`n" + ^
"            [void][Win32x86]::GetWindowThreadProcessId(`$hWnd, [ref]`$pidOut)`n" + ^
"            if (`$pidOut -gt 0) {`n" + ^
"                `$p = Get-Process -Id `$pidOut -ErrorAction SilentlyContinue`n" + ^
"                if (`$p) { `$proc = `$p.ProcessName }`n" + ^
"            }`n" + ^
"        }`n" + ^
"        if (`$curState -eq 'IDLE') { `$title = \"[Пауза / Бездействие - `$idleSec сек]\"; `$proc = 'IDLE_PAUSE' }`n" + ^
"        if ((`$proc -ne `$lastProc) -or (`$title -ne `$lastTitle) -or (`$curState -ne `$lastState)) {`n" + ^
"            if (`$lastProc -ne '') {`n" + ^
"                `$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')`n" + ^
"                Log-Activity -Start `$startT -End `$now -Dur `$dur -Proc `$lastProc -Title `$lastTitle -State `$lastState`n" + ^
"                `$startT = `$now; `$dur = 0`n" + ^
"            }`n" + ^
"        }`n" + ^
"        `$lastProc = `$proc; `$lastTitle = `$title; `$lastState = `$curState; `$dur += `$PollIntervalSec`n" + ^
"        Save-Heartbeat -Proc `$proc -Title `$title -State `$curState -Dur `$dur -Idle `$idleSec`n" + ^
"    } catch {}`n" + ^
"    Start-Sleep -Seconds `$PollIntervalSec`n" + ^
"}`n" + ^
"'@; Set-Content -Path '%TARGET_DIR%\agent.ps1' -Value `$code -Encoding utf8 -Force"

echo [OK] Agenta uspesne zkompilovan a pripraven pro 32-bit Win10.

:: Stop existing task
schtasks /delete /tn "UltarixMonitor" /f >nul 2>&1

:: Register scheduled task (Runs on logon, hidden, highest privileges)
schtasks /create /tn "UltarixMonitor" /tr "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TARGET_DIR%\agent.ps1\"" /sc ONLOGON /rl HIGHEST /f >nul 2>&1

:: Register in Registry Run as backup
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "UltarixMonitor" /t REG_SZ /d "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TARGET_DIR%\agent.ps1\"" /f >nul 2>&1

:: Start task right now
schtasks /run /tn "UltarixMonitor" >nul 2>&1

echo.
echo ================================================================================
echo       INSTALACE PROBEHLA USPESNE! MONITORING PRO STEREO A PC-09 BEZI.
echo ================================================================================
echo.
popd 2>nul
timeout /t 5 >nul
exit /b 0

# =============================================================================
# Execution Context : Windows PowerShell 5.1+ (Hidden Background Process)
# Target Server     : ULTARIX Office PCs (e.g., PC-09, PC-02, ULPS1 network)
# Description       : Ultarix Lightweight Employee Activity & Window Monitor Agent
# Author            : VladiMIR + Antigravity AI
# Version           : v1.0.0 (2026-11)
# =============================================================================

[CmdletBinding()]
param(
    [int]$PollIntervalSec = 5,
    [int]$IdleThresholdSec = 60,
    [int]$RetentionDays = 90,
    [string]$ServerShare = "\\ULPS1\ULTARIX\Monitoring"
)

# In-memory Win32 API Definitions
$win32Code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleTimeMillis() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(lii);
        if (GetLastInputInfo(ref lii)) {
            return (uint)Environment.TickCount - lii.dwTime;
        }
        return 0;
    }
}
"@

Add-Type -TypeDefinition $win32Code -ErrorAction SilentlyContinue

# Directory preparation
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME
$localDataDir = "$env:ProgramData\UltarixMonitor"
$localLogDir = "$localDataDir\logs\$computerName"
$null = New-Item -ItemType Directory -Path $localLogDir -Force -ErrorAction SilentlyContinue

# Remote target folder on ULPS1
$remoteLogDir = "$ServerShare\$computerName"

function Test-RemoteShare {
    param([string]$Path)
    try {
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            $null = New-Item -ItemType Directory -Path $Path -Force -ErrorAction SilentlyContinue
        }
        return $true
    } catch {
        return $false
    }
}

function Write-ActivityLog {
    param(
        [string]$StartTime,
        [string]$EndTime,
        [int]$DurationSec,
        [string]$ProcessName,
        [string]$WindowTitle,
        [string]$State
    )

    if ($DurationSec -le 0) { return }

    $dateStr = (Get-Date).ToString("yyyy-MM-dd")
    $csvFileName = "activity_$dateStr.csv"
    $localCsvPath = "$localLogDir\$csvFileName"

    # CSV Header
    if (-not (Test-Path $localCsvPath)) {
        "StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State" | Out-File -FilePath $localCsvPath -Encoding utf8
    }

    # Escape quotes
    $escTitle = $WindowTitle -replace '"', '""'
    $csvLine = "$StartTime,$EndTime,$DurationSec,$computerName,$userName,$ProcessName,`"$escTitle`",$State"
    $csvLine | Out-File -FilePath $localCsvPath -Encoding utf8 -Append

    # Replicate to central server share if online
    if (Test-Path $remoteLogDir -ErrorAction SilentlyContinue) {
        $remoteCsvPath = "$remoteLogDir\$csvFileName"
        try {
            if (-not (Test-Path $remoteCsvPath)) {
                "StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State" | Out-File -FilePath $remoteCsvPath -Encoding utf8
            }
            $csvLine | Out-File -FilePath $remoteCsvPath -Encoding utf8 -Append
        } catch {}
    }
}

function Update-Heartbeat {
    param(
        [string]$ProcessName,
        [string]$WindowTitle,
        [string]$State,
        [int]$CurrentDurationSec,
        [int]$IdleSeconds
    )

    $hb = [PSCustomObject]@{
        timestamp          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        computer           = $computerName
        user               = $userName
        process            = $ProcessName
        window_title       = $WindowTitle
        state              = $State
        duration_sec       = $CurrentDurationSec
        idle_sec           = $IdleSeconds
        agent_version      = "v1.0.0"
    }

    $json = $hb | ConvertTo-Json -Compress
    
    # Write local
    $json | Set-Content -Path "$localDataDir\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue

    # Write remote for PC-02 real-time viewing
    if (Test-Path $remoteLogDir -ErrorAction SilentlyContinue) {
        try {
            $json | Set-Content -Path "$remoteLogDir\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

# Cleanup older logs beyond retention threshold
function Cleanup-OldLogs {
    $cutoff = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $localLogDir -Filter "activity_*.csv" -ErrorAction SilentlyContinue | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | Remove-Item -Force -ErrorAction SilentlyContinue

    if (Test-Path $remoteLogDir -ErrorAction SilentlyContinue) {
        Get-ChildItem -Path $remoteLogDir -Filter "activity_*.csv" -ErrorAction SilentlyContinue | Where-Object {
            $_.LastWriteTime -lt $cutoff
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# State Tracking Variables
$lastProcess = ""
$lastTitle = ""
$lastState = "ACTIVE"
$intervalStartTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$currentDuration = 0
$lastCleanupHour = -1

# Main Infinite Monitoring Loop
while ($true) {
    try {
        # Check remote connection
        $hasRemote = Test-RemoteShare -Path $remoteLogDir

        # Determine Idle Status
        $idleMs = [Win32]::GetIdleTimeMillis()
        $idleSec = [math]::Floor($idleMs / 1000)

        $currentState = if ($idleSec -ge $IdleThresholdSec) { "IDLE" } else { "ACTIVE" }

        # Determine Foreground Window & Process
        $hWnd = [Win32]::GetForegroundWindow()
        $procName = "Unknown"
        $winTitle = ""

        if ($hWnd -ne [IntPtr]::Zero) {
            $sb = New-Object System.Text.StringBuilder 512
            [void][Win32]::GetWindowText($hWnd, $sb, $sb.Capacity)
            $winTitle = $sb.ToString().Trim()

            $pidOut = 0
            [void][Win32]::GetWindowThreadProcessId($hWnd, [ref]$pidOut)
            if ($pidOut -gt 0) {
                $p = Get-Process -Id $pidOut -ErrorAction SilentlyContinue
                if ($p) {
                    $procName = $p.ProcessName
                }
            }
        }

        if ($currentState -eq "IDLE") {
            $winTitle = "[Пауза / Бездействие - $idleSec сек]"
            $procName = "IDLE_PAUSE"
        }

        # Check if activity changed (window switched, or entered/left idle)
        $hasChanged = ($procName -ne $lastProcess) -or ($winTitle -ne $lastTitle) -or ($currentState -ne $lastState)

        if ($hasChanged -and $lastProcess -ne "") {
            $nowStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Write-ActivityLog -StartTime $intervalStartTime -EndTime $nowStr -DurationSec $currentDuration -ProcessName $lastProcess -WindowTitle $lastTitle -State $lastState

            # Reset interval
            $intervalStartTime = $nowStr
            $currentDuration = 0
        }

        # Update last known state
        $lastProcess = $procName
        $lastTitle = $winTitle
        $lastState = $currentState
        $currentDuration += $PollIntervalSec

        # Update Heartbeat
        Update-Heartbeat -ProcessName $procName -WindowTitle $winTitle -State $currentState -CurrentDurationSec $currentDuration -IdleSeconds $idleSec

        # Daily log purge check
        $curHour = (Get-Date).Hour
        if ($curHour -ne $lastCleanupHour) {
            Cleanup-OldLogs
            $lastCleanupHour = $curHour
        }

    } catch {
        # Silent recovery from any Win32 or disk lock error
    }

    Start-Sleep -Seconds $PollIntervalSec
}

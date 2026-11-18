# ULTARIX Activity Monitor & Executive Audit System

Lightweight, private, zero-dependency background activity and window tracking suite for ULTARIX s.r.o. office workstations (Windows 10/11).

## Architecture & Data Flow

```
+-------------------------------------------------------------+
| PC-09 (Monitored Workstation)                               |
|   - Ultarix_Agent.ps1 (Runs silently via Scheduled Task)    |
|   - Samples every 5s: Active Window + AFK/Idle Detection    |
|   - Writes local cache: %ProgramData%\UltarixMonitor\logs\  |
|   - Syncs real-time to \\ULPS1\ULTARIX\Monitoring\PC-09\    |
+-------------------------------------------------------------+
                              |
                              v (Local SMB Share / Network)
+-------------------------------------------------------------+
| Central Server ULPS1 (192.168.33.128)                       |
|   - \\ULPS1\ULTARIX\Monitoring\PC-09\activity_YYYY-MM-DD.csv|
|   - \\ULPS1\ULTARIX\Monitoring\PC-09\current_status.json    |
+-------------------------------------------------------------+
                              |
                              v (On-demand inspection)
+-------------------------------------------------------------+
| PC-02 (Director Ulyana's Workstation)                       |
|   - Check_PC09_Activity.cmd -> Get_Ultarix_Report.ps1       |
|   - Real-time live status: current program & AFK duration   |
|   - 60-day historical audit, Top 10 apps, pause analytics  |
|   - Interactive HTML Executive Dashboard                    |
+-------------------------------------------------------------+
```

## Features
- **Zero Third-Party Dependencies:** 100% native Windows PowerShell and Win32 APIs (`user32.dll` `GetForegroundWindow`, `GetWindowText`, `GetLastInputInfo`).
- **Resource Footprint:** Consumes less than 15 MB RAM, 0% CPU impact.
- **AFK / Idle Detection:** Accurately distinguishes active keyboard/mouse work from idle pauses (default threshold: 60 seconds).
- **60-90 Days Retention:** Daily structured CSV logs and automatic rolling purge of files older than 90 days.
- **Offline Resilient:** If server ULPS1 is temporarily unavailable, logs are queued locally on PC-09 and pushed automatically upon reconnection.
- **Turnkey Reporting:** 1-click execution for Director Ulyana on PC-02 to view daily breakdown, application time percentages, and open an interactive visual HTML dashboard.

## Deployment Steps

### 1. On PC-09 (Monitored Employee PC):
Run as Administrator:
```cmd
Install_Ultarix_Agent.cmd
```
This registers the scheduled task `UltarixMonitor` running hidden at logon.

### 2. On PC-02 (Director Ulyana's PC):
Double-click:
```cmd
Check_PC09_Activity.cmd
```
Or run from PowerShell:
```powershell
.\Get_Ultarix_Report.ps1 -TargetComputer "PC-09" -Days 60 -OpenReport
```

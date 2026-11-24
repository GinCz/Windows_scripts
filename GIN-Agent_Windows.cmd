<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent v036

:: Parse all arguments robustly across %1, %2, %3, %4
set "GIN_ARG1=%~1"
set "GIN_ARG2=%~2"
set "GIN_ARG3=%~3"

:: Detect silent mode
if /i "%GIN_ARG1%"=="/silent" set "GIN_AGENT_SILENT=1"
if /i "%GIN_ARG2%"=="/silent" set "GIN_AGENT_SILENT=1"
if /i "%GIN_ARG3%"=="/silent" set "GIN_AGENT_SILENT=1"
if /i "%GIN_ARG1%"=="/update" set "GIN_AGENT_SILENT=1"
if /i "%GIN_ARG2%"=="/update" set "GIN_AGENT_SILENT=1"
if /i "%GIN_ARG3%"=="/update" set "GIN_AGENT_SILENT=1"

:: Detect region parameter
if /i "%GIN_ARG1%"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%GIN_ARG1%"=="RU" set "GIN_AGENT_REGION=RU"
if /i "%GIN_ARG2%"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%GIN_ARG2%"=="RU" set "GIN_AGENT_REGION=RU"
if /i "%GIN_ARG3%"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%GIN_ARG3%"=="RU" set "GIN_AGENT_REGION=RU"

if /i "%GIN_ARG1%"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%GIN_ARG1%"=="EU" set "GIN_AGENT_REGION=EU"
if /i "%GIN_ARG2%"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%GIN_ARG2%"=="EU" set "GIN_AGENT_REGION=EU"
if /i "%GIN_ARG3%"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%GIN_ARG3%"=="EU" set "GIN_AGENT_REGION=EU"

:: Mode routing
if /i "%GIN_ARG1%"=="/uninstall" goto :RUN_UNINSTALL
if /i "%GIN_ARG1%"=="--uninstall" goto :RUN_UNINSTALL
if /i "%GIN_ARG1%"=="/checkupdate" goto :RUN_CHECKUPDATE
if /i "%GIN_ARG1%"=="--checkupdate" goto :RUN_CHECKUPDATE

:: Note: If /silent is passed (auto-updater invocation),
:: we MUST run the installer first to perform the complete deep cleanup and file update!
if defined GIN_AGENT_SILENT (
    goto :RUN_INSTALLER
)

if /i "%GIN_ARG1%"=="/service" goto :RUN_SERVICE
if /i "%GIN_ARG1%"=="--service" goto :RUN_SERVICE

:: 1. Resilient Elevation Check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_INSTALLER

if not defined GIN_AGENT_ELEVATED (
    set GIN_AGENT_ELEVATED=1
    if defined GIN_AGENT_REGION (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList '%GIN_AGENT_REGION%' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    ) else (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    )
    if not errorlevel 1 exit /b 0
)

:RUN_INSTALLER
set "GIN_AGENT_MODE=INSTALL"
goto :EXEC_PS

:RUN_SERVICE
set "GIN_AGENT_MODE=SERVICE"
goto :EXEC_PS

:RUN_CHECKUPDATE
set "GIN_AGENT_MODE=CHECKUPDATE"
goto :EXEC_PS

:RUN_UNINSTALL
set "GIN_AGENT_MODE=UNINSTALL"
goto :EXEC_PS

:EXEC_PS
set "GIN_AGENT_SCRIPT=%~f0"

set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) else if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"
set "PS_ERR=%errorlevel%"

if "%GIN_AGENT_MODE%"=="INSTALL" (
    if not defined GIN_AGENT_SILENT (
        if %PS_ERR% neq 0 (
            echo.
            echo ====================================================================
            echo [ERROR] GIN-Agent execution halted with error code: %PS_ERR%
            echo ====================================================================
            echo.
            pause
        )
    )
)

exit /b %PS_ERR%
#>
# ==============================================================================
# GIN-Agent Windows Service v036 (Single File CMD Hybrid)
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Permanent Background Windows Service (Auto-Start, Watchdog Recovery, No Console Window)
# Primary Identifier: 9-Digit Hardware GIN-PIN
# Supported Platforms: Windows 10 (32-bit & 64-bit), Windows 11 (64-bit / ARM64)
# Regional Gateways:
#   - Europe: Server_222 (152.53.182.222:9876), Global (remote.gincz.com)
#   - Russia: Server_109 (212.109.223.109), RU-FastNode (195.158.255.208)
# Key v036 Fixes:
#   1. Universal 3-Tier Multi-Source Auto-Update: Tier 1 GitHub -> Tier 2 Server 222 (EU) -> Tier 3 Server 109 (RU)
#   2. Ultra-Fast Resilient Timeout: max 5s version check per tier, 15s payload download
#   3. Fully agnostic roaming support (Europe / Russia / Global)
#   1. Guaranteed Remote Desktop (RDP) & TermService Enablement on Install and Auto-Update
#   2. Fixed PowerShell syntax error in RDP policy registry configuration
#   3. Start and enable TermService & UmRdpService automatic startup
#   4. Multi-language Windows Firewall open for TCP/UDP Port 3389 and Remote Desktop
#   5. Allow local blank passwords (LimitBlankPasswordUse=0) & disable NLA requirement (UserAuthentication=0)
# Key v033 Fixes:
#   0. 100% Pre-Install & Pre-Update Autostart & Registry Deep Purge (Purges all duplicate PowerShell autostart scripts, Run keys and ghost tasks)
# Key v032 Fixes:
#   1. Clean Regex Tokenization: Escaped hexadecimal ASCII hex ["\x27] for RustDesk ID matching
#   2. Guaranteed Dual KeepAlive Heartbeat: Direct loop ping every ~25s + global-scoped background timer
#   3. Corrected Variable Scope in Timer & Heartbeat (100% valid PIN & RustDesk ID delivery)
#   4. Clean Process Killer: Kills all previous GIN-Agent instances unconditionally so mutex is released
#   5. Battery & 72h Timeout Hardening: Task Scheduler settings updated to prevent auto-kill on battery
# ==============================================================================

try {
    $ErrorActionPreference = "Continue"

    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $OutputEncoding = [System.Text.Encoding]::UTF8
    } catch {}

    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {}

    $installDir = "$env:ProgramFiles\GIN-Agent"
    $targetCmd = "$installDir\GIN-Agent.cmd"
    $targetCmdVer = "$installDir\GIN-Agent_Windows_v036.cmd"
    $uninstallerCmd = "$installDir\uninstall.cmd"
    $serviceName = "GIN-Agent"
    $serviceDisplayName = "GIN-Agent Remote Support Service"
    $serviceDesc = "Provides resilient background diagnostic connection, auto-updates and RDP shadow support for Vladimir Bulantsev (GinCz)."

    $mode = $env:GIN_AGENT_MODE
    if (-not $mode) {
        if ($env:GIN_AGENT_SCRIPT -and ($env:GIN_AGENT_SCRIPT.ToLower().Contains("program files") -or $env:GIN_AGENT_SCRIPT.ToLower().Contains("programdata"))) {
            $mode = "SERVICE"
        } else {
            $mode = "INSTALL"
        }
    }

    # ==========================================================================
    # FUNCTION: Enable Remote Desktop (RDP), TermService, Firewall & Policies
    # ==========================================================================
    function Enable-RemoteDesktopSupport {
        try {
            # 1. Enable RDP in System & Terminal Server Registry
            $tsPath = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
            if (-not (Test-Path $tsPath)) { New-Item -Path $tsPath -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $tsPath -Name "fDenyTSConnections" -Value 0 -Force -ErrorAction SilentlyContinue

            $rdpTcp = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
            if (-not (Test-Path $rdpTcp)) { New-Item -Path $rdpTcp -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $rdpTcp -Name "UserAuthentication" -Value 0 -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $rdpTcp -Name "SecurityLayer" -Value 1 -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $rdpTcp -Name "PortNumber" -Value 3389 -Force -ErrorAction SilentlyContinue

            # 2. Terminal Services Policies (Overrides GPO restrictions, enables Shadow Full Control)
            $tsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            if (-not (Test-Path $tsPolicy)) { New-Item -Path $tsPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $tsPolicy -Name "fDenyTSConnections" -Value 0 -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $tsPolicy -Name "fAllowToGetHelp" -Value 1 -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $tsPolicy -Name "Shadow" -Value 2 -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $tsPolicy -Name "MaxInstanceCount" -Value 999999 -Force -ErrorAction SilentlyContinue

            # 3. Remote Assistance & Blank Password Allowance for local accounts
            $raPath = 'HKLM:\System\CurrentControlSet\Control\Remote Assistance'
            if (-not (Test-Path $raPath)) { New-Item -Path $raPath -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $raPath -Name "fAllowToGetHelp" -Value 1 -Force -ErrorAction SilentlyContinue

            $lsaPath = 'HKLM:\System\CurrentControlSet\Control\Lsa'
            if (Test-Path $lsaPath) {
                $null = Set-ItemProperty -Path $lsaPath -Name "LimitBlankPasswordUse" -Value 0 -Force -ErrorAction SilentlyContinue
            }

            # 4. Windows Services: TermService (Remote Desktop) & UmRdpService
            try {
                Set-Service -Name "TermService" -StartupType Automatic -ErrorAction SilentlyContinue
                $svc = Get-Service -Name "TermService" -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -ne "Running") {
                    Start-Service -Name "TermService" -ErrorAction SilentlyContinue
                }
            } catch {}
            try {
                Set-Service -Name "UmRdpService" -StartupType Automatic -ErrorAction SilentlyContinue
                $uSvc = Get-Service -Name "UmRdpService" -ErrorAction SilentlyContinue
                if ($uSvc -and $uSvc.Status -ne "Running") {
                    Start-Service -Name "UmRdpService" -ErrorAction SilentlyContinue
                }
            } catch {}

            # Native service configuration fallback
            try {
                & sc.exe config TermService start= auto >$null 2>&1
                & net.exe start TermService >$null 2>&1
                & sc.exe config UmRdpService start= auto >$null 2>&1
                & net.exe start UmRdpService >$null 2>&1
            } catch {}

            # 5. Windows Firewall Rules: Built-in, Localized, and Custom Port 3389 Rules
            try {
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Out-Null
                Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -ErrorAction SilentlyContinue | Out-Null
                Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP" -ErrorAction SilentlyContinue | Out-Null
                Enable-NetFirewallRule -Name "RemoteDesktop-Shadow-In-TCP" -ErrorAction SilentlyContinue | Out-Null
            } catch {}

            try {
                & netsh.exe advfirewall firewall set rule group="remote desktop" new enable=Yes >$null 2>&1
                & netsh.exe advfirewall firewall set rule group="vzdálená plocha" new enable=Yes >$null 2>&1
                & netsh.exe advfirewall firewall set rule group="дистанционное управление рабочим столом" new enable=Yes >$null 2>&1
                & netsh.exe advfirewall firewall set rule group="@FirewallAPI.dll,-28752" new enable=Yes >$null 2>&1
                & netsh.exe advfirewall firewall add rule name="GIN-Agent-RDP-TCP" dir=in action=allow protocol=TCP localport=3389 >$null 2>&1
                & netsh.exe advfirewall firewall add rule name="GIN-Agent-RDP-UDP" dir=in action=allow protocol=UDP localport=3389 >$null 2>&1
            } catch {}
        } catch {}
    }

    # ==========================================================================
    # DEEP SYSTEM PURGE FUNCTION (Zero-Clutter Standard: Auto-start, Tasks, Svc)
    # ==========================================================================
    function Invoke-GINAgentDeepCleanup {
        param([switch]$FullUninstall = $false)

        if (-not ($env:GIN_AGENT_SILENT -eq "1")) {
            Write-Host "[*] Executing deep purge of previous services, tasks, processes and autostart..." -ForegroundColor Cyan
        }

        # 1. Stop and remove all legacy Windows Services (sc.exe)
        $servicesToKill = @("GIN-Agent", "GIN-Agent-Service", "GIN_Agent")
        foreach ($s in $servicesToKill) {
            try { & sc.exe stop $s 2>&1 | Out-Null } catch {}
            try { & sc.exe delete $s 2>&1 | Out-Null } catch {}
        }
        try {
            Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -like "*GIN*Agent*" -or $_.DisplayName -like "*GIN*Agent*"
            } | ForEach-Object {
                try { & sc.exe stop $_.Name 2>&1 | Out-Null } catch {}
                try { & sc.exe delete $_.Name 2>&1 | Out-Null } catch {}
            }
        } catch {}

        # 2. Stop and remove all running scheduled task instances
        $tasksToKill = @("GIN-Agent-Service", "GIN-Agent-Update-Logon", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
        foreach ($ot in $tasksToKill) {
            try { schtasks.exe /end /tn "$ot" 2>&1 | Out-Null } catch {}
            try { schtasks.exe /delete /tn "$ot" /f 2>&1 | Out-Null } catch {}
        }
        try {
            Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $_.TaskName -like "*GIN*Agent*" -or $_.TaskPath -like "*GIN*Agent*"
            } | ForEach-Object {
                try { schtasks.exe /end /tn "$($_.TaskName)" 2>&1 | Out-Null } catch {}
                try { schtasks.exe /delete /tn "$($_.TaskName)" /f 2>&1 | Out-Null } catch {}
            }
        } catch {}

        # 3. Terminate running background agent processes safely (release Global Mutex)
        $currentPid = $PID
        $parentPid = 0
        try {
            $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
            if ($parentProc) { $parentPid = $parentProc.ParentProcessId }
        } catch {}

        try {
            Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' or Name = 'cmd.exe' or Name = 'pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                    $_.CommandLine -like "*GIN-Agent*" -or
                    $_.CommandLine -like "*agent-api*"
                )
            } | ForEach-Object {
                try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
            }
        } catch {}
        try {
            Get-Process -Name "GIN-Agent*" -ErrorAction SilentlyContinue | Where-Object {
                $_.Id -ne $currentPid -and $_.Id -ne $parentPid
            } | Stop-Process -Force -ErrorAction SilentlyContinue
        } catch {}

        Start-Sleep -Milliseconds 600

        # 4. Aggressively purge all duplicate/ghost Autostart items from Registry Run & RunOnce
        $runKeyPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        try {
            Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | Where-Object {
                $_.PSChildName -notmatch '_Classes$' -and $_.PSChildName -ne '.DEFAULT'
            } | ForEach-Object {
                $runKeyPaths += "Registry::HKEY_USERS\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Run"
                $runKeyPaths += "Registry::HKEY_USERS\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\RunOnce"
            }
        } catch {}

        foreach ($rk in $runKeyPaths) {
            if (Test-Path $rk) {
                try {
                    $item = Get-Item -Path $rk -ErrorAction SilentlyContinue
                    if ($item) {
                        foreach ($prop in $item.Property) {
                            $val = ($item.GetValue($prop) | Out-String).Trim()
                            $isMatch = $false
                            if ($prop -match '(?i)(GIN-Agent|GIN_Agent|NeverCombine|FolderView|UltarixMonitor)') {
                                $isMatch = $true
                            } elseif ($val -match '(?i)(GIN-Agent|GIN_Agent|agent-api|NeverCombineTaskbar|FolderViewListSortType)') {
                                $isMatch = $true
                            } elseif ($val -match '(?i)powershell\.exe' -and $val -match '(?i)(GIN|NeverCombine|FolderView)') {
                                $isMatch = $true
                            }
                            if ($isMatch) {
                                try { Remove-ItemProperty -Path $rk -Name $prop -Force -ErrorAction SilentlyContinue } catch {}
                            }
                        }
                    }
                } catch {}
            }
        }

        # 5. Clean StartupApproved registry keys
        $approvedPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        )
        foreach ($ap in $approvedPaths) {
            if (Test-Path $ap) {
                try {
                    $item = Get-Item -Path $ap -ErrorAction SilentlyContinue
                    if ($item) {
                        foreach ($prop in $item.Property) {
                            if ($prop -match '(?i)(GIN-Agent|GIN_Agent|NeverCombine|FolderView|UltarixMonitor)') {
                                try { Remove-ItemProperty -Path $ap -Name $prop -Force -ErrorAction SilentlyContinue } catch {}
                            }
                        }
                    }
                } catch {}
            }
        }

        # 6. Aggressively purge all files and shortcuts from Startup folders
        $startupFolders = @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\StartUp",
            "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$([Environment]::GetFolderPath('Startup'))"
        )
        try {
            Get-ChildItem -Path "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $uStartup = "$($_.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
                if (Test-Path $uStartup) { $startupFolders += $uStartup }
            }
        } catch {}

        $wscriptShell = $null
        try { $wscriptShell = New-Object -ComObject WScript.Shell } catch {}

        foreach ($sf in ($startupFolders | Select-Object -Unique)) {
            if (Test-Path $sf) {
                try {
                    Get-ChildItem -Path $sf -Force -ErrorAction SilentlyContinue | ForEach-Object {
                        $f = $_
                        $shouldDelete = $false
                        $fn = $f.Name
                        if ($fn -match '(?i)(GIN-Agent|GIN_Agent|NeverCombine|FolderView|UltarixMonitor|CLEAN\.lnk)') {
                            $shouldDelete = $true
                        } elseif ($f.Extension -eq ".ps1") {
                            $shouldDelete = $true
                        } elseif ($f.Extension -eq ".lnk" -and $wscriptShell) {
                            try {
                                $sc = $wscriptShell.CreateShortcut($f.FullName)
                                $target = ($sc.TargetPath | Out-String).Trim()
                                $args = ($sc.Arguments | Out-String).Trim()
                                if ($target -match '(?i)powershell' -and ($args -match '(?i)(GIN|Agent|NeverCombine|FolderView)' -or -not $args)) {
                                    $shouldDelete = $true
                                } elseif ($target -match '(?i)(GIN-Agent|GIN_Agent)' -or $args -match '(?i)(GIN-Agent|GIN_Agent)') {
                                    $shouldDelete = $true
                                } elseif ($target -and -not (Test-Path $target)) {
                                    if ($target -match '(?i)(GIN|Agent|powershell)') {
                                        $shouldDelete = $true
                                    }
                                }
                            } catch {}
                        } elseif ($f.Extension -in @(".cmd", ".bat", ".vbs")) {
                            try {
                                $content = Get-Content -Path $f.FullName -Raw -ErrorAction SilentlyContinue
                                if ($content -match '(?i)(GIN-Agent|GIN_Agent|agent-api|NeverCombineTaskbar)') {
                                    $shouldDelete = $true
                                }
                            } catch {}
                        }
                        if ($shouldDelete) {
                            try {
                                $f.IsReadOnly = $false
                                Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
                            } catch {}
                        }
                    }
                } catch {}
            }
        }

        # 7. Clean legacy ProgramData folder
        $legacyDir = "$env:ProgramData\GIN-Agent"
        if (Test-Path $legacyDir) {
            try {
                Get-ChildItem -Path $legacyDir -File -ErrorAction SilentlyContinue | ForEach-Object {
                    try { $_.IsReadOnly = $false; Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
                }
                Remove-Item -Path $legacyDir -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }

        # 8. Clean old versions & artifacts inside Program Files\GIN-Agent
        $instDir = "$env:ProgramFiles\GIN-Agent"
        if (Test-Path $instDir) {
            try {
                Get-ChildItem -Path $instDir -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $fname = $_.Name
                    if ($FullUninstall) {
                        try { $_.IsReadOnly = $false; Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
                    } else {
                        if ($fname -match '(?i)^GIN-Agent_Windows_v\d{3}\.(cmd|zip)$' -or
                            $fname -match '(?i)^GIN-Agent.*\.bak' -or
                            $fname -match '(?i)\.tmp$' -or
                            $fname -match '(?i)\.old$' -or
                            $fname -match '(?i)^GIN-Agent.*\.exe$') {
                            try { $_.IsReadOnly = $false; Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
                        }
                    }
                }
            } catch {}
        }

        # 9. If FullUninstall requested, purge registry keys too
        if ($FullUninstall) {
            $regPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent",
                "HKLM:\SOFTWARE\GIN-Agent",
                "HKCU:\Software\GIN-Agent",
                "HKLM:\SOFTWARE\WOW6432Node\GIN-Agent",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent"
            )
            foreach ($rp in $regPaths) {
                if (Test-Path $rp) {
                    try { Remove-Item -Path $rp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                }
            }
        }

        # 10. Purge temp update files
        try {
            Get-ChildItem -Path $env:TEMP -Filter "*GIN-Agent*" -Force -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.FullName -ne $MyInvocation.MyCommand.Path) {
                    try { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                }
            }
        } catch {}
    }

    # Universal 3-Tier Multi-Source Auto-Update
    function Check-GINAgentUpdate {
        param([string]$currentVer = "v036", [string]$activeRegion = "EU")
        try {
            # Structured sources: Tier 1 GitHub -> Tier 2 Server 222 (EU) -> Tier 3 Server 109 (RU)
            $updateSources = @(
                @{
                    Name = "GitHub (Cloud Primary)"
                    VersionUrls = @("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/version.txt")
                    DownloadUrls = @("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Agent_Windows.cmd")
                },
                @{
                    Name = "Server 222 (Europe NetCup DE)"
                    VersionUrls = @(
                        "http://152.53.182.222:9876/version.txt",
                        "https://remote.gincz.com/agent-api/version.txt"
                    )
                    DownloadUrls = @(
                        "http://152.53.182.222:9876/GIN-Agent_Windows.cmd",
                        "https://remote.gincz.com/agent-api/GIN-Agent_Windows.cmd"
                    )
                },
                @{
                    Name = "Server 109 (Russia FirstVDS RU)"
                    VersionUrls = @(
                        "http://212.109.223.109/agent/version.txt",
                        "https://rd.gincz.com/agent/version.txt"
                    )
                    DownloadUrls = @(
                        "http://212.109.223.109/agent/GIN-Agent_Windows.cmd",
                        "https://rd.gincz.com/agent/GIN-Agent_Windows.cmd"
                    )
                }
            )

            $remoteVer = ""
            $winnerTier = $null

            # Fast version probe: max 5 seconds per URL in strict priority order (GitHub -> 222 -> 109)
            foreach ($src in $updateSources) {
                foreach ($vu in $src.VersionUrls) {
                    try {
                        $rawV = (Invoke-RestMethod -Uri $vu -TimeoutSec 5 -ErrorAction Stop).Trim()
                        if ($rawV -match '^v\d{3}$') {
                            $remoteVer = $rawV
                            $winnerTier = $src
                            break
                        }
                    } catch {}
                }
                if ($remoteVer) { break }
            }

            if ($remoteVer -and ($remoteVer -gt $currentVer)) {
                $tempUpdateFile = "$env:TEMP\GIN-Agent_Update_$remoteVer.cmd"

                # Build ordered download queue: winning tier first, then remaining tiers
                $downloadQueue = @()
                if ($winnerTier) {
                    foreach ($du in $winnerTier.DownloadUrls) { $downloadQueue += $du }
                }
                foreach ($src in $updateSources) {
                    if ($src -ne $winnerTier) {
                        foreach ($du in $src.DownloadUrls) { $downloadQueue += $du }
                    }
                }

                # Download with 15s timeout
                foreach ($du in $downloadQueue) {
                    try {
                        Invoke-WebRequest -Uri $du -OutFile $tempUpdateFile -TimeoutSec 15 -ErrorAction Stop
                        if ((Test-Path $tempUpdateFile) -and ((Get-Item $tempUpdateFile).Length -gt 15000)) {
                            $sample = Get-Content -Path $tempUpdateFile -TotalCount 30 -Raw
                            if ($sample -like "*GIN-Agent*") {
                                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"`"$tempUpdateFile`" /silent /service $activeRegion`"" -WindowStyle Hidden
                                exit 0
                            }
                        }
                    } catch {}
                }
            }
        } catch {}
    }

    # ==========================================================================
    # MODE 1.5: STANDALONE UPDATE CHECK (/checkupdate - Scheduled on logon +30m)
    # ==========================================================================
    if ($mode -eq "CHECKUPDATE") {
        $reg = $env:GIN_AGENT_REGION
        if (-not $reg) {
            $regFile = "$installDir\region.txt"
            if (Test-Path $regFile) {
                try { $reg = (Get-Content $regFile -Raw).Trim() } catch {}
            }
        }
        if (-not $reg -or ($reg -ne "RU" -and $reg -ne "EU")) { $reg = "EU" }
        Check-GINAgentUpdate -currentVer "v036" -activeRegion $reg
        [System.Environment]::Exit(0)
    }

    # ==========================================================================
    # MODE 0: UNINSTALLATION
    # ==========================================================================
    if ($mode -eq "UNINSTALL") {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Red
        Write-Host "           GIN-AGENT - COMPLETE SYSTEM UNINSTALLATION               " -ForegroundColor Yellow
        Write-Host "====================================================================" -ForegroundColor Red
        Invoke-GINAgentDeepCleanup -FullUninstall

        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) { $scriptPath = "$installDir\GIN-Agent.cmd" }
        $parentFolder = Split-Path -Parent $scriptPath

        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host "  [OK] GIN-AGENT HAS BEEN COMPLETELY AND CLEANLY REMOVED!           " -ForegroundColor Green
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host ""

        if ($parentFolder -and (Test-Path $parentFolder)) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c ping 127.0.0.1 -n 3 >nul & rd /s /q `"`"$parentFolder`"`"" -WindowStyle Hidden
        }

        Start-Sleep -Seconds 2
        exit 0
    }

    # ==========================================================================
    # MODE 1: INSTALLER (Interactive / Silent Deployment)
    # ==========================================================================
    if ($mode -ne "SERVICE") {
        $isSilent = ($env:GIN_AGENT_SILENT -eq "1")

        if (-not $isSilent) {
            Write-Host ""
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "         GIN-AGENT v036 - REGION / GATEWAY SELECTION               " -ForegroundColor Cyan
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "  [1] Europe (Server_222 / Global)   [Default in 5 sec]" -ForegroundColor Green
            Write-Host "  [2] Russia  (Server 109 FirstVDS)" -ForegroundColor Yellow
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
        }

        $selectedRegion = $env:GIN_AGENT_REGION
        if (-not $selectedRegion) {
            $regFilePrev = "$installDir\region.txt"
            $oldRegFile = "$env:ProgramData\GIN-Agent\region.txt"
            if (Test-Path $regFilePrev) {
                try { $selectedRegion = (Get-Content -Path $regFilePrev -Raw -ErrorAction SilentlyContinue).Trim() } catch {}
            } elseif (Test-Path $oldRegFile) {
                try { $selectedRegion = (Get-Content -Path $oldRegFile -Raw -ErrorAction SilentlyContinue).Trim() } catch {}
            }
        }

        if (-not $selectedRegion -and -not $isSilent) {
            $selectedRegion = "EU"
            $secondsLeft = 1
            try {
                while ($secondsLeft -gt 0) {
                    Write-Host -NoNewline "`r[*] Select region [1/2] (default [1] in $secondsLeft sec): "
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $keyHit = $false
                    while ($sw.ElapsedMilliseconds -lt 1000) {
                        if ([System.Console]::KeyAvailable) {
                            $key = [System.Console]::ReadKey($true)
                            if ($key.KeyChar -eq "2") {
                                $selectedRegion = "RU"
                                $keyHit = $true
                                break
                            } elseif ($key.KeyChar -eq "1" -or $key.Key -eq [System.ConsoleKey]::Enter) {
                                $selectedRegion = "EU"
                                $keyHit = $true
                                break
                            }
                        }
                        Start-Sleep -Milliseconds 50
                    }
                    if ($keyHit) { break }
                    $secondsLeft--
                }
            } catch {
                $selectedRegion = "EU"
            }
        }

        if (-not $selectedRegion) { $selectedRegion = "EU" }

        if (-not $isSilent) {
            Write-Host ""
            if ($selectedRegion -eq "RU") {
                Write-Host "[OK] Region selected: RUSSIA (Server 109 - 212.109.223.109)" -ForegroundColor Yellow
            } else {
                Write-Host "[OK] Region selected: EUROPE (Server_222 - 152.53.182.222)" -ForegroundColor Green
            }
            Write-Host ""

            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "         GIN-AGENT v036 - SYSTEM SERVICE DEPLOYMENT                " -ForegroundColor Green
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "[*] Stopping and updating all previous agent versions..." -ForegroundColor Yellow
        }

        # 1-4. Deep System Cleanup: Purges legacy services, tasks, processes, autostart shortcuts & registry clutter
        Invoke-GINAgentDeepCleanup -FullUninstall:$false

        # 5. Create Program Files directory
        if (-not (Test-Path $installDir)) {
            New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # 6. Save region configuration
        [System.IO.File]::WriteAllText("$installDir\region.txt", $selectedRegion, [System.Text.Encoding]::UTF8)

        # 7. Copy single CMD file to installation target
        $sourceScript = $env:GIN_AGENT_SCRIPT
        if (-not $sourceScript -or (-not (Test-Path $sourceScript))) {
            $sourceScript = $MyInvocation.MyCommand.Path
        }

        if ($sourceScript -and (Test-Path $sourceScript)) {
            try {
                Copy-Item -Path $sourceScript -Destination $targetCmd -Force -ErrorAction Stop
            } catch {
                try {
                    [System.IO.File]::WriteAllBytes($targetCmd, [System.IO.File]::ReadAllBytes($sourceScript))
                } catch {}
            }
            try { Copy-Item -Path $sourceScript -Destination $targetCmdVer -Force -ErrorAction SilentlyContinue } catch {}
        } else {
            if ($raw) {
                try { [System.IO.File]::WriteAllText($targetCmd, $raw, [System.Text.Encoding]::UTF8) } catch {}
                try { [System.IO.File]::WriteAllText($targetCmdVer, $raw, [System.Text.Encoding]::UTF8) } catch {}
            }
        }

        # 8. Deploy uninstaller script using clean Base64 (zero syntax clashes)
        $uninstallerB64 = "PCMgOg0KQGVjaG8gb2ZmDQpzZXRsb2NhbCBEaXNhYmxlRGVsYXllZEV4cGFuc2lvbg0KdGl0bGUgR0lOLUFnZW50IFVuaW5zdGFsbGVyDQoNCjo6IEVsZXZhdGlvbiBjaGVjaw0KbmV0IHNlc3Npb24gPm51bCAyPiYxDQppZiAlZXJyb3JsZXZlbCUgZXF1IDAgZ290byA6UlVOX1VOSU5TVEFMTA0KDQpwb3dlcnNoZWxsLmV4ZSAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICJ0cnkgeyBTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAnJX5mMCcgLVZlcmIgUnVuQXMgLUVycm9yQWN0aW9uIFN0b3A7IGV4aXQgMCB9IGNhdGNoIHsgZXhpdCAxIH0iID5udWwgMj4mMQ0KZXhpdCAvYiAlZXJyb3JsZXZlbCUNCg0KOlJVTl9VTklOU1RBTEwNCnNldCAiUFNfRVhFPXBvd2Vyc2hlbGwuZXhlIg0KaWYgZXhpc3QgIiVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSIgKA0KICAgIHNldCAiUFNfRVhFPSVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikgZWxzZSBpZiBleGlzdCAiJVN5c3RlbVJvb3QlXFN5c3RlbTMyXFdpbmRvd3NQb3dlclNoZWxsXHYxLjBccG93ZXJzaGVsbC5leGUiICgNCiAgICBzZXQgIlBTX0VYRT0lU3lzdGVtUm9vdCVcU3lzdGVtMzJcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikNCg0KIiVQU19FWEUlIiAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICIkcmF3ID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbFRleHQoJyV+ZjAnLCBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4KTsgJiAoW1NjcmlwdEJsb2NrXTo6Q3JlYXRlKCRyYXcpKSINCnNldCAiUFNfRVJSPSVlcnJvcmxldmVsJSINCmV4aXQgL2IgJVBTX0VSUiUNCiM+DQp0cnkgew0KICAgIFtDb25zb2xlXTo6T3V0cHV0RW5jb2RpbmcgPSBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4DQogICAgJE91dHB1dEVuY29kaW5nID0gW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6VVRGOA0KfSBjYXRjaCB7fQ0KDQpXcml0ZS1Ib3N0ICIiDQpXcml0ZS1Ib3N0ICI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIgLUZvcmVncm91bmRDb2xvciBSZWQNCldyaXRlLUhvc3QgIiAgICAgICAgICAgR0lOLUFHRU5UIC0gQ09NUExFVEUgU1lTVEVNIFVOSU5TVEFMTEFUSU9OICAgICAgICAgICAgICAgIiAtRm9yZWdyb3VuZENvbG9yIFllbGxvdw0KV3JpdGUtSG9zdCAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iIC1Gb3JlZ3JvdW5kQ29sb3IgUmVkDQpXcml0ZS1Ib3N0ICJbKl0gU3RvcHBpbmcgYW5kIHJlbW92aW5nIEdJTi1BZ2VudCBzZXJ2aWNlcywgdGFza3MsIHByb2Nlc3Nlcy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQoNCiMgMS4gU3RvcCBhbmQgcmVtb3ZlIHNjaGVkdWxlZCB0YXNrcw0KJHRhc2tzID0gQCgiR0lOLUFnZW50LVNlcnZpY2UiLCAiR0lOLUFnZW50IiwgIkdJTi1BZ2VudC1XYXRjaGRvZyIsICJHSU4tQWdlbnQtVXBkYXRlciIsICJHSU4tQWdlbnQtVXBkYXRlLUxvZ29uIiwgIkdJTi1SZW1vdGUiKQ0KZm9yZWFjaCAoJHQgaW4gJHRhc2tzKSB7DQogICAgdHJ5IHsgc2NodGFza3MuZXhlIC9lbmQgL3RuICIkdCIgMj4mMSB8IE91dC1OdWxsIH0gY2F0Y2gge30NCiAgICB0cnkgeyBzY2h0YXNrcy5leGUgL2RlbGV0ZSAvdG4gIiR0IiAvZiAyPiYxIHwgT3V0LU51bGwgfSBjYXRjaCB7fQ0KfQ0KdHJ5IHsNCiAgICBHZXQtU2NoZWR1bGVkVGFzayAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB8IFdoZXJlLU9iamVjdCB7DQogICAgICAgICRfLlRhc2tOYW1lIC1saWtlICIqR0lOKkFnZW50KiIgLW9yICRfLlRhc2tQYXRoIC1saWtlICIqR0lOKkFnZW50KiINCiAgICB9IHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICB0cnkgeyBzY2h0YXNrcy5leGUgL2VuZCAvdG4gIiQoJF8uVGFza05hbWUpIiAyPiYxIHwgT3V0LU51bGw7IHNjaHRhc2tzLmV4ZSAvZGVsZXRlIC90biAiJCgkXy5UYXNrTmFtZSkiIC9mIDI+JjEgfCBPdXQtTnVsbCB9IGNhdGNoIHt9DQogICAgfQ0KfSBjYXRjaCB7fQ0KDQojIDIuIFN0b3AgYW5kIHJlbW92ZSBXaW5kb3dzIFNlcnZpY2VzDQokc2VydmljZXMgPSBAKCJHSU4tQWdlbnQiLCAiR0lOLUFnZW50LVNlcnZpY2UiLCAiR0lOX0FnZW50IikNCmZvcmVhY2ggKCRzIGluICRzZXJ2aWNlcykgew0KICAgIHRyeSB7ICYgc2MuZXhlIHN0b3AgJHMgMj4mMSB8IE91dC1OdWxsIH0gY2F0Y2gge30NCiAgICB0cnkgeyAmIHNjLmV4ZSBkZWxldGUgJHMgMj4mMSB8IE91dC1OdWxsIH0gY2F0Y2gge30NCn0NCnRyeSB7DQogICAgR2V0LUNpbUluc3RhbmNlIFdpbjMyX1NlcnZpY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfCBXaGVyZS1PYmplY3Qgew0KICAgICAgICAkXy5OYW1lIC1saWtlICIqR0lOKkFnZW50KiIgLW9yICRfLkRpc3BsYXlOYW1lIC1saWtlICIqR0lOKkFnZW50KiINCiAgICB9IHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICB0cnkgeyAmIHNjLmV4ZSBzdG9wICRfLk5hbWUgMj4mMSB8IE91dC1OdWxsOyAmIHNjLmV4ZSBkZWxldGUgJF8uTmFtZSAyPiYxIHwgT3V0LU51bGwgfSBjYXRjaCB7fQ0KICAgIH0NCn0gY2F0Y2gge30NCg0KIyAzLiBUZXJtaW5hdGUgcnVubmluZyBhZ2VudCBwcm9jZXNzZXMgc2FmZWx5DQokY3VycmVudFBpZCA9ICRQSUQNCiRwYXJlbnRQaWQgPSAwDQp0cnkgew0KICAgICRwYXJlbnRQcm9jID0gR2V0LUNpbUluc3RhbmNlIFdpbjMyX1Byb2Nlc3MgLUZpbHRlciAiUHJvY2Vzc0lkID0gJGN1cnJlbnRQaWQiIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgaWYgKCRwYXJlbnRQcm9jKSB7ICRwYXJlbnRQaWQgPSAkcGFyZW50UHJvYy5QYXJlbnRQcm9jZXNzSWQgfQ0KfSBjYXRjaCB7fQ0KDQp0cnkgew0KICAgIEdldC1DaW1JbnN0YW5jZSBXaW4zMl9Qcm9jZXNzIC1GaWx0ZXIgIk5hbWUgPSAncG93ZXJzaGVsbC5leGUnIG9yIE5hbWUgPSAnY21kLmV4ZScgb3IgTmFtZSA9ICdwd3NoLmV4ZSciIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgV2hlcmUtT2JqZWN0IHsNCiAgICAgICAgJF8uUHJvY2Vzc0lkIC1uZSAkY3VycmVudFBpZCAtYW5kICRfLlByb2Nlc3NJZCAtbmUgJHBhcmVudFBpZCAtYW5kICgNCiAgICAgICAgICAgICRfLkNvbW1hbmRMaW5lIC1saWtlICIqR0lOLUFnZW50KiIgLW9yDQogICAgICAgICAgICAkXy5Db21tYW5kTGluZSAtbGlrZSAiKmFnZW50LWFwaSoiDQogICAgICAgICkNCiAgICB9IHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICB0cnkgeyBTdG9wLVByb2Nlc3MgLUlkICRfLlByb2Nlc3NJZCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfSBjYXRjaCB7fQ0KICAgIH0NCn0gY2F0Y2gge30NCnRyeSB7DQogICAgR2V0LVByb2Nlc3MgLU5hbWUgIkdJTi1BZ2VudCoiIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgV2hlcmUtT2JqZWN0IHsgJF8uSWQgLW5lICRjdXJyZW50UGlkIC1hbmQgJF8uSWQgLW5lICRwYXJlbnRQaWQgfSB8IFN0b3AtUHJvY2VzcyAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCn0gY2F0Y2gge30NCg0KU3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyA2MDANCg0KIyA0LiBSZW1vdmUgYWxsIGR1cGxpY2F0ZS9naG9zdCBBdXRvc3RhcnQgaXRlbXMgZnJvbSBSZWdpc3RyeSBSdW4gJiBSdW5PbmNlDQpXcml0ZS1Ib3N0ICJbKl0gUHVyZ2luZyBhbGwgUG93ZXJTaGVsbCBhbmQgYWdlbnQgZW50cmllcyBmcm9tIFJlZ2lzdHJ5IFJ1biBrZXlzLi4uIiAtRm9yZWdyb3VuZENvbG9yIEN5YW4NCiRydW5LZXlQYXRocyA9IEAoDQogICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFJ1biIsDQogICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFJ1bk9uY2UiLA0KICAgICJIS0xNOlxTT0ZUV0FSRVxXT1c2NDMyTm9kZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxSdW4iLA0KICAgICJIS0xNOlxTT0ZUV0FSRVxXT1c2NDMyTm9kZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxSdW5PbmNlIiwNCiAgICAiSEtDVTpcU29mdHdhcmVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cUnVuIiwNCiAgICAiSEtDVTpcU29mdHdhcmVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cUnVuT25jZSIsDQogICAgIkhLQ1U6XFNvZnR3YXJlXFdPVzY0MzJOb2RlXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFJ1biIsDQogICAgIkhLQ1U6XFNvZnR3YXJlXFdPVzY0MzJOb2RlXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFJ1bk9uY2UiDQopDQp0cnkgew0KICAgIEdldC1DaGlsZEl0ZW0gLVBhdGggIlJlZ2lzdHJ5OjpIS0VZX1VTRVJTIiAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB8IFdoZXJlLU9iamVjdCB7DQogICAgICAgICRfLlBTQ2hpbGROYW1lIC1ub3RtYXRjaCAnX0NsYXNzZXMkJyAtYW5kICRfLlBTQ2hpbGROYW1lIC1uZSAnLkRFRkFVTFQnDQogICAgfSB8IEZvckVhY2gtT2JqZWN0IHsNCiAgICAgICAgJHJ1bktleVBhdGhzICs9ICJSZWdpc3RyeTo6SEtFWV9VU0VSU1wkKCRfLlBTQ2hpbGROYW1lKVxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxSdW4iDQogICAgICAgICRydW5LZXlQYXRocyArPSAiUmVnaXN0cnk6OkhLRVlfVVNFUlNcJCgkXy5QU0NoaWxkTmFtZSlcU29mdHdhcmVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cUnVuT25jZSINCiAgICB9DQp9IGNhdGNoIHt9DQoNCmZvcmVhY2ggKCRyayBpbiAkcnVuS2V5UGF0aHMpIHsNCiAgICBpZiAoVGVzdC1QYXRoICRyaykgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgJGl0ZW0gPSBHZXQtSXRlbSAtUGF0aCAkcmsgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgIGlmICgkaXRlbSkgew0KICAgICAgICAgICAgICAgIGZvcmVhY2ggKCRwcm9wIGluICRpdGVtLlByb3BlcnR5KSB7DQogICAgICAgICAgICAgICAgICAgICR2YWwgPSAoJGl0ZW0uR2V0VmFsdWUoJHByb3ApIHwgT3V0LVN0cmluZykuVHJpbSgpDQogICAgICAgICAgICAgICAgICAgICRpc01hdGNoID0gJGZhbHNlDQogICAgICAgICAgICAgICAgICAgIGlmICgkcHJvcCAtbWF0Y2ggJyg/aSkoR0lOLUFnZW50fEdJTl9BZ2VudHxOZXZlckNvbWJpbmV8Rm9sZGVyVmlld3xVbHRhcml4TW9uaXRvciknKSB7DQogICAgICAgICAgICAgICAgICAgICAgICAkaXNNYXRjaCA9ICR0cnVlDQogICAgICAgICAgICAgICAgICAgIH0gZWxzZWlmICgkdmFsIC1tYXRjaCAnKD9pKShHSU4tQWdlbnR8R0lOX0FnZW50fGFnZW50LWFwaXxOZXZlckNvbWJpbmVUYXNrYmFyfEZvbGRlclZpZXdMaXN0U29ydFR5cGUpJykgew0KICAgICAgICAgICAgICAgICAgICAgICAgJGlzTWF0Y2ggPSAkdHJ1ZQ0KICAgICAgICAgICAgICAgICAgICB9IGVsc2VpZiAoJHZhbCAtbWF0Y2ggJyg/aSlwb3dlcnNoZWxsXC5leGUnIC1hbmQgJHZhbCAtbWF0Y2ggJyg/aSkoR0lOfE5ldmVyQ29tYmluZXxGb2xkZXJWaWV3KScpIHsNCiAgICAgICAgICAgICAgICAgICAgICAgICRpc01hdGNoID0gJHRydWUNCiAgICAgICAgICAgICAgICAgICAgfQ0KICAgICAgICAgICAgICAgICAgICBpZiAoJGlzTWF0Y2gpIHsNCiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7IFJlbW92ZS1JdGVtUHJvcGVydHkgLVBhdGggJHJrIC1OYW1lICRwcm9wIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB9IGNhdGNoIHt9DQogICAgICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICB9DQogICAgICAgIH0gY2F0Y2gge30NCiAgICB9DQp9DQoNCiMgNS4gQ2xlYW4gU3RhcnR1cEFwcHJvdmVkIHJlZ2lzdHJ5IGtleXMNCiRhcHByb3ZlZFBhdGhzID0gQCgNCiAgICAiSEtMTTpcU09GVFdBUkVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cRXhwbG9yZXJcU3RhcnR1cEFwcHJvdmVkXFJ1biIsDQogICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXEV4cGxvcmVyXFN0YXJ0dXBBcHByb3ZlZFxSdW4zMiIsDQogICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXEV4cGxvcmVyXFN0YXJ0dXBBcHByb3ZlZFxTdGFydHVwRm9sZGVyIiwNCiAgICAiSEtDVTpcU29mdHdhcmVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cRXhwbG9yZXJcU3RhcnR1cEFwcHJvdmVkXFJ1biIsDQogICAgIkhLQ1U6XFNvZnR3YXJlXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXEV4cGxvcmVyXFN0YXJ0dXBBcHByb3ZlZFxTdGFydHVwRm9sZGVyIg0KKQ0KZm9yZWFjaCAoJGFwIGluICRhcHByb3ZlZFBhdGhzKSB7DQogICAgaWYgKFRlc3QtUGF0aCAkYXApIHsNCiAgICAgICAgdHJ5IHsNCiAgICAgICAgICAgICRpdGVtID0gR2V0LUl0ZW0gLVBhdGggJGFwIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgICAgICAgICBpZiAoJGl0ZW0pIHsNCiAgICAgICAgICAgICAgICBmb3JlYWNoICgkcHJvcCBpbiAkaXRlbS5Qcm9wZXJ0eSkgew0KICAgICAgICAgICAgICAgICAgICBpZiAoJHByb3AgLW1hdGNoICcoP2kpKEdJTi1BZ2VudHxHSU5fQWdlbnR8TmV2ZXJDb21iaW5lfEZvbGRlclZpZXd8VWx0YXJpeE1vbml0b3IpJykgew0KICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHsgUmVtb3ZlLUl0ZW1Qcm9wZXJ0eSAtUGF0aCAkYXAgLU5hbWUgJHByb3AgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIH0gY2F0Y2gge30NCiAgICAgICAgICAgICAgICAgICAgfQ0KICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgIH0NCiAgICAgICAgfSBjYXRjaCB7fQ0KICAgIH0NCn0NCg0KIyA2LiBQdXJnZSBTdGFydHVwIGZvbGRlcnMNCldyaXRlLUhvc3QgIlsqXSBQdXJnaW5nIGFsbCBQb3dlclNoZWxsIGFuZCBkdXBsaWNhdGUgc2NyaXB0cyBmcm9tIFN0YXJ0dXAgZm9sZGVycy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQokc3RhcnR1cEZvbGRlcnMgPSBAKA0KICAgICIkZW52OlByb2dyYW1EYXRhXE1pY3Jvc29mdFxXaW5kb3dzXFN0YXJ0IE1lbnVcUHJvZ3JhbXNcU3RhcnRVcCIsDQogICAgIiRlbnY6UHJvZ3JhbURhdGFcTWljcm9zb2Z0XFdpbmRvd3NcU3RhcnQgTWVudVxQcm9ncmFtc1xTdGFydHVwIiwNCiAgICAiJGVudjpBTExVU0VSU1BST0ZJTEVcTWljcm9zb2Z0XFdpbmRvd3NcU3RhcnQgTWVudVxQcm9ncmFtc1xTdGFydFVwIiwNCiAgICAiJGVudjpBTExVU0VSU1BST0ZJTEVcTWljcm9zb2Z0XFdpbmRvd3NcU3RhcnQgTWVudVxQcm9ncmFtc1xTdGFydHVwIiwNCiAgICAiJGVudjpBUFBEQVRBXE1pY3Jvc29mdFxXaW5kb3dzXFN0YXJ0IE1lbnVcUHJvZ3JhbXNcU3RhcnR1cCIsDQogICAgIiQoW0Vudmlyb25tZW50XTo6R2V0Rm9sZGVyUGF0aCgnU3RhcnR1cCcpKSINCikNCnRyeSB7DQogICAgR2V0LUNoaWxkSXRlbSAtUGF0aCAiJGVudjpTeXN0ZW1Ecml2ZVxVc2VycyIgLURpcmVjdG9yeSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB8IEZvckVhY2gtT2JqZWN0IHsNCiAgICAgICAgJHVTdGFydHVwID0gIiQoJF8uRnVsbE5hbWUpXEFwcERhdGFcUm9hbWluZ1xNaWNyb3NvZnRcV2luZG93c1xTdGFydCBNZW51XFByb2dyYW1zXFN0YXJ0dXAiDQogICAgICAgIGlmIChUZXN0LVBhdGggJHVTdGFydHVwKSB7ICRzdGFydHVwRm9sZGVycyArPSAkdVN0YXJ0dXAgfQ0KICAgIH0NCn0gY2F0Y2gge30NCg0KJHdzY3JpcHRTaGVsbCA9ICRudWxsDQp0cnkgeyAkd3NjcmlwdFNoZWxsID0gTmV3LU9iamVjdCAtQ29tT2JqZWN0IFdTY3JpcHQuU2hlbGwgfSBjYXRjaCB7fQ0KDQpmb3JlYWNoICgkc2YgaW4gKCRzdGFydHVwRm9sZGVycyB8IFNlbGVjdC1PYmplY3QgLVVuaXF1ZSkpIHsNCiAgICBpZiAoVGVzdC1QYXRoICRzZikgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgR2V0LUNoaWxkSXRlbSAtUGF0aCAkc2YgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICAgICAgICAgICRmID0gJF8NCiAgICAgICAgICAgICAgICAkc2hvdWxkRGVsZXRlID0gJGZhbHNlDQogICAgICAgICAgICAgICAgJGZuID0gJGYuTmFtZQ0KICAgICAgICAgICAgICAgIGlmICgkZm4gLW1hdGNoICcoP2kpKEdJTi1BZ2VudHxHSU5fQWdlbnR8TmV2ZXJDb21iaW5lfEZvbGRlclZpZXd8VWx0YXJpeE1vbml0b3J8Q0xFQU5cLmxuayknKSB7DQogICAgICAgICAgICAgICAgICAgICRzaG91bGREZWxldGUgPSAkdHJ1ZQ0KICAgICAgICAgICAgICAgIH0gZWxzZWlmICgkZi5FeHRlbnNpb24gLWVxICIucHMxIikgew0KICAgICAgICAgICAgICAgICAgICAkc2hvdWxkRGVsZXRlID0gJHRydWUNCiAgICAgICAgICAgICAgICB9IGVsc2VpZiAoJGYuRXh0ZW5zaW9uIC1lcSAiLmxuayIgLWFuZCAkd3NjcmlwdFNoZWxsKSB7DQogICAgICAgICAgICAgICAgICAgIHRyeSB7DQogICAgICAgICAgICAgICAgICAgICAgICAkc2MgPSAkd3NjcmlwdFNoZWxsLkNyZWF0ZVNob3J0Y3V0KCRmLkZ1bGxOYW1lKQ0KICAgICAgICAgICAgICAgICAgICAgICAgJHRhcmdldCA9ICgkc2MuVGFyZ2V0UGF0aCB8IE91dC1TdHJpbmcpLlRyaW0oKQ0KICAgICAgICAgICAgICAgICAgICAgICAgJGFyZ3MgPSAoJHNjLkFyZ3VtZW50cyB8IE91dC1TdHJpbmcpLlRyaW0oKQ0KICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCR0YXJnZXQgLW1hdGNoICcoP2kpcG93ZXJzaGVsbCcgLWFuZCAoJGFyZ3MgLW1hdGNoICcoP2kpKEdJTnxBZ2VudHxOZXZlckNvbWJpbmV8Rm9sZGVyVmlldyknIC1vciAtbm90ICRhcmdzKSkgew0KICAgICAgICAgICAgICAgICAgICAgICAgICAgICRzaG91bGREZWxldGUgPSAkdHJ1ZQ0KICAgICAgICAgICAgICAgICAgICAgICAgfSBlbHNlaWYgKCR0YXJnZXQgLW1hdGNoICcoP2kpKEdJTi1BZ2VudHxHSU5fQWdlbnQpJyAtb3IgJGFyZ3MgLW1hdGNoICcoP2kpKEdJTi1BZ2VudHxHSU5fQWdlbnQpJykgew0KICAgICAgICAgICAgICAgICAgICAgICAgICAgICRzaG91bGREZWxldGUgPSAkdHJ1ZQ0KICAgICAgICAgICAgICAgICAgICAgICAgfSBlbHNlaWYgKCR0YXJnZXQgLWFuZCAtbm90IChUZXN0LVBhdGggJHRhcmdldCkpIHsNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoJHRhcmdldCAtbWF0Y2ggJyg/aSkoR0lOfEFnZW50fHBvd2Vyc2hlbGwpJykgew0KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAkc2hvdWxkRGVsZXRlID0gJHRydWUNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge30NCiAgICAgICAgICAgICAgICB9IGVsc2VpZiAoJGYuRXh0ZW5zaW9uIC1pbiBAKCIuY21kIiwgIi5iYXQiLCAiLnZicyIpKSB7DQogICAgICAgICAgICAgICAgICAgIHRyeSB7DQogICAgICAgICAgICAgICAgICAgICAgICAkY29udGVudCA9IEdldC1Db250ZW50IC1QYXRoICRmLkZ1bGxOYW1lIC1SYXcgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgICAgICAgICAgICAgIGlmICgkY29udGVudCAtbWF0Y2ggJyg/aSkoR0lOLUFnZW50fEdJTl9BZ2VudHxhZ2VudC1hcGl8TmV2ZXJDb21iaW5lVGFza2JhciknKSB7DQogICAgICAgICAgICAgICAgICAgICAgICAgICAgJHNob3VsZERlbGV0ZSA9ICR0cnVlDQogICAgICAgICAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge30NCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgaWYgKCRzaG91bGREZWxldGUpIHsNCiAgICAgICAgICAgICAgICAgICAgdHJ5IHsNCiAgICAgICAgICAgICAgICAgICAgICAgICRmLklzUmVhZE9ubHkgPSAkZmFsc2UNCiAgICAgICAgICAgICAgICAgICAgICAgIFJlbW92ZS1JdGVtIC1QYXRoICRmLkZ1bGxOYW1lIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQ0KICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIHt9DQogICAgICAgICAgICAgICAgfQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9IGNhdGNoIHt9DQogICAgfQ0KfQ0KDQojIDcuIFJlbW92ZSBXaW5kb3dzIFJlZ2lzdHJ5IGVudHJpZXMNCldyaXRlLUhvc3QgIlsqXSBSZW1vdmluZyByZWdpc3RyeSBlbnRyaWVzLi4uIiAtRm9yZWdyb3VuZENvbG9yIEN5YW4NCiRyZWdQYXRocyA9IEAoDQogICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFVuaW5zdGFsbFxHSU4tQWdlbnQiLA0KICAgICJIS0NVOlxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxVbmluc3RhbGxcR0lOLUFnZW50IiwNCiAgICAiSEtMTTpcU09GVFdBUkVcR0lOLUFnZW50IiwNCiAgICAiSEtDVTpcU29mdHdhcmVcR0lOLUFnZW50IiwNCiAgICAiSEtMTTpcU09GVFdBUkVcV09XNjQzMk5vZGVcR0lOLUFnZW50IiwNCiAgICAiSEtMTTpcU09GVFdBUkVcV09XNjQzMk5vZGVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cVW5pbnN0YWxsXEdJTi1BZ2VudCINCikNCmZvcmVhY2ggKCRycCBpbiAkcmVnUGF0aHMpIHsNCiAgICBpZiAoVGVzdC1QYXRoICRycCkgew0KICAgICAgICB0cnkgeyBSZW1vdmUtSXRlbSAtUGF0aCAkcnAgLVJlY3Vyc2UgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIH0gY2F0Y2gge30NCiAgICB9DQp9DQoNCiMgOC4gQ2xlYW4gdXAgZGlyZWN0b3JpZXMNCldyaXRlLUhvc3QgIlsqXSBSZW1vdmluZyBHSU4tQWdlbnQgZmlsZXMgYW5kIGRpcmVjdG9yaWVzLi4uIiAtRm9yZWdyb3VuZENvbG9yIEN5YW4NCiRkaXJzVG9QdXJnZSA9IEAoDQogICAgIiRlbnY6UHJvZ3JhbURhdGFcR0lOLUFnZW50IiwNCiAgICAiJGVudjpQcm9ncmFtRmlsZXNcR0lOLUFnZW50IiwNCiAgICAiJHtlbnY6UHJvZ3JhbUZpbGVzKHg4Nil9XEdJTi1BZ2VudCINCikNCmZvcmVhY2ggKCRkIGluICRkaXJzVG9QdXJnZSkgew0KICAgIGlmIChUZXN0LVBhdGggJGQpIHsNCiAgICAgICAgdHJ5IHsNCiAgICAgICAgICAgIEdldC1DaGlsZEl0ZW0gLVBhdGggJGQgLUZpbGUgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfCBGb3JFYWNoLU9iamVjdCB7DQogICAgICAgICAgICAgICAgaWYgKCRfLkZ1bGxOYW1lIC1uZSAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5QYXRoKSB7DQogICAgICAgICAgICAgICAgICAgIHRyeSB7ICRfLklzUmVhZE9ubHkgPSAkZmFsc2U7IFJlbW92ZS1JdGVtIC1QYXRoICRfLkZ1bGxOYW1lIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB9IGNhdGNoIHt9DQogICAgICAgICAgICAgICAgfQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9IGNhdGNoIHt9DQogICAgfQ0KfQ0KDQojIDkuIERldGFjaGVkIHNlbGYtY2xlYW51cCBmb3IgcmVtYWluaW5nIGZvbGRlcg0KJHNjcmlwdFBhdGggPSAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5QYXRoDQppZiAoLW5vdCAkc2NyaXB0UGF0aCkgeyAkc2NyaXB0UGF0aCA9ICIkZW52OlByb2dyYW1GaWxlc1xHSU4tQWdlbnRcdW5pbnN0YWxsLmNtZCIgfQ0KJHBhcmVudEZvbGRlciA9IFNwbGl0LVBhdGggLVBhcmVudCAkc2NyaXB0UGF0aA0KDQpXcml0ZS1Ib3N0ICIiDQpXcml0ZS1Ib3N0ICI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIgLUZvcmVncm91bmRDb2xvciBHcmVlbg0KV3JpdGUtSG9zdCAiICBbT0tdIEdJTi1BR0VOVCBIQVMgQkVFTiBDT01QTEVURUxZIEFORCBDTEVBTkxZIFJFTU9WRUQhICAgICAgICAgICAiIC1Gb3JlZ3JvdW5kQ29sb3IgR3JlZW4NCldyaXRlLUhvc3QgIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQpXcml0ZS1Ib3N0ICIiDQoNCmlmICgkcGFyZW50Rm9sZGVyIC1hbmQgKFRlc3QtUGF0aCAkcGFyZW50Rm9sZGVyKSkgew0KICAgIFN0YXJ0LVByb2Nlc3MgLUZpbGVQYXRoICJjbWQuZXhlIiAtQXJndW1lbnRMaXN0ICIvYyBwaW5nIDEyNy4wLjAuMSAtbiAzID5udWwgJiByZCAvcyAvcSBgImAiJHBhcmVudEZvbGRlcmAiYCIiIC1XaW5kb3dTdHlsZSBIaWRkZW4NCn0NCg0KU3RhcnQtU2xlZXAgLVNlY29uZHMgMg0KZXhpdCAwDQo="
        [System.IO.File]::WriteAllBytes($uninstallerCmd, [System.Convert]::FromBase64String($uninstallerB64))

        # 9. Register in Windows Installed Apps (Add/Remove Programs)
        try {
            $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent"
            if (-not (Test-Path $uninstallKey)) { New-Item -Path $uninstallKey -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayName" -Value "GIN-Agent Remote Support" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayVersion" -Value "v036" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "Publisher" -Value "VladiMIR+AI" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "InstallLocation" -Value $installDir -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "UninstallString" -Value "`"$uninstallerCmd`"" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "QuietUninstallString" -Value "`"$uninstallerCmd`"" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "NoModify" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "NoRepair" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } catch {}

        # 10. Enable Remote Desktop (RDP), TermService, Port 3389 and Windows Firewall
        if (-not $isSilent) {
            Write-Host "[*] Enabling Remote Desktop Connection (RDP), TermService & Firewall..." -ForegroundColor Cyan
        }
        Enable-RemoteDesktopSupport
        if (-not $isSilent) {
            Write-Host "    [OK] Remote Desktop enabled (TermService active, NLA requirement disabled, Port 3389 open)." -ForegroundColor Green
        }

        # 11. Register Bulletproof Native Windows Scheduled Service Host (Session 0, SYSTEM, Unkillable)
        if (-not $isSilent) {
            Write-Host "[*] Registering unkillable Session 0 SYSTEM service ($selectedRegion)..." -ForegroundColor Cyan
        }

        # Prevent laptops from dropping Wi-Fi / sleeping on AC power after user logoff or screen lock
        try {
            & powercfg.exe /change standby-timeout-ac 0 2>&1 | Out-Null
            & powercfg.exe /setacvalueindex scheme_current sub_buttons lidaction 0 2>&1 | Out-Null
            & powercfg.exe /setactive scheme_current 2>&1 | Out-Null
        } catch {}

        $taskName = "GIN-Agent-Service"
        try { schtasks.exe /end /tn "$taskName" 2>&1 | Out-Null } catch {}
        try { schtasks.exe /delete /tn "$taskName" /f 2>&1 | Out-Null } catch {}

        # Use native Register-ScheduledTask for 100% reliable quote preservation and battery immunity
        $regSuccess = $false
        try {
            $act = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"`"$targetCmd`" /service $selectedRegion`"" -WorkingDirectory $installDir
            $trigBoot = New-ScheduledTaskTrigger -AtStartup
            $trigLogon = New-ScheduledTaskTrigger -AtLogOn
            $princ = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $sett = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0) -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable -MultipleInstances IgnoreNew
            $null = Register-ScheduledTask -TaskName "$taskName" -TaskPath "\" -Action $act -Trigger @($trigBoot, $trigLogon) -Principal $princ -Settings $sett -Force -ErrorAction Stop
            $regSuccess = $true
        } catch {
            # Resilient fallback via schtasks XML
            $xmlDef = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Author>VladiMIR+AI</Author><Description>GIN-Agent Unkillable System Service</Description></RegistrationInfo>
  <Triggers><BootTrigger><Enabled>true</Enabled></BootTrigger><LogonTrigger><Enabled>true</Enabled></LogonTrigger></Triggers>
  <Principals><Principal id="Author"><UserId>S-1-5-18</UserId><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardImmediate>false</AllowHardImmediate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings><StopOnIdleEnd>false</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>4</Priority>
    <RestartOnFailure><Interval>PT1M</Interval><Count>999</Count></RestartOnFailure>
  </Settings>
  <Actions Context="Author"><Exec><Command>cmd.exe</Command><Arguments>/c &quot;&quot;$targetCmd&quot; /service $selectedRegion&quot;</Arguments><WorkingDirectory>$installDir</WorkingDirectory></Exec></Actions>
</Task>
"@
            $xmlPath = "$env:TEMP\gin_agent_svc.xml"
            [System.IO.File]::WriteAllText($xmlPath, $xmlDef, [System.Text.Encoding]::Unicode)
            & schtasks.exe /create /tn "$taskName" /xml "$xmlPath" /f 2>&1 | Out-Null
            try { Remove-Item -Path $xmlPath -Force -ErrorAction SilentlyContinue } catch {}
        }

        # Start the SYSTEM service task
        schtasks.exe /run /tn "$taskName" 2>&1 | Out-Null

        # Watchdog Task: checks every 3 minutes, restarts GIN-Agent-Service if stopped
        $watchdogName = "GIN-Agent-Watchdog"
        try { schtasks.exe /end /tn "$watchdogName" 2>&1 | Out-Null } catch {}
        try { schtasks.exe /delete /tn "$watchdogName" /f 2>&1 | Out-Null } catch {}

        try {
            $wdAct = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"if ((Get-ScheduledTask -TaskName 'GIN-Agent-Service' -TaskPath '\' -ErrorAction SilentlyContinue).State -ne 'Running') { Start-ScheduledTask -TaskName 'GIN-Agent-Service' -TaskPath '\' -ErrorAction SilentlyContinue }`""
            $wdTrig = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::MaxValue)
            $wdPrinc = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $wdSett = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0) -StartWhenAvailable
            $null = Register-ScheduledTask -TaskName "$watchdogName" -TaskPath "\" -Action $wdAct -Trigger $wdTrig -Principal $wdPrinc -Settings $wdSett -Force -ErrorAction Stop
        } catch {
            $wdActionCmd = "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -Command `"if ((Get-ScheduledTask -TaskName 'GIN-Agent-Service' -ErrorAction SilentlyContinue).State -ne 'Running') { Start-ScheduledTask -TaskName 'GIN-Agent-Service' }`""
            schtasks.exe /create /tn "$watchdogName" /tr "$wdActionCmd" /sc MINUTE /mo 3 /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null
        }

        # Scheduled Auto-Update Task on User Logon (+15 minutes delay)
        $logonTaskName = "GIN-Agent-Update-Logon"
        try { schtasks.exe /delete /tn "$logonTaskName" /f 2>&1 | Out-Null } catch {}
        $logonAction = "cmd.exe /c `"`"$targetCmd`" /checkupdate $selectedRegion`""
        schtasks.exe /create /tn "$logonTaskName" /tr $logonAction /sc ONLOGON /delay 0015:00 /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null

        if (-not $isSilent) {
            $regDesc = if ($selectedRegion -eq "RU") { "RUSSIA (Server 109: 212.109.223.109)" } else { "EUROPE (Server_222: 152.53.182.222)" }
            Write-Host ""
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [+] GIN-Agent v036 deployed cleanly in Program Files!" -ForegroundColor Green
            Write-Host "  [+] Location: $installDir" -ForegroundColor White
            Write-Host "  [+] Uninstaller: $uninstallerCmd" -ForegroundColor White
            Write-Host "  [+] Active region: $regDesc" -ForegroundColor Cyan
            Write-Host "  [+] Auto-Update: enabled (Dual-channel: RU-109 / GitHub)" -ForegroundColor Green
            Write-Host "  [+] Tasks: GIN-Agent-Service (Auto-start on OS boot) + GIN-Agent-Watchdog (5-min watchdog)" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "====================================================================" -ForegroundColor Green
            Write-Host "  [OK] INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
            Write-Host "====================================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "[*] Deployment finished. Window closing automatically..." -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 600
        }
        [System.Environment]::Exit(0)
    }

    # ==========================================================================
    # MODE 2: SERVICE WORKER (Background execution loop)
    # ==========================================================================
    $token = "GinCz-Remote-2026"
    $headers = @{ "Token" = $token; "X-Host" = $env:COMPUTERNAME }

    # Singleton Mutex to prevent duplicate service instances
    $createdNew = $false
    try {
        $mutex = New-Object System.Threading.Mutex($true, "Global\GIN_Agent_Core_Mutex", [ref]$createdNew)
    } catch [System.Threading.AbandonedMutexException] {
        $createdNew = $true
    }
    if (-not $createdNew) { exit 0 }
    $global:agentMutex = $mutex

    # Determine Active Region (Command parameter > region.txt > default EU)
    $region = $env:GIN_AGENT_REGION
    if (-not $region -or ($region -ne "RU" -and $region -ne "EU")) {
        $regFile = "$installDir\region.txt"
        if (Test-Path $regFile) {
            try {
                $saved = (Get-Content -Path $regFile -Raw -ErrorAction SilentlyContinue).Trim()
                if ($saved -eq "RU" -or $saved -eq "EU") { $region = $saved }
            } catch {}
        }
    }
    if ($region -ne "RU") { $region = "EU" }

    # Resilient Regional Gateways
    if ($region -eq "RU") {
        $gateways = @(
            @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" },
            @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
            @{ Name = "Europe (Server_222)"; Url = "http://152.53.182.222:9876" },
            @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" }
        )
    } else {
        $gateways = @(
            @{ Name = "Europe (Server_222)"; Url = "http://152.53.182.222:9876" },
            @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
            @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" },
            @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" }
        )
    }

    $serverUrl = ""
    $activeGatewayName = ""
    foreach ($gw in $gateways) {
        try {
            $resp = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
            if ($resp) {
                $serverUrl = $gw.Url
                $activeGatewayName = $gw.Name
                break
            }
        } catch {}
    }
    if (-not $serverUrl) {
        if ($region -eq "RU") {
            $serverUrl = "http://212.109.223.109/agent-api"
            $activeGatewayName = "RU-109 Fallback"
        } else {
            $serverUrl = "http://152.53.182.222:9876"
            $activeGatewayName = "Server_222 Fallback"
        }
    }

    # Ensure RDP, TermService, Firewall & Shadow Policy
    Enable-RemoteDesktopSupport

    # Hardware GIN-PIN calculation (Deterministic WMI)
    $pin = "100-000-001"
    try {
        $uuid = (Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        $board = (Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).SerialNumber
        if (-not $uuid) { $uuid = $env:COMPUTERNAME }
        if (-not $board) { $board = "DefaultBoard" }
        $rawPin = "hw_win_${uuid}_${board}"
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawPin)
        $digest = $sha.ComputeHash($bytes)
        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($digest, 0, 8) }
        $num = [Math]::Abs([BitConverter]::ToInt64($digest, 0))
        $code = ($num % 900000000) + 100000000
        $dStr = $code.ToString("D9")
        $pin = "$($dStr.Substring(0,3))-$($dStr.Substring(3,3))-$($dStr.Substring(6,3))"
    } catch {}

    $headers["X-Pin"] = $pin

    # ULTARIX Policy: Enforce RustDesk unattended password 'Ultarix-22'
    try {
        if ($env:COMPUTERNAME -match '^(ULTARIX|U-\d|ULPS)' -or (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).Workgroup -match 'ULTARIX') {
            $rdExe = @(
                "$env:ProgramFiles\RustDesk\RustDesk.exe",
                "${env:ProgramFiles(x86)}\RustDesk\RustDesk.exe",
                "C:\Program Files\RustDesk\rustdesk.exe"
            ) | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($rdExe) {
                $p = Start-Process -FilePath $rdExe -ArgumentList "--password", "Ultarix-22" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                if ($p) { $p.WaitForExit(5000) }
                Start-Sleep -Seconds 1
                $src = "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
                Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    $dst = "$($_.FullName)\AppData\Roaming\RustDesk\config"
                    if (Test-Path $dst) {
                        Copy-Item "$src\RustDesk*.toml" -Destination $dst -Force -ErrorAction SilentlyContinue
                    }
                }
                Restart-Service RustDesk -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # Detect RustDesk ID
    $rustdeskId = ""
    $rdBin = @(
        "$env:ProgramFiles\RustDesk\RustDesk.exe",
        "${env:ProgramFiles(x86)}\RustDesk\RustDesk.exe",
        "C:\Program Files\RustDesk\rustdesk.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($rdBin) {
        try {
            $tempIdFile = "$env:TEMP\rd_id_probe.txt"
            $p = Start-Process -FilePath $rdBin -ArgumentList "--get-id" -RedirectStandardOutput $tempIdFile -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
            if ($p) { $p.WaitForExit(3000) }
            if (Test-Path $tempIdFile) {
                $probeId = (Get-Content -Path $tempIdFile -Raw -ErrorAction SilentlyContinue).Trim()
                if ($probeId -match '^\d{6,12}$') { $rustdeskId = $probeId }
                Remove-Item -Path $tempIdFile -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    if (-not $rustdeskId) {
        $rdPaths = @(
            "$env:APPDATA\RustDesk\config\RustDesk.toml",
            "$env:APPDATA\RustDesk\config\rustdesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\rustdesk.toml"
        )
        foreach ($cp in $rdPaths) {
            if (Test-Path $cp) {
                $c = Get-Content -Path $cp -Raw -ErrorAction SilentlyContinue
                if ($c -match '(?m)^\s*id\s*=\s*["\x27]?(\d{6,12})["\x27]?') {
                    $rustdeskId = $matches[1]
                    break
                }
            }
        }
    }

    # Telemetry
    $arch = if ([IntPtr]::Size -eq 8) { "64-bit" } else { "32-bit" }
    $osName = "Microsoft Windows ($arch)"
    $cpuName = "N/A"
    $ramStr = "N/A"
    $diskStr = "N/A"
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($osInfo) { $osName = "$($osInfo.Caption) ($arch)" }
        $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpuObj) { $cpuName = $cpuObj.Name.Trim() }
        if ($osInfo) {
            $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
            $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
            $totRam = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            $ramStr = "$freeRam GB free / $totRam GB total"
        }
        $drive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($drive) {
            $freeGb = [math]::Round($drive.Free / 1GB, 1)
            $totGb = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
            $diskStr = "C: $freeGb GB free / $totGb GB total"
        }
    } catch {}

    # Registration & Telegram Alert Suppression Check
    $tagFile = "$installDir\registered.tag"
    $isFirstRegistration = -not (Test-Path $tagFile)

    try {
        $regPayload = @{
            pin             = $pin
            host            = $env:COMPUTERNAME
            user            = $env:USERNAME
            admin           = $true
            os              = $osName
            cpu             = $cpuName
            ram             = $ramStr
            disk            = $diskStr
            rustdesk_id     = $rustdeskId
            rdp_ready       = $true
            region          = $region
            gateway         = $activeGatewayName
            version         = "v036"
            first_connect   = $isFirstRegistration
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
        if ($isFirstRegistration) {
            [System.IO.File]::WriteAllText($tagFile, (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), [System.Text.Encoding]::UTF8)
        }
    } catch {}

    # Global scope variables for bulletproof background heartbeat timer
    $global:hbServerUrl = $serverUrl
    $global:hbHeaders = $headers
    $global:hbPin = $pin
    $global:hbRustdeskId = $rustdeskId
    $global:hbActiveGatewayName = $activeGatewayName
    $global:hbRegion = $region

    # BACKGROUND HEARTBEAT TIMER (ThreadPool execution, active during long commands)
    $hbTimer = New-Object System.Timers.Timer
    $hbTimer.Interval = 30000  # 30 seconds
    $hbTimer.AutoReset = $true

    $hbAction = {
        try {
            $targetPin = if ($global:hbPin) { $global:hbPin } else { $pin }
            $targetRd = if ($global:hbRustdeskId) { $global:hbRustdeskId } else { $rustdeskId }
            $targetGw = if ($global:hbActiveGatewayName) { $global:hbActiveGatewayName } else { $activeGatewayName }
            $targetReg = if ($global:hbRegion) { $global:hbRegion } else { $region }
            if ($targetPin) {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$targetPin&v=v036&rd_id=$targetRd&gw=$([System.Uri]::EscapeDataString($targetGw))&region=$targetReg"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
        try {
            $targetServer = if ($global:hbServerUrl) { $global:hbServerUrl } else { $serverUrl }
            $targetHdr = if ($global:hbHeaders) { $global:hbHeaders } else { $headers }
            $targetPin = if ($global:hbPin) { $global:hbPin } else { $pin }
            $targetReg = if ($global:hbRegion) { $global:hbRegion } else { $region }
            if ($targetServer -and $targetPin) {
                $reRegPayload = @{ pin = $targetPin; host = $env:COMPUTERNAME; region = $targetReg; version = "v036" } | ConvertTo-Json
                Invoke-RestMethod -Uri "$targetServer/register" -Method Post -Headers $targetHdr -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
    }

    Register-ObjectEvent -InputObject $hbTimer -EventName Elapsed -Action $hbAction | Out-Null
    $hbTimer.Start()

    # Background Polling Loop (with direct KeepAlive guaranteed every ~25s)
    $updateCheckCounter = 0
    $consecutiveErrors = 0
    $loopCount = 0

    while ($true) {
        try {
            $pollUrl = "$serverUrl/poll?h=$([System.Uri]::EscapeDataString($env:COMPUTERNAME))&pin=$pin"
            $resp = Invoke-RestMethod -Uri $pollUrl -Method Get -Headers $headers -TimeoutSec 15 -ErrorAction Stop
            $consecutiveErrors = 0  # reset on success
            if ($resp -and $resp.command) {
                $cmdId = $resp.id
                $cmdText = $resp.command
                $out = ""
                try {
                    # Isolated execution: command runs in separate Job, never blocks main loop permanently
                    $job = Start-Job -ScriptBlock ([ScriptBlock]::Create($cmdText))
                    $completed = Wait-Job $job -Timeout 90
                    if ($completed) {
                        $out = Receive-Job $job 2>&1 | Out-String
                    } else {
                        Stop-Job $job -ErrorAction SilentlyContinue
                        $out = "[ERROR: Command timed out after 90 seconds - agent stayed online]"
                    }
                    Remove-Job $job -Force -ErrorAction SilentlyContinue
                } catch {
                    $out = "EXEC ERROR: $($_.Exception.Message)"
                }
                if (-not $out -or $out.Trim() -eq "") { $out = "[OK: Command completed with no output]" }
                $bodyObj = @{ id = $cmdId; host = $env:COMPUTERNAME; output = $out } | ConvertTo-Json
                Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $bodyObj -TimeoutSec 10 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            $consecutiveErrors++
            if ($consecutiveErrors -ge 3) {
                # Network recovery: re-probe gateways and re-register
                $consecutiveErrors = 0
                try {
                    foreach ($gw in $gateways) {
                        try {
                            $resp2 = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
                            if ($resp2) {
                                $serverUrl = $gw.Url
                                $activeGatewayName = $gw.Name
                                $global:hbServerUrl = $serverUrl
                                $global:hbActiveGatewayName = $activeGatewayName
                                break
                            }
                        } catch {}
                    }
                    $reRegPayload = @{ pin = $pin; host = $env:COMPUTERNAME; region = $region; version = "v036" } | ConvertTo-Json
                    Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
                } catch {}
                Start-Sleep -Seconds 10
            } else {
                Start-Sleep -Seconds 2
            }
        }

        # Direct KeepAlive to rd.gincz.com every ~25 seconds (Guaranteed delivery)
        $loopCount++
        if ($loopCount -ge 5) {
            $loopCount = 0
            try {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v036&rd_id=$rustdeskId&gw=$([System.Uri]::EscapeDataString($activeGatewayName))&region=$region"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
            try {
                $reRegPayload = @{ pin = $pin; host = $env:COMPUTERNAME; region = $region; version = "v036" } | ConvertTo-Json
                Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }

        # Periodic RDP & Auto-Update Check: Initial check after 4 loops (~20s), hourly RDP refresh, update every ~6h
        $updateCheckCounter++
        if ($updateCheckCounter -eq 4 -or ($updateCheckCounter % 720 -eq 0)) {
            Enable-RemoteDesktopSupport
        }
        if ($updateCheckCounter -eq 4 -or $updateCheckCounter -ge 4320) {
            if ($updateCheckCounter -ge 4320) { $updateCheckCounter = 5 }
            Check-GINAgentUpdate -currentVer "v036" -activeRegion $region
        }

        Start-Sleep -Seconds 5
    }

} catch {
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host "  [!] CRITICAL ERROR GIN-AGENT v036:" -ForegroundColor Red
    Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Line:    $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}

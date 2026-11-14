<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Win-Optimizer v047 - Windows 7/8/10/11 Ultimate Optimizer [ VladiMIR ^& Antigravity ]

:: Detect PowerShell location (supports x86, x64, Sysnative on 32-bit processes in 64-bit OS)
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:: Auto-Elevation: Ensure Full Administrator Privileges on Windows 7 / 8 / 10 / 11 (32-bit and 64-bit)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges for GIN-Win-Optimizer v047...
    copy /y "%~f0" "%TEMP%\GIN-Win-Optimizer_v047.cmd" >nul 2>&1
    if exist "%TEMP%\GIN-Win-Optimizer_v047.cmd" (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%TEMP%\GIN-Win-Optimizer_v047.cmd""' -Verb RunAs"
    ) else (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs"
    )
    exit /b
)

:: Immediately kill UAC to absolute zero in registry (EnableLUA=0, slider to bottom, no prompts ever)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ValidateAdminCodeSignatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections /t REG_DWORD /d 1 /f >nul 2>&1

:: Pass script path safely through environment variable to avoid quote escaping issues
set "GIN_OPT_SCRIPT=%~f0"

:: Launch GUI cleanly in background (hidden console) for single-window experience across Win 7 / 8 / 10 / 11
start "" "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "try { $p = $env:GIN_OPT_SCRIPT; if (-not $p -or -not (Test-Path $p)) { $p = '%~f0' }; $raw = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8); Invoke-Expression $raw } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'Optimizer Error') }"
exit /b
#>
# ==============================================================================
#  GIN-WIN-OPTIMIZER PLUS                                          v047
#  Windows 7/8/10/11 Ultimate Optimizer & Deep Cleaner
#  Author: Vladimir Bulantsev (GinCz) & AI [VladiMIR + AI]
#  License: Freeware (Lifetime Free for Personal & Business Use)
#  Telegram Support: https://t.me/GinCz
# ==============================================================================
# ==============================================================================
#  SELF-HEALING & ENVIRONMENT CLEANUP (Removes past artifacts & phantom icons)
# ==============================================================================
try {
    # 1. Purge rogue phantom Desktop\NameSpace key (removes blank white ghost icon from Desktop)
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue

    # 2. Clean stray redirection artifacts (e.g. 'v027)', temporary fix scripts)
    $cleanPaths = @(
        (Get-Location).Path,
        [Environment]::GetFolderPath('Desktop'),
        'D:\MEGA\WIN-FLASH\Util-WINDOWS',
        'V:\WIN-FLASH\Util-WINDOWS'
    ) | Select-Object -Unique
    foreach ($cp in $cleanPaths) {
        if ($cp -and (Test-Path $cp)) {
            Get-ChildItem -Path $cp -Filter "*v029)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $cp -Filter "*v030)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $cp -Filter "*v031)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $cp -Filter "*v032)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $cp -Filter "*v033)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $cp -Filter "*v034)*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $cp "Fix-Phantom-Desktop-Icon.cmd") -Force -ErrorAction SilentlyContinue
        }
    }

    # 2.1 Autonomous Purge of Legacy Start Menu Applets (Accessibility, Accessories, Speech, Math, Steps, Fax, Character Map)
    try {
        $startRoots = @(
            "C:\ProgramData\Microsoft\Windows\Start Menu\Programs",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
            "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
        )
        $junkShortcuts = @("Speech Recognition.lnk", "Math Input Panel.lnk", "Steps Recorder.lnk", "Windows Fax and Scan.lnk", "Character Map.lnk")
        foreach ($root in $startRoots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($fn in @("Accessibility", "Accessories")) {
                $dirPath = Join-Path $root $fn
                if (Test-Path $dirPath) {
                    foreach ($junk in $junkShortcuts) {
                        Get-ChildItem -Path $dirPath -Filter $junk -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    $sysTools = Join-Path $dirPath "System Tools"
                    if ((Test-Path $sysTools) -and (Get-ChildItem $sysTools -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                        Remove-Item -Path $sysTools -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    if ($fn -eq "Accessibility") {
                        Remove-Item -Path $dirPath -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    if ($fn -eq "Accessories") {
                        $rem = Get-ChildItem -Path $dirPath -Recurse -File -Force -ErrorAction SilentlyContinue
                        if ($rem.Count -eq 0 -or ($rem | Where-Object { $_.Name -notmatch "(?i)Notepad|Paint|Wordpad|Remote Desktop|Snipping" }).Count -eq 0) {
                            Remove-Item -Path $dirPath -Force -Recurse -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }
    } catch {}

    # 3. Autonomous Taskbar Unpin: Purge Microsoft Edge and Internet Explorer from Taskbar (AppsFolder COM + shortcuts)
    try {
        $ruUnpin = [char]0x043E + [char]0x0442 + [char]0x043A + [char]0x0440 + [char]0x0435 + [char]0x043F + [char]0x0438 + [char]0x0442 + [char]0x044C
        $ruPanel = [char]0x043F + [char]0x0430 + [char]0x043D + [char]0x0435 + [char]0x043B
        $appsFolder = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
        if ($appsFolder) {
            foreach ($item in $appsFolder.Items()) {
                if ($item.Name -like "*Edge*" -or $item.Path -like "*Edge*" -or $item.Path -like "*iexplore*" -or $item.Name -like "*Internet Explorer*") {
                    foreach ($verb in $item.Verbs()) {
                        $cleanVerb = ($verb.Name -replace "&", "").Trim()
                        if (($cleanVerb -match "(?i)unpin.*taskbar") -or ($cleanVerb -match "(?i)odepnout.*panel") -or ($cleanVerb -match "$ruUnpin.*$ruPanel")) {
                            $verb.DoIt()
                        }
                    }
                }
            }
        }
    } catch {}

    # 4. Autonomous Taskbar Default Layout Lock: Deploy empty PinList to permanently prevent Windows from ever auto-pinning Edge
    try {
        $layoutXml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`r`n<LayoutModificationTemplate xmlns=`"http://schemas.microsoft.com/Start/2014/LayoutModification`" xmlns:defaultlayout=`"http://schemas.microsoft.com/Start/2014/FullDefaultLayout`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`" xmlns:taskbar=`"http://schemas.microsoft.com/Start/2014/TaskbarLayout`" Version=`"1`">`r`n  <CustomTaskbarLayoutCollection PinListPlacement=`"Replace`">`r`n    <defaultlayout:TaskbarLayout>`r`n      <taskbar:TaskbarPinList />`r`n    </defaultlayout:TaskbarLayout>`r`n  </CustomTaskbarLayoutCollection>`r`n</LayoutModificationTemplate>"
        $layoutPaths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml",
            "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
        )
        foreach ($lp in $layoutPaths) {
            $ldir = [System.IO.Path]::GetDirectoryName($lp)
            if (-not (Test-Path $ldir)) { New-Item -Path $ldir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
            [System.IO.File]::WriteAllText($lp, $layoutXml, [System.Text.Encoding]::UTF8)
        }
    } catch {}

    # 5. Autonomous Windows Update Lock: Direct native reg.exe execution matching Dism++ "Never check for updates" strictly
    $wuCommands = @(
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d 0 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "DetectionFrequencyEnabled" /t REG_DWORD /d 0 /f /reg:64',
        'delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "CachedAUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DoNotCreateTaskbarShortcut" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DoNotCreateDesktopShortcut" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "DoNotCreateTaskbarShortcut" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "DoNotCreateDesktopShortcut" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "DisableEdgeDesktopShortcutCreation" /t REG_DWORD /d 1 /f /reg:64'
    )
    # Pre-enable UNC and LinkedConnections so launching from network shares never drops
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    # Enforce TOTAL Zero-UAC (EnableLUA=0, Slider to absolute minimum "Never Notify", zero prompts)
    $sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (-not (Test-Path $sysPol)) { New-Item -Path $sysPol -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $sysPol -Name "EnableLUA" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "FilterAdministratorToken" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "EnableInstallerDetection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "ValidateAdminCodeSignatures" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysPol -Name "EnableVirtualization" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    # Ensure LanmanWorkstation Parameters and ServiceDll are 100% intact (prevent Error 2 / dropping network drives)
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "ServiceDll" -Value "%SystemRoot%\System32\wkssvc.dll" -Type ExpandString -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Command Processor" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    New-Item -Path "HKCU:\Software\Microsoft\Command Processor" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    foreach ($cmd in $wuCommands) {
        $cmdNative = $cmd -replace '\s*/reg:(64|32)', ''
        cmd.exe /c "reg.exe $cmdNative" 2>$null | Out-Null
        if ([Environment]::Is64BitOperatingSystem) {
            cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
        }
    }
} catch {}


# ==============================================================================

#  GIN-WIN-OPTIMIZER PLUS                                          v047

#  Rule: Strict Version Increment Mandate (v032 -> v047)

#  Trilingual: [1] English | [2] Čeština | [3] Русский

#  Author: Vladimir Bulantsev (GinCz) & Antigravity

#  Encoding: UTF-8 (No BOM) | Single-Window WPF Polyglot Hybrid CMD/PowerShell

# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$OutputEncoding           = [System.Text.Encoding]::UTF8

# Hide console window completely to guarantee a single unified modern window

Add-Type -MemberDefinition @"

[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();

[DllImport("kernel32.dll")] public static extern bool Beep(uint dwFreq, uint dwDuration);

"@ -Name "Win32Console" -Namespace "Win32Utils" -ErrorAction SilentlyContinue

$hConsole = [Win32Utils.Win32Console]::GetConsoleWindow()

if ($hConsole -ne [IntPtr]::Zero) {

    [Win32Utils.Win32Console]::ShowWindowAsync($hConsole, 0) | Out-Null

}

Add-Type -AssemblyName PresentationFramework

Add-Type -AssemblyName PresentationCore

Add-Type -AssemblyName WindowsBase

Add-Type -AssemblyName System.Drawing

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

# Trilingual Localization Dictionary

$t = @{

    "en" = @{

        "Title" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"

        "HeaderTitle" = "Computer Information"

        "HeaderSub" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"

        "HostFormat" = "Host: local | Device: {0} | Windows: {1} | IP: {2}"

        "Presets" = "Presets:"

        "BtnSelectAll" = "✓ Select All (Max Clean)"

        "BtnDeselectAll" = "✗ Deselect All"

        "BtnPresetOffice" = "🏢 Office (Keep OneDrive)"

        "BtnPresetGaming" = "⚡ Gaming (Keep Xbox)"

        "BtnStart" = "🚀 OPTIMIZE"

        "BtnStartBottom" = "🚀 Optimize"

        "BtnExport" = "💾 Export Log"

        "BtnExit" = "Exit"

        "BtnSkip" = "⏭ SKIP STEP"

        "BtnClear" = "🧹 Clear"

        "BtnCopy" = "📋 Copy"

        "StatusReady" = "Ready. Configure checkboxes and click OPTIMIZE."

        "StatusRunning" = "Optimizing... Progress:"

        "StatusDone" = "Optimization Complete! Total tasks executed:"

        "grpPrivacy" = "Privacy & Diagnostics Telemetry"

        "grpSecurity" = "Security, UAC & SmartScreen"

        "grpCloud" = "Cloud & Consumer Features"

        "grpEdge" = "Microsoft Edge Optimization"

        "grpUI" = "Explorer, Desktop & Taskbar (Dism++ Tweaks)"

        "grpContextMenu" = "Context Menu Cleanup (Right-Click)"

        "grpWinUpdate" = "Windows Update, BSOD & System"

        "grpApps" = "App Debloater & Provisioned Packages"

        "grpServices" = "System Performance & Services"

        "grpClean" = "Cache, Temp & Component Cleaning"

        "chk_telem_diagtrack" = "Disable Connected User Experiences & Telemetry (DiagTrack)"

        "chk_telem_dmwappush" = "Disable WAP Push Message Routing Service (dmwappushservice)"

        "chk_telem_wer" = "Disable Windows Error Reporting Service (WerSvc)"

        "chk_telem_allow_telem" = "Disable Diagnostics Data Collection via Policy (AllowTelemetry = 0)"

        "chk_telem_ad_id" = "Disable Advertising ID for all user profiles"

        "chk_telem_inking" = "Disable Inking & Typing Data Personalization"

        "chk_telem_activity" = "Disable Activity History (Timeline) & Cloud Sync"

        "chk_telem_location" = "Disable Geolocation & Location Sensor Service (lfsvc)"

        "chk_telem_feedback" = "Disable Windows Feedback Surveys & Prompts"

        "chk_telem_tasks" = "Disable Scheduled Telemetry & Customer Experience Tasks"

        "chk_telem_cortana" = "Disable and Block Cortana Assistant in Registry"

        "chk_net_wifi_privacy" = "Wi-Fi: Disable Random Hardware Addresses (MAC) & Disable Hotspot 2.0 Online Sign-Up"

        "chk_sec_uac_quiet" = "Total Zero-UAC (Disable UAC completely: EnableLUA=0, Slider to zero, no elevation prompts)"

        "chk_sec_admin_approval" = "Enable Admin Approval Mode for built-in Administrator account"

        "chk_sec_smartscreen" = "Disable SmartScreen filter for apps and File Explorer"

        "chk_sec_open_file_warning" = "Disable 'Open File - Security Warning' for downloaded files"

        "chk_cloud_onedrive" = "Completely remove Microsoft OneDrive (UNCHECK TO KEEP ONEDRIVE)"

        "chk_cloud_settings_sync" = "Disable Settings Synchronization with Microsoft Account"

        "chk_cloud_bing_search" = "Disable Bing Web Search in Start Menu (keep local search only)"

        "chk_cloud_spotlight" = "Disable Windows Spotlight lock screen ads & suggestions"

        "chk_cloud_consumer_features" = "Block automatic background installation of sponsored apps"

        "chk_edge_background" = "Prevent Edge from running in background after closing window"

        "chk_edge_startup_boost" = "Disable Edge Startup Boost (frees RAM at boot)"

        "chk_edge_telemetry" = "Disable Edge diagnostics and telemetry data reporting"

        "chk_edge_sidebar" = "Disable Edge sidebar, shopping suggestions, and built-in AI"

        "chk_edge_prelaunch" = "Disable Edge prelaunch during Windows startup"

        "chk_edge_first_run" = "Prevent Edge First Run Experience and welcome page"

        "chk_edge_unpin" = "Unpin Edge & Internet Explorer from Taskbar, block auto-reinstall"
        "chk_browser_updaters" = "Stop background updaters & purge Update folders (Chrome, Brave, Cent Browser)"

        "chk_reloc_documents" = "Relocate Documents folder to D:\DOCS (migrates files & shell paths)"
        "chk_reloc_desktop" = "Relocate Desktop folder to D:\DOCS\desktop (migrates files & shell paths)"
        "BtnReboot" = "⚡ REBOOT"
        "chk_ui_widgets" = "Disable and remove Windows 11 Widgets & News (TaskbarDa & WebExperience)"

        "chk_ui_teams_chat" = "Remove Microsoft Teams Chat icon from Taskbar"

        "chk_ui_copilot" = "Disable Windows Copilot AI (Taskbar button and side panel)"

        "chk_ui_recall" = "Disable Windows Recall AI (background screen snapshot taking)"

        "chk_ui_start_ads" = "Clean Start Menu: Remove Recommended section, suggestions & recent history"

        "chk_ui_explorer_ads" = "Disable OneDrive and Office sync promo ads in File Explorer"

        "chk_ui_welcome_screen" = "Disable 'Let\'s finish setting up your device' welcome screen"
        "chk_ui_lockscreen_clean" = "Lock screen: Disable fun facts/ads, show lock screen background on sign-in"
        "chk_ui_color_accent_theme" = "Color scheme: Dark system theme, Steel Blue accent on Taskbar/Start & Titlebars, Transparency Off"
        "chk_ui_mouse_inverted_large" = "Mouse pointer: Inverted (large) system scheme with pointer shadow"

        "chk_ui_classic_context" = "Restore Windows 10 Classic Context Menu (skip 'Show More Options')"

        "chk_ui_hide_search" = "Hide Search box and icon from Taskbar completely"

        "chk_ui_hide_taskview" = "Hide Task View button from Taskbar"

        "chk_ui_show_all_tray_icons" = "Always show all icons in system tray (never hide behind chevron)"

        "chk_ui_never_combine_taskbar" = "Never combine taskbar buttons (show window labels separately)"

        "chk_ui_show_this_pc" = "Always display 'This PC' icon on Desktop"

        "chk_ui_clock_24h_seconds" = "System Tray Clock: 24-hour format and display seconds"
        "chk_ui_region_time_czech" = "Set Region to Czech Republic, TimeZone (Prague, UTC+1), Auto-DST & Date/Time Formats"

        "chk_ui_lang_keyboards" = "Preferred Keyboards: English #1 (Default), Czech #2 (if present), Russian #2/#3"

        "chk_ui_regional_date_format" = "Regional Formats: Russian (ru-RU), Date dd.MM.yyyy, 24h Time HH:mm:ss, Monday"

        "chk_tb_small_icons" = "Use small taskbar buttons"

        "chk_tb_lock" = "Lock the Taskbar"

        "chk_tb_hide_action_center" = "Hide Action Center in system tray"

        "chk_tb_hide_people" = "Hide People button on taskbar"

        "chk_exp_open_this_pc" = "Open File Explorer directly to 'This PC' instead of Quick Access"

        "chk_ui_folder_view_list_sort_type" = "Set default folder view to List and sort by Type for all folders"

        "chk_exp_hide_user_folders" = "Hide 6 user folders (Videos, Music, 3D, etc.) from This PC window"

        "chk_exp_no_shortcut_suffix" = "Do not append '- Shortcut' text when creating shortcuts"

        "chk_exp_hide_quick_access_recent" = "Do not show recent files or frequent folders in Quick Access"

        "chk_exp_show_full_path" = "Display full folder path in File Explorer title bar"

        "chk_exp_separate_process" = "Launch folder windows in a separate process (prevents desktop crash)"

        "chk_exp_hide_nav_libraries" = "Hide 'Libraries' from File Explorer navigation pane"

        "chk_desktop_show_user_folder" = "Show User Profile Folder on Desktop"

        "chk_ctx_cleanup_bloat" = "Remove context menu bloat (Troubleshoot compatibility, Paint 3D, Disc Burn, etc.)"

        "chk_ctx_winrar_email" = "WinRAR: Hide 'Compress and email...' clutter in context menu"

        "chk_wu_disable_auto_updates" = "Configure Windows Update check: Never check for updates [Dism++ standard / Manual Mode]"

        "chk_wu_exclude_drivers" = "Windows Update does not include drivers [ExcludeWUDriversInQualityUpdate]"

        "chk_wu_exclude_msrt" = "Windows Update does not include Malicious Software Removal Tool (MSRT)"

        "chk_sys_bsod_no_autoreboot" = "Disable automatic reboot on BSOD (allow reading stop code)"

        "chk_sys_small_minidump" = "Configure small kernel memory minidump (saves SSD space)"

        "chk_sys_fast_startup_off" = "Disable Fast Startup (prevents kernel corruption and driver sleep bugs)"

        "chk_sys_disable_remote_assist" = "Disable Remote Assistance (fAllowToGetHelp = 0)"

        "chk_sys_enable_photo_viewer" = "Restore classic Windows Photo Viewer (fast & lightweight)"

        "chk_sys_notepad_tweaks" = "Notepad: Enable Word Wrap and Status Bar by default"

        "chk_app_xbox" = "Remove Xbox packages (Xbox App, GameBar - uncheck if gaming PC)"

        "chk_app_gamebar_disable" = "Disable Xbox Game Bar recording & Controller button shortcut"

        "chk_app_games" = "Remove promo games (Candy Crush, Solitaire Collection, TikTok stubs)"

        "chk_app_news" = "Remove MSN News, Weather, Sports, Money / Finance apps"

        "chk_app_office_stub" = "Remove Microsoft 365 / GetOffice stub"

        "chk_app_clipchamp" = "Remove pre-installed Clipchamp video editor"

        "chk_app_people" = "Remove unused People components and legacy mail stub"

        "chk_app_feedback" = "Remove Feedback Hub app"

        "chk_app_get_help" = "Remove Get Help and Tips apps"

        "chk_app_phone" = "Remove Phone Link (uncheck if using smartphone integration)"

        "chk_srv_sysmain" = "Disable SysMain / Superfetch service (extends SSD lifespan)"

        "chk_srv_indexing" = "Disable Windows Search indexing service (reduces CPU/disk spikes)"

        "chk_srv_remote_reg" = "Disable Remote Registry service (security hardening)"

        "chk_srv_delivery_opt" = "Disable Delivery Optimization P2P bandwidth sharing"

        "chk_srv_reserved_storage" = "Disable Windows Reserved Storage (frees ~7 GB on disk)"

        "chk_srv_hibernation" = "Disable hibernation & delete hiberfil.sys (frees GBs on SSD)"

        "chk_srv_power_plan" = "Activate Ultimate Performance power plan"

        "chk_srv_power_sleep_screen" = "Display & Sleep timeouts: Display Never, Sleep 30m (DC) / Never (AC), Screensaver 10m"

        "chk_srv_ssd_trim" = "Deep SSD & NVMe M.2 Optimization (TRIM, NTFS Cache, Disable LastAccess/SysMain)"
        "chk_srv_pagefile_auto" = "Smart dynamic pagefile on C: (auto-scaled by RAM & free SSD space)"

        "chk_srv_network_offload" = "Disable network Task Offload & Chimney (prevents latency spikes)"

        "chk_srv_visual_appearance" = "Visual effects: Adjust for best appearance (enable all animations, shadows, font smoothing)"

        "chk_srv_pca" = "Disable Program Compatibility Assistant service (PcaSvc)"

        "chk_srv_trkwks" = "Disable Distributed Link Tracking Client service (TrkWks)"

        "chk_srv_iphlpsvc" = "Disable IP Helper service (iphlpsvc - uncheck if using IPv6 VPNs)"
        "chk_srv_oem_lenovo" = "Purge / Disable Lenovo ImController bloat, services & background tasks"
        "chk_srv_intel_graphics" = "Disable Intel HD Graphics background services, tray & hotkey modules"
        "chk_srv_conexant_audio" = "Disable Conexant / Synaptics Audio background services (CxAudioSvc, CxUIUSvc, CxUtilSvc)"

        "chk_clean_user_temp" = "Clean user temporary files (%TEMP% and LocalAppData\\Temp)"

        "chk_clean_win_temp" = "Clean system temporary directory (C:\\Windows\\Temp)"

        "chk_clean_soft_dist" = "Clean Windows Update download cache (SoftwareDistribution\\Download)"

        "chk_clean_thumb_cache" = "Clean thumbnail cache databases (thumbcache_*.db)"

        "chk_clean_shaders_dns" = "Clean DirectX Shader Cache & Flush DNS"

        "chk_clean_event_logs" = "Clear all Windows Event Logs"

        "chk_clean_recycle_bin" = "Empty Recycle Bin for all local drives"

        "chk_clean_cleanmgr" = "Run automated system disk cleanup (cleanmgr)"

        "chk_deep_dism_repair" = "Check & repair component store via DISM (slow - медленно)"

        "chk_deep_dism_resetbase" = "Deep clean WinSxS folder: ResetBase (slow - медленно)"

        "chk_deep_sfc_compact" = "Run SFC Scannow file verification & CompactOS (slow - медленно)"

    }

    "cs" = @{

        "Title" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"
        "HeaderTitle" = "Údaje o počítači"
        "HeaderSub" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"

        "HostFormat" = "Host: local | Zařízení: {0} | Windows: {1} | IP: {2}"

        "Presets" = "Předvolby:"

        "BtnSelectAll" = "✓ Vybrat vše (Max. čištění)"

        "BtnDeselectAll" = "✗ Zrušit výběr"

        "BtnPresetOffice" = "🏢 Kancelář (Ponechat OneDrive)"

        "BtnPresetGaming" = "⚡ Hraní her (Ponechat Xbox)"

        "BtnStart" = "🚀 OPTIMALIZOVAT"

        "BtnStartBottom" = "🚀 Optimalizovat"

        "BtnExport" = "💾 Export protokolu"

        "BtnExit" = "Konec"

        "BtnSkip" = "⏭ PŘESKOČIT KROK"

        "BtnClear" = "🧹 Vyčistit"

        "BtnCopy" = "📋 Kopírovat"

        "StatusReady" = "Připraveno. Nastavte volby a klikněte na OPTIMALIZOVAT."

        "StatusRunning" = "Probíhá optimalizace... Průběh:"

        "StatusDone" = "Optimalizace byla úspěšně dokončena! Celkem úloh:"

        "grpPrivacy" = "Soukromí a diagnostická telemetrie"

        "grpSecurity" = "Zabezpečení, UAC a SmartScreen"

        "grpCloud" = "Cloud a spotřebitelské funkce"

        "grpEdge" = "Optimalizace Microsoft Edge"

        "grpUI" = "Průzkumník, Plocha a Hlavní panel (Dism++)"

        "grpContextMenu" = "Čištění kontextové nabídky (Pravé tlačítko)"

        "grpWinUpdate" = "Windows Update, BSOD a Systém"

        "grpApps" = "Odstranění aplikací a zbytečného bloatware"

        "grpServices" = "Výkon systému a optimalizace služeb"

        "grpClean" = "Čištění mezipaměti a hluboký úklid"

        "chk_telem_diagtrack" = "Zakázat Telemetrii a sledování uživatelských zkušeností (DiagTrack)"

        "chk_telem_dmwappush" = "Zakázat službu směrování zpráv WAP Push (dmwappushservice)"

        "chk_telem_wer" = "Zakázat službu Zasílání zpráv o chybách systému Windows (WerSvc)"

        "chk_telem_allow_telem" = "Zakázat sběr diagnostických dat pomocí zásad (AllowTelemetry = 0)"

        "chk_telem_ad_id" = "Zakázat reklamní identifikátor (Advertising ID) pro všechny účty"

        "chk_telem_inking" = "Zakázat přizpůsobení psaní rukou a zadávání na klávesnici"

        "chk_telem_activity" = "Zakázat historii aktivit (časovou osu) a cloudovou synchronizaci"

        "chk_telem_location" = "Zakázat geolokaci a službu snímače polohy (lfsvc)"

        "chk_telem_feedback" = "Zakázat dotazníky zpětné vazby systému Windows"

        "chk_telem_tasks" = "Zakázat naplánované úlohy zákaznické zkušenosti (CEIP) a telemetrie"

        "chk_telem_cortana" = "Zakázat a zablokovat hlasovou asistentku Cortana v registru"

        "chk_net_wifi_privacy" = "Wi-Fi: Vypnout náhodné hardwarové adresy (MAC) a vypnout Hotspot 2.0 Online Sign-Up"

        "chk_sec_uac_quiet" = "Úplné vypnutí UAC (Řízení uživatelských účtů na nulu: EnableLUA=0, jezdec na nulu, bez výzev)"

        "chk_sec_admin_approval" = "Povolit režim schvalování správcem pro vestavěný účet Administrator"

        "chk_sec_smartscreen" = "Zakázat filtr SmartScreen pro aplikace a Průzkumník souborů"

        "chk_sec_open_file_warning" = "Zakázat varování 'Otevřít soubor - varování zabezpečení' pro stažené soubory"

        "chk_cloud_onedrive" = "Zcela odinstalovat Microsoft OneDrive (ZRUSTE PRO ZACHOVÁNÍ)"

        "chk_cloud_settings_sync" = "Zakázat synchronizaci nastavení s účtem Microsoft"

        "chk_cloud_bing_search" = "Zakázat vyhledávání Bing v nabídce Start (pouze místní hledání)"

        "chk_cloud_spotlight" = "Zakázat Windows Spotlight (reklamy na zamykací obrazovce)"

        "chk_cloud_consumer_features" = "Blokovat automatickou instalaci sponzorovaných aplikací na pozadí"

        "chk_edge_background" = "Zabránit běhu prohlížeče Edge na pozadí po zavření okna"

        "chk_edge_startup_boost" = "Zakázat funkci Startup Boost u Edge (uvolní RAM při startu)"

        "chk_edge_telemetry" = "Zakázat diagnostická data a telemetrii v Microsoft Edge"

        "chk_edge_sidebar" = "Zakázat postranní panel Edge, nákupní tipy a integrovanou AI"

        "chk_edge_prelaunch" = "Zakázat předběžné spouštění Microsoft Edge při startu Windows"

        "chk_edge_first_run" = "Zabránit zobrazování uvítací stránky prvního spuštění v Edge"

        "chk_edge_unpin" = "Odepnout Edge a Internet Explorer z hlavního panelu, zablokovat reinstalaci"
        "chk_browser_updaters" = "Zastavit aktualizace na pozadí a smazat složky Update (Chrome, Brave, Cent Browser)"

        "chk_reloc_documents" = "Přesunout složku Dokumenty do D:\DOCS (migrace souborů a cest)"
        "chk_reloc_desktop" = "Přesunout složku Plocha do D:\DOCS\desktop (migrace souborů a cest)"
        "BtnReboot" = "⚡ REBOOT"
        "chk_ui_widgets" = "Zakázat a odebrat Widgety a Zprávy Windows 11 (TaskbarDa a WebExperience)"

        "chk_ui_teams_chat" = "Odstranit ikonu Chatu Microsoft Teams z hlavního panelu"

        "chk_ui_copilot" = "Zakázat Windows Copilot AI (tlačítko na liště a boční panel)"

        "chk_ui_recall" = "Zakázat Windows Recall AI (pořizování snímků obrazovky na pozadí)"

        "chk_ui_start_ads" = "Vyčistit nabídku Start: Skrýt sekci Doporučené, tipy a historii"

        "chk_ui_explorer_ads" = "Zakázat reklamní oznámení OneDrive a Office v Průzkumníku"

        "chk_ui_welcome_screen" = "Zakázat obrazovku 'Dokončete nastavení zařízení' po aktualizaci"
        "chk_ui_lockscreen_clean" = "Zamykací obrazovka: zakázat tipy/reklamy, zobrazit pozadí na přihlašovací obrazovce"
        "chk_ui_color_accent_theme" = "Barevné schéma: tmavý systémový motiv, ocelově modrý akcent na hlavním panelu a záhlaví, vypnout průhlednost"
        "chk_ui_mouse_inverted_large" = "Ukazatel myši: Inverzní (velké) systémové schéma se stínem ukazatele"

        "chk_ui_classic_context" = "Obnovit klasické kontextové menu Windows 10 (bez 'Zobrazit více')"

        "chk_ui_hide_search" = "Zcela skrýt vyhledávací pole a ikonu hledání z hlavního panelu"

        "chk_ui_hide_taskview" = "Skrýt tlačítko Zobrazení úloh (Task View) z hlavního panelu"

        "chk_ui_show_all_tray_icons" = "Vždy zobrazovat všechny ikony v oznamovací oblasti (neskrývat za šipku)"

        "chk_ui_never_combine_taskbar" = "Nikdy neseskupovat tlačítka hlavního panelu (Combine: Never)"

        "chk_ui_show_this_pc" = "Vždy zobrazovat ikonu 'Tento počítač' na ploše"

        "chk_ui_clock_24h_seconds" = "Hodiny v oznamovací oblasti: 24hodinový formát a sekundy"
        "chk_ui_region_time_czech" = "Nastavit region Česko, časové pásmo (Praha, UTC+1), letní čas a formát data a času"

        "chk_ui_lang_keyboards" = "Rozložení klávesnic: Angličtina #1 (Výchozí), Čeština #2 (je-li přítomna), Ruština #2/#3"

        "chk_ui_regional_date_format" = "Formát dat: Ruština (ru-RU), datum dd.MM.yyyy, čas 24h HH:mm:ss, pondělí"

        "chk_tb_small_icons" = "Použít malé ikony na hlavním panelu"

        "chk_tb_lock" = "Uzamknout hlavní panel"

        "chk_tb_hide_action_center" = "Skrýt Centrum akcí v oznamovací oblasti"

        "chk_tb_hide_people" = "Skrýt tlačítko Lidé na hlavním panelu"

        "chk_exp_open_this_pc" = "Otevírat Průzkumník souborů rovnou na 'Tento počítač' místo Rychlého přístupu"

        "chk_ui_folder_view_list_sort_type" = "Nastavit výchozí zobrazení složek na Seznam a řazení podle typu"

        "chk_exp_hide_user_folders" = "Skrýt 6 uživatelských složek (Videa, Hudba, 3D atd.) v okně Tento počítač"

        "chk_exp_no_shortcut_suffix" = "Nepřidávat text '- zástupce' při vytváření nových zástupců"

        "chk_exp_hide_quick_access_recent" = "Nezobrazovat nedávné soubory ani časté složky v Rychlém přístupu"

        "chk_exp_show_full_path" = "Zobrazovat úplnou cestu v záhlaví Průzkumníka souborů"

        "chk_exp_separate_process" = "Spouštět složky v samostatném procesu (ochrana před pádem plochy)"

        "chk_exp_hide_nav_libraries" = "Skrýt položku Knihovny z navigačního panelu Průzkumníka"

        "chk_desktop_show_user_folder" = "Zobrazit uživatelskou složku profilu na ploše"

        "chk_ctx_cleanup_bloat" = "Odstranit zbytečnosti z kontextového menu (Kompatibilita, Malování 3D atd.)"

        "chk_ctx_winrar_email" = "WinRAR: Skrýt položky 'Komprimovat a odeslat emailem...' v kontextovém menu"

        "chk_wu_disable_auto_updates" = "Zcela zakázat automatické aktualizace Windows (pouze ručně / vypnout wuauserv, UsoSvc, dosvc, úlohy)"

        "chk_wu_exclude_drivers" = "Vyloučit aktualizace ovladačů hardwaru ze služby Windows Update"

        "chk_wu_exclude_msrt" = "Vyloučit stahování nástroje pro odstranění škodlivého softwaru (MSRT)"

        "chk_sys_bsod_no_autoreboot" = "Zakázat automatický restart při modré smrti BSOD (pro zobrazení chyby)"

        "chk_sys_small_minidump" = "Nastavit malý výpis paměti Minidump při havárii (šetří místo na SSD)"

        "chk_sys_fast_startup_off" = "Zakázat Rychlé spouštění (ochrana před poškozením jádra a chybami spánku)"

        "chk_sys_disable_remote_assist" = "Zakázat Vzdálenou pomoc systému Windows (fAllowToGetHelp = 0)"

        "chk_sys_enable_photo_viewer" = "Obnovit klasický prohlížeč fotografií Windows Photo Viewer"

        "chk_sys_notepad_tweaks" = "Poznámkový blok: Ve výchozím stavu zapnout zalamování řádků a stavový řádek"

        "chk_app_xbox" = "Odstranit balíčky Xbox (Xbox App, GameBar - zrušte, pokud je PC herní)"

        "chk_app_gamebar_disable" = "Zakázat Xbox Game Bar záznam a zkratku tlačítka ovladače"

        "chk_app_games" = "Odstranit předinstalované hry (Candy Crush, Solitaire, TikTok zástupci)"

        "chk_app_news" = "Odstranit aplikace MSN Zprávy, Počasí, Sport a Finance"

        "chk_app_office_stub" = "Odstranit zástupce Microsoft 365 / GetOffice"

        "chk_app_clipchamp" = "Odstranit předinstalovaný editor videa Clipchamp"

        "chk_app_people" = "Odstranit nepoužívanou aplikaci Lidé a starého poštovního klienta"

        "chk_app_feedback" = "Odstranit aplikaci Centrum zpětné vazby (Feedback Hub)"

        "chk_app_get_help" = "Odstranit aplikace Získat nápovědu a Tipy"

        "chk_app_phone" = "Odstranit Propojení s telefonem (Phone Link - zrušte, pokud propojujete mobil)"

        "chk_srv_sysmain" = "Zakázat službu SysMain / Superfetch (šetří životnost SSD)"

        "chk_srv_indexing" = "Zakázat indexování Windows Search (snižuje zátěž procesoru a disku)"

        "chk_srv_remote_reg" = "Zakázat službu Vzdálený registr (RemoteRegistry - zabezpečení)"

        "chk_srv_delivery_opt" = "Zakázat optimalizaci doručování P2P aktualizací přes síť"

        "chk_srv_reserved_storage" = "Zakázat Vyhrazené úložiště Windows (uvolní ~7 GB místa na disku)"

        "chk_srv_hibernation" = "Zakázat hibernaci a smazat hiberfil.sys (uvolní gigabajty na SSD)"

        "chk_srv_power_plan" = "Aktivovat schéma napájení Maximální výkon (Ultimate Plan)"

        "chk_srv_power_sleep_screen" = "Časové limity obrazovky a spánku: Displej Nikdy, Spánek 30 min (baterie) / Nikdy (síť), Šetřič 10 min"

        "chk_srv_ssd_trim" = "Hloubková optimalizace pro SSD a NVMe M.2 (TRIM, NTFS mezipaměť, zákaz SysMain)"
        "chk_srv_pagefile_auto" = "Chytrý dynamický stránkovací soubor na C: (podle RAM a volného místa na SSD)"

        "chk_srv_network_offload" = "Zakázat síťový Task Offload a Chimney (ochrana před skoky latence)"

        "chk_srv_visual_appearance" = "Vizuální efekty: Nastavit pro nejlepší vzhled (všechny animace, stíny a vyhlazování)"

        "chk_srv_pca" = "Zakázat Pomocníka pro kompatibilitu programů (PcaSvc)"

        "chk_srv_trkwks" = "Zakázat Klienta sledování distribuovaných odkazů (TrkWks)"

        "chk_srv_iphlpsvc" = "Zakázat službu Pomocník protokolu IP (iphlpsvc - IPv6)"
        "chk_srv_oem_lenovo" = "Vyčistit / zakázat bloatware Lenovo ImController, služby a úlohy na pozadí"
        "chk_srv_intel_graphics" = "Zakázat služby Intel HD Graphics na pozadí, ikonu v liště a moduly kláves"
        "chk_srv_conexant_audio" = "Zakázat služby Conexant / Synaptics Audio na pozadí (CxAudioSvc, CxUIUSvc, CxUtilSvc)"

        "chk_clean_user_temp" = "Vyčistit uživatelské dočasné soubory (%TEMP% a LocalAppData\\Temp)"

        "chk_clean_win_temp" = "Vyčistit systémový adresář dočasných souborů (C:\\Windows\\Temp)"

        "chk_clean_soft_dist" = "Vyčistit mezipaměť aktualizací (SoftwareDistribution\\Download)"

        "chk_clean_thumb_cache" = "Vyčistit databáze miniatur souborů (thumbcache_*.db)"

        "chk_clean_shaders_dns" = "Vyčistit mezipaměť DirectX shaderů a vyprázdnit DNS cache"

        "chk_clean_event_logs" = "Vymazat všechny protokoly událostí systému Windows"

        "chk_clean_recycle_bin" = "Vysypat Koš pro všechny místní diskové jednotky"

        "chk_clean_cleanmgr" = "Spustit automatické systémové čištění disku (cleanmgr)"

        "chk_deep_dism_repair" = "Zkontrolovat a opravit integritu komponent DISM (slow - медленно)"

        "chk_deep_dism_resetbase" = "Provést hluboké vyčištění složky WinSxS: ResetBase (slow - медленно)"

        "chk_deep_sfc_compact" = "Provést ověření souborů SFC Scannow a CompactOS (slow - медленно)"

    }

    "ru" = @{

        "Title" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"

        "HeaderTitle" = "Данные о компьютере"

        "HeaderSub" = "GIN-Win-Optimizer v047 [VladiMIR + AI]"

        "HostFormat" = "Host: local | Устройство: {0} | Windows: {1} | IP: {2}"

        "Presets" = "Пресеты:"

        "BtnSelectAll" = "✓ Выбрать все (Макс. очистка)"

        "BtnDeselectAll" = "✗ Снять все"

        "BtnPresetOffice" = "🏢 Офис (Оставить OneDrive)"

        "BtnPresetGaming" = "⚡ Игры (Оставить Xbox)"

        "BtnStart" = "🚀 ОПТИМИЗИРОВАТЬ"

        "BtnStartBottom" = "🚀 Оптимизировать"

        "BtnExport" = "💾 Экспорт лога"

        "BtnExit" = "Выход"

        "BtnSkip" = "⏭ Пропустить шаг"

        "BtnClear" = "🧹 Очистить"

        "BtnCopy" = "📋 Копировать"

        "StatusReady" = "Готово к работе. Отметьте нужные пункты и нажмите ОПТИМИЗИРОВАТЬ."

        "StatusRunning" = "Выполняется оптимизация... Прогресс:"

        "StatusDone" = "Оптимизация успешно завершена! Выполнено задач:"

        "grpPrivacy" = "Приватность и диагностическая телеметрия"

        "grpSecurity" = "Безопасность, твики UAC и SmartScreen"

        "grpCloud" = "Облачные и потребительские функции"

        "grpEdge" = "Оптимизация Microsoft Edge"

        "grpUI" = "Проводник, Рабочий стол и Панель задач (Dism++)"

        "grpContextMenu" = "Очистка контекстного меню (ПКМ)"

        "grpWinUpdate" = "Windows Update, BSOD и Диагностика"

        "grpApps" = "Удаление предустановленных приложений и мусора"

        "grpServices" = "Производительность и системные службы"

        "grpClean" = "Очистка кэша, мусора и компонентов"

        "chk_telem_diagtrack" = "Отключить службу сбора телеметрии и пользовательского опыта (DiagTrack)"

        "chk_telem_dmwappush" = "Отключить службу маршрутизации WAP Push (dmwappushservice)"

        "chk_telem_wer" = "Отключить службу регистрации ошибок Windows (WerSvc)"

        "chk_telem_allow_telem" = "Отключить сбор диагностических данных через политики (AllowTelemetry = 0)"

        "chk_telem_ad_id" = "Отключить рекламный идентификатор (Advertising ID) для всех профилей"

        "chk_telem_inking" = "Отключить сбор данных рукописного ввода и ввода с клавиатуры"

        "chk_telem_activity" = "Отключить журнал действий (Timeline) и синхронизацию с облаком"

        "chk_telem_location" = "Отключить службу геолокации и датчиков местоположения (lfsvc)"

        "chk_telem_feedback" = "Отключить опросы и запросы отзывов Windows Feedback"

        "chk_telem_tasks" = "Отключить запланированные задачи программы улучшения качества (CEIP)"

        "chk_telem_cortana" = "Отключить и заблокировать голосовой ассистент Cortana в реестре"

        "chk_net_wifi_privacy" = "Wi-Fi: отключить случайные аппаратные адреса (MAC) и отключить Hotspot 2.0 Online Sign-Up"

        "chk_sec_uac_quiet" = "Полное отключение UAC (Контроль учетных записей на ноль: EnableLUA=0, ползунок в 0, без запросов)"

        "chk_sec_admin_approval" = "Включить режим одобрения администратором для встроенной учетной записи"

        "chk_sec_smartscreen" = "Отключить фильтр SmartScreen для приложений и Проводника"

        "chk_sec_open_file_warning" = "Отключить предупреждение «Открыть файл - предупреждение системы безопасности»"

        "chk_cloud_onedrive" = "Полностью удалить Microsoft OneDrive (СНИМИТЕ, ЧТОБЫ ОСТАВИТЬ ONEDRIVE)"

        "chk_cloud_settings_sync" = "Отключить синхронизацию параметров системы с учетной записью Microsoft"

        "chk_cloud_bing_search" = "Отключить поиск в интернете Bing Search в меню Пуск (оставить только локальный)"

        "chk_cloud_spotlight" = "Отключить Windows Spotlight (рекламу и советы на экране блокировки)"

        "chk_cloud_consumer_features" = "Заблокировать автоматическую фоновую загрузку стороннего мусора и игр"

        "chk_edge_background" = "Запретить Edge висеть и работать в фоне после закрытия окна"

        "chk_edge_startup_boost" = "Отключить ускорение запуска Edge (Startup Boost, освобождает память)"

        "chk_edge_telemetry" = "Отключить сбор диагностических данных и телеметрию в Edge"

        "chk_edge_sidebar" = "Отключить боковую панель Edge, рекламу покупок и встроенный ИИ"

        "chk_edge_prelaunch" = "Отключить предварительный запуск Edge при старте Windows"

        "chk_edge_first_run" = "Предотвратить показ страницы первого запуска Microsoft Edge"

        "chk_edge_unpin" = "Открепить значки Internet Explorer и Edge от панели задач и Рабочего стола"
        "chk_browser_updaters" = "Остановить фоновые службы и удалить папки Update (Chrome, Brave, Cent Browser)"

        "chk_reloc_documents" = "Переместить папку «Документы» в D:\DOCS (перенос файлов и путей)"
        "chk_reloc_desktop" = "Переместить «Рабочий стол» в D:\DOCS\desktop (перенос файлов и путей)"
        "BtnReboot" = "⚡ ПЕРЕЗАГРУЗКА"
        "chk_ui_widgets" = "Отключить и удалить Виджеты и Новости Windows 11 (TaskbarDa, Feeds, WebExperience)"

        "chk_ui_teams_chat" = "Убрать значок «Чат» Microsoft Teams с панели задач"

        "chk_ui_copilot" = "Отключить Windows Copilot AI (кнопку в панели задач и боковую панель)"

        "chk_ui_recall" = "Отключить Windows Recall AI (фоновый сбор снапшотов экрана)"

        "chk_ui_start_ads" = "Очистить Пуск: скрыть блок «Рекомендуем», недавние файлы, приложения и советы"

        "chk_ui_explorer_ads" = "Отключить рекламные уведомления OneDrive / Office в Проводнике"

        "chk_ui_welcome_screen" = "Отключить экран «Завершить настройку устройства» после обновлений"
        "chk_ui_lockscreen_clean" = "Экран блокировки: отключить факты/подсказки, показывать фон на экране входа"
        "chk_ui_color_accent_theme" = "Цветовая схема: тёмная тема, морской акцент в меню Пуск/панели задач и заголовках, без прозрачности"
        "chk_ui_mouse_inverted_large" = "Курсор мыши: Инверсная (крупная) системная схема с тенью указателя"

        "chk_ui_classic_context" = "Вернуть классическое компактное контекстное меню Windows 10 (без «Показать больше»)"

        "chk_ui_hide_search" = "Полностью убрать строку и значок поиска с панели задач (Searchbox = 0)"

        "chk_ui_hide_taskview" = "Скрыть кнопку «Просмотр задач» (Task View) с панели задач"

        "chk_ui_show_all_tray_icons" = "Всегда показывать все иконки в трее возле часов (не прятать под стрелку)"

        "chk_ui_never_combine_taskbar" = "Никогда не группировать кнопки панели задач (Combine: Never)"

        "chk_ui_show_this_pc" = "Всегда отображать значок «Этот компьютер» на Рабочем столе"

        "chk_ui_clock_24h_seconds" = "Часы в трее: 24-часовой формат и отображение секунд"
        "chk_ui_region_time_czech" = "Регион Чехия, часовой пояс (Прага), автопереход на летнее время и формат даты/времени"

        "chk_ui_lang_keyboards" = "Порядок клавиатур: Английский #1 (по умолч.), Чешский #2 (если есть), Русский #2/#3"

        "chk_ui_regional_date_format" = "Форматы данных: Регион Русский (ru-RU), дата dd.MM.yyyy, время 24ч HH:mm:ss, понедельник"

        "chk_tb_small_icons" = "Использовать маленькие кнопки на панели задач"

        "chk_tb_lock" = "Закрепить панель задач (защита от случайного сдвига)"

        "chk_tb_hide_action_center" = "Скрыть значок Центра уведомлений в системном трее"

        "chk_tb_hide_people" = "Скрыть кнопку «Люди» (People) на панели задач"

        "chk_exp_open_this_pc" = "Открывать Проводник на «Этот компьютер» вместо «Быстрого доступа»"

        "chk_ui_folder_view_list_sort_type" = "Вид папок по умолчанию — «Список» (лист) и сортировка по типу"

        "chk_exp_hide_user_folders" = "Скрыть 6 пользовательских папок (Видео, Музыка, 3D и т.д.) в «Этот компьютер»"

        "chk_exp_no_shortcut_suffix" = "При создании ярлыков не добавлять приписку «- Ярлык»"

        "chk_exp_hide_quick_access_recent" = "Не сохранять и не показывать недавние файлы и папки в Быстром доступе"

        "chk_exp_show_full_path" = "Отображать полный путь в заголовке окна Проводника"

        "chk_exp_separate_process" = "Открывать папки в отдельном процессе (защита от зависания Рабочего стола)"

        "chk_exp_hide_nav_libraries" = "Скрыть раздел «Библиотеки» из панели навигации Проводника"

        "chk_desktop_show_user_folder" = "Отображать значок профиля пользователя на Рабочем столе"

        "chk_ctx_cleanup_bloat" = "Очистить контекстное меню ПКМ (убрать «Устранение неполадок», 3D Paint и др.)"

        "chk_ctx_winrar_email" = "WinRAR: Скрыть пункты «Сжать и отправить по email...» в контекстном меню"

        "chk_wu_disable_auto_updates" = "*Настройка проверки обновлений: Не проверять (не рекомендуется) [режим Dism++]"

        "chk_wu_exclude_drivers" = "Windows Update не включает в себя драйверы"

        "chk_wu_exclude_msrt" = "Обновление Windows не включает в себя средство удаления вредоносных программ"

        "chk_sys_bsod_no_autoreboot" = "Отключить автоматическую перезагрузку при синем экране BSOD"

        "chk_sys_small_minidump" = "Настроить создание малого дампа памяти Minidump при сбоях (экономия SSD)"

        "chk_sys_fast_startup_off" = "Отключить Быстрый запуск (защита от повреждения ядра и багов гибернации)"

        "chk_sys_disable_remote_assist" = "Отключить службу удаленного помощника Windows (Remote Assistance)"

        "chk_sys_enable_photo_viewer" = "Восстановить классический быстрый Windows Photo Viewer"

        "chk_sys_notepad_tweaks" = "Блокнот: включить перенос по словам и строку состояния по умолчанию"

        "chk_app_xbox" = "Удалить пакеты Xbox (Xbox App, GameBar - снимите, если ПК игровой)"

        "chk_app_gamebar_disable" = "Отключить Xbox Game Bar (запись клипов и вызов кнопкой геймпада)"

        "chk_app_games" = "Удалить промо-игры (Candy Crush, Solitaire Collection, TikTok, Disney ярлыки)"

        "chk_app_news" = "Удалить приложения MSN News, Weather, Sports, Money / Finance"

        "chk_app_office_stub" = "Удалить заглушку Microsoft 365 / GetOffice"

        "chk_app_clipchamp" = "Удалить предустановленный видеоредактор Clipchamp"

        "chk_app_people" = "Удалить неиспользуемые компоненты People и старый почтовый клиент"

        "chk_app_feedback" = "Удалить приложение Feedback Hub (Центр отзывов)"

        "chk_app_get_help" = "Удалить приложения Get Help и Советы (Tips)"

        "chk_app_phone" = "Удалить Связь с телефоном (Phone Link - снимите, если используете со смартфоном)"

        "chk_srv_sysmain" = "Отключить службу SysMain / Superfetch (продлевает ресурс SSD)"

        "chk_srv_indexing" = "Отключить службу индексирования Windows Search (снижает нагрузку на CPU и диск)"

        "chk_srv_remote_reg" = "Отключить службу удаленного реестра (RemoteRegistry - безопасность)"

        "chk_srv_delivery_opt" = "Отключить Delivery Optimization P2P (запретить ПК раздавать обновления в сеть)"

        "chk_srv_reserved_storage" = "Отключить Reserved Storage Windows (освобождает ~7 ГБ на диске)"

        "chk_srv_hibernation" = "Отключить гибернацию и удалить hiberfil.sys (освобождает гигабайты на SSD)"

        "chk_srv_power_plan" = "Активировать схему электропитания «Максимальная производительность» (Ultimate Plan)"

        "chk_srv_power_sleep_screen" = "Таймауты дисплея и сна: экран Никогда, сон 30 мин (батарея) / Никогда (сеть), заставка 10 мин"

        "chk_srv_ssd_trim" = "Глубокая оптимизация под SSD и NVMe M.2 (TRIM, кэш NTFS, отключение LastAccess/SysMain)"
        "chk_srv_pagefile_auto" = "Умный динамический файл подкачки на C: (адаптивно по объёму RAM и места на SSD)"

        "chk_srv_network_offload" = "Отключить сетевой Task Offload и Chimney (защита от скачков задержки)"

        "chk_srv_visual_appearance" = "Визуальные эффекты: Обеспечить наилучший вид (все анимации, тени, сглаживание шрифтов)"

        "chk_srv_pca" = "Отключить Помощника по совместимости программ (PcaSvc)"

        "chk_srv_trkwks" = "Отключить службу отслеживания связей NTFS (TrkWks)"

        "chk_srv_iphlpsvc" = "Отключить службу преобразования IPv6 (iphlpsvc - снимите, если нужен IPv6 VPN)"

        "chk_clean_user_temp" = "Очистить пользовательские временные файлы (%TEMP% и LocalAppData\\Temp)"

        "chk_clean_win_temp" = "Очистить общесистемный каталог временных файлов (C:\\Windows\\Temp)"

        "chk_clean_soft_dist" = "Очистить кэш скачанных обновлений Windows (SoftwareDistribution\\Download)"

        "chk_clean_thumb_cache" = "Очистить базы данных эскизов проводника (thumbcache_*.db)"

        "chk_clean_shaders_dns" = "Очистить кэш шейдеров DirectX и сбросить кэш сопоставителя DNS"

        "chk_clean_event_logs" = "Очистить все журналы событий Windows Event Logs"

        "chk_clean_recycle_bin" = "Очистить корзину для всех локальных дисков"

        "chk_clean_cleanmgr" = "Выполнить автоматическую системную очистку дисков (cleanmgr)"

        "chk_deep_dism_repair" = "Проверка и восстановление хранилища DISM (slow - медленно)"

        "chk_deep_dism_resetbase" = "Глубокая очистка WinSxS: ResetBase (slow - медленно)"

        "chk_deep_sfc_compact" = "Проверка целостности SFC Scannow и CompactOS (slow - медленно)"

    }

}

# Load pure ASCII XAML UI

$xamlBase64 = (@(
        'PFdpbmRvdyB4bWxucz0iaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93aW5meC8yMDA2L3hhbWwvcHJlc2VudGF0aW9uIgog'
        'ICAgICAgIHhtbG5zOng9Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd2luZngvMjAwNi94YW1sIgogICAgICAgIFRpdGxl'
        'PSJHSU4tV2luLU9wdGltaXplciB2MDQ3IFtWbGFkaU1JUiArIEFJXSIKICAgICAgICBIZWlnaHQ9Ijg5MCIgV2lkdGg9IjEyODAi'
        'CiAgICAgICAgTWluSGVpZ2h0PSI3NTAiIE1pbldpZHRoPSIxMTAwIgogICAgICAgIFdpbmRvd1N0YXJ0dXBMb2NhdGlvbj0iQ2Vu'
        'dGVyU2NyZWVuIgogICAgICAgIFdpbmRvd1N0YXRlPSJNYXhpbWl6ZWQiCiAgICAgICAgQmFja2dyb3VuZD0iIzEzMTUxOCIgRm9y'
        'ZWdyb3VuZD0iI2UwZTBlMCIKICAgICAgICBGb250RmFtaWx5PSJTZWdvZSBVSSIgRm9udFNpemU9IjEyIj4KICAgIDxXaW5kb3cu'
        'UmVzb3VyY2VzPgogICAgICAgIDxTdHlsZSBUYXJnZXRUeXBlPSJQYXJhZ3JhcGgiPgogICAgICAgICAgICA8U2V0dGVyIFByb3Bl'
        'cnR5PSJNYXJnaW4iIFZhbHVlPSIwIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlBhZGRpbmciIFZhbHVlPSIwIi8+'
        'CiAgICAgICAgPC9TdHlsZT4KICAgICAgICA8U3R5bGUgVGFyZ2V0VHlwZT0iR3JvdXBCb3giPgogICAgICAgICAgICA8U2V0dGVy'
        'IFByb3BlcnR5PSJCb3JkZXJCcnVzaCIgVmFsdWU9IiMyNTI4MmUiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iQm9y'
        'ZGVyVGhpY2tuZXNzIiBWYWx1ZT0iMSIvPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJNYXJnaW4iIFZhbHVlPSIwLDAs'
        'MCw5Ii8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlBhZGRpbmciIFZhbHVlPSI5LDYsOSw4Ii8+CiAgICAgICAgICAg'
        'IDxTZXR0ZXIgUHJvcGVydHk9IkZvcmVncm91bmQiIFZhbHVlPSIjMDBiNGQ4Ii8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVy'
        'dHk9IkZvbnRXZWlnaHQiIFZhbHVlPSJTZW1pQm9sZCIvPgogICAgICAgIDwvU3R5bGU+CiAgICAgICAgPFN0eWxlIFRhcmdldFR5'
        'cGU9IkNoZWNrQm94Ij4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iRm9yZWdyb3VuZCIgVmFsdWU9IiNkNGQ0ZDgiLz4K'
        'ICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iTWFyZ2luIiBWYWx1ZT0iMiwyLDIsMyIvPgogICAgICAgICAgICA8U2V0dGVy'
        'IFByb3BlcnR5PSJGb250V2VpZ2h0IiBWYWx1ZT0iTm9ybWFsIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkZvbnRT'
        'aXplIiBWYWx1ZT0iMTEuNSIvPgogICAgICAgIDwvU3R5bGU+CiAgICAgICAgPFN0eWxlIFRhcmdldFR5cGU9IkJ1dHRvbiI+CiAg'
        'ICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkJhY2tncm91bmQiIFZhbHVlPSIjMjUyODJlIi8+CiAgICAgICAgICAgIDxTZXR0'
        'ZXIgUHJvcGVydHk9IkZvcmVncm91bmQiIFZhbHVlPSIjZmZmZmZmIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkJv'
        'cmRlckJydXNoIiBWYWx1ZT0iIzNhM2Q0NSIvPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJCb3JkZXJUaGlja25lc3Mi'
        'IFZhbHVlPSIxIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlBhZGRpbmciIFZhbHVlPSIxMCw1Ii8+CiAgICAgICAg'
        'ICAgIDxTZXR0ZXIgUHJvcGVydHk9IkZvbnRXZWlnaHQiIFZhbHVlPSJTZW1pQm9sZCIvPgogICAgICAgICAgICA8U2V0dGVyIFBy'
        'b3BlcnR5PSJDdXJzb3IiIFZhbHVlPSJIYW5kIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlRlbXBsYXRlIj4KICAg'
        'ICAgICAgICAgICAgIDxTZXR0ZXIuVmFsdWU+CiAgICAgICAgICAgICAgICAgICAgPENvbnRyb2xUZW1wbGF0ZSBUYXJnZXRUeXBl'
        'PSJCdXR0b24iPgogICAgICAgICAgICAgICAgICAgICAgICA8Qm9yZGVyIHg6TmFtZT0iYm9yZGVyIiBCYWNrZ3JvdW5kPSJ7VGVt'
        'cGxhdGVCaW5kaW5nIEJhY2tncm91bmR9IiBCb3JkZXJCcnVzaD0ie1RlbXBsYXRlQmluZGluZyBCb3JkZXJCcnVzaH0iIEJvcmRl'
        'clRoaWNrbmVzcz0ie1RlbXBsYXRlQmluZGluZyBCb3JkZXJUaGlja25lc3N9IiBDb3JuZXJSYWRpdXM9IjMiIFBhZGRpbmc9IntU'
        'ZW1wbGF0ZUJpbmRpbmcgUGFkZGluZ30iPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENvbnRlbnRQcmVzZW50ZXIgeDpO'
        'YW1lPSJjb250ZW50UHJlc2VudGVyIiBIb3Jpem9udGFsQWxpZ25tZW50PSJDZW50ZXIiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50'
        'ZXIiIEZvY3VzYWJsZT0iRmFsc2UiIFJlY29nbml6ZXNBY2Nlc3NLZXk9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAg'
        'PC9Cb3JkZXI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxDb250cm9sVGVtcGxhdGUuVHJpZ2dlcnM+CiAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICA8VHJpZ2dlciBQcm9wZXJ0eT0iSXNNb3VzZU92ZXIiIFZhbHVlPSJUcnVlIj4KICAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5hbWU9ImJvcmRlciIgUHJvcGVydHk9IkJhY2tncm91bmQiIFZhbHVlPSIj'
        'MzUzYjQ4Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPFNldHRlciBUYXJnZXROYW1lPSJib3JkZXIiIFByb3Bl'
        'cnR5PSJCb3JkZXJCcnVzaCIgVmFsdWU9IiMwMGI0ZDgiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvVHJpZ2dlcj4K'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxUcmlnZ2VyIFByb3BlcnR5PSJJc1ByZXNzZWQiIFZhbHVlPSJUcnVlIj4KICAg'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5hbWU9ImJvcmRlciIgUHJvcGVydHk9IkJhY2tncm91'
        'bmQiIFZhbHVlPSIjMWExYzIzIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L1RyaWdnZXI+CiAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICA8VHJpZ2dlciBQcm9wZXJ0eT0iSXNFbmFibGVkIiBWYWx1ZT0iRmFsc2UiPgogICAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICAgIDxTZXR0ZXIgVGFyZ2V0TmFtZT0iYm9yZGVyIiBQcm9wZXJ0eT0iQmFja2dyb3VuZCIgVmFsdWU9IiMx'
        'YzFmMjYiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5hbWU9ImJvcmRlciIgUHJvcGVy'
        'dHk9IkJvcmRlckJydXNoIiBWYWx1ZT0iIzJlMzIzYiIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxTZXR0ZXIg'
        'UHJvcGVydHk9IkZvcmVncm91bmQiIFZhbHVlPSIjOTRhM2I4Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L1RyaWdn'
        'ZXI+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvQ29udHJvbFRlbXBsYXRlLlRyaWdnZXJzPgogICAgICAgICAgICAgICAgICAg'
        'IDwvQ29udHJvbFRlbXBsYXRlPgogICAgICAgICAgICAgICAgPC9TZXR0ZXIuVmFsdWU+CiAgICAgICAgICAgIDwvU2V0dGVyPgog'
        'ICAgICAgIDwvU3R5bGU+CiAgICA8L1dpbmRvdy5SZXNvdXJjZXM+CgogICAgPEdyaWQgTWFyZ2luPSIxMiI+CiAgICAgICAgPEdy'
        'aWQuUm93RGVmaW5pdGlvbnM+CiAgICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iQXV0byIvPgogICAgICAgICAgICA8'
        'Um93RGVmaW5pdGlvbiBIZWlnaHQ9IkF1dG8iLz4KICAgICAgICAgICAgPFJvd0RlZmluaXRpb24gSGVpZ2h0PSIqIi8+CiAgICAg'
        'ICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iMTg1Ii8+CiAgICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iQXV0'
        'byIvPgogICAgICAgIDwvR3JpZC5Sb3dEZWZpbml0aW9ucz4KCiAgICAgICAgPCEtLSBUb3AgSGVhZGVyIC0tPgogICAgICAgIDxC'
        'b3JkZXIgR3JpZC5Sb3c9IjAiIEJhY2tncm91bmQ9IiMxYTFjMjEiIENvcm5lclJhZGl1cz0iNiIgUGFkZGluZz0iMTQsMTAiIE1h'
        'cmdpbj0iMCwwLDAsOCIgQm9yZGVyQnJ1c2g9IiMyNTI4MmUiIEJvcmRlclRoaWNrbmVzcz0iMSI+CiAgICAgICAgICAgIDxEb2Nr'
        'UGFuZWwgTGFzdENoaWxkRmlsbD0iVHJ1ZSI+CiAgICAgICAgICAgICAgICA8IS0tIFJpZ2h0IENvbnRyb2xzOiBTa2lwLCBTdGFy'
        'dCwgRXhpdCAtLT4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIERvY2tQYW5lbC5Eb2NrPSJSaWdodCIgT3JpZW50YXRpb249'
        'Ikhvcml6b250YWwiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0i'
        'YnRuU2tpcFRvcCIgQ29udGVudD0i4o+tIFNLSVAgU1RFUCIgQmFja2dyb3VuZD0iI2Q5NzcwNiIgQm9yZGVyQnJ1c2g9IiNmNTll'
        'MGIiIEZvcmVncm91bmQ9IiNmZmZmZmYiIEZvbnRXZWlnaHQ9IkJvbGQiIFBhZGRpbmc9IjE0LDgiIE1hcmdpbj0iMCwwLDgsMCIg'
        'Rm9udFNpemU9IjEzIiBJc0VuYWJsZWQ9IkZhbHNlIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5TdGFy'
        'dFRvcCIgQ29udGVudD0i8J+agCDQntCf0KLQmNCc0JjQl9CY0KDQntCS0JDQotCsIiBCYWNrZ3JvdW5kPSIjMDA3N2I2IiBCb3Jk'
        'ZXJCcnVzaD0iIzAwOTZjNyIgRm9yZWdyb3VuZD0iI2ZmZmZmZiIgRm9udFdlaWdodD0iQm9sZCIgUGFkZGluZz0iMTYsOCIgTWFy'
        'Z2luPSIwLDAsOCwwIiBGb250U2l6ZT0iMTMiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blJlYm9vdFRv'
        'cCIgQ29udGVudD0i4pqhIFJFQk9PVCIgQmFja2dyb3VuZD0iI2RjMjYyNiIgQm9yZGVyQnJ1c2g9IiNmZjRkNGYiIEZvcmVncm91'
        'bmQ9IiNmZmZmZmYiIEZvbnRXZWlnaHQ9IkJvbGQiIFBhZGRpbmc9IjE2LDgiIE1hcmdpbj0iMCwwLDgsMCIgRm9udFNpemU9IjEz'
        'IiBWaXNpYmlsaXR5PSJWaXNpYmxlIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5FeGl0VG9wIiBDb250'
        'ZW50PSJFeGl0IiBCYWNrZ3JvdW5kPSIjM2ExYzFjIiBCb3JkZXJCcnVzaD0iIzY2MjIyMiIgRm9yZWdyb3VuZD0iI2ZmODg4OCIg'
        'UGFkZGluZz0iMTIsOCIvPgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgoKICAgICAgICAgICAgICAgIDwhLS0gQ2VudGVy'
        'IENvbnRyb2xzOiBMYW5ndWFnZSBTd2l0Y2hlciBQaWxscyAmIFRlbGVncmFtIC0tPgogICAgICAgICAgICAgICAgPFN0YWNrUGFu'
        'ZWwgRG9ja1BhbmVsLkRvY2s9IlJpZ2h0IiBPcmllbnRhdGlvbj0iSG9yaXpvbnRhbCIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRl'
        'ciIgTWFyZ2luPSIwLDAsMTYsMCI+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5UZWxlZ3JhbSIgQ29udGVu'
        'dD0i4pyI77iPIFRlbGVncmFtIChAR2luQ3opIiBCYWNrZ3JvdW5kPSIjMDA4OGNjIiBCb3JkZXJCcnVzaD0iIzI5YjZmNiIgRm9y'
        'ZWdyb3VuZD0iI2ZmZmZmZiIgRm9udFdlaWdodD0iU2VtaUJvbGQiIFBhZGRpbmc9IjEwLDUiIE1hcmdpbj0iMCwwLDEyLDAiIEZv'
        'bnRTaXplPSIxMSIgVG9vbFRpcD0i0J3QsNC/0LjRgdCw0YLRjCDQsNCy0YLQvtGA0YMg0LIgVGVsZWdyYW0gKEBHaW5Deik6IGh0'
        'dHBzOi8vdC5tZS9HaW5DeiIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuTGFuZ1J1IiBDb250ZW50PSJS'
        'VSIgQmFja2dyb3VuZD0iIzFlM2E1ZiIgQm9yZGVyQnJ1c2g9IiMwMGI0ZDgiIEZvcmVncm91bmQ9IiNmZmZmZmYiIFBhZGRpbmc9'
        'IjgsNCIgTWFyZ2luPSIwLDAsNCwwIiBGb250U2l6ZT0iMTEiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0'
        'bkxhbmdFbiIgQ29udGVudD0iRU4iIEJhY2tncm91bmQ9IiMyNTI4MmUiIEJvcmRlckJydXNoPSIjM2EzZDQ1IiBGb3JlZ3JvdW5k'
        'PSIjYjBiM2I4IiBQYWRkaW5nPSI4LDQiIE1hcmdpbj0iMCwwLDQsMCIgRm9udFNpemU9IjExIi8+CiAgICAgICAgICAgICAgICAg'
        'ICAgPEJ1dHRvbiBOYW1lPSJidG5MYW5nQ3MiIENvbnRlbnQ9IkNaIiBCYWNrZ3JvdW5kPSIjMjUyODJlIiBCb3JkZXJCcnVzaD0i'
        'IzNhM2Q0NSIgRm9yZWdyb3VuZD0iI2IwYjNiOCIgUGFkZGluZz0iOCw0IiBGb250U2l6ZT0iMTEiLz4KICAgICAgICAgICAgICAg'
        'IDwvU3RhY2tQYW5lbD4KCiAgICAgICAgICAgICAgICA8IS0tIExlZnQgSW5mbzogQ29tcHV0ZXIgSW5mb3JtYXRpb24gJiBTcGVj'
        'cyAtLT4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIE9yaWVudGF0aW9uPSJWZXJ0aWNhbCI+CiAgICAgICAgICAgICAgICAg'
        'ICAgPFN0YWNrUGFuZWwgT3JpZW50YXRpb249Ikhvcml6b250YWwiPgogICAgICAgICAgICAgICAgICAgICAgICA8VGV4dEJsb2Nr'
        'IE5hbWU9InR4dEhlYWRlclRpdGxlIiBUZXh0PSLQlNCw0L3QvdGL0LUg0L4g0LrQvtC80L/RjNGO0YLQtdGA0LUiIEZvbnRTaXpl'
        'PSIxNCIgRm9udFdlaWdodD0iQm9sZCIgRm9yZWdyb3VuZD0iIzAwYjRkOCIvPgogICAgICAgICAgICAgICAgICAgICAgICA8Qm9y'
        'ZGVyIEJhY2tncm91bmQ9IiMxNjY1MzQiIENvcm5lclJhZGl1cz0iMyIgUGFkZGluZz0iNiwxIiBNYXJnaW49IjgsMCwwLDAiIFZl'
        'cnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBUZXh0PSJBRE1J'
        'TiIgRm9udFNpemU9IjkiIEZvbnRXZWlnaHQ9IkJvbGQiIEZvcmVncm91bmQ9IiM4NmVmYWMiLz4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgPC9Cb3JkZXI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxCb3JkZXIgQmFja2dyb3VuZD0iIzBmNzY2ZSIgQ29ybmVy'
        'UmFkaXVzPSIzIiBQYWRkaW5nPSI2LDEiIE1hcmdpbj0iNiwwLDAsMCIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRlciIgVG9vbFRp'
        'cD0i0JHQtdGB0L/Qu9Cw0YLQvdCw0Y8g0L/QvtC20LjQt9C90LXQvdC90LDRjyDQu9C40YbQtdC90LfQuNGPIChQZXJzb25hbCAm'
        'YW1wOyBCdXNpbmVzcyBGcmVld2FyZSkiPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBUZXh0PSJGUkVF'
        'V0FSRSIgRm9udFNpemU9IjkiIEZvbnRXZWlnaHQ9IkJvbGQiIEZvcmVncm91bmQ9IiM1ZWVhZDQiLz4KICAgICAgICAgICAgICAg'
        'ICAgICAgICAgPC9Cb3JkZXI+CiAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDxU'
        'ZXh0QmxvY2sgTmFtZT0idHh0SG9zdEluZm8iIFRleHQ9Ikhvc3Q6IGxvY2FsIHwg0KPRgdGC0YDQvtC50YHRgtCy0L46IFBDIHwg'
        'V2luZG93czogMTAgUHJvIHwgSVA6IDEyNy4wLjAuMSIgRm9udFNpemU9IjExIiBGb3JlZ3JvdW5kPSIjY2JkNWUxIiBNYXJnaW49'
        'IjAsMywwLDAiLz4KICAgICAgICAgICAgICAgICAgICA8VGV4dEJsb2NrIE5hbWU9InR4dEhlYWRlclN1YiIgVGV4dD0iR0lOLVdp'
        'bi1PcHRpbWl6ZXIgdjA0NSBbVmxhZGlNSVIgKyBBSV0iIEZvbnRTaXplPSIxMCIgRm9yZWdyb3VuZD0iIzY0NzQ4YiIgTWFyZ2lu'
        'PSIwLDEsMCwwIi8+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgogICAgICAg'
        'IDwvQm9yZGVyPgoKICAgICAgICA8IS0tIFByZXNldHMgQmFyIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9IjEiIEJhY2tn'
        'cm91bmQ9IiMxZTIwMjYiIENvcm5lclJhZGl1cz0iNCIgUGFkZGluZz0iMTAsNiIgTWFyZ2luPSIwLDAsMCw4IiBCb3JkZXJCcnVz'
        'aD0iIzI1MjgyZSIgQm9yZGVyVGhpY2tuZXNzPSIxIj4KICAgICAgICAgICAgPERvY2tQYW5lbCBMYXN0Q2hpbGRGaWxsPSJUcnVl'
        'Ij4KICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sgTmFtZT0idHh0UHJlc2V0cyIgVGV4dD0iUHJlc2V0czoiIFZlcnRpY2FsQWxp'
        'Z25tZW50PSJDZW50ZXIiIEZvbnRXZWlnaHQ9IkJvbGQiIEZvcmVncm91bmQ9IiNiNWJhYzEiIE1hcmdpbj0iMCwwLDEwLDAiLz4K'
        'ICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIj4KICAgICAgICAgICAgICAgICAgICA8'
        'QnV0dG9uIE5hbWU9ImJ0blNlbGVjdEFsbCIgQ29udGVudD0i4pyTIFNlbGVjdCBBbGwgKE1heCBDbGVhbikiIE1hcmdpbj0iMCww'
        'LDYsMCIgUGFkZGluZz0iMTAsNCIgQmFja2dyb3VuZD0iIzE0NTMyZCIgQm9yZGVyQnJ1c2g9IiMyMmM1NWUiIEZvcmVncm91bmQ9'
        'IiM4NmVmYWMiIEZvbnRXZWlnaHQ9IlNlbWlCb2xkIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5EZXNl'
        'bGVjdEFsbCIgQ29udGVudD0i4pyXIERlc2VsZWN0IEFsbCIgTWFyZ2luPSIwLDAsNiwwIiBQYWRkaW5nPSIxMCw0Ii8+CiAgICAg'
        'ICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5QcmVzZXRPZmZpY2UiIENvbnRlbnQ9IvCfj6IgT2ZmaWNlIChLZWVwIE9u'
        'ZURyaXZlKSIgTWFyZ2luPSIwLDAsNiwwIiBQYWRkaW5nPSIxMCw0Ii8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1l'
        'PSJidG5QcmVzZXRHYW1pbmciIENvbnRlbnQ9IuKaoSBHYW1pbmcgKEtlZXAgWGJveCkiIE1hcmdpbj0iMCwwLDYsMCIgUGFkZGlu'
        'Zz0iMTAsNCIvPgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAgICA8L0RvY2tQYW5lbD4KICAgICAgICA8'
        'L0JvcmRlcj4KCiAgICAgICAgPCEtLSBNYWluIFNjcm9sbGFibGUgT3B0aW9ucyBHcmlkIC0tPgogICAgICAgIDxTY3JvbGxWaWV3'
        'ZXIgR3JpZC5Sb3c9IjIiIFZlcnRpY2FsU2Nyb2xsQmFyVmlzaWJpbGl0eT0iQXV0byIgSG9yaXpvbnRhbFNjcm9sbEJhclZpc2li'
        'aWxpdHk9IkRpc2FibGVkIiBNYXJnaW49IjAsMCwwLDgiPgogICAgICAgICAgICA8R3JpZD4KICAgICAgICAgICAgICAgIDxHcmlk'
        'LkNvbHVtbkRlZmluaXRpb25zPgogICAgICAgICAgICAgICAgICAgIDxDb2x1bW5EZWZpbml0aW9uIFdpZHRoPSIqIi8+CiAgICAg'
        'ICAgICAgICAgICAgICAgPENvbHVtbkRlZmluaXRpb24gV2lkdGg9IioiLz4KICAgICAgICAgICAgICAgICAgICA8Q29sdW1uRGVm'
        'aW5pdGlvbiBXaWR0aD0iKiIvPgogICAgICAgICAgICAgICAgPC9HcmlkLkNvbHVtbkRlZmluaXRpb25zPgoKICAgICAgICAgICAg'
        'ICAgIDwhLS0gQ09MVU1OIDEgLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBHcmlkLkNvbHVtbj0iMCIgTWFyZ2luPSIw'
        'LDAsNiwwIj4KICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBQcml2YWN5ICYgVGVsZW1ldHJ5IC0tPgogICAgICAgICAg'
        'ICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBQcml2YWN5IiBIZWFkZXI9IlByaXZhY3kgJmFtcDsgVGVsZW1ldHJ5Ij4KICAg'
        'ICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt'
        'ZT0iY2hrX3RlbGVtX2RpYWd0cmFjayIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX3RlbGVtX2Rtd2FwcHVzaCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAg'
        'ICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX3dlciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2FsbG93X3RlbGVtIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGVsZW1fYWRfaWQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg'
        'ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV9pbmtpbmciIElzQ2hlY2tlZD0iVHJ1ZSIv'
        'PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV9hY3Rpdml0eSIgSXNDaGVja2Vk'
        'PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2xvY2F0aW9uIiBJ'
        'c0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGVsZW1fZmVl'
        'ZGJhY2siIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190'
        'ZWxlbV90YXNrcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i'
        'Y2hrX3RlbGVtX2NvcnRhbmEiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94'
        'IE5hbWU9ImNoa19uZXRfd2lmaV9wcml2YWN5IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9T'
        'dGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDwvR3JvdXBCb3g+CgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6'
        'IFNlY3VyaXR5ICYgVUFDIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBTZWN1cml0eSIgSGVhZGVy'
        'PSJTZWN1cml0eSAmYW1wOyBVQUMgVHdlYWtzIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY191YWNfcXVpZXQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgog'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zZWNfYWRtaW5fYXBwcm92YWwiIElzQ2hlY2tl'
        'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zZWNfc21hcnRzY3JlZW4i'
        'IElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zZWNfb3Bl'
        'bl9maWxlX3dhcm5pbmciIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAg'
        'ICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogQ2xvdWQgJiBDb25z'
        'dW1lciAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwQ2xvdWQiIEhlYWRlcj0iQ2xvdWQgJmFtcDsg'
        'Q29uc3VtZXIgRmVhdHVyZXMiPgogICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xvdWRfb25lZHJpdmUiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91ZF9zZXR0aW5nc19zeW5jIiBJc0NoZWNrZWQ9IlRydWUi'
        'Lz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xvdWRfYmluZ19zZWFyY2giIElzQ2hl'
        'Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91ZF9zcG90bGln'
        'aHQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91'
        'ZF9jb25zdW1lcl9mZWF0dXJlcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5l'
        'bD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBNaWNyb3Nv'
        'ZnQgRWRnZSAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwRWRnZSIgSGVhZGVyPSJNaWNyb3NvZnQg'
        'RWRnZSBPcHRpbWl6YXRpb24iPgogICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZWRnZV9iYWNrZ3JvdW5kIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZWRnZV9zdGFydHVwX2Jvb3N0IiBJc0NoZWNrZWQ9IlRydWUi'
        'Lz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZWRnZV90ZWxlbWV0cnkiIElzQ2hlY2tl'
        'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3NpZGViYXIiIElz'
        'Q2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3ByZWxh'
        'dW5jaCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Vk'
        'Z2VfZmlyc3RfcnVuIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1l'
        'PSJjaGtfZWRnZV91bnBpbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3gg'
        'TmFtZT0iY2hrX2Jyb3dzZXJfdXBkYXRlcnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0'
        'YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KCiAg'
        'ICAgICAgICAgICAgICA8IS0tIENPTFVNTiAyIC0tPgogICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgR3JpZC5Db2x1bW49IjEi'
        'IE1hcmdpbj0iMywwLDMsMCI+CiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogRXhwbG9yZXIsIERlc2t0b3AgJiBUYXNr'
        'YmFyIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBVSSIgSGVhZGVyPSJFeHBsb3JlciwgRGVza3Rv'
        'cCAmYW1wOyBUYXNrYmFyIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICA8IS0tIEhpZ2hsaWdodGVkIGluIFllbGxvdzogU2hlbGwgRm9sZGVycyBSZWxvY2F0aW9uIHRvIEQ6XCAoT0ZGIGJ5'
        'IGRlZmF1bHQpIC0tPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPEJvcmRlciBCYWNrZ3JvdW5kPSIjMjMxZjA4IiBCb3Jk'
        'ZXJCcnVzaD0iI2VhYjMwOCIgQm9yZGVyVGhpY2tuZXNzPSIxIiBDb3JuZXJSYWRpdXM9IjQiIFBhZGRpbmc9IjYsNCIgTWFyZ2lu'
        'PSIwLDAsMCw2Ij4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19yZWxvY19kb2N1bWVudHMiIElzQ2hlY2tlZD0iRmFsc2UiIEZv'
        'cmVncm91bmQ9IiNmYWNjMTUiIEZvbnRXZWlnaHQ9IkJvbGQiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg'
        'PENoZWNrQm94IE5hbWU9ImNoa19yZWxvY19kZXNrdG9wIiBJc0NoZWNrZWQ9IkZhbHNlIiBGb3JlZ3JvdW5kPSIjZmFjYzE1IiBG'
        'b250V2VpZ2h0PSJCb2xkIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgPC9Cb3JkZXI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hr'
        'X3VpX3dpZGdldHMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
        'ImNoa191aV90ZWFtc19jaGF0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0Jv'
        'eCBOYW1lPSJjaGtfdWlfY29waWxvdCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX3VpX3JlY2FsbCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8'
        'Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX3N0YXJ0X2FkcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAg'
        'ICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2V4cGxvcmVyX2FkcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX3dlbGNvbWVfc2NyZWVuIiBJc0NoZWNrZWQ9IlRydWUiLz4NCiAg'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2xvY2tzY3JlZW5fY2xlYW4iIElzQ2hlY2tl'
        'ZD0iVHJ1ZSIvPg0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfY29sb3JfYWNjZW50'
        'X3RoZW1lIiBJc0NoZWNrZWQ9IlRydWUiLz4NCiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hr'
        'X3VpX21vdXNlX2ludmVydGVkX2xhcmdlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD'
        'aGVja0JveCBOYW1lPSJjaGtfdWlfY2xhc3NpY19jb250ZXh0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfaGlkZV9zZWFyY2giIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9oaWRlX3Rhc2t2aWV3IiBJc0NoZWNrZWQ9IlRydWUiLz4K'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfc2hvd19hbGxfdHJheV9pY29ucyIgSXND'
        'aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX25ldmVyX2Nv'
        'bWJpbmVfdGFza2JhciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt'
        'ZT0iY2hrX3VpX3Nob3dfdGhpc19wYyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX3VpX2Nsb2NrXzI0aF9zZWNvbmRzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfcmVnaW9uX3RpbWVfY3plY2giIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg'
        'ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9sYW5nX2tleWJvYXJkcyIgSXNDaGVja2VkPSJU'
        'cnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX3JlZ2lvbmFsX2RhdGVfZm9y'
        'bWF0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGJf'
        'c21hbGxfaWNvbnMiIElzQ2hlY2tlZD0iRmFsc2UiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1l'
        'PSJjaGtfdGJfbG9jayIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt'
        'ZT0iY2hrX3RiX2hpZGVfYWN0aW9uX2NlbnRlciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAg'
        'ICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RiX2hpZGVfcGVvcGxlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZXhwX29wZW5fdGhpc19wYyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2ZvbGRlcl92aWV3X2xpc3Rfc29ydF90eXBlIiBJc0No'
        'ZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZXhwX2hpZGVfdXNl'
        'cl9mb2xkZXJzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJj'
        'aGtfZXhwX25vX3Nob3J0Y3V0X3N1ZmZpeCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8'
        'Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9oaWRlX3F1aWNrX2FjY2Vzc19yZWNlbnQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAg'
        'ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19leHBfc2hvd19mdWxsX3BhdGgiIElzQ2hlY2tlZD0iVHJ1'
        'ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19leHBfc2VwYXJhdGVfcHJvY2VzcyIg'
        'SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9oaWRl'
        'X25hdl9saWJyYXJpZXMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5h'
        'bWU9ImNoa19kZXNrdG9wX3Nob3dfdXNlcl9mb2xkZXIiIElzQ2hlY2tlZD0iRmFsc2UiLz4KICAgICAgICAgICAgICAgICAgICAg'
        'ICAgPC9TdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDwvR3JvdXBCb3g+CgogICAgICAgICAgICAgICAgICAgIDwhLS0g'
        'R3JvdXA6IENvbnRleHQgTWVudSBDbGVhbnVwIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBDb250'
        'ZXh0TWVudSIgSGVhZGVyPSJDb250ZXh0IE1lbnUgQ2xlYW51cCAoUmlnaHQtQ2xpY2spIj4KICAgICAgICAgICAgICAgICAgICAg'
        'ICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2N0eF9jbGVhbnVw'
        'X2Jsb2F0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtf'
        'Y3R4X2ludGVsX2dyYXBoaWNzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0Jv'
        'eCBOYW1lPSJjaGtfY3R4X3dpbnJhcl9lbWFpbCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwv'
        'U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgoK'
        'ICAgICAgICAgICAgICAgIDwhLS0gQ09MVU1OIDMgLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBHcmlkLkNvbHVtbj0i'
        'MiIgTWFyZ2luPSI2LDAsMCwwIj4KICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBXaW5kb3dzIFVwZGF0ZSAmIFN5c3Rl'
        'bSBEaWFnbm9zdGljcyAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwV2luVXBkYXRlIiBIZWFkZXI9'
        'IldpbmRvd3MgVXBkYXRlLCBCU09EICZhbXA7IFN5c3RlbSI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgog'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa193dV9kaXNhYmxlX2F1dG9fdXBkYXRlcyIgSXND'
        'aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3d1X2V4Y2x1ZGVf'
        'ZHJpdmVycyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hr'
        'X3d1X2V4Y2x1ZGVfbXNydCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3gg'
        'TmFtZT0iY2hrX3N5c19ic29kX25vX2F1dG9yZWJvb3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAg'
        'ICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfc21hbGxfbWluaWR1bXAiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfZmFzdF9zdGFydHVwX29mZiIgSXNDaGVja2VkPSJUcnVl'
        'Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3N5c19kaXNhYmxlX3JlbW90ZV9hc3Np'
        'c3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNf'
        'ZW5hYmxlX3Bob3RvX3ZpZXdlciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC'
        'b3ggTmFtZT0iY2hrX3N5c19ub3RlcGFkX3R3ZWFrcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAg'
        'IDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdy'
        'b3VwOiBBcHBzICYgQmxvYXR3YXJlIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBBcHBzIiBIZWFk'
        'ZXI9IkFwcCBEZWJsb2F0ZXIgJmFtcDsgUHJvdmlzaW9uZWQgUGFja2FnZXMiPgogICAgICAgICAgICAgICAgICAgICAgICA8U3Rh'
        'Y2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX3hib3giIElzQ2hlY2tl'
        'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19hcHBfZ2FtZWJhcl9kaXNh'
        'YmxlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBw'
        'X2dhbWVzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtf'
        'YXBwX25ld3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo'
        'a19hcHBfb2ZmaWNlX3N0dWIiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94'
        'IE5hbWU9ImNoa19hcHBfY2xpcGNoYW1wIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD'
        'aGVja0JveCBOYW1lPSJjaGtfYXBwX3Blb3BsZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAg'
        'ICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9mZWVkYmFjayIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9nZXRfaGVscCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAg'
        'ICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9waG9uZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAg'
        'ICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAg'
        'ICAgICA8IS0tIEdyb3VwOiBTZXJ2aWNlcyAmIFBlcmZvcm1hbmNlIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBO'
        'YW1lPSJncnBTZXJ2aWNlcyIgSGVhZGVyPSJTeXN0ZW0gUGVyZm9ybWFuY2UgJmFtcDsgU2VydmljZXMiPgogICAgICAgICAgICAg'
        'ICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2'
        'X3N5c21haW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo'
        'a19zcnZfaW5kZXhpbmciIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5h'
        'bWU9ImNoa19zcnZfcmVtb3RlX3JlZyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX3Nydl9kZWxpdmVyeV9vcHQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAg'
        'ICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfcmVzZXJ2ZWRfc3RvcmFnZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9oaWJlcm5hdGlvbiIgSXNDaGVja2VkPSJUcnVlIi8+'
        'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9wb3dlcl9wbGFuIiBJc0NoZWNrZWQ9'
        'IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3Bvd2VyX3NsZWVwX3Nj'
        'cmVlbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Ny'
        'dl9zc2RfdHJpbSIgSXNDaGVja2VkPSJUcnVlIi8+DQogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
        'ImNoa19zcnZfcGFnZWZpbGVfYXV0byIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX3Nydl9uZXR3b3JrX29mZmxvYWQiIElzQ2hlY2tlZD0iRmFsc2UiLz4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3Zpc3VhbF9hcHBlYXJhbmNlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAg'
        'ICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3BjYSIgSXNDaGVja2VkPSJGYWxzZSIvPgog'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfdHJrd2tzIiBJc0NoZWNrZWQ9IkZhbHNl'
        'Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9pcGhscHN2YyIgSXNDaGVja2Vk'
        'PSJGYWxzZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfb2VtX2xlbm92byIg'
        'SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9pbnRl'
        'bF9ncmFwaGljcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i'
        'Y2hrX3Nydl9jb25leGFudF9hdWRpbyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQ'
        'YW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBDYWNo'
        'ZSAmIENsZWFuaW5nIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBDbGVhbiIgSGVhZGVyPSJDYWNo'
        'ZSAmYW1wOyBDb21wb25lbnQgQ2xlYW5pbmciPgogICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgIDwhLS0gVGhlIDMgbG9uZ2VzdC9zbG93ZXN0IG1haW50ZW5hbmNlIG9wZXJhdGlvbnMgKGhpZ2hs'
        'aWdodGVkIGluIGJyaWdodCByZWQsIE9GRiBieSBkZWZhdWx0KSAtLT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVj'
        'a0JveCBOYW1lPSJjaGtfZGVlcF9kaXNtX3JlcGFpciIgSXNDaGVja2VkPSJGYWxzZSIgRm9yZWdyb3VuZD0iI2ZmNGQ0ZiIgRm9u'
        'dFdlaWdodD0iQm9sZCIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19kZWVwX2Rpc21f'
        'cmVzZXRiYXNlIiBJc0NoZWNrZWQ9IkZhbHNlIiBGb3JlZ3JvdW5kPSIjZmY0ZDRmIiBGb250V2VpZ2h0PSJCb2xkIi8+CiAgICAg'
        'ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2RlZXBfc2ZjX2NvbXBhY3QiIElzQ2hlY2tlZD0iRmFs'
        'c2UiIEZvcmVncm91bmQ9IiNmZjRkNGYiIEZvbnRXZWlnaHQ9IkJvbGQiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxT'
        'ZXBhcmF0b3IgQmFja2dyb3VuZD0iIzJlMzIzYiIgTWFyZ2luPSIwLDMsMCw0Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAg'
        'ICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFuX3VzZXJfdGVtcCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFuX3dpbl90ZW1wIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAg'
        'ICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xlYW5fc29mdF9kaXN0IiBJc0NoZWNrZWQ9IlRydWUiLz4K'
        'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xlYW5fdGh1bWJfY2FjaGUiIElzQ2hlY2tl'
        'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbGVhbl9zaGFkZXJzX2Ru'
        'cyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFu'
        'X2V2ZW50X2xvZ3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
        'ImNoa19jbGVhbl9yZWN5Y2xlX2JpbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
        'Y2tCb3ggTmFtZT0iY2hrX2NsZWFuX2NsZWFubWdyIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAg'
        'PC9TdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDwvR3JvdXBCb3g+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+'
        'CiAgICAgICAgICAgIDwvR3JpZD4KICAgICAgICA8L1Njcm9sbFZpZXdlcj4KCiAgICAgICAgPCEtLSBMaXZlIEV4ZWN1dGlvbiBD'
        'b25zb2xlIC8gTG9nIEJveCAoSGVpZ2h0IDE4NSkgLS0+CiAgICAgICAgPEJvcmRlciBHcmlkLlJvdz0iMyIgQmFja2dyb3VuZD0i'
        'IzBiMGMwZSIgQ29ybmVyUmFkaXVzPSI0IiBQYWRkaW5nPSI4LDYiIEJvcmRlckJydXNoPSIjMjUyODJlIiBCb3JkZXJUaGlja25l'
        'c3M9IjEiPgogICAgICAgICAgICA8R3JpZD4KICAgICAgICAgICAgICAgIDxHcmlkLlJvd0RlZmluaXRpb25zPgogICAgICAgICAg'
        'ICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iQXV0byIvPgogICAgICAgICAgICAgICAgICAgIDxSb3dEZWZpbml0aW9u'
        'IEhlaWdodD0iQXV0byIvPgogICAgICAgICAgICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iKiIvPgogICAgICAgICAg'
        'ICAgICAgPC9HcmlkLlJvd0RlZmluaXRpb25zPgoKICAgICAgICAgICAgICAgIDwhLS0gQ29uc29sZSBIZWFkZXIgVG9vbGJhciAt'
        'LT4KICAgICAgICAgICAgICAgIDxEb2NrUGFuZWwgR3JpZC5Sb3c9IjAiIE1hcmdpbj0iMCwwLDAsNCI+CiAgICAgICAgICAgICAg'
        'ICAgICAgPFN0YWNrUGFuZWwgRG9ja1BhbmVsLkRvY2s9IlJpZ2h0IiBPcmllbnRhdGlvbj0iSG9yaXpvbnRhbCI+CiAgICAgICAg'
        'ICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuQ2xlYXJMb2ciIENvbnRlbnQ9IvCfp7kgQ2xlYXIiIE1hcmdpbj0iMCww'
        'LDQsMCIgUGFkZGluZz0iNiwyIiBGb250U2l6ZT0iMTAiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJi'
        'dG5Db3B5TG9nIiBDb250ZW50PSLwn5OLIENvcHkiIFBhZGRpbmc9IjYsMiIgRm9udFNpemU9IjEwIi8+CiAgICAgICAgICAgICAg'
        'ICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIE9yaWVudGF0aW9uPSJIb3Jpem9udGFs'
        'IiBWZXJ0aWNhbEFsaWdubWVudD0iQ2VudGVyIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBUZXh0PSJURVJN'
        'SU5BTCBMT0ciIEZvbnRXZWlnaHQ9IkJvbGQiIEZvbnRTaXplPSIxMSIgRm9yZWdyb3VuZD0iIzAwYjRkOCIgTWFyZ2luPSIwLDAs'
        'MTAsMCIvPgogICAgICAgICAgICAgICAgICAgICAgICA8VGV4dEJsb2NrIE5hbWU9InR4dFN1YlN0YXR1cyIgVGV4dD0iUmVhZHku'
        'IiBGb250U2l6ZT0iMTAuNSIgRm9yZWdyb3VuZD0iIzk0YTNiOCIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRlciIvPgogICAgICAg'
        'ICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgIDwvRG9ja1BhbmVsPgoKICAgICAgICAgICAgICAgIDwh'
        'LS0gU3ViLVRhc2sgUHJvZ3Jlc3MgQmFyIChlLmcuIERJU00vU0ZDICUpIC0tPgogICAgICAgICAgICAgICAgPFByb2dyZXNzQmFy'
        'IEdyaWQuUm93PSIxIiBOYW1lPSJwYlN1YlRhc2siIEhlaWdodD0iMyIgTWluaW11bT0iMCIgTWF4aW11bT0iMTAwIiBWYWx1ZT0i'
        'MCIgRm9yZWdyb3VuZD0iIzEwYjk4MSIgQmFja2dyb3VuZD0iIzFlMjAyNiIgQm9yZGVyVGhpY2tuZXNzPSIwIiBNYXJnaW49IjAs'
        'MCwwLDQiLz4KCiAgICAgICAgICAgICAgICA8IS0tIExvZyBUZXh0IEFyZWEgLS0+CiAgICAgICAgICAgICAgICA8UmljaFRleHRC'
        'b3ggR3JpZC5Sb3c9IjIiIE5hbWU9InR4dENvbnNvbGVMb2ciIEJhY2tncm91bmQ9IlRyYW5zcGFyZW50IiBGb3JlZ3JvdW5kPSIj'
        'NmVlN2I3IiBGb250RmFtaWx5PSJDb25zb2xhcyIgRm9udFNpemU9IjExIgogICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJv'
        'cmRlclRoaWNrbmVzcz0iMCIgSXNSZWFkT25seT0iVHJ1ZSIgVmVydGljYWxTY3JvbGxCYXJWaXNpYmlsaXR5PSJBdXRvIiBIb3Jp'
        'em9udGFsU2Nyb2xsQmFyVmlzaWJpbGl0eT0iQXV0byI+CiAgICAgICAgICAgICAgICAgICAgPEZsb3dEb2N1bWVudCBQYWdlUGFk'
        'ZGluZz0iMCI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxQYXJhZ3JhcGggTWFyZ2luPSIwIj4KICAgICAgICAgICAgICAgICAg'
        'ICAgICAgICAgIDxSdW4gVGV4dD0iUmVhZHkuIFNlbGVjdCBkZXNpcmVkIG9wdGltaXphdGlvbiBvcHRpb25zIGFuZCBjbGljayBT'
        'VEFSVCBPUFRJTUlaQVRJT04uIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvUGFyYWdyYXBoPgogICAgICAgICAgICAgICAg'
        'ICAgIDwvRmxvd0RvY3VtZW50PgogICAgICAgICAgICAgICAgPC9SaWNoVGV4dEJveD4KICAgICAgICAgICAgPC9HcmlkPgogICAg'
        'ICAgIDwvQm9yZGVyPgoKICAgICAgICA8IS0tIEJvdHRvbSBBY3Rpb24gQmFyIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9'
        'IjQiIE1hcmdpbj0iMCw4LDAsMCI+CiAgICAgICAgICAgIDxEb2NrUGFuZWwgTGFzdENoaWxkRmlsbD0iVHJ1ZSI+CiAgICAgICAg'
        'ICAgICAgICA8U3RhY2tQYW5lbCBEb2NrUGFuZWwuRG9jaz0iUmlnaHQiIE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIiBWZXJ0aWNh'
        'bEFsaWdubWVudD0iQ2VudGVyIj4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkV4cG9ydExvZyIgQ29udGVu'
        'dD0i8J+SviBFeHBvcnQgTG9nIiBNYXJnaW49IjAsMCw2LDAiIFBhZGRpbmc9IjEyLDYiLz4KICAgICAgICAgICAgICAgICAgICA8'
        'QnV0dG9uIE5hbWU9ImJ0blNraXBCb3R0b20iIENvbnRlbnQ9IuKPrSBTS0lQIFNURVAiIEJhY2tncm91bmQ9IiNkOTc3MDYiIEJv'
        'cmRlckJydXNoPSIjZjU5ZTBiIiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBGb250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNCw2IiBN'
        'YXJnaW49IjAsMCw2LDAiIEZvbnRTaXplPSIxMiIgSXNFbmFibGVkPSJGYWxzZSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0'
        'b24gTmFtZT0iYnRuU3RhcnRCb3R0b20iIENvbnRlbnQ9IvCfmoAg0J7Qn9Ci0JjQnNCY0JfQmNCg0J7QktCQ0KLQrCIgQmFja2dy'
        'b3VuZD0iIzAwNzdiNiIgQm9yZGVyQnJ1c2g9IiMwMDk2YzciIEZvcmVncm91bmQ9IiNmZmZmZmYiIEZvbnRXZWlnaHQ9IkJvbGQi'
        'IFBhZGRpbmc9IjE2LDYiIE1hcmdpbj0iMCwwLDYsMCIgRm9udFNpemU9IjEyIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRv'
        'biBOYW1lPSJidG5SZWJvb3RCb3R0b20iIENvbnRlbnQ9IuKaoSBSRUJPT1QiIEJhY2tncm91bmQ9IiNkYzI2MjYiIEJvcmRlckJy'
        'dXNoPSIjZmY0ZDRmIiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBGb250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNiw2IiBNYXJnaW49'
        'IjAsMCw2LDAiIEZvbnRTaXplPSIxMiIgVmlzaWJpbGl0eT0iVmlzaWJsZSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24g'
        'TmFtZT0iYnRuRXhpdEJvdHRvbSIgQ29udGVudD0iRXhpdCIgTWFyZ2luPSIwLDAsMCwwIiBQYWRkaW5nPSIxMiw2Ii8+CiAgICAg'
        'ICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBPcmllbnRhdGlvbj0iVmVydGljYWwi'
        'IFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiIE1hcmdpbj0iMCwwLDEyLDAiPgogICAgICAgICAgICAgICAgICAgIDxQcm9ncmVz'
        'c0JhciBOYW1lPSJwYlByb2dyZXNzIiBIZWlnaHQ9IjgiIE1pbmltdW09IjAiIE1heGltdW09IjEwMCIgVmFsdWU9IjAiIEZvcmVn'
        'cm91bmQ9IiMwMGI0ZDgiIEJhY2tncm91bmQ9IiMyNTI4MmUiIEJvcmRlclRoaWNrbmVzcz0iMCIgTWFyZ2luPSIwLDAsMCw0Ii8+'
        'CiAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBOYW1lPSJ0eHRTdGF0dXMiIFRleHQ9IlJlYWR5LiAxMTQgT3B0aW1pemF0'
        'aW9uIE1vZHVsZXMgQWN0aXZlLiIgRm9yZWdyb3VuZD0iIzk0OWJhNCIgRm9udFNpemU9IjExIi8+CiAgICAgICAgICAgICAgICA8'
        'L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgogICAgICAgIDwvQm9yZGVyPgogICAgPC9HcmlkPgo8L1dpbmRv'
        'dz4='
    ) -join '')
$xamlBytes = [System.Convert]::FromBase64String($xamlBase64)

$xamlString = [System.Text.Encoding]::UTF8.GetString($xamlBytes)

$reader = New-Object System.Xml.XmlTextReader (New-Object System.IO.StringReader $xamlString)

$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Ensure window opens maximized across entire screen
$window.WindowState = [System.Windows.WindowState]::Maximized

# Set Application Icon safely
try {
    $icoCandidates = @("app.ico")
    if ($env:LOCALAPPDATA) { $icoCandidates += "$env:LOCALAPPDATA\GIN-Win-Optimizer\app.ico" }
    if ($env:TEMP) { $icoCandidates += "$env:TEMP\GIN-Win-Optimizer\app.ico" }
    foreach ($ic in $icoCandidates) {
        if (Test-Path $ic) {
            $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new((Resolve-Path $ic).Path))
            break
        }
    }
} catch {}

# Map UI Controls

$chkNames = @(

    "chk_telem_diagtrack", "chk_telem_dmwappush", "chk_telem_wer", "chk_telem_allow_telem",

    "chk_telem_ad_id", "chk_telem_inking", "chk_telem_activity", "chk_telem_location",

    "chk_telem_feedback", "chk_telem_tasks", "chk_telem_cortana", "chk_net_wifi_privacy",

    "chk_sec_uac_quiet", "chk_sec_admin_approval", "chk_sec_smartscreen", "chk_sec_open_file_warning",

    "chk_cloud_onedrive", "chk_cloud_settings_sync", "chk_cloud_bing_search", "chk_cloud_spotlight",

    "chk_cloud_consumer_features",

    "chk_edge_background", "chk_edge_startup_boost", "chk_edge_telemetry", "chk_edge_sidebar",

    "chk_edge_prelaunch", "chk_edge_first_run", "chk_edge_unpin", "chk_browser_updaters",

    "chk_reloc_documents", "chk_reloc_desktop", "chk_ui_widgets", "chk_ui_teams_chat", "chk_ui_copilot", "chk_ui_recall",

    "chk_ui_start_ads", "chk_ui_explorer_ads", "chk_ui_welcome_screen", "chk_ui_lockscreen_clean", "chk_ui_color_accent_theme", "chk_ui_mouse_inverted_large", "chk_ui_classic_context",

    "chk_ui_hide_search", "chk_ui_hide_taskview", "chk_ui_show_all_tray_icons",

    "chk_ui_never_combine_taskbar", "chk_ui_show_this_pc", "chk_ui_clock_24h_seconds", "chk_ui_region_time_czech", "chk_ui_lang_keyboards", "chk_ui_regional_date_format",

    "chk_tb_small_icons", "chk_tb_lock", "chk_tb_hide_action_center", "chk_tb_hide_people",

    "chk_exp_open_this_pc", "chk_ui_folder_view_list_sort_type", "chk_exp_hide_user_folders", "chk_exp_no_shortcut_suffix",

    "chk_exp_hide_quick_access_recent", "chk_exp_show_full_path", "chk_exp_separate_process",

    "chk_exp_hide_nav_libraries", "chk_desktop_show_user_folder",

    "chk_ctx_cleanup_bloat", "chk_ctx_intel_graphics", "chk_ctx_winrar_email",

    "chk_wu_disable_auto_updates", "chk_wu_exclude_drivers", "chk_wu_exclude_msrt",

    "chk_sys_bsod_no_autoreboot", "chk_sys_small_minidump",

    "chk_sys_fast_startup_off", "chk_sys_disable_remote_assist",

    "chk_sys_enable_photo_viewer", "chk_sys_notepad_tweaks",

    "chk_app_xbox", "chk_app_gamebar_disable", "chk_app_games", "chk_app_news", "chk_app_office_stub",

    "chk_app_clipchamp", "chk_app_people", "chk_app_feedback", "chk_app_get_help", "chk_app_phone",

    "chk_srv_sysmain", "chk_srv_indexing", "chk_srv_remote_reg", "chk_srv_delivery_opt",

    "chk_srv_reserved_storage", "chk_srv_hibernation", "chk_srv_power_plan", "chk_srv_power_sleep_screen", "chk_srv_ssd_trim",
    "chk_srv_pagefile_auto",

    "chk_srv_network_offload", "chk_srv_visual_appearance", "chk_srv_pca", "chk_srv_trkwks", "chk_srv_iphlpsvc",
    "chk_srv_oem_lenovo", "chk_srv_intel_graphics", "chk_srv_conexant_audio",

    "chk_clean_user_temp", "chk_clean_win_temp", "chk_clean_soft_dist", "chk_clean_thumb_cache",

    "chk_clean_shaders_dns", "chk_clean_event_logs", "chk_clean_recycle_bin", "chk_clean_cleanmgr",

    "chk_deep_dism_repair", "chk_deep_dism_resetbase", "chk_deep_sfc_compact"

)

$controls = @{}

foreach ($name in $chkNames) {

    $ctrl = $window.FindName($name)

    if ($ctrl) { $controls[$name] = $ctrl }

}

# Hardened initial state: Defaults configured per Vladimir requirements
if ($controls["chk_sec_admin_approval"]) { $controls["chk_sec_admin_approval"].IsChecked = $false }
if ($controls["chk_srv_network_offload"]) { $controls["chk_srv_network_offload"].IsChecked = $false }
if ($controls["chk_browser_updaters"]) { $controls["chk_browser_updaters"].IsChecked = $true }
if ($controls["chk_srv_pca"]) { $controls["chk_srv_pca"].IsChecked = $true }
if ($controls["chk_srv_trkwks"]) { $controls["chk_srv_trkwks"].IsChecked = $true }
if ($controls["chk_srv_iphlpsvc"]) { $controls["chk_srv_iphlpsvc"].IsChecked = $true }
if ($controls["chk_app_office_stub"]) { $controls["chk_app_office_stub"].IsChecked = $true }
if ($controls["chk_deep_dism_repair"]) { $controls["chk_deep_dism_repair"].IsChecked = $false }
if ($controls["chk_deep_dism_resetbase"]) { $controls["chk_deep_dism_resetbase"].IsChecked = $false }
if ($controls["chk_deep_sfc_compact"]) { $controls["chk_deep_sfc_compact"].IsChecked = $false }
if ($controls["chk_tb_small_icons"]) { $controls["chk_tb_small_icons"].IsChecked = $false }
if ($controls["chk_desktop_show_user_folder"]) { $controls["chk_desktop_show_user_folder"].IsChecked = $false }
if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }

# Find Buttons & Bars

$btnStartTop      = $window.FindName("btnStartTop")

$btnStartBottom   = $window.FindName("btnStartBottom")

$btnSkipTop       = $window.FindName("btnSkipTop")

$btnSkipBottom    = $window.FindName("btnSkipBottom")

$btnExitTop       = $window.FindName("btnExitTop")
$btnRebootTop     = $window.FindName("btnRebootTop")
$btnRebootBottom  = $window.FindName("btnRebootBottom")

$btnExitBottom    = $window.FindName("btnExitBottom")

$btnSelectAll     = $window.FindName("btnSelectAll")

$btnDeselectAll   = $window.FindName("btnDeselectAll")

$btnPresetOffice  = $window.FindName("btnPresetOffice")

$btnPresetGaming  = $window.FindName("btnPresetGaming")

$btnExportLog     = $window.FindName("btnExportLog")

$btnClearLog      = $window.FindName("btnClearLog")

$btnCopyLog       = $window.FindName("btnCopyLog")

$btnTelegram      = $window.FindName("btnTelegram")
$btnLangRu        = $window.FindName("btnLangRu")

$btnLangEn        = $window.FindName("btnLangEn")

$btnLangCs        = $window.FindName("btnLangCs")

$txtConsoleLog    = $window.FindName("txtConsoleLog")
if ($txtConsoleLog -is [System.Windows.Controls.RichTextBox]) {
    $txtConsoleLog | Add-Member -MemberType ScriptProperty -Name "Text" -Value {
        (New-Object System.Windows.Documents.TextRange($this.Document.ContentStart, $this.Document.ContentEnd)).Text
    } -SecondValue {
        param($val)
        $this.Document.Blocks.Clear()
        if ($val) {
            $p = New-Object System.Windows.Documents.Paragraph
            $p.Margin = [System.Windows.Thickness]::new(0)
            $p.Inlines.Add((New-Object System.Windows.Documents.Run($val)))
            $this.Document.Blocks.Add($p)
        }
    } -Force
}

$pbProgress       = $window.FindName("pbProgress")

$pbSubTask        = $window.FindName("pbSubTask")

$txtStatus        = $window.FindName("txtStatus")

$txtSubStatus     = $window.FindName("txtSubStatus")

$txtHeaderTitle   = $window.FindName("txtHeaderTitle")

$txtHeaderSub     = $window.FindName("txtHeaderSub")

$txtHostInfo      = $window.FindName("txtHostInfo")

$txtPresets       = $window.FindName("txtPresets")

# GroupBoxes

$groupNames = @("grpPrivacy", "grpSecurity", "grpCloud", "grpEdge", "grpUI", "grpContextMenu", "grpWinUpdate", "grpApps", "grpServices", "grpClean")

$groups = @{}

foreach ($g in $groupNames) {

    $ctrl = $window.FindName($g)

    if ($ctrl) { $groups[$g] = $ctrl }

}

# Host & Computer Specs Detection (Host, Local, Device Name, Windows Version, IP Address)

$compName = $env:COMPUTERNAME
$userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$ntCur = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
$osCaption = if ($ntCur.ProductName) { $ntCur.ProductName } else { [System.Environment]::OSVersion.VersionString }
$osDisplayVer = if ($ntCur.DisplayVersion) { $ntCur.DisplayVersion } elseif ($ntCur.ReleaseId) { $ntCur.ReleaseId } else { "" }
if ($osDisplayVer -and ($osCaption -notmatch [regex]::Escape($osDisplayVer))) { $osCaption = "$osCaption $osDisplayVer" }

# IP Address Detection (Fast, clean IPv4, filtering virtual/VPN adapters)
$ipAddress = try {
    (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
        $_.InterfaceAlias -notmatch 'vEthernet|Virtual|Loopback|Pseudo|Tailscale|ZeroTier|TAP' -and 
        $_.IPAddress -notlike '169.254*' -and 
        $_.IPAddress -ne '127.0.0.1' 
    } | Select-Object -ExpandProperty IPAddress -First 1)
} catch { $null }

if (-not $ipAddress) {
    try {
        $ipAddress = ([System.Net.Dns]::GetHostAddresses($compName) | Where-Object { 
            $_.AddressFamily -eq 'InterNetwork' -and 
            $_.IPAddressToString -notlike '127.*' -and 
            $_.IPAddressToString -notlike '169.254*' 
        } | Select-Object -ExpandProperty IPAddressToString -First 1)
    } catch { $null }
}
if (-not $ipAddress) { $ipAddress = "127.0.0.1" }

# Function to switch language instantly in GUI

$global:currentLang = "ru"

$culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name.ToLower()

if ($culture -like "cs*") { $global:currentLang = "cs" }

elseif ($culture -like "en*") { $global:currentLang = "en" }

else { $global:currentLang = "ru" }

function Set-InterfaceLanguage ([string]$targetLang) {

    $global:currentLang = $targetLang

    $loc = $t[$targetLang]

    $window.Title = $loc["Title"]

    if ($txtHeaderTitle) { $txtHeaderTitle.Text = $loc["HeaderTitle"] }

    if ($txtHeaderSub)   { $txtHeaderSub.Text = $loc["HeaderSub"] }

    if ($txtHostInfo)    { $txtHostInfo.Text = [string]::Format($loc["HostFormat"], $compName, $osCaption, $ipAddress) }

    if ($txtPresets)     { $txtPresets.Text = $loc["Presets"] }

    if ($btnSelectAll)    { $btnSelectAll.Content = $loc["BtnSelectAll"] }

    if ($btnDeselectAll)  { $btnDeselectAll.Content = $loc["BtnDeselectAll"] }

    if ($btnPresetOffice) { $btnPresetOffice.Content = $loc["BtnPresetOffice"] }

    if ($btnPresetGaming) { $btnPresetGaming.Content = $loc["BtnPresetGaming"] }

    if ($btnStartTop)    { $btnStartTop.Content = $loc["BtnStart"] }

    if ($btnStartBottom) { $btnStartBottom.Content = $loc["BtnStartBottom"] }

    if ($btnSkipTop)     { $btnSkipTop.Content = $loc["BtnSkip"] }

    if ($btnSkipBottom)  { $btnSkipBottom.Content = $loc["BtnSkip"] }

    if ($btnExitTop)     { $btnExitTop.Content = $loc["BtnExit"] }
    if ($btnRebootTop)     { $btnRebootTop.Content = $loc["BtnReboot"] }
    if ($btnRebootBottom)  { $btnRebootBottom.Content = $loc["BtnReboot"] }

    if ($btnExitBottom)  { $btnExitBottom.Content = $loc["BtnExit"] }

    if ($btnExportLog)   { $btnExportLog.Content = $loc["BtnExport"] }

    if ($btnClearLog)    { $btnClearLog.Content = $loc["BtnClear"] }

    if ($btnCopyLog)     { $btnCopyLog.Content = $loc["BtnCopy"] }

    # Update GroupBox Headers

    foreach ($gKey in $groups.Keys) {

        if ($loc.ContainsKey($gKey)) {

            $groups[$gKey].Header = $loc[$gKey]

        }

    }

    # Update Checkbox Texts

    foreach ($k in $controls.Keys) {

        if ($loc.ContainsKey($k)) {

            $controls[$k].Content = $loc[$k]

        }

    }

    # Update active language button styles (clean RU, EN, CZ text)

    $brushConv = New-Object System.Windows.Media.BrushConverter

    if ($btnLangRu) { $btnLangRu.Content = "RU" }

    if ($btnLangEn) { $btnLangEn.Content = "EN" }

    if ($btnLangCs) { $btnLangCs.Content = "CZ" }

    if ($targetLang -eq "ru") {

        $btnLangRu.Background  = $brushConv.ConvertFromString("#1e3a5f")

        $btnLangRu.BorderBrush = $brushConv.ConvertFromString("#00b4d8")

        $btnLangRu.Foreground  = $brushConv.ConvertFromString("#ffffff")

    } else {

        $btnLangRu.Background  = $brushConv.ConvertFromString("#25282e")

        $btnLangRu.BorderBrush = $brushConv.ConvertFromString("#3a3d45")

        $btnLangRu.Foreground  = $brushConv.ConvertFromString("#b0b3b8")

    }

    if ($targetLang -eq "en") {

        $btnLangEn.Background  = $brushConv.ConvertFromString("#1e3a5f")

        $btnLangEn.BorderBrush = $brushConv.ConvertFromString("#00b4d8")

        $btnLangEn.Foreground  = $brushConv.ConvertFromString("#ffffff")

    } else {

        $btnLangEn.Background  = $brushConv.ConvertFromString("#25282e")

        $btnLangEn.BorderBrush = $brushConv.ConvertFromString("#3a3d45")

        $btnLangEn.Foreground  = $brushConv.ConvertFromString("#b0b3b8")

    }

    if ($targetLang -eq "cs") {

        $btnLangCs.Background  = $brushConv.ConvertFromString("#1e3a5f")

        $btnLangCs.BorderBrush = $brushConv.ConvertFromString("#00b4d8")

        $btnLangCs.Foreground  = $brushConv.ConvertFromString("#ffffff")

    } else {

        $btnLangCs.Background  = $brushConv.ConvertFromString("#25282e")

        $btnLangCs.BorderBrush = $brushConv.ConvertFromString("#3a3d45")

        $btnLangCs.Foreground  = $brushConv.ConvertFromString("#b0b3b8")

    }

        # Highlight yellow shell relocation checkboxes
    if ($controls["chk_reloc_documents"]) {
        $controls["chk_reloc_documents"].Foreground = $brushConv.ConvertFromString("#facc15")
        $controls["chk_reloc_documents"].FontWeight = [System.Windows.FontWeights]::Bold
    }
    if ($controls["chk_reloc_desktop"]) {
        $controls["chk_reloc_desktop"].Foreground = $brushConv.ConvertFromString("#facc15")
        $controls["chk_reloc_desktop"].FontWeight = [System.Windows.FontWeights]::Bold
    }
    # Keep the two longest settings bright red and bold

    if ($controls["chk_deep_dism_repair"]) {

        $controls["chk_deep_dism_repair"].Foreground = $brushConv.ConvertFromString("#ff4d4f")

        $controls["chk_deep_dism_repair"].FontWeight = [System.Windows.FontWeights]::Bold

    }

    if ($controls["chk_deep_dism_resetbase"]) {

        $controls["chk_deep_dism_resetbase"].Foreground = $brushConv.ConvertFromString("#ff4d4f")

        $controls["chk_deep_dism_resetbase"].FontWeight = [System.Windows.FontWeights]::Bold

    }

    if ($txtStatus.Text -match 'Ready|Připraveno|Готово') {

        $txtStatus.Text = $loc["StatusReady"]

    }

}

# Attach Language Button Handlers

if ($btnTelegram) {
    $btnTelegram.Add_Click({
        try { Start-Process "https://t.me/GinCz" } catch {}
    })
}
$btnLangRu.Add_Click({ Set-InterfaceLanguage "ru" })

$btnLangEn.Add_Click({ Set-InterfaceLanguage "en" })

$btnLangCs.Add_Click({ Set-InterfaceLanguage "cs" })

# Initial language application

Set-InterfaceLanguage $global:currentLang

# Enhanced Logging Function

function Log-Message {

    param([string]$Message, [string]$Type = "INFO")

    $stamp = (Get-Date).ToString("HH:mm:ss")

    $prefix = switch ($Type) {

        "SUCCESS" { "[SUCCESS]" }

        "WARN"    { "[WARN]   " }

        "ERROR"   { "[ERROR]  " }

        "APPX"    { "[APPX]   " }

        "SUB"     { "[OUTPUT] " }

        default   { "[INFO]   " }

    }

    $logLine = "[$stamp] $prefix $Message"

    $txtConsoleLog.AppendText("$logLine`r`n")

    $txtConsoleLog.ScrollToEnd()

    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

}

# Preset Handlers

$btnSelectAll.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

    if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
    if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }
    if ($controls["chk_srv_network_offload"]) { $controls["chk_srv_network_offload"].IsChecked = $false }
    if ($controls["chk_browser_updaters"]) { $controls["chk_browser_updaters"].IsChecked = $true }
if ($controls["chk_srv_pca"]) { $controls["chk_srv_pca"].IsChecked = $true }
    if ($controls["chk_srv_trkwks"]) { $controls["chk_srv_trkwks"].IsChecked = $true }
    if ($controls["chk_srv_iphlpsvc"]) { $controls["chk_srv_iphlpsvc"].IsChecked = $true }
    if ($controls["chk_sec_admin_approval"]) { $controls["chk_sec_admin_approval"].IsChecked = $false }
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Select All (Max Clean - LAN & Compatibility Protected)" "INFO"

})

$btnDeselectAll.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $false }

    Log-Message "Preset applied: Deselect All" "INFO"

})

$btnPresetOffice.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_cloud_onedrive"].IsChecked = $false

    $controls["chk_app_office_stub"].IsChecked = $true

    $controls["chk_app_phone"].IsChecked = $false

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

    if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
    if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }
    if ($controls["chk_srv_network_offload"]) { $controls["chk_srv_network_offload"].IsChecked = $false }
    if ($controls["chk_browser_updaters"]) { $controls["chk_browser_updaters"].IsChecked = $true }
if ($controls["chk_srv_pca"]) { $controls["chk_srv_pca"].IsChecked = $true }
    if ($controls["chk_srv_trkwks"]) { $controls["chk_srv_trkwks"].IsChecked = $true }
    if ($controls["chk_srv_iphlpsvc"]) { $controls["chk_srv_iphlpsvc"].IsChecked = $true }
    if ($controls["chk_srv_indexing"]) { $controls["chk_srv_indexing"].IsChecked = $false }
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Office (OneDrive, Search Indexing, LAN & Accounting Compatibility preserved)" "INFO"

})

$btnPresetGaming.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_app_xbox"].IsChecked = $false
    if ($controls["chk_app_gamebar_disable"]) { $controls["chk_app_gamebar_disable"].IsChecked = $false }

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

    if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
    if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }
    if ($controls["chk_srv_network_offload"]) { $controls["chk_srv_network_offload"].IsChecked = $false }
    if ($controls["chk_browser_updaters"]) { $controls["chk_browser_updaters"].IsChecked = $true }
if ($controls["chk_srv_pca"]) { $controls["chk_srv_pca"].IsChecked = $true }
    if ($controls["chk_srv_trkwks"]) { $controls["chk_srv_trkwks"].IsChecked = $true }
    if ($controls["chk_srv_iphlpsvc"]) { $controls["chk_srv_iphlpsvc"].IsChecked = $true }
    if ($controls["chk_sec_admin_approval"]) { $controls["chk_sec_admin_approval"].IsChecked = $false }
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Gaming (Xbox app, GameBar & LAN Compatibility preserved)" "INFO"

})

# Skip Step Handler

$global:skipStepRequested = $false

$global:activeProcess = $null

$onSkipClick = {

    $global:skipStepRequested = $true

    if ($global:activeProcess -and -not $global:activeProcess.HasExited) {

        try { $global:activeProcess.Kill() } catch {}

    }

    Get-Process cleanmgr, TiWorker, dism, sfc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Log-Message "Skip requested by user. Aborting active operation..." "WARN"

}

if ($btnSkipTop) { $btnSkipTop.Add_Click($onSkipClick) }

if ($btnSkipBottom) { $btnSkipBottom.Add_Click($onSkipClick) }

# Non-Blocking Live Output Process Runner (Single-Threaded Dispatcher Safe)

function Invoke-ProcessWithLiveOutput {

    param (

        [string]$FilePath,

        [string]$Arguments,

        [string]$TaskName,

        [int]$TimeoutSeconds = 300

    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $psi = New-Object System.Diagnostics.ProcessStartInfo

    $psi.FileName = $FilePath

    $psi.Arguments = $Arguments

    $psi.RedirectStandardOutput = $true

    $psi.RedirectStandardError = $true

    $psi.UseShellExecute = $false

    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process

    $proc.StartInfo = $psi

    $global:activeProcess = $proc

    $global:skipStepRequested = $false

    if ($pbSubTask) { $pbSubTask.Value = 0 }

    if ($txtSubStatus) { $txtSubStatus.Text = "$($TaskName): Running..." }

    $null = $proc.Start()

    while (-not $proc.WaitForExit(100)) {

        if ($global:skipStepRequested) {

            try { $proc.Kill() } catch {}

            if ($TaskName -like "*Cleanmgr*") {

                Get-Process cleanmgr, TiWorker -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            }

            Log-Message "[$current/$total] [SKIPPED] Skipped: $($TaskName)" "WARN"

            break

        }

        if ($sw.Elapsed.TotalSeconds -gt $TimeoutSeconds) {

            try { $proc.Kill() } catch {}

            if ($TaskName -like "*Cleanmgr*") {

                Get-Process cleanmgr, TiWorker -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            }

            Log-Message "[$current/$total] [TIMEOUT] Timed out after ${TimeoutSeconds}s: $($TaskName)" "WARN"

            break

        }

        # Drain output synchronously in Dispatcher loop without cross-thread delegate crashes

        while (-not $proc.StandardOutput.EndOfStream -and ($proc.StandardOutput.Peek() -ne -1)) {

            $line = $proc.StandardOutput.ReadLine()

            if ($line) {

                $raw = $line.Trim()

                if ($raw) {

                    if ($raw -match '(\d{1,3}(?:\.\d+)?)\s*%') {

                        $pctVal = [double]$matches[1]

                        if ($pbSubTask) { $pbSubTask.Value = $pctVal }

                        if ($txtSubStatus) { $txtSubStatus.Text = "$($TaskName): $pctVal%" }

                    }

                    if ($raw -notmatch '^\[=+\]$') {

                        Log-Message "[$($TaskName)] $raw" "SUB"

                    }

                }

            }

        }

        $elapsed = $sw.Elapsed.ToString('mm\:ss')

        $loc = $t[$global:currentLang]

        $txtStatus.Text = "$($loc['StatusRunning']) $pct% ($current/$total) | $($TaskName) [$elapsed]"

        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

    }

    # Drain any remaining lines

    try {

        while (-not $proc.StandardOutput.EndOfStream -and ($proc.StandardOutput.Peek() -ne -1)) {

            $finLine = $proc.StandardOutput.ReadLine()

            if ($finLine) {

                $raw = $finLine.Trim()

                if ($raw -and ($raw -notmatch '^\[=+\]$')) {

                    Log-Message "[$($TaskName)] $raw" "SUB"

                }

            }

        }

    } catch {}

    $sw.Stop()

    if ($pbSubTask) { $pbSubTask.Value = 100 }

    if ($txtSubStatus) { $txtSubStatus.Text = "$($TaskName): Done ($($sw.Elapsed.ToString('mm\:ss')))" }

    $global:activeProcess = $null

}

$btnExitTop.Add_Click({ $window.Close() })

$btnExitBottom.Add_Click({ $window.Close() })

$rebootAction = {
    $confirmMsg = switch ($global:currentLang) {
        "en" { "Are you sure you want to restart your computer now?" }
        "cs" { "Opravdu chcete nyní restartovat počítač?" }
        "ru" { "Вы действительно хотите перезагрузить компьютер прямо сейчас?" }
    }
    $res = [System.Windows.MessageBox]::Show($confirmMsg, "GIN-Win-Optimizer v047 [VladiMIR + AI]", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Log-Message "System restart initiated by user. Restarting in 2 seconds..." "WARN"
        Start-Process shutdown.exe -ArgumentList "/r /t 2 /c `"GIN-Win-Optimizer: Reboot requested by user`""
    }
}
if ($btnRebootTop)    { $btnRebootTop.Add_Click($rebootAction) }
if ($btnRebootBottom) { $btnRebootBottom.Add_Click($rebootAction) }

$btnClearLog.Add_Click({

    if ($txtConsoleLog -is [System.Windows.Controls.RichTextBox]) {
        $txtConsoleLog.Document.Blocks.Clear()
    } else {
        $txtConsoleLog.Text = ""
    }

    Log-Message "Terminal log cleared." "INFO"

})

$btnCopyLog.Add_Click({

    $logContent = if ($txtConsoleLog -is [System.Windows.Controls.RichTextBox]) {
        (New-Object System.Windows.Documents.TextRange($txtConsoleLog.Document.ContentStart, $txtConsoleLog.Document.ContentEnd)).Text
    } else {
        $txtConsoleLog.Text
    }

    [System.Windows.Clipboard]::SetText($logContent)

    Log-Message "Log copied to clipboard." "SUCCESS"

})

$btnExportLog.Add_Click({

    $desktopPath = [Environment]::GetFolderPath("Desktop")

    if (Test-Path "D:\MEGA\DOCS\desktop") { $desktopPath = "D:\MEGA\DOCS\desktop" }

    $logFile = Join-Path $desktopPath ("Optimizer_Log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

    $logContent = if ($txtConsoleLog -is [System.Windows.Controls.RichTextBox]) {
        (New-Object System.Windows.Documents.TextRange($txtConsoleLog.Document.ContentStart, $txtConsoleLog.Document.ContentEnd)).Text
    } else {
        $txtConsoleLog.Text
    }

    $logContent | Out-File -FilePath $logFile -Encoding UTF8

    [System.Windows.MessageBox]::Show("Log exported successfully to:`n$logFile", "Export Log", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

})

function Purge-StartMenuLegacyJunk {
    param([string]$Context = "General")
    try {
        $startRoots = @(
            "C:\ProgramData\Microsoft\Windows\Start Menu\Programs",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
            "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
        )
        $junkShortcuts = @(
            "Speech Recognition.lnk",
            "Math Input Panel.lnk",
            "Steps Recorder.lnk",
            "Windows Fax and Scan.lnk",
            "Character Map.lnk"
        )
        $purgedCount = 0
        foreach ($root in $startRoots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($fn in @("Accessibility", "Accessories")) {
                $dirPath = Join-Path $root $fn
                if (Test-Path $dirPath) {
                    foreach ($junk in $junkShortcuts) {
                        $found = Get-ChildItem -Path $dirPath -Filter $junk -Recurse -Force -ErrorAction SilentlyContinue
                        if ($found) {
                            $found | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                            $purgedCount++
                        }
                    }
                    $sysTools = Join-Path $dirPath "System Tools"
                    if ((Test-Path $sysTools) -and (Get-ChildItem $sysTools -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                        Remove-Item -Path $sysTools -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    if ($fn -eq "Accessibility") {
                        Remove-Item -Path $dirPath -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    if ($fn -eq "Accessories") {
                        $rem = Get-ChildItem -Path $dirPath -Recurse -File -Force -ErrorAction SilentlyContinue
                        if ($rem.Count -eq 0 -or ($rem | Where-Object { $_.Name -notmatch "(?i)Notepad|Paint|Wordpad|Remote Desktop|Snipping" }).Count -eq 0) {
                            Remove-Item -Path $dirPath -Force -Recurse -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }
        if ($purgedCount -gt 0) {
            Log-Message "Purged $purgedCount legacy Start Menu applet shortcut(s) and folders ($Context)." "SUCCESS"
        }
    } catch {}
}

# Execution Engine Action Definition

$executeOptimization = {

    if ($txtStatus) {
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#949ba4")
        $txtStatus.FontWeight = [System.Windows.FontWeights]::Normal
    }

    $btnStartTop.IsEnabled = $false

    $btnStartBottom.IsEnabled = $false

    if ($btnSkipTop) { $btnSkipTop.IsEnabled = $true }

    if ($btnSkipBottom) { $btnSkipBottom.IsEnabled = $true }

    $btnSelectAll.IsEnabled = $false

    $btnDeselectAll.IsEnabled = $false

    $btnPresetOffice.IsEnabled = $false

    $btnPresetGaming.IsEnabled = $false

    $actions = [System.Collections.Generic.List[object]]::new()

    # 1. Privacy & Telemetry

    if ($controls["chk_telem_diagtrack"].IsChecked) {

        $actions += @{ Name = "Disable DiagTrack Service"; Script = {

            Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_dmwappush"].IsChecked) {

        $actions += @{ Name = "Disable dmwappushservice"; Script = {

            Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_wer"].IsChecked) {

        $actions += @{ Name = "Disable Windows Error Reporting (WerSvc)"; Script = {

            Stop-Service -Name "WerSvc" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "WerSvc" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WerSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_allow_telem"].IsChecked) {

        $actions += @{ Name = "Disable Telemetry via Policies"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "MaxTelemetryAllowed" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_ad_id"].IsChecked) {

        $actions += @{ Name = "Disable Advertising ID"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_inking"].IsChecked) {

        $actions += @{ Name = "Disable Inking & Typing Personalization"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\InputPersonalization" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_activity"].IsChecked) {

        $actions += @{ Name = "Disable Activity History & Timeline"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_location"].IsChecked) {

        $actions += @{ Name = "Disable Geolocation & Sensor Service"; Script = {

            Stop-Service -Name "lfsvc" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "lfsvc" -StartupType Disabled -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_feedback"].IsChecked) {

        $actions += @{ Name = "Disable Feedback Surveys"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_telem_tasks"].IsChecked) {

        $actions += @{ Name = "Disable CEIP & Telemetry Scheduled Tasks"; Script = {

            $tasks = @(

                "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",

                "\Microsoft\Windows\Application Experience\ProgramDataUpdater",

                "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",

                "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",

                "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"

            )

            foreach ($t in $tasks) {

                schtasks.exe /change /tn "$t" /disable 2>$null | Out-Null

            }

        }}

    }

    if ($controls["chk_telem_cortana"].IsChecked) {

        $actions += @{ Name = "Completely Uninstall & Purge Cortana Assistant"; Script = {

            Log-Message "Completely removing Cortana package and disabling assistant..." "INFO"
            Stop-Process -Name "Cortana" -Force -ErrorAction SilentlyContinue
            Get-AppxPackage -AllUsers -Name "*Microsoft.549981C3F5F10*" -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxPackage -AllUsers -Name "*Cortana*" -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*Cortana*" -or $_.PackageName -like "*549981C3F5F10*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CanCortanaBeOrganized" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_net_wifi_privacy"].IsChecked) {
        $actions += @{ Name = "Disable Wi-Fi Random MAC & Hotspot 2.0 Online Sign-Up"; Script = {
            Log-Message "Disabling Wi-Fi MAC Randomization and Hotspot 2.0 Online Sign-Up..." "INFO"
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\Anonymization" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\Anonymization" -Name "EnableRandomization" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\Anonymization" -Name "EnableAnonymization" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $wlanInterfaces = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\Interfaces" -ErrorAction SilentlyContinue
            if ($wlanInterfaces) {
                foreach ($iface in $wlanInterfaces) {
                    Set-ItemProperty -Path $iface.PSPath -Name "RandomMacState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                }
            }

            New-Item -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\AnqpCache" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WlanSvc\AnqpCache" -Name "OsuRegistrationStatus" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            try {
                $profiles = netsh.exe wlan show profiles 2>$null | Select-String "All User Profile\s*:\s*(.*)$" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
                foreach ($p in $profiles) {
                    if ($p) { netsh.exe wlan set profileparameter name="$p" randomization=disabled 2>$null | Out-Null }
                }
            } catch {}
            Log-Message "Wi-Fi Random Hardware Addresses & Hotspot 2.0 Online Sign-Up disabled." "SUCCESS"
        }}
    }

    # 2. Security & UAC

        if ($controls["chk_sec_uac_quiet"].IsChecked) {
        $actions += @{ Name = "Total Zero-UAC: Disable UAC Completely (EnableLUA=0, Slider to Zero, Never Notify)"; Script = {
            $sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            if (-not (Test-Path $sysPol)) { New-Item -Path $sysPol -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $sysPol -Name "EnableLUA" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "FilterAdministratorToken" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "EnableInstallerDetection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "ValidateAdminCodeSignatures" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysPol -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Log-Message "Total Zero-UAC applied: EnableLUA=0, ConsentPromptBehaviorAdmin=0, ConsentPromptBehaviorUser=0, PromptOnSecureDesktop=0, FilterAdministratorToken=0 (Slider at absolute zero)." "SUCCESS"
        }}
    }

    if ($controls["chk_sec_admin_approval"].IsChecked) {

        $actions += @{ Name = "Enable Admin Approval Mode"; Script = {

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sec_smartscreen"].IsChecked) {

        $actions += @{ Name = "Disable SmartScreen Filter"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sec_open_file_warning"].IsChecked) {

        $actions += @{ Name = "Disable Open File Security Warning"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Name "LowRiskFileTypes" -Value ".exe;.bat;.cmd;.ps1;.vbs;.msi;.reg;.zip;.rar;.7z;" -Type String -ErrorAction SilentlyContinue

        }}

    }

    # 3. Cloud & Consumer

    if ($controls["chk_cloud_onedrive"].IsChecked) {

        $actions += @{ Name = "Uninstall Microsoft OneDrive"; Script = {

            Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue

            $oneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

            if (-not (Test-Path $oneDriveSetup)) { $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe" }

            if (Test-Path $oneDriveSetup) {

                Start-Process $oneDriveSetup -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

            }

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_cloud_settings_sync"].IsChecked) {

        $actions += @{ Name = "Disable Settings Cloud Sync"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value 2 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_cloud_bing_search"].IsChecked) {

        $actions += @{ Name = "Disable Bing Search in Start Menu"; Script = {

            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_cloud_spotlight"].IsChecked) {

        $actions += @{ Name = "Disable Windows Spotlight"; Script = {

            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableSpotlightCollectionOnDesktop" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_cloud_consumer_features"].IsChecked) {

        $actions += @{ Name = "Block Auto-Install of Sponsored Apps"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    # 4. Microsoft Edge

    if ($controls["chk_edge_background"].IsChecked) {

        $actions += @{ Name = "Prevent Edge Background Processes"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_startup_boost"].IsChecked) {

        $actions += @{ Name = "Disable Edge Startup Boost"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_telemetry"].IsChecked) {

        $actions += @{ Name = "Disable Edge Telemetry & Shopping"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_sidebar"].IsChecked) {

        $actions += @{ Name = "Disable Edge Sidebar & Hubs"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_prelaunch"].IsChecked) {

        $actions += @{ Name = "Disable Edge Prelaunch at Boot"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "AllowPrelaunch" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_first_run"].IsChecked) {

        $actions += @{ Name = "Prevent Edge First Run Experience"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_edge_unpin"].IsChecked) {
        $actions += @{ Name = "Unpin Edge & Internet Explorer from Taskbar"; Script = {
            # 0. Deploy empty PinList LayoutModification to permanently prevent Windows from auto-pinning Edge
            try {
                $layoutXml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`r`n<LayoutModificationTemplate xmlns=`"http://schemas.microsoft.com/Start/2014/LayoutModification`" xmlns:defaultlayout=`"http://schemas.microsoft.com/Start/2014/FullDefaultLayout`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`" xmlns:taskbar=`"http://schemas.microsoft.com/Start/2014/TaskbarLayout`" Version=`"1`">`r`n  <CustomTaskbarLayoutCollection PinListPlacement=`"Replace`">`r`n    <defaultlayout:TaskbarLayout>`r`n      <taskbar:TaskbarPinList />`r`n    </defaultlayout:TaskbarLayout>`r`n  </CustomTaskbarLayoutCollection>`r`n</LayoutModificationTemplate>"
                $layoutPaths = @(
                    "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml",
                    "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
                )
                foreach ($lp in $layoutPaths) {
                    $ldir = [System.IO.Path]::GetDirectoryName($lp)
                    if (-not (Test-Path $ldir)) { New-Item -Path $ldir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                    [System.IO.File]::WriteAllText($lp, $layoutXml, [System.Text.Encoding]::UTF8)
                }
            } catch {}

            # 1. AppsFolder COM unpin for modern Edge, Edge Spartan & UWP apps
            try {
                $ruUnpin = [char]0x043E + [char]0x0442 + [char]0x043A + [char]0x0440 + [char]0x0435 + [char]0x043F + [char]0x0438 + [char]0x0442 + [char]0x044C
                $ruPanel = [char]0x043F + [char]0x0430 + [char]0x043D + [char]0x0435 + [char]0x043B
                $appsFolder = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
                if ($appsFolder) {
                    foreach ($item in $appsFolder.Items()) {
                        if ($item.Name -like "*Edge*" -or $item.Path -like "*Edge*" -or $item.Path -like "*iexplore*" -or $item.Name -like "*Internet Explorer*") {
                            foreach ($verb in $item.Verbs()) {
                                $cleanVerb = ($verb.Name -replace "&", "").Trim()
                                if (($cleanVerb -match "(?i)unpin.*taskbar") -or ($cleanVerb -match "(?i)odepnout.*panel") -or ($cleanVerb -match "$ruUnpin.*$ruPanel")) {
                                    $verb.DoIt()
                                }
                            }
                        }
                    }
                }
            } catch {}

            # 2. Remove any pinned .lnk shortcuts from TaskBar and StartMenu
            $tbPaths = @(
                "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar",
                "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu",
                "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch",
                "C:\Users\Default\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
            )
            foreach ($p in $tbPaths) {
                if (Test-Path $p) {
                    Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                        $_.Name -like "*Internet Explorer*" -or $_.Name -like "*iexplore*" -or $_.Name -like "*Edge*"
                    } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
            # 3. Clean desktop shortcuts
            $dtPaths = @(
                [Environment]::GetFolderPath('Desktop'),
                "$env:PUBLIC\Desktop",
                "D:\DOCS\desktop",
                "D:\MEGA\DOCS\desktop"
            )
            foreach ($p in $dtPaths) {
                if ($p -and (Test-Path $p)) {
                    Get-ChildItem -Path $p -Force -ErrorAction SilentlyContinue | Where-Object {
                        $_.Name -like "*Internet Explorer*" -or $_.Name -like "*iexplore*" -or $_.Name -like "*Edge*"
                    } | Remove-Item -Force -ErrorAction SilentlyContinue
                }
            }
            # 4. Enforce native policies to block Edge & IE shortcuts and reinstallations
            $edgeCmds = @(
                'add "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "NotifyDisableIEOptions" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{871C5380-42A0-1069-A2EA-08002B30309D}" /t REG_DWORD /d 1 /f',
                'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{871C5380-42A0-1069-A2EA-08002B30309D}" /t REG_DWORD /d 1 /f',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DoNotCreateTaskbarShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DoNotCreateDesktopShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotCreateTaskbarShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotCreateDesktopShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "DoNotCreateTaskbarShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "DoNotCreateDesktopShortcut" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "DisableEdgeDesktopShortcutCreation" /t REG_DWORD /d 1 /f /reg:64'
            )
            foreach ($cmd in $edgeCmds) {
                $cmdNative = $cmd -replace '\s*/reg:(64|32)', ''
                cmd.exe /c "reg.exe $cmdNative" 2>$null | Out-Null
                if ([Environment]::Is64BitOperatingSystem) {
                    cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
                }
            }
        }}
    }

    if ($controls["chk_browser_updaters"].IsChecked) {
        $actions += @{ Name = "Purge Chrome, Brave & Cent Browser Background Updaters"; Script = {
            Log-Message "Stopping browser background updaters and purging Update directories..." "INFO"

            # 1. Terminate running updater processes
            $updProcs = @("GoogleUpdate", "BraveUpdate", "CentBrowserUpdate", "MicrosoftEdgeUpdate")
            foreach ($p in $updProcs) {
                Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }

            # 2. Stop and disable updater services
            $updServices = @(
                "gupdate", "gupdatem", "GoogleChromeElevationService",
                "brave", "bravem", "BraveElevationService",
                "CentBrowserUpdate", "CentBrowserElevationService",
                "edgeupdate", "edgeupdatem"
            )
            foreach ($s in $updServices) {
                Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
                sc.exe config $s start= disabled 2>$null | Out-Null
            }

            # 3. Delete scheduled updater tasks
            $updTaskPatterns = @("GoogleUpdate*", "*Chrome*", "BraveUpdate*", "*Brave*", "CentBrowserUpdate*", "*CentBrowser*")
            foreach ($pat in $updTaskPatterns) {
                Get-ScheduledTask -TaskName $pat -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            }
            try {
                $rawTasks = schtasks.exe /query /fo csv 2>$null | ConvertFrom-Csv
                foreach ($t in $rawTasks) {
                    $tn = $t.TaskName
                    if ($tn -and ($tn -match "GoogleUpdate|BraveUpdate|CentBrowser")) {
                        schtasks.exe /delete /tn $tn /f 2>$null | Out-Null
                    }
                }
            } catch {}

            # 4. Recursively purge all Update folders across system and user profiles
            $targetDirs = @(
                "$env:ProgramFiles\Google\Update",
                "${env:ProgramFiles(x86)}\Google\Update",
                "$env:LOCALAPPDATA\Google\Update",
                "$env:ProgramFiles\BraveSoftware\Update",
                "${env:ProgramFiles(x86)}\BraveSoftware\Update",
                "$env:LOCALAPPDATA\BraveSoftware\Update",
                "$env:ProgramFiles\CentBrowser\Update",
                "${env:ProgramFiles(x86)}\CentBrowser\Update",
                "$env:LOCALAPPDATA\CentBrowser\Update"
            )
            Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $uDir = $_.FullName
                $targetDirs += "$uDir\AppData\Local\Google\Update"
                $targetDirs += "$uDir\AppData\Local\BraveSoftware\Update"
                $targetDirs += "$uDir\AppData\Local\CentBrowser\Update"
            }
            foreach ($dir in $targetDirs) {
                if (Test-Path $dir) {
                    try {
                        cmd.exe /c "takeown /f `"$dir`" /r /d y" 2>$null | Out-Null
                        cmd.exe /c "icacls `"$dir`" /grant administrators:F /t /c /q" 2>$null | Out-Null
                        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
                        Log-Message "Deleted browser update folder: $dir" "INFO"
                    } catch {}
                }
            }

            # 5. Lock update check via Registry policies (UpdateDefault=0, AutoUpdateCheckPeriodMinutes=0)
            $regPolicies = @(
                "HKLM:\SOFTWARE\Policies\Google\Update",
                "HKLM:\SOFTWARE\Policies\BraveSoftware\Update",
                "HKLM:\SOFTWARE\Policies\CentBrowser\Update"
            )
            foreach ($rp in $regPolicies) {
                New-Item -Path $rp -Force -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path $rp -Name "AutoUpdateCheckPeriodMinutes" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $rp -Name "UpdateDefault" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $rp -Name "DisableAutoUpdateChecksCheckboxValue" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }

            Log-Message "Browser background updaters stopped and Update folders purged." "SUCCESS"
        }}
    }



    # 5. Explorer, Desktop, Taskbar & Start Menu (Dism++ Tweaks)

    # Relocate Documents to D:\DOCS
    if ($controls["chk_reloc_documents"] -and $controls["chk_reloc_documents"].IsChecked) {
        $actions += @{
            Name = "Relocate Documents Folder to D:\DOCS"
            Script = {
                Log-Message "Starting Documents relocation to D:\DOCS..." "INFO"
                try {
                    if (-not (Test-Path "D:\")) {
                        Log-Message "Drive D:\ does not exist! Documents relocation skipped safely." "WARN"
                        return
                    }
                    $targetDocs = "D:\DOCS"
                    if (-not (Test-Path $targetDocs)) {
                        [System.IO.Directory]::CreateDirectory($targetDocs) | Out-Null
                    }
                    $currDocs = [Environment]::GetFolderPath('MyDocuments')
                    if (-not $currDocs -or -not (Test-Path $currDocs)) {
                        try {
                            $currDocs = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).Personal
                            if ($currDocs) { $currDocs = [Environment]::ExpandEnvironmentVariables($currDocs) }
                        } catch {}
                    }
                    if ($currDocs -and (Test-Path $currDocs) -and ($currDocs.TrimEnd('\') -ne $targetDocs.TrimEnd('\'))) {
                        Log-Message "Migrating existing Documents files from '$currDocs' to '$targetDocs'..." "INFO"
                        Get-ChildItem -Path $currDocs -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
                            try {
                                Move-Item -Path $_.FullName -Destination $targetDocs -Force -ErrorAction SilentlyContinue
                            } catch {
                                try { Copy-Item -Path $_.FullName -Destination $targetDocs -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                            }
                        }
                    }
                    $usfKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
                    $sfKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
                    if (-not (Test-Path $usfKey)) { New-Item -Path $usfKey -Force | Out-Null }
                    if (-not (Test-Path $sfKey))  { New-Item -Path $sfKey -Force | Out-Null }
                    Set-ItemProperty -Path $usfKey -Name "Personal" -Value $targetDocs -Type ExpandString -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $usfKey -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value $targetDocs -Type ExpandString -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $sfKey -Name "Personal" -Value $targetDocs -Type String -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path (Join-Path $targetDocs "desktop.ini") -Force -ErrorAction SilentlyContinue
                    try {
                        $regApp = 'HKLM:\SOFTWARE\GIN-Win-Optimizer'
                        if (-not (Test-Path $regApp)) { New-Item -Path $regApp -Force | Out-Null }
                        Set-ItemProperty -Path $regApp -Name "Documents_Path" -Value $targetDocs -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $regApp -Name "Documents_Relocated_At" -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Type String -Force -ErrorAction SilentlyContinue
                    } catch {}
                    Log-Message "Documents path successfully redirected to '$targetDocs'." "SUCCESS"
                } catch {
                    Log-Message "Documents relocation notice: $($_.Exception.Message)" "WARN"
                }
            }
        }
    }

    # Relocate Desktop to D:\DOCS\desktop
    if ($controls["chk_reloc_desktop"] -and $controls["chk_reloc_desktop"].IsChecked) {
        $actions += @{
            Name = "Relocate Desktop Folder to D:\DOCS\desktop"
            Script = {
                Log-Message "Starting Desktop relocation to D:\DOCS\desktop..." "INFO"
                try {
                    if (-not (Test-Path "D:\")) {
                        Log-Message "Drive D:\ does not exist! Desktop relocation skipped safely." "WARN"
                        return
                    }
                    $targetDesktop = "D:\DOCS\desktop"
                    if (-not (Test-Path $targetDesktop)) {
                        [System.IO.Directory]::CreateDirectory($targetDesktop) | Out-Null
                    }
                    $currDesktop = [Environment]::GetFolderPath('Desktop')
                    if (-not $currDesktop -or -not (Test-Path $currDesktop)) {
                        try {
                            $currDesktop = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).Desktop
                            if ($currDesktop) { $currDesktop = [Environment]::ExpandEnvironmentVariables($currDesktop) }
                        } catch {}
                    }
                    if ($currDesktop -and (Test-Path $currDesktop) -and ($currDesktop.TrimEnd('\') -ne $targetDesktop.TrimEnd('\'))) {
                        Log-Message "Migrating existing Desktop files from '$currDesktop' to '$targetDesktop'..." "INFO"
                        Get-ChildItem -Path $currDesktop -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
                            try {
                                Move-Item -Path $_.FullName -Destination $targetDesktop -Force -ErrorAction SilentlyContinue
                            } catch {
                                try { Copy-Item -Path $_.FullName -Destination $targetDesktop -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                            }
                        }
                    }
                    $usfKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
                    $sfKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
                    if (-not (Test-Path $usfKey)) { New-Item -Path $usfKey -Force | Out-Null }
                    if (-not (Test-Path $sfKey))  { New-Item -Path $sfKey -Force | Out-Null }
                    Set-ItemProperty -Path $usfKey -Name "Desktop" -Value $targetDesktop -Type ExpandString -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $usfKey -Name "{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}" -Value $targetDesktop -Type ExpandString -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $usfKey -Name "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Value $targetDesktop -Type ExpandString -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $sfKey -Name "Desktop" -Value $targetDesktop -Type String -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path (Join-Path $targetDesktop "desktop.ini") -Force -ErrorAction SilentlyContinue
                    try {
                        $regApp = 'HKLM:\SOFTWARE\GIN-Win-Optimizer'
                        if (-not (Test-Path $regApp)) { New-Item -Path $regApp -Force | Out-Null }
                        Set-ItemProperty -Path $regApp -Name "Desktop_Path" -Value $targetDesktop -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $regApp -Name "Desktop_Relocated_At" -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Type String -Force -ErrorAction SilentlyContinue
                    } catch {}
                    Log-Message "Desktop path successfully redirected to '$targetDesktop'." "SUCCESS"
                } catch {
                    Log-Message "Desktop relocation notice: $($_.Exception.Message)" "WARN"
                }
            }
        }
    }

    if ($controls["chk_ui_widgets"].IsChecked) {

        $actions += @{ Name = "Disable Windows 11 Widgets & News"; Script = {

            # Hide Widgets from Taskbar in Win11

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # Disable News and Interests (Win10 feeds)

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "HeadlinesOptIn" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # Policies

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # Propagate to all user profiles in HKEY_USERS

            Get-ChildItem Registry::HKEY_USERS -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' } | ForEach-Object {

                $uSid = $_.PSChildName

                New-Item -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

                Set-ItemProperty -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                New-Item -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Feeds" -Force -ErrorAction SilentlyContinue | Out-Null

                Set-ItemProperty -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue

            }

            # Uninstall WebExperience package

            Get-AppxPackage -AllUsers *WebExperience* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*WebExperience*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_teams_chat"].IsChecked) {

        $actions += @{ Name = "Remove Teams Chat Icon from Taskbar"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarChat" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_copilot"].IsChecked) {

        $actions += @{ Name = "Disable Windows Copilot AI"; Script = {

            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_recall"].IsChecked) {

        $actions += @{ Name = "Disable Windows Recall AI"; Script = {

            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_start_ads"].IsChecked) {

        $actions += @{ Name = "Clean Start Menu: Clean Layout, Suggestions Off & Keep Jump Lists Active"; Script = {

            # Advanced Start Menu Settings
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ShowClassicMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ShowMoreTiles" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ForceStartSize" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # Show recently opened items in Jump Lists (Start, Taskbar, Quick Access): ON
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowRecent" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            # Disable recommendations, suggestions and promotional tips in Start
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # Explorer Policies: Hide recently added apps, but purge policies that block Jump Lists
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoRecentDocsHistory" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "ClearRecentDocsOnExit" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoFrequentFolders" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoRecentDocsHistory" -Force -ErrorAction SilentlyContinue

            Purge-StartMenuLegacyJunk "Clean Start Menu"
        }}

    }

    if ($controls["chk_ui_explorer_ads"].IsChecked) {

        $actions += @{ Name = "Disable Explorer Sync Promo Ads"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_welcome_screen"].IsChecked) {

        $actions += @{ Name = "Disable Finish Device Setup Screen"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_lockscreen_clean"].IsChecked) {

        $actions += @{ Name = "Configure Lock Screen (Disable Tips/Ads, Show Background on Sign-In)"; Script = {

            Log-Message "Configuring clean Lock Screen..." "INFO"
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force -ErrorAction SilentlyContinue | Out-Null
            # Disable fun facts, tips, tricks, and overlay ads on lock screen
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            # Show lock screen background picture on sign-in screen
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableLogonBackgroundImage" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Log-Message "Lock Screen configured (tips disabled, background enabled on sign-in screen)." "SUCCESS"

        }}

    }

    if ($controls["chk_ui_color_accent_theme"].IsChecked) {

        $actions += @{ Name = "Configure Theme: Dark System, Steel Blue Accent & Surfaces"; Script = {

            Log-Message "Applying Color Scheme: Dark System, Steel Blue Accent, Transparency Off..." "INFO"
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Force -ErrorAction SilentlyContinue | Out-Null
            # System dark theme for taskbar, Start and Action Center
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            # Transparency effects: Off
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            # Show accent color on Start, taskbar, and action center: ON
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "ColorPrevalence" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

            # DWM: Accent color on title bars and window borders: ON
            New-Item -Path "HKCU:\Software\Microsoft\Windows\DWM" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorPrevalence" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableWindowColorization" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

            # Accent Color: Steel Blue / Dark Teal (#2D5F9A)
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "AccentColor" -Value 4288314669 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorizationColor" -Value 3291315610 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorizationAfterglow" -Value 3291315610 -Type DWord -Force -ErrorAction SilentlyContinue

            # Automatic color pick: OFF
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Log-Message "Color Scheme applied (Dark system, Steel Blue accent on Taskbar/Start & Titlebars)." "SUCCESS"

        }}

    }

    if ($controls["chk_ui_mouse_inverted_large"].IsChecked) {

        $actions += @{ Name = "Configure Mouse Pointers: Inverted Large Scheme with Pointer Shadow"; Script = {

            Log-Message "Applying Inverted (large) mouse pointer scheme..." "INFO"
            New-Item -Path "HKCU:\Control Panel\Cursors" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "(default)" -Value "Инверсная (крупная)" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "AppStarting" -Value "%SystemRoot%\cursors\wait_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Arrow" -Value "%SystemRoot%\cursors\arrow_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Crosshair" -Value "%SystemRoot%\cursors\cross_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Hand" -Value "%SystemRoot%\cursors\aero_link_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Help" -Value "%SystemRoot%\cursors\help_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "IBeam" -Value "%SystemRoot%\cursors\beam_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "No" -Value "%SystemRoot%\cursors\no_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "NWPen" -Value "%SystemRoot%\cursors\pen_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "SizeAll" -Value "%SystemRoot%\cursors\move_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "SizeNESW" -Value "%SystemRoot%\cursors\size1_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "SizeNS" -Value "%SystemRoot%\cursors\size4_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "SizeNWSE" -Value "%SystemRoot%\cursors\size2_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "SizeWE" -Value "%SystemRoot%\cursors\size3_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "UpArrow" -Value "%SystemRoot%\cursors\up_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Wait" -Value "%SystemRoot%\cursors\busy_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Pin" -Value "%SystemRoot%\cursors\pin_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Person" -Value "%SystemRoot%\cursors\person_im.cur" -Type ExpandString -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Scheme Source" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "CursorBaseSize" -Value 32 -Type DWord -Force -ErrorAction SilentlyContinue

            # Enable pointer shadow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DropShadow" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

            # Apply cursors live via Win32 API
            try {
                [Win32Utils.Win32Console]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3) | Out-Null
            } catch {}
            Log-Message "Mouse pointer scheme (Inverted Large with shadow) applied." "SUCCESS"

        }}

    }

    if ($controls["chk_ui_classic_context"].IsChecked) {

        $actions += @{ Name = "Restore Classic Context Menu"; Script = {

            $regKey = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

            New-Item -Path $regKey -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path $regKey -Name "(default)" -Value "" -ErrorAction SilentlyContinue

        }}

    }

    # Keep File Extensions Hidden & Clean Desktop (Standard per Vladimir's requirement)

    $actions += @{ Name = "Keep File Extensions Hidden & Clean Desktop"; Script = {

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type DWord -ErrorAction SilentlyContinue

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        # Remove any desktop.ini leftover from Desktop

        $dtPath = [Environment]::GetFolderPath('Desktop')

        if ($dtPath) { Remove-Item -Path (Join-Path $dtPath 'desktop.ini') -Force -ErrorAction SilentlyContinue }

        Remove-Item -Path "$env:PUBLIC\Desktop\desktop.ini" -Force -ErrorAction SilentlyContinue

        if (Test-Path "D:\DOCS\desktop\desktop.ini") {
        Remove-Item -Path "D:\DOCS\desktop\desktop.ini" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "D:\MEGA\DOCS\desktop\desktop.ini") {

            Remove-Item -Path "D:\MEGA\DOCS\desktop\desktop.ini" -Force -ErrorAction SilentlyContinue

        }

    }}

    if ($controls["chk_ui_hide_search"].IsChecked) {

        $actions += @{ Name = "Hide Search Icon & Box from Taskbar"; Script = {

            # Hide Search across all Windows 10/11 keys, policies and all user profiles

            $searchPaths = @(

                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search",

                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",

                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search",

                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

            )

            foreach ($sp in $searchPaths) {

                New-Item -Path $sp -Force -ErrorAction SilentlyContinue | Out-Null

                Set-ItemProperty -Path $sp -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            }

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarModePolicy" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            # Propagate to all loaded user profiles in HKEY_USERS

            Get-ChildItem Registry::HKEY_USERS -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' } | ForEach-Object {

                $uSid = $_.PSChildName

                New-Item -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Search" -Force -ErrorAction SilentlyContinue | Out-Null

                Set-ItemProperty -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                Set-ItemProperty -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                New-Item -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

                Set-ItemProperty -Path "Registry::HKEY_USERS\$uSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            }

        }}

    }

    if ($controls["chk_ui_hide_taskview"].IsChecked) {

        $actions += @{ Name = "Hide Task View Button from Taskbar"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_show_all_tray_icons"].IsChecked) {

        $actions += @{ Name = "Always Show All Icons in System Tray"; Script = {

            # 1. Windows 10 & legacy auto-tray disable

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            # 2. Explorer Policy: NoAutoTray

            $polPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

            if (-not (Test-Path $polPath)) { New-Item -Path $polPath -Force | Out-Null }

            Set-ItemProperty -Path $polPath -Name "NoAutoTray" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            # 3. Windows 11 NotifyIconSettings: Promote all icons to taskbar

            $notifyPath = "HKCU:\Control Panel\NotifyIconSettings"

            if (Test-Path $notifyPath) {

                Get-ChildItem $notifyPath -ErrorAction SilentlyContinue | ForEach-Object {

                    Set-ItemProperty -Path $_.PSPath -Name "IsPromoted" -Value 1 -Type DWord -ErrorAction SilentlyContinue

                }

            }

        }}

    }

    if ($controls["chk_ui_never_combine_taskbar"].IsChecked) {

        $actions += @{ Name = "Never Combine Taskbar Buttons"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 2 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MMTaskbarGlomLevel" -Value 2 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_show_this_pc"].IsChecked) {

        $actions += @{ Name = "Display 'This PC' Icon on Desktop"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_desktop_show_user_folder"].IsChecked) {

        $actions += @{ Name = "Display User Profile Folder on Desktop"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    } else {

        $actions += @{ Name = "Clean User Folder from Desktop"; Script = {

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_clock_24h_seconds"].IsChecked) {

        $actions += @{ Name = "Enable 24h Clock & Seconds in Tray"; Script = {

            Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sTimeFormat" -Value "HH:mm:ss" -Type String -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm" -Type String -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSecondsInSystemClock" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_region_time_czech"].IsChecked) {
        $actions += @{ Name = "Set TimeZone to Prague (UTC+1), Auto-DST & Czech Geo"; Script = {
            Log-Message "Setting TimeZone to W. Europe Standard Time (Prague, UTC+1, Auto-DST)..." "INFO"
            try { tzutil.exe /s "W. Europe Standard Time" 2>$null | Out-Null } catch {}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "DynamicDaylightTimeDisabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name "Nation" -Value "75" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name "Name" -Value "CZ" -Type String -Force -ErrorAction SilentlyContinue
            Log-Message "TimeZone (Prague) and Auto-DST activated." "SUCCESS"
        }}
    }

    if ($controls["chk_ui_lang_keyboards"].IsChecked) {
        $actions += @{ Name = "Configure Preferred Keyboards (English #1 Default, Czech #2 if present, Russian #2/#3)"; Script = {
            Log-Message "Configuring keyboard layout priorities (EN #1 Default, CZ #2 if present, RU #2/#3)..." "INFO"
            $hasCzech = $false
            try {
                $uLangs = Get-WinUserLanguageList -ErrorAction SilentlyContinue
                if ($uLangs) {
                    foreach ($ul in $uLangs) {
                        if ($ul.LanguageTag -like "cs*" -or $ul.LanguageTag -eq "cs-CZ") { $hasCzech = $true }
                    }
                }
            } catch {}
            if (-not $hasCzech) {
                $pre = Get-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -ErrorAction SilentlyContinue
                if ($pre) {
                    foreach ($prop in $pre.PSObject.Properties) {
                        if ($prop.Value -eq "00000405" -or $prop.Value -eq "0405:00000405") { $hasCzech = $true }
                    }
                }
            }
            try {
                $newList = New-Object System.Collections.Generic.List[Microsoft.InternationalSettings.Commands.WinUserLanguage]
                $newList.Add((New-WinUserLanguage "en-US"))
                if ($hasCzech) {
                    Log-Message "Czech keyboard layout detected in system: setting Czech as #2." "INFO"
                    $newList.Add((New-WinUserLanguage "cs-CZ"))
                } else {
                    Log-Message "Czech keyboard layout not detected: configuring English #1, Russian #2." "INFO"
                }
                $newList.Add((New-WinUserLanguage "ru-RU"))
                Set-WinUserLanguageList -LanguageList $newList -Force -ErrorAction SilentlyContinue
            } catch {}
            try {
                Set-WinDefaultInputMethodOverride -InputTip "0409:00000409" -ErrorAction SilentlyContinue
            } catch {}
            New-Item -Path "HKCU:\Keyboard Layout\Preload" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "1" -Value "00000409" -Type String -Force -ErrorAction SilentlyContinue
            if ($hasCzech) {
                Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "2" -Value "00000405" -Type String -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "3" -Value "00000419" -Type String -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "4" -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "2" -Value "00000419" -Type String -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "3" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "4" -ErrorAction SilentlyContinue
            }
            New-Item -Path "HKCU:\Control Panel\International\User Profile" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name "InputMethodOverride" -Value "0409:00000409" -Type String -Force -ErrorAction SilentlyContinue
            Log-Message "Preferred keyboards & English (US) default input method applied (OS display language preserved)." "SUCCESS"
        }}
    }

    if ($controls["chk_ui_regional_date_format"].IsChecked) {
        $actions += @{ Name = "Configure Regional Formats (ru-RU, dd.MM.yyyy, HH:mm:ss, Monday)"; Script = {
            Log-Message "Applying Russian regional format (ru-RU) and date/time formats..." "INFO"
            try { Set-Culture "ru-RU" -ErrorAction SilentlyContinue } catch {}
            $intl = "HKCU:\Control Panel\International"
            New-Item -Path $intl -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $intl -Name "Locale" -Value "00000419" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "LocaleName" -Value "ru-RU" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "sShortDate" -Value "dd.MM.yyyy" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "sLongDate" -Value "d MMMM yyyy 'г.'" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "sShortTime" -Value "HH:mm" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "sTimeFormat" -Value "HH:mm:ss" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "iFirstDayOfWeek" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $intl -Name "iCalendarType" -Value "1" -Type String -Force -ErrorAction SilentlyContinue
            Log-Message "Regional format ru-RU (dd.MM.yyyy, HH:mm:ss, Monday first day) applied." "SUCCESS"
        }}
    }

    if ($controls["chk_tb_small_icons"].IsChecked) {

        $actions += @{ Name = "Use Small Taskbar Buttons"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    } else {

        $actions += @{ Name = "Keep Standard Taskbar Buttons"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_tb_lock"].IsChecked) {

        $actions += @{ Name = "Lock the Taskbar"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSizeMove" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_tb_hide_action_center"].IsChecked) {

        $actions += @{ Name = "Hide Action Center in System Tray"; Script = {

            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "HideActionCenter" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_tb_hide_people"].IsChecked) {
        $actions += @{ Name = "Hide People Button on Taskbar"; Script = {
            $peopleKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
            if (-not (Test-Path $peopleKey)) { New-Item -Path $peopleKey -Force | Out-Null }
            Set-ItemProperty -Path $peopleKey -Name "PeopleBand" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $peopleKey -Name "ShowTaskbarPinPople" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "PeopleBand" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $polUser = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $polUser)) { New-Item -Path $polUser -Force | Out-Null }
            Set-ItemProperty -Path $polUser -Name "HidePeopleBar" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $polMachine = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $polMachine)) { New-Item -Path $polMachine -Force | Out-Null }
            Set-ItemProperty -Path $polMachine -Name "HidePeopleBar" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } }
    }

    if ($controls["chk_exp_open_this_pc"].IsChecked) {

        $actions += @{ Name = "Open File Explorer to 'This PC'"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_exp_hide_user_folders"].IsChecked) {

        $actions += @{ Name = "Hide 6 User Folders from This PC"; Script = {

            $clsids = @(

                "{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}",

                "{d3162b92-9365-467a-956b-92703aca08af}",

                "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}",

                "{f42ee2d3-909f-4907-8871-4c22fc0bf756}",

                "{088e3905-0323-4b02-9826-5d99428e115f}",

                "{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"

            )

            foreach ($c in $clsids) {

                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\$c\PropertyBag"

                if (Test-Path $p) {

                    Set-ItemProperty -Path $p -Name "ThisPCPolicy" -Value "Hide" -ErrorAction SilentlyContinue

                }

            }

        }}

    }

    if ($controls["chk_exp_no_shortcut_suffix"].IsChecked) {

        $actions += @{ Name = "Remove '- Shortcut' Suffix"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "link" -Value ([byte[]](0,0,0,0)) -Type Binary -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_exp_hide_quick_access_recent"].IsChecked) {

        $actions += @{ Name = "Hide Recent Files in Quick Access"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_exp_show_full_path"].IsChecked) {

        $actions += @{ Name = "Show Full Path in Explorer Title Bar"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_exp_separate_process"].IsChecked) {

        $actions += @{ Name = "Launch Explorer Windows in Separate Process"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SeparateProcess" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_exp_hide_nav_libraries"].IsChecked) {

        $actions += @{ Name = "Hide Libraries from Navigation Pane"; Script = {

            # Purge rogue phantom Desktop\NameSpace key that causes blank white ghost icon on Desktop
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue

            # Properly hide Libraries from Explorer Navigation Pane (Correct GUID: {031E4825-7B94-4dc3-B131-E946B44C8DD5})
            $libClsidPath = "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}"
            if (-not (Test-Path $libClsidPath)) { New-Item -Path $libClsidPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $libClsidPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    # 6. Context Menu Cleanup

    if ($controls["chk_ctx_cleanup_bloat"].IsChecked) {

        $actions += @{ Name = "Clean Right-Click Context Menu Bloat"; Script = {

            Remove-Item -Path "HKCR:\*\shellex\ContextMenuHandlers\ModernSharing" -Recurse -Force -ErrorAction SilentlyContinue

            Remove-Item -Path "HKCR:\SystemFileAssociations\.bmp\Shell\3D Edit" -Recurse -Force -ErrorAction SilentlyContinue

            Remove-Item -Path "HKCR:\SystemFileAssociations\.png\Shell\3D Edit" -Recurse -Force -ErrorAction SilentlyContinue

            Remove-Item -Path "HKCR:\SystemFileAssociations\.jpg\Shell\3D Edit" -Recurse -Force -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCR:\exefile\shellex\ContextMenuHandlers\Compatibility" -Name "(default)" -Value "" -ErrorAction SilentlyContinue

            # Intel Graphics Context Menu Clutter (Desktop Right-Click)
            $intelCtxList = @(
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxCUI",
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxcui",
                "HKLM:\SOFTWARE\Classes\Directory\background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKLM:\SOFTWARE\Classes\Directory\background\shellex\ContextMenuHandlers\igfxCUI",
                "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\igfxCUI"
            )
            foreach ($ic in $intelCtxList) {
                Remove-Item -Path $ic -Recurse -Force -ErrorAction SilentlyContinue
            }

        }}

    }

    if ($controls["chk_ctx_winrar_email"].IsChecked) {

        $actions += @{ Name = "WinRAR: Hide 'Compress & Email' Clutter"; Script = {

            New-Item -Path "HKCU:\Software\WinRAR\Interface" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\WinRAR\Interface" -Name "ContextMenuEmail" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ctx_intel_graphics"].IsChecked) {
        $actions += @{ Name = "Disable Intel Graphics Desktop Context Menu & Screen Rotation Hotkeys"; Script = {
            Log-Message "Removing Intel Graphics desktop context menu entries..." "INFO"
            $intelCtxPaths = @(
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxCUI",
                "HKCR:\Directory\Background\shellex\ContextMenuHandlers\igfxcui",
                "HKLM:\SOFTWARE\Classes\Directory\background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKLM:\SOFTWARE\Classes\Directory\background\shellex\ContextMenuHandlers\igfxCUI",
                "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM",
                "HKCU:\Software\Classes\Directory\Background\shellex\ContextMenuHandlers\igfxCUI"
            )
            foreach ($cp in $intelCtxPaths) {
                Remove-Item -Path $cp -Recurse -Force -ErrorAction SilentlyContinue
            }

            Log-Message "Disabling Intel hotkeys (screen rotation Ctrl+Alt+Arrows) and system tray icon..." "INFO"
            $intelRegTweaks = @(
                @{ Path = "HKCU:\Software\Intel\Display\igfxcui\HotKeys"; Name = "Enable"; Value = 0 },
                @{ Path = "HKLM:\SOFTWARE\Intel\Display\igfxcui\HotKeys"; Name = "Enable"; Value = 0 },
                @{ Path = "HKCU:\Software\Intel\IGFX\UI"; Name = "HotKey"; Value = 0 },
                @{ Path = "HKLM:\SOFTWARE\Intel\IGFX"; Name = "HotKey"; Value = 0 },
                @{ Path = "HKCU:\Software\Intel\Display\igfxcui\TrayIcon"; Name = "Enable"; Value = 0 },
                @{ Path = "HKLM:\SOFTWARE\Intel\Display\igfxcui\TrayIcon"; Name = "Enable"; Value = 0 },
                @{ Path = "HKCU:\Software\Intel\Display\igfxcui\Profiles"; Name = "Enable"; Value = 0 }
            )
            foreach ($tw in $intelRegTweaks) {
                if (-not (Test-Path $tw.Path)) {
                    New-Item -Path $tw.Path -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $tw.Path -Name $tw.Name -Value $tw.Value -Type DWord -Force -ErrorAction SilentlyContinue
            }
            Log-Message "Intel Graphics context menu, hotkeys and screen rotation disabled." "SUCCESS"
        }}
    }

    # 7. Windows Update & System Diagnostics

    if ($controls["chk_wu_disable_auto_updates"].IsChecked) {
        $actions += @{ Name = "Configure Windows Update: Never Check (Dism++ Standard)"; Script = {
            # 1. Terminate running update worker processes immediately
            Stop-Process -Name "MoUsoCoreWorker", "UsoClient", "wuauclt", "WaaSMedic", "SIHClient", "TiWorker" -Force -ErrorAction SilentlyContinue

            # 2. Native direct reg.exe execution: Exactly matches Dism++ "Never check for updates (not recommended)"
            $wuCmds = @(
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d 0 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "DetectionFrequencyEnabled" /t REG_DWORD /d 0 /f /reg:64',
                'delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:32',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:32',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:32',
                'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "CachedAUOptions" /t REG_DWORD /d 1 /f /reg:64',
                'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f /reg:64'
            )
            foreach ($cmd in $wuCmds) {
                $cmdNative = $cmd -replace '\s*/reg:(64|32)', ''
                cmd.exe /c "reg.exe $cmdNative" 2>$null | Out-Null
                if ([Environment]::Is64BitOperatingSystem) {
                    cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
                }
            }

            # 3. Permanently DISABLE update services (Start = 4 - Disabled)
            $updateSvcs = @("wuauserv", "UsoSvc", "WaaSMedicSvc", "dosvc")
            foreach ($s in $updateSvcs) {
                cmd.exe /c "sc.exe config $s start= disabled & sc.exe stop $s" 2>$null | Out-Null
                cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f" 2>$null | Out-Null
                if ([Environment]::Is64BitOperatingSystem) {
                    cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f /reg:64" 2>$null | Out-Null
                }
            }

            # 4. Disable scheduled background update scanner tasks that bypass Group Policy
            Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            Get-ScheduledTask -TaskPath '\Microsoft\Windows\WaaSMedic\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
        }}
    }


    if ($controls["chk_wu_exclude_drivers"].IsChecked) {
        $actions += @{ Name = "Exclude Driver Updates from Windows Update (Dism++ Standard)"; Script = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }}
    }

    if ($controls["chk_wu_exclude_msrt"].IsChecked) {
        $actions += @{ Name = "Exclude MSRT from Windows Update (Dism++ Standard)"; Script = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Name "DontOfferThroughWUAU" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }}
    }

    if ($controls["chk_sys_bsod_no_autoreboot"].IsChecked) {

        $actions += @{ Name = "Disable Auto-Reboot on BSOD"; Script = {

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sys_small_minidump"].IsChecked) {

        $actions += @{ Name = "Configure Small Memory Minidump"; Script = {

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 3 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sys_fast_startup_off"].IsChecked) {

        $actions += @{ Name = "Disable Fast Startup (Power)"; Script = {

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sys_disable_remote_assist"].IsChecked) {

        $actions += @{ Name = "Disable Remote Assistance"; Script = {

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_sys_enable_photo_viewer"].IsChecked) {

        $actions += @{ Name = "Restore Classic Windows Photo Viewer"; Script = {

            $pvKey = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"

            New-Item -Path $pvKey -Force -ErrorAction SilentlyContinue | Out-Null

            $pvVal = "PhotoViewer.FileAssoc.Tiff"

            @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".ico") | ForEach-Object {

                Set-ItemProperty -Path $pvKey -Name $_ -Value $pvVal -ErrorAction SilentlyContinue

            }

        }}

    }

    if ($controls["chk_sys_notepad_tweaks"].IsChecked) {

        $actions += @{ Name = "Notepad: Word Wrap & Status Bar"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Notepad" -Name "fWrap" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Notepad" -Name "StatusBar" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    # 8. App Debloater

    if ($controls["chk_app_xbox"].IsChecked) {

        $actions += @{ Name = "Remove Xbox Packages"; Script = {

            $xboxApps = Get-AppxPackage -AllUsers *Xbox* -ErrorAction SilentlyContinue

            foreach ($x in $xboxApps) {

                Log-Message "Removing App: $($x.Name)..." "APPX"

                $x | Remove-AppxPackage -ErrorAction SilentlyContinue

            }

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Xbox*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_app_gamebar_disable"].IsChecked) {
        $actions += @{ Name = "Disable Xbox Game Bar Recording & Controller Shortcut"; Script = {
            Log-Message "Disabling Xbox Game Bar recording & controller button Win+G shortcut..." "INFO"
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\System\GameConfigStore" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Log-Message "Xbox Game Bar recording & Controller shortcut disabled." "SUCCESS"
        }}
    }

    if ($controls["chk_app_games"].IsChecked) {

        $actions += @{ Name = "Remove Promo Games & Stubs"; Script = {

            $gList = @("*CandyCrush*", "*SolitaireCollection*", "*TikTok*", "*Disney*", "*Spotify*")

            foreach ($g in $gList) {

                $gApps = Get-AppxPackage -AllUsers $g -ErrorAction SilentlyContinue

                foreach ($app in $gApps) {

                    Log-Message "Removing App: $($app.Name)..." "APPX"

                    $app | Remove-AppxPackage -ErrorAction SilentlyContinue

                }

                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $g } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            }

        }}

    }

    if ($controls["chk_app_news"].IsChecked) {

        $actions += @{ Name = "Remove MSN News, Weather & Finance"; Script = {

            $nList = @("*BingNews*", "*BingWeather*", "*BingSports*", "*BingFinance*")

            foreach ($n in $nList) {

                $nApps = Get-AppxPackage -AllUsers $n -ErrorAction SilentlyContinue

                foreach ($app in $nApps) {

                    Log-Message "Removing App: $($app.Name)..." "APPX"

                    $app | Remove-AppxPackage -ErrorAction SilentlyContinue

                }

                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $n } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            }

        }}

    }

    if ($controls["chk_app_office_stub"].IsChecked) {

        $actions += @{ Name = "Completely Remove Demo/Trial Microsoft Office & Commercial Trialware"; Script = {

            Log-Message "Purging demo Microsoft Office (1-month trial) & sponsored trial bloatware..." "INFO"
            $officeStubs = @(
                "*MicrosoftOfficeHub*",
                "*Office.OneNote*",
                "*Microsoft.Office.Desktop*",
                "*MyOffice*",
                "*Microsoft365*",
                "*Clipchamp*",
                "*Spotify*",
                "*Disney*",
                "*Netflix*",
                "*Amazon*",
                "*TikTok*",
                "*CandyCrush*",
                "*MarchofEmpires*",
                "*BubbleWitch*"
            )
            foreach ($p in $officeStubs) {
                Get-AppxPackage -AllUsers -Name $p -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like $p -or $_.DisplayName -like $p } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            }
            Log-Message "Demo Office and commercial trialware removed." "SUCCESS"

        }}

    }

    if ($controls["chk_app_clipchamp"].IsChecked) {

        $actions += @{ Name = "Remove Clipchamp Video Editor"; Script = {

            Get-AppxPackage -AllUsers *Clipchamp* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Clipchamp*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_app_people"].IsChecked) {

        $actions += @{ Name = "Remove People & Legacy Mail"; Script = {

            Get-AppxPackage -AllUsers *People* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*People*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_app_feedback"].IsChecked) {

        $actions += @{ Name = "Remove Feedback Hub"; Script = {

            Get-AppxPackage -AllUsers *WindowsFeedbackHub* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*WindowsFeedbackHub*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_app_get_help"].IsChecked) {

        $actions += @{ Name = "Remove Get Help & Tips"; Script = {

            Get-AppxPackage -AllUsers *GetHelp* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxPackage -AllUsers *Getstarted* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_app_phone"].IsChecked) {

        $actions += @{ Name = "Remove Phone Link App"; Script = {

            Get-AppxPackage -AllUsers *YourPhone* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*YourPhone*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        }}

    }

    # 9. Services & Performance Tuning

    if ($controls["chk_srv_sysmain"].IsChecked) {

        $actions += @{ Name = "Disable SysMain / Superfetch"; Script = {

            Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_indexing"].IsChecked) {

        $actions += @{ Name = "Disable Windows Search Indexing"; Script = {

            Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_remote_reg"].IsChecked) {

        $actions += @{ Name = "Disable Remote Registry Service"; Script = {

            Stop-Service -Name "RemoteRegistry" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "RemoteRegistry" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteRegistry" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_delivery_opt"].IsChecked) {

        $actions += @{ Name = "Disable Delivery Optimization P2P"; Script = {

            Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "DoSvc" -StartupType Disabled -ErrorAction SilentlyContinue

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_reserved_storage"].IsChecked) {

        $actions += @{ Name = "Disable Windows Reserved Storage"; Script = {

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -Name "ShippedWithReserves" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            try { dism.exe /Online /Set-ReservedStorageState /State:Disabled /Quiet } catch {}

        }}

    }

    if ($controls["chk_srv_hibernation"].IsChecked) {

        $actions += @{ Name = "Disable Hibernation & Delete hiberfil.sys"; Script = {

            powercfg.exe /hibernate off 2>$null | Out-Null

        }}

    }

    if ($controls["chk_srv_power_plan"].IsChecked) {

        $actions += @{ Name = "Activate Ultimate Performance Plan"; Script = {

            $pOut = powercfg.exe -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null

            if ($pOut -match '([0-9a-fA-F-]{36})') {

                powercfg.exe -setactive $matches[1] 2>$null | Out-Null

            }

        }}

    }

    if ($controls["chk_srv_power_sleep_screen"].IsChecked) {
        $actions += @{ Name = "Configure Power & Sleep Timeouts (Screen Never, Sleep DC 30m / AC Never, Screensaver 10m)"; Script = {
            Log-Message "Configuring display and sleep timeouts (Screen Never, Sleep DC 30m / AC Never)..." "INFO"
            try {
                powercfg.exe /change monitor-timeout-ac 0 2>$null | Out-Null
                powercfg.exe /change monitor-timeout-dc 0 2>$null | Out-Null
                powercfg.exe /change standby-timeout-ac 0 2>$null | Out-Null
                powercfg.exe /change standby-timeout-dc 30 2>$null | Out-Null
            } catch {}

            New-Item -Path "HKCU:\Control Panel\Desktop" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "600" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "1" -Type String -Force -ErrorAction SilentlyContinue
            $saverPath = if (Test-Path "$env:SystemRoot\X-SAVER3.SCR") { "$env:SystemRoot\X-SAVER3.SCR" } elseif (Test-Path "$env:SystemRoot\system32\scrnsave.scr") { "$env:SystemRoot\system32\scrnsave.scr" } else { "C:\Windows\X-SAVER3.SCR" }
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SCRNSAVE.EXE" -Value $saverPath -Type String -Force -ErrorAction SilentlyContinue
            Log-Message "Display timeouts (Never), Sleep (30m DC / Never AC) & Screensaver (10m) configured." "SUCCESS"
        }}
    }

    if ($controls["chk_srv_ssd_trim"].IsChecked) {
        $actions += @{ Name = "Deep SSD & NVMe M.2 Performance Optimization & ReTrim"; Script = {
            Log-Message "Configuring maximum SSD & NVMe M.2 filesystem optimizations..." "INFO"

            # 1. Enforce TRIM / Delete Notification for SSD / NVMe
            cmd.exe /c "fsutil.exe behavior set DisableDeleteNotify 0" 2>$null | Out-Null

            # 2. Disable LastAccess timestamps on NTFS (saves high-frequency write cycles on SSD)
            cmd.exe /c "fsutil.exe behavior set disablelastaccess 1" 2>$null | Out-Null

            # 3. Expand NTFS memory cache pool (NtfsMemoryUsage=2) to maximize NVMe/SSD I/O bandwidth
            cmd.exe /c "fsutil.exe behavior set NtfsMemoryUsage 2" 2>$null | Out-Null

            # 4. Disable 8.3 short filename generation (disable8dot3=1) to eliminate legacy directory overhead
            cmd.exe /c "fsutil.exe behavior set disable8dot3 1" 2>$null | Out-Null

            # 5. Disable HDD Scheduled Defragmentation (unnecessary wear on SSD/NVMe)
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
            cmd.exe /c "schtasks.exe /change /tn `"\Microsoft\Windows\Defrag\ScheduledDefrag`" /disable" 2>$null | Out-Null

            # 6. Disable Superfetch / SysMain and Prefetcher in Registry (HDD relics obsolete on SSD/NVMe)
            $memMgr = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
            if (Test-Path $memMgr) {
                Set-ItemProperty -Path $memMgr -Name "EnablePrefetcher" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $memMgr -Name "EnableSuperfetch" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            }

            # 7. Execute active ReTrim across all attached SSD / NVMe fixed volumes
            Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq "Fixed" -and $_.DriveLetter } | ForEach-Object {
                $dl = $_.DriveLetter
                Log-Message "Executing active ReTrim optimization on Drive ${dl}:..." "INFO"
                Optimize-Volume -DriveLetter $dl -ReTrim -Verbose -ErrorAction SilentlyContinue
            }

            Log-Message "Deep SSD & NVMe M.2 optimizations applied successfully." "SUCCESS"
        }}
    }

    if ($controls["chk_srv_pagefile_auto"].IsChecked) {

        $actions += @{ Name = "Configure Smart Dynamic Pagefile on C:"; Script = {

            Log-Message "Calculating optimal dynamic pagefile for Drive C:..." "INFO"

            try {

                # 1. Query Physical RAM (MB)
                $compSys = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
                $ramMB = if ($compSys -and $compSys.TotalPhysicalMemory) {
                    [math]::Round($compSys.TotalPhysicalMemory / 1MB)
                } else {
                    8192
                }

                # 2. Query Disk C: Free Space & Existing pagefile size
                $cDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
                $rawFreeMB = if ($cDrive -and $cDrive.FreeSpace) { [math]::Floor($cDrive.FreeSpace / 1MB) } else { 10240 }

                # Check if pagefile.sys exists on C: to count its allocated space as reusable
                $pfItem = Get-Item "C:\pagefile.sys" -Force -ErrorAction SilentlyContinue
                $pfCurrentMB = if ($pfItem) { [math]::Ceiling($pfItem.Length / 1MB) } else { 0 }
                $effectiveFreeMB = $rawFreeMB + $pfCurrentMB

                # 3. Ultarix-Grade Pagefile Logic (4096 - 8192 MB standard to prevent 0xe0000008 OOM crashes on 32-bit/4GB PCs):
                $baseInit = 4096
                $baseMax  = 8192

                # 4. Free Space Guard for Disk C:
                # Guarantee at least 4 GB remains free on C:; if >= 14 GB effective free space, apply full 4096-8192 MB
                if ($effectiveFreeMB -ge 14336) {
                    $calcInit = 4096
                    $calcMax  = 8192
                } else {
                    $safeMinRemain = [math]::Max(2048, $effectiveFreeMB - 4096)
                    $calcMax = [math]::Min($baseMax, $safeMinRemain)
                    if ($calcMax -lt 2048) { $calcMax = 2048 }
                    $calcInit = [math]::Min($baseInit, [math]::Max(2048, [math]::Floor($calcMax / 2)))
                    if ($calcInit -gt $calcMax) { $calcInit = $calcMax }
                }

                Log-Message ("Detected RAM: {0} MB | C: Effective Free: {1} MB | Pagefile: {2} MB - {3} MB (Elastic)" -f $ramMB, $effectiveFreeMB, $calcInit, $calcMax) "INFO"

                # 5. Apply Pagefile Settings via Registry & WMI / CIM
                # Disable Windows automatic management so custom range takes effect
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "AutomaticManagedPagefile" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

                # Centralize pagefile strictly on C: (removes pagefile from other drives)
                $pagefileSetting = "C:\pagefile.sys $calcInit $calcMax"
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value @($pagefileSetting) -Type MultiString -Force -ErrorAction SilentlyContinue

                # CIM update for live management
                try {
                    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
                    $cs.AutomaticManagedPagefile = $false
                    $cs | Set-CimInstance -ErrorAction SilentlyContinue
                    Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Remove-CimInstance -ErrorAction SilentlyContinue
                    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
                        Name = "C:\pagefile.sys"
                        InitialSize = [uint32]$calcInit
                        MaximumSize = [uint32]$calcMax
                    } -ErrorAction SilentlyContinue | Out-Null
                } catch {}

                Log-Message ("Smart dynamic pagefile configured on C: ({0} MB - {1} MB). Active upon reboot." -f $calcInit, $calcMax) "SUCCESS"

            } catch {

                Log-Message ("Failed to configure pagefile: " + $_.Exception.Message) "WARN"

            }

        }}

    }

    if ($controls["chk_srv_network_offload"].IsChecked) {

        $actions += @{ Name = "Disable Network Task Offload & Chimney"; Script = {

            netsh int ip set global taskoffload=disabled 2>$null | Out-Null

            netsh int tcp set global chimney=disabled 2>$null | Out-Null

        }}

    }

    if ($controls["chk_srv_visual_appearance"].IsChecked) {

        $actions += @{ Name = "Visual Effects: Adjust for Best Appearance (Enable all visual effects & font smoothing)"; Script = {

            # 1. Explorer VisualFXSetting: 1 = Best Appearance (Обеспечить наилучший вид)
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

            # 2. Desktop & Window Metrics (DragFullWindows, FontSmoothing, MinAnimate, Shadows)
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "1" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "CursorShadow" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -Type Binary -Force -ErrorAction SilentlyContinue

            if (-not (Test-Path "HKCU:\Control Panel\Desktop\WindowMetrics")) {
                New-Item -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1" -Type String -Force -ErrorAction SilentlyContinue

            # 3. Advanced Explorer Effects (Taskbar animations, Listview shadow/alpha, DropShadow, IconsOnly=0)
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DropShadow" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            # 4. Desktop Window Manager (DWM) Aero Peek & Thumbnails
            if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\DWM")) {
                New-Item -Path "HKCU:\Software\Microsoft\Windows\DWM" -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "Composition" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "CompositionPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "AlwaysHibernateThumbnails" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_pca"].IsChecked) {

        $actions += @{ Name = "Disable Program Compatibility Assistant (PcaSvc)"; Script = {

            Stop-Service -Name "PcaSvc" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "PcaSvc" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PcaSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_trkwks"].IsChecked) {

        $actions += @{ Name = "Disable Distributed Link Tracking (TrkWks)"; Script = {

            Stop-Service -Name "TrkWks" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "TrkWks" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TrkWks" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_iphlpsvc"].IsChecked) {

        $actions += @{ Name = "Disable IP Helper Service (iphlpsvc)"; Script = {

            Stop-Service -Name "iphlpsvc" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "iphlpsvc" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\iphlpsvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_oem_lenovo"].IsChecked) {
        $actions += @{ Name = "Purge / Disable Lenovo ImController Bloatware & Services"; Script = {
            Log-Message "Auditing Lenovo components and background ImController services..." "INFO"
            $mfg = try { (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).Manufacturer } catch { "" }
            $isLenovo = ($mfg -and $mfg -match "Lenovo")

            # 1. Terminate all Lenovo processes
            Stop-Process -Name "Lenovo.Modern.ImController*", "LenovoVantage*", "ClientBrokerAgent*" -Force -ErrorAction SilentlyContinue

            # 2. Process Lenovo services
            $lenovoServices = Get-Service -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '^Lenovo|^ImController' -or $_.DisplayName -match 'Lenovo|ImController|System Interface Foundation'
            }
            foreach ($svc in $lenovoServices) {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                if (-not $isLenovo) {
                    sc.exe delete $svc.Name 2>$null | Out-Null
                    Log-Message "Non-Lenovo system: Deleted service $($svc.Name)" "SUCCESS"
                } else {
                    Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
                    Log-Message "Lenovo device: Disabled background service $($svc.Name)" "SUCCESS"
                }
            }

            # 3. Clean Lenovo scheduled tasks
            try {
                $lenovoTasks = Get-ScheduledTask -TaskPath "\Lenovo\*" -ErrorAction SilentlyContinue
                foreach ($lt in $lenovoTasks) {
                    Disable-ScheduledTask -TaskName $lt.TaskName -TaskPath $lt.TaskPath -ErrorAction SilentlyContinue | Out-Null
                    if (-not $isLenovo) {
                        Unregister-ScheduledTask -TaskName $lt.TaskName -TaskPath $lt.TaskPath -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            } catch {}

            # 4. Remove directories if not Lenovo (or ImController on Lenovo)
            if (-not $isLenovo) {
                $lenovoDirs = @(
                    "$env:SystemRoot\Lenovo",
                    "$env:ProgramData\Lenovo",
                    "$env:ProgramFiles\Lenovo",
                    "${env:ProgramFiles(x86)}\Lenovo"
                )
                foreach ($ld in $lenovoDirs) {
                    if (Test-Path $ld) {
                        takeown.exe /F $ld /R /D Y 2>$null | Out-Null
                        icacls.exe $ld /grant administrators:F /T /C /Q 2>$null | Out-Null
                        Remove-Item -Path $ld -Recurse -Force -ErrorAction SilentlyContinue
                        Log-Message "Purged non-Lenovo folder: $ld" "SUCCESS"
                    }
                }
            } else {
                if (Test-Path "$env:SystemRoot\Lenovo\ImController") {
                    takeown.exe /F "$env:SystemRoot\Lenovo\ImController" /R /D Y 2>$null | Out-Null
                    icacls.exe "$env:SystemRoot\Lenovo\ImController" /grant administrators:F /T /C /Q 2>$null | Out-Null
                    Remove-Item -Path "$env:SystemRoot\Lenovo\ImController" -Recurse -Force -ErrorAction SilentlyContinue
                    Log-Message "Purged ImController bloat folder on Lenovo device." "SUCCESS"
                }
            }
        }}
    }

    if ($controls["chk_srv_intel_graphics"].IsChecked) {
        $actions += @{ Name = "Disable Intel Graphics Background Services & Tray / Hotkey Modules"; Script = {
            Log-Message "Disabling Intel Graphics background services and helper processes..." "INFO"
            # 1. Terminate running helper processes
            Stop-Process -Name "igfxCUIService", "igfxEM", "igfxHK", "igfxTray", "hkcmd", "igfxpers" -Force -ErrorAction SilentlyContinue

            # 2. Disable Intel helper services
            $intelServices = @("igfxCUIService1.0.0.0", "igfxCUIService", "LMS", "cphs", "jhi_service", "ESRV_SVC_QUEENCREEK", "IntelAudioService")
            foreach ($s in $intelServices) {
                if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$s" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
                }
            }

            # 3. Clean Run keys in Registry
            $runPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            )
            $intelRunValues = @("IgfxTray", "HotKeysCmds", "Persistence", "IntelGraphicsAdmin")
            foreach ($rp in $runPaths) {
                foreach ($rv in $intelRunValues) {
                    Remove-ItemProperty -Path $rp -Name $rv -Force -ErrorAction SilentlyContinue
                }
            }
            Log-Message "Intel Graphics background services and auto-start modules disabled." "SUCCESS"
        }}
    }

    if ($controls["chk_srv_conexant_audio"].IsChecked) {
        $actions += @{ Name = "Disable Conexant Audio Background Services (CxAudioSvc, CxUIUSvc, CxUtilSvc)"; Script = {
            Log-Message "Stopping and disabling Conexant Audio background services (CPU offload)..." "INFO"
            # 1. Terminate running Conexant helper processes
            Stop-Process -Name "CxUIU32", "CxUIU64", "CxAudS64", "CxUtil64", "CxHSSvc" -Force -ErrorAction SilentlyContinue

            # 2. Disable all services starting with Cx*
            $cxServices = Get-Service -Name "Cx*" -ErrorAction SilentlyContinue
            foreach ($svc in $cxServices) {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
                Log-Message "Disabled service: $($svc.Name)" "SUCCESS"
            }
        }}
    }

    # Ensure LAN Network Discovery, Printing, Accounting Database & SMB Services are always running (Ultarix Standard)
    $actions += @{ Name = "Ensure LAN Discovery, Printing, SMB & Accounting Services (Private Profile, Firewall, SMB, Spooler, NexusDB)"; Script = {
        # 1. Switch active and stored Network Profiles to Private (Doma/Kancelar) so Firewall never blocks local LAN
        try {
            Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.NetworkCategory -ne "Private" } | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
            Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" -ErrorAction SilentlyContinue | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name "Category" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        # 2. Enable Guest SMB Auth, Admin Mapped Drives (EnableLinkedConnections), and UNC Script Execution (DisableUNCCheck)
        $sysPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if (-not (Test-Path $sysPol)) { New-Item -Path $sysPol -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $sysPol -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPol -Name "EnableLUA" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPol -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPol -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPol -Name "FilterAdministratorToken" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "ServiceDll" -Value "%SystemRoot%\System32\wkssvc.dll" -Type ExpandString -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Command Processor" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        New-Item -Path "HKCU:\Software\Microsoft\Command Processor" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        # 3. Guarantee core LAN, Discovery, Printing, Compatibility & Link Tracking services are Automatic and Running
        $coreLanServices = @("FDResPub", "fdPHost", "LanmanWorkstation", "LanmanServer", "lmhosts", "Dnscache", "Spooler", "NlaSvc", "netprofm", "SSDPSRV", "upnphost")
        foreach ($svcName in $coreLanServices) {
            Set-Service -Name $svcName -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        }

        # 4. Protect Accounting Database Services if present (NexusDB / FORM studio / SQL Server DUEL / Firebird)
        if (Get-Service -Name "FSServer412Service" -ErrorAction SilentlyContinue) {
            Set-Service -Name "FSServer412Service" -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name "FSServer412Service" -ErrorAction SilentlyContinue
        }
        Get-Service -Name "MSSQL*", "Firebird*", "nxServer*" -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.StartType -ne "Disabled") {
                Start-Service -Name $_.Name -ErrorAction SilentlyContinue
            }
        }

        # 5. Enable Windows Firewall rules for Network Discovery, File and Printer Sharing, and Accounting DB ports
        netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >$null 2>&1
        netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=Yes >$null 2>&1
        netsh.exe advfirewall firewall set rule group="@FirewallAPI.dll,-28502" new enable=Yes >$null 2>&1
        netsh.exe advfirewall firewall set rule group="@FirewallAPI.dll,-28752" new enable=Yes >$null 2>&1
        try {
            Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayGroup -match "File and Printer Sharing|Sd.+len.+ soubor.+|Общий доступ|Network Discovery|Zji.+ov.+n.+ s.+t.+|Обнаружение сети"
            } | Enable-NetFirewallRule -ErrorAction SilentlyContinue
        } catch {}

        # 6. Ensure NIC Task Offload is enabled for stable Gigabit SMB & NexusDB throughput
        if (-not $controls["chk_srv_network_offload"].IsChecked) {
            netsh.exe int ip set global taskoffload=enabled >$null 2>&1
        }

        Log-Message "LAN Network Profile (Private), Firewall Rules, Printing (Spooler), SMB & Accounting Services active." "SUCCESS"
    }}

    # 10. Cache & Deep Cleaning

    if ($controls["chk_clean_user_temp"].IsChecked) {

        $actions += @{ Name = "Clean User Temp Directories"; Script = {

            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

            Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_clean_win_temp"].IsChecked) {

        $actions += @{ Name = "Clean Windows Temp Directory"; Script = {

            Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_clean_soft_dist"].IsChecked) {

        $actions += @{ Name = "Clean SoftwareDistribution Download Cache"; Script = {

            Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

            # NOTE: Never start wuauserv here, keeping updates strictly stopped & manual

        }}

    }

    if ($controls["chk_clean_thumb_cache"].IsChecked) {

        $actions += @{ Name = "Clean Thumbnail Cache Databases"; Script = {

            # Safely remove thumbcache files without stopping Explorer in the middle

            Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*.db" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_clean_shaders_dns"].IsChecked) {

        $actions += @{ Name = "Clean DirectX Shader Cache & Flush DNS"; Script = {

            Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue

            Clear-DnsClientCache -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_clean_event_logs"].IsChecked) {

        $actions += @{ Name = "Clear Windows Event Logs"; Script = {

            $evLogs = wevtutil.exe el

            $cCount = 0

            foreach ($el in $evLogs) {

                wevtutil.exe cl "$el" 2>$null

                $cCount++

            }

            Log-Message "Cleared $cCount Windows Event Logs successfully" "SUCCESS"

        }}

    }

    if ($controls["chk_clean_recycle_bin"].IsChecked) {

        $actions += @{ Name = "Empty Recycle Bin on All Drives"; Script = {

            Clear-RecycleBin -Force -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_clean_cleanmgr"].IsChecked) {

        $actions += @{ Name = "Run Cleanmgr Disk Cleanup (C: then D:)"; Script = {

            # 1. Prevent background Windows Maintenance from concurrently colliding

            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\DiskCleanup\" -TaskName "SilentCleanup" -ErrorAction SilentlyContinue

            # 2. Check if another Disk Cleanup or System Cleanup is already running and wait in queue

            $activeCleanmgr = Get-Process -Name cleanmgr -ErrorAction SilentlyContinue

            if ($activeCleanmgr) {

                Log-Message "System Disk Cleanup is currently running ($($activeCleanmgr.Count) instance(s)). Queuing: waiting for active cleanup to finish..." "WARN"

                $waitSec = 0

                while ((Get-Process -Name cleanmgr -ErrorAction SilentlyContinue) -and ($waitSec -lt 45)) {

                    Start-Sleep -Seconds 2

                    $waitSec += 2

                    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

                }

                if (Get-Process -Name cleanmgr -ErrorAction SilentlyContinue) {

                    Log-Message "Stale system cleanup detected. Releasing disk lock to execute scheduled optimization queue..." "WARN"

                    Get-Process -Name cleanmgr, TiWorker -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

                    Start-Sleep -Milliseconds 1000

                } else {

                    Log-Message "Active system cleanup finished. Starting optimizer disk cleanup in queue." "SUCCESS"

                }

            }

            # 3. Configure StateFlags6553 for drive cleanup

            $regClean = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

            Get-ChildItem $regClean -ErrorAction SilentlyContinue | ForEach-Object {

                if ($_.PSChildName -notmatch "Update Cleanup") {

                    Set-ItemProperty -Path $_.PSPath -Name "StateFlags6553" -Value 2 -Type DWord -ErrorAction SilentlyContinue

                } else {

                    Set-ItemProperty -Path $_.PSPath -Name "StateFlags6553" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                }

            }

            # 4. STEP 1: Run Cleanmgr strictly for Drive C: and wait until 100% finished

            Log-Message "Starting sequential Disk Cleanup for Drive C:..." "INFO"

            Invoke-ProcessWithLiveOutput -FilePath "cleanmgr.exe" -Arguments "/autoclean /d C:" -TaskName "Cleanmgr Disk Cleanup (C:)" -TimeoutSeconds 240

            $settleC = 0

            while ((Get-Process -Name cleanmgr -ErrorAction SilentlyContinue) -and ($settleC -lt 30)) {

                Start-Sleep -Seconds 1

                $settleC++

                [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

            }

            Log-Message "Disk Cleanup for Drive C: completed successfully." "SUCCESS"

            # 5. STEP 2: Run Cleanmgr strictly for Drive D: sequentially AFTER C: finishes

            if (Test-Path "D:\") {

                Log-Message "Starting sequential Disk Cleanup for Drive D:..." "INFO"

                Invoke-ProcessWithLiveOutput -FilePath "cleanmgr.exe" -Arguments "/autoclean /d D:" -TaskName "Cleanmgr Disk Cleanup (D:)" -TimeoutSeconds 240

                $settleD = 0

                while ((Get-Process -Name cleanmgr -ErrorAction SilentlyContinue) -and ($settleD -lt 30)) {

                    Start-Sleep -Seconds 1

                    $settleD++

                    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

                }

                Log-Message "Disk Cleanup for Drive D: completed successfully." "SUCCESS"

            }

            # 6. Re-enable the SilentCleanup scheduled task

            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\DiskCleanup\" -TaskName "SilentCleanup" -ErrorAction SilentlyContinue

            Purge-StartMenuLegacyJunk "Post-Cleanmgr"
        }}

    }

    if ($controls["chk_deep_dism_repair"].IsChecked) {

        $actions += @{ Name = "DISM Component Store Repair"; Script = {

            Invoke-ProcessWithLiveOutput -FilePath "dism.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth" -TaskName "DISM RestoreHealth" -TimeoutSeconds 600

            # Immediately re-assert Dism++ Never Check policy and keep services disabled
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv" -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc" -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue

            Purge-StartMenuLegacyJunk "Post-DISM"
        }}

    }

    if ($controls["chk_deep_dism_resetbase"].IsChecked) {

        $actions += @{ Name = "Deep WinSxS Cleanup (ResetBase)"; Script = {

            Invoke-ProcessWithLiveOutput -FilePath "dism.exe" -Arguments "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -TaskName "DISM ResetBase" -TimeoutSeconds 600

        }}

    }

    if ($controls["chk_deep_sfc_compact"].IsChecked) {

        $actions += @{ Name = "SFC Scannow & CompactOS Query"; Script = {

            Invoke-ProcessWithLiveOutput -FilePath "sfc.exe" -Arguments "/scannow" -TaskName "SFC Scannow" -TimeoutSeconds 400

            compact.exe /CompactOS:query 2>$null | Out-Null

            Purge-StartMenuLegacyJunk "Post-SFC"
        }}

    }

    # Execute all queued actions

    $total = $actions.Count

    if ($total -eq 0) {

        Log-Message "No optimization tasks selected. Please check at least one option." "WARN"

        $btnStartTop.IsEnabled = $true

        $btnStartBottom.IsEnabled = $true

        if ($btnSkipTop) { $btnSkipTop.IsEnabled = $false }

        if ($btnSkipBottom) { $btnSkipBottom.IsEnabled = $false }

        $btnSelectAll.IsEnabled = $true

        $btnDeselectAll.IsEnabled = $true

        $btnPresetOffice.IsEnabled = $true

        $btnPresetGaming.IsEnabled = $true

        return

    }

    Log-Message "====================================================================" "INFO"

    Log-Message "STARTING GIN-WIN-OPTIMIZER ENGINE v047. Total tasks selected: $total" "INFO"

    Log-Message "====================================================================" "INFO"

    $current = 0

    foreach ($act in $actions) {

        $current++

        $pct = [int](($current / $total) * 100)

        $pbProgress.Value = $pct

        $loc = $t[$global:currentLang]

        $txtStatus.Text = "$($loc['StatusRunning']) $pct% ($current/$total) - $($act.Name)"

        Log-Message "[$current/$total] Running: $($act.Name)..." "INFO"

        try {

            & $act.Script

            Log-Message "[$current/$total] Successfully applied: $($act.Name)" "SUCCESS"

        } catch {

            $err = $_.Exception.Message

            Log-Message "[$current/$total] Warning in $($act.Name): $err" "WARN"

        }

    }

    # Clean Desktop: Remove any stray desktop.ini or artifacts
    $dtPath = [Environment]::GetFolderPath('Desktop')
    if ($dtPath) { Remove-Item -Path (Join-Path $dtPath 'desktop.ini') -Force -ErrorAction SilentlyContinue }
    Remove-Item -Path "$env:PUBLIC\Desktop\desktop.ini" -Force -ErrorAction SilentlyContinue
    if (Test-Path "D:\MEGA\DOCS\desktop\desktop.ini") {
        Remove-Item -Path "D:\MEGA\DOCS\desktop\desktop.ini" -Force -ErrorAction SilentlyContinue
    }

    # Purge rogue phantom Desktop\NameSpace key (removes blank white ghost icon from Desktop)
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Recurse -Force -ErrorAction SilentlyContinue

    Purge-StartMenuLegacyJunk "Final Pre-Restart Sweep"

    # CRITICAL POST-OPTIMIZATION FINAL LOCK: Enforce Dism++ Never Check & Edge lock right before Explorer restart
    $finalLockCmds = @(
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d 0 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "DetectionFrequencyEnabled" /t REG_DWORD /d 0 /f /reg:64',
        'delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f /reg:32',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "CachedAUOptions" /t REG_DWORD /d 1 /f /reg:64',
        'add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f /reg:64',
        'add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d 1 /f /reg:64'
    )
    if ($controls["chk_wu_disable_auto_updates"].IsChecked) {
        foreach ($cmd in $finalLockCmds) {
            $cmdNative = $cmd -replace '\s*/reg:(64|32)', ''
            cmd.exe /c "reg.exe $cmdNative" 2>$null | Out-Null
            if ([Environment]::Is64BitOperatingSystem) {
                cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
            }
        }
        foreach ($s in @("wuauserv", "UsoSvc", "WaaSMedicSvc", "dosvc")) {
            cmd.exe /c "sc.exe config $s start= disabled & sc.exe stop $s" 2>$null | Out-Null
            cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f" 2>$null | Out-Null
            if ([Environment]::Is64BitOperatingSystem) {
                cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f /reg:64" 2>$null | Out-Null
            }
        }
    }

    # Autonomous Taskbar Unpin verification right before Explorer restarts
    try {
        $ruUnpin = [char]0x043E + [char]0x0442 + [char]0x043A + [char]0x0440 + [char]0x0435 + [char]0x043F + [char]0x0438 + [char]0x0442 + [char]0x044C
        $ruPanel = [char]0x043F + [char]0x0430 + [char]0x043D + [char]0x0435 + [char]0x043B
        $appsFolder = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
        if ($appsFolder) {
            foreach ($item in $appsFolder.Items()) {
                if ($item.Name -like "*Edge*" -or $item.Path -like "*Edge*" -or $item.Path -like "*iexplore*" -or $item.Name -like "*Internet Explorer*") {
                    foreach ($verb in $item.Verbs()) {
                        $cleanVerb = ($verb.Name -replace "&", "").Trim()
                        if (($cleanVerb -match "(?i)unpin.*taskbar") -or ($cleanVerb -match "(?i)odepnout.*panel") -or ($cleanVerb -match "$ruUnpin.*$ruPanel")) {
                            $verb.DoIt()
                        }
                    }
                }
            }
        }
    } catch {}

    # Refresh Windows Shell & Taskbar: Restart explorer.exe so all changes apply immediately!
    Log-Message "Applying Taskbar changes and restarting Explorer shell..." "INFO"
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 1200
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 1500
        # Post-restart sweep: Ensure Edge didn't get pinned by default initialization
        $appsFolder = (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
        if ($appsFolder) {
            foreach ($item in $appsFolder.Items()) {
                if ($item.Name -like "*Edge*" -or $item.Path -like "*Edge*") {
                    foreach ($verb in $item.Verbs()) {
                        $cleanVerb = ($verb.Name -replace "&", "").Trim()
                        if (($cleanVerb -match "(?i)unpin.*taskbar") -or ($cleanVerb -match "(?i)odepnout.*panel") -or ($cleanVerb -match "$ruUnpin.*$ruPanel")) {
                            $verb.DoIt()
                        }
                    }
                }
            }
        }
        # Final post-restart re-assert of WU lock in case Explorer restart or service triggered background check
        if ($controls["chk_wu_disable_auto_updates"].IsChecked) {
            foreach ($cmd in $finalLockCmds) {
                $cmdNative = $cmd -replace '\s*/reg:(64|32)', ''
                cmd.exe /c "reg.exe $cmdNative" 2>$null | Out-Null
                if ([Environment]::Is64BitOperatingSystem) {
                    cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
                }
            }
        }
    } catch {}

    $pbProgress.Value = 100

    if ($pbSubTask) { $pbSubTask.Value = 100 }

    $loc = $t[$global:currentLang]

    $txtStatus.Text = "$($loc['StatusDone']) $total"

    if ($txtSubStatus) { $txtSubStatus.Text = "All operations finished successfully." }

    Log-Message "====================================================================" "INFO"

    Log-Message "ALL SELECTED OPERATIONS COMPLETED ($total of $total)!" "SUCCESS"

    Log-Message "All execution results and details are preserved in the Terminal Log above." "INFO"

    Log-Message "System restart is recommended to finalize all changes." "INFO"

    Log-Message "====================================================================" "INFO"

    # Play completion sound: exactly two short, low-pitch, clearly audible confirmation tones (~320 Hz)

    try {

        [Win32Utils.Win32Console]::Beep(320, 180) | Out-Null

        Start-Sleep -Milliseconds 90

        [Win32Utils.Win32Console]::Beep(320, 220) | Out-Null

    } catch {

        try {

            [System.Console]::Beep(320, 180)

            Start-Sleep -Milliseconds 90

            [System.Console]::Beep(320, 220)

        } catch {

            try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}

        }

    }

    $btnStartTop.IsEnabled = $true

    $btnStartBottom.IsEnabled = $true

    if ($btnSkipTop) { $btnSkipTop.IsEnabled = $false }

    if ($btnSkipBottom) { $btnSkipBottom.IsEnabled = $false }

    $btnSelectAll.IsEnabled = $true

    $btnDeselectAll.IsEnabled = $true

    $btnPresetOffice.IsEnabled = $true

    $btnPresetGaming.IsEnabled = $true

    # Big clear completion banner in Terminal Log (NO popup MessageBox per Vladimir directive)
    $bannerText = switch ($global:currentLang) {
        "en" {
            "`r`n" + ("=" * 76) + "`r`n" +
            "  >>> [DONE] ALL OPTIMIZATION TASKS COMPLETED SUCCESSFULLY! <<<`r`n" +
            "  Tasks executed: $total of $total`r`n" +
            "  PLEASE RESTART YOUR COMPUTER WHEN YOU HAVE TIME (BUTTON [⚡ REBOOT]).`r`n" +
            ("=" * 76) + "`r`n"
        }
        "cs" {
            "`r`n" + ("=" * 76) + "`r`n" +
            "  >>> [HOTOVO] VŠECHNY ÚLOHY OPTIMALIZACE BYLY ÚSPĚŠNĚ DOKONČENY! <<<`r`n" +
            "  Provedeno úloh: $total z $total`r`n" +
            "  RESTARTUJTE POČÍTAČ, AŽ BUDETE MÍT ČAS (TLAČÍTKO [⚡ REBOOT]).`r`n" +
            ("=" * 76) + "`r`n"
        }
        "ru" {
            "`r`n" + ("=" * 76) + "`r`n" +
            "  >>> [ГОТОВО] ВСЕ ОПЕРАЦИИ ОПТИМИЗАЦИИ УСПЕШНО ЗАВЕРШЕНЫ! <<<`r`n" +
            "  Выполнено задач: $total из $total`r`n" +
            "  ЖЕЛАТЕЛЬНО ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР, КОГДА БУДЕТ ВРЕМЯ (КНОПКА [⚡ REBOOT]).`r`n" +
            ("=" * 76) + "`r`n"
        }
    }
    if ($txtConsoleLog -is [System.Windows.Controls.RichTextBox]) {
        $tr = New-Object System.Windows.Documents.TextRange($txtConsoleLog.Document.ContentEnd, $txtConsoleLog.Document.ContentEnd)
        $tr.Text = $bannerText
        $yellowBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#facc15")
        $tr.ApplyPropertyValue([System.Windows.Documents.TextElement]::ForegroundProperty, $yellowBrush)
        $tr.ApplyPropertyValue([System.Windows.Documents.TextElement]::FontWeightProperty, [System.Windows.FontWeights]::Bold)
    } else {
        $txtConsoleLog.AppendText($bannerText)
    }
    $txtConsoleLog.ScrollToEnd()
    if ($txtStatus) {
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#facc15")
        $txtStatus.FontWeight = [System.Windows.FontWeights]::Bold
        $txtStatus.Text = switch ($global:currentLang) {
            "en" { "✅ COMPLETED! Please restart your computer when you have time." }
            "cs" { "✅ HOTOVO! Restartujte počítač, až budete mít čas." }
            "ru" { "✅ ГОТОВО! Желательно перезагрузить компьютер, когда будет время." }
        }
    }
    if ($txtSubStatus) {
        $txtSubStatus.Text = "All $total tasks finished."
    }
}

# Wire Start Buttons

$btnStartTop.Add_Click($executeOptimization)

$btnStartBottom.Add_Click($executeOptimization)

# Show UI Dialog with robust exception guard

try {

    $window.ShowDialog() | Out-Null

} catch {

    [System.Windows.MessageBox]::Show("Unexpected Error: " + $_.Exception.ToString(), "GIN-Win-Optimizer v046 Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)

}


<# :
@echo off
chcp 65001 >nul
setlocal DisableDelayedExpansion
title GIN-Win-Optimizer v038 - Windows 10/11 Ultimate Optimizer [ VladiMIR & Antigravity ]

:: Elevate to Administrator via PowerShell if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs"
    exit /b
)

:: Launch PowerShell cleanly in background (hidden console) for single-window GUI experience
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { $raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $raw } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'Optimizer Error') }"
exit /b
#>
# ==============================================================================
#  GIN-WIN-OPTIMIZER PLUS                                          v038
#  Windows 10/11 Ultimate Optimizer & Deep Cleaner
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
    foreach ($cmd in $wuCommands) {
        cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
    }

    # Terminate background update processes and ensure services are stopped & disabled
    Stop-Process -Name "MoUsoCoreWorker", "UsoClient", "wuauclt", "WaaSMedic", "SIHClient", "TiWorker" -Force -ErrorAction SilentlyContinue
    foreach ($s in @("wuauserv", "UsoSvc", "WaaSMedicSvc", "dosvc")) {
        cmd.exe /c "sc.exe config $s start= disabled & sc.exe stop $s" 2>$null | Out-Null
        cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f /reg:64" 2>$null | Out-Null
    }
} catch {}


# ==============================================================================

#  GIN-WIN-OPTIMIZER PLUS                                          v038

#  Rule: Strict Version Increment Mandate (v032 -> v038)

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

        "Title" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

        "HeaderTitle" = "Computer Information"

        "HeaderSub" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

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

        "chk_sec_uac_quiet" = "Silent UAC for Administrators (No prompts/dimming, keeps UWP apps working)"

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

        "chk_srv_ssd_trim" = "Disable LastAccess/8dot3 and trigger SSD TRIM"
        "chk_srv_pagefile_auto" = "Smart dynamic pagefile on C: (auto-scaled by RAM & free SSD space)"

        "chk_srv_network_offload" = "Disable network Task Offload & Chimney (prevents latency spikes)"

        "chk_srv_visual_appearance" = "Visual effects: Adjust for best appearance (enable all animations, shadows, font smoothing)"

        "chk_srv_pca" = "Disable Program Compatibility Assistant service (PcaSvc)"

        "chk_srv_trkwks" = "Disable Distributed Link Tracking Client service (TrkWks)"

        "chk_srv_iphlpsvc" = "Disable IP Helper service (iphlpsvc - uncheck if using IPv6 VPNs)"

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

        "Title" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

        "HeaderTitle" = "Údaje o počítači"

        "HeaderSub" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

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

        "chk_sec_uac_quiet" = "Tichý režim UAC pro správce (bez ztmavnutí obrazovky, UWP zachováno)"

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

        "chk_srv_ssd_trim" = "Zakázat LastAccess/8dot3 a provést okamžitý SSD TRIM"
        "chk_srv_pagefile_auto" = "Chytrý dynamický stránkovací soubor na C: (podle RAM a volného místa na SSD)"

        "chk_srv_network_offload" = "Zakázat síťový Task Offload a Chimney (ochrana před skoky latence)"

        "chk_srv_visual_appearance" = "Vizuální efekty: Nastavit pro nejlepší vzhled (všechny animace, stíny a vyhlazování)"

        "chk_srv_pca" = "Zakázat Pomocníka pro kompatibilitu programů (PcaSvc)"

        "chk_srv_trkwks" = "Zakázat Klienta sledování distribuovaných odkazů (TrkWks)"

        "chk_srv_iphlpsvc" = "Zakázat službu Pomocník protokolu IP (iphlpsvc - IPv6)"

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

        "Title" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

        "HeaderTitle" = "Данные о компьютере"

        "HeaderSub" = "GIN-Win-Optimizer v038 [VladiMIR + AI]"

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

        "chk_sec_uac_quiet" = "Бесшумный UAC для Администратора (без затемнения экрана, UWP работает)"

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

        "chk_srv_ssd_trim" = "Отключить LastAccess/8dot3 и выполнить принудительный SSD TRIM"
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
    'PSJHSU4tV2luLU9wdGltaXplciB2MDM4IFtWbGFkaU1JUiArIEFJXSIKICAgICAgICBIZWlnaHQ9Ijg5MCIgV2lkdGg9IjEyODAi'
    'CiAgICAgICAgTWluSGVpZ2h0PSI3NTAiIE1pbldpZHRoPSIxMTAwIgogICAgICAgIFdpbmRvd1N0YXJ0dXBMb2NhdGlvbj0iQ2Vu'
    'dGVyU2NyZWVuIgogICAgICAgIFdpbmRvd1N0YXRlPSJNYXhpbWl6ZWQiCiAgICAgICAgQmFja2dyb3VuZD0iIzEzMTUxOCIgRm9y'
    'ZWdyb3VuZD0iI2UwZTBlMCIKICAgICAgICBGb250RmFtaWx5PSJTZWdvZSBVSSIgRm9udFNpemU9IjEyIj4KICAgIDxXaW5kb3cu'
    'UmVzb3VyY2VzPgogICAgICAgIDxTdHlsZSBUYXJnZXRUeXBlPSJHcm91cEJveCI+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVy'
    'dHk9IkJvcmRlckJydXNoIiBWYWx1ZT0iIzI1MjgyZSIvPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJCb3JkZXJUaGlj'
    'a25lc3MiIFZhbHVlPSIxIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9Ik1hcmdpbiIgVmFsdWU9IjAsMCwwLDkiLz4K'
    'ICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iUGFkZGluZyIgVmFsdWU9IjksNiw5LDgiLz4KICAgICAgICAgICAgPFNldHRl'
    'ciBQcm9wZXJ0eT0iRm9yZWdyb3VuZCIgVmFsdWU9IiMwMGI0ZDgiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iRm9u'
    'dFdlaWdodCIgVmFsdWU9IlNlbWlCb2xkIi8+CiAgICAgICAgPC9TdHlsZT4KICAgICAgICA8U3R5bGUgVGFyZ2V0VHlwZT0iQ2hl'
    'Y2tCb3giPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJGb3JlZ3JvdW5kIiBWYWx1ZT0iI2Q0ZDRkOCIvPgogICAgICAg'
    'ICAgICA8U2V0dGVyIFByb3BlcnR5PSJNYXJnaW4iIFZhbHVlPSIyLDIsMiwzIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVy'
    'dHk9IkZvbnRXZWlnaHQiIFZhbHVlPSJOb3JtYWwiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iRm9udFNpemUiIFZh'
    'bHVlPSIxMS41Ii8+CiAgICAgICAgPC9TdHlsZT4KICAgICAgICA8U3R5bGUgVGFyZ2V0VHlwZT0iQnV0dG9uIj4KICAgICAgICAg'
    'ICAgPFNldHRlciBQcm9wZXJ0eT0iQmFja2dyb3VuZCIgVmFsdWU9IiMyNTI4MmUiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9w'
    'ZXJ0eT0iRm9yZWdyb3VuZCIgVmFsdWU9IiNmZmZmZmYiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iQm9yZGVyQnJ1'
    'c2giIFZhbHVlPSIjM2EzZDQ1Ii8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkJvcmRlclRoaWNrbmVzcyIgVmFsdWU9'
    'IjEiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iUGFkZGluZyIgVmFsdWU9IjEwLDUiLz4KICAgICAgICAgICAgPFNl'
    'dHRlciBQcm9wZXJ0eT0iRm9udFdlaWdodCIgVmFsdWU9IlNlbWlCb2xkIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9'
    'IkN1cnNvciIgVmFsdWU9IkhhbmQiLz4KICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iVGVtcGxhdGUiPgogICAgICAgICAg'
    'ICAgICAgPFNldHRlci5WYWx1ZT4KICAgICAgICAgICAgICAgICAgICA8Q29udHJvbFRlbXBsYXRlIFRhcmdldFR5cGU9IkJ1dHRv'
    'biI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxCb3JkZXIgeDpOYW1lPSJib3JkZXIiIEJhY2tncm91bmQ9IntUZW1wbGF0ZUJp'
    'bmRpbmcgQmFja2dyb3VuZH0iIEJvcmRlckJydXNoPSJ7VGVtcGxhdGVCaW5kaW5nIEJvcmRlckJydXNofSIgQm9yZGVyVGhpY2tu'
    'ZXNzPSJ7VGVtcGxhdGVCaW5kaW5nIEJvcmRlclRoaWNrbmVzc30iIENvcm5lclJhZGl1cz0iMyIgUGFkZGluZz0ie1RlbXBsYXRl'
    'QmluZGluZyBQYWRkaW5nfSI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q29udGVudFByZXNlbnRlciB4Ok5hbWU9ImNv'
    'bnRlbnRQcmVzZW50ZXIiIEhvcml6b250YWxBbGlnbm1lbnQ9IkNlbnRlciIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRlciIgRm9j'
    'dXNhYmxlPSJGYWxzZSIgUmVjb2duaXplc0FjY2Vzc0tleT0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L0JvcmRl'
    'cj4KICAgICAgICAgICAgICAgICAgICAgICAgPENvbnRyb2xUZW1wbGF0ZS5UcmlnZ2Vycz4KICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgIDxUcmlnZ2VyIFByb3BlcnR5PSJJc01vdXNlT3ZlciIgVmFsdWU9IlRydWUiPgogICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgIDxTZXR0ZXIgVGFyZ2V0TmFtZT0iYm9yZGVyIiBQcm9wZXJ0eT0iQmFja2dyb3VuZCIgVmFsdWU9IiMzNTNiNDgi'
    'Lz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5hbWU9ImJvcmRlciIgUHJvcGVydHk9IkJv'
    'cmRlckJydXNoIiBWYWx1ZT0iIzAwYjRkOCIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9UcmlnZ2VyPgogICAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgPFRyaWdnZXIgUHJvcGVydHk9IklzUHJlc3NlZCIgVmFsdWU9IlRydWUiPgogICAgICAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgIDxTZXR0ZXIgVGFyZ2V0TmFtZT0iYm9yZGVyIiBQcm9wZXJ0eT0iQmFja2dyb3VuZCIgVmFs'
    'dWU9IiMxYTFjMjMiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvVHJpZ2dlcj4KICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgIDxUcmlnZ2VyIFByb3BlcnR5PSJJc0VuYWJsZWQiIFZhbHVlPSJGYWxzZSI+CiAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgPFNldHRlciBUYXJnZXROYW1lPSJib3JkZXIiIFByb3BlcnR5PSJCYWNrZ3JvdW5kIiBWYWx1ZT0iIzFjMWYyNiIv'
    'PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxTZXR0ZXIgVGFyZ2V0TmFtZT0iYm9yZGVyIiBQcm9wZXJ0eT0iQm9y'
    'ZGVyQnJ1c2giIFZhbHVlPSIjMmUzMjNiIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPFNldHRlciBQcm9wZXJ0'
    'eT0iRm9yZWdyb3VuZCIgVmFsdWU9IiM5NGEzYjgiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvVHJpZ2dlcj4KICAg'
    'ICAgICAgICAgICAgICAgICAgICAgPC9Db250cm9sVGVtcGxhdGUuVHJpZ2dlcnM+CiAgICAgICAgICAgICAgICAgICAgPC9Db250'
    'cm9sVGVtcGxhdGU+CiAgICAgICAgICAgICAgICA8L1NldHRlci5WYWx1ZT4KICAgICAgICAgICAgPC9TZXR0ZXI+CiAgICAgICAg'
    'PC9TdHlsZT4KICAgIDwvV2luZG93LlJlc291cmNlcz4KCiAgICA8R3JpZCBNYXJnaW49IjEyIj4KICAgICAgICA8R3JpZC5Sb3dE'
    'ZWZpbml0aW9ucz4KICAgICAgICAgICAgPFJvd0RlZmluaXRpb24gSGVpZ2h0PSJBdXRvIi8+CiAgICAgICAgICAgIDxSb3dEZWZp'
    'bml0aW9uIEhlaWdodD0iQXV0byIvPgogICAgICAgICAgICA8Um93RGVmaW5pdGlvbiBIZWlnaHQ9IioiLz4KICAgICAgICAgICAg'
    'PFJvd0RlZmluaXRpb24gSGVpZ2h0PSIxODUiLz4KICAgICAgICAgICAgPFJvd0RlZmluaXRpb24gSGVpZ2h0PSJBdXRvIi8+CiAg'
    'ICAgICAgPC9HcmlkLlJvd0RlZmluaXRpb25zPgoKICAgICAgICA8IS0tIFRvcCBIZWFkZXIgLS0+CiAgICAgICAgPEJvcmRlciBH'
    'cmlkLlJvdz0iMCIgQmFja2dyb3VuZD0iIzFhMWMyMSIgQ29ybmVyUmFkaXVzPSI2IiBQYWRkaW5nPSIxNCwxMCIgTWFyZ2luPSIw'
    'LDAsMCw4IiBCb3JkZXJCcnVzaD0iIzI1MjgyZSIgQm9yZGVyVGhpY2tuZXNzPSIxIj4KICAgICAgICAgICAgPERvY2tQYW5lbCBM'
    'YXN0Q2hpbGRGaWxsPSJUcnVlIj4KICAgICAgICAgICAgICAgIDwhLS0gUmlnaHQgQ29udHJvbHM6IFNraXAsIFN0YXJ0LCBFeGl0'
    'IC0tPgogICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgRG9ja1BhbmVsLkRvY2s9IlJpZ2h0IiBPcmllbnRhdGlvbj0iSG9yaXpv'
    'bnRhbCIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRlciI+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5Ta2lw'
    'VG9wIiBDb250ZW50PSLij60gU0tJUCBTVEVQIiBCYWNrZ3JvdW5kPSIjZDk3NzA2IiBCb3JkZXJCcnVzaD0iI2Y1OWUwYiIgRm9y'
    'ZWdyb3VuZD0iI2ZmZmZmZiIgRm9udFdlaWdodD0iQm9sZCIgUGFkZGluZz0iMTQsOCIgTWFyZ2luPSIwLDAsOCwwIiBGb250U2l6'
    'ZT0iMTMiIElzRW5hYmxlZD0iRmFsc2UiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blN0YXJ0VG9wIiBD'
    'b250ZW50PSLwn5qAINCe0J/QotCY0JzQmNCX0JjQoNCe0JLQkNCi0KwiIEJhY2tncm91bmQ9IiMwMDc3YjYiIEJvcmRlckJydXNo'
    'PSIjMDA5NmM3IiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBGb250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNiw4IiBNYXJnaW49IjAs'
    'MCw4LDAiIEZvbnRTaXplPSIxMyIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuUmVib290VG9wIiBDb250'
    'ZW50PSLimqEgUkVCT09UIiBCYWNrZ3JvdW5kPSIjZGMyNjI2IiBCb3JkZXJCcnVzaD0iI2ZmNGQ0ZiIgRm9yZWdyb3VuZD0iI2Zm'
    'ZmZmZiIgRm9udFdlaWdodD0iQm9sZCIgUGFkZGluZz0iMTYsOCIgTWFyZ2luPSIwLDAsOCwwIiBGb250U2l6ZT0iMTMiIFZpc2li'
    'aWxpdHk9IlZpc2libGUiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkV4aXRUb3AiIENvbnRlbnQ9IkV4'
    'aXQiIEJhY2tncm91bmQ9IiMzYTFjMWMiIEJvcmRlckJydXNoPSIjNjYyMjIyIiBGb3JlZ3JvdW5kPSIjZmY4ODg4IiBQYWRkaW5n'
    'PSIxMiw4Ii8+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CgogICAgICAgICAgICAgICAgPCEtLSBDZW50ZXIgQ29udHJv'
    'bHM6IExhbmd1YWdlIFN3aXRjaGVyIFBpbGxzICYgVGVsZWdyYW0gLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBEb2Nr'
    'UGFuZWwuRG9jaz0iUmlnaHQiIE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIiBWZXJ0aWNhbEFsaWdubWVudD0iQ2VudGVyIiBNYXJn'
    'aW49IjAsMCwxNiwwIj4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blRlbGVncmFtIiBDb250ZW50PSLinIjv'
    'uI8gVGVsZWdyYW0gKEBHaW5DeikiIEJhY2tncm91bmQ9IiMwMDg4Y2MiIEJvcmRlckJydXNoPSIjMjliNmY2IiBGb3JlZ3JvdW5k'
    'PSIjZmZmZmZmIiBGb250V2VpZ2h0PSJTZW1pQm9sZCIgUGFkZGluZz0iMTAsNSIgTWFyZ2luPSIwLDAsMTIsMCIgRm9udFNpemU9'
    'IjExIiBUb29sVGlwPSLQndCw0L/QuNGB0LDRgtGMINCw0LLRgtC+0YDRgyDQsiBUZWxlZ3JhbSAoQEdpbkN6KTogaHR0cHM6Ly90'
    'Lm1lL0dpbkN6Ii8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5MYW5nUnUiIENvbnRlbnQ9IlJVIiBCYWNr'
    'Z3JvdW5kPSIjMWUzYTVmIiBCb3JkZXJCcnVzaD0iIzAwYjRkOCIgRm9yZWdyb3VuZD0iI2ZmZmZmZiIgUGFkZGluZz0iOCw0IiBN'
    'YXJnaW49IjAsMCw0LDAiIEZvbnRTaXplPSIxMSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuTGFuZ0Vu'
    'IiBDb250ZW50PSJFTiIgQmFja2dyb3VuZD0iIzI1MjgyZSIgQm9yZGVyQnJ1c2g9IiMzYTNkNDUiIEZvcmVncm91bmQ9IiNiMGIz'
    'YjgiIFBhZGRpbmc9IjgsNCIgTWFyZ2luPSIwLDAsNCwwIiBGb250U2l6ZT0iMTEiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0'
    'dG9uIE5hbWU9ImJ0bkxhbmdDcyIgQ29udGVudD0iQ1oiIEJhY2tncm91bmQ9IiMyNTI4MmUiIEJvcmRlckJydXNoPSIjM2EzZDQ1'
    'IiBGb3JlZ3JvdW5kPSIjYjBiM2I4IiBQYWRkaW5nPSI4LDQiIEZvbnRTaXplPSIxMSIvPgogICAgICAgICAgICAgICAgPC9TdGFj'
    'a1BhbmVsPgoKICAgICAgICAgICAgICAgIDwhLS0gTGVmdCBJbmZvOiBDb21wdXRlciBJbmZvcm1hdGlvbiAmIFNwZWNzIC0tPgog'
    'ICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgT3JpZW50YXRpb249IlZlcnRpY2FsIj4KICAgICAgICAgICAgICAgICAgICA8U3Rh'
    'Y2tQYW5lbCBPcmllbnRhdGlvbj0iSG9yaXpvbnRhbCI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sgTmFtZT0i'
    'dHh0SGVhZGVyVGl0bGUiIFRleHQ9ItCU0LDQvdC90YvQtSDQviDQutC+0LzQv9GM0Y7RgtC10YDQtSIgRm9udFNpemU9IjE0IiBG'
    'b250V2VpZ2h0PSJCb2xkIiBGb3JlZ3JvdW5kPSIjMDBiNGQ4Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgIDxCb3JkZXIgQmFj'
    'a2dyb3VuZD0iIzE2NjUzNCIgQ29ybmVyUmFkaXVzPSIzIiBQYWRkaW5nPSI2LDEiIE1hcmdpbj0iOCwwLDAsMCIgVmVydGljYWxB'
    'bGlnbm1lbnQ9IkNlbnRlciI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8VGV4dEJsb2NrIFRleHQ9IkFETUlOIiBGb250'
    'U2l6ZT0iOSIgRm9udFdlaWdodD0iQm9sZCIgRm9yZWdyb3VuZD0iIzg2ZWZhYyIvPgogICAgICAgICAgICAgICAgICAgICAgICA8'
    'L0JvcmRlcj4KICAgICAgICAgICAgICAgICAgICAgICAgPEJvcmRlciBCYWNrZ3JvdW5kPSIjMGY3NjZlIiBDb3JuZXJSYWRpdXM9'
    'IjMiIFBhZGRpbmc9IjYsMSIgTWFyZ2luPSI2LDAsMCwwIiBWZXJ0aWNhbEFsaWdubWVudD0iQ2VudGVyIiBUb29sVGlwPSLQkdC1'
    '0YHQv9C70LDRgtC90LDRjyDQv9C+0LbQuNC30L3QtdC90L3QsNGPINC70LjRhtC10L3Qt9C40Y8gKFBlcnNvbmFsICZhbXA7IEJ1'
    'c2luZXNzIEZyZWV3YXJlKSI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8VGV4dEJsb2NrIFRleHQ9IkZSRUVXQVJFIiBG'
    'b250U2l6ZT0iOSIgRm9udFdlaWdodD0iQm9sZCIgRm9yZWdyb3VuZD0iIzVlZWFkNCIvPgogICAgICAgICAgICAgICAgICAgICAg'
    'ICA8L0JvcmRlcj4KICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9j'
    'ayBOYW1lPSJ0eHRIb3N0SW5mbyIgVGV4dD0iSG9zdDogbG9jYWwgfCDQo9GB0YLRgNC+0LnRgdGC0LLQvjogUEMgfCBXaW5kb3dz'
    'OiAxMCBQcm8gfCBJUDogMTI3LjAuMC4xIiBGb250U2l6ZT0iMTEiIEZvcmVncm91bmQ9IiNjYmQ1ZTEiIE1hcmdpbj0iMCwzLDAs'
    'MCIvPgogICAgICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sgTmFtZT0idHh0SGVhZGVyU3ViIiBUZXh0PSJHSU4tV2luLU9wdGlt'
    'aXplciB2MDM4IFtWbGFkaU1JUiArIEFJXSIgRm9udFNpemU9IjEwIiBGb3JlZ3JvdW5kPSIjNjQ3NDhiIiBNYXJnaW49IjAsMSww'
    'LDAiLz4KICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgPC9Eb2NrUGFuZWw+CiAgICAgICAgPC9Cb3Jk'
    'ZXI+CgogICAgICAgIDwhLS0gUHJlc2V0cyBCYXIgLS0+CiAgICAgICAgPEJvcmRlciBHcmlkLlJvdz0iMSIgQmFja2dyb3VuZD0i'
    'IzFlMjAyNiIgQ29ybmVyUmFkaXVzPSI0IiBQYWRkaW5nPSIxMCw2IiBNYXJnaW49IjAsMCwwLDgiIEJvcmRlckJydXNoPSIjMjUy'
    'ODJlIiBCb3JkZXJUaGlja25lc3M9IjEiPgogICAgICAgICAgICA8RG9ja1BhbmVsIExhc3RDaGlsZEZpbGw9IlRydWUiPgogICAg'
    'ICAgICAgICAgICAgPFRleHRCbG9jayBOYW1lPSJ0eHRQcmVzZXRzIiBUZXh0PSJQcmVzZXRzOiIgVmVydGljYWxBbGlnbm1lbnQ9'
    'IkNlbnRlciIgRm9udFdlaWdodD0iQm9sZCIgRm9yZWdyb3VuZD0iI2I1YmFjMSIgTWFyZ2luPSIwLDAsMTAsMCIvPgogICAgICAg'
    'ICAgICAgICAgPFN0YWNrUGFuZWwgT3JpZW50YXRpb249Ikhvcml6b250YWwiPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24g'
    'TmFtZT0iYnRuU2VsZWN0QWxsIiBDb250ZW50PSLinJMgU2VsZWN0IEFsbCAoTWF4IENsZWFuKSIgTWFyZ2luPSIwLDAsNiwwIiBQ'
    'YWRkaW5nPSIxMCw0IiBCYWNrZ3JvdW5kPSIjMTQ1MzJkIiBCb3JkZXJCcnVzaD0iIzIyYzU1ZSIgRm9yZWdyb3VuZD0iIzg2ZWZh'
    'YyIgRm9udFdlaWdodD0iU2VtaUJvbGQiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkRlc2VsZWN0QWxs'
    'IiBDb250ZW50PSLinJcgRGVzZWxlY3QgQWxsIiBNYXJnaW49IjAsMCw2LDAiIFBhZGRpbmc9IjEwLDQiLz4KICAgICAgICAgICAg'
    'ICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blByZXNldE9mZmljZSIgQ29udGVudD0i8J+PoiBPZmZpY2UgKEtlZXAgT25lRHJpdmUp'
    'IiBNYXJnaW49IjAsMCw2LDAiIFBhZGRpbmc9IjEwLDQiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blBy'
    'ZXNldEdhbWluZyIgQ29udGVudD0i4pqhIEdhbWluZyAoS2VlcCBYYm94KSIgTWFyZ2luPSIwLDAsNiwwIiBQYWRkaW5nPSIxMCw0'
    'Ii8+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgogICAgICAgIDwvQm9yZGVy'
    'PgoKICAgICAgICA8IS0tIE1haW4gU2Nyb2xsYWJsZSBPcHRpb25zIEdyaWQgLS0+CiAgICAgICAgPFNjcm9sbFZpZXdlciBHcmlk'
    'LlJvdz0iMiIgVmVydGljYWxTY3JvbGxCYXJWaXNpYmlsaXR5PSJBdXRvIiBIb3Jpem9udGFsU2Nyb2xsQmFyVmlzaWJpbGl0eT0i'
    'RGlzYWJsZWQiIE1hcmdpbj0iMCwwLDAsOCI+CiAgICAgICAgICAgIDxHcmlkPgogICAgICAgICAgICAgICAgPEdyaWQuQ29sdW1u'
    'RGVmaW5pdGlvbnM+CiAgICAgICAgICAgICAgICAgICAgPENvbHVtbkRlZmluaXRpb24gV2lkdGg9IioiLz4KICAgICAgICAgICAg'
    'ICAgICAgICA8Q29sdW1uRGVmaW5pdGlvbiBXaWR0aD0iKiIvPgogICAgICAgICAgICAgICAgICAgIDxDb2x1bW5EZWZpbml0aW9u'
    'IFdpZHRoPSIqIi8+CiAgICAgICAgICAgICAgICA8L0dyaWQuQ29sdW1uRGVmaW5pdGlvbnM+CgogICAgICAgICAgICAgICAgPCEt'
    'LSBDT0xVTU4gMSAtLT4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIEdyaWQuQ29sdW1uPSIwIiBNYXJnaW49IjAsMCw2LDAi'
    'PgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6IFByaXZhY3kgJiBUZWxlbWV0cnkgLS0+CiAgICAgICAgICAgICAgICAg'
    'ICAgPEdyb3VwQm94IE5hbWU9ImdycFByaXZhY3kiIEhlYWRlcj0iUHJpdmFjeSAmYW1wOyBUZWxlbWV0cnkiPgogICAgICAgICAg'
    'ICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtf'
    'dGVsZW1fZGlhZ3RyYWNrIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBO'
    'YW1lPSJjaGtfdGVsZW1fZG13YXBwdXNoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD'
    'aGVja0JveCBOYW1lPSJjaGtfdGVsZW1fd2VyIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'IDxDaGVja0JveCBOYW1lPSJjaGtfdGVsZW1fYWxsb3dfdGVsZW0iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV9hZF9pZCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAg'
    'ICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2lua2luZyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2FjdGl2aXR5IiBJc0NoZWNrZWQ9IlRydWUi'
    'Lz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGVsZW1fbG9jYXRpb24iIElzQ2hlY2tl'
    'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV9mZWVkYmFjayIg'
    'SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX3Rh'
    'c2tzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGVs'
    'ZW1fY29ydGFuYSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i'
    'Y2hrX25ldF93aWZpX3ByaXZhY3kiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFu'
    'ZWw+CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogU2VjdXJp'
    'dHkgJiBVQUMgLS0+CiAgICAgICAgICAgICAgICAgICAgPEdyb3VwQm94IE5hbWU9ImdycFNlY3VyaXR5IiBIZWFkZXI9IlNlY3Vy'
    'aXR5ICZhbXA7IFVBQyBUd2Vha3MiPgogICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc2VjX3VhY19xdWlldCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAg'
    'ICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY19hZG1pbl9hcHByb3ZhbCIgSXNDaGVja2VkPSJUcnVl'
    'Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY19zbWFydHNjcmVlbiIgSXNDaGVj'
    'a2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY19vcGVuX2ZpbGVf'
    'd2FybmluZyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAg'
    'ICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBDbG91ZCAmIENvbnN1bWVyIC0t'
    'PgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBDbG91ZCIgSGVhZGVyPSJDbG91ZCAmYW1wOyBDb25zdW1l'
    'ciBGZWF0dXJlcyI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91ZF9vbmVkcml2ZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX3NldHRpbmdzX3N5bmMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91ZF9iaW5nX3NlYXJjaCIgSXNDaGVja2VkPSJU'
    'cnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX3Nwb3RsaWdodCIgSXND'
    'aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX2NvbnN1'
    'bWVyX2ZlYXR1cmVzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAg'
    'ICAgICAgICAgICAgICAgIDwvR3JvdXBCb3g+CgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6IE1pY3Jvc29mdCBFZGdl'
    'IC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBFZGdlIiBIZWFkZXI9Ik1pY3Jvc29mdCBFZGdlIE9w'
    'dGltaXphdGlvbiI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX2JhY2tncm91bmQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3N0YXJ0dXBfYm9vc3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3RlbGVtZXRyeSIgSXNDaGVja2VkPSJUcnVl'
    'Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2VkZ2Vfc2lkZWJhciIgSXNDaGVja2Vk'
    'PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2VkZ2VfcHJlbGF1bmNoIiBJ'
    'c0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZWRnZV9maXJz'
    'dF9ydW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19l'
    'ZGdlX3VucGluIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAg'
    'ICAgICAgICAgICAgIDwvR3JvdXBCb3g+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CgogICAgICAgICAgICAgICAgPCEt'
    'LSBDT0xVTU4gMiAtLT4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIEdyaWQuQ29sdW1uPSIxIiBNYXJnaW49IjMsMCwzLDAi'
    'PgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6IEV4cGxvcmVyLCBEZXNrdG9wICYgVGFza2JhciAtLT4KICAgICAgICAg'
    'ICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwVUkiIEhlYWRlcj0iRXhwbG9yZXIsIERlc2t0b3AgJmFtcDsgVGFza2JhciI+'
    'CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPCEtLSBIaWdo'
    'bGlnaHRlZCBpbiBZZWxsb3c6IFNoZWxsIEZvbGRlcnMgUmVsb2NhdGlvbiB0byBEOlwgKE9GRiBieSBkZWZhdWx0KSAtLT4KICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgIDxCb3JkZXIgQmFja2dyb3VuZD0iIzIzMWYwOCIgQm9yZGVyQnJ1c2g9IiNlYWIzMDgi'
    'IEJvcmRlclRoaWNrbmVzcz0iMSIgQ29ybmVyUmFkaXVzPSI0IiBQYWRkaW5nPSI2LDQiIE1hcmdpbj0iMCwwLDAsNiI+CiAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'IDxDaGVja0JveCBOYW1lPSJjaGtfcmVsb2NfZG9jdW1lbnRzIiBJc0NoZWNrZWQ9IkZhbHNlIiBGb3JlZ3JvdW5kPSIjZmFjYzE1'
    'IiBGb250V2VpZ2h0PSJCb2xkIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJj'
    'aGtfcmVsb2NfZGVza3RvcCIgSXNDaGVja2VkPSJGYWxzZSIgRm9yZWdyb3VuZD0iI2ZhY2MxNSIgRm9udFdlaWdodD0iQm9sZCIv'
    'PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'IDwvQm9yZGVyPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV93aWRnZXRzIiBJc0No'
    'ZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfdGVhbXNfY2hh'
    'dCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2Nv'
    'cGlsb3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191'
    'aV9yZWNhbGwiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo'
    'a191aV9zdGFydF9hZHMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5h'
    'bWU9ImNoa191aV9leHBsb3Jlcl9hZHMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENo'
    'ZWNrQm94IE5hbWU9ImNoa191aV93ZWxjb21lX3NjcmVlbiIgSXNDaGVja2VkPSJUcnVlIi8+DQogICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9sb2Nrc2NyZWVuX2NsZWFuIiBJc0NoZWNrZWQ9IlRydWUiLz4NCiAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2NvbG9yX2FjY2VudF90aGVtZSIgSXNDaGVja2Vk'
    'PSJUcnVlIi8+DQogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9tb3VzZV9pbnZlcnRl'
    'ZF9sYXJnZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hr'
    'X3VpX2NsYXNzaWNfY29udGV4dCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC'
    'b3ggTmFtZT0iY2hrX3VpX2hpZGVfc2VhcmNoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'IDxDaGVja0JveCBOYW1lPSJjaGtfdWlfaGlkZV90YXNrdmlldyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX3Nob3dfYWxsX3RyYXlfaWNvbnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgog'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9uZXZlcl9jb21iaW5lX3Rhc2tiYXIiIElz'
    'Q2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9zaG93X3Ro'
    'aXNfcGMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191'
    'aV9jbG9ja18yNGhfc2Vjb25kcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC'
    'b3ggTmFtZT0iY2hrX3VpX3JlZ2lvbl90aW1lX2N6ZWNoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfbGFuZ19rZXlib2FyZHMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg'
    'ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9yZWdpb25hbF9kYXRlX2Zvcm1hdCIgSXNDaGVja2VkPSJU'
    'cnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RiX3NtYWxsX2ljb25zIiBJc0No'
    'ZWNrZWQ9IkZhbHNlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RiX2xvY2siIElz'
    'Q2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190Yl9oaWRlX2Fj'
    'dGlvbl9jZW50ZXIiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
    'ImNoa190Yl9oaWRlX3Blb3BsZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC'
    'b3ggTmFtZT0iY2hrX2V4cF9vcGVuX3RoaXNfcGMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9mb2xkZXJfdmlld19saXN0X3NvcnRfdHlwZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9oaWRlX3VzZXJfZm9sZGVycyIgSXNDaGVj'
    'a2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9ub19zaG9ydGN1'
    'dF9zdWZmaXgiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo'
    'a19leHBfaGlkZV9xdWlja19hY2Nlc3NfcmVjZW50IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZXhwX3Nob3dfZnVsbF9wYXRoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAg'
    'ICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZXhwX3NlcGFyYXRlX3Byb2Nlc3MiIElzQ2hlY2tlZD0iVHJ1ZSIv'
    'PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19leHBfaGlkZV9uYXZfbGlicmFyaWVzIiBJ'
    'c0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZGVza3RvcF9z'
    'aG93X3VzZXJfZm9sZGVyIiBJc0NoZWNrZWQ9IkZhbHNlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4K'
    'ICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBDb250ZXh0IE1l'
    'bnUgQ2xlYW51cCAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwQ29udGV4dE1lbnUiIEhlYWRlcj0i'
    'Q29udGV4dCBNZW51IENsZWFudXAgKFJpZ2h0LUNsaWNrKSI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgog'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jdHhfY2xlYW51cF9ibG9hdCIgSXNDaGVja2Vk'
    'PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2N0eF93aW5yYXJfZW1haWwi'
    'IElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAg'
    'ICAgPC9Hcm91cEJveD4KICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KCiAgICAgICAgICAgICAgICA8IS0tIENPTFVNTiAz'
    'IC0tPgogICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgR3JpZC5Db2x1bW49IjIiIE1hcmdpbj0iNiwwLDAsMCI+CiAgICAgICAg'
    'ICAgICAgICAgICAgPCEtLSBHcm91cDogV2luZG93cyBVcGRhdGUgJiBTeXN0ZW0gRGlhZ25vc3RpY3MgLS0+CiAgICAgICAgICAg'
    'ICAgICAgICAgPEdyb3VwQm94IE5hbWU9ImdycFdpblVwZGF0ZSIgSGVhZGVyPSJXaW5kb3dzIFVwZGF0ZSwgQlNPRCAmYW1wOyBT'
    'eXN0ZW0iPgogICAgICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD'
    'aGVja0JveCBOYW1lPSJjaGtfd3VfZGlzYWJsZV9hdXRvX3VwZGF0ZXMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAg'
    'ICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa193dV9leGNsdWRlX2RyaXZlcnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgog'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa193dV9leGNsdWRlX21zcnQiIElzQ2hlY2tlZD0i'
    'VHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfYnNvZF9ub19hdXRvcmVi'
    'b290IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3lz'
    'X3NtYWxsX21pbmlkdW1wIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBO'
    'YW1lPSJjaGtfc3lzX2Zhc3Rfc3RhcnR1cF9vZmYiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfZGlzYWJsZV9yZW1vdGVfYXNzaXN0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3lzX2VuYWJsZV9waG90b192aWV3ZXIiIElzQ2hlY2tl'
    'ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfbm90ZXBhZF90d2Vh'
    'a3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAg'
    'ICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogQXBwcyAmIEJsb2F0d2FyZSAtLT4KICAg'
    'ICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwQXBwcyIgSGVhZGVyPSJBcHAgRGVibG9hdGVyICZhbXA7IFByb3Zp'
    'c2lvbmVkIFBhY2thZ2VzIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF94Ym94IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX2dhbWViYXJfZGlzYWJsZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9nYW1lcyIgSXNDaGVja2VkPSJUcnVlIi8+CiAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9uZXdzIiBJc0NoZWNrZWQ9IlRydWUiLz4K'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX29mZmljZV9zdHViIiBJc0NoZWNrZWQ9'
    'IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX2NsaXBjaGFtcCIgSXND'
    'aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9wZW9wbGUi'
    'IElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19hcHBfZmVl'
    'ZGJhY2siIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19h'
    'cHBfZ2V0X2hlbHAiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
    'ImNoa19hcHBfcGhvbmUiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAg'
    'ICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogU2VydmljZXMgJiBQ'
    'ZXJmb3JtYW5jZSAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwU2VydmljZXMiIEhlYWRlcj0iU3lz'
    'dGVtIFBlcmZvcm1hbmNlICZhbXA7IFNlcnZpY2VzIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+CiAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9zeXNtYWluIiBJc0NoZWNrZWQ9IlRydWUiLz4K'
    'ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X2luZGV4aW5nIiBJc0NoZWNrZWQ9IlRy'
    'dWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3JlbW90ZV9yZWciIElzQ2hl'
    'Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfZGVsaXZlcnlf'
    'b3B0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2'
    'X3Jlc2VydmVkX3N0b3JhZ2UiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94'
    'IE5hbWU9ImNoa19zcnZfaGliZXJuYXRpb24iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'PENoZWNrQm94IE5hbWU9ImNoa19zcnZfcG93ZXJfcGxhbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9wb3dlcl9zbGVlcF9zY3JlZW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg'
    'ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfc3NkX3RyaW0iIElzQ2hlY2tlZD0iVHJ1ZSIv'
    'Pg0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3BhZ2VmaWxlX2F1dG8iIElzQ2hl'
    'Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfbmV0d29ya19v'
    'ZmZsb2FkIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtf'
    'c3J2X3Zpc3VhbF9hcHBlYXJhbmNlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVj'
    'a0JveCBOYW1lPSJjaGtfc3J2X3BjYSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hl'
    'Y2tCb3ggTmFtZT0iY2hrX3Nydl90cmt3a3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAg'
    'PENoZWNrQm94IE5hbWU9ImNoa19zcnZfaXBobHBzdmMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAg'
    'ICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBH'
    'cm91cDogQ2FjaGUgJiBDbGVhbmluZyAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwQ2xlYW4iIEhl'
    'YWRlcj0iQ2FjaGUgJmFtcDsgQ29tcG9uZW50IENsZWFuaW5nIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFuZWw+'
    'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8IS0tIFRoZSAzIGxvbmdlc3Qvc2xvd2VzdCBtYWludGVuYW5jZSBvcGVyYXRp'
    'b25zIChoaWdobGlnaHRlZCBpbiBicmlnaHQgcmVkLCBPRkYgYnkgZGVmYXVsdCkgLS0+CiAgICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2RlZXBfZGlzbV9yZXBhaXIiIElzQ2hlY2tlZD0iRmFsc2UiIEZvcmVncm91bmQ9IiNm'
    'ZjRkNGYiIEZvbnRXZWlnaHQ9IkJvbGQiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtf'
    'ZGVlcF9kaXNtX3Jlc2V0YmFzZSIgSXNDaGVja2VkPSJGYWxzZSIgRm9yZWdyb3VuZD0iI2ZmNGQ0ZiIgRm9udFdlaWdodD0iQm9s'
    'ZCIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19kZWVwX3NmY19jb21wYWN0IiBJc0No'
    'ZWNrZWQ9IkZhbHNlIiBGb3JlZ3JvdW5kPSIjZmY0ZDRmIiBGb250V2VpZ2h0PSJCb2xkIi8+CiAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgICA8U2VwYXJhdG9yIEJhY2tncm91bmQ9IiMyZTMyM2IiIE1hcmdpbj0iMCwzLDAsNCIvPgogICAgICAgICAgICAgICAg'
    'ICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbGVhbl91c2VyX3RlbXAiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAg'
    'ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbGVhbl93aW5fdGVtcCIgSXNDaGVja2VkPSJUcnVlIi8+'
    'CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFuX3NvZnRfZGlzdCIgSXNDaGVja2Vk'
    'PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFuX3RodW1iX2NhY2hl'
    'IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xlYW5f'
    'c2hhZGVyc19kbnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9'
    'ImNoa19jbGVhbl9ldmVudF9sb2dzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVj'
    'a0JveCBOYW1lPSJjaGtfY2xlYW5fcmVjeWNsZV9iaW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAg'
    'ICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbGVhbl9jbGVhbm1nciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAg'
    'ICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgogICAgICAgICAgICAgICAgPC9T'
    'dGFja1BhbmVsPgogICAgICAgICAgICA8L0dyaWQ+CiAgICAgICAgPC9TY3JvbGxWaWV3ZXI+CgogICAgICAgIDwhLS0gTGl2ZSBF'
    'eGVjdXRpb24gQ29uc29sZSAvIExvZyBCb3ggKEhlaWdodCAxODUpIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9IjMiIEJh'
    'Y2tncm91bmQ9IiMwYjBjMGUiIENvcm5lclJhZGl1cz0iNCIgUGFkZGluZz0iOCw2IiBCb3JkZXJCcnVzaD0iIzI1MjgyZSIgQm9y'
    'ZGVyVGhpY2tuZXNzPSIxIj4KICAgICAgICAgICAgPEdyaWQ+CiAgICAgICAgICAgICAgICA8R3JpZC5Sb3dEZWZpbml0aW9ucz4K'
    'ICAgICAgICAgICAgICAgICAgICA8Um93RGVmaW5pdGlvbiBIZWlnaHQ9IkF1dG8iLz4KICAgICAgICAgICAgICAgICAgICA8Um93'
    'RGVmaW5pdGlvbiBIZWlnaHQ9IkF1dG8iLz4KICAgICAgICAgICAgICAgICAgICA8Um93RGVmaW5pdGlvbiBIZWlnaHQ9IioiLz4K'
    'ICAgICAgICAgICAgICAgIDwvR3JpZC5Sb3dEZWZpbml0aW9ucz4KCiAgICAgICAgICAgICAgICA8IS0tIENvbnNvbGUgSGVhZGVy'
    'IFRvb2xiYXIgLS0+CiAgICAgICAgICAgICAgICA8RG9ja1BhbmVsIEdyaWQuUm93PSIwIiBNYXJnaW49IjAsMCwwLDQiPgogICAg'
    'ICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIERvY2tQYW5lbC5Eb2NrPSJSaWdodCIgT3JpZW50YXRpb249Ikhvcml6b250YWwi'
    'PgogICAgICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkNsZWFyTG9nIiBDb250ZW50PSLwn6e5IENsZWFyIiBN'
    'YXJnaW49IjAsMCw0LDAiIFBhZGRpbmc9IjYsMiIgRm9udFNpemU9IjEwIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDxCdXR0'
    'b24gTmFtZT0iYnRuQ29weUxvZyIgQ29udGVudD0i8J+TiyBDb3B5IiBQYWRkaW5nPSI2LDIiIEZvbnRTaXplPSIxMCIvPgogICAg'
    'ICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBPcmllbnRhdGlvbj0i'
    'SG9yaXpvbnRhbCIgVmVydGljYWxBbGlnbm1lbnQ9IkNlbnRlciI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sg'
    'VGV4dD0iVEVSTUlOQUwgTE9HIiBGb250V2VpZ2h0PSJCb2xkIiBGb250U2l6ZT0iMTEiIEZvcmVncm91bmQ9IiMwMGI0ZDgiIE1h'
    'cmdpbj0iMCwwLDEwLDAiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBOYW1lPSJ0eHRTdWJTdGF0dXMiIFRl'
    'eHQ9IlJlYWR5LiIgRm9udFNpemU9IjEwLjUiIEZvcmVncm91bmQ9IiM5NGEzYjgiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIi'
    'Lz4KICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICA8L0RvY2tQYW5lbD4KCiAgICAgICAg'
    'ICAgICAgICA8IS0tIFN1Yi1UYXNrIFByb2dyZXNzIEJhciAoZS5nLiBESVNNL1NGQyAlKSAtLT4KICAgICAgICAgICAgICAgIDxQ'
    'cm9ncmVzc0JhciBHcmlkLlJvdz0iMSIgTmFtZT0icGJTdWJUYXNrIiBIZWlnaHQ9IjMiIE1pbmltdW09IjAiIE1heGltdW09IjEw'
    'MCIgVmFsdWU9IjAiIEZvcmVncm91bmQ9IiMxMGI5ODEiIEJhY2tncm91bmQ9IiMxZTIwMjYiIEJvcmRlclRoaWNrbmVzcz0iMCIg'
    'TWFyZ2luPSIwLDAsMCw0Ii8+CgogICAgICAgICAgICAgICAgPCEtLSBMb2cgVGV4dCBBcmVhIC0tPgogICAgICAgICAgICAgICAg'
    'PFRleHRCb3ggR3JpZC5Sb3c9IjIiIE5hbWU9InR4dENvbnNvbGVMb2ciIEJhY2tncm91bmQ9IlRyYW5zcGFyZW50IiBGb3JlZ3Jv'
    'dW5kPSIjNmVlN2I3IiBGb250RmFtaWx5PSJDb25zb2xhcyIgRm9udFNpemU9IjExIgogICAgICAgICAgICAgICAgICAgICAgICAg'
    'Qm9yZGVyVGhpY2tuZXNzPSIwIiBJc1JlYWRPbmx5PSJUcnVlIiBWZXJ0aWNhbFNjcm9sbEJhclZpc2liaWxpdHk9IkF1dG8iIEhv'
    'cml6b250YWxTY3JvbGxCYXJWaXNpYmlsaXR5PSJBdXRvIiBUZXh0V3JhcHBpbmc9IldyYXAiCiAgICAgICAgICAgICAgICAgICAg'
    'ICAgICBUZXh0PSJSZWFkeS4gU2VsZWN0IGRlc2lyZWQgb3B0aW1pemF0aW9uIG9wdGlvbnMgYW5kIGNsaWNrIFNUQVJUIE9QVElN'
    'SVpBVElPTi4iLz4KICAgICAgICAgICAgPC9HcmlkPgogICAgICAgIDwvQm9yZGVyPgoKICAgICAgICA8IS0tIEJvdHRvbSBBY3Rp'
    'b24gQmFyIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9IjQiIE1hcmdpbj0iMCw4LDAsMCI+CiAgICAgICAgICAgIDxEb2Nr'
    'UGFuZWwgTGFzdENoaWxkRmlsbD0iVHJ1ZSI+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBEb2NrUGFuZWwuRG9jaz0iUmln'
    'aHQiIE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIiBWZXJ0aWNhbEFsaWdubWVudD0iQ2VudGVyIj4KICAgICAgICAgICAgICAgICAg'
    'ICA8QnV0dG9uIE5hbWU9ImJ0bkV4cG9ydExvZyIgQ29udGVudD0i8J+SviBFeHBvcnQgTG9nIiBNYXJnaW49IjAsMCw2LDAiIFBh'
    'ZGRpbmc9IjEyLDYiLz4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blNraXBCb3R0b20iIENvbnRlbnQ9IuKP'
    'rSBTS0lQIFNURVAiIEJhY2tncm91bmQ9IiNkOTc3MDYiIEJvcmRlckJydXNoPSIjZjU5ZTBiIiBGb3JlZ3JvdW5kPSIjZmZmZmZm'
    'IiBGb250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNCw2IiBNYXJnaW49IjAsMCw2LDAiIEZvbnRTaXplPSIxMiIgSXNFbmFibGVk'
    'PSJGYWxzZSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuU3RhcnRCb3R0b20iIENvbnRlbnQ9IvCfmoAg'
    '0J7Qn9Ci0JjQnNCY0JfQmNCg0J7QktCQ0KLQrCIgQmFja2dyb3VuZD0iIzAwNzdiNiIgQm9yZGVyQnJ1c2g9IiMwMDk2YzciIEZv'
    'cmVncm91bmQ9IiNmZmZmZmYiIEZvbnRXZWlnaHQ9IkJvbGQiIFBhZGRpbmc9IjE2LDYiIE1hcmdpbj0iMCwwLDYsMCIgRm9udFNp'
    'emU9IjEyIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5SZWJvb3RCb3R0b20iIENvbnRlbnQ9IuKaoSBS'
    'RUJPT1QiIEJhY2tncm91bmQ9IiNkYzI2MjYiIEJvcmRlckJydXNoPSIjZmY0ZDRmIiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBGb250'
    'V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNiw2IiBNYXJnaW49IjAsMCw2LDAiIEZvbnRTaXplPSIxMiIgVmlzaWJpbGl0eT0iVmlz'
    'aWJsZSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuRXhpdEJvdHRvbSIgQ29udGVudD0iRXhpdCIgTWFy'
    'Z2luPSIwLDAsMCwwIiBQYWRkaW5nPSIxMiw2Ii8+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAg'
    'ICA8U3RhY2tQYW5lbCBPcmllbnRhdGlvbj0iVmVydGljYWwiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiIE1hcmdpbj0iMCww'
    'LDEyLDAiPgogICAgICAgICAgICAgICAgICAgIDxQcm9ncmVzc0JhciBOYW1lPSJwYlByb2dyZXNzIiBIZWlnaHQ9IjgiIE1pbmlt'
    'dW09IjAiIE1heGltdW09IjEwMCIgVmFsdWU9IjAiIEZvcmVncm91bmQ9IiMwMGI0ZDgiIEJhY2tncm91bmQ9IiMyNTI4MmUiIEJv'
    'cmRlclRoaWNrbmVzcz0iMCIgTWFyZ2luPSIwLDAsMCw0Ii8+CiAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBOYW1lPSJ0'
    'eHRTdGF0dXMiIFRleHQ9IlJlYWR5LiAxMTAgT3B0aW1pemF0aW9uIE1vZHVsZXMgQWN0aXZlLiIgRm9yZWdyb3VuZD0iIzk0OWJh'
    'NCIgRm9udFNpemU9IjExIi8+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgog'
    'ICAgICAgIDwvQm9yZGVyPgogICAgPC9HcmlkPgo8L1dpbmRvdz4='
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

    "chk_edge_prelaunch", "chk_edge_first_run", "chk_edge_unpin",

    "chk_reloc_documents", "chk_reloc_desktop", "chk_ui_widgets", "chk_ui_teams_chat", "chk_ui_copilot", "chk_ui_recall",

    "chk_ui_start_ads", "chk_ui_explorer_ads", "chk_ui_welcome_screen", "chk_ui_lockscreen_clean", "chk_ui_color_accent_theme", "chk_ui_mouse_inverted_large", "chk_ui_classic_context",

    "chk_ui_hide_search", "chk_ui_hide_taskview", "chk_ui_show_all_tray_icons",

    "chk_ui_never_combine_taskbar", "chk_ui_show_this_pc", "chk_ui_clock_24h_seconds", "chk_ui_region_time_czech", "chk_ui_lang_keyboards", "chk_ui_regional_date_format",

    "chk_tb_small_icons", "chk_tb_lock", "chk_tb_hide_action_center", "chk_tb_hide_people",

    "chk_exp_open_this_pc", "chk_ui_folder_view_list_sort_type", "chk_exp_hide_user_folders", "chk_exp_no_shortcut_suffix",

    "chk_exp_hide_quick_access_recent", "chk_exp_show_full_path", "chk_exp_separate_process",

    "chk_exp_hide_nav_libraries", "chk_desktop_show_user_folder",

    "chk_ctx_cleanup_bloat", "chk_ctx_winrar_email",

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

    "chk_clean_user_temp", "chk_clean_win_temp", "chk_clean_soft_dist", "chk_clean_thumb_cache",

    "chk_clean_shaders_dns", "chk_clean_event_logs", "chk_clean_recycle_bin", "chk_clean_cleanmgr",

    "chk_deep_dism_repair", "chk_deep_dism_resetbase", "chk_deep_sfc_compact"

)

$controls = @{}

foreach ($name in $chkNames) {

    $ctrl = $window.FindName($name)

    if ($ctrl) { $controls[$name] = $ctrl }

}

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
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Select All (Max Clean)" "INFO"

})

$btnDeselectAll.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $false }

    Log-Message "Preset applied: Deselect All" "INFO"

})

$btnPresetOffice.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_cloud_onedrive"].IsChecked = $false

    $controls["chk_app_office_stub"].IsChecked = $false

    $controls["chk_app_phone"].IsChecked = $false

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

    if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
    if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Office (OneDrive, Phone Link and Office preserved)" "INFO"

})

$btnPresetGaming.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_app_xbox"].IsChecked = $false
    if ($controls["chk_app_gamebar_disable"]) { $controls["chk_app_gamebar_disable"].IsChecked = $false }

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

    if ($controls["chk_reloc_documents"]) { $controls["chk_reloc_documents"].IsChecked = $false }
    if ($controls["chk_reloc_desktop"]) { $controls["chk_reloc_desktop"].IsChecked = $false }
    $controls["chk_deep_dism_repair"].IsChecked = $false

    $controls["chk_deep_dism_resetbase"].IsChecked = $false

    $controls["chk_deep_sfc_compact"].IsChecked = $false

    Log-Message "Preset applied: Gaming (Xbox app and GameBar preserved)" "INFO"

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
    $res = [System.Windows.MessageBox]::Show($confirmMsg, "GIN-Win-Optimizer v038 [VladiMIR + AI]", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Log-Message "System restart initiated by user. Restarting in 2 seconds..." "WARN"
        Start-Process shutdown.exe -ArgumentList "/r /t 2 /c `"GIN-Win-Optimizer: Reboot requested by user`""
    }
}
if ($btnRebootTop)    { $btnRebootTop.Add_Click($rebootAction) }
if ($btnRebootBottom) { $btnRebootBottom.Add_Click($rebootAction) }

$btnClearLog.Add_Click({

    $txtConsoleLog.Text = ""

    Log-Message "Terminal log cleared." "INFO"

})

$btnCopyLog.Add_Click({

    [System.Windows.Clipboard]::SetText($txtConsoleLog.Text)

    Log-Message "Log copied to clipboard." "SUCCESS"

})

$btnExportLog.Add_Click({

    $desktopPath = [Environment]::GetFolderPath("Desktop")

    if (Test-Path "D:\MEGA\DOCS\desktop") { $desktopPath = "D:\MEGA\DOCS\desktop" }

    $logFile = Join-Path $desktopPath ("Optimizer_Log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

    $txtConsoleLog.Text | Out-File -FilePath $logFile -Encoding UTF8

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

        $actions += @{ Name = "Disable Cortana Assistant"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value 0 -Type DWord -ErrorAction SilentlyContinue

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

        $actions += @{ Name = "Silent UAC for Administrators"; Script = {

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -ErrorAction SilentlyContinue

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
                cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
            }
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
            New-Item -Path "HKCU:\Control Panel\Desktop" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PreferredUILanguages" -Value @("en-US") -Type MultiString -Force -ErrorAction SilentlyContinue
            Log-Message "Preferred keyboards & English (US) default input method applied." "SUCCESS"
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

        }}

    }

    if ($controls["chk_ctx_winrar_email"].IsChecked) {

        $actions += @{ Name = "WinRAR: Hide 'Compress & Email' Clutter"; Script = {

            New-Item -Path "HKCU:\Software\WinRAR\Interface" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\WinRAR\Interface" -Name "ContextMenuEmail" -Value 0 -Type DWord -ErrorAction SilentlyContinue

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
                cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
            }

            # 3. Permanently DISABLE update services (Start = 4 - Disabled)
            $updateSvcs = @("wuauserv", "UsoSvc", "WaaSMedicSvc", "dosvc")
            foreach ($s in $updateSvcs) {
                cmd.exe /c "sc.exe config $s start= disabled & sc.exe stop $s" 2>$null | Out-Null
                cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f /reg:64" 2>$null | Out-Null
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

        $actions += @{ Name = "Remove Microsoft 365 Stub"; Script = {

            Get-AppxPackage -AllUsers *MicrosoftOfficeHub* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*MicrosoftOfficeHub*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

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

        $actions += @{ Name = "Disable LastAccess & Trigger SSD TRIM"; Script = {

            fsutil.exe behavior set disablelastaccess 1 2>$null | Out-Null

            fsutil.exe behavior set disable8dot3 1 2>$null | Out-Null

            Log-Message "Running SSD TRIM on drive C:\..." "INFO"

            Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue

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

                # 3. Dynamic "Elastic" Pagefile Logic:
                # Base initial & max targets based on physical RAM
                if ($ramMB -le 4096) {
                    $baseInit = 1536
                    $baseMax  = 4096
                } elseif ($ramMB -le 8192) {
                    $baseInit = 2048
                    $baseMax  = 4096
                } elseif ($ramMB -le 16384) {
                    $baseInit = 2048
                    $baseMax  = 6144
                } else {
                    # 32 GB or more RAM
                    $baseInit = 2048
                    $baseMax  = 4096
                }

                # 4. Strict Free Space Guard for Disk C:
                # Never consume more than 35% of free space, and guarantee at least 3 GB remains free
                $safeDiskLimit = [math]::Max(1024, [math]::Floor($effectiveFreeMB * 0.35))
                $safeMinRemain = [math]::Max(1024, $effectiveFreeMB - 3072)
                $maxAllowedByDisk = [math]::Min($safeDiskLimit, $safeMinRemain)

                # Final Maximum Size: bounded by disk headroom
                $calcMax = [math]::Min($baseMax, $maxAllowedByDisk)
                if ($calcMax -lt 1024) { $calcMax = 1024 }

                # Final Initial Size: bounded by half of max, minimum 512-1024 MB
                $calcInit = [math]::Min($baseInit, [math]::Max(512, [math]::Floor($calcMax / 2)))
                if ($calcInit -gt $calcMax) { $calcInit = $calcMax }

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

    # Ensure LAN Network Discovery, Printing, Accounting Database & SMB Services are always running
     += @{ Name = "Ensure LAN Discovery, Printing, SMB & Accounting Services (FDResPub, fdPHost, Lanman, Spooler, NexusDB)"; Script = {
        Set-Service -Name "FDResPub" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "FDResPub" -ErrorAction SilentlyContinue
        Set-Service -Name "fdPHost" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "fdPHost" -ErrorAction SilentlyContinue
        Set-Service -Name "LanmanWorkstation" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "LanmanWorkstation" -ErrorAction SilentlyContinue
        Set-Service -Name "LanmanServer" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "LanmanServer" -ErrorAction SilentlyContinue
        Set-Service -Name "lmhosts" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "lmhosts" -ErrorAction SilentlyContinue
        Set-Service -Name "Dnscache" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "Dnscache" -ErrorAction SilentlyContinue
        Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
        if (Get-Service -Name "FSServer412Service" -ErrorAction SilentlyContinue) {
            Set-Service -Name "FSServer412Service" -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name "FSServer412Service" -ErrorAction SilentlyContinue
        }
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Log-Message "LAN Network Discovery, Printing, SMB & Accounting Services active." "SUCCESS"
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

    Log-Message "STARTING GIN-WIN-OPTIMIZER ENGINE v036. Total tasks selected: $total" "INFO"

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
    foreach ($cmd in $finalLockCmds) {
        cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
    }
    foreach ($s in @("wuauserv", "UsoSvc", "WaaSMedicSvc", "dosvc")) {
        cmd.exe /c "sc.exe config $s start= disabled & sc.exe stop $s" 2>$null | Out-Null
        cmd.exe /c "reg.exe add ""HKLM\SYSTEM\CurrentControlSet\Services\$s"" /v ""Start"" /t REG_DWORD /d 4 /f /reg:64" 2>$null | Out-Null
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
        foreach ($cmd in $finalLockCmds) {
            cmd.exe /c "reg.exe $cmd" 2>$null | Out-Null
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

    # Display clear completion dialog with task count; log and all results remain visible in the main window

    $completeMsg = switch ($global:currentLang) {
            "en" { "Optimization completed successfully!`n`nTasks executed: $total of $total`n`nAll results and status of each task are preserved in the Terminal Log below.`n`nYou can click '⚡ REBOOT' on the panel whenever you are ready to restart your PC." }
            "cs" { "Optimalizace byla úspěšně dokončena!`n`nProvedeno úloh: $total z $total`n`nVšechny výsledky a stav každé úlohy jsou zachovány v protokolu terminálu níže.`n`nAž budete připraveni restartovat systém, klikněte na tlačítko '⚡ REBOOT' na panelu." }
            "ru" { "Глубокая оптимизация Windows успешно завершена!`n`nВыполнено задач: $total из $total`n`nВсе подробные результаты и статус каждой операции сохранены в окне Терминала ниже.`n`nКогда будете готовы перезагрузить систему, нажмите яркую кнопку «⚡ REBOOT / Перезагрузка» на панели." }
        }
        [System.Windows.MessageBox]::Show($completeMsg, "GIN-Win-Optimizer v038 [VladiMIR + AI]", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

# Wire Start Buttons

$btnStartTop.Add_Click($executeOptimization)

$btnStartBottom.Add_Click($executeOptimization)

# Show UI Dialog with robust exception guard

try {

    $window.ShowDialog() | Out-Null

} catch {

    [System.Windows.MessageBox]::Show("Unexpected Error: " + $_.Exception.ToString(), "GIN-Win-Optimizer v038 Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)

}


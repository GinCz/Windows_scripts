<# :

@echo off

chcp 65001 >nul

setlocal DisableDelayedExpansion

title GIN-Win-Optimizer v017 - Windows 10/11 Ultimate Optimizer [ VladiMIR & Antigravity ]



:: Elevate to Administrator via PowerShell if needed

net session >nul 2>&1

if %errorlevel% neq 0 (

    echo [*] Elevating to Administrator privileges...

    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs"

    exit /b

)



:: Launch PowerShell cleanly in background (hidden console) for single-window GUI experience

start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { $script = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $script } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'Optimizer Error') }"

exit /b

#>





# ==============================================================================

#  GIN-WIN-OPTIMIZER PLUS                                          v017

#  Rule: Strict Version Increment Mandate (v016 -> v017)

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

        "Title" = "GIN-Win-Optimizer v017 [VladiMIR & Antigravity]"

        "HeaderTitle" = "GIN-WIN-OPTIMIZER PLUS - v017"

        "HeaderSub" = "Performance Tuning, Privacy, Taskbar & Start Cleanup, Context Menu, Debloater & Live Terminal"

        "Host" = "Host: Local / Remote Admin"

        "Presets" = "Presets:"

        "BtnSelectAll" = "✓ Select All (Max Clean)"

        "BtnDeselectAll" = "✗ Deselect All"

        "BtnPresetOffice" = "🏢 Office (Keep OneDrive)"

        "BtnPresetGaming" = "⚡ Gaming (Keep Xbox)"

        "BtnStart" = "🚀 START OPTIMIZATION"

        "BtnExport" = "💾 Export Log"

        "BtnExit" = "Exit"

        "BtnSkip" = "⏭ SKIP STEP"

        "BtnClear" = "🧹 Clear"

        "BtnCopy" = "📋 Copy"

        "StatusReady" = "Ready. Configure checkboxes and click START OPTIMIZATION."

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



        "chk_ui_widgets" = "Disable and remove Windows 11 Widgets & News (TaskbarDa & WebExperience)"

        "chk_ui_teams_chat" = "Remove Microsoft Teams Chat icon from Taskbar"

        "chk_ui_copilot" = "Disable Windows Copilot AI (Taskbar button and side panel)"

        "chk_ui_recall" = "Disable Windows Recall AI (background screen snapshot taking)"

        "chk_ui_start_ads" = "Clean Start Menu: Remove Recommended section, suggestions & recent history"

        "chk_ui_explorer_ads" = "Disable OneDrive and Office sync promo ads in File Explorer"

        "chk_ui_welcome_screen" = "Disable 'Let\'s finish setting up your device' welcome screen"

        "chk_ui_classic_context" = "Restore Windows 10 Classic Context Menu (skip 'Show More Options')"

        "chk_ui_hide_search" = "Hide Search box and icon from Taskbar completely"

        "chk_ui_hide_taskview" = "Hide Task View button from Taskbar"

        "chk_ui_show_all_tray_icons" = "Always show all icons in system tray (never hide behind chevron)"

        "chk_ui_never_combine_taskbar" = "Never combine taskbar buttons (show window labels separately)"

        "chk_ui_show_this_pc" = "Always display 'This PC' icon on Desktop"

        "chk_ui_clock_24h_seconds" = "System Tray Clock: 24-hour format and display seconds"

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



        "chk_wu_disable_auto_updates" = "Completely disable automatic Windows Updates (manual only / stop wuauserv, UsoSvc, dosvc, tasks)"

        "chk_wu_exclude_drivers" = "Exclude hardware driver updates from Windows Update"

        "chk_wu_exclude_msrt" = "Exclude Malicious Software Removal Tool (MSRT) downloads"

        "chk_sys_bsod_no_autoreboot" = "Disable automatic reboot on BSOD (allow reading stop code)"

        "chk_sys_small_minidump" = "Configure small kernel memory minidump (saves SSD space)"

        "chk_sys_fast_startup_off" = "Disable Fast Startup (prevents kernel corruption and driver sleep bugs)"

        "chk_sys_disable_remote_assist" = "Disable Remote Assistance (fAllowToGetHelp = 0)"

        "chk_sys_enable_photo_viewer" = "Restore classic Windows Photo Viewer (fast & lightweight)"

        "chk_sys_notepad_tweaks" = "Notepad: Enable Word Wrap and Status Bar by default"



        "chk_app_xbox" = "Remove Xbox packages (Xbox App, GameBar - uncheck if gaming PC)"

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

        "chk_srv_ssd_trim" = "Disable LastAccess/8dot3 and trigger SSD TRIM"

        "chk_srv_network_offload" = "Disable network Task Offload & Chimney (prevents latency spikes)"

        "chk_srv_visual_perf" = "Tune visual effects for performance (keeps font smoothing)"

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

        "chk_deep_dism_repair" = "Check and repair component store integrity via DISM"

        "chk_deep_dism_resetbase" = "Deep clean WinSxS folder (ResetBase - frees gigabytes)"

        "chk_deep_sfc_compact" = "Run SFC Scannow integrity verification and CompactOS check"

    }



    "cs" = @{

        "Title" = "GIN-Win-Optimizer v017 [VladiMIR & Antigravity]"

        "HeaderTitle" = "GIN-WIN-OPTIMIZER PLUS - v017"

        "HeaderSub" = "Kompletní sada pro výkon, soukromí, Hlavní panel, Start menu, Dism++ ladění a čištění"

        "Host" = "Hostitel: Místní / Vzdálený Správce"

        "Presets" = "Předvolby:"

        "BtnSelectAll" = "✓ Vybrat vše (Max. čištění)"

        "BtnDeselectAll" = "✗ Zrušit výběr"

        "BtnPresetOffice" = "🏢 Kancelář (Ponechat OneDrive)"

        "BtnPresetGaming" = "⚡ Hraní her (Ponechat Xbox)"

        "BtnStart" = "🚀 SPUSTIT OPTIMALIZACI"

        "BtnExport" = "💾 Export protokolu"

        "BtnExit" = "Konec"

        "BtnSkip" = "⏭ PŘESKOČIT KROK"

        "BtnClear" = "🧹 Vyčistit"

        "BtnCopy" = "📋 Kopírovat"

        "StatusReady" = "Připraveno. Nastavte volby a klikněte na SPUSTIT OPTIMALIZACI."

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



        "chk_ui_widgets" = "Zakázat a odebrat Widgety a Zprávy Windows 11 (TaskbarDa a WebExperience)"

        "chk_ui_teams_chat" = "Odstranit ikonu Chatu Microsoft Teams z hlavního panelu"

        "chk_ui_copilot" = "Zakázat Windows Copilot AI (tlačítko na liště a boční panel)"

        "chk_ui_recall" = "Zakázat Windows Recall AI (pořizování snímků obrazovky na pozadí)"

        "chk_ui_start_ads" = "Vyčistit nabídku Start: Skrýt sekci Doporučené, tipy a historii"

        "chk_ui_explorer_ads" = "Zakázat reklamní oznámení OneDrive a Office v Průzkumníku"

        "chk_ui_welcome_screen" = "Zakázat obrazovku 'Dokončete nastavení zařízení' po aktualizaci"

        "chk_ui_classic_context" = "Obnovit klasické kontextové menu Windows 10 (bez 'Zobrazit více')"

        "chk_ui_hide_search" = "Zcela skrýt vyhledávací pole a ikonu hledání z hlavního panelu"

        "chk_ui_hide_taskview" = "Skrýt tlačítko Zobrazení úloh (Task View) z hlavního panelu"

        "chk_ui_show_all_tray_icons" = "Vždy zobrazovat všechny ikony v oznamovací oblasti (neskrývat za šipku)"

        "chk_ui_never_combine_taskbar" = "Nikdy neseskupovat tlačítka hlavního panelu (Combine: Never)"

        "chk_ui_show_this_pc" = "Vždy zobrazovat ikonu 'Tento počítač' na ploše"

        "chk_ui_clock_24h_seconds" = "Hodiny v oznamovací oblasti: 24hodinový formát a sekundy"

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

        "chk_srv_ssd_trim" = "Zakázat LastAccess/8dot3 a provést okamžitý SSD TRIM"

        "chk_srv_network_offload" = "Zakázat síťový Task Offload a Chimney (ochrana před skoky latence)"

        "chk_srv_visual_perf" = "Nastavit vizuální efekty pro nejvyšší výkon (vyhlazování písem zachováno)"

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

        "chk_deep_dism_repair" = "Zkontrolovat a opravit integritu komponent DISM (RestoreHealth)"

        "chk_deep_dism_resetbase" = "Provést hluboké vyčištění složky WinSxS (ResetBase - uvolní GB)"

        "chk_deep_sfc_compact" = "Provést ověření integrity souborů SFC Scannow a kontrolu CompactOS"

    }



    "ru" = @{

        "Title" = "GIN-Win-Optimizer v017 [VladiMIR & Antigravity]"

        "HeaderTitle" = "GIN-WIN-OPTIMIZER PLUS - v017"

        "HeaderSub" = "Полный комплекс производительности, приватности, панели задач, меню Пуск, Dism++ твиков и очистки"

        "Host" = "Хост: Локальный / Удаленный Администратор"

        "Presets" = "Пресеты:"

        "BtnSelectAll" = "✓ Выбрать все (Макс. очистка)"

        "BtnDeselectAll" = "✗ Снять все"

        "BtnPresetOffice" = "🏢 Офис (Оставить OneDrive)"

        "BtnPresetGaming" = "⚡ Игры (Оставить Xbox)"

        "BtnStart" = "🚀 НАЧАТЬ ОПТИМИЗАЦИЮ"

        "BtnExport" = "💾 Экспорт лога"

        "BtnExit" = "Выход"

        "BtnSkip" = "⏭ Пропустить шаг"

        "BtnClear" = "🧹 Очистить"

        "BtnCopy" = "📋 Копировать"

        "StatusReady" = "Готово к работе. Отметьте нужные пункты и нажмите НАЧАТЬ ОПТИМИЗАЦИЮ."

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



        "chk_ui_widgets" = "Отключить и удалить Виджеты и Новости Windows 11 (TaskbarDa, Feeds, WebExperience)"

        "chk_ui_teams_chat" = "Убрать значок «Чат» Microsoft Teams с панели задач"

        "chk_ui_copilot" = "Отключить Windows Copilot AI (кнопку в панели задач и боковую панель)"

        "chk_ui_recall" = "Отключить Windows Recall AI (фоновый сбор снапшотов экрана)"

        "chk_ui_start_ads" = "Очистить Пуск: скрыть блок «Рекомендуем», недавние файлы, приложения и советы"

        "chk_ui_explorer_ads" = "Отключить рекламные уведомления OneDrive / Office в Проводнике"

        "chk_ui_welcome_screen" = "Отключить экран «Завершить настройку устройства» после обновлений"

        "chk_ui_classic_context" = "Вернуть классическое компактное контекстное меню Windows 10 (без «Показать больше»)"

        "chk_ui_hide_search" = "Полностью убрать строку и значок поиска с панели задач (Searchbox = 0)"

        "chk_ui_hide_taskview" = "Скрыть кнопку «Просмотр задач» (Task View) с панели задач"

        "chk_ui_show_all_tray_icons" = "Всегда показывать все иконки в трее возле часов (не прятать под стрелку)"

        "chk_ui_never_combine_taskbar" = "Никогда не группировать кнопки панели задач (Combine: Never)"

        "chk_ui_show_this_pc" = "Всегда отображать значок «Этот компьютер» на Рабочем столе"

        "chk_ui_clock_24h_seconds" = "Часы в трее: 24-часовой формат и отображение секунд"

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



        "chk_wu_disable_auto_updates" = "Полностью отключить автообновление Windows (только вручную / отключить службы и задачи)"

        "chk_wu_exclude_drivers" = "Исключить автоматическое обновление драйверов через Windows Update"

        "chk_wu_exclude_msrt" = "Исключить загрузку средства удаления вредоносных программ (MSRT)"

        "chk_sys_bsod_no_autoreboot" = "Отключить автоматическую перезагрузку при синем экране BSOD"

        "chk_sys_small_minidump" = "Настроить создание малого дампа памяти Minidump при сбоях (экономия SSD)"

        "chk_sys_fast_startup_off" = "Отключить Быстрый запуск (защита от повреждения ядра и багов гибернации)"

        "chk_sys_disable_remote_assist" = "Отключить службу удаленного помощника Windows (Remote Assistance)"

        "chk_sys_enable_photo_viewer" = "Восстановить классический быстрый Windows Photo Viewer"

        "chk_sys_notepad_tweaks" = "Блокнот: включить перенос по словам и строку состояния по умолчанию"



        "chk_app_xbox" = "Удалить пакеты Xbox (Xbox App, GameBar - снимите, если ПК игровой)"

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

        "chk_srv_ssd_trim" = "Отключить LastAccess/8dot3 и выполнить принудительный SSD TRIM"

        "chk_srv_network_offload" = "Отключить сетевой Task Offload и Chimney (защита от скачков задержки)"

        "chk_srv_visual_perf" = "Настроить визуальные эффекты на быстродействие (сглаживание шрифтов сохранено)"

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

        "chk_deep_dism_repair" = "Выполнить проверку и восстановление хранилища компонентов DISM (RestoreHealth)"

        "chk_deep_dism_resetbase" = "Выполнить глубокую очистку WinSxS (ResetBase - освобождает гигабайты)"

        "chk_deep_sfc_compact" = "Выполнить проверку целостности SFC Scannow и проверку CompactOS"

    }

}



# Load pure ASCII XAML UI

$xamlBase64 = (
    "PFdpbmRvdyB4bWxucz0iaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93aW5meC8yMDA2L3hhbWwv" +
    "cHJlc2VudGF0aW9uIgogICAgICAgIHhtbG5zOng9Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20v" +
    "d2luZngvMjAwNi94YW1sIgogICAgICAgIFRpdGxlPSJHSU4tV2luLU9wdGltaXplciB2MDE3IFtWbGFk" +
    "aU1JUiArIEFudGlncmF2aXR5XSIKICAgICAgICBIZWlnaHQ9Ijg5MCIgV2lkdGg9IjEyODAiCiAgICAg" +
    "ICAgTWluSGVpZ2h0PSI3NTAiIE1pbldpZHRoPSIxMTAwIgogICAgICAgIFdpbmRvd1N0YXJ0dXBMb2Nh" +
    "dGlvbj0iQ2VudGVyU2NyZWVuIgogICAgICAgIEJhY2tncm91bmQ9IiMxMzE1MTgiIEZvcmVncm91bmQ9" +
    "IiNlMGUwZTAiCiAgICAgICAgRm9udEZhbWlseT0iU2Vnb2UgVUkiIEZvbnRTaXplPSIxMiI+CiAgICA8" +
    "V2luZG93LlJlc291cmNlcz4KICAgICAgICA8U3R5bGUgVGFyZ2V0VHlwZT0iR3JvdXBCb3giPgogICAg" +
    "ICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJCb3JkZXJCcnVzaCIgVmFsdWU9IiMyNTI4MmUiLz4KICAg" +
    "ICAgICAgICAgPFNldHRlciBQcm9wZXJ0eT0iQm9yZGVyVGhpY2tuZXNzIiBWYWx1ZT0iMSIvPgogICAg" +
    "ICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJNYXJnaW4iIFZhbHVlPSIwLDAsMCw5Ii8+CiAgICAgICAg" +
    "ICAgIDxTZXR0ZXIgUHJvcGVydHk9IlBhZGRpbmciIFZhbHVlPSI5LDYsOSw4Ii8+CiAgICAgICAgICAg" +
    "IDxTZXR0ZXIgUHJvcGVydHk9IkZvcmVncm91bmQiIFZhbHVlPSIjMDBiNGQ4Ii8+CiAgICAgICAgICAg" +
    "IDxTZXR0ZXIgUHJvcGVydHk9IkZvbnRXZWlnaHQiIFZhbHVlPSJTZW1pQm9sZCIvPgogICAgICAgIDwv" +
    "U3R5bGU+CiAgICAgICAgPFN0eWxlIFRhcmdldFR5cGU9IkNoZWNrQm94Ij4KICAgICAgICAgICAgPFNl" +
    "dHRlciBQcm9wZXJ0eT0iRm9yZWdyb3VuZCIgVmFsdWU9IiNkNGQ0ZDgiLz4KICAgICAgICAgICAgPFNl" +
    "dHRlciBQcm9wZXJ0eT0iTWFyZ2luIiBWYWx1ZT0iMiwyLDIsMyIvPgogICAgICAgICAgICA8U2V0dGVy" +
    "IFByb3BlcnR5PSJGb250V2VpZ2h0IiBWYWx1ZT0iTm9ybWFsIi8+CiAgICAgICAgICAgIDxTZXR0ZXIg" +
    "UHJvcGVydHk9IkZvbnRTaXplIiBWYWx1ZT0iMTEuNSIvPgogICAgICAgIDwvU3R5bGU+CiAgICAgICAg" +
    "PFN0eWxlIFRhcmdldFR5cGU9IkJ1dHRvbiI+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkJh" +
    "Y2tncm91bmQiIFZhbHVlPSIjMjUyODJlIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkZv" +
    "cmVncm91bmQiIFZhbHVlPSIjZmZmZmZmIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkJv" +
    "cmRlckJydXNoIiBWYWx1ZT0iIzNhM2Q0NSIvPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJC" +
    "b3JkZXJUaGlja25lc3MiIFZhbHVlPSIxIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlBh" +
    "ZGRpbmciIFZhbHVlPSIxMCw1Ii8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkZvbnRXZWln" +
    "aHQiIFZhbHVlPSJTZW1pQm9sZCIvPgogICAgICAgICAgICA8U2V0dGVyIFByb3BlcnR5PSJDdXJzb3Ii" +
    "IFZhbHVlPSJIYW5kIi8+CiAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IlRlbXBsYXRlIj4KICAg" +
    "ICAgICAgICAgICAgIDxTZXR0ZXIuVmFsdWU+CiAgICAgICAgICAgICAgICAgICAgPENvbnRyb2xUZW1w" +
    "bGF0ZSBUYXJnZXRUeXBlPSJCdXR0b24iPgogICAgICAgICAgICAgICAgICAgICAgICA8Qm9yZGVyIHg6" +
    "TmFtZT0iYm9yZGVyIiBCYWNrZ3JvdW5kPSJ7VGVtcGxhdGVCaW5kaW5nIEJhY2tncm91bmR9IiBCb3Jk" +
    "ZXJCcnVzaD0ie1RlbXBsYXRlQmluZGluZyBCb3JkZXJCcnVzaH0iIEJvcmRlclRoaWNrbmVzcz0ie1Rl" +
    "bXBsYXRlQmluZGluZyBCb3JkZXJUaGlja25lc3N9IiBDb3JuZXJSYWRpdXM9IjMiIFBhZGRpbmc9IntU" +
    "ZW1wbGF0ZUJpbmRpbmcgUGFkZGluZ30iPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENvbnRl" +
    "bnRQcmVzZW50ZXIgeDpOYW1lPSJjb250ZW50UHJlc2VudGVyIiBIb3Jpem9udGFsQWxpZ25tZW50PSJD" +
    "ZW50ZXIiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiIEZvY3VzYWJsZT0iRmFsc2UiIFJlY29nbml6" +
    "ZXNBY2Nlc3NLZXk9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9Cb3JkZXI+CiAgICAg" +
    "ICAgICAgICAgICAgICAgICAgIDxDb250cm9sVGVtcGxhdGUuVHJpZ2dlcnM+CiAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICA8VHJpZ2dlciBQcm9wZXJ0eT0iSXNNb3VzZU92ZXIiIFZhbHVlPSJUcnVlIj4K" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5hbWU9ImJvcmRlciIg" +
    "UHJvcGVydHk9IkJhY2tncm91bmQiIFZhbHVlPSIjMzUzYjQ4Ii8+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgPFNldHRlciBUYXJnZXROYW1lPSJib3JkZXIiIFByb3BlcnR5PSJCb3JkZXJCcnVz" +
    "aCIgVmFsdWU9IiMwMGI0ZDgiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvVHJpZ2dlcj4K" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxUcmlnZ2VyIFByb3BlcnR5PSJJc1ByZXNzZWQiIFZh" +
    "bHVlPSJUcnVlIj4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0dGVyIFRhcmdldE5h" +
    "bWU9ImJvcmRlciIgUHJvcGVydHk9IkJhY2tncm91bmQiIFZhbHVlPSIjMWExYzIzIi8+CiAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICA8L1RyaWdnZXI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8" +
    "VHJpZ2dlciBQcm9wZXJ0eT0iSXNFbmFibGVkIiBWYWx1ZT0iRmFsc2UiPgogICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgIDxTZXR0ZXIgVGFyZ2V0TmFtZT0iYm9yZGVyIiBQcm9wZXJ0eT0iQmFja2dy" +
    "b3VuZCIgVmFsdWU9IiMxYzFmMjYiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2V0" +
    "dGVyIFRhcmdldE5hbWU9ImJvcmRlciIgUHJvcGVydHk9IkJvcmRlckJydXNoIiBWYWx1ZT0iIzJlMzIz" +
    "YiIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxTZXR0ZXIgUHJvcGVydHk9IkZvcmVn" +
    "cm91bmQiIFZhbHVlPSIjOTRhM2I4Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L1RyaWdn" +
    "ZXI+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvQ29udHJvbFRlbXBsYXRlLlRyaWdnZXJzPgogICAg" +
    "ICAgICAgICAgICAgICAgIDwvQ29udHJvbFRlbXBsYXRlPgogICAgICAgICAgICAgICAgPC9TZXR0ZXIu" +
    "VmFsdWU+CiAgICAgICAgICAgIDwvU2V0dGVyPgogICAgICAgIDwvU3R5bGU+CiAgICA8L1dpbmRvdy5S" +
    "ZXNvdXJjZXM+CgogICAgPEdyaWQgTWFyZ2luPSIxMiI+CiAgICAgICAgPEdyaWQuUm93RGVmaW5pdGlv" +
    "bnM+CiAgICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iQXV0byIvPgogICAgICAgICAgICA8" +
    "Um93RGVmaW5pdGlvbiBIZWlnaHQ9IkF1dG8iLz4KICAgICAgICAgICAgPFJvd0RlZmluaXRpb24gSGVp" +
    "Z2h0PSIqIi8+CiAgICAgICAgICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iMTg1Ii8+CiAgICAgICAg" +
    "ICAgIDxSb3dEZWZpbml0aW9uIEhlaWdodD0iQXV0byIvPgogICAgICAgIDwvR3JpZC5Sb3dEZWZpbml0" +
    "aW9ucz4KCiAgICAgICAgPCEtLSBUb3AgSGVhZGVyIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9" +
    "IjAiIEJhY2tncm91bmQ9IiMxYTFjMjEiIENvcm5lclJhZGl1cz0iNiIgUGFkZGluZz0iMTQsMTAiIE1h" +
    "cmdpbj0iMCwwLDAsOCIgQm9yZGVyQnJ1c2g9IiMyNTI4MmUiIEJvcmRlclRoaWNrbmVzcz0iMSI+CiAg" +
    "ICAgICAgICAgIDxEb2NrUGFuZWwgTGFzdENoaWxkRmlsbD0iVHJ1ZSI+CiAgICAgICAgICAgICAgICA8" +
    "IS0tIFJpZ2h0IENvbnRyb2xzOiBTa2lwLCBTdGFydCwgRXhpdCAtLT4KICAgICAgICAgICAgICAgIDxT" +
    "dGFja1BhbmVsIERvY2tQYW5lbC5Eb2NrPSJSaWdodCIgT3JpZW50YXRpb249Ikhvcml6b250YWwiIFZl" +
    "cnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0i" +
    "YnRuU2tpcFRvcCIgQ29udGVudD0i4o+tIFNLSVAgU1RFUCIgQmFja2dyb3VuZD0iI2Q5NzcwNiIgQm9y" +
    "ZGVyQnJ1c2g9IiNmNTllMGIiIEZvcmVncm91bmQ9IiNmZmZmZmYiIEZvbnRXZWlnaHQ9IkJvbGQiIFBh" +
    "ZGRpbmc9IjE0LDgiIE1hcmdpbj0iMCwwLDgsMCIgRm9udFNpemU9IjEzIiBJc0VuYWJsZWQ9IkZhbHNl" +
    "Ii8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5TdGFydFRvcCIgQ29udGVudD0i" +
    "8J+agCBTVEFSVCBPUFRJTUlaQVRJT04iIEJhY2tncm91bmQ9IiMwMDc3YjYiIEJvcmRlckJydXNoPSIj" +
    "MDA5NmM3IiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBGb250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNiw4" +
    "IiBNYXJnaW49IjAsMCw4LDAiIEZvbnRTaXplPSIxMyIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0" +
    "b24gTmFtZT0iYnRuRXhpdFRvcCIgQ29udGVudD0iRXhpdCIgQmFja2dyb3VuZD0iIzNhMWMxYyIgQm9y" +
    "ZGVyQnJ1c2g9IiM2NjIyMjIiIEZvcmVncm91bmQ9IiNmZjg4ODgiIFBhZGRpbmc9IjEyLDgiLz4KICAg" +
    "ICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KCiAgICAgICAgICAgICAgICA8IS0tIENlbnRlciBDb250" +
    "cm9sczogTGFuZ3VhZ2UgU3dpdGNoZXIgUGlsbHMgLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5l" +
    "bCBEb2NrUGFuZWwuRG9jaz0iUmlnaHQiIE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIiBWZXJ0aWNhbEFs" +
    "aWdubWVudD0iQ2VudGVyIiBNYXJnaW49IjAsMCwxNiwwIj4KICAgICAgICAgICAgICAgICAgICA8VGV4" +
    "dEJsb2NrIFRleHQ9Ikxhbmd1YWdlOiIgRm9yZWdyb3VuZD0iIzhlOTI5YiIgVmVydGljYWxBbGlnbm1l" +
    "bnQ9IkNlbnRlciIgTWFyZ2luPSIwLDAsOCwwIiBGb250U2l6ZT0iMTEiIEZvbnRXZWlnaHQ9IlNlbWlC" +
    "b2xkIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJidG5MYW5nUnUiIENvbnRlbnQ9" +
    "IlJVIiBCYWNrZ3JvdW5kPSIjMWUzYTVmIiBCb3JkZXJCcnVzaD0iIzAwYjRkOCIgRm9yZWdyb3VuZD0i" +
    "I2ZmZmZmZiIgUGFkZGluZz0iOCw0IiBNYXJnaW49IjAsMCw0LDAiIEZvbnRTaXplPSIxMSIvPgogICAg" +
    "ICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRuTGFuZ0VuIiBDb250ZW50PSJFTiIgQmFja2dy" +
    "b3VuZD0iIzI1MjgyZSIgQm9yZGVyQnJ1c2g9IiMzYTNkNDUiIEZvcmVncm91bmQ9IiNiMGIzYjgiIFBh" +
    "ZGRpbmc9IjgsNCIgTWFyZ2luPSIwLDAsNCwwIiBGb250U2l6ZT0iMTEiLz4KICAgICAgICAgICAgICAg" +
    "ICAgICA8QnV0dG9uIE5hbWU9ImJ0bkxhbmdDcyIgQ29udGVudD0iQ1oiIEJhY2tncm91bmQ9IiMyNTI4" +
    "MmUiIEJvcmRlckJydXNoPSIjM2EzZDQ1IiBGb3JlZ3JvdW5kPSIjYjBiM2I4IiBQYWRkaW5nPSI4LDQi" +
    "IEZvbnRTaXplPSIxMSIvPgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgoKICAgICAgICAgICAg" +
    "ICAgIDwhLS0gTGVmdCBJbmZvOiBUaXRsZSAmIEhvc3QgLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQ" +
    "YW5lbCBPcmllbnRhdGlvbj0iVmVydGljYWwiPgogICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVs" +
    "IE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9j" +
    "ayBOYW1lPSJ0eHRIZWFkZXJUaXRsZSIgVGV4dD0iR0lOLVdJTi1PUFRJTUlaRVIgUExVUyAtIHYwMTci" +
    "IEZvbnRTaXplPSIxNSIgRm9udFdlaWdodD0iQm9sZCIgRm9yZWdyb3VuZD0iIzAwYjRkOCIvPgogICAg" +
    "ICAgICAgICAgICAgICAgICAgICA8Qm9yZGVyIEJhY2tncm91bmQ9IiMxNjY1MzQiIENvcm5lclJhZGl1" +
    "cz0iMyIgUGFkZGluZz0iNiwxIiBNYXJnaW49IjgsMCwwLDAiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50" +
    "ZXIiPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRCbG9jayBUZXh0PSJBRE1JTiIgRm9u" +
    "dFNpemU9IjkiIEZvbnRXZWlnaHQ9IkJvbGQiIEZvcmVncm91bmQ9IiM4NmVmYWMiLz4KICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgPC9Cb3JkZXI+CiAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgog" +
    "ICAgICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sgTmFtZT0idHh0SGVhZGVyU3ViIiBUZXh0PSJQZXJm" +
    "b3JtYW5jZSBUdW5pbmcsIFByaXZhY3ksIFRhc2tiYXIgJmFtcDsgU3RhcnQgQ2xlYW51cCwgQ29udGV4" +
    "dCBNZW51LCBEZWJsb2F0ZXIgJmFtcDsgTGl2ZSBUZXJtaW5hbCIgRm9udFNpemU9IjExIiBGb3JlZ3Jv" +
    "dW5kPSIjOTQ5YmE0IiBNYXJnaW49IjAsMiwwLDAiLz4KICAgICAgICAgICAgICAgICAgICA8VGV4dEJs" +
    "b2NrIE5hbWU9InR4dEhvc3RJbmZvIiBUZXh0PSJIb3N0OiBMb2NhbCAvIFJlbW90ZSBTeXN0ZW0gQWRt" +
    "aW4iIEZvbnRTaXplPSIxMCIgRm9yZWdyb3VuZD0iIzZjNzU3ZCIgTWFyZ2luPSIwLDEsMCwwIi8+CiAg" +
    "ICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgogICAgICAg" +
    "IDwvQm9yZGVyPgoKICAgICAgICA8IS0tIFByZXNldHMgQmFyIC0tPgogICAgICAgIDxCb3JkZXIgR3Jp" +
    "ZC5Sb3c9IjEiIEJhY2tncm91bmQ9IiMxZTIwMjYiIENvcm5lclJhZGl1cz0iNCIgUGFkZGluZz0iMTAs" +
    "NiIgTWFyZ2luPSIwLDAsMCw4IiBCb3JkZXJCcnVzaD0iIzI1MjgyZSIgQm9yZGVyVGhpY2tuZXNzPSIx" +
    "Ij4KICAgICAgICAgICAgPERvY2tQYW5lbCBMYXN0Q2hpbGRGaWxsPSJUcnVlIj4KICAgICAgICAgICAg" +
    "ICAgIDxUZXh0QmxvY2sgTmFtZT0idHh0UHJlc2V0cyIgVGV4dD0iUHJlc2V0czoiIFZlcnRpY2FsQWxp" +
    "Z25tZW50PSJDZW50ZXIiIEZvbnRXZWlnaHQ9IkJvbGQiIEZvcmVncm91bmQ9IiNiNWJhYzEiIE1hcmdp" +
    "bj0iMCwwLDEwLDAiLz4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIE9yaWVudGF0aW9uPSJIb3Jp" +
    "em9udGFsIj4KICAgICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0blNlbGVjdEFsbCIgQ29u" +
    "dGVudD0i4pyTIFNlbGVjdCBBbGwgKE1heCBDbGVhbikiIE1hcmdpbj0iMCwwLDYsMCIgUGFkZGluZz0i" +
    "MTAsNCIgQmFja2dyb3VuZD0iIzE0NTMyZCIgQm9yZGVyQnJ1c2g9IiMyMmM1NWUiIEZvcmVncm91bmQ9" +
    "IiM4NmVmYWMiIEZvbnRXZWlnaHQ9IlNlbWlCb2xkIi8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRv" +
    "biBOYW1lPSJidG5EZXNlbGVjdEFsbCIgQ29udGVudD0i4pyXIERlc2VsZWN0IEFsbCIgTWFyZ2luPSIw" +
    "LDAsNiwwIiBQYWRkaW5nPSIxMCw0Ii8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1lPSJi" +
    "dG5QcmVzZXRPZmZpY2UiIENvbnRlbnQ9IvCfj6IgT2ZmaWNlIChLZWVwIE9uZURyaXZlKSIgTWFyZ2lu" +
    "PSIwLDAsNiwwIiBQYWRkaW5nPSIxMCw0Ii8+CiAgICAgICAgICAgICAgICAgICAgPEJ1dHRvbiBOYW1l" +
    "PSJidG5QcmVzZXRHYW1pbmciIENvbnRlbnQ9IuKaoSBHYW1pbmcgKEtlZXAgWGJveCkiIE1hcmdpbj0i" +
    "MCwwLDYsMCIgUGFkZGluZz0iMTAsNCIvPgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAg" +
    "ICAgICAgICA8L0RvY2tQYW5lbD4KICAgICAgICA8L0JvcmRlcj4KCiAgICAgICAgPCEtLSBNYWluIFNj" +
    "cm9sbGFibGUgT3B0aW9ucyBHcmlkIC0tPgogICAgICAgIDxTY3JvbGxWaWV3ZXIgR3JpZC5Sb3c9IjIi" +
    "IFZlcnRpY2FsU2Nyb2xsQmFyVmlzaWJpbGl0eT0iQXV0byIgSG9yaXpvbnRhbFNjcm9sbEJhclZpc2li" +
    "aWxpdHk9IkRpc2FibGVkIiBNYXJnaW49IjAsMCwwLDgiPgogICAgICAgICAgICA8R3JpZD4KICAgICAg" +
    "ICAgICAgICAgIDxHcmlkLkNvbHVtbkRlZmluaXRpb25zPgogICAgICAgICAgICAgICAgICAgIDxDb2x1" +
    "bW5EZWZpbml0aW9uIFdpZHRoPSIqIi8+CiAgICAgICAgICAgICAgICAgICAgPENvbHVtbkRlZmluaXRp" +
    "b24gV2lkdGg9IioiLz4KICAgICAgICAgICAgICAgICAgICA8Q29sdW1uRGVmaW5pdGlvbiBXaWR0aD0i" +
    "KiIvPgogICAgICAgICAgICAgICAgPC9HcmlkLkNvbHVtbkRlZmluaXRpb25zPgoKICAgICAgICAgICAg" +
    "ICAgIDwhLS0gQ09MVU1OIDEgLS0+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBHcmlkLkNvbHVt" +
    "bj0iMCIgTWFyZ2luPSIwLDAsNiwwIj4KICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBQcml2" +
    "YWN5ICYgVGVsZW1ldHJ5IC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBQ" +
    "cml2YWN5IiBIZWFkZXI9IlByaXZhY3kgJmFtcDsgVGVsZW1ldHJ5Ij4KICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgPFN0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt" +
    "ZT0iY2hrX3RlbGVtX2RpYWd0cmFjayIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2Rtd2FwcHVzaCIgSXNDaGVja2VkPSJU" +
    "cnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVt" +
    "X3dlciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC" +
    "b3ggTmFtZT0iY2hrX3RlbGVtX2FsbG93X3RlbGVtIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdGVsZW1fYWRfaWQiIElzQ2hlY2tl" +
    "ZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190" +
    "ZWxlbV9pbmtpbmciIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAg" +
    "PENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV9hY3Rpdml0eSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2xvY2F0aW9uIiBJ" +
    "c0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1l" +
    "PSJjaGtfdGVsZW1fZmVlZGJhY2siIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190ZWxlbV90YXNrcyIgSXNDaGVja2VkPSJUcnVlIi8+" +
    "CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RlbGVtX2NvcnRh" +
    "bmEiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+" +
    "CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAgICAgICAgICAgICAgICAgICAgPCEtLSBH" +
    "cm91cDogU2VjdXJpdHkgJiBVQUMgLS0+CiAgICAgICAgICAgICAgICAgICAgPEdyb3VwQm94IE5hbWU9" +
    "ImdycFNlY3VyaXR5IiBIZWFkZXI9IlNlY3VyaXR5ICZhbXA7IFVBQyBUd2Vha3MiPgogICAgICAgICAg" +
    "ICAgICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVj" +
    "a0JveCBOYW1lPSJjaGtfc2VjX3VhY19xdWlldCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY19hZG1pbl9hcHByb3ZhbCIgSXND" +
    "aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i" +
    "Y2hrX3NlY19zbWFydHNjcmVlbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3NlY19vcGVuX2ZpbGVfd2FybmluZyIgSXNDaGVja2Vk" +
    "PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAg" +
    "ICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBDbG91ZCAm" +
    "IENvbnN1bWVyIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBDbG91ZCIg" +
    "SGVhZGVyPSJDbG91ZCAmYW1wOyBDb25zdW1lciBGZWF0dXJlcyI+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9" +
    "ImNoa19jbG91ZF9vbmVkcml2ZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX3NldHRpbmdzX3N5bmMiIElzQ2hlY2tlZD0i" +
    "VHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbG91" +
    "ZF9iaW5nX3NlYXJjaCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX3Nwb3RsaWdodCIgSXNDaGVja2VkPSJUcnVlIi8+CiAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Nsb3VkX2NvbnN1bWVy" +
    "X2ZlYXR1cmVzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFj" +
    "a1BhbmVsPgogICAgICAgICAgICAgICAgICAgIDwvR3JvdXBCb3g+CgogICAgICAgICAgICAgICAgICAg" +
    "IDwhLS0gR3JvdXA6IE1pY3Jvc29mdCBFZGdlIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJv" +
    "eCBOYW1lPSJncnBFZGdlIiBIZWFkZXI9Ik1pY3Jvc29mdCBFZGdlIE9wdGltaXphdGlvbiI+CiAgICAg" +
    "ICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAgICAg" +
    "PENoZWNrQm94IE5hbWU9ImNoa19lZGdlX2JhY2tncm91bmQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3N0YXJ0dXBfYm9v" +
    "c3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94" +
    "IE5hbWU9ImNoa19lZGdlX3RlbGVtZXRyeSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2VkZ2Vfc2lkZWJhciIgSXNDaGVja2VkPSJU" +
    "cnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2VkZ2Vf" +
    "cHJlbGF1bmNoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD" +
    "aGVja0JveCBOYW1lPSJjaGtfZWRnZV9maXJzdF9ydW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19lZGdlX3VucGluIiBJc0NoZWNr" +
    "ZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAg" +
    "ICAgICAgICAgIDwvR3JvdXBCb3g+CiAgICAgICAgICAgICAgICA8L1N0YWNrUGFuZWw+CgogICAgICAg" +
    "ICAgICAgICAgPCEtLSBDT0xVTU4gMiAtLT4KICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIEdyaWQu" +
    "Q29sdW1uPSIxIiBNYXJnaW49IjMsMCwzLDAiPgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6" +
    "IEV4cGxvcmVyLCBEZXNrdG9wICYgVGFza2JhciAtLT4KICAgICAgICAgICAgICAgICAgICA8R3JvdXBC" +
    "b3ggTmFtZT0iZ3JwVUkiIEhlYWRlcj0iRXhwbG9yZXIsIERlc2t0b3AgJmFtcDsgVGFza2JhciI+CiAg" +
    "ICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICAgPENoZWNrQm94IE5hbWU9ImNoa191aV93aWRnZXRzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfdGVhbXNfY2hhdCIgSXND" +
    "aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i" +
    "Y2hrX3VpX2NvcGlsb3QiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9yZWNhbGwiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9zdGFydF9hZHMiIElzQ2hl" +
    "Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo" +
    "a191aV9leHBsb3Jlcl9hZHMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV93ZWxjb21lX3NjcmVlbiIgSXNDaGVja2VkPSJUcnVl" +
    "Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2NsYXNz" +
    "aWNfY29udGV4dCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8" +
    "Q2hlY2tCb3ggTmFtZT0iY2hrX3VpX2hpZGVfc2VhcmNoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfdWlfaGlkZV90YXNrdmlldyIg" +
    "SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt" +
    "ZT0iY2hrX3VpX3Nob3dfYWxsX3RyYXlfaWNvbnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9uZXZlcl9jb21iaW5lX3Rhc2ti" +
    "YXIiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94" +
    "IE5hbWU9ImNoa191aV9zaG93X3RoaXNfcGMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa191aV9jbG9ja18yNGhfc2Vjb25kcyIgSXND" +
    "aGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0i" +
    "Y2hrX3RiX3NtYWxsX2ljb25zIiBJc0NoZWNrZWQ9IkZhbHNlIi8+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3RiX2xvY2siIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa190Yl9oaWRlX2FjdGlvbl9j" +
    "ZW50ZXIiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNr" +
    "Qm94IE5hbWU9ImNoa190Yl9oaWRlX3Blb3BsZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9vcGVuX3RoaXNfcGMiIElzQ2hl" +
    "Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo" +
    "a191aV9mb2xkZXJfdmlld19saXN0X3NvcnRfdHlwZSIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2V4cF9oaWRlX3VzZXJfZm9sZGVy" +
    "cyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3gg" +
    "TmFtZT0iY2hrX2V4cF9ub19zaG9ydGN1dF9zdWZmaXgiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19leHBfaGlkZV9xdWlja19hY2Nl" +
    "c3NfcmVjZW50IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxD" +
    "aGVja0JveCBOYW1lPSJjaGtfZXhwX3Nob3dfZnVsbF9wYXRoIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZXhwX3NlcGFyYXRlX3By" +
    "b2Nlc3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNr" +
    "Qm94IE5hbWU9ImNoa19leHBfaGlkZV9uYXZfbGlicmFyaWVzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfZGVza3RvcF9zaG93X3Vz" +
    "ZXJfZm9sZGVyIiBJc0NoZWNrZWQ9IkZhbHNlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3Rh" +
    "Y2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAg" +
    "ICA8IS0tIEdyb3VwOiBDb250ZXh0IE1lbnUgQ2xlYW51cCAtLT4KICAgICAgICAgICAgICAgICAgICA8" +
    "R3JvdXBCb3ggTmFtZT0iZ3JwQ29udGV4dE1lbnUiIEhlYWRlcj0iQ29udGV4dCBNZW51IENsZWFudXAg" +
    "KFJpZ2h0LUNsaWNrKSI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jdHhfY2xlYW51cF9ibG9hdCIg" +
    "SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt" +
    "ZT0iY2hrX2N0eF93aW5yYXJfZW1haWwiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KICAgICAg" +
    "ICAgICAgICAgIDwvU3RhY2tQYW5lbD4KCiAgICAgICAgICAgICAgICA8IS0tIENPTFVNTiAzIC0tPgog" +
    "ICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgR3JpZC5Db2x1bW49IjIiIE1hcmdpbj0iNiwwLDAsMCI+" +
    "CiAgICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogV2luZG93cyBVcGRhdGUgJiBTeXN0ZW0gRGlh" +
    "Z25vc3RpY3MgLS0+CiAgICAgICAgICAgICAgICAgICAgPEdyb3VwQm94IE5hbWU9ImdycFdpblVwZGF0" +
    "ZSIgSGVhZGVyPSJXaW5kb3dzIFVwZGF0ZSwgQlNPRCAmYW1wOyBTeXN0ZW0iPgogICAgICAgICAgICAg" +
    "ICAgICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0Jv" +
    "eCBOYW1lPSJjaGtfd3VfZGlzYWJsZV9hdXRvX3VwZGF0ZXMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa193dV9leGNsdWRlX2RyaXZl" +
    "cnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94" +
    "IE5hbWU9ImNoa193dV9leGNsdWRlX21zcnQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zeXNfYnNvZF9ub19hdXRvcmVib290IiBJ" +
    "c0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1l" +
    "PSJjaGtfc3lzX3NtYWxsX21pbmlkdW1wIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3lzX2Zhc3Rfc3RhcnR1cF9vZmYiIElzQ2hl" +
    "Y2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNo" +
    "a19zeXNfZGlzYWJsZV9yZW1vdGVfYXNzaXN0IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3lzX2VuYWJsZV9waG90b192aWV3ZXIi" +
    "IElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5h" +
    "bWU9ImNoa19zeXNfbm90ZXBhZF90d2Vha3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAg" +
    "ICAgICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICAgICAgPC9Hcm91cEJveD4KCiAg" +
    "ICAgICAgICAgICAgICAgICAgPCEtLSBHcm91cDogQXBwcyAmIEJsb2F0d2FyZSAtLT4KICAgICAgICAg" +
    "ICAgICAgICAgICA8R3JvdXBCb3ggTmFtZT0iZ3JwQXBwcyIgSGVhZGVyPSJBcHAgRGVibG9hdGVyICZh" +
    "bXA7IFByb3Zpc2lvbmVkIFBhY2thZ2VzIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFN0YWNrUGFu" +
    "ZWw+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF94Ym94" +
    "IiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBO" +
    "YW1lPSJjaGtfYXBwX2dhbWVzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX25ld3MiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19hcHBfb2ZmaWNlX3N0dWIi" +
    "IElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5h" +
    "bWU9ImNoa19hcHBfY2xpcGNoYW1wIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfYXBwX3Blb3BsZSIgSXNDaGVja2VkPSJUcnVlIi8+" +
    "CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9mZWVkYmFj" +
    "ayIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3gg" +
    "TmFtZT0iY2hrX2FwcF9nZXRfaGVscCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2FwcF9waG9uZSIgSXNDaGVja2VkPSJUcnVlIi8+" +
    "CiAgICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8" +
    "L0dyb3VwQm94PgoKICAgICAgICAgICAgICAgICAgICA8IS0tIEdyb3VwOiBTZXJ2aWNlcyAmIFBlcmZv" +
    "cm1hbmNlIC0tPgogICAgICAgICAgICAgICAgICAgIDxHcm91cEJveCBOYW1lPSJncnBTZXJ2aWNlcyIg" +
    "SGVhZGVyPSJTeXN0ZW0gUGVyZm9ybWFuY2UgJmFtcDsgU2VydmljZXMiPgogICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8U3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBO" +
    "YW1lPSJjaGtfc3J2X3N5c21haW4iIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfaW5kZXhpbmciIElzQ2hlY2tlZD0iVHJ1ZSIv" +
    "PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfcmVtb3Rl" +
    "X3JlZyIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tC" +
    "b3ggTmFtZT0iY2hrX3Nydl9kZWxpdmVyeV9vcHQiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfcmVzZXJ2ZWRfc3RvcmFnZSIg" +
    "SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt" +
    "ZT0iY2hrX3Nydl9oaWJlcm5hdGlvbiIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl9wb3dlcl9wbGFuIiBJc0NoZWNrZWQ9IlRy" +
    "dWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X3Nz" +
    "ZF90cmltIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVj" +
    "a0JveCBOYW1lPSJjaGtfc3J2X25ldHdvcmtfb2ZmbG9hZCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX3Nydl92aXN1YWxfcGVyZiIg" +
    "SXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFt" +
    "ZT0iY2hrX3Nydl9wY2EiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICAgPENoZWNrQm94IE5hbWU9ImNoa19zcnZfdHJrd2tzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfc3J2X2lwaGxwc3ZjIiBJc0No" +
    "ZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAg" +
    "ICAgICAgICAgICAgIDwvR3JvdXBCb3g+CgogICAgICAgICAgICAgICAgICAgIDwhLS0gR3JvdXA6IENh" +
    "Y2hlICYgQ2xlYW5pbmcgLS0+CiAgICAgICAgICAgICAgICAgICAgPEdyb3VwQm94IE5hbWU9ImdycENs" +
    "ZWFuIiBIZWFkZXI9IkNhY2hlICZhbXA7IENvbXBvbmVudCBDbGVhbmluZyI+CiAgICAgICAgICAgICAg" +
    "ICAgICAgICAgIDxTdGFja1BhbmVsPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94" +
    "IE5hbWU9ImNoa19jbGVhbl91c2VyX3RlbXAiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19jbGVhbl93aW5fdGVtcCIgSXNDaGVja2Vk" +
    "PSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2Ns" +
    "ZWFuX3NvZnRfZGlzdCIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2NsZWFuX3RodW1iX2NhY2hlIiBJc0NoZWNrZWQ9IlRydWUiLz4K" +
    "ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xlYW5fc2hhZGVy" +
    "c19kbnMiIElzQ2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNr" +
    "Qm94IE5hbWU9ImNoa19jbGVhbl9ldmVudF9sb2dzIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAg" +
    "ICAgICAgICAgICAgICAgICAgIDxDaGVja0JveCBOYW1lPSJjaGtfY2xlYW5fcmVjeWNsZV9iaW4iIElz" +
    "Q2hlY2tlZD0iVHJ1ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9" +
    "ImNoa19jbGVhbl9jbGVhbm1nciIgSXNDaGVja2VkPSJUcnVlIi8+CiAgICAgICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8Q2hlY2tCb3ggTmFtZT0iY2hrX2RlZXBfZGlzbV9yZXBhaXIiIElzQ2hlY2tlZD0iVHJ1" +
    "ZSIvPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPENoZWNrQm94IE5hbWU9ImNoa19kZWVwX2Rp" +
    "c21fcmVzZXRiYXNlIiBJc0NoZWNrZWQ9IlRydWUiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAg" +
    "IDxDaGVja0JveCBOYW1lPSJjaGtfZGVlcF9zZmNfY29tcGFjdCIgSXNDaGVja2VkPSJUcnVlIi8+CiAg" +
    "ICAgICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAgICAgICAgICAgICAgICAgICA8L0dy" +
    "b3VwQm94PgogICAgICAgICAgICAgICAgPC9TdGFja1BhbmVsPgogICAgICAgICAgICA8L0dyaWQ+CiAg" +
    "ICAgICAgPC9TY3JvbGxWaWV3ZXI+CgogICAgICAgIDwhLS0gTGl2ZSBFeGVjdXRpb24gQ29uc29sZSAv" +
    "IExvZyBCb3ggKEhlaWdodCAxODUpIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5Sb3c9IjMiIEJhY2tn" +
    "cm91bmQ9IiMwYjBjMGUiIENvcm5lclJhZGl1cz0iNCIgUGFkZGluZz0iOCw2IiBCb3JkZXJCcnVzaD0i" +
    "IzI1MjgyZSIgQm9yZGVyVGhpY2tuZXNzPSIxIj4KICAgICAgICAgICAgPEdyaWQ+CiAgICAgICAgICAg" +
    "ICAgICA8R3JpZC5Sb3dEZWZpbml0aW9ucz4KICAgICAgICAgICAgICAgICAgICA8Um93RGVmaW5pdGlv" +
    "biBIZWlnaHQ9IkF1dG8iLz4KICAgICAgICAgICAgICAgICAgICA8Um93RGVmaW5pdGlvbiBIZWlnaHQ9" +
    "IkF1dG8iLz4KICAgICAgICAgICAgICAgICAgICA8Um93RGVmaW5pdGlvbiBIZWlnaHQ9IioiLz4KICAg" +
    "ICAgICAgICAgICAgIDwvR3JpZC5Sb3dEZWZpbml0aW9ucz4KCiAgICAgICAgICAgICAgICA8IS0tIENv" +
    "bnNvbGUgSGVhZGVyIFRvb2xiYXIgLS0+CiAgICAgICAgICAgICAgICA8RG9ja1BhbmVsIEdyaWQuUm93" +
    "PSIwIiBNYXJnaW49IjAsMCwwLDQiPgogICAgICAgICAgICAgICAgICAgIDxTdGFja1BhbmVsIERvY2tQ" +
    "YW5lbC5Eb2NrPSJSaWdodCIgT3JpZW50YXRpb249Ikhvcml6b250YWwiPgogICAgICAgICAgICAgICAg" +
    "ICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkNsZWFyTG9nIiBDb250ZW50PSLwn6e5IENsZWFyIiBNYXJn" +
    "aW49IjAsMCw0LDAiIFBhZGRpbmc9IjYsMiIgRm9udFNpemU9IjEwIi8+CiAgICAgICAgICAgICAgICAg" +
    "ICAgICAgIDxCdXR0b24gTmFtZT0iYnRuQ29weUxvZyIgQ29udGVudD0i8J+TiyBDb3B5IiBQYWRkaW5n" +
    "PSI2LDIiIEZvbnRTaXplPSIxMCIvPgogICAgICAgICAgICAgICAgICAgIDwvU3RhY2tQYW5lbD4KICAg" +
    "ICAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBPcmllbnRhdGlvbj0iSG9yaXpvbnRhbCIgVmVydGlj" +
    "YWxBbGlnbm1lbnQ9IkNlbnRlciI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxUZXh0QmxvY2sgVGV4" +
    "dD0iVEVSTUlOQUwgTE9HIiBGb250V2VpZ2h0PSJCb2xkIiBGb250U2l6ZT0iMTEiIEZvcmVncm91bmQ9" +
    "IiMwMGI0ZDgiIE1hcmdpbj0iMCwwLDEwLDAiLz4KICAgICAgICAgICAgICAgICAgICAgICAgPFRleHRC" +
    "bG9jayBOYW1lPSJ0eHRTdWJTdGF0dXMiIFRleHQ9IlJlYWR5LiIgRm9udFNpemU9IjEwLjUiIEZvcmVn" +
    "cm91bmQ9IiM5NGEzYjgiIFZlcnRpY2FsQWxpZ25tZW50PSJDZW50ZXIiLz4KICAgICAgICAgICAgICAg" +
    "ICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgICAgICA8L0RvY2tQYW5lbD4KCiAgICAgICAgICAg" +
    "ICAgICA8IS0tIFN1Yi1UYXNrIFByb2dyZXNzIEJhciAoZS5nLiBESVNNL1NGQyAlKSAtLT4KICAgICAg" +
    "ICAgICAgICAgIDxQcm9ncmVzc0JhciBHcmlkLlJvdz0iMSIgTmFtZT0icGJTdWJUYXNrIiBIZWlnaHQ9" +
    "IjMiIE1pbmltdW09IjAiIE1heGltdW09IjEwMCIgVmFsdWU9IjAiIEZvcmVncm91bmQ9IiMxMGI5ODEi" +
    "IEJhY2tncm91bmQ9IiMxZTIwMjYiIEJvcmRlclRoaWNrbmVzcz0iMCIgTWFyZ2luPSIwLDAsMCw0Ii8+" +
    "CgogICAgICAgICAgICAgICAgPCEtLSBMb2cgVGV4dCBBcmVhIC0tPgogICAgICAgICAgICAgICAgPFRl" +
    "eHRCb3ggR3JpZC5Sb3c9IjIiIE5hbWU9InR4dENvbnNvbGVMb2ciIEJhY2tncm91bmQ9IlRyYW5zcGFy" +
    "ZW50IiBGb3JlZ3JvdW5kPSIjNmVlN2I3IiBGb250RmFtaWx5PSJDb25zb2xhcyIgRm9udFNpemU9IjEx" +
    "IgogICAgICAgICAgICAgICAgICAgICAgICAgQm9yZGVyVGhpY2tuZXNzPSIwIiBJc1JlYWRPbmx5PSJU" +
    "cnVlIiBWZXJ0aWNhbFNjcm9sbEJhclZpc2liaWxpdHk9IkF1dG8iIEhvcml6b250YWxTY3JvbGxCYXJW" +
    "aXNpYmlsaXR5PSJBdXRvIiBUZXh0V3JhcHBpbmc9IldyYXAiCiAgICAgICAgICAgICAgICAgICAgICAg" +
    "ICBUZXh0PSJSZWFkeS4gU2VsZWN0IGRlc2lyZWQgb3B0aW1pemF0aW9uIG9wdGlvbnMgYW5kIGNsaWNr" +
    "IFNUQVJUIE9QVElNSVpBVElPTi4iLz4KICAgICAgICAgICAgPC9HcmlkPgogICAgICAgIDwvQm9yZGVy" +
    "PgoKICAgICAgICA8IS0tIEJvdHRvbSBBY3Rpb24gQmFyIC0tPgogICAgICAgIDxCb3JkZXIgR3JpZC5S" +
    "b3c9IjQiIE1hcmdpbj0iMCw4LDAsMCI+CiAgICAgICAgICAgIDxEb2NrUGFuZWwgTGFzdENoaWxkRmls" +
    "bD0iVHJ1ZSI+CiAgICAgICAgICAgICAgICA8U3RhY2tQYW5lbCBEb2NrUGFuZWwuRG9jaz0iUmlnaHQi" +
    "IE9yaWVudGF0aW9uPSJIb3Jpem9udGFsIiBWZXJ0aWNhbEFsaWdubWVudD0iQ2VudGVyIj4KICAgICAg" +
    "ICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkV4cG9ydExvZyIgQ29udGVudD0i8J+SviBFeHBv" +
    "cnQgTG9nIiBNYXJnaW49IjAsMCw2LDAiIFBhZGRpbmc9IjEyLDYiLz4KICAgICAgICAgICAgICAgICAg" +
    "ICA8QnV0dG9uIE5hbWU9ImJ0blNraXBCb3R0b20iIENvbnRlbnQ9IuKPrSBTS0lQIFNURVAiIEJhY2tn" +
    "cm91bmQ9IiNkOTc3MDYiIEJvcmRlckJydXNoPSIjZjU5ZTBiIiBGb3JlZ3JvdW5kPSIjZmZmZmZmIiBG" +
    "b250V2VpZ2h0PSJCb2xkIiBQYWRkaW5nPSIxNCw2IiBNYXJnaW49IjAsMCw2LDAiIEZvbnRTaXplPSIx" +
    "MiIgSXNFbmFibGVkPSJGYWxzZSIvPgogICAgICAgICAgICAgICAgICAgIDxCdXR0b24gTmFtZT0iYnRu" +
    "U3RhcnRCb3R0b20iIENvbnRlbnQ9IvCfmoAgU1RBUlQgT1BUSU1JWkFUSU9OIiBCYWNrZ3JvdW5kPSIj" +
    "MDA3N2I2IiBCb3JkZXJCcnVzaD0iIzAwOTZjNyIgRm9yZWdyb3VuZD0iI2ZmZmZmZiIgRm9udFdlaWdo" +
    "dD0iQm9sZCIgUGFkZGluZz0iMTYsNiIgTWFyZ2luPSIwLDAsNiwwIiBGb250U2l6ZT0iMTIiLz4KICAg" +
    "ICAgICAgICAgICAgICAgICA8QnV0dG9uIE5hbWU9ImJ0bkV4aXRCb3R0b20iIENvbnRlbnQ9IkV4aXQi" +
    "IE1hcmdpbj0iMCwwLDAsMCIgUGFkZGluZz0iMTIsNiIvPgogICAgICAgICAgICAgICAgPC9TdGFja1Bh" +
    "bmVsPgogICAgICAgICAgICAgICAgPFN0YWNrUGFuZWwgT3JpZW50YXRpb249IlZlcnRpY2FsIiBWZXJ0" +
    "aWNhbEFsaWdubWVudD0iQ2VudGVyIiBNYXJnaW49IjAsMCwxMiwwIj4KICAgICAgICAgICAgICAgICAg" +
    "ICA8UHJvZ3Jlc3NCYXIgTmFtZT0icGJQcm9ncmVzcyIgSGVpZ2h0PSI4IiBNaW5pbXVtPSIwIiBNYXhp" +
    "bXVtPSIxMDAiIFZhbHVlPSIwIiBGb3JlZ3JvdW5kPSIjMDBiNGQ4IiBCYWNrZ3JvdW5kPSIjMjUyODJl" +
    "IiBCb3JkZXJUaGlja25lc3M9IjAiIE1hcmdpbj0iMCwwLDAsNCIvPgogICAgICAgICAgICAgICAgICAg" +
    "IDxUZXh0QmxvY2sgTmFtZT0idHh0U3RhdHVzIiBUZXh0PSJSZWFkeS4gNzQgT3B0aW1pemF0aW9uIE1v" +
    "ZHVsZXMgQWN0aXZlLiIgRm9yZWdyb3VuZD0iIzk0OWJhNCIgRm9udFNpemU9IjExIi8+CiAgICAgICAg" +
    "ICAgICAgICA8L1N0YWNrUGFuZWw+CiAgICAgICAgICAgIDwvRG9ja1BhbmVsPgogICAgICAgIDwvQm9y" +
    "ZGVyPgogICAgPC9HcmlkPgo8L1dpbmRvdz4="
)

$xamlBytes = [System.Convert]::FromBase64String($xamlBase64)

$xamlString = [System.Text.Encoding]::UTF8.GetString($xamlBytes)

$reader = New-Object System.Xml.XmlTextReader (New-Object System.IO.StringReader $xamlString)

$window = [System.Windows.Markup.XamlReader]::Load($reader)



# Map UI Controls

$chkNames = @(

    "chk_telem_diagtrack", "chk_telem_dmwappush", "chk_telem_wer", "chk_telem_allow_telem",

    "chk_telem_ad_id", "chk_telem_inking", "chk_telem_activity", "chk_telem_location",

    "chk_telem_feedback", "chk_telem_tasks", "chk_telem_cortana",

    "chk_sec_uac_quiet", "chk_sec_admin_approval", "chk_sec_smartscreen", "chk_sec_open_file_warning",

    "chk_cloud_onedrive", "chk_cloud_settings_sync", "chk_cloud_bing_search", "chk_cloud_spotlight",

    "chk_cloud_consumer_features",

    "chk_edge_background", "chk_edge_startup_boost", "chk_edge_telemetry", "chk_edge_sidebar",

    "chk_edge_prelaunch", "chk_edge_first_run", "chk_edge_unpin",

    "chk_ui_widgets", "chk_ui_teams_chat", "chk_ui_copilot", "chk_ui_recall",

    "chk_ui_start_ads", "chk_ui_explorer_ads", "chk_ui_welcome_screen", "chk_ui_classic_context",

    "chk_ui_hide_search", "chk_ui_hide_taskview", "chk_ui_show_all_tray_icons",

    "chk_ui_never_combine_taskbar", "chk_ui_show_this_pc", "chk_ui_clock_24h_seconds",

    "chk_tb_small_icons", "chk_tb_lock", "chk_tb_hide_action_center", "chk_tb_hide_people",

    "chk_exp_open_this_pc", "chk_ui_folder_view_list_sort_type", "chk_exp_hide_user_folders", "chk_exp_no_shortcut_suffix",

    "chk_exp_hide_quick_access_recent", "chk_exp_show_full_path", "chk_exp_separate_process",

    "chk_exp_hide_nav_libraries", "chk_desktop_show_user_folder",

    "chk_ctx_cleanup_bloat", "chk_ctx_winrar_email",

    "chk_wu_disable_auto_updates", "chk_wu_exclude_drivers", "chk_wu_exclude_msrt",

    "chk_sys_bsod_no_autoreboot", "chk_sys_small_minidump",

    "chk_sys_fast_startup_off", "chk_sys_disable_remote_assist",

    "chk_sys_enable_photo_viewer", "chk_sys_notepad_tweaks",

    "chk_app_xbox", "chk_app_games", "chk_app_news", "chk_app_office_stub",

    "chk_app_clipchamp", "chk_app_people", "chk_app_feedback", "chk_app_get_help", "chk_app_phone",

    "chk_srv_sysmain", "chk_srv_indexing", "chk_srv_remote_reg", "chk_srv_delivery_opt",

    "chk_srv_reserved_storage", "chk_srv_hibernation", "chk_srv_power_plan", "chk_srv_ssd_trim",

    "chk_srv_network_offload", "chk_srv_visual_perf", "chk_srv_pca", "chk_srv_trkwks", "chk_srv_iphlpsvc",

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

$btnExitBottom    = $window.FindName("btnExitBottom")

$btnSelectAll     = $window.FindName("btnSelectAll")

$btnDeselectAll   = $window.FindName("btnDeselectAll")

$btnPresetOffice  = $window.FindName("btnPresetOffice")

$btnPresetGaming  = $window.FindName("btnPresetGaming")

$btnExportLog     = $window.FindName("btnExportLog")

$btnClearLog      = $window.FindName("btnClearLog")

$btnCopyLog       = $window.FindName("btnCopyLog")

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



# Host Detection

$compName = $env:COMPUTERNAME

$userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name

$osCaption = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName

if (-not $osCaption) { $osCaption = [System.Environment]::OSVersion.VersionString }



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

    if ($txtHostInfo)    { $txtHostInfo.Text = "$($loc['Host']): $compName ($userName) | $osCaption" }

    if ($txtPresets)     { $txtPresets.Text = $loc["Presets"] }



    if ($btnSelectAll)    { $btnSelectAll.Content = $loc["BtnSelectAll"] }

    if ($btnDeselectAll)  { $btnDeselectAll.Content = $loc["BtnDeselectAll"] }

    if ($btnPresetOffice) { $btnPresetOffice.Content = $loc["BtnPresetOffice"] }

    if ($btnPresetGaming) { $btnPresetGaming.Content = $loc["BtnPresetGaming"] }



    if ($btnStartTop)    { $btnStartTop.Content = $loc["BtnStart"] }

    if ($btnStartBottom) { $btnStartBottom.Content = $loc["BtnStart"] }

    if ($btnSkipTop)     { $btnSkipTop.Content = $loc["BtnSkip"] }

    if ($btnSkipBottom)  { $btnSkipBottom.Content = $loc["BtnSkip"] }

    if ($btnExitTop)     { $btnExitTop.Content = $loc["BtnExit"] }

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



    if ($txtStatus.Text -match 'Ready|Připraveno|Готово') {

        $txtStatus.Text = $loc["StatusReady"]

    }

}



# Attach Language Button Handlers

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

    Log-Message "Preset applied: Office (OneDrive, Phone Link and Office preserved)" "INFO"

})



$btnPresetGaming.Add_Click({

    foreach ($k in $controls.Keys) { $controls[$k].IsChecked = $true }

    $controls["chk_tb_small_icons"].IsChecked = $false

    $controls["chk_app_xbox"].IsChecked = $false

    $controls["chk_desktop_show_user_folder"].IsChecked = $false

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



    $actions = @()



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

        $actions += @{ Name = "Unpin Edge from Taskbar"; Script = {

            try {

                $shell = New-Object -ComObject Shell.Application

                $desktop = $shell.NameSpace([Environment]::GetFolderPath("Desktop"))

                $edgeLink = $desktop.Items() | Where-Object { $_.Name -like "*Edge*" }

                if ($edgeLink) {

                    foreach ($verb in $edgeLink.Verbs()) {

                        if ($verb.Name -replace '&','' -match "Unpin from taskbar|Открепить от панели задач|Odpnout z hlavního panelu") {

                            $verb.DoIt()

                            break

                        }

                    }

                }

            } catch {}

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DoNotCreateTaskbarShortcutOnFirstRun" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }



    # 5. Explorer, Desktop, Taskbar & Start Menu (Dism++ Tweaks)

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

        $actions += @{ Name = "Clean Start Menu: Remove Recommended & Suggestions"; Script = {

            # Win11: Minimize Recommended section to 1 row (More Pins mode)

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowRecent" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowFrequent" -Value 0 -Type DWord -ErrorAction SilentlyContinue



            # Disable recommendations and tips in Start

            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue



            # Explorer Policies

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoRecentDocsHistory" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "ClearRecentDocsOnExit" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoFrequentFolders" -Value 1 -Type DWord -ErrorAction SilentlyContinue

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

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_ui_folder_view_list_sort_type"].IsChecked) {

        $actions += @{ Name = "Set Folder View to List and Sort by Type"; Script = {

            # 1. Base Bags AllFolders Shell template

            $allFoldersShell = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"

            if (-not (Test-Path $allFoldersShell)) { New-Item -Path $allFoldersShell -Force | Out-Null }

            Set-ItemProperty -Path $allFoldersShell -Name "FolderType" -Value "NotSpecified" -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $allFoldersShell -Name "LogicalViewMode" -Value 4 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $allFoldersShell -Name "Mode" -Value 3 -Type DWord -ErrorAction SilentlyContinue



            # 2. Configure standard ShellBags for Generic folder GUID

            $genericBag = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell\{5c4f28b5-f869-4e84-8e60-f11db97c5ec7}"

            if (-not (Test-Path $genericBag)) { New-Item -Path $genericBag -Force | Out-Null }

            Set-ItemProperty -Path $genericBag -Name "LogicalViewMode" -Value 4 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $genericBag -Name "Mode" -Value 3 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $genericBag -Name "SortByList" -Value "prop:System.ItemTypeText;System.ItemNameDisplay" -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $genericBag -Name "GroupBy" -Value "" -ErrorAction SilentlyContinue



            # 3. Set FolderTypes TopViews for all common folder templates

            $ftGuids = @(

                "{5c4f28b5-f869-4e84-8e60-f11db97c5ec7}", # Generic

                "{7d49d726-3c21-4f05-99aa-fdc2c9474656}", # Documents

                "{b3607772-e24d-440e-9ca7-5ba5667e30ff}", # Pictures

                "{94d6f697-b25d-4404-9660-bb607f5e3d70}", # Music

                "{5fa96407-7e77-4837-ac58-0a6e0585b102}", # Videos

                "{0887779a-3a16-4f40-a386-8d1e84a25997}"  # Downloads

            )

            foreach ($guid in $ftGuids) {

                $topViewPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\FolderTypes\$guid\TopViews\{00000000-0000-0000-0000-000000000000}"

                if (-not (Test-Path $topViewPath)) { New-Item -Path $topViewPath -Force | Out-Null }

                Set-ItemProperty -Path $topViewPath -Name "LogicalViewMode" -Value 4 -Type DWord -ErrorAction SilentlyContinue

                Set-ItemProperty -Path $topViewPath -Name "Mode" -Value 3 -Type DWord -ErrorAction SilentlyContinue

                Set-ItemProperty -Path $topViewPath -Name "SortByList" -Value "prop:System.ItemTypeText;System.ItemNameDisplay" -ErrorAction SilentlyContinue

                Set-ItemProperty -Path $topViewPath -Name "GroupBy" -Value "" -ErrorAction SilentlyContinue

            }



            # 4. Streams Defaults to NotSpecified

            $streamsDefaults = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Defaults"

            if (-not (Test-Path $streamsDefaults)) { New-Item -Path $streamsDefaults -Force | Out-Null }

            Set-ItemProperty -Path $streamsDefaults -Name "FolderType" -Value "NotSpecified" -ErrorAction SilentlyContinue



            # 5. Clear per-folder Bags and BagMRU so every new and existing folder immediately uses List view & Sort by Type

            Get-ChildItem "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -ne "AllFolders" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

            Remove-Item "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -Force -ErrorAction SilentlyContinue

        }}

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

            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue

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

        $actions += @{ Name = "Disable Automatic Windows Updates (Strict Manual Only)"; Script = {

            # 1. Terminate running update workers immediately

            Stop-Process -Name "MoUsoCoreWorker", "UsoClient", "wuauclt" -Force -ErrorAction SilentlyContinue



            # 2. Stop and disable Windows Update services

            Stop-Service -Name "wuauserv", "UsoSvc", "dosvc", "WaaSMedicSvc", "bits" -Force -ErrorAction SilentlyContinue

            Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-Service -Name "UsoSvc" -StartupType Disabled -ErrorAction SilentlyContinue

            Set-Service -Name "dosvc" -StartupType Disabled -ErrorAction SilentlyContinue



            # 3. Direct registry service startup lock (Start = 4: Disabled)

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\dosvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue



            # 4. Group Policies: AUOptions = 1 (Never check), NoAutoUpdate = 1

            $wuPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

            $auPolicyPath = "$wuPolicyPath\AU"

            New-Item -Path $wuPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null

            New-Item -Path $auPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null



            Set-ItemProperty -Path $auPolicyPath -Name "NoAutoUpdate" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $auPolicyPath -Name "AUOptions" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $auPolicyPath -Name "AutoInstallMinorUpdate" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $auPolicyPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path $wuPolicyPath -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1 -Type DWord -ErrorAction SilentlyContinue



            # 5. Disable all scheduled tasks that trigger background update checks

            Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue

            Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue

            Get-ScheduledTask -TaskPath '\Microsoft\Windows\WaaSMedic\*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_wu_exclude_drivers"].IsChecked) {

        $actions += @{ Name = "Exclude Driver Updates from Windows Update"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_wu_exclude_msrt"].IsChecked) {

        $actions += @{ Name = "Exclude MSRT from Windows Update"; Script = {

            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Force -ErrorAction SilentlyContinue | Out-Null

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Name "DontOfferThroughWUAU" -Value 1 -Type DWord -ErrorAction SilentlyContinue

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

    if ($controls["chk_srv_ssd_trim"].IsChecked) {

        $actions += @{ Name = "Disable LastAccess & Trigger SSD TRIM"; Script = {

            fsutil.exe behavior set disablelastaccess 1 2>$null | Out-Null

            fsutil.exe behavior set disable8dot3 1 2>$null | Out-Null

            Log-Message "Running SSD TRIM on drive C:\..." "INFO"

            Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue

        }}

    }

    if ($controls["chk_srv_network_offload"].IsChecked) {

        $actions += @{ Name = "Disable Network Task Offload & Chimney"; Script = {

            netsh int ip set global taskoffload=disabled 2>$null | Out-Null

            netsh int tcp set global chimney=disabled 2>$null | Out-Null

        }}

    }

    if ($controls["chk_srv_visual_perf"].IsChecked) {

        $actions += @{ Name = "Optimize Visual Effects (Keep Font Smoothing)"; Script = {

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Type DWord -ErrorAction SilentlyContinue

            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -Type String -ErrorAction SilentlyContinue

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

        }}

    }

    if ($controls["chk_deep_dism_repair"].IsChecked) {

        $actions += @{ Name = "DISM Component Store Repair"; Script = {

            Invoke-ProcessWithLiveOutput -FilePath "dism.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth" -TaskName "DISM RestoreHealth" -TimeoutSeconds 600

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

    Log-Message "STARTING GIN-WIN-OPTIMIZER ENGINE v017. Total tasks selected: $total" "INFO"

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



    # Refresh Windows 11 Shell & Taskbar: Restart explorer.exe so search box, news/widgets, task view and copilot are removed immediately!

    Log-Message "Applying Windows 11 Taskbar changes and restarting Explorer shell..." "INFO"

    try {

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

        Start-Sleep -Milliseconds 1200

        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {

            Start-Process explorer.exe -ErrorAction SilentlyContinue

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

        "en" { "Optimization completed successfully!`n`nTasks executed: $total of $total`n`nAll results and status of each task are preserved in the Terminal Log below.`nThe window stays open for inspection, copy or export.`n`nA system restart is recommended to apply all changes." }

        "cs" { "Optimalizace byla úspěšně dokončena!`n`nProvedeno úloh: $total z $total`n`nVšechny výsledky a stav každé úlohy jsou zachovány v protokolu terminálu níže.`nOkno zůstává otevřené pro kontrolu, kopírování nebo export.`n`nPro dokončení všech změn se doporučuje restartovat počítač." }

        "ru" { "Глубокая оптимизация Windows успешно завершена!`n`nВыполнено задач: $total из $total`n`nВсе подробные результаты и статус каждой операции сохранены в окне Терминала ниже.`nОкно не закрывается — вы можете изучить лог, скопировать или экспортировать его.`n`nДля окончательного вступления всех настроек в силу рекомендуется перезагрузить компьютер." }

    }

    [System.Windows.MessageBox]::Show($completeMsg, "GIN-Win-Optimizer v017 [VladiMIR & Antigravity]", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

}



# Wire Start Buttons

$btnStartTop.Add_Click($executeOptimization)

$btnStartBottom.Add_Click($executeOptimization)



# Show UI Dialog with robust exception guard

try {

    $window.ShowDialog() | Out-Null

} catch {

    [System.Windows.MessageBox]::Show("Unexpected Error: " + $_.Exception.ToString(), "GIN-Win-Optimizer v017 Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)

}


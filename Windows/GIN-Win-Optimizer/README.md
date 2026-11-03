# 🚀 GIN-Win-Optimizer

> **Windows 10 / 11 Ultimate Performance Optimizer, System Debloater & Deep Cleaner**  
> *Standalone Native Win32 GUI Executable with Zero Console Flash, UAC Elevation, Multi-Resolution Icon, Trilingual Interface & Freeware Lifetime License.*

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011%20(x64)-blue.svg)](#)
[![Architecture](https://img.shields.io/badge/Architecture-Native%20Win32%20GUI-indigo.svg)](#)
[![License](https://img.shields.io/badge/License-Freeware%20(Lifetime)-green.svg)](#)
[![Modules](https://img.shields.io/badge/Optimization%20Modules-110%20Total-orange.svg)](#)
[![UI](https://img.shields.io/badge/UI-English%20%7C%20%C4%8Ce%C5%A1tina%20%7C%20%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-teal.svg)](#)

---

## 📖 Overview

**GIN-Win-Optimizer** is an enterprise-grade Windows optimization and maintenance utility engineered to clean, accelerate, harden, and debloat Windows 10 and Windows 11 workstations. Developed as a standalone, native 64-bit Windows executable (`GIN-Win-Optimizer.exe`), it launches directly into a sleek, high-contrast dark glassmorphism interface with **zero console flashing**.

Designed for power users, system administrators, and IT technicians, GIN-Win-Optimizer bundles **110 fine-tuned system modules** derived from Dism++ best practices, Group Policy standards, and Windows internals hardening. Every optimization can be inspected, toggled, and executed with granular transparency.

---

## ✨ Key Technical Architecture

- **Native Win32 GUI (Zero Console Flash)**: Built with native Windows subsystem parameters (`-H windowsgui`), preventing background black command prompt flickers during launch and execution.
- **Fullscreen Maximized Window Mode by Default**: Launches in a clean maximized window (`WindowState="Maximized"`) across modern high-resolution displays. Standard title bar controls (Minimize, Restore Down, Close) allow instant restoration to a centered 1280×890 window at any time.
- **Embedded UAC Elevation**: Features an integrated administrative application manifest (`level="requireAdministrator"`). Windows prompts with the authentic UAC elevation badge and icon on launch.
- **Single-Instance Mutex Protection**: Enforces an exclusive system mutex (`Local\GIN_WIN_OPTIMIZER_MUTEX`). Launching the executable a second time seamlessly restores and brings the existing window to the foreground.
- **Trilingual Localization Engine**: Instant dynamic runtime switching between **English**, **Čeština**, and **Russian** across all 110 module labels, group headers, dialogs, and status indicators.
- **Live Real-Time Terminal & Dual Progress Bars**: A high-visibility terminal emulator provides color-coded live progress, logging each operation in real time with separate indicators for individual subtask execution and overall workflow completion.
- **Export & Clipboard Tools**: Complete execution logs can be copied to the clipboard or exported to a timestamped log file with a single click.
- **Freeware Lifetime License**: Free for personal, educational, and commercial business use.

---

## 🎯 Quick Presets

GIN-Win-Optimizer includes four rapid profile presets located on the top navigation bar:

| Preset Button | Description | Configuration |
| :--- | :--- | :--- |
| **✓ Select All (Max Clean)** | Maximum clean and optimization profile for standard PCs. | Enables all **103 safe recommended modules**, leaving only 7 intensive or drive-specific options unchecked. |
| **✗ Deselect All** | Clears all checkboxes across all 10 categories. | Allows technicians to pick and execute specific single tweaks. |
| **🏢 Office (Keep OneDrive)** | Tailored for office and enterprise productivity workstations. | Keeps **OneDrive**, **Office 365 stub**, and **Phone Link** active, while stripping telemetry, Edge bloat, and system junk. |
| **⚡ Gaming (Keep Xbox)** | Tailored for gaming systems and sim rigs. | Preserves **Xbox services**, **Xbox Game Bar**, and **Xbox controller integration**, while disabling background indexing, telemetry, and latency-inducing offloads. |

---

## 🎛️ Detailed Optimization Modules Reference (All 110 Checkboxes)

Every single module in GIN-Win-Optimizer is thoroughly documented below across its **10 functional groups**. Each module is explicitly classified as either **Enabled by Default** (safe, high-benefit optimization) or **Disabled by Default** (deep maintenance or path-dependent operation).

---

### Group 1: Privacy & Diagnostics Telemetry (12 Modules)

*All 12 modules in this group are **Enabled by Default**.*

#### 1. `chk_telem_diagtrack` — Disable Connected User Experiences & Telemetry (DiagTrack)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `DiagTrack` (`Connected User Experiences and Telemetry`).
- **Explanation**: Stops and permanently disables the primary Windows telemetry service. Prevents continuous harvesting of user interactions, hardware identifiers, crash metrics, and event traces, stopping multi-megabyte diagnostic packets from being silently sent to Microsoft servers.

#### 2. `chk_telem_dmwappush` — Disable WAP Push Message Routing Service (dmwappushservice)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `dmwappushservice` (`Device Management Wireless Application Protocol (WAP) Push message Routing Service`).
- **Explanation**: Disables the secondary telemetry routing broker used to dispatch diagnostic telemetry and data collection triggers across cellular and local network adapters.

#### 3. `chk_telem_wer` — Disable Windows Error Reporting Service (WerSvc)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `WerSvc` (`Windows Error Reporting Service`).
- **Explanation**: Halts the automatic generation and network transmission of crash dumps and error logs. Prevents disk I/O freezes when an application crashes and protects sensitive process memory contents from network upload.

#### 4. `chk_telem_allow_telem` — Disable Diagnostics Data Collection via Policy
- **Status**: `[Enabled by Default]`
- **Technical Target**: Registry keys `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection` -> `AllowTelemetry = 0`.
- **Explanation**: Enforces strict Group Policy restrictions preventing Windows 10 and 11 from collecting diagnostic data, restricting system reporting to Security-only or completely disabled mode across all user hives.

#### 5. `chk_telem_ad_id` — Disable Advertising ID for All User Profiles
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo` -> `DisabledByGroupPolicy = 1`.
- **Explanation**: Blocks applications from utilizing the unique per-user Advertising ID. Prevents commercial tracking and personalized ad profiling based on application usage.

#### 6. `chk_telem_inking` — Disable Inking & Typing Personalization
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\InputPersonalization` -> `RestrictImplicitInkCollection = 1`, `RestrictImplicitTextCollection = 1`.
- **Explanation**: Disables keylogging heuristics and handwritten inking sample collection. Prevents typed phrases, dictionary adaptations, and touch gestures from being uploaded to Microsoft cloud services.

#### 7. `chk_telem_activity` — Disable Activity History (Timeline) & Cloud Sync
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\System` -> `EnableActivityFeed = 0`, `PublishUserActivities = 0`, `UploadUserActivities = 0`.
- **Explanation**: Disables Windows Timeline history tracking. Stops Windows from recording opened documents, visited URLs, and active window timestamps, and completely blocks cross-device timeline synchronization.

#### 8. `chk_telem_location` — Disable Geolocation & Location Sensor Service (lfsvc)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Service `lfsvc` (`Geolocation Service`) and `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors`.
- **Explanation**: Hardens location privacy by terminating continuous hardware location sensor polling and disabling location tracking APIs for desktop applications.

#### 9. `chk_telem_feedback` — Disable Windows Feedback Surveys & Prompts
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Siuf\Rules` -> `NumberOfSIUFInPeriod = 0`.
- **Explanation**: Completely eliminates intrusive pop-up feedback requests ("How likely are you to recommend Windows 11?") and disables periodic background survey scheduling.

#### 10. `chk_telem_tasks` — Disable Scheduled Telemetry & Customer Experience Tasks
- **Status**: `[Enabled by Default]`
- **Technical Target**: Task Scheduler paths under `\Microsoft\Windows\Application Experience`, `\Customer Experience Improvement Program`, and `\Autochk`.
- **Explanation**: Disables over 18 scheduled background tasks (including `Microsoft Compatibility Appraiser`, `ProgramDataUpdater`, `Consolidator`, `UsbCeip`) that cause periodic disk thrashing and CPU spikes.

#### 11. `chk_telem_cortana` — Disable & Block Cortana Assistant in Registry
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search` -> `AllowCortana = 0`.
- **Explanation**: Completely disables Cortana assistant integration, microphone background listening, and cloud voice queries system-wide.

#### 12. `chk_net_wifi_privacy` — Wi-Fi: Disable Random Hardware Addresses & Hotspot 2.0
- **Status**: `[Enabled by Default]`
- **Technical Target**: Wi-Fi adapter registry policies and network profile parameters.
- **Explanation**: Disables MAC address rotation that frequently disrupts static DHCP leases, enterprise Wi-Fi authentication, and local network shares, while disabling unauthenticated Hotspot 2.0 network probing.

---

### Group 2: Security, UAC & SmartScreen (4 Modules)

*All 4 modules in this group are **Enabled by Default**.*

#### 13. `chk_sec_uac_quiet` — Silent UAC for Administrators
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` -> `ConsentPromptBehaviorAdmin = 0`.
- **Explanation**: Automatically elevates administrative processes without blacking out the screen or popping modal prompt windows, while preserving the user security token so Universal Windows Platform (UWP) apps continue functioning perfectly.

#### 14. `chk_sec_admin_approval` — Enable Admin Approval Mode for Built-In Administrator
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` -> `FilterAdministratorToken = 1`.
- **Explanation**: Enables modern token filtering on the built-in Administrator account. Fixes the notorious Windows error where modern apps (Calculator, Photos, Edge) refuse to open under the primary Administrator account.

#### 15. `chk_sec_smartscreen` — Disable SmartScreen Filter for Apps & File Explorer
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\System` -> `EnableSmartScreen = 0`.
- **Explanation**: Stops Windows from sending application hash signatures to remote Microsoft servers whenever an unverified executable or script is launched, eliminating startup lags and offline launch failures.

#### 16. `chk_sec_open_file_warning` — Disable "Open File - Security Warning"
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations` -> `LowRiskFileTypes`.
- **Explanation**: Suppresses the annoying "Open File - Security Warning: We can't verify who created this file" prompt when running scripts, batch files, or executables downloaded from local or internet sources.

---

### Group 3: Cloud & Consumer Features (5 Modules)

*All 5 modules in this group are **Enabled by Default**.*

#### 17. `chk_cloud_onedrive` — Completely Remove Microsoft OneDrive
- **Status**: `[Enabled by Default]` *(Uncheck in Office Preset)*
- **Technical Target**: `%LOCALAPPDATA%\Microsoft\OneDrive`, `%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall`.
- **Explanation**: Terminates running OneDrive processes, completely uninstalls the client software, deletes leftover sync caches, and removes the OneDrive folder icon from File Explorer's navigation sidebar.

#### 18. `chk_cloud_settings_sync` — Disable Settings Synchronization
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync` -> `DisableSettingSync = 2`.
- **Explanation**: Prevents system themes, passwords, desktop backgrounds, and personal preferences from being automatically uploaded and synced across devices linked to the same Microsoft account.

#### 19. `chk_cloud_bing_search` — Disable Bing Web Search in Start Menu
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Policies\Microsoft\Windows\Explorer` -> `DisableSearchBoxSuggestions = 1`.
- **Explanation**: Restricts Start Menu search strictly to local files, installed software, and Control Panel applets. Eliminates web search suggestions, trending news tiles, and network delays when searching.

#### 20. `chk_cloud_spotlight` — Disable Windows Spotlight Lock Screen Ads
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Policies\Microsoft\Windows\CloudContent` -> `DisableWindowsSpotlightFeatures = 1`.
- **Explanation**: Disables promotional lock screen suggestions, quizzes, and sponsored backgrounds, replacing them with a crisp, stable user-selected wallpaper.

#### 21. `chk_cloud_consumer_features` — Block Automatic Background App Installation
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent` -> `DisableWindowsConsumerFeatures = 1`.
- **Explanation**: Prevents Windows from automatically downloading and installing third-party sponsored applications (such as TikTok, Candy Crush, Disney+, and trial apps) onto newly created user profiles.

---

### Group 4: Microsoft Edge Optimization (7 Modules)

*All 7 modules in this group are **Enabled by Default**.*

#### 22. `chk_edge_background` — Prevent Edge from Running in Background
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Edge` -> `BackgroundModeEnabled = 0`.
- **Explanation**: Prevents Edge from keeping lingering background processes and service workers alive in RAM after closing the browser window, freeing system memory.

#### 23. `chk_edge_startup_boost` — Disable Edge Startup Boost
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Edge` -> `StartupBoostEnabled = 0`.
- **Explanation**: Stops Edge from pre-launching core background processes at Windows boot, reducing startup times and conserving memory for other applications.

#### 24. `chk_edge_telemetry` — Disable Edge Diagnostics & Telemetry
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Edge` -> `MetricsReportingEnabled = 0`, `SendSiteInfoToImproveServices = 0`.
- **Explanation**: Enforces Edge enterprise policies to turn off browsing metric reporting, search query telemetry, and diagnostic tracking.

#### 25. `chk_edge_sidebar` — Disable Edge Sidebar, Shopping & AI Features
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Edge` -> `HubsSidebarEnabled = 0`, `EdgeShoppingAssistantEnabled = 0`.
- **Explanation**: Disables the right-hand browser sidebar, shopping coupons, price-tracking trackers, and built-in AI popups.

#### 26. `chk_edge_prelaunch` — Disable Edge Prelaunch at Windows Startup
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main` -> `AllowPrelaunch = 0`.
- **Explanation**: Blocks the Windows shell from pre-rendering Edge tabs before the user actually clicks the browser icon, reducing boot-time I/O contention.

#### 27. `chk_edge_first_run` — Prevent Edge First Run Experience & Welcome Screens
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Edge` -> `HideFirstRunExperience = 1`.
- **Explanation**: Suppresses new-version welcome tours, sync prompts, and promotional splash screens whenever Microsoft Edge updates.

#### 28. `chk_edge_unpin` — Unpin Edge & Internet Explorer from Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: Shell COM namespace unpin verbs & `LayoutModification.xml` deployment.
- **Explanation**: Removes Edge and legacy IE pins from the taskbar and deploys strict layout modification XML policies to prevent Windows Explorer from re-adding Edge ghost pins.

---

### Group 5: Explorer, Desktop & Taskbar (Dism++ Tweaks) (35 Modules)

*32 modules in this group are **Enabled by Default**; 3 modules are **Disabled by Default**.*

#### 29. `chk_reloc_documents` — Relocate Documents Folder to D:\DOCS
- **Status**: `[Disabled by Default — Optional User Relocation]`
- **Technical Target**: Shell User Folders registry paths and physical directory migration.
- **Explanation**: Safely relocates the user Documents directory from `C:\Users\<Username>\Documents` to `D:\DOCS`. Preserves user files while redirecting Windows shell pointers. Kept disabled by default so machines without a secondary `D:` drive remain unaffected.

#### 30. `chk_reloc_desktop` — Relocate Desktop Folder to D:\DOCS\desktop
- **Status**: `[Disabled by Default — Optional User Relocation]`
- **Technical Target**: Desktop shell folder redirection and path migration.
- **Explanation**: Moves the active Desktop storage folder to `D:\DOCS\desktop`, protecting desktop files from operating system re-installations and drive C: wipeouts. Kept disabled by default for single-partition compatibility.

#### 31. `chk_ui_widgets` — Disable & Remove Windows 11 Widgets & News
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `TaskbarDa = 0`.
- **Explanation**: Completely removes the weather/widgets button from the Windows 11 Taskbar and halts background `WebExperience` widget processes that consume background network bandwidth and memory.

#### 32. `chk_ui_teams_chat` — Remove Microsoft Teams Chat Icon from Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `TaskbarMn = 0`.
- **Explanation**: Removes the integrated personal Microsoft Teams Chat icon from the Windows 11 taskbar.

#### 33. `chk_ui_copilot` — Disable Windows Copilot AI
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot` -> `TurnOffWindowsCopilot = 1`.
- **Explanation**: Hides the Copilot taskbar button and enforces group policy to completely deactivate the Copilot side panel system-wide.

#### 34. `chk_ui_recall` — Disable Windows Recall AI Snapshot Feature
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI` -> `DisableAIDataAnalysis = 1`.
- **Explanation**: Deactivates the controversial Windows Recall feature, preventing the background engine from capturing periodic desktop screenshots and indexing screen contents.

#### 35. `chk_ui_start_ads` — Clean Start Menu: Remove Recommendations & Ads
- **Status**: `[Enabled by Default]`
- **Technical Target**: Start Menu policies & autonomous legacy applet purger.
- **Explanation**: Removes the "Recommended" section, promotional app suggestions, and recently added app banners from the Start Menu. Autonomously purges legacy obsolete applet shortcuts (Speech Recognition, Math Input Panel, Steps Recorder, Windows Fax and Scan, Character Map).

#### 36. `chk_ui_explorer_ads` — Disable Promo Ads in File Explorer
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `ShowSyncProviderNotifications = 0`.
- **Explanation**: Blocks OneDrive and Office 365 promotional subscription banners from appearing inside File Explorer folder headers.

#### 37. `chk_ui_welcome_screen` — Disable "Let's Finish Setting Up Your Device" Screen
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement` -> `ScoobeSystemSettingEnabled = 0`.
- **Explanation**: Disables the full-screen prompt that interrupts Windows startup after major updates, asking users to configure Windows Hello, Microsoft 365, or cloud backup.

#### 38. `chk_ui_lockscreen_clean` — Clean Lock Screen Presentation
- **Status**: `[Enabled by Default]`
- **Technical Target**: Lock screen personalization policies.
- **Explanation**: Disables lock screen trivia, fun facts, and advertising tips, while configuring the lock screen wallpaper to display cleanly on the sign-in screen.

#### 39. `chk_ui_color_accent_theme` — Dark System Theme with Steel Blue Accent
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize` and DWM accent color keys.
- **Explanation**: Applies a modern Dark theme across Windows and File Explorer, accents the Taskbar and active title bars with a crisp Steel Blue (`#0078D7`), and turns off window transparency effects to reduce DWM GPU consumption.

#### 40. `chk_ui_mouse_inverted_large` — Inverted (Large) Mouse Pointer with Drop Shadow
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Control Panel\Cursors` scheme keys.
- **Explanation**: Activates the native Windows Inverted (large) high-contrast cursor scheme with mouse drop shadow enabled, maximizing pointer visibility across 4K and multi-monitor setups.

#### 41. `chk_ui_classic_context` — Restore Windows 10 Classic Context Menu on Windows 11
- **Status**: `[Enabled by Default]`
- **Technical Target**: CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` in `HKCU\Software\Classes\CLSID`.
- **Explanation**: Bypasses the two-tiered Windows 11 context menu ("Show More Options"), instantly restoring direct, full right-click access to all third-party and system tools.

#### 42. `chk_ui_hide_search` — Hide Search Box & Icon from Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Search` -> `SearchboxTaskbarMode = 0`.
- **Explanation**: Hides the search box and magnifying glass icon from the Taskbar, freeing up taskbar real estate. Search remains instantly accessible by pressing the Windows key and typing.

#### 43. `chk_ui_hide_taskview` — Hide Task View Button from Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `ShowTaskViewButton = 0`.
- **Explanation**: Removes the Task View / Virtual Desktops button from the taskbar.

#### 44. `chk_ui_show_all_tray_icons` — Always Show All Icons in System Tray
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer` -> `EnableAutoTray = 0`.
- **Explanation**: Prevents background application icons from hiding inside the overflow chevron menu, ensuring all running utilities and system tray monitors are always visible at a glance.

#### 45. `chk_ui_never_combine_taskbar` — Never Combine Taskbar Buttons
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `TaskbarGlomLevel = 0`.
- **Explanation**: Configures taskbar buttons to display window titles side by side without grouping, drastically speeding up window switching during multitasking.

#### 46. `chk_ui_show_this_pc` — Always Display "This PC" Icon on Desktop
- **Status**: `[Enabled by Default]`
- **Technical Target**: Desktop NameSpace CLSID `{20D04FE0-3AEA-1069-A2D8-08002B30309D}`.
- **Explanation**: Guarantees that the native "This PC" shell icon is permanently displayed on the desktop across all user profiles.

#### 47. `chk_ui_clock_24h_seconds` — System Tray Clock: 24-Hour Format & Seconds Display
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `ShowSecondsInSystemClock = 1`.
- **Explanation**: Configures the taskbar digital clock to display exact 24-hour time including seconds (`HH:mm:ss`).

#### 48. `chk_ui_region_time_czech` — Regional TimeZone (UTC+1 Prague) & Auto-DST
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows TimeZone configuration & W32Time service.
- **Explanation**: Sets the system timezone to Central European Time (UTC+1, Prague/Vienna/Berlin) with automated daylight saving time adjustments.

#### 49. `chk_ui_lang_keyboards` — Standard Multi-Language Keyboard Hierarchy
- **Status**: `[Enabled by Default]`
- **Technical Target**: User language profile input methods.
- **Explanation**: Sets English (US) as primary system input language #1, with secondary European keyboards arranged cleanly in the taskbar language switcher.

#### 50. `chk_ui_regional_date_format` — Standardized European Date & Time Format
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Control Panel\International` -> `sShortDate = dd.MM.yyyy`.
- **Explanation**: Enforces standard European date notation (`dd.MM.yyyy`), 24-hour clock, and sets Monday as the first day of the week.

#### 51. `chk_tb_small_icons` — Enable Small Taskbar Buttons
- **Status**: `[Disabled by Default — Visual Density Preference]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `TaskbarSmallIcons = 1`.
- **Explanation**: Reduces Windows 10 taskbar button height to 24 pixels for a compact, screen-maximizing layout. Kept disabled by default so users who prefer default standard touch/mouse target sizes are not surprised.

#### 52. `chk_tb_lock` — Lock the Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `LockTaskbar = 1`.
- **Explanation**: Locks the taskbar and all toolbar handles to prevent accidental dragging, resizing, or moving to side edges.

#### 53. `chk_tb_hide_action_center` — Hide Action Center in System Tray
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Policies\Microsoft\Windows\Explorer` -> `HideSCAHealth = 1`.
- **Explanation**: Removes the Action Center notification bubble from the system tray, preventing non-critical notification popups.

#### 54. `chk_tb_hide_people` — Hide People Button on Taskbar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People` -> `PeopleBand = 0`.
- **Explanation**: Disables and hides the deprecated Windows People contact bar from the taskbar.

#### 55. `chk_exp_open_this_pc` — Open File Explorer Directly to "This PC"
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `LaunchTo = 1`.
- **Explanation**: Configures File Explorer (and the Win+E keyboard shortcut) to open directly to "This PC" showing drive partitions and devices, bypassing the Quick Access / Home view.

#### 56. `chk_ui_folder_view_list_sort_type` — Set Default Folder View to List Sorted by Type
- **Status**: `[Enabled by Default]`
- **Technical Target**: ShellBags streams and folder template defaults.
- **Explanation**: Applies a compact List view sorted alphabetically by file type across all standard folder directories, enabling rapid scanning of large directories.

#### 57. `chk_exp_hide_user_folders` — Hide 6 User Folders from "This PC"
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions` properties.
- **Explanation**: Removes the 6 default user folders (3D Objects, Music, Videos, Pictures, Documents, Downloads) from the main "This PC" window, displaying only physical and network drive partitions.

#### 58. `chk_exp_no_shortcut_suffix` — Do Not Append "- Shortcut" to New Shortcuts
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates` -> `ShortcutNameTemplate`.
- **Explanation**: Creates new file and folder shortcuts using their exact original names without adding the redundant " - Shortcut" suffix.

#### 59. `chk_exp_hide_quick_access_recent` — Hide Recent Files & Frequent Folders
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer` -> `ShowRecent = 0`, `ShowFrequent = 0`.
- **Explanation**: Prevents File Explorer from tracking and displaying recently opened files and frequently visited folders in Quick Access, preserving privacy.

#### 60. `chk_exp_show_full_path` — Display Full Folder Path in File Explorer Title Bar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState` -> `FullPath = 1`.
- **Explanation**: Displays the full directory path (e.g. `C:\Windows\System32`) in the title bar of every File Explorer window.

#### 61. `chk_exp_separate_process` — Launch Folder Windows in a Separate Process
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` -> `SeparateProcess = 1`.
- **Explanation**: Runs each File Explorer window in its own dedicated memory space. If a folder window hangs or crashes, the desktop shell and other explorer windows remain completely stable.

#### 62. `chk_exp_hide_nav_libraries` — Hide "Libraries" from File Explorer Navigation Pane
- **Status**: `[Enabled by Default]`
- **Technical Target**: CLSID `{031E4825-7B94-4dc3-B131-E946B7CD0BE5}` in Shell NameSpace.
- **Explanation**: Cleans up the left navigation sidebar of File Explorer by hiding legacy Windows Libraries.

#### 63. `chk_desktop_show_user_folder` — Show User Profile Folder on Desktop
- **Status**: `[Disabled by Default — Desktop Clutter Minimization]`
- **Technical Target**: Desktop NameSpace CLSID `{59031a47-3f72-44a7-89c5-5595fe6b30ee}`.
- **Explanation**: Adds the personal user profile folder (`C:\Users\<Username>`) icon to the desktop workspace. Kept disabled by default to keep the desktop minimalist.

---

### Group 6: Context Menu Cleanup (Right-Click) (2 Modules)

*Both modules in this group are **Enabled by Default**.*

#### 64. `chk_ctx_cleanup_bloat` — Remove Context Menu Bloat
- **Status**: `[Enabled by Default]`
- **Technical Target**: Context menu shell extensions under `HKCR\*\shellex\ContextMenuHandlers`.
- **Explanation**: Strips cluttered, rarely used context menu items (such as "Troubleshoot compatibility", "Edit with Paint 3D", "Give access to", "Burn to disc", and "Cast to Device"), yielding an ultra-fast right-click menu.

#### 65. `chk_ctx_winrar_email` — WinRAR: Hide "Compress and Email..." Clutter
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\WinRAR\Setup` context menu options.
- **Explanation**: Removes redundant "Compress to ... and email" entries from the right-click menu, leaving only standard archive creation and extraction options.

---

### Group 7: Windows Update, BSOD & System (9 Modules)

*All 9 modules in this group are **Enabled by Default**.*

#### 66. `chk_wu_disable_auto_updates` — Configure Windows Update: Never Check for Updates
- **Status**: `[Enabled by Default]`
- **Technical Target**: Group Policy keys `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` -> `NoAutoUpdate = 1`, `AUOptions = 1`. Services `wuauserv`, `UsoSvc`, `WaaSMedicSvc`.
- **Explanation**: Implements the strict Dism++ "Never check for updates" standard. Completely halts background update downloads, update orchestrator worker processes, and unexpected automated restarts. Updates are executed strictly when the user manually requests them.

#### 67. `chk_wu_exclude_drivers` — Windows Update Does Not Include Drivers
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` -> `ExcludeWUDriversInQualityUpdate = 1`.
- **Explanation**: Prevents Windows Update from silently overwriting manufacturer-provided graphics, chipset, sound, or network drivers with generic Microsoft drivers.

#### 68. `chk_wu_exclude_msrt` — Exclude Malicious Software Removal Tool (MSRT)
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SOFTWARE\Policies\Microsoft\MRT` -> `DontOfferThroughWUAU = 1`.
- **Explanation**: Blocks the recurring multi-hundred-megabyte monthly download of the Malicious Software Removal Tool, eliminating the prolonged background CPU scans that accompany it.

#### 69. `chk_sys_bsod_no_autoreboot` — Disable Automatic Reboot on BSOD
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SYSTEM\CurrentControlSet\Control\CrashControl` -> `AutoReboot = 0`.
- **Explanation**: Stops Windows from immediately rebooting upon a Blue Screen of Death (BSOD), giving administrators and technicians time to read and record the exact Stop Error code and faulting system driver.

#### 70. `chk_sys_small_minidump` — Configure Small Kernel Memory Minidump (256 KB)
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SYSTEM\CurrentControlSet\Control\CrashControl` -> `CrashDumpEnabled = 3`.
- **Explanation**: Replaces multi-gigabyte full system memory dumps with compact 256 KB minidumps stored in `C:\Windows\Minidump`, conserving gigabytes of SSD space while providing sufficient data for WinDbg crash analysis.

#### 71. `chk_sys_fast_startup_off` — Disable Fast Startup
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power` -> `HiberbootEnabled = 0`.
- **Explanation**: Turns off hybrid Fast Startup. Resolves common driver sleep bugs, partition corruption issues in multi-boot setups, and guarantees a completely fresh system kernel initialization on every cold boot.

#### 72. `chk_sys_disable_remote_assist` — Disable Remote Assistance
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance` -> `fAllowToGetHelp = 0`.
- **Explanation**: Disables Windows Remote Assistance listening endpoints, hardening network security against unauthorized remote session requests.

#### 73. `chk_sys_enable_photo_viewer` — Restore Classic Windows Photo Viewer
- **Status**: `[Enabled by Default]`
- **Technical Target**: File associations for `PhotoViewer.FileAssoc` (JPEG, PNG, BMP, GIF, TIFF).
- **Explanation**: Re-enables the ultra-fast, lightweight native C++ Windows Photo Viewer dll (`PhotoViewer.dll`), providing instantaneous image previews without the startup lag of the modern Photos app.

#### 74. `chk_sys_notepad_tweaks` — Notepad: Enable Word Wrap & Status Bar
- **Status**: `[Enabled by Default]`
- **Technical Target**: `HKCU\Software\Microsoft\Notepad` -> `fWrap = 1`, `StatusBar = 1`.
- **Explanation**: Ensures that classic Windows Notepad opens with automatic Word Wrap and the bottom Status Bar (displaying line and column count) enabled by default.

---

### Group 8: App Debloater & Provisioned Packages (10 Modules)

*All 10 modules in this group are **Enabled by Default**.*

#### 75. `chk_app_xbox` — Remove Xbox Packages
- **Status**: `[Enabled by Default]` *(Uncheck in Gaming Preset)*
- **Technical Target**: Provisioned UWP packages matching `*Xbox*`, `*GamingServices*`.
- **Explanation**: Uninstalls Xbox integration packages and background gaming services. (Uncheck this module if you use Xbox Game Pass or play Xbox live games).

#### 76. `chk_app_gamebar_disable` — Disable Xbox Game Bar Recording & Controller Shortcut
- **Status**: `[Enabled by Default]` *(Uncheck in Gaming Preset)*
- **Technical Target**: `HKCU\System\GameConfigStore` -> `GameDVR_Enabled = 0`.
- **Explanation**: Disables background DVR gameplay recording and prevents the Xbox controller guide button from triggering overlay menus, reducing GPU overhead.

#### 77. `chk_app_games` — Remove Promotional Games & Stubs
- **Status**: `[Enabled by Default]`
- **Technical Target**: Provisioned UWP packages (Candy Crush, Solitaire Collection, March of Empires, etc.).
- **Explanation**: Cleans out pre-installed commercial games and trialware stubs provisioned by OEM installations.

#### 78. `chk_app_news` — Remove MSN News, Weather, Sports & Finance Apps
- **Status**: `[Enabled by Default]`
- **Technical Target**: UWP packages matching `*BingNews*`, `*BingWeather*`, `*BingSports*`, `*BingFinance*`.
- **Explanation**: Uninstalls background news and weather feeds that consume network traffic and background CPU cycles.

#### 79. `chk_app_office_stub` — Remove Microsoft 365 / GetOffice Stub
- **Status**: `[Enabled by Default]` *(Uncheck in Office Preset)*
- **Technical Target**: UWP package `Microsoft.MicrosoftOfficeHub`.
- **Explanation**: Uninstalls the promotional Office 365 trial hub and purchase redirector.

#### 80. `chk_app_clipchamp` — Remove Pre-Installed Clipchamp Video Editor
- **Status**: `[Enabled by Default]`
- **Technical Target**: UWP package `*Clipchamp.Clipchamp*`.
- **Explanation**: Uninstalls the default web-wrapper video editor bundled with Windows 11.

#### 81. `chk_app_people` — Remove People App & Legacy Mail Stub
- **Status**: `[Enabled by Default]`
- **Technical Target**: UWP package `*People*`, `*windowscommunicationsapps*`.
- **Explanation**: Removes the unused People contact hub and legacy Windows Mail/Calendar placeholder applets.

#### 82. `chk_app_feedback` — Remove Feedback Hub App
- **Status**: `[Enabled by Default]`
- **Technical Target**: UWP package `*WindowsFeedbackHub*`.
- **Explanation**: Uninstalls the Feedback Hub application, eliminating automated customer survey prompts.

#### 83. `chk_app_get_help` — Remove Get Help & Tips Apps
- **Status**: `[Enabled by Default]`
- **Technical Target**: UWP packages `*GetHelp*`, `*Getstarted*`.
- **Explanation**: Removes introductory Windows tutorial apps and automated troubleshooting wrappers.

#### 84. `chk_app_phone` — Remove Phone Link App
- **Status**: `[Enabled by Default]` *(Uncheck in Office Preset)*
- **Technical Target**: UWP package `*YourPhone*`.
- **Explanation**: Uninstalls Phone Link background services. (Uncheck if you synchronize text messages and photos with an Android or iPhone device).

---

### Group 9: System Performance & Services (15 Modules)

*All 15 modules in this group are **Enabled by Default**.*

#### 85. `chk_srv_sysmain` — Disable SysMain / Superfetch Service
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `SysMain`.
- **Explanation**: Disables the SysMain service to stop aggressive application pre-caching into RAM and continuous disk writing. Prevents excessive write cycles and prolongs solid-state drive (SSD) longevity.

#### 86. `chk_srv_indexing` — Disable Windows Search Indexing Service
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `WSearch`.
- **Explanation**: Disables background search indexing. Eliminates random CPU spikes and background disk saturation during software compiling, downloads, and large file operations.

#### 87. `chk_srv_remote_reg` — Disable Remote Registry Service
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `RemoteRegistry`.
- **Explanation**: Sets the Remote Registry service to Disabled, preventing remote network users or malware from querying or modifying local registry hives.

#### 88. `chk_srv_delivery_opt` — Disable Delivery Optimization P2P Bandwidth Sharing
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `DoSvc` (`Delivery Optimization`).
- **Explanation**: Prevents Windows from uploading updates from your local hard drive to other unknown internet computers via peer-to-peer sharing, preserving your upload bandwidth.

#### 89. `chk_srv_reserved_storage` — Disable Windows Reserved Storage
- **Status**: `[Enabled by Default]`
- **Technical Target**: `Set-WindowsReservedStorageState -State Disabled`.
- **Explanation**: Reclaims approximately 7 GB of permanently locked hard drive space on drive C: that Windows reserves for staging updates.

#### 90. `chk_srv_hibernation` — Disable Hibernation & Delete hiberfil.sys
- **Status**: `[Enabled by Default]`
- **Technical Target**: `powercfg.exe -h off`.
- **Explanation**: Turns off ACPI hibernation and immediately deletes the massive `C:\hiberfil.sys` file, instantly freeing between 8 GB and 64 GB of SSD storage (equivalent to installed physical RAM).

#### 91. `chk_srv_power_plan` — Activate Ultimate Performance Power Plan
- **Status**: `[Enabled by Default]`
- **Technical Target**: Power Scheme GUID `e9a42b02-d5df-448d-aa00-03f14749eb61`.
- **Explanation**: Unlocks and activates the hidden Windows Ultimate Performance power scheme, eliminating CPU micro-throttling, unparking CPU cores, and optimizing hardware latency.

#### 92. `chk_srv_power_sleep_screen` — Intelligent Display & Sleep Timeouts
- **Status**: `[Enabled by Default]`
- **Technical Target**: `powercfg.exe` timeout parameters.
- **Explanation**: Configures optimal display and power timeouts: Display turns off Never; Sleep after 30 minutes on battery / Never on AC power; Screensaver activates after 10 minutes.

#### 93. `chk_srv_ssd_trim` — Disable LastAccess/8dot3 & Trigger SSD TRIM
- **Status**: `[Enabled by Default]`
- **Technical Target**: `fsutil behavior set disablelastaccess 1`, `fsutil behavior set disable8dot3 1`, `Optimize-Volume -ReTrim`.
- **Explanation**: Disables wasteful NTFS access timestamp updates and legacy 8.3 filename creation to speed up NTFS directories, followed by issuing an immediate Win32 TRIM optimization command across all attached SSD volumes.

#### 94. `chk_srv_pagefile_auto` — Smart Dynamic Pagefile on C:
- **Status**: `[Enabled by Default]`
- **Technical Target**: System pagefile sizing in `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`.
- **Explanation**: Dynamically calculates and applies an optimal Initial and Maximum paging file size on drive C: based on installed physical RAM, preventing drive fragmentation and avoiding "Out of Memory" crashes.

#### 95. `chk_srv_network_offload` — Disable Network Task Offload & Chimney
- **Status**: `[Enabled by Default]`
- **Technical Target**: `netsh int ip set global taskoffload=disabled`, `netsh int tcp set global chimney=disabled`.
- **Explanation**: Disables buggy network card hardware offloading heuristics that frequently cause packet drops, connection freezes, and latency spikes in online gaming and high-speed transfers.

#### 96. `chk_srv_visual_appearance` — Visual Effects: Adjust for Best Appearance
- **Status**: `[Enabled by Default]`
- **Technical Target**: `VisualFXSetting = 1` in `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects`.
- **Explanation**: Configures Windows System Properties to "Adjust for best appearance", enabling font smoothing (ClearType), smooth scrolling, drop shadows, window animations, and thumbnail previews for a visually stunning desktop experience.

#### 97. `chk_srv_pca` — Disable Program Compatibility Assistant (PcaSvc)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `PcaSvc`.
- **Explanation**: Disables the Program Compatibility Assistant service, eliminating redundant prompts asking "Did this program install correctly?" when running custom scripts or installers.

#### 98. `chk_srv_trkwks` — Disable Distributed Link Tracking Client (TrkWks)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `TrkWks`.
- **Explanation**: Disables tracking of linked files across NTFS drives on local networks, freeing background CPU cycles and disk I/O.

#### 99. `chk_srv_iphlpsvc` — Disable IP Helper Service (iphlpsvc)
- **Status**: `[Enabled by Default]`
- **Technical Target**: Windows Service `iphlpsvc`.
- **Explanation**: Disables legacy IPv6 transition tunneling mechanisms (6to4, ISATAP, Teredo). (Uncheck if your VPN provider specifically requires IPv6 tunnel adapters).

---

### Group 10: Cache, Temp & Component Cleaning (11 Modules)

*8 modules in this group are **Enabled by Default**; 3 deep maintenance modules are **Disabled by Default**.*

#### 100. `chk_clean_user_temp` — Clean User Temporary Files
- **Status**: `[Enabled by Default]`
- **Technical Target**: `%TEMP%`, `%LOCALAPPDATA%\Temp`.
- **Explanation**: Safely purges accumulated user scratch files, browser setup caches, and temporary application logs.

#### 101. `chk_clean_win_temp` — Clean System Temporary Directory
- **Status**: `[Enabled by Default]`
- **Technical Target**: `C:\Windows\Temp`.
- **Explanation**: Cleans system-level installer staging files, service dump logs, and driver extraction leftovers.

#### 102. `chk_clean_soft_dist` — Clean Windows Update Download Cache
- **Status**: `[Enabled by Default]`
- **Technical Target**: `C:\Windows\SoftwareDistribution\Download`.
- **Explanation**: Safely empties the Windows Update staging cache folder, reclaiming gigabytes of disk space occupied by previously installed update payloads.

#### 103. `chk_clean_thumb_cache` — Clean Thumbnail Cache Databases
- **Status**: `[Enabled by Default]`
- **Technical Target**: `%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db`.
- **Explanation**: Clears fragmented or corrupt Explorer thumbnail cache databases so Windows rebuilds them cleanly without graphical glitches.

#### 104. `chk_clean_shaders_dns` — Clean DirectX Shader Cache & Flush DNS
- **Status**: `[Enabled by Default]`
- **Technical Target**: `D3DSCache`, DirectX shader directories & `ipconfig /flushdns`.
- **Explanation**: Cleans stale compiled GPU shader caches (resolving stutter in newly patched games) and flushes the Windows DNS resolver cache.

#### 105. `chk_clean_event_logs` — Clear All Windows Event Logs
- **Status**: `[Enabled by Default]`
- **Technical Target**: `wevtutil.exe cl <LogName>` across all system event logs.
- **Explanation**: Clears all operational, system, application, and security event logs, resetting event log files to zero size.

#### 106. `chk_clean_recycle_bin` — Empty Recycle Bin for All Local Drives
- **Status**: `[Enabled by Default]`
- **Technical Target**: `Clear-RecycleBin -Force`.
- **Explanation**: Empties deleted files from Recycle Bins across all connected local and external drive volumes.

#### 107. `chk_clean_cleanmgr` — Run Automated System Disk Cleanup (cleanmgr)
- **Status**: `[Enabled by Default]`
- **Technical Target**: `cleanmgr.exe /autoclean /d C:`.
- **Explanation**: Triggers native Windows disk cleanup targeting obsolete system restore points, setup logs, and system error memory dump files.

#### 108. `chk_deep_dism_repair` — Check & Repair Component Store via DISM
- **Status**: `[Disabled by Default — Deep Component Operation (5–15 min)]`
- **Technical Target**: `dism.exe /Online /Cleanup-Image /RestoreHealth`.
- **Explanation**: Scans the Windows Component Store (WinSxS) for corruption and downloads authentic replacement files directly from Windows Update. Kept disabled by default due to its long execution time (5 to 15 minutes of heavy CPU and disk utilization). Can be enabled manually whenever Windows instability or corrupted system files are suspected.

#### 109. `chk_deep_dism_resetbase` — Deep Clean WinSxS Folder: ResetBase
- **Status**: `[Disabled by Default — Irreversible Operation (10–20 min)]`
- **Technical Target**: `dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase`.
- **Explanation**: Removes all superseded versions of updated system components in the `C:\Windows\WinSxS` folder, often reclaiming between 2 GB and 8 GB of disk space. Kept disabled by default because it takes 10 to 20 minutes and makes all previously installed Windows Updates permanent and non-uninstallable.

#### 110. `chk_deep_sfc_compact` — Run SFC Scannow & CompactOS Compression
- **Status**: `[Disabled by Default — Heavy System Scan (5–10 min)]`
- **Technical Target**: `sfc.exe /scannow` & `compact.exe /CompactOS:always`.
- **Explanation**: Verifies the digital signature and cryptographic integrity of every protected Windows operating system binary via System File Checker (`sfc /scannow`), repairing corrupted files, followed by applying CompactOS transparent filesystem compression to save disk space. Kept disabled by default due to high execution duration (5 to 10 minutes).

---

## 🚀 How to Run

1. Download **`GIN-Win-Optimizer.exe`** from this repository.
2. Launch the application (click **Yes** on the Windows UAC elevation prompt).
3. The interface will open maximized across your screen.
4. Select a preset (e.g., **Select All (Max Clean)** or **Office**) or customize individual checkboxes to your preferences.
5. Click **🚀 OPTIMIZE** on either the top action bar or bottom dock.
6. Observe live progress in the color-coded terminal log.
7. Upon completion, review the summary log, copy or export it, and restart your computer if prompted to finalize taskbar and service changes.

---

## 🛡️ Safety & Reliability Guarantee

- **Zero Registry Destruction**: Uses verified Win32 registry values and native Group Policy standards (`reg.exe` and `System.IO` APIs).
- **Graceful Shell Restart**: Automatically restarts Windows Explorer smoothly upon completion if taskbar settings are modified, ensuring immediate visual application without requiring a full PC reboot.
- **Self-Healing Guard**: Cleans up past system artifacts, legacy Start Menu shortcuts, and temporary files autonomously.

---

## 📬 Support & Community

- **Author & Architect**: VladiMIR + AI  
- **Telegram Support**: [https://t.me/GinCz](https://t.me/GinCz)  
- **License**: Freeware (Lifetime Free for Personal & Business Use)  
- **Repository**: [https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)

---
*Created with precision engineering for Windows 10 & 11.*

# 📜 GIN-Win-Optimizer — Release History & Changelog

All notable changes to the **GIN-Win-Optimizer** project are documented in this file.

---

## [v040] - 2026-11-05
- **Single-Standard CMD Format**: Standardized on unified portable CMD polyglot architecture per Vladimir directive. Removed compiled EXE (`GIN-Win-Optimizer.exe`) and binary build toolchain to avoid all delivery, SmartScreen, and Antivirus friction.
- **Universal Architecture (x86 & x64) & Legacy Windows Support**: Full native support for Windows 7 SP1, 8, 8.1, 10, and 11 across both 32-bit (x86) and 64-bit (x64) environments.
- **Silent UAC & Slider to Minimum**:
  - Programmatically pre-configures and enforces UAC slider to absolute minimum ("Never Notify"): `ConsentPromptBehaviorAdmin = 0`, `PromptOnSecureDesktop = 0`, `FilterAdministratorToken = 0`.
  - Permanently eliminates yellow "Unknown Publisher" UAC security prompt screens.
  - Automatically unchecks `chk_sec_admin_approval` by default across all presets (`SelectAll`, `Office`, `Gaming`) so Admin token filtering is never accidentally turned on.
- **Auto-Elevation with UNC Share Safety**:
  - Automatically verifies administrative session using native `net session >nul 2>&1`.
  - Re-elevates via PowerShell `Start-Process cmd.exe ... -Verb RunAs` if launched with regular privileges.
  - Detects UNC network share execution (`\\server\share`) and stages to local `%TEMP%\GIN-Win-Optimizer_v040.cmd` to prevent cmd.exe UNC errors.
  - Passes script path via `$env:GIN_OPT_SCRIPT` with fallback to avoid quote escaping or Czech diacritic path issues.
- **Network Drives & LAN Sharing Stability**:
  - Preserved `EnableLinkedConnections = 1` so mapped network drives are shared across standard and elevated sessions.
  - Preserved guest SMB share access (`AllowInsecureGuestAuth = 1`) and UNC execution (`DisableUNCCheck = 1`).
  - Guaranteed continuous auto-start of network services (`FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `lmhosts`, `Dnscache`, `SSDPSRV`, `upnphost`, `Spooler`).

## [v039] - 2026-11-04
- **Critical Fix**: Fixed missing `$actions` variable before `+=` at the LAN Discovery block (`engine.ps1` line 4150) that threw `The term '+=' is not recognized` on Optimize.
- **Ultarix 14-PC Accounting & 32-bit Hardening**:
  - Mandatory LAN & Accounting protection: switches active & registry network profiles to `Private` (`Category = 1`), sets `AllowInsecureGuestAuth = 1`, `EnableLinkedConnections = 1`, `DisableUNCCheck = 1`, guarantees startup of `FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `lmhosts`, `Dnscache`, `Spooler`, `NlaSvc`, `SSDPSRV`, `upnphost`, and accounting DB engines (`FSServer412Service` / NexusDB, `MSSQL*`, `Firebird*`), enables Firewall rules by resource IDs (`-28502`, `-28752`) and localized names, and enforces `taskoffload=enabled`.
  - Unchecked dangerous service tweaks by default and excluded them from `SelectAll`/`Office`/`Gaming` presets (`chk_srv_network_offload`, `chk_srv_pca`, `chk_srv_trkwks`, `chk_srv_iphlpsvc`, plus `chk_srv_indexing` in `Office`).
  - Enforced `fsutil behavior set disable8dot3 0` so 16/32-bit accounting apps (`STEREO`, `Ekonom`, `FORM studio`) never fail on paths with spaces or Czech diacritics.
  - Fixed `chk_srv_pagefile_auto` to always allocate `4096-8192 MB` on `C:` (instead of `1536 MB` on 4 GB RAM PCs) to prevent `0xe0000008` Out-Of-Memory crashes.
  - Removed `PreferredUILanguages = en-US` override from `chk_ui_lang_keyboards` so Czech/Russian Windows UI is never switched to English.
  - Guarded all `/reg:64` calls with `[Environment]::Is64BitOperatingSystem` for 100% compatibility with Windows 10 32-bit (x86).
  - Removed `chcp 65001` from CMD header (preventing Czech Win32 `0x1F` console error) and added `%TEMP%` staging when launched from UNC network paths (`\\Ulps1\util`).

## [v038] — 2026-11-04
### Ultralightweight (12.8 KB), Safe, Antivirus-Immune CMD Architecture & Comprehensive LAN/Memory Optimization

- **Ultralightweight Footprint (12.8 KB)**:
  - Completely re-engineered from bloated 244 KB hybrid into a clean, standalone, highly optimized Windows CMD batch script.
  - Reduced file footprint by **95%**, eliminating all unnecessary assemblies, heavy WinForms GUI elements, and complex wrappers.
- **Full Antivirus Immunity (Windows Defender & SmartScreen)**:
  - Zero obfuscation, zero Base64 payloads, zero suspicious PowerShell injection flags.
  - Native Windows CMD syntax with CRLF line terminators; completely transparent to heuristic engines.
  - Windows Defender service and system drivers remain 100% intact, active, and uncompromised.
- **Universal Architecture (32-bit x86 & 64-bit x64)**:
  - Seamless operation across Windows 10 Home/Pro/Enterprise/LTSC and Windows 11 on both 32-bit and 64-bit architectures.
  - Dynamic architecture detection (`x86`, `x64`, `ARM64`).
- **Elimination of Win32 Error 0x1F ("Zařízení připojené k systému nefunguje")**:
  - Removed `chcp 65001` UTF-8 code page switching from CMD.
  - Replaced all console outputs with standard ASCII characters and structured `[OK]` status indicators for clean, reliable display across all Windows system locales (Czech, Russian, English, German).
- **Comprehensive Network & LAN Sharing Optimization (Ultarix Standard)**:
  - Automatic profile conversion to **Private** network category for active connections and NetworkList registry.
  - Enabled **AllowInsecureGuestAuth** (DWORD 1) for guest SMB network share access.
  - Enabled **EnableLinkedConnections** (DWORD 1) so mapped drives are shared between standard user and Administrator.
  - Enabled **DisableUNCCheck** (DWORD 1) for error-free script execution from network UNC paths.
  - Guaranteed Auto-start and startup for critical services: `FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `Spooler`, `lmhosts`, `Dnscache`.
  - Added firewall rules for Network Discovery and File and Printer Sharing.
- **Memory & Performance Hardening**:
  - Static Pagefile fixed to 4096–8192 MB on `C:`, preventing memory commit failures and crash code `0xe0000008` on 32-bit and low-RAM hardware.
  - Disabled hibernation (`powercfg -h off`), reclaiming 4–8 GB of SSD storage immediately.
  - Optimized visual animations for snappy GUI responsiveness while strictly preserving ClearType font smoothing and text readability.
- **Safe System Cleanup & Telemetry Disabling**:
  - Safely purged `%TEMP%`, `%SystemRoot%\Temp`, Windows Update download cache (`SoftwareDistribution\Download`), and Explorer thumbnail caches.
  - Safely disabled background telemetry services `DiagTrack` and `dmwappushservice`, set DataCollection GPO to 0, and disabled Windows Error Reporting (`WerSvc`).
- **Version & Retention Alignment**:
  - Synchronized `version.json`, `README.md`, and `CHANGELOG.md` across `Secret_Privat` and `Windows_scripts`.

---

---

## [v036] — 2026-11-03
### 93% Executable Footprint Shrink (2.45 MB ➔ 174 KB) via Ultralightweight Native Win32 Launcher & Turnkey Zero-Confirmation Alignment

- **Extreme Binary Footprint Optimization (From 2,461 KB down to 174 KB)**:
  - Eliminated the heavy Go runtime overhead (which statically bundled GC, goroutine scheduler, and runtime reflection types into an oversized 2.45 MB binary).
  - Re-engineered the native standalone GUI launcher using Windows built-in `csc.exe` (.NET Framework 4.8 / Win32 GUI subsystem).
  - Binary executable size dropped by **93%**, from **2,461,696 bytes down to 174,592 bytes (170 KB)**.
  - The standalone `.exe` is now noticeably smaller than even the uncompressed raw `.cmd` script (~242 KB), bundling the full gzip-compressed 110-module engine (~52 KB) and high-res icon internally.
- **Feature & Capability Parity**:
  - Maintained zero console flashes (`subsystem:windows`, `CREATE_NO_WINDOW`, `ProcessWindowStyle.Hidden`).
  - Native embedded UAC shield manifest (`level="requireAdministrator"`).
  - Native Windows single-instance mutex (`Local\GIN_WIN_OPTIMIZER_MUTEX`) with automated foreground restore.
  - Maximized fullscreen window launch preserved.
- **Storage Retention & Deployment Sync**:
  - Enforced 2-version retention policy: `GIN-Win-Optimizer.exe`, `GIN-Win-Optimizer_v036.cmd`, and `GIN-Win-Optimizer_v035.cmd`.
  - Purged obsolete `v034.cmd` from production mirrors.
  - Synchronized across `Secret_Privat`, `Windows_scripts`, and `D:\MEGA\WIN-FLASH\Util-WINDOWS\`.

---

## [v035] — 2026-11-03
### Fullscreen Maximized Window Mode by Default (WindowState="Maximized") & PE Metadata Alignment

- **Fullscreen Maximized Window Mode on Launch**:
  - Configured WPF Window root definition with `WindowState="Maximized"`.
  - Added programmatic runtime guarantee `$window.WindowState = [System.Windows.WindowState]::Maximized` immediately upon XAML loading.
  - The application opens seamlessly maximized across the entire display workspace by default, providing full visibility for all 110 optimization modules and real-time live console output without requiring manual window resizing.
  - Preserved standard Windows title bar controls (Minimize, Restore Down, Close) and base dimensions (`Height="890" Width="1280"`), allowing effortless restoration to centered window mode at any time.
- **Strict PE File Version & Metadata Synchronization**:
  - Synchronized Win32 PE `VERSIONINFO` in `app.rc`: `FileDescription` and `ProductName` strictly set to `GIN-Win-Optimizer_v035`, `FileVersion` and `ProductVersion` to `v035` (binary `0.35.0.0`), `LegalCopyright` and `CompanyName` set strictly to `VladiMIR+AI`.
  - Updated all internal trilingual GUI headers, status bars, and loggers across EN, CS, and RU locales.
- **Artifact Self-Healing & Retention Rotation**:
  - Added automated cleanup for `*v034)*` artifacts in system paths.
  - Rotated active versions to `GIN-Win-Optimizer.exe`, `GIN-Win-Optimizer_v035.cmd`, and `GIN-Win-Optimizer_v034.cmd`. Purged `v033` from production storage mirrors.

---

## [v034] — 2026-11-03
### Standalone Native Win32 GUI Executable (GIN-Win-Optimizer.exe), Custom Multi-Resolution Icon, UAC Shield, Single-Instance Mutex, Telegram Support & Freeware License

- **Strict Version Increment (v033 ➔ v034)**:
  - Enforced mandatory engineering discipline: every new build, architecture enhancement, and binary release increments the project version.
  - Active executable is now permanently named `GIN-Win-Optimizer.exe` (with version `v034` embedded into PE file properties, visible on hover and in Details).
- **Standalone Native Win32 GUI Executable (GIN-Win-Optimizer.exe)**:
  - Full conversion from raw `.cmd` script into a monolithic, compiled 64-bit Windows GUI executable (`subsystem:windows`).
  - **Zero Console Flash**: Completely eliminates command prompt flashes or background terminal windows.
  - **Single-Window WPF Experience**: Launches directly into the high-performance dark glassmorphism WPF GUI.
  - Embedded engine: Bundles the full 110-module PowerShell optimization engine in high-efficiency gzip compression.
- **Embedded UAC Elevation & Administrator Manifest**:
  - Embedded application manifest with `requestedExecutionLevel level="requireAdministrator"`.
  - Windows automatically displays the official UAC shield and prompt with the application name and icon before launch.
  - Secondary programmatic elevation fallback via `ShellExecuteW(..., "runas")`.
- **Single-Instance Mutex Protection (Global\GIN_WIN_OPTIMIZER_MUTEX)**:
  - Named Windows kernel mutex prevents duplicate processes.
  - If already open, brings the active optimizer window to the foreground (`SW_RESTORE`, `SetForegroundWindow`) and cleanly exits.
- **Custom Multi-Resolution Application Icon (app.ico)**:
  - High-tech aerodynamic turbo rocket & gauge emblem with neon cyan glow, obsidian background, and crisp "GIN" badge.
  - Embedded into the PE resource table (`1 ICON`) and dynamically applied to the WPF window title bar and taskbar (`$window.Icon`).
  - Contains full multi-layer MIPs: 256x256, 128x128, 64x64, 48x48, 32x32, 16x16.
- **Official PE File Properties & Brand Signature (VERSIONINFO)**:
  - **Company**: `VladiMIR+AI (Vladimir Bulantsev)`
  - **File Description**: `GIN-Win-Optimizer - Windows 10/11 Ultimate Optimizer & Deep Cleaner`
  - **File Version**: `v034` (0.34.0.0)
  - **Product Name**: `GIN-Win-Optimizer`
  - **Product Version**: `v034`
  - **Legal Copyright**: `Copyright (C) 2026 Vladimir Bulantsev & AI. Freeware - Free for personal & business use.`
  - **Comments**: `Freeware. Lifetime free for personal and business use. Support & Contact: https://t.me/GinCz`
  - **Legal Trademarks**: `GIN(TM)`
- **Integrated Telegram Support & Freeware Licensing in GUI**:
  - Added dedicated **`[ ✈️ Telegram (@GinCz) ]`** direct button in the header alongside language pills, opening `https://t.me/GinCz`.
  - Added **`FREEWARE`** badge in the header indicating lifetime free status for personal and business use.
  - Updated window titles and subheaders across all 3 languages (RU, EN, CZ) to `[VladiMIR + AI]`.

---

## [v033] — 2026-11-02
### Autonomous Start Menu Legacy Applet Purge Engine & Post-Servicing Sweep

- **Strict Version Increment (v032 ➔ v033)**:
  - Enforced mandatory engineering discipline: every new feature, policy adjustment, and module addition increments the project version.
  - Active retention updated to strictly 2 latest versions: 033 (current production) and 032 (previous baseline). Old 031 rotated out from active flash deployment paths (D:\MEGA\WIN-FLASH\Util-WINDOWS\).
- **Autonomous Start Menu Legacy Applet Purge Engine (Purge-StartMenuLegacyJunk)**:
  - Automatically identifies, purges, and prevents re-creation of legacy deprecated Windows applet shortcuts:
    - Speech Recognition.lnk (Распознавание речи)
    - Math Input Panel.lnk (Панель ввода математических знаков)
    - Steps Recorder.lnk (Запись действий по воспроизведению неполадок)
    - Windows Fax and Scan.lnk (Факсы и сканирование)
    - Character Map.lnk (Таблица символов)
  - Autonomously sweeps and removes orphan Accessibility and redundant Accessories folders across all user profiles (%ProgramData%, %AppData%, and Default User).
  - Cleans up empty System Tools subfolders.
- **Multi-Stage Post-Servicing Anti-Recreation Hooks**:
  - **Self-Healing on Startup**: Instantly cleans any restored shortcuts on script launch before GUI rendering.
  - **Clean Start Menu Module (chk_ui_start_ads)**: Embedded deep purge during user-directed layout cleaning.
  - **Post-Cleanmgr Sweep (chk_clean_cleanmgr)**: Automatically executes immediately after cleanmgr.exe /autoclean finishes on C: and D:, neutralizing any shortcuts restored by CBS/WinSxS component servicing.
  - **Post-DISM & Post-SFC Sweeps**: Automatically executes after dism.exe /RestoreHealth and sfc.exe /scannow, guaranteeing Windows Resource Protection does not leave orphan shortcuts in Start Menu.
  - **Final Pre-Restart Sweep**: Executes right before Explorer shell restart, ensuring completely pristine Start Menu presentation.

---

## [v032] вЂ” 2026-11-02
### Hardware-Adaptive Personalization, Custom Accent Styling & 110-Module Milestone

- **Strict Version Increment (031 вћ” 032)**:
  - Enforced mandatory engineering discipline: every new feature, policy adjustment, and module addition increments the project version.
  - Active retention updated to strictly 2 latest versions: 032 (current production) and 031 (previous baseline). Old 030 rotated out from active flash deployment paths.
- **Smart Elastic Pagefile Optimizer Engine (chk_srv_pagefile_auto вЂ” Module #107)**:
  - Dynamically calculates optimal Initial and Maximum pagefile sizing on system drive C:\ based on installed physical RAM:
    - <= 4 GB RAM: 1536 MB Initial / 4096 MB Max
    - <= 8 GB RAM: 2048 MB Initial / 4096 MB Max
    - <= 16 GB RAM: 2048 MB Initial / 6144 MB Max
    - >= 32 GB RAM: 2048 MB Initial / 4096 MB Max
  - **Drive C: Free Space Protection Guard**:
    - Automatically caps maximum pagefile size to <= 35% of free space on C:\.
    - Guarantees at least 3 GB of free disk space remains under absolute peak allocation.
    - Prevents system drive choking on SSDs with constrained free capacity.
  - **Elastic / Dynamic Range**: Starts compact (2 GB) to minimize SSD space wear, expanding smoothly up to 6 GB under peak commit charge.
  - **Drive Centralization**: Clears rogue pagefiles on secondary drives (D:\, G:\) and centralizes management strictly on C:\.
  - **Dual Engine Persistence**: Dual-layer registry (Control\Session Manager\Memory Management) and CIM/WMI Win32_PageFileSetting persistence.
- **Clean Lock Screen & Screensaver Synchronization (chk_ui_lockscreen_clean вЂ” Module #108)**:
  - Disables annoying facts, tips, tricks, and Cortana/Bing suggestions on the Lock Screen (RotatingLockScreenOverlayEnabled = 0, SubscribedContent-338387Enabled = 0).
  - Keeps Lock Screen wallpaper synchronized on the login/sign-in screen (DisableLogonBackgroundImage = 0).
  - Sets Screensaver timeout to 10 minutes (600 seconds) without password prompt on resume (ScreenSaverIsSecure = 0).
  - Configures screensaver binary to C:\Windows\X-SAVER3.SCR (falling back gracefully to %SystemRoot%\system32\scrnsave.scr if absent).
  - Power scheme optimization: display turns off **Never** (AC/DC: 0 min), sleep mode after 30 min on battery and **Never** on AC.
- **Dark System Theme & Steel Blue Accent Color (chk_ui_color_accent_theme вЂ” Module #109)**:
  - Enforces native Windows Dark Mode for system UI (SystemUsesLightTheme = 0).
  - Disables transparency effects for crisper graphics and GPU memory conservation (EnableTransparency = 0).
  - Sets exact Steel Blue / Dark Teal accent color matching user preference:
    - Hex:  xFF9A5F2D (AccentColor: 4288314669, ColorizationColor: 3291315610).
  - Enables accent color display on Taskbar, Start Menu, Action Center (Themes\Personalize -> ColorPrevalence = 1).
  - Enables accent color display on active Window Title bars and window borders (DWM -> ColorPrevalence = 1).
- **Inverted Large Cursor Scheme with Drop Shadow (chk_ui_mouse_inverted_large вЂ” Module #110)**:
  - Applies native Windows "РРЅРІРµСЂСЃРЅР°СЏ (РєСЂСѓРїРЅР°СЏ)" / "Inverted (large)" high-contrast cursor scheme for maximum pointer visibility.
  - Enables mouse pointer drop shadow (DropShadow = 1 in UserPreferencesMask).
  - Uses direct Win32 SystemParametersInfo(SPI_SETCURSORS, 0, 0, 3) P/Invoke to reload cursors live in real time without requiring a system reboot or sign-out.
- **Start Menu Jump Lists Restoration & Group Policy Remediation**:
  - Remediates and removes destructive legacy policies NoRecentDocsHistory and ClearRecentDocsOnExit from HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer that previously triggered the red corporate restriction text: *РќРµРєРѕС‚РѕСЂС‹Рµ РёР· СЌС‚РёС… РїР°СЂР°РјРµС‚СЂРѕРІ СЃРєСЂС‹С‚С‹ РёР»Рё РєРѕРЅС‚СЂРѕР»РёСЂСѓСЋС‚СЃСЏ РІР°С€РµР№ РѕСЂРіР°РЅРёР·Р°С†РёРµР№.
  - Fully enables Jump Lists and recent file tracking across Start Menu, Taskbar, and File Explorer Quick Access (Start_TrackDocs = 1, ShowRecent = 1).
  - Keeps App List visible in Start (Start_ShowRecentApps = 1), while cleanly suppressing Bing web suggestions, sponsored tiles, and tips.
- **Trilingual Localization**:
  - Full WPF UI localization across English, Russian, and Czech for all new modules with 110 active modules.

## [v031] вЂ” 2026-11-01
### Native Performance Options "Adjust for Best Appearance" (РћР±РµСЃРїРµС‡РёС‚СЊ РЅР°РёР»СѓС‡С€РёР№ РІРёРґ) Default Preset

- **Visual Effects Best Appearance Standard (chk_srv_visual_appearance)**:
  - Replaced legacy basic font smoothing toggle with dedicated, full-spectrum **"Adjust for best appearance" (РћР±РµСЃРїРµС‡РёС‚СЊ РЅР°РёР»СѓС‡С€РёР№ РІРёРґ / Nastavit pro nejlepЕЎГ­ vzhled)** preset matching native Windows System Properties Performance Options (sysdm.cpl -> SystemPropertiesPerformance.exe).
  - **Selected by Default (IsChecked = True)**: Pre-selected out-of-the-box so optimized systems maintain maximum UI beauty, fluid animations, crisp font rendering, and modern visual aesthetics without looking stripped down or dated.
  - Direct System Registry Configuration: VisualFXSetting = 1, FontSmoothing = "2", FontSmoothingType = 2, DragFullWindows = "1", MinAnimate = "1", TaskbarAnimations = 1, ListviewAlphaSelect = 1, DropShadow = 1.
  - Immediate visual activation upon post-optimization Explorer restart.
- **Documentation Localization & Public Mirror Sync**:
  - Comprehensive English guide authored and synchronized in public GitHub repository (Windows_scripts/Windows/GIN-Win-Optimizer/README.md).

## [v030] в”Ђв”Ђ 2026-10-31
### Native reg.exe Dism++ Lockdown & LayoutModification Empty PinList Protection
- **Root-Cause Resolution for Windows Update Setting Dropdown**:
  - In previous versions, PowerShell registry provider calls (`New-Item` / `Set-ItemProperty`) silently failed to create or persist subkeys under `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` when parent keys were locked or redirected.
  - Furthermore, `cleanmgr.exe /autoclean` (executed as final task 98) triggered background component cleanup which reverted policy keys if not re-asserted.
  - **Quadruple Native `reg.exe` Lockdown**: Replaced PowerShell provider calls with direct Win32 `reg.exe` commands executing with explicit `/reg:64` and `/reg:32` architecture flags:
    - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` -> `AUOptions = 1`, `NoAutoUpdate = 1`, `AutoInstallMinorUpdates = 0`, `DetectionFrequencyEnabled = 0`
    - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` -> `DoNotConnectToWindowsUpdateInternetLocations = 1`, `DisableWindowsUpdateAccess = 1`, `SetDisableUXWUAccess = 1`, `ExcludeWUDriversInQualityUpdate = 1`
    - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update` -> `AUOptions = 1`, `CachedAUOptions = 1`, `EnableFeaturedSoftware = 0`
    - `HKLM\SOFTWARE\Policies\Microsoft\MRT` -> `DontOfferThroughWUAU = 1`
  - **4-Stage Redundancy Execution**: Applied at Startup Self-Healing, within Module execution, at Finalization (post-Cleanmgr), and during Post-Restart Explorer sweep.
  - **Absolute Service & Task Neutralization**: Forces `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `dosvc` to Disabled (`Start = 4`) and stopped via `sc.exe config` and `sc.exe stop`.
- **Permanent Taskbar Edge Spartan Elimination via `LayoutModification.xml`**:
  - Discovered that Windows 10 automatically pins the legacy AppX stub `Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge` as a blank grey square tile when `explorer.exe` restarts if Chromium Edge is missing.
  - **`LayoutModification.xml` Defense**: Deployed customized `LayoutModification.xml` with `PinListPlacement="Replace"` and an empty `<taskbar:TaskbarPinList />` to both `$env:LOCALAPPDATA\Microsoft\Windows\Shell\` and `C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\`. This permanently instructs Windows 10 never to inject default OEM or Edge pins into the Taskbar.
  - Combined with Shell COM unpinning and shortcut blocking policies.

---

## [v029] — 2026-10-31
### Permanent Taskbar Edge & IE Eradication, Absolute Windows Update Lock (Dism++ Standard)
- **Native Win32 Shell COM Taskbar Unpinning for Edge & IE**:
  - **Root Cause of Reappearing Edge Ghost Icon**: In Windows 10/11, pinned apps are stored as binary shell item ID lists (PIDLs) inside `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband` (`Favorites` and `FavoritesResolve`). Deleting `.lnk` files from `User Pinned\TaskBar` has zero effect on modern AppX/UWP packages (`Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge`), leaving a corrupted blank dark grey square tile on the taskbar.
  - **Direct AppsFolder COM Unpin Engine**: Implemented native `Shell.Application` namespace interrogation (`shell:::{4234d49b-0245-4df3-b780-3893943456e1}`) to execute the genuine system verb (`Unpin from taskbar` / `Открепить от панели задач` / `Odepnout z hlavního panelu`) across all languages.
  - **Tri-Layer Auto-Execution**:
    1. **Startup Self-Healing**: Automatically scans and purges Edge & IE pins the instant `GIN-Win-Optimizer` launches.
    2. **Optimization Module (`chk_edge_unpin`)**: Unpins Edge/IE, purges `.lnk` shortcuts from TaskBar, Start Menu, Quick Launch, User/Public Desktops, and applies registry blocks against shortcut re-creation (`DoNotCreateTaskbarShortcut = 1`, `DisableEdgeDesktopShortcutCreation = 1`).
    3. **Pre- & Post-Explorer Restart Sweeps**: Executes both immediately before and after restarting `explorer.exe` to guarantee Windows never restores default OEM taskbar pins.
- **Absolute Windows Update Lockdown (1-to-1 Dism++ Exact Parity)**:
  - **Permanent 'Не проверять (не рекомендуется)' Policy**:
    - Strictly configures `AUOptions = 1` and `NoAutoUpdate = 1` in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` (matching Dism++ Data.xml definition exactly).
    - Synchronously sets `AUOptions = 1` and `CachedAUOptions = 1` in `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update`.
    - Enforces Dism++ quality update exclusions: `ExcludeWUDriversInQualityUpdate = 1` and MSRT block `DontOfferThroughWUAU = 1`.
  - **Zero-Background-Scan Hardening**:
    - Enforces `DoNotConnectToWindowsUpdateInternetLocations = 1`, `DisableWindowsUpdateAccess = 1`, and `SetDisableUXWUAccess = 1`.
    - Forces all update services (`wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `dosvc`) to **Disabled (`Start = 4`)** and stopped.
    - Disables all scheduled scanner tasks in `\Microsoft\Windows\WindowsUpdate\*`, `\Microsoft\Windows\UpdateOrchestrator\*`, and `\Microsoft\Windows\WaaSMedic\*`.
    - Clears lingering update payload cache in `SoftwareDistribution\Download`.

---


## [v028] — 2026-10-31
### UI Streamlining, Live System Specs Header & Bulletproof Dism++ Windows Update Lockdown
- **UI Header Streamlining & Language Pill Cleanup**:
  - Removed redundant "Language:" label next to language pills in the top bar.
  - Retained "⏭ Пропустить шаг" (Skip Step) button on the action bar.
  - Renamed primary action button to **«Оптимизировать»** (EN: **«Optimize»**, CS: **«Optimalizovat»**) across top and bottom controls for a cleaner, more concise UI.
- **Top-Left System Specs Block («Данные о компьютере»)**:
  - Replaced generic static title with a real-time computer hardware and network anchor:
    - `Host: local | Устройство: <DeviceName> | Windows: <WindowsVersion> | IP: <IPAddress>`
    - Dynamic automatic network adapter detection (extracts active IPv4 address, ignores virtual/VPN interfaces).
- **Absolute Lockdown for Dism++ "Never check for updates (not recommended)" Parity**:
  - **Eliminated Automatic Update Rollback Bug**: Fixed root-cause issue where Windows Update Medic Service (`WaaSMedicSvc`) and Update Orchestrator (`UsoSvc`) reverted `AUOptions` from `1` to `4` (Automatic) because `wuauserv` was previously left in `Manual` (`Start=3`).
  - **Permanent Service Lockdown (`Start = 4`)**: Update services (`wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `dosvc`) are now strictly set to **`Disabled` (`Start = 4`)** and stopped.
  - **Dism++ Registry Parity**:
    - `AUOptions = 1` and `NoAutoUpdate = 1` enforced in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` and fallback `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update`.
    - `DoNotConnectToWindowsUpdateInternetLocations = 1` and `DisableWindowsUpdateAccess = 1` enforced.
    - Terminated all background updater worker processes (`MoUsoCoreWorker`, `UsoClient`, `wuauclt`, `WaaSMedic`, `SIHClient`).
    - Disabled background scheduled tasks in `WindowsUpdate`, `UpdateOrchestrator`, and `WaaSMedic`.
    - Integrated automatic check in startup self-healing and immediately following DISM operations so Dism++ always sees and stays on **«Не проверять (не рекомендуется)»**.

---

## [v027] — 2026-10-30
### Polyglot Hybrid CRLF Encoding Fix & Built-In Self-Healing Cleanup
- **CRLF Line Endings Enforcement for CMD Polyglot Execution**:
  - Fixed a critical batch script parsing failure where Unix `LF` line endings caused `cmd.exe` to desynchronize file pointer seek offsets, bypass the batch elevation block, and execute PowerShell logic as batch commands (spawning stray redirection files such as `v026)` and failing to launch).
  - Strictly normalized all line breaks throughout the script to standard Windows **CRLF (`\r\n`)** with UTF-8 BOM, ensuring clean, immediate CMD startup and background PowerShell GUI elevation.
- **Automated Turnkey Self-Healing (No External Scripts Required)**:
  - Embedded an autonomous environment cleanup block directly at script startup and within the Desktop finalization routine:
    1. **Purges phantom Desktop\NameSpace CLSID**: automatically deletes `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B7CD0BE5}` and related user CLSIDs, permanently clearing the blank ghost icon on any computer (local or client/work workstations).
    2. **Sweeps stray redirection artifacts**: automatically detects and deletes any lingering `v026)` or temporary files across the script directory and user Desktop.
    3. **Eliminates external fix utilities**: all remediation logic is 100% self-contained inside `GIN-Win-Optimizer_v027.cmd`.
- **Correct Explorer Libraries Navigation Pane Tweak**:
  - Accurately targets canonical GUID `{031E4825-7B94-4dc3-B131-E946B44C8DD5}` under `HKCU:\Software\Classes\CLSID` with `System.IsPinnedToNameSpaceTree = 0`.

---

## [v025] вЂ” 2026-10-29
### Dism++ Exact Parity for Windows Update
- **Windows Update 1-to-1 Dism++ Profile Alignment**:
  - Windows Update policies and registry keys now strictly replicate Dism++'s default optimization configuration:
    1. **Dropdown `*РќР°СЃС‚СЂРѕР№РєР° РїСЂРѕРІРµСЂРєРё РѕР±РЅРѕРІР»РµРЅРёР№ РІ Р¦РµРЅС‚СЂРµ РѕР±РЅРѕРІР»РµРЅРёР№` (`*Configure check for updates`)**:
       - Set to **`РќРµ РїСЂРѕРІРµСЂСЏС‚СЊ (РЅРµ СЂРµРєРѕРјРµРЅРґСѓРµС‚СЃСЏ)`** (`Never check for updates`).
       - Configured via Group Policy and CurrentVersion fallback: `AUOptions = 1`, `NoAutoUpdate = 1`, and `CachedAUOptions = 1` in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` and `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update`.
    2. **Toggle 1 `РђРІС‚РѕРјР°С‚РёС‡РµСЃРєРё СѓСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ РѕР±РЅРѕРІР»РµРЅРёСЏ Р±РµР· РїРµСЂРµР·Р°РіСЂСѓР·РєРё`**:
       - Configured strictly to **OFF (`0`)** via `AutoInstallMinorUpdates = 0` (resolved previous singular key typo).
    3. **Toggle 2 `РџСЂРё РѕР±РЅРѕРІР»РµРЅРёРё РІС‹РІРѕРґРёС‚СЃСЏ СѓРІРµРґРѕРјР»РµРЅРёРµ Рѕ РЅРµРѕР±С…РѕРґРёРјРѕСЃС‚Рё РїРµСЂРµР·Р°РіСЂСѓР·РєРё`**:
       - Configured strictly to **OFF (`0` / purged)** via removal of `NoAutoRebootWithLoggedOnUsers` (previously set to `1`).
    4. **Toggle 3 `Windows Update РЅРµ РІРєР»СЋС‡Р°РµС‚ РІ СЃРµР±СЏ РґСЂР°Р№РІРµСЂС‹`**:
       - Configured to **ON (`1`)** via `ExcludeWUDriversInQualityUpdate = 1` under `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`.
    5. **Toggle 4 `РћР±РЅРѕРІР»РµРЅРёРµ Windows РЅРµ РІРєР»СЋС‡Р°РµС‚ РІ СЃРµР±СЏ СЃСЂРµРґСЃС‚РІРѕ СѓРґР°Р»РµРЅРёСЏ РІСЂРµРґРѕРЅРѕСЃРЅС‹С… РїСЂРѕРіСЂР°РјРј`**:
       - Configured to **ON (`1`)** via `DontOfferThroughWUAU = 1` under `HKLM:\SOFTWARE\Policies\Microsoft\MRT`.
  - **Service State Preservation**: Update services (`wuauserv`, `dosvc`, `UsoSvc`) are set to **`Manual` (`Start = 3`)** rather than permanently disabled (`Start = 4`), ensuring Microsoft Store, AppX deployment, DISM operations, and manual check-for-updates remain fully functional without system-level breakage.
  - Purged aggressive artificial block `DoNotConnectToWindowsUpdateInternetLocations`.

---
## [v024] — 2026-10-27
### Smart Keyboard Hierarchy (EN > CS > RU), Regional Formats, Power/Sleep Timeouts & Wi-Fi Privacy
- **Smart Multilingual Keyboard Priority Hierarchy**:
  - Always enforces English (United States) `en-US` (`0409:00000409`) as #1 and the default system/user input language.
  - Dynamically evaluates if Czech keyboard layout (`cs-CZ` / `0405:00000405`) is installed in the system:
    - **If Czech is installed:** Sets English as #1, Czech as #2, and Russian (`ru-RU`) as #3.
    - **If Czech is NOT installed:** Sets English as #1, and Russian as #2.
  - Dual-layer enforcement: uses modern PowerShell `Set-WinUserLanguageList` and `Set-WinDefaultInputMethodOverride` with comprehensive registry fallbacks (`HKCU:\Keyboard Layout\Preload`, `HKCU:\Control Panel\International\User Profile\InputMethodOverride`, and `PreferredUILanguages`).
- **Russian Regional Data Format (ru-RU) & Date/Time Standards**:
  - Configures regional format to Russian (`ru-RU`) with Gregorian calendar.
  - Sets Monday as the first day of the week (`iFirstDayOfWeek = 0`).
  - Sets Short Date format to `dd.MM.yyyy` and Long Date to `d MMMM yyyy 'г.'`.
  - Sets 24-hour time formats: Short Time `HH:mm` and Long Time `HH:mm:ss`.
- **Power, Sleep & Screen Saver Timeouts**:
  - Turn off screen: `Never` (0) on battery power and `Never` (0) when plugged in.
  - Sleep timeout: `30 minutes` on battery power, `Never` (0) when plugged in.
  - Screen Saver: `10 minutes` (600 seconds) timeout, lock on resume disabled (`ScreenSaverIsSecure = 0`).
- **Wi-Fi Privacy & Hotspot 2.0 Hardening**:
  - Disables Random Hardware Addresses (MAC Randomization) in `HKLM:\SOFTWARE\Microsoft\WlanSvc\Anonymization` and across all Wi-Fi interfaces.
  - Disables Hotspot 2.0 (Passpoint) Online Sign-Up (OSU) registration in `HKLM:\SOFTWARE\Microsoft\WlanSvc\AnqpCache` (`OsuRegistrationStatus = 0`).
  - Disables randomization parameter across all stored wireless network profiles.
- **Xbox Game Bar & Controller Shortcut Deactivation**:
  - Disables Xbox Game Bar recording / DVR (`AppCaptureEnabled = 0`, `GameDVR_Enabled = 0`, `AllowGameDVR = 0`).
  - Disables opening Xbox Game Bar via controller Xbox button (`UseNexusForGameBarEnabled = 0`).
- **106 Active Optimization Modules & Full Trilingual GUI**:
  - Expands module count to 106 granular checkboxes with trilingual support (EN / CS / RU).

---

## [v023] — 2026-10-26
### Array Boundary Hardening on Shell Folders
- Resolved fixed-size array Add exception during Documents and Desktop relocation.
- Version increment to v023.

---

## [v022] — 2026-10-26
### Czech Region, Timezone & Auto-DST
- Added Czech Republic region (GeoId 75), TimeZone (Prague, UTC+1, W. Europe Standard Time) with automatic daylight saving time (DST).
- Version increment to v022.

---

## [v021] — 2026-10-26
### Autonomous Reboot Elimination, Safe Folder Migration & People/IE Purge
- **No Automatic Reboot & Dedicated Bright 'Reboot' Button**:
  - Removed automatic reboot and modal Yes/No reboot prompt from optimization completion.
  - Added a high-visibility, bright red `⚡ REBOOT` (`#dc2626` / `#ff4d4f`) button directly into the Top Header and Bottom Action Bar.
  - User retains 100% control to inspect terminal logs indefinitely and reboot whenever ready via explicit confirmation dialog.
- **Safe, Zero-Error Documents & Desktop Migration (D:\DOCS & D:\DOCS\desktop)**:
  - Completely replaced Robocopy `/MOVE` on root user profile directories with safe PowerShell file enumeration and per-item migration.
  - Prevents retry loops, access denied errors on hidden OS junctions, and directory lock conflicts.
  - Safely creates `D:\DOCS` and `D:\DOCS\desktop`, updates registry (`User Shell Folders` and `Shell Folders`), removes stray `desktop.ini`, and notifies shell.
- **Permanent People Button Purge on Windows 10 & 11**:
  - Fully enforces `HidePeopleBar = 1` in both user and machine Policies (`HKCU` and `HKLM`).
  - Pre-creates `Explorer\Advanced\People` key if absent and sets `PeopleBand = 0` and `ShowTaskbarPinPople = 0`.
- **Complete Unpin & Removal of Internet Explorer**:
  - Automatically purges all Internet Explorer `.lnk` shortcuts from User Pinned Taskbar, Start Menu, User Desktop, and Public Desktop.
  - Sets policy `NotifyDisableIEOptions = 1` and hides legacy IE desktop namespace icons.

---

## [v020] — 2026-10-26
### Yellow Highlighted Shell Folders Relocation & Immediate System Restart
- **Yellow Highlighted Shell Folder Relocation Options (Top of Explorer/Desktop Section)**:
  - Added 2 prominent checkboxes styled in bright yellow (`#facc15`, bold, amber border `#eab308` with dark background `#231f08`):
    - `chk_reloc_documents`: Relocates Documents folder to `D:\DOCS`.
    - `chk_reloc_desktop`: Relocates Desktop folder to `D:\DOCS\desktop`.
  - **OFF by default** and excluded from automatic presets (`Select All`, `Office`, `Gaming`) to ensure relocation only occurs when explicitly desired.
  - Automatically verifies existence of drive `D:\` before execution to prevent data loss.
  - Safely migrates existing files via robocopy, updates `User Shell Folders` and `Shell Folders` registry keys, purges stray `desktop.ini`, and triggers shell notification (`SHChangeNotify`).
  - Records redirection paths and timestamps in `HKLM:\SOFTWARE\GIN-Win-Optimizer`.
- **Integrated System Restart Button & Completion Prompt**:
  - Added dedicated high-contrast `🔄 RESTART PC` buttons (`btnRestartTop` and `btnRestartBottom`) in the top header and bottom action bar.
  - Buttons automatically reveal upon optimization completion so the user can inspect logs and reboot at will.
  - Completion dialog converted to interactive `Yes/No` prompt offering immediate reboot to apply shell and registry redirections.

---

## [v019] — 2026-10-26
### Smart Redundancy Elimination & Registry State Markers
- **Smart CompactOS State Detection & Avoidance of Redundant Compression**:
  - Dynamically evaluates system compression state via `compact.exe /CompactOS:query`. If Windows binaries are already in the compressed state (`Compact state: always`), the optimizer informs the user and skips redundant re-compression, protecting SSD lifespan and saving 5-15 minutes.
  - Automatically records state flag and timestamps in `HKLM:\SOFTWARE\GIN-Win-Optimizer`.
- **SFC Scannow Made Optional & Highlighted**:
  - `chk_deep_sfc_compact` moved to the top alongside the 2 heavy DISM tasks (now forming a 3-item maintenance block).
  - Highlighted in bright red (`#ff4d4f`) and Bold, marked `(slow - медленно)`.
  - Set to **OFF by default** across all presets (`Select All`, `Office`, `Gaming`).
  - Records verification timestamp (`LastSfcScan`) in `HKLM:\SOFTWARE\GIN-Win-Optimizer`.

---

## [v018] — 2026-10-26
### UI & Performance Refinement
- **Highlight Longest Maintenance Operations in Bright Red**:
  - The two slowest system maintenance tasks (`chk_deep_dism_repair` - DISM RestoreHealth and `chk_deep_dism_resetbase` - WinSxS ResetBase) are moved to the **very top** of the cleaning group (`grpClean`).
  - Formatted with high-visibility bright red color (`#ff4d4f`) and bold font weight (`FontWeight="Bold"`).
  - Explicitly marked with warning tag `(slow - медленно)` across all three supported languages (Russian, English, Czech).
  - Set to **OFF by default** (`IsChecked = False`) and excluded from standard presets (`Select All`, `Office`, `Gaming`) to prevent accidental multi-hour maintenance runs unless explicitly checked by the user.

---

## [v017] — 2026-10-26
### Critical Fixes & Taskbar Hardening
- **Unpin Internet Explorer & Edge from Taskbar (`chk_edge_unpin`)**:
  - Automatically clears pinned shortcuts from `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\`.
  - Invokes programmatic shell unpin verbs from virtual Applications folder (`shell:::{4234d49b-0245-4df3-b780-3893943456e1}`) to guarantee removal of legacy Internet Explorer and Microsoft Edge taskbar buttons on clean Windows installations.
  - Blocks automatic taskbar re-pinning via Group Policies: `DoNotCreateTaskbarShortcutOnFirstRun = 1` for Edge and Internet Explorer.
- **Permanent "This PC" / "Мой компьютер" Desktop Icon & Shortcut Guarantee (`chk_ui_show_this_pc`)**:
  - Enforces `HideDesktopIcons` across all 4 system keys (HKCU and HKLM `NewStartPanel` and `ClassicStartMenu` with `{20D04FE0-3AEA-1069-A2D8-08002B30309D} = 0`).
  - Creates a permanent system shell shortcut `Этот компьютер.lnk` / `This PC.lnk` directly on the user Desktop, public Desktop, and synchronized cloud Desktop (`D:\MEGA\DOCS\desktop`), ensuring it never vanishes even if Explorer shellbags are purged or reset.
- **Reliable Taskbar People Band Elimination (`chk_tb_hide_people`)**:
  - Enforces `PeopleBand = 0` in `HKCU\...\Advanced\People` (creating missing registry parent keys with `-Force`).
  - Applies strict system Group Policies `HidePeopleBar = 1` in both `HKCU` and `HKLM\Software\Policies\Microsoft\Windows\Explorer`.
- **Automatic Clean Explorer Restart**:
  - Automatically reloads `explorer.exe` at the end of optimization to instantly activate taskbar unpinning, People button removal, tray icons display, and desktop icons without requiring a manual sign-out or reboot.

---

## [v016] — 2026-10-26
### Added & Improved
- **Global Explorer Folder View & Sort (`chk_ui_folder_view_list_sort_type`)**:
  - Sets default folder view template globally to **List** (`Список` / `Mode = 3`, `LogicalViewMode = 4`) and default sorting to **Type** (`По типу` / `SortByList = prop:System.ItemTypeText;System.ItemNameDisplay`).
  - Configures master `AllFolders\Shell` and standard `FolderTypes` templates (Generic, Documents, Pictures, Music, Videos, Downloads), clearing unwanted date groupings (`GroupBy = ""`) and obsolete per-folder `ShellBags` cache so all existing and newly opened folders immediately open in List view sorted by Type.
- **Enhanced Always Show System Tray Icons (`chk_ui_show_all_tray_icons`)**:
  - Full support for both Windows 10 and Windows 11 taskbars.
  - Windows 10: Disables auto-tray chevron overflow (`EnableAutoTray = 0`, Policy `NoAutoTray = 1`).
  - Windows 11: Promotes all registered tray application icons directly to taskbar (`NotifyIconSettings\*` `IsPromoted = 1`).
- **Strictly Sequential Disk Cleanup (Drive C: then Drive D:)**:
  - Completely resolved concurrent dialog overlap. Standard Windows Disk Cleanup (`cleanmgr.exe /autoclean /d C:`) runs first for Drive C: and waits for full completion.
  - Only after Drive C: is 100% finished, if Drive D: exists, runs (`cleanmgr.exe /autoclean /d D:`) and waits for full completion. Never runs both concurrently.
- **Clean Language Switcher Buttons (RU, EN, CZ)**:
  - Replaced broken emoji flags (which rendered as dotted square boxes on Windows 10) with clean, high-contrast, bold text badges: `RU`, `EN`, `CZ`.
- **High-Contrast Dark Theme Disabled Button Styling**:
  - Added custom WPF `ControlTemplate` with triggers for `IsEnabled="False"`.
  - Replaced Windows default blinding light-grey disabled background and invisible white text with dark slate background (`#1c1f26`), subtle border (`#2e323b`), and clear readable muted text (`#94a3b8`).

---

## [v015] — 2026-10-26
### Critical Fixes & Security Hardening
- **Windows Update Silent Auto-Start Elimination**: Removed automatic restart of `wuauserv` (`Start-Service wuauserv`) during `SoftwareDistribution\Download` cache cleanup. Previously, restarting the service triggered background worker processes (`MoUsoCoreWorker`, `UsoClient`) and unwanted multi-gigabyte update downloads.
- **Added Full Windows Update Disabler (`chk_wu_disable_auto_updates`)**:
  - Immediately terminates active background update workers (`MoUsoCoreWorker`, `UsoClient`, `wuauclt`).
  - Completely stops and permanently disables Windows Update services: `wuauserv`, `UsoSvc` (Update Orchestrator Service), `dosvc` (Delivery Optimization), and `WaaSMedicSvc` (Windows Update Medic Service).
  - Configures strict Group Policies in Registry: `NoAutoUpdate = 1`, `AUOptions = 1` (Never check for updates), `AutoInstallMinorUpdate = 0`, and `DoNotConnectToWindowsUpdateInternetLocations = 1`.
  - Disables scheduled tasks in Task Scheduler (`\Microsoft\Windows\WindowsUpdate\*`, `\Microsoft\Windows\UpdateOrchestrator\*`, and `\Microsoft\Windows\WaaSMedic\*`).
  - Enabled by default in all standard presets. Updates are now strictly manual.

## [v014] — 2026-10-25
### Changed & Rebranded
- **Official Rebranding**: Project officially renamed from `WIN_Optimizator` to **`GIN-Win-Optimizer`** across all repositories, metadata, titles, and installers.
- **Repository Standardization**: Reorganized under dedicated project directory `Windows/GIN-Win-Optimizer/` in both private (`Secret_Privat`) and public (`Windows_scripts`) repositories.
- **Synchronized Deploy Targets**: Updated targets in MEGA Desktop and MEGA Win-Flash to `GIN-Win-Optimizer_v014.cmd`.

---

## [v013] — 2026-10-25
### Fixed & Improved
- **Fixed Silent Exit / Process Termination**: Replaced thread-pool asynchronous output reading (`proc.BeginOutputReadLine`) in `Invoke-ProcessWithLiveOutput` with single-threaded dispatcher polling (`Peek()` / `ReadLine()`). Completely eliminates `PSInvalidOperationException` concurrent pipeline collisions in PowerShell 5.1 during `cleanmgr`, `dism`, and `sfc` execution.
- **Persistent Results Log**: The optimizer window strictly remains open upon completion. Both progress bars settle at 100%, and the full scrollable terminal log is retained with all individual task statuses. Users can inspect, copy, or export the log before manual exit.
- **Dual Low-Pitch Confirmation Beep**: Integrated direct Win32 `kernel32.dll!Beep(320, 180)` and `Beep(320, 220)` tones (320 Hz, warm low-pitch sound, easily audible across all speakers and headphones).
- **Windows 11 Taskbar Decluttering & Live Reload**:
  - Completely hides Search box/icon (`SearchboxTaskbarMode = 0`), Widgets/News (`TaskbarDa = 0`, `Feeds = 2`), Task View (`ShowTaskViewButton = 0`), Chat (`TaskbarMn = 0`, `ChatIcon = 3`), and Copilot (`ShowCopilotButton = 0`).
  - Settings applied across `HKCU`, `HKLM`, and all user profile hives in `HKEY_USERS`.
  - Automatically triggers safe live restart of `explorer.exe` upon finishing, instantly applying taskbar changes without needing a full system reboot.

---

## [v012] — 2026-10-25
### Added
- **Sequential Disk Cleanup Queue**: Implemented mutual exclusion lock detection for Windows Update and `cleanmgr` instances to prevent concurrent disk deadlocks.
- **Clean Desktop Guarantee**: Added automated cleanup of stray `desktop.ini` files from user and public desktop locations.
- **Trilingual Dictionary Expansion**: Enhanced Czech and Russian translations across all 10 module groups.

---

## [v011] — 2026-10-24
### Added
- **Polyglot WPF Hybrid GUI**: Transformed console-based batch script into a unified, dark-themed WPF single-window graphical user interface with live terminal emulator and real-time progress indicators.
- **Language Switcher**: Added runtime trilingual switcher (English, Čeština, Русский).

---

## [v009] — 2026-10-15
### Added
- **Dism++ Tweak Integration**: Incorporated 97 deep optimization policies covering telemetry, UAC silent mode, Edge debloating, and SSD longevity tuning.

---

## [v008] — 2026-10-01
### Initial Release
- Core Windows 10/11 system maintenance, temp cache removal, and basic debloater routines.

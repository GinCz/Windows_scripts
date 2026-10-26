# 📜 GIN-Win-Optimizer — Release History & Changelog

All notable changes to the **GIN-Win-Optimizer** project are documented in this file.

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

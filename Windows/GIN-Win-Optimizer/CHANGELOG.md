# 📜 GIN-Win-Optimizer — Release History & Changelog

All notable changes to the **GIN-Win-Optimizer** project are documented in this file.

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
- **Official Rebranding**: Project officially renamed from `WIN_Optimizator` to **`GIN-Win-Optimizer`** across all public repositories, metadata, titles, and installers.
- **Repository Standardization**: Reorganized under dedicated project directory `Windows/GIN-Win-Optimizer/`.
- **Packaging**: Distributed as standalone executable hybrid script `GIN-Win-Optimizer_v014.cmd`.

---

## [v013] — 2026-10-25
### Fixed & Improved
- **Fixed Silent Process Exit**: Replaced thread-pool asynchronous output reading (`proc.BeginOutputReadLine`) in `Invoke-ProcessWithLiveOutput` with single-threaded dispatcher polling (`Peek()` / `ReadLine()`). Completely eliminates `PSInvalidOperationException` concurrent pipeline collisions in PowerShell 5.1 during `cleanmgr`, `dism`, and `sfc` execution.
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

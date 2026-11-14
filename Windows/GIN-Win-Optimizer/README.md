# 🔒 GIN-Win-Optimizer — Master Repository

> **Private Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Public Mirror:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Architect & Author:** Vladimir Bulantsev ([@GinCz ↗](https://github.com/GinCz)) & AI [VladiMIR + AI]  
> **Target Operating Systems:** Windows 7 / 8 / 8.1 / 10 / 11 (Universal x86 32-bit & x64 64-bit, all editions)  
> **Current Version:** `v048` (Active Production)  
> **Retention Policy:** Strictly **2 latest production versions** (`GIN-Win-Optimizer_v048.cmd` and `GIN-Win-Optimizer_v047.cmd`).  
> **Release History:** Complete technical changelog available in [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/CHANGELOG.md)

---

## 🚀 Overview & Architectural Philosophy

**GIN-Win-Optimizer** is an enterprise-grade, turnkey Windows optimization, debloating, and system-hardening suite engineered for corporate workstations, developer rigs, and personal PCs.

Built upon a robust **single-standard polyglot CMD architecture**, the optimizer requires **zero compilers, zero third-party runtimes, and zero binary installations**. It executes seamlessly across all modern Windows installations (Windows 7 SP1 through Windows 11 24H2) without triggering SmartScreen warnings, Antivirus heuristics, or "Unknown Publisher" friction.

---

## ⚡ Key Highlights of Recent Releases

### 🛡️ Release v048 — Windows Defender High-Performance Exclusions
- **Remote Network Shares (SMB / UNC)**: Exempts `\\s.gincz.com\soft`, `\\s.gincz.com\user`, `\\s.gincz.com\Storage`, `\\p.gincz.com\soft`, `\\152.53.182.222\soft`, `\\152.53.182.222\storage` from real-time network scanning, eradicating 10–30s Windows Explorer freezes and transfer lag over VPN/WAN links.
- **Local Dev & Admin Workspaces**: Exempts `D:\UTIL`, `C:\UTIL`, `D:\AI` (Git repos, Python virtualenvs, AI weights), `D:\MEGA` (cloud sync repository), `C:\GIN-Agent`, `C:\GIN-Agent-PC`.
- **High-I/O Process Exclusions**: Adds process exemptions for `git.exe` (3–5x faster repository operations) and `MEGAsync.exe` (eliminates 20–50% background CPU thrashing by `MsMpEng.exe`).
- **Catalog Expanded**: Total active optimization modules increased to **115**.

### 🧹 Release v047 — OEM & Driver Bloatware Purge
- **Lenovo ImController & System Interface Foundation Purge**: Auto-detects manufacturer; if non-Lenovo, deletes `ImControllerService`, `LenovoVantageService`, scheduled tasks, and `C:\Windows\Lenovo`; on native Lenovo devices, disables background services and scheduled tasks to prevent RAM/CPU waste.
- **Intel Graphics Context Menu & Rotation Hotkeys Removal**: Strips `igfxDTCM`, `igfxCUI` context menu clutter, disables accidental screen rotation hotkeys (`Ctrl+Alt+Arrows`) and tray icon.
- **Intel HD Graphics Background Services Disabling**: Stops and disables `igfxCUIService`, `LMS`, `cphs`, `jhi_service`, and cleans autorun registry keys.
- **Conexant Audio Background Services Disabling**: Stops and disables all `Cx*` services (`CxAudioSvc`, `CxUIUSvc`, `CxUtilSvc`), completely eliminating high CPU usage and handle leaks while preserving standard Windows audio.

### 🎨 Release v046 — Terminal Completion Highlighting & Silent UAC
- **Terminal Log Completion Highlighting**: Upgraded log control to a high-performance WPF `RichTextBox` with zero-margin paragraph styling, formatting the final completion banner in bold, vibrant yellow/gold (`#facc15`).
- **Status Bar Highlight**: Bottom status bar text dynamically highlights in bold yellow upon successful completion of all optimization tasks.
- **Silent UAC (Slider to Minimum: "Never Notify")**: Enforces `EnableLUA = 0` / minimum notification slider, eliminating all yellow elevation prompts.

---

## 📜 Complete Version History & Milestones

The table below summarizes the evolution of **GIN-Win-Optimizer**. For deep technical specifications on any version, consult [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/CHANGELOG.md).

| Version | Release Date | Core Milestone / Focus Area | Active Modules | Status |
| :---: | :---: | :--- | :---: | :---: |
| **v048** | 2026-11-14 | Windows Defender High-Performance Exclusions (Network Shares, Dev Workspaces, git.exe, MEGAsync.exe) | 115 | 🟢 Current Production |
| **v047** | 2026-11-14 | OEM & Driver Bloatware Purge (Lenovo ImController, Intel Graphics hotkeys/services, Conexant Audio) | 114 | 🟢 Retained Baseline |
| **v046** | 2026-11-05 | WPF RichTextBox Terminal Log & Vibrant Yellow Completion Banner Highlighting | 110 | ⚪ Archived |
| **v045** | 2026-11-05 | Comprehensive Total Zero-UAC Enforcement (`EnableLUA=0`, Slider to Absolute Zero) | 110 | ⚪ Archived |
| **v044** | 2026-11-05 | Critical CMD Launcher Header Restoration & Batch Syntax Integrity | 110 | ⚪ Archived |
| **v043** | 2026-11-05 | Critical Parser Syntax Bug Fix (Token AST ParseException Resolution) | 110 | ⚪ Archived |
| **v042]** | 2026-11-05 | Universal UAC Slider to Absolute Minimum ("Never Notify") & Network Drive Retention | 110 | ⚪ Archived |
| **v041** | 2026-11-05 | Critical Fix for Network Drives (`LanmanWorkstation ServiceDll` Expand-String Fix) | 110 | ⚪ Archived |
| **v040** | 2026-11-05 | Single-Standard Portable CMD Polyglot Architecture Standardized (EXE Purged) | 110 | ⚪ Archived |
| **v039** | 2026-11-04 | Critical Operator Syntax Bug Fix (`+=` initialization in LAN Discovery block) | 110 | ⚪ Archived |
| **v038** | 2026-11-04 | Ultralightweight CMD Architecture, LAN File Sharing Protection & Static Pagefile Fixation | 110 | ⚪ Archived |
| **v036** | 2026-11-03 | 93% Executable Footprint Shrink (2.45 MB ➔ 174 KB) via Native Win32 Launcher | 110 | ⚪ Archived |
| **v035** | 2026-11-03 | Fullscreen Maximized Window Mode by Default (`WindowState="Maximized"`) & PE Metadata | 110 | ⚪ Archived |
| **v034** | 2026-11-03 | Standalone Native Win32 GUI Executable, Multi-Resolution Icon & Named Mutex | 110 | ⚪ Archived |
| **v033** | 2026-11-02 | Autonomous Start Menu Legacy Applet Purge Engine & Post-Servicing Sweep | 110 | ⚪ Archived |
| **v032** | 2026-11-02 | Hardware-Adaptive Elastic Pagefile Optimizer, Dark Steel Blue Theme & Inverted Large Cursor | 110 | ⚪ Archived |
| **v031** | 2026-11-01 | Native Performance Options "Adjust for Best Appearance" Full-Spectrum Default Preset | 106 | ⚪ Archived |
| **v030** | 2026-10-31 | Native `reg.exe` Dism++ Lockdown & LayoutModification Empty PinList Protection | 105 | ⚪ Archived |
| **v029** | 2026-10-31 | Permanent Taskbar Edge & IE Eradication via Shell COM Verbs & PIDL Cleanup | 105 | ⚪ Archived |
| **v028** | 2026-10-31 | UI Streamlining, Live System Specs Header & Windows Update Service Lockdown | 105 | ⚪ Archived |
| **v027** | 2026-10-30 | Polyglot Hybrid Windows CRLF Line Endings Enforcement & Turnkey Self-Healing | 105 | ⚪ Archived |
| **v025** | 2026-10-29 | Dism++ 1-to-1 Parity for Windows Update Lockdown ("Never check for updates") | 105 | ⚪ Archived |
| **v024** | 2026-10-27 | Smart Keyboard Layout Hierarchy (EN > CS > RU), Regional Formats & Wi-Fi Privacy | 105 | ⚪ Archived |
| **v023** | 2026-10-26 | Array Boundary Hardening on Shell Folders Redirection (`System.Collections.Generic.List`) | 104 | ⚪ Archived |
| **v022** | 2026-10-26 | Czech Republic Region (GeoId 75), Prague Timezone & Automatic Daylight Saving Time | 104 | ⚪ Archived |
| **v021** | 2026-10-26 | Autonomous Reboot Elimination (Live Explorer Restart), Shell Folder Migration to D: | 104 | ⚪ Archived |
| **v020** | 2026-10-26 | Visual Highlighting for Shell Folders Relocation & Verification Pre-Checks | 102 | ⚪ Archived |
| **v019** | 2026-10-26 | Smart Redundancy Elimination & Registry State Markers (`HKLM:\SOFTWARE\GIN-Win-Optimizer`) | 102 | ⚪ Archived |
| **v018** | 2026-10-26 | UI & Performance Refinement, Heavy Task High-Contrast Red Warning Tags | 102 | ⚪ Archived |
| **v017** | 2026-10-26 | Unpin Edge/IE from Taskbar, Permanent "This PC" Desktop Icon Guarantee & People Purge | 102 | ⚪ Archived |
| **v016** | 2026-10-26 | Global Explorer Folder View & Sort Standard (List view by Type), System Tray Promotion | 101 | ⚪ Archived |
| **v015** | 2026-10-26 | Windows Update Silent Auto-Start Elimination & Full Disabler Module (`wuauserv`, `UsoSvc`) | 100 | ⚪ Archived |
| **v014** | 2026-10-25 | Official Project Rebranding to `GIN-Win-Optimizer` & Repository Structure Standardization | 98 | ⚪ Archived |
| **v013** | 2026-10-25 | Single-Threaded Dispatcher Polling Overhaul, Persistent Log & Windows 11 Taskbar Declutter | 98 | ⚪ Archived |
| **v012** | 2026-10-25 | Sequential Disk Cleanup Queue (Drive C: then D:), Clean Desktop Guarantee (`desktop.ini`) | 97 | ⚪ Archived |
| **v011** | 2026-10-24 | Modern WPF Dark-Themed GUI Engine with Live Terminal & Trilingual Switcher (EN, CS, RU) | 97 | ⚪ Archived |
| **v009** | 2026-10-15 | Dism++ Registry Optimization Integration (97 policies covering telemetry and SSD life) | 97 | ⚪ Archived |
| **v008** | 2026-10-01 | Initial Genesis Release: Core Windows Maintenance, Cache Purge & Basic Debloater | 25 | ⚪ Archived |

---

## 🛠️ Functional Module Categories (115 Active Modules)

### 1. Security & UAC Hardening
- **Total Zero-UAC (`chk_sec_uac_quiet`)**: Silences all elevation confirmation dialogs (`EnableLUA = 0`, `ConsentPromptBehaviorAdmin = 0`, `PromptOnSecureDesktop = 0`, `FilterAdministratorToken = 0`).
- **Windows Defender High-Performance Exclusions (`chk_sec_defender_exclusions`)**: Automatic exclusion of trusted remote shares, admin/dev directories (`UTIL`, `AI`, `MEGA`), and high-I/O processes (`git.exe`, `MEGAsync.exe`).
- **Download Warning Bypass**: Disables "Open File - Security Warning" for downloaded files (`LowRiskFileTypes`).
- **SmartScreen Disabling**: Disables Windows Defender SmartScreen telemetry and execution prompts.

### 2. Network & File / Printer Sharing Protection
- **Active Network Profile to Private**: Converts public connections to Private (`Category = 1`), enabling LAN firewall exceptions.
- **Guest SMB Share Access (`AllowInsecureGuestAuth = 1`)**: Enables LanmanWorkstation guest authentication for NAS, Samba, and network router shares.
- **Admin Mapped Drives (`EnableLinkedConnections = 1`)**: Ensures mapped network drives remain accessible to elevated processes.
- **UNC Path Execution (`DisableUNCCheck = 1`)**: Disables UNC validation warnings when executing scripts directly from network shares.
- **Core LAN Services Auto-Start**: Enforces automatic startup for `FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `Spooler`, `lmhosts`, and `Dnscache`.

### 3. Memory & Hardware Performance Optimization
- **Elastic Pagefile Optimizer Engine (`chk_srv_pagefile_auto`)**: Adapts virtual memory paging dynamically based on physical RAM capacity.
- **Static Pagefile Fixation**: Locks a 4096–8192 MB paging file on drive `C:` to prevent out-of-virtual-memory crashes.
- **Hibernation Disabling (`powercfg -h off`)**: Removes `hiberfil.sys`, recovering 4 to 16 GB of SSD storage.
- **Visual Effects Tuning**: Retains crisp font smoothing (`FontSmoothing = 2`) while eliminating sluggish minimize/maximize delays (`MinAnimate = 0`, `MenuShowDelay = 100`).

### 4. OEM & Driver Bloatware Neutralization
- **Lenovo ImController Purge (`chk_srv_oem_lenovo`)**: Auto-detects manufacturer and eradicates Lenovo services, scheduled tasks, and directories on non-Lenovo hardware.
- **Intel Graphics Menu & Hotkeys (`chk_ctx_intel_graphics`)**: Purges context menu clutter, disables rotation hotkeys (`Ctrl+Alt+Arrows`) and tray icon.
- **Intel HD Graphics Services (`chk_srv_intel_graphics`)**: Disables `igfxCUIService`, `LMS`, and background helper modules.
- **Conexant Audio Services (`chk_srv_conexant_audio`)**: Disables `Cx*` background services to eliminate CPU leaks.

### 5. Windows Update & Servicing Lockdown (Dism++ Standard)
- **Never Check for Updates (`AUOptions = 1`)**: Permanent registry lockdown preventing spontaneous update downloads.
- **Service Neutralization**: Disables `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, and `dosvc`.
- **Driver Exclusions**: Prevents Windows Update from replacing vendor graphics, audio, or network drivers.
- **MRT Exclusion**: Excludes Malicious Software Removal Tool from monthly updates.

### 6. Explorer & UI Personalization
- **Global List View Sorted by Type (`chk_ui_folder_view_list_sort_type`)**: Sets all folder view templates to List view sorted by Type.
- **Always Show Notification Tray Icons (`chk_ui_show_all_tray_icons`)**: Windows 10/11 system tray promotion.
- **Taskbar Decluttering**: Hides Search, Widgets, Task View, Teams Chat, and Copilot.
- **Permanent "This PC" Desktop Icon**: Deploys system shell registry keys and desktop shortcut fallback.
- **Dark Theme & Steel Blue Accent (`#FF9A5F2D`)**: Dark system theme with custom accent color.
- **Inverted Large Cursor Scheme**: High-contrast inverted pointer scheme with drop shadow.

### 7. Safe System Cleanup & Component Servicing
- **Temporary Files & Update Caches**: User `%TEMP%`, system `%SystemRoot%\Temp`, and `SoftwareDistribution\Download`.
- **Sequential Disk Cleanup**: Sequential Drive C: and Drive D: cleanups without concurrent collisions.
- **Component Store Cleanup (DISM)**: WinSxS component store reduction and image health restoration (optional slow mode).

---

## 🖥️ Target Deployment Environments

| Environment / Medium | Target Path | Target Version | Active Retention |
| :--- | :--- | :---: | :---: |
| 💾 **USB Flash Drive (Ventoy)** | `V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v048.cmd` | v048 | Strictly 2 latest versions |
| ☁️ **MEGA Win-Flash Mirror** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v048.cmd` | v048 | Strictly 2 latest versions |
| 💻 **Vladimir's Desktop (Primary)** | `D:\MEGA\DOCS\desktop\GIN-Win-Optimizer_v048.cmd` | v048 | Strictly 2 latest versions |
| 🔒 **Private Git Repository** | `Secret_Privat/Windows/GIN-Win-Optimizer/` | v048 | Full Git history |
| 🌐 **Public Git Repository** | `Windows_scripts/Windows/GIN-Win-Optimizer/` | v048 | Full Git history |

---

## 📦 Delivery & Execution Instructions

1. **Autonomous Elevation**: Double-clicking `GIN-Win-Optimizer_v048.cmd` automatically checks for administrative privileges and elevates itself via native UAC `RunAs` without modal prompts.
2. **Network Share Execution**: When launched from UNC network shares (`\\server\share\GIN-Win-Optimizer_v048.cmd`), the script automatically stages itself to `%TEMP%` to prevent CMD working directory execution warnings.
3. **Turnkey Execution**: Select preset (**Select All**, **Office**, or **Gaming**) and click **Optimize** (or **Optimalizovat**). The terminal emulator outputs live progress, followed by acoustic confirmation chimes upon completion.

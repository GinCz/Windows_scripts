# ⚡ GIN-Win-Optimizer — Windows 7 / 8 / 10 / 11 Ultimate Optimizer

[![Download Latest Production Release](https://img.shields.io/badge/📥_DOWNLOAD-GIN--Win--Optimizer_v050.cmd_(LATEST)-00C853?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd)
[![View Script on GitHub](https://img.shields.io/badge/💻_VIEW_ON_GITHUB-GIN--Win--Optimizer_v050.cmd-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd)

[![Version](https://img.shields.io/badge/Version-v050_(Latest_Production)-00E676.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)
[![Platform](https://img.shields.io/badge/Platform-Windows_7_|_8.1_|_10_|_11_|_Server-0078D6.svg?style=flat-square&logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Architecture](https://img.shields.io/badge/Arch-Universal_x86_|_x64-0284C7.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts)
[![Modules](https://img.shields.io/badge/Catalog-115_Active_Modules-FF6D00.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts)
[![UI](https://img.shields.io/badge/UI-Modern_WPF_XAML_(Maximized)-7C3AED.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-Freeware_%7C_100%25_Free-76FF03.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts)

> **Architect & Author:** Vladimir Bulantsev ([@GinCz](https://github.com/GinCz)) & AI [VladiMIR + AI]  
> **Public Repository:** [Windows_scripts / Windows / GIN-Win-Optimizer](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Private Master Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Target Operating Systems:** Windows 7 / 8 / 8.1 / 10 / 11 / Windows Server (32-bit x86 & 64-bit x64, all editions)  
> **Current Version:** `v050` (Active Production)  
> **Active Retention Policy:** Strictly **2 latest production versions** (`GIN-Win-Optimizer_v050.cmd` and `GIN-Win-Optimizer_v049.cmd`)  
> **Release History:** Complete technical changelog available in [CHANGELOG.md](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/CHANGELOG.md)

---

## 📥 Quick Download & Fast Launch

### Direct Download Links

| Release | File | Size | Direct Download Button | Web UI |
| :--- | :--- | :---: | :---: | :---: |
| 🟢 **Latest (Recommended)** | `GIN-Win-Optimizer_v050.cmd` | ~294 KB | [**📥 Download v050**](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd) | [View v050 Code](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd) |
| ⚪ **Previous Stable** | `GIN-Win-Optimizer_v049.cmd` | ~290 KB | [**📥 Download v049**](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v049.cmd) | [View v049 Code](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v049.cmd) |

---

### ⚡ 1-Click Terminal Download Commands

#### Option A: PowerShell (Run as Administrator)
Download directly to your Desktop and run immediately:
```powershell
$path = "$([Environment]::GetFolderPath('Desktop'))\GIN-Win-Optimizer_v050.cmd"
Invoke-WebRequest -Uri "https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd" -OutFile $path
Start-Process $path
```

#### Option B: Command Prompt (CMD)
```cmd
curl -fLo "%USERPROFILE%\Desktop\GIN-Win-Optimizer_v050.cmd" "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_v050.cmd"
start "" "%USERPROFILE%\Desktop\GIN-Win-Optimizer_v050.cmd"
```

---

## 🚀 Overview & Architectural Philosophy

**GIN-Win-Optimizer** is an enterprise-grade, turnkey Windows optimization, debloating, and system-hardening suite engineered for corporate workstations, developer rigs, and personal PCs.

Built upon a robust **single-standard polyglot CMD architecture**, the optimizer requires **zero compilers, zero third-party runtimes, and zero binary installations**. It executes seamlessly across all modern Windows installations (Windows 7 SP1 through Windows 11 24H2) without triggering SmartScreen warnings, Antivirus heuristics, or "Unknown Publisher" friction.

---

## ⚡ Key Highlights of Recent Releases

### 🔔 Release v050 — Universal System Tray Unhiding & Multi-User Icon Promotion
- **Multi-User Icon Promotion Engine**: Scans and enforces `IsPromoted = 1` across all registered application subkeys under `Control Panel\NotifyIconSettings` for **all user profiles** in `HKEY_USERS` (`S-1-5-21-*`) and the default template, resolving elevation isolation issues where icons were previously only promoted for the elevated Administrator token.
- **Universal Auto-Tray Policies**: Enforces `NoAutoTray = 1` in `HKLM` and `HKCU` Policies, alongside `EnableAutoTray = 0` across all hives, completely eradicating the hidden icon chevron across Windows 10 and 11.
- **Persistent Logon Hook**: Registers `GIN-PromoteTrayIcons` in `HKLM Run` to ensure any newly added application icons stay visible without manual dragging.

### 🔍 Release v049 — Windows 11 Taskbar Search Box/Pill Complete Suppression
- **Canonical Policy Enforcement (SearchOnTaskbarMode)**: Enforces `SearchOnTaskbarMode = 0` under `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search` and `HKCU`, completely eradicating the Windows 11 search pill (`[ Q Hledat ]` / `[ Q Search ]`) at the Group Policy level.
- **Instant Launcher & Startup Suppression**: Direct native `reg.exe` commands in CMD launcher header and startup `SELF-HEALING & ENVIRONMENT CLEANUP` guarantee the search widget never appears when applying layout templates.
- **Universal Multi-Profile & Default User Propagation**: Propagates to all active profiles in `HKEY_USERS` and seeds `C:\Users\Default\NTUSER.DAT`.
- **Post-Restart Explorer Re-Assertion**: Re-locks search suppression after `explorer.exe` restart to eliminate shell reinitialization glitches.

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

### 🎨 Release v046 — Terminal Completion Highlighting & Silent Zero-UAC
- **Terminal Highlighting**: Upgraded `txtConsoleLog` to RichTextBox with vibrant gold status completion banners (`#facc15`).
- **Total Zero-UAC Enforcement**: Hardcoded immediate registry lockdown (`EnableLUA = 0`, slider to bottom) at launcher elevation.

---

## 🛠️ Complete Feature Matrix & Capabilities (115 Modules)

### 1. Privacy, Telemetry & Diagnostics Neutralization
- **DiagTrack & dmwappushservice**: Disabled and service startup set to Disabled (Start = 4).
- **Windows Error Reporting (WER)**: Neutralized across machine and user hives.
- **Advertising ID & Inking/Typing Tracking**: Eradicated telemetry harvesting.
- **Cortana & Bing Web Search**: Completely blocked from Start menu and search bar.
- **Feedback Frequency**: Set to Never (`PeriodInNanoSeconds = 0`).

### 2. Network Sharing & LAN Discovery Hardening
- **Network Profile to Private**: Converts public connections to Private (`Category = 1`), enabling LAN firewall exceptions.
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
- **Always Show Notification Tray Icons (`chk_ui_show_all_tray_icons`)**: Multi-user system tray promotion for Windows 10 & 11.
- **Taskbar Decluttering**: Completely hides Search, Widgets, Task View, Teams Chat, and Copilot.
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
| 💾 **USB Flash Drive (Ventoy)** | `V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v050.cmd` | v050 | Strictly 2 latest versions (`v050`, `v049`) |
| ☁️ **MEGA Win-Flash Mirror** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v050.cmd` | v050 | Strictly 2 latest versions (`v050`, `v049`) |
| 💻 **Vladimir's Desktop (Primary)** | `D:\MEGA\DOCS\desktop\GIN-Win-Optimizer_v050.cmd` | v050 | Strictly 2 latest versions (`v050`, `v049`) |
| 🔒 **Private Git Repository** | `Secret_Privat/Windows/GIN-Win-Optimizer/` | v050 | Full Git history |
| 🌐 **Public Git Repository** | `Windows_scripts/Windows/GIN-Win-Optimizer/` | v050 | Full Git history |

---

## 📦 Delivery & Execution Instructions

1. **Autonomous Elevation**: Double-clicking `GIN-Win-Optimizer_v050.cmd` automatically checks for administrative privileges and elevates itself via native UAC `RunAs` without modal prompts.
2. **Network Share Execution**: When launched from UNC network shares (`\\server\share\GIN-Win-Optimizer_v050.cmd`), the script automatically stages itself to `%TEMP%` to prevent CMD working directory execution warnings.
3. **Turnkey Execution**: Select preset (**Select All**, **Office**, or **Gaming**) and click **Optimize** (or **Optimalizovat**). The terminal emulator outputs live progress, followed by acoustic confirmation chimes upon completion.

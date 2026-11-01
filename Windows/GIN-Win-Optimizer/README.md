# 🚀 GIN-Win-Optimizer — Windows 10/11 Ultimate Optimizer & Deep Cleaner Plus

> **Public Documentation Repository:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Private Master Source:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Author & System Architect:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Target OS:** Windows 10 / 11 (x86_64, all editions: Home, Pro, Enterprise, LTSC)  
> **Current Version:** `v031` (Production Active)  
> **UI Architecture:** Single-Window WPF Polyglot Hybrid (CMD wrapper + Embedded UTF-8 PowerShell + Vector XAML)  
> **Localization:** Trilingual Engine — English 🇬🇧 | Čeština 🇨🇿 | Русский 🇷🇺

---

## 📋 Table of Contents
1. [Overview & Design Philosophy](#-overview--design-philosophy)
2. [Key Architecture & Core Features](#-key-architecture--core-features)
3. [Visual Effects: "Adjust for Best Appearance" Preset](#-visual-effects-adjust-for-best-appearance-preset)
4. [Optimization Categories & Modules Breakdown](#-optimization-categories--modules-breakdown)
   - [Windows Explorer & Desktop Customization](#1-windows-explorer--desktop-customization)
   - [Taskbar & Start Menu Streamlining](#2-taskbar--start-menu-streamlining)
   - [Context Menu Cleanup (Right-Click)](#3-context-menu-cleanup-right-click)
   - [Windows Update & BSOD System Diagnostics](#4-windows-update--bsod-system-diagnostics)
   - [Universal App Debloater & Provisioned Packages](#5-universal-app-debloater--provisioned-packages)
   - [System Performance & Services Hardening](#6-system-performance--services-hardening)
   - [Cache, Component Store & Deep Maintenance](#7-cache-component-store--deep-maintenance)
5. [Self-Healing Engine & System Integrity](#-self-healing-engine--system-integrity)
6. [Deployment & Two-Repository Storage Hierarchy](#-deployment--two-repository-storage-hierarchy)
7. [Changelog & Version History](#-changelog--version-history)
8. [License & Credits](#-license--credits)

---

## 🌟 Overview & Design Philosophy

**GIN-Win-Optimizer** is an enterprise-grade, standalone Windows optimization and deep system maintenance suite developed by **Vladimir Bulantsev (GinCz)**. Designed for modern Windows 10 and Windows 11 environments, it provides over 106 granular system enhancements, registry hardening profiles, performance optimizations, and component cleanups.

Unlike conventional third-party optimization tools that rely on black-box executables or bloated frameworks, **GIN-Win-Optimizer** is built upon a **Polyglot Hybrid Architecture**:
- It begins execution as a standard Windows Command script (`.cmd`), ensuring zero-click elevation to Administrator rights.
- It seamlessly delegates execution into an embedded UTF-8 PowerShell engine that hosts a native Windows Presentation Foundation (**WPF**) dark-themed GUI.
- **Zero Third-Party Dependencies:** Runs out-of-the-box on clean Windows installations without requiring external runtimes, Python, or .NET installers.

```text
GIN-Win-Optimizer_v031.cmd
  │
  ├── [1] Batch Bootstrap (net session check -> UAC auto-elevation -> Hide CMD window)
  │
  └── [2] WPF Polyglot Engine (PowerShell 5.1+ / Modern Dark UI / Live Async Logger)
        ├── Multi-Language Dynamic Switcher (EN / CS / RU)
        ├── 106+ Categorized Checkbox Modules (Safe defaults pre-checked)
        ├── Live Console Output (185px interactive audit log with dual audio tones)
        └── Automated Safe Explorer Restart & Policy Re-Assertion Sweep
```

---

## ⚡ Key Architecture & Core Features

- **Single-Window Modern Dark WPF GUI:** Custom vector-styled dark interface (`#131518` background with cyan `#00b4d8` accents), real-time system specifications banner (CPU model, RAM capacity, OS build, Motherboard, GPU), and responsive multi-column layout.
- **Trilingual Instant Switching:** Full runtime localization for English, Czech, and Russian with localized tooltips and console logs.
- **Safe Single-Threaded Live Terminal Output:** Built-in 185px scrolling console providing real-time stdout/stderr tracking for each operation with color-coded status badges (`[INFO]`, `[SUCCESS]`, `[WARN]`, `[FAIL]`).
- **Dual Low-Pitch Audio Confirmation:** Non-intrusive sound signals upon task milestones and completion for headless or remote administration.
- **Safe Explorer Restart & Post-Optimization Sweep:** Gracefully restarts `explorer.exe` to apply visual, desktop, and taskbar modifications immediately without requiring a full system reboot.
- **Strict Version Control & Retention Policy:** Enforces the strict rule of retaining only the two latest production builds on administrative deployment media (`V:\WIN-FLASH\Util-WINDOWS\` and `D:\MEGA\WIN-FLASH\Util-WINDOWS\`).

---

## 🎨 Visual Effects: "Adjust for Best Appearance" Preset

A defining highlight of **GIN-Win-Optimizer v031** is the inclusion of the **"Adjust for best appearance" (Обеспечить наилучший вид / Nastavit pro nejlepší vzhled)** preset, selected by default (`IsChecked = True`).

Many aggressive optimization scripts disable all visual effects to gain negligible performance, leaving Windows looking dated, flat, with jagged fonts and disabled window animations. **GIN-Win-Optimizer** prioritizes a balanced, visually stunning user experience by default while eliminating genuine background bloat.

### What is Configured (`chk_srv_visual_appearance`):
When enabled, the module directly aligns Windows registry settings with the native System Properties Performance Options dialog (`sysdm.cpl` -> `SystemPropertiesPerformance.exe`):

| Performance Option / Visual Effect | Registry Path | Value Configured | Effect / Behavior |
| :--- | :--- | :---: | :--- |
| **Explorer Master Visual FX Setting** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects` | `VisualFXSetting = 1` | Sets radio button to **"Adjust for best appearance"** |
| **ClearType Font Smoothing** | `HKCU:\Control Panel\Desktop` | `FontSmoothing = "2"`<br>`FontSmoothingType = 2` | Smooths edges of screen fonts with subpixel rendering |
| **Show Window Contents While Dragging** | `HKCU:\Control Panel\Desktop` | `DragFullWindows = "1"` | Prevents wireframe dragging; renders full contents |
| **Window Minimize & Maximize Animation** | `HKCU:\Control Panel\Desktop\WindowMetrics` | `MinAnimate = "1"` | Enables smooth zoom animation when minimizing/restoring |
| **Drop Shadows Under Windows & Mouse** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`<br>`HKCU:\Control Panel\Desktop` | `DropShadow = 1`<br>`CursorShadow = 1` | Renders soft drop shadows behind active windows and cursor |
| **Desktop Icon Label Drop Shadows** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ListviewShadow = 1` | Transparent, shadowed text for desktop icons |
| **Taskbar Animations & Previews** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarAnimations = 1` | Smooth slide animation on taskbar button hover/launch |
| **Translucent Selection Rectangle** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ListviewAlphaSelect = 1` | Modern translucent blue selection box in Explorer |
| **Show Thumbnails Instead of Icons** | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `IconsOnly = 0` | Generates thumbnail previews for pictures and videos |
| **Aero Peek & DWM Composition** | `HKCU:\Software\Microsoft\Windows\DWM` | `Composition = 1`<br>`EnableAeroPeek = 1` | Enables desktop peek and dynamic DWM compositing |
| **Comprehensive User Preferences Mask** | `HKCU:\Control Panel\Desktop` | `UserPreferencesMask` = `9E 3E 07 80 12 00 00 00` | Enables smooth scrolling, menu fading, and combo box sliding |

---

## 🛠️ Optimization Categories & Modules Breakdown

### 1. Windows Explorer & Desktop Customization
- **Classic Context Menu (Windows 11):** Restores the full, traditional right-click context menu by configuring `HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`.
- **Guaranteed "This PC" Desktop Icon:** Restores the classic "This PC" (`{20D04FE0-3AEA-1069-A2D8-08002B30309D}`) icon to the desktop across all user profile hives.
- **Show Hidden Files & File Extensions:** Sets `Hidden = 1` and `HideFileExt = 0` to prevent malicious extension spoofing (e.g. `.pdf.exe`).
- **Hide 3D Objects & Removable Libraries:** Removes clutter folders from "This PC" namespace.
- **Compact View & Folder Template Standardization:** Automatically standardizes Windows Explorer folders to "List" or "Details" view sorted by file type.

### 2. Taskbar & Start Menu Streamlining
- **Taskbar Alignment:** Allows centering or left-aligning the Windows 11 Taskbar.
- **Search Box Elimination:** Replaces the wide search bar with a compact icon or hides it completely (`SearchboxTaskbarMode = 0`).
- **Widgets & Task View Removal:** Removes the MSN News/Widgets board (`TaskbarDa = 0`) and Task View button (`ShowTaskViewButton = 0`).
- **Notification Area (System Tray) Auto-Tray Disable:** Forces `EnableAutoTray = 0` and `NoAutoTray = 1` so all running utility and background icons remain visible in the tray at all times.
- **Hide People Band:** Disables the legacy People taskbar toolbar.

### 3. Context Menu Cleanup (Right-Click)
- **Purge Bloat Items:** Removes redundant third-party context menu handlers, Cast to Device, and Modern Share entries.
- **WinRAR Email Entry Removal:** Cleans up legacy "Compress and email..." shell context entries.

### 4. Windows Update & BSOD System Diagnostics
- **Quadruple Native `reg.exe` Lockdown (Dism++ Standard):**
  - Configures `AUOptions = 1` ("Never check for updates") and `NoAutoUpdate = 1` directly via 64-bit and 32-bit native `reg.exe`.
  - Blocks automatic background driver downloads via Windows Update (`ExcludeWUDriversInQualityUpdate = 1`).
  - Excludes the Malicious Software Removal Tool payload (`DontOfferThroughWUAU = 1`).
  - Disables Windows Update telemetry background endpoints (`DoNotConnectToWindowsUpdateInternetLocations = 1`).
  - Neutralizes update orchestrator services (`wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `dosvc`).
- **BSOD Memory Diagnostics Configuration:** Configures Small Memory Dump (Minidump) generation on crash and disables automatic reboot on BSOD so error codes remain readable.
- **Disable Fast Startup:** Turns off Hybrid Boot (`HiberbootEnabled = 0`) to prevent kernel corruption across dual-boot and fast maintenance cycles.

### 5. Universal App Debloater & Provisioned Packages
- Safely uninstalls and de-provisions OEM and Microsoft bloatware apps for all users:
  - Xbox Gaming Overlay & Services (`Microsoft.XboxApp`, `Microsoft.GamingApp`)
  - Game Bar DVR Background Recording
  - Microsoft News & Weather (`Microsoft.BingNews`, `Microsoft.BingWeather`)
  - Office Hub & Promo Stubs
  - Clipchamp Video Editor
  - People & Contacts Hub
  - Windows Feedback Hub
  - Get Help Stubs
  - Phone Link (optional)

### 6. System Performance & Services Hardening
- **SysMain / Superfetch Tuning:** Disables SysMain to preserve write cycles and prevent micro-stutter on modern NVMe/SATA SSDs.
- **Windows Search Indexer Control:** Disables background indexing spikes on low-power devices.
- **Remote Registry Neutralization:** Sets `RemoteRegistry` service to Disabled for local network security.
- **Delivery Optimization (P2P Bandwidth Sharing):** Prevents Windows from uploading system updates to other internet peers.
- **Disable Reserved Storage:** Frees approximately 7.2 GB of disk space locked by Windows for update staging (`fsutil storagereserve disable`).
- **Hibernation Control:** Disables `hiberfil.sys` to instantly reclaim RAM-equivalent disk space on SSDs (`powercfg -h off`).
- **Ultimate Performance Power Plan:** Unlocks and activates the hidden Windows Ultimate Performance power scheme.
- **Forced SSD TRIM & File System Hardening:** Triggers immediate SSD TRIM optimization and disables `LastAccessUpdate` and legacy `8dot3` short name generation.
- **Disable Network Task Offload & Chimney:** Prevents DPC/ISR network latency spikes on real-time systems.
- **Visual Effects: Adjust for Best Appearance (`chk_srv_visual_appearance`):** Full visual suite enabled by default.

### 7. Cache, Component Store & Deep Maintenance
- **User & Windows Temp Purge:** Recursively clears `%TEMP%`, `C:\Windows\Temp`, and memory dump logs.
- **SoftwareDistribution Download Purge:** Flushes leftover `.cab` and `.esd` installation files.
- **DirectX Shader & Thumbnail Cache Flush:** Eliminates stutter caused by corrupt GPU shaders and rebuilds icon databases.
- **Event Viewer Logs Purge:** Cleans historical system, application, and security event logs.
- **Sequential Disk Cleanup (`cleanmgr.exe`):** Automated silent disk cleanup run on system and data volumes.
- **Deep Component Maintenance (Highlighted in Red, Disabled by Default):**
  - `DISM /Online /Cleanup-Image /RestoreHealth` — Verifies and repairs the Windows Component Store.
  - `DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase` — Cleans up superseded component versions.
  - `SFC /scannow` — Verifies and fixes system file integrity.

---

## 🛡️ Self-Healing Engine & System Integrity

Every launch of **GIN-Win-Optimizer** initiates an automated startup self-healing sequence before presenting the GUI:
1. **Phantom Desktop Icon Eraser:** Detects and removes orphaned shell GUIDs (`{031E4825-7B94-4dc3-B131-E946B7CD0BE5}`) that manifest as blank white square icons on user desktops.
2. **Native Win32 Shell COM Taskbar Unpinning:** Queries the system `AppsFolder` (`shell:::{4234d49b-0245-4df3-b780-3893943456e1}`) to execute genuine localized shell verbs, cleanly unpinning Microsoft Edge and Internet Explorer from the taskbar without corrupting PIDL stream structures.
3. **LayoutModification.xml Immunity:** Deploys an empty taskbar pinlist template with `PinListPlacement="Replace"` to `$env:LOCALAPPDATA\Microsoft\Windows\Shell\` and `C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\`, permanently preventing Windows 10/11 from regenerating OEM taskbar shortcuts.

---

## 📦 Deployment & Two-Repository Storage Hierarchy

Under the strict operational standards of **Vladimir Bulantsev (GinCz)**:

1. **Private Repository (`Secret_Privat`):**
   - Holds all executable scripts (`GIN-Win-Optimizer_v*.cmd`), build recipes, and internal system configs.
   - Master path: `Secret_Privat/Windows/GIN-Win-Optimizer/`
2. **Public Repository (`Windows_scripts`):**
   - Serves as the public documentation mirror containing comprehensive guides (`README.md`), release notes (`CHANGELOG.md`), and version manifests (`version.json`).
   - Executable scripts are not published in the public repository.
3. **Administrative Physical & Cloud Media:**
   - **Ventoy USB Flash Drive:** `V:\WIN-FLASH\Util-WINDOWS\`
   - **Local MEGA Cloud Sync Mirror:** `D:\MEGA\WIN-FLASH\Util-WINDOWS\`
   - **Remote MEGA Cloud Storage:** `/MEGA/WIN-FLASH/Util-WINDOWS/`
   - **Retention Policy:** Exactly **two latest production versions** are preserved (`v031` and `v030`). Older builds are purged automatically upon release.

---

## 📜 Changelog & Version History

See the complete history of features, bugfixes, and optimizations in [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Win-Optimizer/CHANGELOG.md).

- **`v031` (2026-11-01):** Native System Properties "Adjust for Best Appearance" (Обеспечить наилучший вид) default preset; comprehensive English documentation release.
- **`v030` (2026-10-31):** Quadruple native `reg.exe` Dism++ update lockdown; `LayoutModification.xml` zero-pin taskbar defense.
- **`v029` (2026-10-31):** Native Win32 Shell COM taskbar unpinning engine for Edge/IE; multi-stage self-healing sweeps.
- **`v028` (2026-10-31):** UI modernization; real-time hardware specifications header; streamlined language switching.

---

## ⚖️ License & Credits

- **Author & Architect:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI
- **Repository:** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)
- **License:** Proprietary tooling designed for high-performance administration and precision Windows deployment.

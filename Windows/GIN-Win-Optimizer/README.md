# 🚀 GIN-Win-Optimizer — Windows 10 & 11 Ultimate Performance Suite

> **Author / Chief Architect:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Target Platforms:** Windows 10 & Windows 11 (64-bit, all editions: Home, Pro, Enterprise, LTSC)  
> **Current Version:** `v028` (Active)  
> **Architecture:** Polyglot Hybrid CMD / PowerShell 5.1 / WPF Dark-Themed GUI  
> **License:** Proprietary / Private Source (Documentation & Metadata Public Mirror)

---

## 🧭 Overview & Philosophy

**GIN-Win-Optimizer** is an enterprise-grade, single-window system optimizer and deep cleaner for Windows 10 and Windows 11 workstations and laptops. It unifies over 97 deep system tweaks, telemetry eliminators, privacy enforcers, and disk cleaning procedures into an intuitive, dark-themed graphical interface.

Unlike generic cleanup utilities, GIN-Win-Optimizer is designed with DevOps-grade precision:
* **Zero External Dependencies:** Built as a polyglot CMD/PowerShell hybrid that executes entirely in-memory using native Windows APIs (`PresentationFramework`, `kernel32.dll`, Win32 Shell COM).
* **Single-Window Modern Dark WPF UI:** Pure ASCII Base64 XAML rendered dynamically without compiling or extracting temporary files.
* **Safe, Non-Blocking Live Output:** Custom single-threaded Dispatcher output loop prevents PowerShell runspace pipeline collisions during long operations (DISM, SFC, Cleanmgr).
* **Trilingual at Runtime:** Instant UI language switching between **English (EN)**, **Čeština (CZ)**, and **Русский (RU)** with crisp, high-contrast badges.

---

## 🛡️ Core Capabilities & Module Breakdown

### 1. Privacy & Diagnostics Telemetry
- Completely disables Connected User Experiences and Telemetry (`DiagTrack`, `dmwappushservice`).
- Disables Windows Error Reporting (`WerSvc`) and telemetry scheduled tasks in Task Scheduler.
- Blocks advertising ID tracking, inking/typing personalization, and location sensors.
- Disables Cortana integration across system policies and registry.

### 2. Windows Update & Maintenance Control
- Complete manual update control: disables automatic background updates (`wuauserv`, `UsoSvc`, `dosvc`, `WaaSMedicSvc`).
- Prevents silent background downloads (`MoUsoCoreWorker`, `UsoClient`) and driver overrides.
- Excludes driver updates and Malicious Software Removal Tool (MSRT) bloat from Windows Update.

### 3. Explorer, Desktop & Taskbar (Windows 10 / 11)
- **Always Show All Tray Icons:** Automatically reveals all notification area icons next to the clock (disables auto-tray chevron overflow on Windows 10 and promotes all icons in Windows 11).
- **Global Folder View Mode:** Sets default folder view template globally to **List** (`Mode = 3`, `LogicalViewMode = 4`) and default sorting to **Type** (`SortByList = prop:System.ItemTypeText;System.ItemNameDisplay`) across all standard folder types, removing annoying date groupings.
- **Unpin Bloatware from Taskbar:** Unpins legacy Internet Explorer and Microsoft Edge from the taskbar, blocking auto-repinning policies.
- **Hide People Band:** Permanently eliminates the People bar on Windows 10 via policy and registry.
- **Desktop "This PC" Guarantee:** Enforces visible "This PC" / "Этот компьютер" icon across all user profiles and cloud desktops.
- **Clean Taskbar (Windows 11):** Completely hides Search box, Widgets/Feeds, Chat/Teams, and Task View buttons.

### 4. Sequential Disk Cleanup & Cache Evacuation
- **Sequential Dual-Drive Cleanup:** Runs standard Windows Disk Cleanup (`cleanmgr.exe /autoclean /d C:`) first and waits for full exit; only then proceeds to Drive D:, preventing simultaneous dialog conflicts.
- Empties temporary caches: `%TEMP%`, `Windows\Temp`, `SoftwareDistribution\Download`, DirectX shader cache, thumbnail databases (`thumbcache_*.db`), and Event Logs.
- **High-Visibility Long-Running Operations:** The two slowest operations (**DISM RestoreHealth** and **WinSxS ResetBase**) are highlighted in bright red at the top of the group, tagged with `(slow - медленно)`, and unchecked by default to prevent unexpected multi-hour maintenance.

---

## 📦 Project Distribution & Storage Architecture

Per strict architectural standards, this project operates under a dual-repository model:

| Repository / Storage Location | Purpose | Content Policy |
| :--- | :--- | :--- |
| 🔒 **[Secret_Privat ↗](https://github.com/GinCz/Secret_Privat)** | Private Master Repository | **Full source code (`.cmd`), deployment manifests, and internal tools.** |
| 🌐 **[Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)** | Public Mirror | **English documentation (`README.md`), changelogs, and metadata only.** |
| 💾 **`V:\WIN-FLASH\Util-WINDOWS\`** | Physical USB Flash (Ventoy) | Strictly **2 latest production versions** (`v021` and `v017`). |
| ☁️ **`D:\MEGA\WIN-FLASH\Util-WINDOWS\`** | Cloud Flash Mirror | Synchronized cloud backup of the 2 latest production versions. |
| 🚫 **Desktop (`D:\MEGA\DOCS\desktop\`)** | Desktop Workspace | **Strictly excluded.** No optimizer files are placed on Desktop. |

---

## 📋 Release History Highlights

- **v021 (Current):** Highlighted the two longest DISM operations in bright red at the top of the cleaning group, marked `(slow - медленно)`, unchecked by default across all presets.
- **v017:** Added taskbar unpinning for Internet Explorer & Edge, enforced People band removal policies, permanent "This PC" desktop icon guarantee, and automated soft Explorer reload.
- **v016:** Introduced global List folder view sorted by Type, sequential C: then D: cleanmgr execution, and readable dark-theme disabled button styling.
- **v015:** Full Windows Update disabler and elimination of silent background downloads.

*For complete version details, see [`CHANGELOG.md`](./CHANGELOG.md).*

---

## 👤 Author & Maintainer

* **Architect:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))
* **Email:** `gin@volny.cz` | `gin.vladimir@gmail.com`
* **Profile:** Senior DevOps & Cloud Infrastructure Engineer, PCI DSS Certified Analyst

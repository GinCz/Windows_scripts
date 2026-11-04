# 🔒 GIN-Win-Optimizer — Master Repository

> **Private Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Public Mirror:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Author / Architect:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & AI [VladiMIR + AI]  
> **Target OS:** Windows 10 / 11 (Universal x86 32-bit & x64 64-bit, all editions: Home, Pro, Enterprise, LTSC)  
> **Current Version:** `v039` (Active)  
> **Retention Policy:** Strictly **2 latest production versions** (`GIN-Win-Optimizer_v039.cmd` and `GIN-Win-Optimizer_v038.cmd`).

---

## 🚀 GIN-Win-Optimizer v039: Ultralightweight, Safe & Antivirus-Immune Architecture

Version `v039` represents a major architectural overhaul focusing on extreme lightness, rock-solid stability, and total antivirus transparency:
- **Ultra-Compact Footprint (12.8 KB)**: Reduced from 244 KB down to less than 13 KB. No heavy embedded assemblies, no monolithic GUI overhead, no bloated payloads.
- **100% Antivirus Immunity**: Completely transparent native Windows CMD batch script with CRLF line terminators. Zero obfuscation, zero Base64 payloads, zero suspicious downloader scripts. Trusted natively by Windows Defender and SmartScreen.
- **Universal Architecture Compatibility**: Seamless native execution on both 32-bit (x86) and 64-bit (x64) platforms across Windows 10 Home/Pro/Enterprise/LTSC and Windows 11.
- **Code Page & Console Stability**: Uses pure standard ASCII console output with clear step-by-step `[OK]` status markers. **Eliminates `chcp 65001`**, preventing Win32 Error 0x1F (`Zařízení připojené k systému nefunguje` / `A device attached to the system is not functioning`) on Czech and European Windows installations.

---

## 🛠️ Core Functional Modules (v039)

### 1. Network & File / Printer Sharing Optimization (Ultarix Standard)
- **Active Network Profile to Private**: Converts public connections to Private (`Doma/Kancelář`) via PowerShell and NetworkList registry, ensuring local firewall rules unblock LAN discovery and file/printer sharing.
- **Guest SMB Share Access (`AllowInsecureGuestAuth = 1`)**: Enables LanmanWorkstation guest authentication for unhindered access to network NAS, routers, and legacy file shares.
- **Admin Mapped Drives (`EnableLinkedConnections = 1`)**: Ensures network drive mappings remain fully accessible to both unprivileged desktop users and elevated Administrator processes.
- **UNC Path Execution (`DisableUNCCheck = 1`)**: Disables UNC validation warnings, enabling scripts to execute directly from network shares.
- **Core Discovery & Printing Services Auto-Start**: Enforces automatic startup for `FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `Spooler`, `lmhosts`, and `Dnscache`.
- **Comprehensive Firewall Rules**: Activates Network Discovery and File and Printer Sharing firewall rules across multiple localized rule groups.

### 2. Memory & Performance Optimization (Crucial for 32-bit & Low-RAM PCs)
- **Static Pagefile Fixation (4096–8192 MB on C:)**: Disables automatic managed pagefile and locks a stable, contiguous 4–8 GB virtual memory backing on drive `C:`, preventing memory allocation crashes (`0xe0000008` / out-of-commit).
- **Hibernation Disabling (`powercfg -h off`)**: Immediately removes `hiberfil.sys`, recovering 4 to 8 GB of valuable SSD/system storage.
- **Visual Effects Tuning**: Eliminates sluggish window minimize/maximize and taskbar animations (`MinAnimate = 0`, `MenuShowDelay = 100`) while strictly preserving **ClearType font smoothing** (`FontSmoothing = 2`, `FontSmoothingType = 2`) for crisp text legibility.

### 3. Safe System Cleanup
- **Temporary Files**: Cleans user `%TEMP%` and `%SystemRoot%\Temp`.
- **Windows Update Cache**: Safely stops `wuauserv`, purges `%SystemRoot%\SoftwareDistribution\Download\*`, and restarts the update service.
- **Explorer Thumbnail & Icon Caches**: Purges cached thumbnail databases to resolve icon corruption and free disk space.
- **Diagnostics Dumps**: Deletes user crash dumps, mini dumps, and memory dumps.

### 4. Telemetry, Error Reporting & Security Integrity
- **Safe Telemetry Deactivation**: Disables background telemetry services `DiagTrack` and `dmwappushservice`, sets DataCollection GPO to Security level (0) without breaking any network or system components.
- **Error Reporting Deactivation**: Disables `WerSvc` and sets Windows Error Reporting GPO policies to disabled.
- **Antivirus & Driver Integrity**: **Strictly preserves Windows Defender and system drivers** without interference or tampering.

---

## 🖥️ Target Deployment Environments

| Environment / Medium | Path | Target Version | Retention Policy |
| :--- | :--- | :---: | :---: |
| 💾 **USB Flash Drive (Ventoy)** | `V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v039.cmd` | v039 | Latest 2 versions |
| ☁️ **MEGA Win-Flash Mirror** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v039.cmd` | v039 | Latest 2 versions |
| ☁️ **MEGA Cloud Remote** | `/MEGA/WIN-FLASH/Util-WINDOWS/GIN-Win-Optimizer_v039.cmd` | v039 | Latest 2 versions |
| 🔒 **Private Git Repository** | `Secret_Privat/Windows/GIN-Win-Optimizer/` | v039 | Full Git history |
| 🌐 **Public Git Repository** | `Windows_scripts/Windows/GIN-Win-Optimizer/` | v039 | Full Git history |

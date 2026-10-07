<div align="center">

# Windows Scripts — VladiMIR Bulantsev (GinCz)

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Language-Batch%20%2F%20PowerShell-4D4D4D?logo=windowsterminal&logoColor=white)
![Version](https://img.shields.io/badge/Version-v2026--08--16-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Scripts](https://img.shields.io/badge/Scripts-15-orange)

**= Rooted by VladiMIR + AI | v.2026.08.16 | github.com/GinCz =**

A production-grade collection of self-elevating Windows utility scripts for system optimization,
deep cache cleaning, Windows Update repair, diagnostics, and **Samba SMB network drive management**.

> By **VladiMIR Bulantsev** (GinCz) — Linux sysadmin · DevOps · IPGuard · Cloudflare · Samba · XRAY VPN · CrowdSec · Czech Republic

---

`#WindowsScripts` `#SystemOptimization` `#WindowsUpdateFix` `#CentBrowser` `#SysAdmin` `#PowerShell` `#BatchScript` `#CyberSecurity` `#Performance`

</div>

---

## Table of Contents

- [Windows Applications & Executable Suite (.exe) ➔](Windows/README.md)
  - [GIN-NetScan — High-Speed Native Win32 LAN Discovery & Port Scanner](Windows/GIN-NetScan/README.md)
  - [GIN-VPN — High-Speed Native Xray VLESS-Reality Client](Windows/VPN/GIN-VPN/README.md)
  - [MEGA Drive — Universal Standalone Cloud Mount Engine](Windows/MEGA/README.md)
  - [Xray VPN Suite — Automated Installers & Dynamic Tray Shield](Windows/VPN/README.md)
- [Scripts Overview](#scripts-overview)
  - [System Optimization & Sweepers](#system-optimization--sweepers)
  - [Diagnostics & Security Audit](#diagnostics--security-audit)
  - [Software Installers](#software-installers)
  - [SMB Network Drives](#smb-network-drives)
- [Detailed Script Documentation](#detailed-script-documentation)
  - [CLEAN.cmd — High-Performance System Sweeper](#1-cleancmd--system--security-sweeper)
  - [CentBrowser_CLEAN.bat — Multi-Profile Browser Cleaner](#2-centbrowser_cleanbat--multi-profile-cache-cleaner)
  - [Error_80070002_AI.cmd — Windows Update Fast Repair Tool](#3-error_80070002_aicmd--windows-update-fast-repair-tool)
  - [Nox_AdBlock.cmd — NoxPlayer AdBlock & Privacy Tool](#4-nox_adblockcmd--noxplayer-adblock--privacy-tool)
  - [System_Security_Miner_Audit.cmd — Advanced Security & Cryptominer Deep Audit](#5-system_security_miner_auditcmd--advanced-security--cryptominer-deep-audit)
- [SMB Network Drives — SMB_Connect](#smb-network-drives--smb_connect)
- [Requirements & Usage](#requirements--usage)
- [Deployment Rules & Standards (MEGA Desktop Auto-Sync)](RULES.md)
- [Code Conventions](#code-conventions)
- [Author](#author)

---

## 🪟 Windows Applications & Executable Suite (.exe)

All native Windows applications are developed with zero external runtime dependencies, standalone architecture, and compiled with custom embedded Windows PE icons.

> [!IMPORTANT]
> **MEGA Desktop Auto-Sync Standard:** Only the **single latest compiled version** of each executable (`GIN-NetScan_vXXX.exe`, `GIN-VPN_vXXX.exe`) is maintained on the user's Desktop via cloud folder `/MEGA/DOCS/desktop/` (`D:\MEGA\DOCS\desktop\`). Outdated versions are automatically purged upon release. See [RULES.md](RULES.md).

| Application / Package | Binary (.exe) / Launcher | Description & Key Architecture | Release & Status |
| :--- | :--- | :--- | :---: |
| 🌐 **[GIN-NetScan](Windows/GIN-NetScan/README.md)** | `GIN-NetScan_v025.exe` | Standalone native Win32 GUI network discovery & port scanner. Hardware `SendARP`, mDNS Bonjour, deep Apple model decoding, colorful owner-drawn buttons (`BS_OWNERDRAW`), native PE icon resource. | 🟢 **`v025`** |
| 🛡️ **[GIN-VPN](Windows/VPN/GIN-VPN/README.md)** | `GIN-VPN_v013.exe`<br>`GIN-VPN.ps1` | High-speed native Xray VLESS-Reality client with 3D Glassmorphism UI, real-time telemetry, auto-update & official Windows uninstaller. | 🟢 **`v013`** |
| ☁️ **[MEGA Drive](Windows/MEGA/README.md)** | `MEGA_Drive_Universal.cmd` | Standalone universal cloud drive mount engine (`M:`) with 2FA support and auto-reconnect. | 🟢 **Stable** |
| 🛡️ **[Xray VPN Suite](Windows/VPN/README.md)** | `XRAY-VPN_VladiMIR__Win-ALL_109_&&&.bat` | Universal automated Xray installer for Windows 7/10/11 with GDI+ dynamic tray shield. | 🟢 **Stable** |
| 🤖 **[CODEX ChatGPT](Windows/CODEX_ChatGPT/README.md)** | `Install_ChatGPT_Codex_Universal.cmd` | Direct MS Store CDN bypass installer for ChatGPT Desktop & Codex. | 🟢 **Stable** |

👉 **[Explore Full Windows Applications Catalog & Documentation ➔](Windows/README.md)**

---

## Scripts Overview

### System Optimization & Sweepers

| # | Script | Description | Admin | Delay/Mode |
|---|--------|-------------|:-----:|:----------:|
| 1 | [`CLEAN.cmd`](#1-cleancmd--system--security-sweeper) | High-performance system & user cache cleaner + security persistence sweeper | **YES** | Startup / Fast |
| 2 | [`CentBrowser_CLEAN.bat`](#2-centbrowser_cleanbat--multi-profile-cache-cleaner) | Universal multi-profile cache cleaner for CentBrowser & Chromium (scans 1 to 500+ profiles) | **YES** | Manual / Auto |
| 3 | [`Error_80070002_AI.cmd`](#3-error_80070002_aicmd--windows-update-fast-repair-tool) | Ultra-fast Windows Update error `0x80070002` / `0x80070003` reset & repair tool (~5s) | **YES** | Immediate |
| 4 | [`Nox_AdBlock.cmd`](#4-nox_adblockcmd--noxplayer-adblock--privacy-tool) | Blocks NoxPlayer ads, promo popups & telemetry while keeping Google Play 100% OK | **YES** | Immediate |
| 5 | `CMD_setting.bat` | Sets CMD font to Consolas 20pt, UTF-8 encoding, buffer size 120x9001 globally via registry | **YES** | Immediate |
| 6 | `WIN_Optimize.bat` | 15-step deep optimizer: reserved storage, hibernation, services, SSD TRIM, visual effects, temp/disk cleanup, network, power plan, telemetry, DISM, WinSxS, SFC, CompactOS | **YES** | Immediate |
| 7 | `AntiVir_OFF.bat` | Toggle Windows Defender real-time protection ON/OFF interactively | **YES** | Interactive |

### Diagnostics & Security Audit

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 7 | [`System_Security_Miner_Audit.cmd`](#5-system_security_miner_auditcmd--advanced-security--cryptominer-deep-audit) | **Windows Advanced Security & Cryptominer Deep Audit** (16 inspection vectors, CPU load sampling, hidden tunnels, WMI/IFEO persistence, Defender status & exclusions) | **YES** |
| 8 | `MemTest_7z.bat` | Hardware stress test via 7-Zip benchmark: auto-installs 7-Zip, 10 passes, 256MB dictionary, 4 threads | **YES** |
| 9 | `SMB_Test.bat` | Live SMB network benchmark: 50MB/5GB modes, measures upload/download speed with MD5 integrity check | **YES** |

### Software Installers

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 9 | `Install_7zip_Universal.bat` | Auto-detects architecture (x64/arm64/x86), fetches latest 7-Zip, silently installs | **YES** |
| 10 | `Telegram_Setup.bat` | Downloads and launches latest Telegram Desktop x64 installer via BITS transfer | no |
| 11 | `MEGA_x64_x86_Setup.bat` | Downloads and launches latest MEGAsync x64/x86 installer | no |
| 12 | `TeraBox_Setup.bat` | Downloads and launches TeraBox PC installer | no |
| 13 | `Google_Drive_Setup.bat` | Downloads and launches Google Drive for Desktop installer | no |
| 14 | `Heaven_Benchmark_Setup.bat` | Downloads and launches UNIGINE Heaven Benchmark 4.0 GPU stress test | no |
| 15 | [`Install_ChatGPT_Codex_Universal.cmd`](Windows/CODEX_ChatGPT/README.md) | Universal zero-dependency installer for **ChatGPT Desktop & Codex AI Agent** (direct Store CDN bypass) | **YES** |

### SMB Network Drives

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 15 | `SMB_Connect.bat` | Connects all 10 Samba servers as network drives (A: – Y:) in parallel with status report | **YES** |

---

## Detailed Script Documentation

### 1. `CLEAN.cmd` — System & Security Sweeper

`CLEAN.cmd` is a self-elevating, standalone batch-PowerShell hybrid script engineered for boot-time and manual deep cleaning of junk files, temporary system caches, and known malware persistence artifacts.

#### Key Features
* **Zero Dependencies:** Single-file architecture with embedded PowerShell runtime.
* **Auto-Elevation (UAC):** Automatically requests Administrator privileges without requiring right-click.
* **Boot Delay Mode (`-Startup`):** Provides a clean 30-second countdown at Windows boot to let core system services initialize first (skippable with any key).
* **Malware & Threat Persistence Sweeper:** Safely searches and purges known rogue persistence drops (`wendos`, fake `wuauclt1.exe` miners, disguised `%TEMP%\*.vbe`/`*.jse` scripts, template droppers).
* **Data Safety Guarantee:** Never empties the Recycle Bin, does not alter personal client browser profiles, and preserves system drivers.

#### Cleaned Scopes (10 Zones)
1. **User Temporary Files:** `%LOCALAPPDATA%\Temp`, `%USERPROFILE%\AppData\Local\Temp`
2. **Windows System Temp:** `C:\Windows\Temp`
3. **Malware & Persistence Sweeper:** `System32\wendos`, `SysWOW64\wendos`, `wuauclt1.exe`, `svchost1.exe`, rogue VBS/JSE autoruns
4. **Crash Dumps & Telemetry:** `%LOCALAPPDATA%\CrashDumps`, Windows Error Reporting (`WER`) Queues & Reports
5. **Windows Update Cache:** `SoftwareDistribution\Download`, Delivery Optimization P2P fragments
6. **System Web Cache:** `INetCache\IE`, `INetCache\Low\IE`
7. **Runtime Caches:** Java Deployment Cache (`Sun`/`Oracle`), Adobe Acrobat/Reader caches
8. **GPU & DirectX Shader Cache:** `D3DSCache`, AMD `DxCache`, NVIDIA `DXCache`, Intel `ShaderCache`
9. **BSOD & Debug Logs:** `C:\Windows\Minidump`, `C:\Windows\Debug`
10. **System Diagnostics:** `C:\Windows\Logs\DISM`, `C:\Windows\Panther`

```cmd
# Run immediately (Manual Mode):
CLEAN.cmd -Fast

# Run in Startup Mode (30-second delay):
CLEAN.cmd -Startup
```

---

### 2. `CentBrowser_CLEAN.bat` — Multi-Profile Cache Cleaner

`CentBrowser_CLEAN.bat` is an automated cache sweeper specifically built for multi-profile client environments (supporting from 1 to 500+ separate user profiles).

#### Key Features
* **Universal Multi-Profile Discovery:** Automatically scans containers such as `D:\UTIL\N E T\CHROME_temp`, `%LOCALAPPDATA%\CentBrowser\User Data`, `%LOCALAPPDATA%\Google\Chrome\User Data`, `Brave`, and `Edge`.
* **Zero Data Loss:** Preserves all passwords, saved logins, session cookies, browsing history, bookmarks, tabs, and extensions.
* **Targeted Purging:** Cleans only transient render caches:
  * Disk Cache & `Cache_Data`
  * Code Cache (V8 compiled JS/WASM)
  * `GPUCache`, `GrShaderCache`, `GraphiteDawnCache`
  * `Service Worker\CacheStorage` & `ScriptCache`
  * `Crashpad\reports` and `blob_storage`
* **High Performance:** Purges dozens of gigabytes across 80+ profiles in less than 1 second.

---

### 3. `Error_80070002_AI.cmd` — Windows Update Fast Repair Tool

`Error_80070002_AI.cmd` is a rapid, non-destructive repair tool for Windows Update error codes (`0x80070002`, `0x80070003`, `0x80240020`, `0x80070057`) caused by corrupted download manifests or interrupted download states.

#### Execution Pipeline (~5 Seconds)
1. **Service Suspension:** Gracefully stops `wuauserv`, `bits`, `cryptsvc`, `dosvc`, and `msiserver`.
2. **Payload Purge:** Wipes corrupted downloaded update packages in `C:\Windows\SoftwareDistribution\Download`.
3. **Metadata Reset:** Resets the local update catalog database in `C:\Windows\SoftwareDistribution\DataStore`.
4. **Signature Catalog Refresh:** Refreshes cryptographic catalog cache in `C:\Windows\System32\catroot2`.
5. **BITS Queue Reset:** Clears stalled downloader jobs in `qmgr*.dat`.
6. **Binary Re-Registration & Network Reset:** Re-registers essential update libraries (`wups2.dll`, `wuaueng.dll`, `urlmon.dll`, `atl.dll`) and resets the Winsock network catalog.
7. **Service Activation:** Re-enables and starts all update services.
8. **Immediate Detection:** Triggers a clean scan via Windows Update Orchestrator (`usoclient StartScan`).

---

### 4. `Nox_AdBlock.cmd` — NoxPlayer AdBlock & Privacy Tool

`Nox_AdBlock.cmd` blocks intrusive advertising, sponsored game icons, popup recommendations, and analytics telemetry from NoxPlayer while strictly keeping Google Play Services and app downloads fully operational.

#### Key Features
* **DNS Sinkhole Blocking:** Redirects 13 known BigNox ad, popup, and telemetry domains (`advert.bignox.com`, `hotgames.bignox.com`, `res06.bignox.com`, `stat.bignox.com`, etc.) to `0.0.0.0` in the Windows `hosts` file.
* **Google Play Compatibility:** Does NOT touch Google servers, Google Play Services, or APK repositories. Apps install and update without interruption.
* **Config Hardening:** Patches `conf.ini` to disable `loadingpage_show`, `collect_behavior_enable`, and `app_notice_enable`.
* **Ad Cache Purge:** Cleans all accumulated promo images in `app_images`, `loading`, `preview`, and `app_notice_list`.

---

### 5. `System_Security_Miner_Audit.cmd` — Advanced Security & Cryptominer Deep Audit

`System_Security_Miner_Audit.cmd` is a standalone, polyglot CMD/PowerShell audit suite designed to inspect Windows workstations and servers for covert background cryptocurrency miners, masquerading system binaries, unauthorized remote control tools, stealth reverse tunnels, persistence hooks, and compromised Windows Defender configurations.

#### Core Security Vectors (16 Inspection Modules)

| # | Check Vector | Description | Status Level |
| :---: | :--- | :--- | :---: |
| **`[01]`** | **CPU Load Sampling** | Samples all active processes over 5 seconds across logical CPU cores to detect silent CPU-throttling miners. | `WARN` |
| **`[02]`** | **Cryptominer Signatures** | Scans process names, binary paths, and CLI parameters for 30+ mining engines (`xmrig`, `nbminer`, `phoenixminer`, `t-rex`, `lolminer`, `srbminer`, `cpuminer`, `randomx`, `cryptonight`, etc.). | `CRIT` |
| **`[03]`** | **Process Integrity & Spoofing** | Validates Authenticode signatures and detects fake system binaries (`svchost.exe`, `lsass.exe`, `csrss.exe`) executing outside the `System32` directory. | `CRIT` / `WARN` |
| **`[04]`** | **Mining Pool Sockets** | Inspects active TCP connections for standard Stratum mining ports (`3333`, `4444`, `5555`, `14444`, `45560`, etc.) connecting to public endpoints. | `WARN` |
| **`[05]`** | **Mining Pool DNS Cache** | Audits the local Windows DNS Client Cache for queries to known cryptocurrency pools (`nanopool`, `minexmr`, `supportxmr`, `2miners`, `f2pool`, `unmineable`, `kryptex`, etc.). | `WARN` |
| **`[06]`** | **Reverse Tunnels & Proxies** | Identifies active stealth reverse tunneling clients (`ngrok`, `cloudflared`, `frpc`, `chisel`, `ligolo`, `bore`, `localxpose`, `pagekite`). | `WARN` |
| **`[07]`** | **Remote Access Software** | Detects remote administration and screen-sharing agents (`RustDesk`, `TeamViewer`, `AnyDesk`, `Radmin`, `Splashtop`, `ScreenConnect`, `VNC`, etc.) with process instance counts. | `INFO` / `OK` |
| **`[08]`** | **Task Scheduler Triggers** | Audits Task Scheduler for suspicious download stagers (`-enc`, `certutil -urlcache`, `downloadstring`, `IEX`, `mshta`, `bitsadmin`) and untrusted tasks in user folders. | `CRIT` / `WARN` |
| **`[09]`** | **Registry Autorun & Shell** | Scans `Run` / `RunOnce` registry keys and verifies that `Winlogon\Shell` (`explorer.exe`) and `Userinit` have not been hijacked. | `CRIT` / `WARN` |
| **`[10]`** | **Startup Folders** | Inspects user and global `Startup` directories (`shell:startup` and `shell:common startup`) for unauthorized `.bat`, `.cmd`, `.vbs`, `.ps1`, or `.hta` scripts. | `WARN` |
| **`[11]`** | **IFEO Process Hijacking** | Scans `Image File Execution Options` for debugger redirections used by malware to intercept task managers or security tools. | `CRIT` |
| **`[12]`** | **Local Administrators** | Audits members of the local `Administrators` group (`SID S-1-5-32-544`) to detect unauthorized backdoor accounts. | `WARN` |
| **`[13]`** | **WMI Event Persistence** | Queries `root\subscription:__EventConsumer` for hidden WMI event bindings used for stealth persistence across reboots. | `CRIT` |
| **`[14]`** | **Windows Defender Health** | Verifies Real-Time Protection state, antivirus signature age, and detects dangerous path exclusions (e.g. `C:\`, `G:\`, `Temp`, `Downloads`). | `CRIT` / `WARN` |
| **`[15]`** | **Low-Level Hardware Drivers** | Scans loaded kernel drivers for hardware-access exploits commonly bundled with miners (`WinRing0`, `InpOut`, `ProcessHacker`). | `WARN` |
| **`[16]`** | **Hosts & Proxy Hijacking** | Detects blocked security vendor updates (`microsoft`, `windowsupdate`, `defender`, `virustotal`) in the `hosts` file. | `CRIT` |
| **`[17]`** | **Dropped Miner Configs** | Recursively scans `AppData`, `ProgramData`, and `Temp` directories for orphaned miner configuration files (`config.json` containing pool or wallet signatures). | `CRIT` |

#### Key Features
* **Zero Dependencies & Polyglot Runtime:** Single file `.cmd` executable with seamless embedded UTF-8 PowerShell runtime.
* **Auto UAC Elevation:** Automatically triggers Windows UAC prompt with zero configuration.
* **Multi-Language Interface:** English *(Default)*, Česky, Русский.
* **Minimalist High-Contrast UI:** Green `[ OK ]`, Yellow `[ NO ]` *(Warning)*, Red `[ NO ]` *(Critical)*.
* **Automated Report Generation:** Automatically resolves the user's actual Desktop path (even if redirected to external drives or OneDrive) and exports `Security_Audit_Report.txt`.

---

## SMB Network Drives — SMB_Connect

`SMB_Connect.bat` connects Samba servers simultaneously as Windows network drives.

```text
[  OK  ]  A:  AWS_12       18.195.117.12
[  OK  ]  E:  IONOS_38     82.223.116.38
[  OK  ]  I:  ILYA_221     89.110.69.221
[  OK  ]  N:  PILIK_33     195.63.138.33
[  OK  ]  Q:  SO_38        144.124.233.38
[  OK  ]  W:  STOLB_24     144.124.239.24
[  OK  ]  Y:  ALEX_180     88.210.6.180
```

All servers run **Samba on Ubuntu 24 LTS** with IPGuard triple-layer security.
See the full server-side setup in 👉 [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public).

---

## Requirements & Usage

* **Operating System:** Windows 10 / Windows 11 (x64 / x86 / ARM64)
* **Shell:** Standard CMD / PowerShell 5.1+
* **Privileges:** Scripts automatically request UAC elevation when administrator privileges are required.
* **Usage:** Simply double-click any script or run via terminal with supported arguments.

---

## Code Conventions

| Convention | Value |
|------------|-------|
| Language | English only |
| Encoding | UTF-8 (`chcp 65001`) |
| Elevation | Failsafe `fltmc` elevation check with PowerShell RunAs |
| Versioning | `vYYYY.MM.DD` format |
| Signature | `= Rooted by VladiMIR | AI = \| github.com/GinCz` |
| Performance | Suppressed stdout directory iteration, parallel file removal |

---

## Author

**VladiMIR Bulantsev** (GinCz) — Linux SysAdmin, DevOps & Security Engineer, Czech Republic

* 🌐 GitHub: [github.com/GinCz](https://github.com/GinCz)
* 🐧 Linux Server Repositories: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)
* 💼 Windows Automation: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)

`= Rooted by VladiMIR | AI = | v.2026.08.16 | github.com/GinCz =`

---

<div align="center">

*Tested on Windows 10 & Windows 11 — Production Ready*

</div>

---

<div align="center">

<a href="https://www.linkedin.com/in/gincz/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white" alt="LinkedIn" /></a>
&nbsp;&nbsp;<b>|||</b>&nbsp;&nbsp;
<a href="https://uslugi.yandex.ru/profile/VladimirBulantsev-1756893" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Яндекс.Услуги-FC3F1D?style=flat&logo=yandex&logoColor=white" alt="Яндекс.Услуги" /></a>

<br/><br/>

<sub><b>= Rooted by VladiMIR + AI &nbsp;|&nbsp; <a href="https://github.com/GinCz" target="_blank" rel="noopener noreferrer">github.com/GinCz ↗</a> =</b></sub>

</div>

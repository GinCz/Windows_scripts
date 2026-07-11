<div align="center">

# Windows Scripts — VladiMIR Bulantsev (GinCz)

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Language-Batch%20%2F%20CMD-4D4D4D?logo=windowsterminal&logoColor=white)
![Version](https://img.shields.io/badge/Version-v2026--07--11-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Scripts](https://img.shields.io/badge/Scripts-12-orange)

**= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =**

A collection of Windows CMD/BAT/PowerShell utility scripts for system optimization,
diagnostics, benchmarking, software installation, and **Samba SMB network drive management**.

> By **VladiMIR Bulantsev** (GinCz) — Linux sysadmin · IPGuard · Cloudflare · Samba · Linux server · Ubuntu 24 · XRAY VPN · CrowdSec · Czech Republic

</div>

---

## Table of Contents

- [Scripts Overview](#scripts-overview)
- [SMB Network Drives — SMB\_Connect](#smb-network-drives--smb_connect)
- [Requirements](#requirements)
- [Usage](#usage)
- [Code Conventions](#code-conventions)
- [Author](#author)

---

## Scripts Overview

### System & Optimization

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 1 | `CMD_setting.bat` | Sets CMD font to Consolas 20pt, UTF-8 encoding, buffer size 120x9001 globally via registry | YES |
| 2 | `WIN_Optimize.bat` | 15-step deep optimizer: reserved storage, hibernation, services, SSD TRIM, visual effects, temp/disk cleanup, network, power plan, telemetry, DISM, WinSxS, SFC, CompactOS | YES |
| 3 | `AntiVir_OFF.bat` | Toggle Windows Defender real-time protection ON/OFF interactively | YES |

### Diagnostics & Benchmarking

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 4 | `MemTest_7z.bat` | Hardware stress test via 7-Zip benchmark: auto-installs 7-Zip, 10 passes, 256MB dictionary, 4 threads (detects RAM/CPU instability) | YES |
| 5 | `SMB_Test.bat` | Live SMB network benchmark: 50MB/5GB modes, measures upload/download speed with progress bar and MD5 integrity check | YES |

### Software Installers

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 6 | `Install_7zip_Universal.bat` | Auto-detects architecture (x64/arm64/x86), fetches latest 7-Zip version from 7-zip.org, silently installs | YES |
| 7 | `Telegram_Setup.bat` | Downloads and launches latest Telegram Desktop x64 installer via BITS transfer with live progress | no |
| 8 | `MEGA_x86_Setup.bat` | Downloads and launches MEGAsync x86 (32-bit) installer | no |
| 9 | `TeraBox_Setup.bat` | Downloads and launches TeraBox PC installer | no |
| 10 | `Google_Drive_Setup.bat` | Downloads and launches Google Drive for Desktop installer | no |
| 11 | `Heaven_Benchmark_Setup.bat` | Downloads and launches UNIGINE Heaven Benchmark 4.0 GPU stress test installer | no |

### SMB Network Drives

| # | Script | Description | Admin |
|---|--------|-------------|:-----:|
| 12 | `SMB_Connect.bat` | Connects all 10 Samba servers as network drives (A: – Y:) in parallel, color-coded status report, ~8 sec total | YES |

---

## SMB Network Drives — SMB_Connect

`SMB_Connect.bat` connects **10 Samba servers** simultaneously as Windows network drives.

```
[  OK  ]  A:  AWS_12       18.195.117.12
[  OK  ]  E:  IONOS_38     82.223.116.38
[  OK  ]  I:  ILYA_176     146.103.110.176
[  OK  ]  N:  PILIK_33     195.63.138.33
[  OK  ]  O:  4TON_237     144.124.228.237
[  OK  ]  Q:  SO_38        144.124.233.38
[  OK  ]  T:  TATRA_9      144.124.232.9
[  OK  ]  V:  SHAHIN_227   144.124.228.227
[  OK  ]  W:  STOLB_24     144.124.239.24
[  OK  ]  Y:  ALEX_47      109.234.38.47
```

All servers run **Samba on Ubuntu 24 LTS** with IPGuard triple-layer security.
See the full server-side setup in 👉 [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public).

---

## Requirements

- **OS:** Windows 10 / Windows 11
- **Shell:** CMD (Command Prompt) — not PowerShell
- **Admin rights:** Required for most scripts (see table above)
- **Internet access:** Required for all installer scripts

---

## Usage

1. Download the desired `.bat` script
2. Right-click the file
3. Select **Run as administrator** (for scripts requiring admin rights)
4. Follow the on-screen instructions

> **Warning:** Always review scripts before running them. Never run untrusted `.bat` files with administrator privileges.

---

## Code Conventions

| Convention | Value |
|------------|-------|
| Language | English only |
| First lines | `@echo off` + `cls` |
| Version format | `v2026-MM-DD` |
| Author tag | `= Rooted by VladiMIR + AI \| vYYYY.MM.DD \| github.com/GinCz =` |
| ANSI colors | Via `VirtualTerminalLevel` registry key |
| Admin check | Via `net session` at the top of every privileged script |
| Encoding | `chcp 65001` (UTF-8) |

---

## Author

**VladiMIR Bulantsev** (GinCz) — Linux sysadmin & DevOps, Czech Republic

> IPGuard · Cloudflare · Samba · Linux server · Ubuntu 24 · XRAY VPN · CrowdSec · Fail2Ban · FastPanel · bash scripting

- 🔗 GitHub: [github.com/GinCz](https://github.com/GinCz)
- 🐧 Linux server scripts: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)
- 👨‍💻 Profile: [github.com/GinCz](https://github.com/GinCz)

`= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =`

---

<div align="center">

*Tested on Windows 10 & Windows 11 — Use at your own risk*

</div>

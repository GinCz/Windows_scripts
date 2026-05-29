<div align="center">

# Windows Scripts

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Language-Batch%20%2F%20CMD-4D4D4D?logo=windowsterminal&logoColor=white)
![Version](https://img.shields.io/badge/Version-v2026--05--05-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Scripts](https://img.shields.io/badge/Scripts-11-orange)

**= Rooted by VladiMIR | AI =**

A collection of Windows CMD/BAT utility scripts for system optimization,
diagnostics, benchmarking, and software installation.
All scripts follow a unified code style and versioning convention.

</div>

---

## Table of Contents

- [Scripts Overview](#scripts-overview)
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
| Author tag | `= Rooted by VladiMIR \| AI =` |
| ANSI colors | Via `VirtualTerminalLevel` registry key |
| Admin check | Via `net session` at the top of every privileged script |
| Encoding | `chcp 65001` (UTF-8) |

---

## Author

**VladiMIR Bulantsev** | [github.com/GinCz](https://github.com/GinCz)

`= Rooted by VladiMIR | AI =`

---

<div align="center">

*Tested on Windows 10 & Windows 11 — Use at your own risk*

</div>

# Windows Scripts

> = Rooted by VladiMIR | AI = | v2026-05-05
> 
> A collection of Windows CMD/BAT utility scripts for system optimization, diagnostics, and software installation.
> All scripts follow the same code style and versioning convention.

---

## Rules & Conventions

- All code and comments are written in **English**
- Every script starts with `@echo off` + `cls` (no `clear` — it does not exist in Windows CMD)
- Version tag format: `v2026-MM-DD`
- Author tag: `= Rooted by VladiMIR | AI =`
- ANSI color support via `VirtualTerminalLevel` registry key
- Admin check via `net session` at the top of every privileged script
- `chcp 65001` for UTF-8 encoding

---

## Scripts

| # | File | Description | Requires Admin |
|---|------|-------------|----------------|
| 1 | [CMD_setting.bat](CMD_setting.bat) | Sets CMD font to Consolas 20pt, UTF-8 encoding, buffer size 120x9001 globally via registry | ✅ Yes |
| 2 | [WIN_Optimize.bat](WIN_Optimize.bat) | 15-step Windows deep optimizer: reserved storage, hibernation, services, SSD TRIM, visual effects, temp cleanup, disk cleanup, network fix, power plan, telemetry, DISM, WinSxS, SFC, CompactOS | ✅ Yes |
| 3 | [MemTest_7z.bat](MemTest_7z.bat) | Hardware stress test using 7-Zip benchmark — auto-installs 7-Zip if missing, runs 10 passes with 256MB dictionary on 4 threads to detect RAM/CPU instability | ✅ Yes |
| 4 | [Install_7zip_Universal.bat](Install_7zip_Universal.bat) | Universal 7-Zip installer — auto-detects architecture (x64/arm64/x86), fetches latest version number from 7-zip.org, downloads and silently installs | ✅ Yes |
| 5 | [SMB_Test.bat](SMB_Test.bat) | Live SMB network benchmark — interactive path and mode selection (50MB fast / 5GB deep), measures upload/download speed with progress bar, MD5 integrity check | ✅ Yes |
| 6 | [AntiVir_OFF.bat](AntiVir_OFF.bat) | Toggle Windows Defender real-time protection ON/OFF interactively | ✅ Yes |
| 7 | [Telegram_Setup.bat](Telegram_Setup.bat) | Downloads and launches the latest Telegram Desktop x64 installer via BITS transfer with live progress | ❌ No |
| 8 | [MEGA_x86_Setup.bat](MEGA_x86_Setup.bat) | Downloads and launches MEGAsync x86 (32-bit) installer | ❌ No |
| 9 | [TeraBox_Setup.bat](TeraBox_Setup.bat) | Downloads and launches TeraBox PC installer | ❌ No |
| 10 | [Google_Drive_Setup.bat](Google_Drive_Setup.bat) | Downloads and launches Google Drive for Desktop installer | ❌ No |
| 11 | [Heaven_Benchmark_Setup.bat](Heaven_Benchmark_Setup.bat) | Downloads and launches UNIGINE Heaven Benchmark 4.0 GPU stress test installer | ❌ No |

---

## Usage

1. Right-click the `.bat` file
2. Select **Run as administrator** (for scripts marked ✅)
3. Follow on-screen instructions

---

## Author

**VladiMIR** | [github.com/GinCz](https://github.com/GinCz)

```
= Rooted by VladiMIR | AI =
```

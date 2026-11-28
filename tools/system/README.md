# Windows System Optimization, Diagnostics & Security Audits

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `tools/system/`

Battle-tested scripts for deep Windows OS cleanup, memory stress verification, security/cryptominer triage, and performance tuning.

---

## ⚡ Tool Catalog

| Script | Purpose | Highlights |
| :--- | :--- | :--- |
| `CLEAN.cmd` | Deep Disk Cleaner | Clears Windows Temp, Prefetch, CrashDumps, SoftwareDistribution and Windows Update cache |
| `WIN_Optimize.bat` | Performance Tweak | Disables telemetry, unnecessary background services, Cortana, and tracking tasks |
| `WIN_Optimize_restart.bat` | Reboot Pipeline | Executes system optimization pipeline and triggers clean reboot |
| `System_Security_Miner_Audit.cmd`| Security Audit | Probes running processes, suspicious GPU/CPU load, hidden scheduled tasks, and rogue miners |
| `MemTest_7z.bat` | RAM Stability | Runs multi-threaded 7-Zip LZMA compression stress loops to test system memory stability |
| `AntiVir_OFF.bat` | Security Toggle | Temporarily suppresses Windows Defender real-time protection for benchmarking |
| `CMD_setting.bat` | Shell UX | Configures raster fonts, UTF-8 code page (65001), and color scheme for CMD |
| `Disable_Windows_Update_Power_Flyout.ps1`| UX Fix | Suppresses intrusive Windows Update restart alerts and flyouts |
| `Nox_AdBlock.cmd` | Emulator Tweak | Blocks advertising telemetry hosts for Nox Android emulator |
| `Antigravity_Health_Check.ps1`| AI Dev Tools | Routine maintenance: purges stale daemon sockets, presence locks, and crash logs |

---

## ⚠️ Safety Information

* All cleaning and optimization operations are designed to be safe and reversible.
* `System_Security_Miner_Audit.cmd` is read-only by default and logs findings to an audit report.

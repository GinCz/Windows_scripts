# Ultarix System Monitor for Windows

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Project: `projects/Ultarix-Monitor/`  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Latest Version: `v009`

Enterprise telemetry, hardware health watchdog, and remote metrics daemon for Windows desktop and server environments.

---

## ⚡ Overview

`Ultarix-Monitor` provides lightweight, low-overhead system observability:
* **Metrics Tracked:** CPU per-core load, RAM commit vs physical usage, NVMe/SSD temperatures, GPU utilization, and network adapter throughput.
* **Lightweight Daemon:** Runs as an optimized background service or scheduled task without impact on foreground gaming or rendering.
* **Alerting Engine:** Triggers alerts upon critical thresholds (high thermals, disk fill > 90%, suspicious sustained process spikes).

---

## 📥 Direct Download & Launch

| Package | Version | Download | Type |
| :--- | :-: | :--- | :--- |
| **Ultarix-Monitor Setup v009** | `v009` | [📥 Ultarix-Monitor_Setup_v009.cmd](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/projects/Ultarix-Monitor/Ultarix-Monitor_Setup_v009.cmd) | Automated Installer |
| **Ultarix Universal Setup** | `v009` | [📥 ULTARIX_Universal_Setup.cmd](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/projects/Ultarix-Monitor/ULTARIX_Universal_Setup.cmd) | Standalone Setup |

---

## 📋 Version History

<details>
<summary><b>Click to expand changelog</b></summary>

### v009 (Latest)
* Added dynamic thermal monitoring for modern NVMe drives.
* Improved service installation resilience on Windows 11 24H2.
* Reduced background telemetry idle overhead to < 0.2% CPU.

### v008
* Initial release of the unified Ultarix hardware telemetry engine.

</details>

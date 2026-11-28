# GIN-Agent for Windows (Autonomous Remote Management Agent)

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Project: `projects/GIN-Agent/`  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Latest Version: `v043`

Autonomous, single-file polyglot (`.cmd` + embedded PowerShell) remote systems management and diagnostics agent for Windows 10/11 and Windows Server.

---

## ⚡ Overview

`GIN-Agent` is designed as a zero-dependency, ultra-resilient workstation administration agent:
* **Standalone Architecture:** Single polyglot batch file with zero external `.ps1` requirements.
* **3-Tier Redundant Auto-Updater:** Automatically checks GitHub Primary ➔ EU Node ➔ RU Node for version parity and self-updates seamlessly.
* **Remote Support Integration:** Configures and establishes secure RustDesk, Supremo, or reverse tunnels on demand.
* **Hardware & Process Watchdog:** Real-time health metrics, memory checks, SSD diagnostics, and network bandwidth tests.

---

## 📥 Direct Download & Packages

| Package | Version | Download | Verification |
| :--- | :-: | :--- | :--- |
| **GIN-Agent Standalone CMD** | `v043` | [📥 GIN-Agent_Windows.cmd](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Agent_Windows.cmd) | UTF-8 CRLF |
| **GIN-Agent Companion ZIP** | `v043` | [📥 GIN-Agent_Windows_v043.zip](https://github.com/GinCz/Windows_scripts/raw/main/projects/GIN-Agent/GIN-Agent_Windows_v043.zip) | ZIP Archive |

---

## 📋 Version History

<details>
<summary><b>Click to expand changelog</b></summary>

### v043 (Latest)
* Enhanced multi-region update probe with 5-second connection timeouts.
* Optimized process watchdog and remote session recovery.
* Automated companion `.zip` packaging.

### v042
* Added silent diagnostic mode and hardware JSON export.
* Fixed socket hang when querying offline endpoints.

</details>

# 🛡️ GIN-VPN: High-Speed Native Xray Desktop Client (VLESS + Reality + Vision)

<div align="center">

![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208.1%20%7C%2010%20%7C%2011%20%7C%20Server-0078D4?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Language-Go%201.22+-00ADD8?logo=go&logoColor=white)
![Core](https://img.shields.io/badge/Core-Xray%20VLESS%20Reality%20Vision-FF6D00)
![Release](https://img.shields.io/badge/Release-v056-brightgreen)
![License](https://img.shields.io/badge/License-Freeware%20%7C%20Free%20to%20Use-blue)

**Ultra-fast, native Win32 anti-censorship desktop client with embedded Xray-core. Bypasses deep packet inspection (DPI) with zero external dependencies and zero background runtime overhead.**

[⬇️ Download v056](#-quick-download--latest-release-v056) • [Quick Start](#-quick-start) • [Key Features](#-key-features) • [Changelog](CHANGELOG.md)

</div>

---

## 🚀 Quick Download & Latest Release (v056)

<div align="center">

### 🛡️ [⬇️ Click Here to Download GIN-VPN.exe (v056)](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN.exe)
*Single standalone executable & auto-installer (15.9 MB) • Windows 7/8.1/10/11 & Server*

</div>

> [!NOTE]
> **Strict Single-Release Policy:** We exclusively distribute **only the latest, thoroughly tested production build**. Outdated legacy versions are retired and not hosted here to ensure all users receive the most stable, bug-free, and optimized experience.

### ⚡ 1-Click PowerShell Install
Copy and paste into Windows PowerShell:
```powershell
Invoke-WebRequest -Uri "https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN.exe" -OutFile "$env:USERPROFILE\Downloads\GIN-VPN.exe"; Start-Process "$env:USERPROFILE\Downloads\GIN-VPN.exe"
```

---

## ⚡ Quick Start

1. **Download** the single standalone binary [`GIN-VPN.exe`](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN.exe).
2. **Run it** — no Python, .NET, or external runtimes required. The high-speed Xray-core engine is embedded directly inside the PE binary.
3. **Paste your VLESS URL** (click `[ 📋 Paste ]`) and press **`[ ▶ CONNECT VPN ]`**.

---

## 🌟 Key Features

* **🛡️ Single-Instance Guard (v056):** Prevents multiple running processes via named Win32 mutex and window class detection. Auto-restores and focuses existing window on duplicate launches.
* **⚡ Native Embedded Xray-Core:** High-performance VLESS + Reality + Vision implementation capable of gigabit throughput with low memory footprint (~25 MB RAM).
* **🌐 Dual IP Leak Verification:** Simultaneous real-time detection of external ISP IP and VPN tunnel IP with ping latency measurements.
* **🔃 Interactive Server Management:** Reorder connection priority with `[ ▲ Up ]` and `[ ▼ Down ]` buttons, auto-reconnect, and health checks.
* **🔄 Smart In-App Auto-Updater:** 1-Click background check against GitHub raw releases; right-click for silent instant update.
* **💾 Windows Persistence:** Remembers selected language (RU/EN), dark/OLED themes, and active servers across restarts in Windows Registry and local config.

---

## 👤 Author & Maintainer

* **Author:** **Vladimir Bulantsev** ([GinCz ↗](https://github.com/GinCz))
* **Specialization:** Senior Infrastructure & DevOps Engineer, PCI DSS Certified Analyst, Windows & Linux Sysadmin.
* **Email:** `gin@volny.cz` | `gin.vladimir@gmail.com`
* **LinkedIn:** [linkedin.com/in/gincz ↗](https://www.linkedin.com/in/gincz/)
* **Repository:** [https://github.com/GinCz/Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)

---

## 📄 License & Distribution

This application is provided completely **free of charge (Freeware)** for personal, educational, and commercial use.
- **100% Free:** Zero ads, zero telemetry, zero hidden monetization, zero subscription fees.
- **Proprietary Freeware Core:** The network management engine, system tray integration, and UI architecture are developed and maintained exclusively by Vladimir Bulantsev. Reverse engineering, decompilation, redistribution for a fee, or unauthorized repackaging are strictly prohibited.

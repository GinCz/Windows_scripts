# 🌐 GIN-NetScan: Ultra-Fast Multi-Subnet Hardware Network Discovery & Latency Profiler

<div align="center">

![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(64--bit)-0078D4?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Language-Go%201.22+-00ADD8?logo=go&logoColor=white)
![Architecture](https://img.shields.io/badge/UI-Native%20Win32%20GDI-success)
![Release](https://img.shields.io/badge/Release-v035-brightgreen)
![License](https://img.shields.io/badge/License-Freeware%20%7C%20Free%20to%20Use-blue)

**Ultra-fast, standalone network discovery and diagnostics desktop engine for Windows. Scans entire IPv4 subnets (`/24`, `/16`) in seconds via hardware ARP inspection and multi-threaded ICMP probes with zero external dependencies.**

[⬇️ Download v035](#-quick-download--latest-release-v035) • [Key Features](#-key-features) • [Device Categorization](#-color-coded-device-classes) • [Service Auditor](#-36-port-service-auditor) • [Changelog](CHANGELOG.md)

</div>

---

## 🚀 Quick Download & Latest Release (v035)

<div align="center">

### 🌐 [⬇️ Click Here to Download GIN-NetScan.exe (v035)](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-NetScan/GIN-NetScan.exe)
*Single standalone executable & auto-installer (3.1 MB) • Windows 10/11 64-bit*

</div>

> [!NOTE]
> **Strict Single-Release Policy:** We exclusively distribute **only the latest, thoroughly tested production build**. Outdated legacy versions are retired and not hosted here to ensure all users receive the most stable, bug-free, and optimized experience.

### ⚡ 1-Click PowerShell Install
Copy and paste into Windows PowerShell:
```powershell
Invoke-WebRequest -Uri "https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-NetScan/GIN-NetScan.exe" -OutFile "$env:USERPROFILE\Downloads\GIN-NetScan.exe"; Start-Process "$env:USERPROFILE\Downloads\GIN-NetScan.exe"
```

---

## 🌟 Key Features

* **⚡ Ultra-Fast Parallel Hardware Discovery:** Probes entire IPv4 subnets (`/24`, `/16`) in seconds using asynchronous ARP hardware table inspection and ICMP ping probes.
* **🎨 Color-Coded Ping Latency (RTT):**
  * `< 5 ms`: Emerald Green (Ultra-fast local LAN)
  * `< 30 ms`: Fluent Blue (Good stable connection)
  * `≥ 30 ms`: Amber / Orange (High latency or Wi-Fi interference)
* **🔍 Full 36-Port Service Auditor:** Deep port scan for HTTP, HTTPS, SSH, RDP, SMB, RTSP, DNS, SNMP, MQTT, etc., with dedicated multi-threaded audit window (on-demand via right-click).
* **💾 1-Click Log Export:** Exports full network inventory report directly to Desktop in UTF-8 formatted text.
* **📦 2-in-1 Portable + Permanent Installer:**
  * Runs instantly with zero dependencies (.NET not required).
  * 1-Click install into `C:\Program Files\GIN-NetScan` with desktop and start menu shortcuts.

---

## 🌈 Color-Coded Device Classes

| Icon & Emoji | Category | Distinct Color | Typical Nodes |
| :---: | :--- | :--- | :--- |
| 👑 🌐 | **Gateway / Router** | Royal Indigo / Purple | Default Gateway, Core Router |
| 📱 🍎 | **Apple Devices** | Apple Sky Blue | iPhone, iPad, MacBook, Mac Mini |
| 📱 📲 | **Android & Smartphones** | Emerald Green | Android Phones, Tablets |
| 💻 🖥️ | **PC / Workstations** | Fluent Blue | Desktop PCs, Windows Laptops |
| ⚡ 💡 | **Smart IoT Nodes** | Amber Gold | Smart Bulbs, Relays, ESP32/ESP8266 |
| 📡 📶 | **Access Points & Mesh** | Cyan / Teal | UniFi, Keenetic, TP-Link Mesh |
| 📹 📷 | **Surveillance Cameras** | Coral Red | IP Cameras, RTSP Streamers, NVR |
| 📺 🎬 | **Smart TVs & Players** | Magenta / Violet | Android TV, Apple TV, Chromecast |
| 🖨️ 📄 | **Network Printers** | Bronze / Amber | Laser/Inkjet Network Printers |
| 💻 🗄️ | **NAS Servers & Storage** | Deep Navy | Synology, QNAP, TrueNAS, Samba |
| 👻 🕵️ | **Ghost / Stealth Nodes** | Slate Gray | Unknown OUI, Unidentified Hardware |

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
- **Proprietary Freeware Core:** The network discovery engine and Win32 GDI architecture are developed and maintained exclusively by Vladimir Bulantsev. Reverse engineering, decompilation, redistribution for a fee, or unauthorized repackaging are strictly prohibited.

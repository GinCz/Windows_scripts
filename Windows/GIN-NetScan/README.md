# 🌐 GIN-NetScan by VladiMIR+AI

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v026%20(Latest%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-NetScan)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Architecture](https://img.shields.io/badge/Architecture-x64%20(Native%20Win32%20GUI)-purple.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-Vladimir%20Bulantsev%20(GinCz)-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, standalone, portable native Windows network scanner and security audit utility developed for IT administrators, network engineers, and system operators. It requires zero external dependencies, runtimes (.NET / Java / Python), or installation.

---

## ⚡ Direct Download (Latest Single Release)

- 📥 **Executable:** [`GIN-NetScan_v026.exe`](GIN-NetScan_v026.exe) *(Portable 2-in-1 application & installer)*

> **Zero Installation Required:** Download `GIN-NetScan_v026.exe` and launch directly on any Windows workstation or server. Only the latest stable release binary is distributed in this repository.

---

## 🌟 Key Features & Capabilities

### 1. High-Speed Subnet Discovery & Hardware Identification
* **Hardware SendARP & Raw ICMP:** Probes entire IPv4 `/24` subnets (254 addresses) in under 1.5 seconds.
* **Automatic Multi-Interface Detection:** Seamlessly enumerates physical Ethernet adapters, Wi-Fi interfaces, and VPN tunnels (XRAY, WireGuard, OpenVPN, Hyper-V, WSL).
* **Comprehensive MAC OUI Database:** Automatically identifies manufacturers for 300+ network hardware vendors (Apple, Intel, Cisco, TP-Link, MikroTik, Synology, Samsung, Hikvision, Espressif, etc.).
* **Deep Apple Model Decoding:** Translates Apple internal hardware identifiers (e.g. `iPhone15,2` -> `iPhone 14 Pro`, `MacBookPro18,1` -> `MacBook Pro 16-inch M1 Pro`).

### 2. Live Multi-Host Port & Service Security Audit
* **Dedicated Service Scanner Window (`🔍 Scan Ports`):** Audits 36 standard infrastructure and service ports across all discovered live hosts concurrently:
  * **Management:** SSH (22), Telnet (23), RDP (3389), VNC (5900), WinRM (5985/5986), Webmin (10000).
  * **Web Services:** HTTP (80/8080/8000), HTTPS (443/8443).
  * **File & Directory:** SMB/NetBIOS (139/445), FTP (21), NFS (2049).
  * **Databases:** MySQL (3306), PostgreSQL (5432), MS SQL (1433), Redis (6379), MongoDB (27017).
  * **Network Core:** DNS (53), SNMP (161), NTP (123).

### 3. Native Win32 Owner-Drawn High-DPI GUI
* **Vivid Action Controls:** High-visibility owner-drawn buttons with distinct color coding:
  * `▶ Start Scan` — Emerald Green
  * `⏹ Stop` — Crimson Red
  * `🔍 Scan Ports` — Windows Fluent Sapphire Blue
  * `💾 Save Log` — Deep Cyan / Teal
  * `Install` — Coral Red (Switches to Green `Installed` when registered)
* **Embedded Resource Icons:** Multi-resolution PE icon resource (16x16 to 256x256 RGBA 32-bit) embedded directly in the binary for crisp Windows Explorer tiles and Desktop shortcuts.
* **Non-Blocking Multithreaded Engine:** Runs background probes with `BELOW_NORMAL_PRIORITY_CLASS` to guarantee zero UI stutter and 100% responsiveness.

### 4. 2-in-1 Portable Mode & Permanent System Installation
* Run directly as a standalone `.exe` without touching the system registry or disk.
* Or click `Install` to register permanently in `C:\Program Files\GIN-NetScan` with Desktop / Start Menu shortcuts and standard Windows `Apps & Features` Control Panel uninstaller.

### 5. Persistent Session Cache & Clean UTF-8 Export
* **Offline Host Tracking:** Maintains discovered hosts during the session; sleeping or disconnected devices remain listed in gray text with preserved historical fingerprints.
* **One-Click Export:** Click `💾 Save Log` to generate a formatted UTF-8 report (`Network_Deep_Audit_Report.txt`) directly onto the Desktop.

---

## 📋 System Requirements

* **Operating System:** Windows 7, 8, 8.1, 10, 11 / Windows Server 2008 R2, 2012, 2016, 2019, 2022, 2025 (64-bit).
* **Privileges:** Standard User (Elevated Administrator recommended for raw ICMP and `C:\Program Files` installation).
* **RAM / Disk:** ~15 MB RAM / 3.0 MB Disk space.

---

## 📜 Version History

| Version | Date | Key Highlights |
|:---:|:---:|:---|
| **v026** | **2026-10-05** | **Current Release:** Expanded window viewport to 1280px and symmetrically optimized toolbar control layout for 100% visibility of all action buttons (including `💾 Save Log`), updated version constants, and unified single-installer deployment across repositories. |
| **v025** | 2026-10-04 | Native Win32 Owner-Drawn Toolbar Buttons (`BS_OWNERDRAW`) with vivid saturated color palettes and embedded multi-resolution PE icon resources. |
| **v024** | 2026-10-04 | Added official Windows uninstaller registry integration and update notifications. |
| **v020** | 2026-10-04 | Dedicated 36-port multi-host security scanner dialog with live progress tracking. |
| **v018** | 2026-10-04 | All-in-one automatic deep discovery (mDNS, Bonjour, NetBIOS, SSDP) during initial scan. |
| **v001** | 2026-10-04 | Initial standalone Win32 hardware ARP & ICMP network scanner release. |

---

## 📄 License & Author

* **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))
* **License:** [MIT License ↗](https://opensource.org/licenses/MIT) — 100% Free & Open Source.

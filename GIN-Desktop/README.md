# ⚡ GIN-Desktop `v043` (Universal Release)

<div align="center">

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(32%2F64--bit)-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![Architecture](https://img.shields.io/badge/Architecture-Native%20WinAPI%20%7C%20GDI%2B-239120?style=for-the-badge&logo=csharp&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![RAM Usage](https://img.shields.io/badge/Idle%20Memory-~2--4%20MB-00E676?style=for-the-badge&logo=speedtest&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20Open%20Source-9C27B0?style=for-the-badge)](LICENSE)

<br/>

### 🌟 Unified Windows Desktop Companion: Hot-Corner Dock Bar, 4K Wallpaper Engine, Calendar HUD, Live Hardware Monitor & Real-Time Weather
**Universal 32/64-bit • Native WinAPI • Independent Modular ON/OFF Engines • 12 Signature Themes • 12 Languages**

<br/>

[Download GIN-Desktop v043 Setup.exe](https://github.com/GinCz/Windows_scripts/blob/main/GIN-Desktop/GIN-Desktop_v043_Setup.exe)

</div>

---

## 💡 Overview

**GIN-Desktop** is an ultra-lightweight, high-performance Windows desktop companion built in native C# with pure WinAPI and GDI+ (~2–4 MB RAM idle).

### Key Integrated Modules:
1. **Top Hot-Corner Dock Bar**: An auto-hiding application launcher that slides smoothly from the top of the monitor when the cursor moves to the top-left corner. Supports folder trees, shortcuts, drag & drop, and customized brand icons.
2. **Dynamic 4K Wallpaper & Calendar HUD**: Multi-tier 4K background downloader with automatic daily midnight refresh at 00:03, 24 curated typefaces, and dual alternating desktop buffers.
3. **Live Hardware Monitor HUD**: Optional real-time metrics badge on the Dock Bar displaying CPU %, RAM %, GPU %, and GPU Temperature (°C).
4. **Real-Time Weather HUD**: Weather pill rendered cleanly below the desktop Calendar HUD, powered by Open-Meteo or wttr.in with auto-geolocation.
5. **Portable-First Configuration**: Settings are preserved directly in the application folder (`config.json`), keeping the Windows registry completely clean.

---

## 🚀 What's New in v043

- **Rebranded as GIN Desktop**: Unified project architecture consolidating previous dock and wallpaper experiments under a clean product name.
- **Top-Only Placement & Top-Left Hover**: Eliminated cluttered side placement; dock bar lives strictly at the top of the screen and activates on hovering the top-left corner.
- **Configurable Shortcuts Path with Browse Button**: Defaulted to `D:\UTIL\GIN-Desktop\` with an interactive `[Browse...]` button and clipboard copy-paste support.
- **Live Hardware Monitor HUD**: Checkbox options for CPU %, RAM %, GPU %, and GPU Temperature monitoring directly on the Dock Bar.
- **Real-Time Weather Badge**: Configurable weather widget directly under the Calendar HUD with Open-Meteo and wttr.in support.
- **Midnight Calendar & Wallpaper Sync**: Automatic background swap and calendar date advancement at 00:03 every day.
- **7-Day & 100 MB Cache Quota**: Automatic disk cleanup purging temporary wallpapers older than 7 days or exceeding 100 MB.
- **Cryptographic SHA-256 Checksum Validation**: Integrity verification on automated application updates.

---

## ⚙️ Requirements & Installation

- **OS**: Windows 10 / 11 (32-bit or 64-bit)
- **Runtime**: Built-in .NET Framework 4.5+ (Standard on all modern Windows installations)
- **Installer**: Run `GIN-Desktop_v043_Setup.exe` for turnkey 1-click deployment.

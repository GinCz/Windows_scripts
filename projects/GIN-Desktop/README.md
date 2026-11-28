# ⚡ GIN-Desktop `v054` (Universal Release)

<div align="center">

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(32%2F64--bit)-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![Architecture](https://img.shields.io/badge/Architecture-Native%20WinAPI%20%7C%20GDI%2B-239120?style=for-the-badge&logo=csharp&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![RAM Usage](https://img.shields.io/badge/Idle%20Memory-~2--4%20MB-00E676?style=for-the-badge&logo=speedtest&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20Open%20Source-9C27B0?style=for-the-badge)](LICENSE)

<br/>

### 🌟 Unified Windows Desktop Companion: Hot-Corner Dock Bar, 4K Wallpaper Engine, Calendar HUD, Live Hardware Monitor & Real-Time Weather
**Universal 32/64-bit • Native WinAPI • Independent Modular ON/OFF Engines • 12 Signature Themes • 12 Languages**

<br/>

[Download GIN-Desktop v054 Setup.exe](https://github.com/GinCz/Windows_scripts/blob/main/projects/GIN-Desktop/GIN-Desktop_v054_Setup.exe)

</div>

---

## 💡 Overview

**GIN-Desktop** is an ultra-lightweight, high-performance Windows desktop companion built in native C# with pure WinAPI and GDI+ (~2–4 MB RAM idle).

### Key Integrated Modules:
1. **Top Hot-Corner Dock Bar**: An auto-hiding application launcher that slides smoothly from the top of the monitor when the cursor moves to the top-left corner. Supports folder trees, shortcuts, drag & drop, and customized brand icons.
2. **Dynamic 4K Wallpaper & Calendar HUD**: Multi-tier 4K background downloader with automatic daily midnight refresh at 00:03, 24 curated typefaces, and dual alternating desktop buffers.
3. **Celestial Shimmer Audio Engine**: Signature peaceful velvet bells chime (from GIN-Wallpaper) on every wallpaper transition and sound activation.
4. **Hardware Monitor Under Weather Badge**: Real-time metrics badge rendered directly onto the desktop wallpaper below the Weather pill displaying CPU %, RAM %, GPU %, and GPU Temperature (°C).
5. **Real-Time Weather HUD with Localized City**: Weather pill rendered cleanly below the desktop Calendar HUD displaying city name, temperature, and localized conditions powered by Open-Meteo or wttr.in with auto-geolocation.
6. **Silent Tray HUD Auto-Updater**: Zero-popup background update pipeline with a non-activating toast HUD above the system tray and gentle pure-sine audio feedback identical to GIN-Voice.
7. **Portable-First Configuration**: Settings are preserved directly in the application folder (`config.json`), keeping the Windows registry completely clean.

---

## 🚀 What's New in v050

- **Critical Windows .NET Framework Installer Launch Fix**: Resolved root cause where `GIN-Desktop_vXXX_Setup.exe` failed to launch or install silently on clean Windows workstations (`MissingMethodException` on Mono's single-char `Trim(char)` overload). Enforced explicit `char[]` overloads across all modules.
- **Single Clean Start Menu Shortcut**: Installer writes strictly ONE direct shortcut (`GIN Desktop.lnk`) into the Windows Start Menu Programs root, purging legacy folders and eliminating clutter.
- **Direct Program Folder Quick Access**: Added `📁 Открыть папку программы` / `Open Program Folder` directly to the system tray context menu and Dock brand menu for instant access to the application directory and uninstaller.
- **Single Versioned Setup on Desktop**: Retains strictly 1 versioned installer (`GIN-Desktop_v050_Setup.exe`) on MEGA Desktop.

---

## ⚙️ Requirements & Installation

- **OS**: Windows 10 / 11 (32-bit or 64-bit)
- **Runtime**: Built-in .NET Framework 4.5+ (Standard on all modern Windows installations)
- **Installer**: Run `GIN-Desktop_v050_Setup.exe` for turnkey 1-click deployment.

# ⚡ GIN-Desktop `v045` (Universal Release)

<div align="center">

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(32%2F64--bit)-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![Architecture](https://img.shields.io/badge/Architecture-Native%20WinAPI%20%7C%20GDI%2B-239120?style=for-the-badge&logo=csharp&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![RAM Usage](https://img.shields.io/badge/Idle%20Memory-~2--4%20MB-00E676?style=for-the-badge&logo=speedtest&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20Open%20Source-9C27B0?style=for-the-badge)](LICENSE)

<br/>

### 🌟 Unified Windows Desktop Companion: Hot-Corner Dock Bar, 4K Wallpaper Engine, Calendar HUD, Live Hardware Monitor & Real-Time Weather
**Universal 32/64-bit • Native WinAPI • Independent Modular ON/OFF Engines • 12 Signature Themes • 12 Languages**

<br/>

[Download GIN-Desktop v045 Setup.exe](https://github.com/GinCz/Windows_scripts/blob/main/GIN-Desktop/GIN-Desktop_v045_Setup.exe)

</div>

---

## 💡 Overview

**GIN-Desktop** is an ultra-lightweight, high-performance Windows desktop companion built in native C# with pure WinAPI and GDI+ (~2–4 MB RAM idle).

### Key Integrated Modules:
1. **Top Hot-Corner Dock Bar**: An auto-hiding application launcher that slides smoothly from the top of the monitor when the cursor moves to the top-left corner. Supports folder trees, shortcuts, drag & drop, and customized brand icons.
2. **Dynamic 4K Wallpaper & Calendar HUD**: Multi-tier 4K background downloader with automatic daily midnight refresh at 00:03, 24 curated typefaces, and dual alternating desktop buffers.
3. **Live Hardware Monitor HUD**: Optional real-time metrics badge on the Dock Bar displaying CPU %, RAM %, GPU %, and GPU Temperature (°C).
4. **Real-Time Weather HUD**: Weather pill rendered cleanly below the desktop Calendar HUD, powered by Open-Meteo or wttr.in with auto-geolocation.
5. **Silent Tray HUD Auto-Updater**: Zero-popup background update pipeline with a non-activating toast HUD above the system tray and gentle pure-sine audio feedback identical to GIN-Voice.
6. **Portable-First Configuration**: Settings are preserved directly in the application folder (`config.json`), keeping the Windows registry completely clean.

---

## 🚀 What's New in v045

- **Silent Non-Activating Tray HUD**: Replaced modal popup dialogs with an elegant auto-fading toast window right above the system tray icons.
- **Pure-Sine Gentle Sound Chimes**: In-memory audio synthesis matching GIN-Voice (350 Hz notice blip and 620 Hz completion chime).
- **Auto-Dismiss Notification**: Up-to-date notice disappears automatically after 3 seconds without interrupting work.
- **Dynamic Transition Updater**: Displays transition badge (e.g. `44 ➔ 45`), halts services and instances, updates files silently, and restarts with `--updated` status notice.
- **Clean Desktop Layout Preservation**: Automatic updates strictly bypass recreating desktop shortcuts, preserving the user's desktop layout.
- **Single Versioned Setup on Desktop**: Retains strictly 1 versioned installer (`GIN-Desktop_v045_Setup.exe`) on MEGA Desktop.

---

## ⚙️ Requirements & Installation

- **OS**: Windows 10 / 11 (32-bit or 64-bit)
- **Runtime**: Built-in .NET Framework 4.5+ (Standard on all modern Windows installations)
- **Installer**: Run `GIN-Desktop_v044_Setup.exe` for turnkey 1-click deployment.

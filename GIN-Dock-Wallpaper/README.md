# ⚡ GIN-Dock-Wallpaper `v038` (Universal Release)

<div align="center">

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(32%2F64--bit)-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![Architecture](https://img.shields.io/badge/Architecture-Native%20WinAPI%20%7C%20GDI%2B-239120?style=for-the-badge&logo=csharp&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![RAM Usage](https://img.shields.io/badge/Idle%20Memory-~2--4%20MB-00E676?style=for-the-badge&logo=speedtest&logoColor=white)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20Open%20Source-9C27B0?style=for-the-badge)](LICENSE)

<br/>

### 🌟 Unified Hot-Corner Application Dock & Dynamic 4K Wallpaper Calendar HUD Engine
**Universal 32/64-bit • Native WinAPI • Dual-Feature Independent Toggles • 12 Signature Themes • 12 Languages**

<br/>

[![Download Setup](https://img.shields.io/badge/🚀%20Download-GIN--Dock--Wallpaper%20v038%20Setup.exe-00E676?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Dock-Wallpaper/GIN-Dock-Wallpaper_v038_Setup.exe)
[![Alternative Script Setup](https://img.shields.io/badge/📦%201--Click-GIN--Dock--Wallpaper%20Setup%20v038.cmd-2196F3?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Dock-Wallpaper/GIN-Dock-Wallpaper_Setup_v038.cmd)

</div>

---

## 💡 Overview

**GIN-Dock-Wallpaper** unites two productivity utilities into a single, ultra-lightweight Windows desktop companion:
1. **Hot-Corner Application & Folder Dock**: An auto-hiding quick-access bar that slides out smoothly when your cursor touches the screen corner, providing instant access to folder hierarchies, system shortcuts, and frequently used applications.
2. **Dynamic 4K Wallpaper & Live Calendar HUD Engine**: A scheduler that fetches high-definition Ultra HD wallpapers and overlays an anti-aliased live calendar HUD onto your desktop.

Unlike resource-heavy Electron frameworks that consume hundreds of megabytes, **GIN-Dock-Wallpaper** runs directly on native Windows GDI+ and Win32 APIs, consuming just **~2 to 4 MB of RAM** while idling in the background.

---

## 🎨 Visual Identity & Key Highlights

- **Unified Sand-Colored 'G' Icon**: A clean, warm sand-toned visual emblem with the letter **G** across the application tray, the Windows installer, and the dedicated uninstaller.
- **Streamlined Brand Button**: The redundant left arrow icon next to the GIN brand logo has been completely removed, presenting a clean, modern aesthetic.
- **Independent Feature Switches**: Enable or disable either the Dock Bar or the Wallpaper Engine independently in Settings. If you only need the Dock or only need the Wallpaper, turn off the other with a single checkbox.
- **Top or Left Placement**: Position the dock bar along the top edge (sliding downwards) or the left edge (sliding rightwards).
- **Dual Font Size Sliders**: Separate typographic size controls for Folder buttons (7–16 pt) and open application items (7–16 pt).
- **Comprehensive Item Sorting**: Sort shortcuts and folders Alphabetically (A–Z default), Reverse Alphabetical (Z–A), Folders First, by File Extension, or by Modification Date.
- **12 Curated Visual Themes**:
  1. *Warm Sand (Default Signature)* — Warm desert gold, soft amber accents (`#D4A373`)
  2. *Midnight OLED* — Deep black with electric cyan accents (`#000000`, `#38BDF8`)
  3. *Cyberpunk Amber* — Obsidian base with high-contrast neon amber (`#120E0A`, `#F59E0B`)
  4. *Nordic Frost* — Glacial slate and cold arctic cyan (`#2E3440`, `#88C0D0`)
  5. *Emerald Forest* — Dark jade, evergreen, and mint highlights (`#081C14`, `#10B981`)
  6. *Deep Space Navy* — Deep indigo cosmic nebula tones (`#0B0E1B`, `#818CF8`)
  7. *Solarized Desert* — Terracotta stone and warm parchment (`#1E1A16`, `#CB4B16`)
  8. *Tokyo Neon* — Synthwave violet with vivid magenta glow (`#161026`, `#F43F5E`)
  9. *Pure Glass Slate* — Modern translucent graphite with crisp borders (`#181B22`, `#E2E8F0`)
  10. *Rose Gold Luxury* — Satin copper, dusk plum, and rose accents (`#21181C`, `#F472B6`)
  11. *Titanium Monochrome* — Industrial gray, graphite, and white (`#1A1A1A`, `#E5E5E5`)
  12. *Daylight Light Mode* — Pearl white card surfaces with crisp dark text (`#F5F7FA`, `#0F172A`)
- **Day / Night Switching**: Select Light Mode, Dark Mode, or Automatic system synchronization.
- **12 Multilingual Localizations**: Fully translated interface in English, Russian, Czech, German, French, Spanish, Italian, Portuguese, Polish, Ukrainian, Chinese, and Japanese.
- **Integrated Uninstaller**: Contains both `Uninstall.exe` and `uninstall.cmd` inside the program folder for clean removal of files, shortcuts, and registry entries.
- **Update Checking**: Automatic background checks on startup or manual checks via the system tray context menu.

---

## ⚙️ Configuration & Options

Access settings at any time by **right-clicking the Sand 'G' tray icon** or by clicking the `⚡ GIN` logo button on the dock.

| Tab | Available Options |
|---|---|
| **General** | Enable Dock Bar, Enable 4K Wallpaper & Calendar, Dock Placement (Top/Left), Language selector (12 languages), Windows Startup autostart, Automatic update check |
| **Appearance & Themes** | Day / Night mode (Auto, Day, Night), 12 Color themes, Folder font size slider, Item font size slider, Show labels (Folders only, All items, Icons only) |
| **Dock & Items** | Root folder path with Browse button, Item sorting modes (Alphabetical default), Auto-hide delay timer (200–1500 ms), Hot-corner pixel trigger radius |
| **Wallpaper & Calendar** | Wallhaven category filter (Nature, Cyberpunk, 3D, Space, Cars, Cities, Minimalism, Random), Change interval (15m to 24h), Live calendar HUD toggle, Immediate next wallpaper trigger, Save current wallpaper to Pictures |
| **About** | Version details, Author attribution, MIT license, Update verification |

---

## 🚀 Installation & Uninstallation

### Installation
- **Binary Installer**: Download and execute [GIN-Dock-Wallpaper_v032_Setup.exe](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Dock-Wallpaper/GIN-Dock-Wallpaper_v032_Setup.exe).
- **1-Click Script**: Or execute [GIN-Dock-Wallpaper_Setup_v032.cmd](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Dock-Wallpaper/GIN-Dock-Wallpaper_Setup_v032.cmd) with administrator privileges.

### Uninstallation
1. Open Windows **Settings → Installed Apps (Add or Remove Programs)** and select **GIN Dock Wallpaper**, or
2. Run `Uninstall.exe` directly inside the installation directory (`%ProgramFiles%\GIN-Dock-Wallpaper` or `%LocalAppData%\GIN-Dock-Wallpaper`).

---

## 🛠️ Building from Source

### On Windows
Run the automated build script:
```cmd
src\build.cmd
```
Uses the standard Microsoft .NET Framework compiler (`csc.exe`) included with Windows.

### On Linux (Cross-Compilation via Mono)
```bash
bash src/build.sh
```

---

## 📄 License

Distributed under the **MIT License**. Created by **Vladimir Bulantsev (@GinCz)** & **Antigravity**.

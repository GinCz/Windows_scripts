# 🖼 GIN-Wallpaper-Calend v026

> **Smart Desktop Wallpaper with Calendar for Windows** — lightweight native tray applet with installer  
> **Author:** [GinCz / Vladimir Bulantsev ↗](https://github.com/GinCz)  
> **Repository:** [Windows_scripts/GIN-Wallpaper ↗](https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper)  
> **License:** MIT

---

## 🚀 Quick Start — Installation

**Download Installer:**  
[`GIN-Wallpaper-Calend_v026_Setup.exe`](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Wallpaper/GIN-Wallpaper-Calend_v026_Setup.exe)

> **Run** → confirm `GIN-Wallpaper-Calend - Install?` [OK] → ✅ Done! (100% standalone native binary, no Python or external dependencies required).

---

## ✨ What's New in v026

| Feature | Description |
|---|---|
| 🚫 Anti-Duplication History Cache | Sliding window history of the last 100 wallpapers + dynamic 6-char random seed on every search completely eliminates repeating wallpapers |
| 👗 Girls & Models Precision (Categories=001) | Fixed Wallhaven `categories=001` (People category only, SFW `purity=100`) with 115,000+ real fashion model portraits, eliminating random tree fallback |
| 🚙 Trucks & Jeeps Precision | Category renamed from *Trucks & 4x4 Off-Road* to **Trucks & Jeeps** (`truck`, `pickup truck`, `jeep`, `lorry`, `off-road jeep`) for 100% vehicle accuracy |
| 📐 Clean Header Bar | Day/Night buttons separated from languages by dash, RU/EN/CS language order, and separated from sound button by dash with ~1mm (~4px) spacing |
| 🔊 Compact Sound Button | Reduced sound toggle button width from 180px to 140px for a much neater, balanced top header |
| 🔤 Zero Font Clipping (Col 2 Widened) | Reduced gap between font columns by ~5 mm and expanded Column 2 width to 420px so Century Gothic Bold and long date samples never truncate |
| 🌐 Full Trilingual Support | All 14 wallpaper categories fully translated into English (`EN` default), Czech (`CS` / Čeština), and Russian (`RU`) |
| 📉 Ultra-Low RAM Footprint (~1.5–2 MB) | Native WinAPI memory trimming (`SetProcessWorkingSetSize` + `debug.FreeOSMemory`) keeps idle process at ~1.5–2 MB |

---

## 📋 Version History

| Version | Date | Changes |
|---|---|---|
| **v026** | **2026-11-07** | **Anti-duplication history (last 100 IDs), dynamic seed on Wallhaven queries, categories=001 for Girls/Models (no tree fallbacks), category renamed to Trucks & Jeeps** |
| v025 | 2026-11-07 | Clean header layout with dashes, RU/EN/CS order, compact sound button, font column 2 widened to 420px with reduced gap, Cars & Supercars kept |
| v024 | 2026-11-07 | Added Trucks & 4x4 Off-Road category, added Girls & Aesthetic Portraits (strictly SFW, non-vulgar, purity=100) category; 14 categories total with full English/Czech/Russian support |
| v023 | 2026-11-07 | English by default, added full Czech (Čeština) language support across UI, calendar overlay and tray menu; minimal English-only installer dialog ('GIN-Wallpaper-Calend - Install?'); completely silent uninstaller with 0 popups |
| v022 | 2026-11-07 | Soft organic double bloop sound (220–360 Hz) on update completion, removed premature audio triggers |
| v021 | 2026-11-07 | Deep memory optimization (Variant A): WinAPI `SetProcessWorkingSetSize` and `debug.FreeOSMemory`, idle RAM drops to ~1.5–2 MB |
| v020 | 2026-11-07 | Font #16 replaced with Calibri Bold, verified Czech/Russian/English diacritics support |

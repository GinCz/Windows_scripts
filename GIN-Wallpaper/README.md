# 🖼 GIN-Wallpaper-Calend v025

> **Smart Desktop Wallpaper with Calendar for Windows** — lightweight native tray applet with installer  
> **Author:** [GinCz / Vladimir Bulantsev ↗](https://github.com/GinCz)  
> **Repository:** [Windows_scripts/GIN-Wallpaper ↗](https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper)  
> **License:** MIT

---

## 🚀 Quick Start — Installation

**Download Installer:**  
[`GIN-Wallpaper-Calend_v025_Setup.exe`](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Wallpaper/GIN-Wallpaper-Calend_v025_Setup.exe)

> **Run** → confirm `GIN-Wallpaper-Calend - Install?` [OK] → ✅ Done! (100% standalone native binary, no Python or external dependencies required).

---

## ✨ What's New in v025

| Feature | Description |
|---|---|
| 📐 Clean Header Bar | Day/Night buttons separated from languages by dash, RU/EN/CS language order, and separated from sound button by dash with ~1mm (~4px) spacing |
| 🔊 Compact Sound Button | Reduced sound toggle button width from 180px to 140px for a much neater, balanced top header |
| 🔤 Zero Font Clipping (Col 2 Widened) | Reduced gap between font columns by ~5 mm and expanded Column 2 width to 420px so Century Gothic Bold and long date samples never truncate |
| 🏎️ Cars & Supercars Kept | Preserved the classic 'Cars & Supercars' category without motorcycle dilution |
| 🚛 Trucks & 4x4 Off-Road | Dedicated category for semi-trucks, big commercial rigs, extreme 4x4 off-road, SUVs, and overland expedition vehicles |
| 👗 Girls: Models & Fashion (SFW) | Refined aesthetic portraiture category: high-fashion runway, model photography, and editorial portraits with guaranteed 100% SFW purity and zero vulgarity |
| 🌐 Full Trilingual Support | All 14 wallpaper categories fully translated into English (`EN` default), Czech (`CS` / Čeština), and Russian (`RU`) |
| 📉 Ultra-Low RAM Footprint (~1.5–2 MB) | Native WinAPI memory trimming (`SetProcessWorkingSetSize` + `debug.FreeOSMemory`) keeps idle process at ~1.5–2 MB |

---

## 📋 Version History

| Version | Date | Changes |
|---|---|---|
| **v025** | **2026-11-07** | **Clean header layout with dashes, RU/EN/CS order, compact sound button, font column 2 widened to 420px with reduced gap, Cars & Supercars kept, Trucks & Off-Road and aesthetic Girls: Models & Fashion categories** |
| v024 | 2026-11-07 | Added Trucks & 4x4 Off-Road category, added Girls & Aesthetic Portraits (strictly SFW, non-vulgar, purity=100) category; 14 categories total with full English/Czech/Russian support |
| v023 | 2026-11-07 | English by default, added full Czech (Čeština) language support across UI, calendar overlay and tray menu; minimal English-only installer dialog ('GIN-Wallpaper-Calend - Install?'); completely silent uninstaller with 0 popups |
| v022 | 2026-11-07 | Soft organic double bloop sound (220–360 Hz) on update completion, removed premature audio triggers |
| v021 | 2026-11-07 | Deep memory optimization (Variant A): WinAPI `SetProcessWorkingSetSize` and `debug.FreeOSMemory`, idle RAM drops to ~1.5–2 MB |
| v020 | 2026-11-07 | Font #16 replaced with Calibri Bold, verified Czech/Russian/English diacritics support |

# 🎙️ GIN-Voice [v023]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v023`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v023
* **Menu Renamed to "Настройки - Ввод ключа":** Context menu items updated with clean dash separator across all languages (RU: `⚙️ Настройки - Ввод ключа` / EN: `⚙️ Settings - API Key Setup`).
* **Win32 Menu Capture Deadlock Resolved:** Fixed application freezing when opening settings by implementing `TPM_RETURNCMD`, asynchronous message posting, and removing `WS_EX_TOPMOST` conflicts.
* **Dialog Message Processing:** Added Win32 `IsDialogMessageW` loop handling for responsive dialog focus and navigation.
* **Full Changelog & Architecture Codification (v022):** Comprehensive `CHANGELOG.md` and 7 Iron Rules in `RULES.md` preventing release desync and regression.

---

## 📦 Distribution
* `GIN-Voice_Setup_v023.exe` — Single-File Self-Extracting Installer, Application & Uninstaller (Deployed to MEGA Desktop).
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs.
* `dictionary.json` — Custom vocabulary replacements.
* `version.json` / `version.txt` — Release metadata.

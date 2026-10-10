# 🎙️ GIN-Voice [v018]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v018`  

---

## 🎯 What's New in v018
* **In-App Interactive Language Switcher:** Settings window now includes real-time `🇬🇧 English` and `🇷🇺 Русский` toggle buttons that dynamically re-render all UI elements without restarting.
* **Persistent UI Language:** Saved in `config.json` and retained across reboots and application restarts.
* **Windows Installed Apps List Integration:** Full registry registration (`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice`) for proper appearance in Windows 10/11 "Apps & features".
* **Tail-End Speech Preservation:** Removed aggressive silence trimming and added 200ms audio buffer flush ensuring no trailing words are dropped.
* **Dual-Layer API Key Storage:** Primary local storage in working directory (`config.json`) with automated fallback to Windows Registry.
* **HUD Font Selector:** Configurable font styles with non-bold default (`Comfortaa`).
* **Strict Versioning Policy:** Every modification automatically increments the version.

---

## 📦 Files
* `GIN-Voice_Setup_v018.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v018.exe` — Portable executable
* `GIN-Voice.exe` — Main runtime executable
* `Uninstall.exe` — Standalone Uninstaller with icon and signature 90-character terminal styling
* `uninstall.ps1` — PowerShell Uninstaller script
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

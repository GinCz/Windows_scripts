# 🎙️ GIN-Voice [v017]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v017`  

---

## 🎯 What's New in v017
* **Bilingual Setup Guide with Interactive Language Switcher:** `setup_guide.html` opens in English by default with two large glowing switcher buttons at the top (`🇬🇧 English` / `🇷🇺 Русский язык`), featuring comprehensive step-by-step onboarding for both languages.
* **Aesthetic HUD Font Customization:** Added support for beautiful, non-bold typography in the on-screen status HUD (defaulting to **Comfortaa**, with seamless support for *Segoe UI Variable*, *Bahnschrift*, *Montserrat*, *Consolas*). Configurable directly in the Settings window.
* **Save Confirmation Dialog & HUD Banner:** Clicking "Save & Apply" now displays an explicit confirmation dialog and a radiant top HUD banner (`✅ Ready | Hotkey: [F4]`), eliminating any ambiguity about application activation and tray status.
* **Windows Single-Instance Mutex & Process Protection:** Implemented a global Windows Mutex (`GIN_VOICE_RUNNING_MUTEX`). Relaunching the application focuses the existing Settings window rather than spawning conflicting duplicate processes.
* **Guaranteed Clean Installer Process Termination:** The installer automatically terminates any previous background instances via `taskkill` before overwriting the executable, preventing file lock errors.

---

## 📦 Files
* `GIN-Voice_Setup_v017.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v017.exe` — Portable executable
* `GIN-Voice.exe` — Main runtime executable
* `Uninstall.exe` — Standalone Uninstaller with icon and signature 90-character terminal styling
* `uninstall.ps1` — PowerShell Uninstaller script
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

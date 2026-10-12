# 🎙️ GIN-Voice [v026]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v026`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v026
* **Dictionary Editor Crash Fixed:** Resolved Win32 runtime crash when clicking "Edit Dictionary" in settings dialog. `dictionary.json` is now verified/created automatically and opened in Windows Notepad via a non-blocking background goroutine.
* **Safe Asynchronous External Launches:** Web URLs and HTML guide are decoupled from the Win32 window procedure to guarantee smooth, non-freezing UI interactions.
* **Restored Embedded PE Icon:** Single-binary installer and main application embed high-res `.rsrc` icons (`app.ico`).
* **Settings Dialog Freeze Fixed:** Eliminated WinMM audio deadlock in key recording routine by using non-blocking asynchronous audio.
* **Direct Tray Clipboard Toggle:** Added "Keep Recognized Text in Clipboard" and "Auto-Paste Text at Cursor" tray menu options.

---

## 📦 Distribution
* `GIN-Voice_Setup_v026.exe` — Single-File Self-Extracting Installer, Application & Uninstaller (Deployed to MEGA Desktop).
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs.
* `dictionary.json` — Custom vocabulary replacements.
* `version.json` / `version.txt` — Release metadata.

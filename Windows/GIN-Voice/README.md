# 🎙️ GIN-Voice [v025]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v025`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v025
* **Restored Embedded PE Icon:** Single-binary installer and main application now strictly embed high-res `.rsrc` icons (`app.ico`).
* **Settings Dialog Freeze Fixed:** Eliminated WinMM audio deadlock in key recording routine by using non-blocking asynchronous audio.
* **Direct Tray Clipboard Toggle:** Added "Keep Recognized Text in Clipboard" and "Auto-Paste Text at Cursor" tray menu options.
* **Eliminated Hallucinated Keywords:** Removed raw prompt arrays from Whisper HTTP requests to prevent spurious brand words during speech pauses. Added regex boundary matching and trailing conversational filler cleanup ("и так далее").

---

## 📦 Distribution
* `GIN-Voice_Setup_v025.exe` — Single-File Self-Extracting Installer, Application & Uninstaller (Deployed to MEGA Desktop).
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs.
* `dictionary.json` — Custom vocabulary replacements.
* `version.json` / `version.txt` — Release metadata.

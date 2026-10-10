# 🎙️ GIN-Voice [v015]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v015`  

---

## 🎯 What's New in v015
* **Zero-Redundancy Single Executable Deployment:** Fixed self-installer to avoid leaving duplicate installer copies or versioned binaries in `%LOCALAPPDATA%\GIN-Voice\`. The installation folder now only contains the lean runtime `GIN-Voice.exe`, `Uninstall.exe`, assets, and configuration.
* **English Default Language on First Install:** Clean out-of-the-box configuration with `active_languages: ["EN"]` pre-selected upon initial setup.
* **Auto-Launch Interactive Setup Guide in Browser:** Automatically opens the visual `setup_guide.html` in the user's default web browser immediately upon initial installation/first run.
* **Embedded Standalone Uninstaller:** `Uninstall.exe` is now embedded directly into the installer and deployed alongside the application with Start Menu integration.
* **Cool Slate Grey & Cyber Accent Theme:** Settings window with `#22272E` background, vibrant Cyan `#00E5FF` header banner, Emerald Green `#22C55E` section titles, and Sky Blue `#7DD3FC` helper tips.
* **One-Click In-App Auto-Updater:** Seamless GitHub version checking with 1-click update preserving keys and dictionaries.

---

## 📦 Files
* `GIN-Voice_Setup_v015.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v015.exe` — Portable executable
* `GIN-Voice.exe` — Main runtime executable
* `Uninstall.exe` — Standalone Uninstaller with icon and signature 90-character terminal styling
* `uninstall.ps1` — PowerShell Uninstaller script
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

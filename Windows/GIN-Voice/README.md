# 🎙️ GIN-Voice [v016]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v016`  

---

## 🎯 What's New in v016
* **Right-Click Context Menu "Check for Updates" Button:** Added dedicated "🔄 Check for Updates..." ("🔄 Проверить обновления...") item placed directly above the "Exit" button in the tray icon context menu. Provides instant HUD feedback when checking, updating, or confirming up-to-date status.
* **Strict Working Folder Installer Cleanup:** Guaranteed removal of any installer files (`GIN-Voice_Setup*.exe`) and legacy version binaries (`GIN-Voice_v*.exe`) from the working directory (`%LOCALAPPDATA%\GIN-Voice\`). The directory strictly maintains only the primary runtime `GIN-Voice.exe`, `Uninstall.exe`, assets, dictionary, and configuration.
* **Freeze & Hang Fixes:** Unconditional immediate system tray registration on launch and Win32 `WM_NULL` message dispatch after popup menu dismissal to eliminate any window or tray freezing.
* **Clean Cloud Sync Policy:** Excluded bare icon files (`app.ico`) from sync root desktop directory.

---

## 📦 Files
* `GIN-Voice_Setup_v016.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v016.exe` — Portable executable
* `GIN-Voice.exe` — Main runtime executable
* `Uninstall.exe` — Standalone Uninstaller with icon and signature 90-character terminal styling
* `uninstall.ps1` — PowerShell Uninstaller script
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

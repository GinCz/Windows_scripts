# 🎙️ GIN-Voice [v008]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v008`  

---

## 🎯 What's New in v008
* **Multi-Language UI (Menu & Interface):** Default interface language is now English (`EN`), with instant switching to `RU` (Русский), `CS` (Čeština), `IT` (Italiano), `ES` (Español), or `FR` (Français) via Tray Menu.
* **Recognition Languages Priority:** English (`EN`) is set as first and checked by default, followed by Czech (`CS`) and Russian (`RU`).
* **Zero Pre-Filled Keys (Clean Security):** No default API key is pre-filled. Fresh installs start cleanly with an empty API key field, prompting the configuration wizard.
* **Streamlined Tray Menu:** Removed redundant "Uninstall" and "Open Folder" menu items for a cleaner, focused experience.
* **Guaranteed Windows PE Resource Icon:** Native compilation embeds 32bpp DIB multi-resolution icons (16x16 to 256x256) directly into the executable `.rsrc` table so Windows Explorer and Desktop render the neon microphone icon.
* **Event-Driven Audio Engine (`CALLBACK_EVENT`):** Complete isolation of WinMM audio driver from window messages for 100% deadlock-free continuous dictation.
* **Shortcuts & Mega Desktop Support:** Automatically installs shortcuts to Desktop, Start Menu, and `D:\MEGA\DOCS\desktop\`.

---

## 📦 Files
* `GIN-Voice_Setup_v008.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v008.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

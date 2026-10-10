# 🎙️ GIN-Voice [v009]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v009`  

---

## 🎯 What's New in v009
* **Strict Zero-Key Architecture (100% Secure):** Absolutely no hardcoded keys, no fallback to system/user environment variables (`GROQ_API_KEY`), and no auto-population. Fresh installations strictly start with an empty key field, ensuring complete security for public distribution.
* **Direct MEGA Cloud Synchronisation:** Binary `GIN-Voice_Setup_v009.exe` is uploaded directly to `D:\MEGA\DOCS\desktop\` via MEGA cloud CLI.
* **Multi-Language UI (Menu & Interface):** Default interface language is English (`EN`), with instant switching to `RU` (Русский), `CS` (Čeština), `IT` (Italiano), `ES` (Español), or `FR` (Français) via Tray Menu.
* **Recognition Languages Priority:** English (`EN`) is set as first and checked by default, followed by Czech (`CS`) and Russian (`RU`).
* **Streamlined Tray Menu:** Removed redundant "Uninstall" and "Open Folder" menu items for a cleaner, focused experience.
* **Guaranteed Windows PE Resource Icon:** Native compilation embeds 32bpp DIB multi-resolution icons (16x16 to 256x256) directly into the executable `.rsrc` table so Windows Explorer and Desktop render the neon microphone icon.
* **Event-Driven Audio Engine (`CALLBACK_EVENT`):** Complete isolation of WinMM audio driver from window messages for 100% deadlock-free continuous dictation.

---

## 📦 Files
* `GIN-Voice_Setup_v009.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v009.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

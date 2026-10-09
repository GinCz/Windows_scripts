# 🎙️ GIN-Voice [v001]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v001`  

---

## 🎯 Features
* **Zero Overhead:** Native Go binary compiled for Windows 64-bit with Win32 API. Consumes **< 15 MB RAM** and **0% CPU** when idle.
* **Global Hotkey:** Toggle dictation with `[F4]` anywhere across Windows.
* **Multilingual Transcription:** OpenAI Whisper Large v3 backend via Groq API (~0.3s latency) with full code-switching support (Russian + English + Czech).
* **System Tray Menu:** Language toggles with custom priority (English checked by default, Czech second, Russian third), dictionary editor, and settings.
* **Custom Project Entities:** Automatic post-processing dictionary replacing spoken phrases (e.g., `джин синема` -> `GinCinema`, `джин нетскан` -> `GinNetScan`).
* **Knowledge Folder Linker:** Automatically scans AI repositories and builds context prompt embeddings.
* **Punto Switcher Immune:** Atomic clipboard injection prevents keyboard layout switching glitches.

---

## 📦 Files
* `GIN-Voice.exe` / `GIN-Voice_v001.exe` — Standalone Windows 64-bit executable
* `GIN-Voice_Setup_v001.ps1` — PowerShell installer
* `GIN-Voice_Setup_v001.bat` — 1-click batch launcher
* `config.json` — Settings and language preferences
* `dictionary.json` — Custom vocabulary replacements
* `HELP.md` — Guide and personalization help

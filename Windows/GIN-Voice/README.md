# 🎙️ GIN-Voice [v001]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v001`  

---

## 🎯 Features
* **1-Click Single-Exe Installer:** Just run `GIN-Voice_Setup_v001.exe` (like GIN-VPN). Installs automatically to `%LOCALAPPDATA%\GIN-Voice\`, creates shortcuts with custom icon, and launches tray client.
* **First-Run Setup Wizard:** Automatically opens the Groq API Keys console and visual `setup_guide.html`, and provides a native activation dialog to paste the API key.
* **Zero Overhead:** Native Go binary compiled for Windows 64-bit with Win32 API. Consumes **< 15 MB RAM** and **0% CPU** when idle.
* **Global Hotkey:** Toggle dictation with `[F4]` anywhere across Windows.
* **Multilingual Transcription:** OpenAI Whisper Large v3 backend via Groq API (~0.3s latency) with full code-switching support (Russian + English + Czech).
* **System Tray Menu:** Language toggles with custom priority (English checked by default, Czech second, Russian third), dictionary editor, and settings.
* **Custom Project Entities:** Automatic post-processing dictionary replacing spoken phrases:
  - `джин тв` / `гин тв` $\rightarrow$ `GIN-TV`
  - `джин синема` / `гин синема` $\rightarrow$ `GIN-Cinema`
  - `джин нетскан` / `гин нетскан` $\rightarrow$ `GIN-NetScan`
  - `джин впн` / `гин впн` $\rightarrow$ `GIN-VPN`
  - `джин чат` / `гин чат` $\rightarrow$ `GIN-Chat`
  - `джин воис` / `гин воис` $\rightarrow$ `GIN-Voice`
  - `секрет приват` $\rightarrow$ `Secret_Privat`
  - `оракл 157` $\rightarrow$ `ORACLE_157`
* **Knowledge Folder Linker:** Automatically scans AI repositories and builds context prompt embeddings.
* **Punto Switcher Immune:** Atomic clipboard injection prevents keyboard layout switching glitches.

---

## 📦 Files
* `GIN-Voice_Setup_v001.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `config.json` — Settings and language preferences
* `dictionary.json` — Custom vocabulary replacements

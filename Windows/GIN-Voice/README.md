# 🎙️ GIN-Voice [v007]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v007`  

---

## 🎯 What's New in v007
* **Event-Driven Audio Engine (`CALLBACK_EVENT`):** WinMM audio recording is now 100% decoupled from the Windows GUI message loop using kernel events. Completely eliminates recording hangs and lockups regardless of recording duration.
* **Non-Blocking Asynchronous Hotkey Listener:** Hardware `[F8]` listener runs in a decoupled worker with debouncing, preventing keyboard hook freezes.
* **True 32bpp BMP DIB Icon Suite:** Full multi-resolution icon embedding (16x16, 20x20, 24x24, 32x32, 40x40, 48x48, 64x64, 128x128, 256x256) ensuring Windows Explorer and Desktop render the crisp GIN-Voice icon instead of a blank white square.
* **Real-time Cyber Floating HUD:** Top-center status indicator showing recording state, Whisper AI transcription, and auto-pasted results.
* **Out-of-the-Box Operation:** Pre-configured with built-in Groq Whisper AI key so it works instantly on launch, with the ability to set a custom key anytime via Tray Menu.
* **Extended Brand Dictionary:** Automatic capitalization and syntax correction for `GIN-Cinema`, `GIN-TV`, `GIN-NetScan`, `GIN-Voice`, `GIN-VPN`, `GIN-Chat`, `Secret_Privat`, `ORACLE_157`, `Server_222`, `Antigravity`, and `Gemini`.

---

## 📦 Files
* `GIN-Voice_Setup_v007.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v007.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

# 🎙️ GIN-Voice [v013]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v013`  

---

## 🎯 What's New in v013
* **One-Click Auto-Updater (Preserves API Key & Settings 100%):** Automatic GitHub release version check at startup and in background. When a new version is published on GitHub, a highlighted tray menu item `✨ Update Available: vXXX (Click to Update)` appears. Clicking it automatically downloads the latest executable, gracefully restarts the app via background PowerShell, and preserves all user configuration (`config.json`, Groq API key, hotkeys, dictionary) completely intact.
* **Anti-Hallucination Filter:** Eliminates Whisper subtitle artifacts (*"Субтитры создавал DimaTorzok"*, *"Amara.org"*, *"Thank you for watching"*, etc.).
* **Smart Audio Silence Trimming (RMS Energy Detection):** Automatically detects and trims silence in audio buffers before transcription to prevent phantom ending subtitle predictions.
* **Soft & Gentle Audio Chimes:** Harmonic PCM WAV tones with Hann amplitude envelope.
* **F4 Default Hotkey & D:\AI\BASE Default Path:** Rapid single-key workflow with default base folder.
* **Balanced 18-Language Matrix:** 6 rows × 3 columns with default active languages `EN`, `CS`, `RU`, `DE`.
* **Direct MEGA Cloud Synchronisation:** `GIN-Voice_Setup_v013.exe` delivered directly to `/MEGA/DOCS/desktop/`.

---

## 📦 Files
* `GIN-Voice_Setup_v013.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v013.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

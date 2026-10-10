# 🎙️ GIN-Voice [v012]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v012`  

---

## 🎯 What's New in v012
* **Anti-Hallucination Filter (Zero Subtitle Artifacts):** Comprehensive multi-language filter eliminating Whisper subtitle hallucinations (e.g., *"Субтитры создавал DimaTorzok"*, *"Редактор субтитров"*, *"Amara.org"*, *"Thank you for watching"*, etc.).
* **Smart Audio Silence Trimming (RMS Energy Detection):** Trailing and leading silence/background noise is automatically detected and trimmed from PCM audio buffers prior to transcription, stopping Whisper from predicting phantom subtitle credits on silence.
* **Soft & Gentle Audio Chimes:** Synthesized harmonic PCM WAV tones with Hann amplitude envelope at comfortable low volume.
* **F4 Default Hotkey & D:\AI\BASE Default Path:** Rapid single-key workflow with default base folder.
* **Balanced 18-Language Recognition Grid:** 6 rows × 3 columns with default active languages `EN`, `CS`, `RU`, `DE`.
* **Direct MEGA Cloud Synchronisation:** `GIN-Voice_Setup_v012.exe` delivered directly to `/MEGA/DOCS/desktop/`.

---

## 📦 Files
* `GIN-Voice_Setup_v012.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v012.exe` — Portable executable
* `setup_guide.html` — Visual HTML guide with step-by-step setup
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

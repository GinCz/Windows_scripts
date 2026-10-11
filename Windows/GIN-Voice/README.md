# 🎙️ GIN-Voice [v022]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v022`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v022
* **Full Changelog & Architecture Codification:** Created comprehensive `CHANGELOG.md` covering all releases from `v001` to `v022` with hard-learned lessons and regression prevention rules.
* **Codified 7 Iron Rules in `RULES.md`:** Embedded zero-desync release pipeline, installer preservation on desktop, trailing speech protection, and loop guards.
* **Zero-Desync Auto-Update Release Pipeline:** Release and self-update validation guarantees zero desync between GitHub and MEGA cloud.
* **Whisper Repetition Loop Guard (v021):** Automatic detection and elimination of prompt hallucination loops, trailing brand spam, and repeated trailing phrases.
* **Prompt Vocabulary Context Cap (v021):** Deduplicated and capped dictionary prompt terms (max 12) preventing Whisper decoder attention lock-in.

---

## 📦 Files
* `GIN-Voice_Setup_v022.exe` — All-in-one Single-File Installer and Application
* `GIN-Voice_v022.exe` — Portable executable
* `GIN-Voice.exe` — Main runtime executable
* `Uninstall.exe` — Standalone Uninstaller with icon and signature 90-character terminal styling
* `uninstall.ps1` — PowerShell Uninstaller script
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs
* `dictionary.json` — Custom vocabulary replacements
* `version.json` — Release metadata

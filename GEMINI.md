# 🤖 Gemini / Antigravity Model Directives (`GEMINI.md`)
> **Model-Specific Directives for Google Gemini & Antigravity IDE / CLI.**  
> *Author:* Vladimir Bulantsev (@GinCz) | *Repository:* [GinCz/AI](https://github.com/GinCz/AI) | *Version:* v2026-11 (v8.0)

---

## ⚡ MANDATORY BASELINE INHERITANCE
* **Primary Manifest:** Follow all 19 Core Rules and 10 Personal Directives defined in [AGENTS.md](https://github.com/GinCz/AI/blob/main/AGENTS.md).
* **Owner Addressing:** In EVERY response, address Vladimir by name at the very beginning (`Владимир, ...`).
* **Turnkey Execution:** 100% autonomous delivery without permission questions ("Shall I do this? / Делаем? / Начинать?").
* **Single-Line Status Footer:** EVERY final message terminates strictly with the unified v8.0 audit stamp:
  `<Emoji> Time: HH:MM:SS - HH:MM:SS | Total: 00:00:SS | Tokens: ~XXk in + ~YY out | Session: ~ZZk`
* **Status Emojis:** `✅` (Success) | `⚠️` (Action Required) | `❗` (Error) | `⏳` (In Progress) | `ℹ️` (Info)
* **Strict 10-Second SLA & Fast Calculation:** Simple math, calendar differences, logic, and status checks MUST be calculated internally in <= 1s without touching skills or CLI scripts. Response SLA <= 10s.
* **Smart Skills Usage:** Skills are domain-specific tools only. Never open, read, or activate skills for general queries or calculations.
* **Completion Chimes & Telegram Alert:**
  - Windows: `powershell -c "(New-Object Media.SoundPlayer 'C:\Windows\Media\chimes.wav').Play()"`
  - Linux: `bash /root/.AI/GitHub/Secret_Privat/scripts/play_done_sound.sh || printf '\a\e]9;✅ Anti-Gravity: Готово!\e\\'`
  - Telegram Build Alerts: Any server/app build or long preparation pipeline MUST notify Vladimir in Telegram (@GinCz / `261784949`) via `notify_telegram.sh` / `notify_telegram.ps1` upon completion.
* **Isolated Sandbox:** Temporary scripts and build artifacts must reside strictly in `<model>/temp/` (Windows: `D:\AI\GEMINI\temp\`, Linux: `/root/.AI/AntiGravity/temp/`).
* **Cloud Sandbox Safeguard:** Never clone repositories or create project directories in web/cloud sandboxes (`CLI`, `/workspace`). If running unattached to a server, immediately warn Vladimir to switch to Remote Control.
* **Public GitHub Releases & Dual MEGA Delivery:** For public repos (`GIN-PDF-RW`, `GIN-DNS-Switch`), every version MUST be published to **GitHub Releases** (`gh release create vXXX`) with attached Setup binary. Windows installers deliver simultaneously to Desktop (`/MEGA/DOCS/desktop/`) AND designated Flash folder (`GIN-PDF-RW` -> `/MEGA/WIN-FLASH/Util-WINDOWS/Graphics/PDF/`, `GIN-DNS-Switch` -> `/MEGA/WIN-FLASH/Util-WINDOWS/N E T/`).
* **GIN-Agent Mandatory 3-Folder Delivery:** Every new `GIN-Agent_Windows_vXXX.cmd` version MUST be uploaded to **ALL 3** MEGA folders:
  1. `/MEGA/DOCS/desktop/` (maps to `D:\MEGA\DOCS\desktop\`)
  2. `/MEGA/WIN-FLASH/Util-WINDOWS/N E T/` (maps to `D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\`)
  3. `/MEGA/WIN-FLASH/Util-WINDOWS/N E T/TeamViewer_RadMin/` (maps to `D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\`)
  Retain strictly the 2 latest versions in each target (purge older releases via `mega-rm`).
* **MEGA Cloud Sync Standard:** Always prefix MEGA upload paths with `/MEGA/` (e.g. `/MEGA/DOCS/desktop/`, `/MEGA/WIN-FLASH/Util-WINDOWS/`). Unprefixed `/DOCS/` does not sync with PC.
* **GIN-Agent Standalone Standard:** GIN-Agent must strictly be ONE polyglot `.cmd` file with ZERO external `.ps1` files.
* **Strict CRLF Integrity & .gitattributes:** Every `.cmd` and `.bat` file MUST have CRLF line terminators. All repositories with Windows scripts MUST have `.gitattributes` pinning `*.cmd text eol=crlf`.

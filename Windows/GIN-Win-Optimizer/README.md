# 🔒 GIN-Win-Optimizer (Private Master Repository)

> **Private Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Public Mirror:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Author / Architect:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Target OS:** Windows 10 / 11 (x86_64, all editions: Home, Pro, Enterprise, LTSC)  
> **Current Version:** `v017` (Active)

---

## 🧭 Project Purpose & Dual-Repository Architecture

**GIN-Win-Optimizer** is a standalone, single-file polyglot hybrid CMD/PowerShell WPF optimizer and deep cleaner for Windows 10 and 11.

- **Private Repository (`Secret_Privat`):** Contains the master source code, development scripts, internal deployment configurations, MEGA synchronization rules, and local caching protocols.
- **Public Repository (`Windows_scripts`):** Contains clean production releases, comprehensive English-only user documentation, and public changelogs for the community. Internal deployment paths and personal cloud directories are strictly excluded from the public repository.

---

## 🖥️ Target Deployment & Cloud Storage Paths (Internal Only)

| Environment / Target | Remote / Local Path | Purpose |
| :--- | :--- | :--- |
| 🪟 **Windows Desktop** | `D:\MEGA\DOCS\desktop\GIN-Win-Optimizer_v017.cmd` | Vladimir's primary synchronized desktop workspace |
| ☁️ **MEGA Cloud Desktop** | `/MEGA/DOCS/desktop/GIN-Win-Optimizer_v017.cmd` | Cloud source for real-time Windows desktop sync |
| 💾 **MEGA Win-Flash Drive** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v017.cmd` | Portable sysadmin USB flash toolkit folder |
| ☁️ **MEGA Cloud Win-Flash** | `/MEGA/WIN-FLASH/Util-WINDOWS/GIN-Win-Optimizer_v017.cmd` | Master cloud repository for flash utilities |
| 🗄️ **Server Permanent Cache** | `/root/AI_222/cache/win_opt/GIN-Win-Optimizer_v017.cmd` | Central DE-222 node permanent offline backup cache |
| 📂 **Private Git Repository** | `/root/Secret_Privat/Windows/GIN-Win-Optimizer/` | Master development branch |
| 🌐 **Public Git Repository** | `/root/Windows_scripts/Windows/GIN-Win-Optimizer/` | Production public mirror |

---

## ⚡ Deployment Pipeline Automation Commands (DE-222 Node)

When releasing a new version (`vXXX`), run the following autonomous deployment commands:

```bash
# 1. Update Server Permanent Cache
cp "/root/Secret_Privat/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_vXXX.cmd" "/root/AI_222/cache/win_opt/GIN-Win-Optimizer_vXXX.cmd"

# 2. Deploy to MEGA Flash Drive (Remove previous, upload current)
mega-rm "/MEGA/WIN-FLASH/Util-WINDOWS/GIN-Win-Optimizer_v<OLD>.cmd" 2>/dev/null || true
mega-put -c "/root/Secret_Privat/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_vXXX.cmd" "/MEGA/WIN-FLASH/Util-WINDOWS/"

# 3. Deploy to MEGA Desktop (Strict Single-Version Policy)
mega-rm "/MEGA/DOCS/desktop/GIN-Win-Optimizer_v<OLD>.cmd" 2>/dev/null || true
mega-put -c "/root/Secret_Privat/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_vXXX.cmd" "/MEGA/DOCS/desktop/"

# 4. Synchronize Public Repository (Windows_scripts)
cp -r "/root/Secret_Privat/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_vXXX.cmd" "/root/Windows_scripts/Windows/GIN-Win-Optimizer/"
cp "/root/Secret_Privat/Windows/GIN-Win-Optimizer/version.json" "/root/Windows_scripts/Windows/GIN-Win-Optimizer/"
cp "/root/Secret_Privat/Windows/GIN-Win-Optimizer/CHANGELOG.md" "/root/Windows_scripts/Windows/GIN-Win-Optimizer/"

# 5. Commit and push both repositories
cd /root/Secret_Privat && git add Windows/ && git commit -m "chore(GIN-Win-Optimizer): release vXXX" && git push origin main
cd /root/Windows_scripts && git add Windows/GIN-Win-Optimizer/ && git commit -m "release(GIN-Win-Optimizer): vXXX" && git push origin main
```

---

## 🛡️ Architecture & Key Technical Specs

- **Polyglot Hybrid Architecture:** Starts as a classic `.cmd` batch file with automatic Administrator UAC elevation, then immediately executes embedded PowerShell 5.1 code without creating temporary files on disk.
- **Pure ASCII WPF GUI:** The modern dark graphical interface (XAML) is compressed in Base64 and rendered dynamically in memory via `[System.Windows.Markup.XamlReader]`.
- **Dispatcher Single-Threaded Output:** Avoids multithreaded runspace race conditions in PowerShell 5.1 by polling output streams synchronously during DISM / Cleanmgr runs.
- **Deep Windows 11 Taskbar Enforcement:** Clears Search, Feeds/Widgets, Chat, Copilot, and Task View across `HKCU`, `HKLM`, and `HKEY_USERS`, immediately validated via clean `explorer.exe` restart.
- **Dual Low-Pitch Tone Audio Notification:** Win32 API `kernel32.dll!Beep(320, 180)` and `Beep(320, 220)`.

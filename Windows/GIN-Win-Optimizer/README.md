# 🔒 GIN-Win-Optimizer — Master Repository

> **Private Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Public Mirror:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Author / Architect:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & AI [VladiMIR + AI]  
> **Target OS:** Windows 7 / 8 / 8.1 / 10 / 11 (Universal x86 32-bit & x64 64-bit, all editions)  
> **Current Version:** `v045` (Active)  
> **Retention Policy:** Strictly **2 latest production versions** (`GIN-Win-Optimizer_v045.cmd` and `GIN-Win-Optimizer_v044.cmd`).

---

## 🚀 GIN-Win-Optimizer v045: Unified Standalone CMD Architecture & Silent UAC Hardening

Version `v045` establishes the single-standard CMD format (EXE removed per Vladimir directive for maximum sysadmin portability and antivirus immunity):
- **Universal Single-Standard CMD**: Standalone hybrid script running natively across Windows 7 SP1, 8, 8.1, 10, and 11 on both 32-bit (x86) and 64-bit (x64) architectures.
- **100% Antivirus & SmartScreen Immunity**: Zero binary blocks, zero quarantine risk, zero compiler dependencies. Can be transferred via AnyDesk, RDP, Telegram, USB flash drives, or network shares without triggering "Unknown Publisher" security blocks.
- **Robust Auto-Elevation (`RunAs`)**: Checks administrative privileges natively via `net session >nul 2>&1`. Automatically re-elevates if launched by regular double-click, staging to local `%TEMP%` when running from UNC network shares (`\\server\share`).
- **Silent UAC (Slider to Minimum: "Never Notify")**: Programmatically enforces the UAC slider to the lowest level (`ConsentPromptBehaviorAdmin = 0`, `PromptOnSecureDesktop = 0`, `FilterAdministratorToken = 0`), completely eliminating yellow security popups. Modern UWP apps remain fully functional (`EnableLUA = 1`).
- **Network Drives & LAN Sharing Protection**: Retains `EnableLinkedConnections = 1`, `AllowInsecureGuestAuth = 1`, and `DisableUNCCheck = 1` while keeping `chk_srv_network_offload` and dangerous token filtering unchecked by default.

---

## 🛠️ Core Functional Modules (v045)

### 1. Security & UAC Hardening
- **Slider to Minimum (Never Notify)**: Pre-configures `ConsentPromptBehaviorAdmin = 0`, `PromptOnSecureDesktop = 0`, and `FilterAdministratorToken = 0`.
- **Token Filtering Disabled by Default**: `chk_sec_admin_approval` is disabled across all presets, preventing accidental elevation prompts for Administrators.
- **Open File Warning**: Disables "Open File - Security Warning" for downloaded files (`LowRiskFileTypes`).

### 2. Network & File / Printer Sharing Protection (Ultarix Standard)
- **Active Network Profile to Private**: Converts public connections to Private (`Doma/Kancelář`) via PowerShell and NetworkList registry, ensuring local firewall rules unblock LAN discovery and file/printer sharing.
- **Guest SMB Share Access (`AllowInsecureGuestAuth = 1`)**: Enables LanmanWorkstation guest authentication for unhindered access to network NAS, routers, and legacy file shares.
- **Admin Mapped Drives (`EnableLinkedConnections = 1`)**: Ensures network drive mappings remain fully accessible to both unprivileged desktop users and elevated Administrator processes.
- **UNC Path Execution (`DisableUNCCheck = 1`)**: Disables UNC validation warnings, enabling scripts to execute directly from network shares.
- **Core Discovery & Printing Services Auto-Start**: Enforces automatic startup for `FDResPub`, `fdPHost`, `LanmanWorkstation`, `LanmanServer`, `Spooler`, `lmhosts`, and `Dnscache`.

### 3. Memory & Performance Optimization
- **Static Pagefile Fixation (4096–8192 MB on C:)**: Disables automatic managed pagefile and locks a stable, contiguous 4–8 GB virtual memory backing on drive `C:`, preventing memory allocation crashes (`0xe0000008` / out-of-commit).
- **Hibernation Disabling (`powercfg -h off`)**: Immediately removes `hiberfil.sys`, recovering 4 to 8 GB of valuable SSD/system storage.
- **Visual Effects Tuning**: Eliminates sluggish window minimize/maximize and taskbar animations (`MinAnimate = 0`, `MenuShowDelay = 100`) while strictly preserving **ClearType font smoothing** (`FontSmoothing = 2`, `FontSmoothingType = 2`) for crisp text legibility.

### 4. Safe System Cleanup
- **Temporary Files**: Cleans user `%TEMP%` and `%SystemRoot%\Temp`.
- **Windows Update Cache**: Safely stops `wuauserv`, purges `%SystemRoot%\SoftwareDistribution\Download\*`, and restarts the update service.
- **Explorer Thumbnail & Icon Caches**: Purges cached thumbnail databases to resolve icon corruption and free disk space.
- **Diagnostics Dumps**: Deletes user crash dumps, mini dumps, and memory dumps.

---

## 🖥️ Target Deployment Environments

| Environment / Medium | Path | Target Version | Retention Policy |
| :--- | :--- | :---: | :---: |
| 💾 **USB Flash Drive (Ventoy)** | `V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v045.cmd` | v045 | Latest 2 versions |
| ☁️ **MEGA Win-Flash Mirror** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v045.cmd` | v045 | Latest 2 versions |
| ☁️ **MEGA Cloud Remote** | `/MEGA/WIN-FLASH/Util-WINDOWS\GIN-Win-Optimizer_v045.cmd` | v045 | Latest 2 versions |
| 🔒 **Private Git Repository** | `Secret_Privat/Windows/GIN-Win-Optimizer/` | v045 | Full Git history |
| 🌐 **Public Git Repository** | `Windows_scripts/Windows/GIN-Win-Optimizer/` | v045 | Full Git history |


---

# ⚡ ЖЕЛЕЗНЫЙ ЗАКОН ДОСТАВКИ: ТОЛЬКО НА РАБОЧИЙ СТОЛ ВЛАДИМИРА (D:\MEGA\DOCS\desktop)

> **КАТЕГОРИЧЕСКИЙ ЗАПРЕТ СТОРОННИХ ПАПОК И СЕРВЕРА DE-222:**
> Все без исключения новые приложения, утилиты, скрипты (CMD, BAT, PS1), таблицы Excel, файлы и скомпилированные релизы для Windows **ОБЯЗАНЫ АВТОНОМНО И БЕЗ НАПОМИНАНИЙ ЗАПИСЫВАТЬСЯ ТОЛЬКО НА РАБОЧИЙ СТОЛ ВЛАДИМИРА**:
> - **Локальный путь на компьютере Владимира:** `D:\MEGA\DOCS\desktop`
> - **Облачный путь синхронизации в MEGA:** `/MEGA/DOCS/desktop/`
> - **Команда загрузки с сервера DE-222:** `mega-put -c "<file_path>" "/MEGA/DOCS/desktop/"`
>
> 🛑 **СТРОГИЙ ЗАПРЕТ:** Запрещено оставлять созданные или обновленные файлы только локально на сервере, только в git-репозитории или на сетевых дисках. Любой релизный файл Windows (.cmd, .bat, .exe, .xlsx, .zip) сразу после создания ДОЛЖЕН лежать в `/MEGA/DOCS/desktop/`!

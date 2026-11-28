# Windows Application Automation & Silent Installers

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `tools/apps/`

Collection of unattended, silent setup scripts and post-installation profile optimizers for popular Windows desktop software.

---

## ⚡ Tool Catalog

| Script | Software | Description | Execution |
| :--- | :--- | :--- | :--- |
| `BraveBrowser_Setup.bat` | Brave Browser | Silent unattended installation with tracker-blocking defaults | Double-click or CMD as Admin |
| `CentBrowser_Setup.bat` | CentBrowser | Chromium-based browser deployment with tab gesture defaults | Double-click or CMD as Admin |
| `CentBrowser_CLEAN.bat` | CentBrowser | Safe cache, temp profile and cookie vacuuming without data loss | Run periodically |
| `Cursor_Install.bat` | Cursor AI Editor | Automated silent installation and shortcut provisioning | Run as Administrator |
| `GitHub_Install.bat` | GitHub Desktop / Git | Automated Git CLI and GitHub Desktop deployment | Run as Administrator |
| `Google_Drive_Setup.bat` | Google Drive | Official Google Drive desktop client silent setup | Run as Administrator |
| `Install_7zip_Universal.bat`| 7-Zip (x64/x86) | Universal architecture-detecting silent 7-Zip installation | Run as Administrator |
| `MEGA_x64_x86_Setup.bat` | MEGA Sync | Unattended MEGAsync client installer with architecture detection | Run as Administrator |
| `Telegram_Setup.bat` | Telegram Desktop | Direct official installation without Microsoft Store bloat | Run as Administrator |
| `TeraBox_Setup.bat` | TeraBox Cloud | Unattended client setup with startup optimization | Run as Administrator |
| `VS-Code_Install.bat` | Visual Studio Code | System-wide VS Code installer with PATH registration | Run as Administrator |
| `Heaven_Benchmark_Setup.bat`| UNIGINE Heaven | Silent deployment for GPU stress testing and thermal benchmarks | Run as Administrator |

---

## 🛡️ Integrity & Standards

* All scripts are encoded in **UTF-8 with CRLF line endings** per Windows CMD parsing standards.
* Scripts verify target system architecture (`AMD64` vs `x86`) before invoking installers.

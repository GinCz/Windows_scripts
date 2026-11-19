# ULTARIX Activity Monitor & Executive Audit Suite (v2.4.4)

Enterprise employee monitoring suite specifically tailored for the ULTARIX s.r.o. office network, engineered to run seamlessly on 32-bit Windows 10 systems hosting legacy accounting applications (**STEREO / Ježek software**, **Ekonom.win**).

---

## 🚀 Package Files in `C:\UTIL\UltarixMonitor\`

1. **`0_Server_Setup.cmd`** — Run once on server `ULPS1` to create `UTIL\UltarixMonitor\logs` and grant network write permissions (`icacls Everyone:(OI)(CI)F`).
2. **`1_Client_Install.cmd`** — Run on client workstations (`ULTARIX-07` Galina, `U-09` Tatiana, `PC-02` Ulyana, etc.). Installs the invisible background agent (`powershell.exe -WindowStyle Hidden`) via Windows Scheduled Task (`ONLOGON`, `/rl HIGHEST`). Self-closes in 2 seconds without user prompts.
3. **`2_Ulyana_Dashboard.cmd`** — Run on `PC-02` (Ulyana) or server to open the browser dashboard in 1 click.
4. **`dashboard.html`** — Executive Web Dashboard with accordion for computers and nested accordion for programs/pages. Includes inline employee name editor (✏️), persistent expand/collapse state, and dynamic script loader bypassing Chromium `file://` CORS restrictions.
5. **`employees.json`** — Company computer and employee role mapping config (covers workstations 01 through 010).
6. **`Update_From_GitHub.cmd`** — 1-click auto-updater that pulls the newest scripts directly from GitHub, replacing files in-place while keeping logs intact.

---

## 🗺️ Master Plan & Future Roadmap

For detailed architecture, cloud mirroring (`Server_222` & `Server_109`), mobile Android APK specifications, and triple-layer remote access (GIN-Agent-PC + RustDesk + RDP), see:
👉 **[Master Plan & Roadmap](PLAN_AND_ROADMAP.md)**

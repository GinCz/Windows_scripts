# ULTARIX Activity Monitor & Executive Audit Suite (v2.3.0)

Enterprise employee monitoring suite specifically tailored for ULTARIX s.r.o. office network, designed to run seamlessly on 32-bit Windows 10 systems hosting legacy accounting applications (**STEREO / Ježek software**, Ekonom.win).

## Package Files in `C:\UTIL\UltarixMonitor\`
1. **`0_Server_Setup.cmd`** — Run once on server `ULPS1` to create `UTIL\UltarixMonitor\logs` and grant write permissions.
2. **`1_Client_Install.cmd`** — Run on monitored client PCs (PC-09, PC-02, etc.). Installs the invisible background agent via Windows Scheduled Task.
3. **`2_Ulyana_Dashboard.cmd`** — Run on PC-02 (Ulyana) or server to open the browser dashboard in 1 click.
4. **`dashboard.html`** — Executive Web Dashboard with accordion for computers and nested accordion for programs/pages. Includes inline employee name editor (✏️) and persistent expand/collapse state.
5. **`employees.json`** — Company computer and employee role mapping config.
6. **`Update_From_GitHub.cmd`** — 1-click auto-updater that pulls the newest scripts directly from GitHub, replacing files in-place while keeping logs intact.

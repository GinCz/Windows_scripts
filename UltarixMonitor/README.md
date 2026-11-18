# ULTARIX Activity Monitor & Executive Audit Suite (32-bit Windows 10 x86)

Enterprise employee monitoring suite specifically tailored for ULTARIX s.r.o. office network, designed to run seamlessly on 32-bit Windows 10 systems hosting legacy accounting applications (**STEREO / Ježek software**, Ekonom.win).

## Architecture & Server Footprint
- **Target OS:** Windows 10 Pro 32-bit (x86).
- **Central Storage:** Placed in the server's `UTIL` directory: `\\ULPS1\Sdílené Data\UTIL\UltarixMonitor\` or `D:\UTIL\UltarixMonitor\`.
- **Server Load:** Strictly **0% CPU and 0% RAM** on `ULPS1 (192.168.33.128)`. The server acts purely as passive SMB storage for daily CSV logs.
- **Client Footprint:** Less than 15 MB RAM, 0% CPU overhead on client PCs.

## Files in Package
1. **`0_Server_Setup.cmd`** — Run once on server `ULPS1` (or admin PC) to create `UTIL\UltarixMonitor\logs` and grant write permissions.
2. **`1_Client_Install.cmd`** — Run on monitored 32-bit client PCs (PC-09, etc.). Installs the invisible background agent via Windows Scheduled Task.
3. **`2_Ulyana_Dashboard.cmd`** — Run on PC-02 (Ulyana). Opens the browser dashboard in 1 click.
4. **`dashboard.html`** — Executive Web Dashboard with accordion for computers and nested accordion for programs/pages.

## Step-by-Step Deployment Guide
1. Copy the entire `UltarixMonitor` folder to the server into `UTIL` (e.g. `D:\UTIL\UltarixMonitor` or `\\ULPS1\Sdílené Data\UTIL\UltarixMonitor`).
2. On server `ULPS1`: run `0_Server_Setup.cmd` as Administrator once.
3. On employee PC (PC-09): run `1_Client_Install.cmd` as Administrator once.
4. On Director PC (PC-02 Ulyana): run `2_Ulyana_Dashboard.cmd` and press `Ctrl + D` to bookmark the page in browser favorites.

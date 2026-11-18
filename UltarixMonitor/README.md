# ULTARIX Activity Monitor & Executive Audit Suite (v2.0.0)

Single-file self-contained background monitoring and executive web dashboard for ULTARIX s.r.o.

## Key Principles & Architecture
- **Single All-in-One CMD Architecture:** No separate external `.ps1` files. `Ultarix_Agent_Setup.cmd` auto-elevates to Administrator, embeds its own PowerShell engine, and registers invisible background tasks.
- **Zero Server Overhead (0% CPU / 0% RAM on ULPS1):** Server `ULPS1 (192.168.33.128)` acts purely as a passive file folder (`\\ULPS1\ULTARIX\Monitoring\`). It runs NO database services, NO background daemons, and processes ZERO queries.
- **Client Processing:** Monitored PCs (e.g. PC-09) sample active windows and AFK pauses locally every 5 seconds, appending tiny text lines to a daily CSV file (~100 bytes per change).
- **Executive Web Dashboard (PC-02 Ulyana):** Ulyana opens `dashboard.html` in Chrome/Edge or bookmarks it in Favorites (`file:///S:/ULTARIX/Monitoring/dashboard.html`):
  - **Level 1 Accordion:** List of all monitored PCs (`PC-09`, `PC-03`, `PC-04`, etc.) with live online/offline/pause status indicators.
  - **Date Picker / Calendar:** Filter by day, week, 30 days, or 60 days.
  - **Daily KPI Cards:** Total time, active work time, and **total pause/idle minutes** (e.g. 95 minutes of idle/breaks).
  - **Level 2 Nested Accordion:** Click on any program (e.g. Google Chrome, Ekonom.win, Excel, Idle pauses) to expand and view exact visited URLs, sub-tabs, documents, and specific pauses with exact minutes spent!

## Deployment

1. **On PC-09 (or any employee workstation):**
   Run as Administrator:
   ```cmd
   Ultarix_Agent_Setup.cmd
   ```

2. **On PC-02 (Ulyana / Director):**
   Run:
   ```cmd
   Ultarix_Dashboard.cmd
   ```
   Or bookmark `S:\ULTARIX\Monitoring\dashboard.html` in Chrome / Edge.

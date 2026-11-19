# 🗺️ ULTARIX Monitor & Infrastructure Master Plan

> **Author:** Vladimir Bulantsev (@GinCz) & Antigravity AI  
> **Target Enterprise:** ULTARIX s.r.o. (Prague, Czech Republic)  
> **Platform:** Windows 10 Pro (32-bit x86 legacy workstations)  
> **Status:** Stage 1 Deployed (v2.4.4) | Stages 2–5 Scheduled  
> **Updated:** 2026-11-19

---

## 🏛️ 1. Multi-Tier Architecture Overview

The system is built on a resilient, multi-tiered infrastructure ensuring 100% visibility, zero single point of failure, and zero disruption to production accounting workflows (**STEREO / Ježek software**, **Ekonom.win**).

```
                      [ Client Workstations ]
                 (PC-02 Ulyana, PC-07 Galina, PC-09 Tatiana...)
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
       [ Local Primary LAN ]         [ Triple Remote Access ]
      \\ulps1\UTIL\UltarixMonitor     1. GIN-Agent-PC (Always Active)
      (Fast local SMB passive log)    2. RustDesk (P2P 1-Click GUI)
                │                     3. Windows RDP (Native Fallback)
                │
                │ Scheduled Push / Rsync Mirror
                ▼
     ┌───────────────────────────────────────────────┐
     │          Cloud Mirroring Hubs                 │
     ├───────────────────────┬───────────────────────┤
     │  Server_222 (DE NetCup)│  Server_109 (RU)     │
     │  remote.gincz.com/mon │  Failover Node        │
     │  (0.01% CPU / 25MB)   │  (Russia low-ping)    │
     └───────────────────────┴───────────────────────┘
                │                             │
                ▼                             ▼
      [ Remote Web Browser ]       [ Android Mobile APK ]
      (Any PC/Laptop worldwide)    (Smartphones: Vladimir & Ulyana)
```

---

## 🛡️ 2. Triple-Layer Remote Access Strategy

Vladimir's strict operational standard: **always maintain at least TWO independent remote control channels plus a persistent background management agent**.

| Channel | Role & Technology | Usage Scenario | Redundancy Status |
| :--- | :--- | :--- | :--- |
| **1. GIN-Agent-PC** | Lightweight PowerShell agent connected to DE-222 bridge | 24/7 background telemetry, script deployment, health checks, headless fixes | **Primary Management Agent** (Always running) |
| **2. RustDesk** | P2P encrypted desktop access (Direct Hole-Punching) | Instant 1-click GUI access with saved address book and credentials | **Primary GUI Remote Access** |
| **3. Windows RDP** | Native Windows Remote Desktop Connection | Direct network/VPN connection, clean independent desktop sessions | **Secondary GUI Fallback** |

---

## 🔄 3. Data Flow & Zero-Strain Cloud Replication

### Primary Local Collection (`ULPS1` - Prague):
1. Client workstations run `agent.ps1` via hidden Windows Scheduled Task (`ONLOGON`, `/rl HIGHEST`).
2. Activity log writes passively to local share:
   - `\\ulps1\UTIL\UltarixMonitor\logs\<COMPUTERNAME>\activity_YYYY-MM-DD.csv`
   - `\\ulps1\UTIL\UltarixMonitor\logs\<COMPUTERNAME>\current_status.js` (Pulse)
   - `\\ulps1\UTIL\UltarixMonitor\logs\<COMPUTERNAME>\today.js` (Aggregated day KPIs & app breakdown)
3. Zero CPU overhead on server `ULPS1` (pure passive file write).

### Cloud Mirroring (`Server_222` & `Server_109`):
* Background sync script on `ULPS1` mirrors `logs/` to:
  - **Server_222 (Germany, NetCup):** `https://remote.gincz.com/monitor/` (Primary European Cloud Hub).
  - **Server_109 (Russia):** Redundant failover mirror.
* **Network & Hardware Footprint:**
  - Bandwidth: ~2 kbps (~0.002 Mbps total across all office PCs).
  - Monthly Data: < 200 MB.
  - Server CPU Impact: **< 0.01%** (completely negligible).
  - Server RAM Impact: **~25 MB**.

---

## 📅 4. Implementation Roadmap

### ✅ Stage 1: Local Office Deployment (COMPLETED - v2.4.4)
- [x] Invisible 32-bit Windows 10 client agent (`1_Client_Install.cmd`).
- [x] Multi-run singleton protection (process termination + single instance guard).
- [x] Chromium CORS bypass via dynamic `<script>` loading (`today.js`, `current_status.js`).
- [x] Executive web dashboard (`dashboard.html`) with dual-level accordion, live status dots, and inline rename tool (✏️).
- [x] Automatic process recognition for **STEREO Ježek (🦔)**, **Ekonom.win (💼)**, **Chrome (🌐)**, **Excel (📊)**, and **AFK pauses (⏸)**.
- [x] 1-Click updater (`Update_From_GitHub.cmd`).

### ⏳ Stage 2: Cloud Mirroring Setup (PLANNED)
- [ ] Deploy lightweight HTTPS ingestion endpoint on `Server_222` (`remote.gincz.com/monitor/`).
- [ ] Configure PIN-protected web dashboard accessible from any browser worldwide.
- [ ] Set up sync daemon on `ULPS1` pushing fresh logs to `Server_222` and `Server_109`.

### ⏳ Stage 3: Android APK Application (PLANNED)
- [ ] Build compact native Android APK for Vladimir and Ulyana.
- [ ] Real-time card view of all employee PCs with active/idle/offline status.
- [ ] Push notifications for extended employee AFK pauses (> 30 min).

### ⏳ Stage 4: Self-Hosted RustDesk Server (PLANNED)
- [ ] Install `hbbs` (signal/rendezvous) and `hbbr` (relay) on `Server_222` and `Server_109`.
- [ ] Direct P2P transmission (zero video traffic through server in 90% of sessions).
- [ ] Distribute custom pre-configured RustDesk client binary:
  `rustdesk-host=152.53.182.222,key=<PUBLIC_KEY>.exe`.

### ⏳ Stage 5: Long-Term Archive to MEGA Cloud (PLANNED)
- [ ] Configure automated nightly maintenance script (23:59).
- [ ] Compress daily CSV logs into monthly ZIP archives.
- [ ] Push archives to ULTARIX corporate paid MEGA storage via `mega-put`.

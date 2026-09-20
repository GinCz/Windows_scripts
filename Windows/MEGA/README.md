# ☁️ MEGA Cloud Integration for Windows (CLI, Sync & Virtual Network Drive)

> **Repository:** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts) | **Author:** Vladimir Bulantsev (GinCz)

A complete production-ready solution to mount MEGA cloud storage as a virtual network drive (`M:`) via WebDAV, run lightweight multi-account background folder synchronization, and automate file transfers using official **MEGAcmd** CLI tools.

---

## 🧭 Table of Contents
1. [Architecture & Comparison (MEGAsync GUI vs MEGAcmd Sync vs WebDAV Drive)](#1-architecture--comparison)
2. [Mount as Virtual Network Drive (Drive M:)](#2-mount-as-virtual-network-drive-drive-m)
3. [Background Folder Sync (Lightweight Alternative to Desktop App)](#3-background-folder-sync)
4. [Deep Dive: Resolving Error 5 (`Unexpected failure to access server: 5`)](#4-deep-dive-resolving-error-5)
5. [Essential CLI Commands Cheat Sheet](#5-essential-cli-commands-cheat-sheet)

---

## 1. Architecture & Comparison

| Feature / Metric | 🖥️ MEGAsync Desktop App (GUI) | ⚡ MEGAcmd Sync (`mega-sync`) | 🔌 MEGAcmd WebDAV (Drive `M:`) |
|---|---|---|---|
| **Local Disk Space** | **Consumes local SSD storage** | **Consumes local SSD storage** | **0 Bytes** (Cloud-only, on-demand streaming) |
| **Write Performance** | **Instant** (Local SSD speed: 500–3000 MB/s), uploaded in background | **Instant** (Local SSD speed: 500–3000 MB/s), uploaded in background | **Internet bound** (Writes streamed directly via WebDAV) |
| **RAM Footprint** | **~350–400 MB** (Heavy Qt GUI + Chromium Web helper) | **~30–50 MB** (Ultra-lightweight C++ daemon) | **~30–50 MB** (Shared `MEGAcmdServer.exe` daemon) |
| **Multi-Account Support** | ❌ Single active account per desktop session | ✅ Runs independently alongside primary MEGAsync app | ✅ Runs independently alongside primary MEGAsync app |
| **Offline File Access** | ✅ Yes, full local offline access | ✅ Yes, full local offline access | ❌ No, requires active internet connection |
| **Best Used For:** | Primary daily work folder with instant local cache | Automated CI/CD builds, headless servers, 2nd accounts | Temporary "Flash Drive" access to browse or upload APKs |

### Key Takeaways:
* **`mega-sync`** provides the exact same local copy speed and asynchronous background upload behavior as the official desktop client, but consumes **8–10x less RAM** and operates completely headless.
* **WebDAV Drive `M:`** allows browsing the entire cloud directory without wasting any local SSD storage space.

---

## 2. Mount as Virtual Network Drive (Drive M:)

The included scripts provide seamless 1-click mounting and unmounting:

### Files:
* [`Mount_MEGA_M.bat` ↗](Mount_MEGA_M.bat) — Launches the PowerShell mount script with bypass execution policy.
* [`Mount_MEGA_M.ps1` ↗](Mount_MEGA_M.ps1) — Starts `MEGAcmdServer.exe` in the current user session, initializes the WebDAV service, and connects drive `M:`.
* [`Unmount_MEGA_M.bat` ↗](Unmount_MEGA_M.bat) — One-click disconnect.
* [`Unmount_MEGA_M.ps1` ↗](Unmount_MEGA_M.ps1) — Safely disconnects drive `M:` and stops the WebDAV listener.

### Quick Start:
1. Double-click **`Mount_MEGA_M.bat`**.
2. Drive **`M:\`** appears in Windows Explorer under *This PC* and opens automatically.
3. To unmount, double-click **`Unmount_MEGA_M.bat`** or right-click Drive `M:` $\rightarrow$ **Disconnect**.

---

## 3. Background Folder Sync

To continuously synchronize a local directory with a remote MEGA folder without installing the heavy desktop app:

```powershell
# Link a local folder to a cloud folder (runs via background daemon)
& "$env:LOCALAPPDATA\MEGAcmd\mega-sync.bat" "D:\Projects\SmartTV_Local" "/-TV_Smart-/"

# View active sync jobs and transfer status
& "$env:LOCALAPPDATA\MEGAcmd\mega-sync.bat"

# Stop a sync job by ID
& "$env:LOCALAPPDATA\MEGAcmd\mega-sync.bat" -d <SYNC_ID>
```

---

## 4. Deep Dive: Resolving Error 5 (`Unexpected failure to access server: 5`)

During script automation, you may encounter:
```text
Unexpected failure to access server: 5
```

### Root Cause Analysis:
1. **Windows Error 5** corresponds to `ERROR_ACCESS_DENIED`.
2. If `MEGAcmdServer.exe` is initiated from an elevated prompt or background service running with **High Mandatory Level** (Administrator privileges), Windows UAC Isolation prevents standard user processes (**Medium Mandatory Level** — such as double-clicking a `.bat` file) from opening its Named Pipe IPC (`\\.\pipe\MEGAcmd...`).
3. Furthermore, re-issuing `mega-webdav /` when the WebDAV server is already active causes an exclusive resource conflict error instead of returning the existing URL.

### The Robust Fix:
* `Mount_MEGA_M.ps1` ensures that `MEGAcmdServer.exe` is launched inside the standard interactive user desktop session.
* The script queries `MegaClient.exe webdav` first to discover any active endpoint URL before attempting to launch a new one.

---

## 5. Essential CLI Commands Cheat Sheet

All utilities are located in `%LOCALAPPDATA%\MEGAcmd\` and added to user `PATH`.

```powershell
# Authenticate
mega-login your_email@example.com "your_password"

# Verify active session
mega-whoami

# Storage quota and usage breakdown
mega-df

# Upload file to remote directory
mega-put "D:\build\app.apk" "/-TV_Smart-/"

# Download file from cloud
mega-get "/-TV_Smart-/app.apk" "D:\downloads\"

# List remote files
mega-ls "/-TV_Smart-/"

# Generate public link with decryption key
mega-export -a "/-TV_Smart-/app.apk"

# List active public links
mega-export -l

# Revoke public link
mega-export -d "/-TV_Smart-/app.apk"
```

# 🛡️ Xray VPN Automated Installers & Tray Agent for Windows (7 / 10 / 11)

> **Complete automated deployment suite and dynamic system tray sentinel for Xray Core (VLESS + Reality + Vision) on Windows 7, Windows 10, and Windows 11.**  
> *Author / Maintainer:* **Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))**  
> *Repository:* [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts) | *Path:* `Windows/VPN/`  
> *Tags:* `#XrayVPN #VLESS #Reality #Vision #WindowsVPN #SystemTray #PowerShell #Windows7 #Windows10 #Windows11 #NetworkSecurity #GinCz`

---

## 📌 Repository Contents & Installer Editions

| File | Scope & Capabilities |
| :--- | :--- |
| 🌟 **[`XRAY-VPN_VladiMIR__Win-ALL_109_&&&.bat` ↗](XRAY-VPN_VladiMIR__Win-ALL_109_&&&.bat)** | **Master Universal Edition (ALL):** Interactive OS selector menu with 1-click Windows 10/11 default (press `Enter`). Supports Windows 7, 10, and 11 within a single monolithic script. |
| 🚀 **[`XRAY-VPN_VladiMIR__Win10-11_109_&&&.bat` ↗](XRAY-VPN_VladiMIR__Win10-11_109_&&&.bat)** | Turnkey installer for **Windows 10 / 11** with fast downloads from dedicated master mirror servers. |
| 🚀 **[`XRAY-VPN_VladiMIR__Win7_&&&.bat` ↗](XRAY-VPN_VladiMIR__Win7_&&&.bat)** | Dedicated installer for **Windows 7** (native HTTP fallback channel, fully compatible with PowerShell 2.0 and .NET 3.5 without strict TLS 1.3 certificate issues). |
| 📖 **`README.md`** | Comprehensive architectural documentation, key formats, and user guide. |

---

## 🏗️ Architecture & Network Infrastructure

All installation assets can be provisioned through automated mirrors:

1. **Xray Core Binaries:**
   - 64-bit: `xray64.exe` (35.6 MB)
   - 32-bit: `xray32.exe` (33.9 MB)
   - ZIP archives: `win7_64.zip`, `win7_32.zip`
2. **Automated Deployment Scripts:**
   - Universal PowerShell deployment script with automatic system proxy configuration.
3. **High-Speed Delivery & Anti-Blocking:**
   - Mirror routing ensures fast download speeds (~40–80 MB/s) without CDN censorship or throttling.
   - Dual-protocol fallback: automatic HTTP fallback when legacy OS TLS handshakes fail.

---

## 🌟 Key Architecture & Features of TrayVPN Sentinel

### 1. 🛡️ Dynamic Pixel Vector Shield Icon (GDI+ 32-bit ARGB)
Instead of outdated 16-color static `.ico` files with visual artifacts, the shield icon is rendered **dynamically in memory** via `System.Drawing`:
* **Green Shield (`#00CD32`)** — VPN connected, system proxy active, outbound traffic secured.
* **Orange Shield (`#F09600`)** — Connecting, spawning core process, or polling remote endpoint.
* **Red Shield (`#E11919`)** — Connection error (invalid key, core crash, or unreachable host).
* **Crisp 1px Outline** — Dark border (`#0C1C0C`) ensuring crisp visibility on both light taskbars (Windows 7) and modern dark themes (Windows 10/11).

---

### 2. 💬 Multi-Line Hover Tooltip
Hovering the mouse cursor over the shield tray icon displays real-time telemetry:

```text
VPN: 195.63.138.33 (NL)
Orig: 185.100.197.0 (CZ)
VladiMIR
```

* **Line 1 (`VPN`):** Active external IP through the tunnel and 2-letter ISO country code.
* **Line 2 (`Orig`):** Native ISP external IP and country code prior to VPN connection.
* **Line 3:** User / Profile identifier extracted from the VLESS configuration tag.
* **Shell Overflow Protection:** Formatted strictly within **63 characters** (hard Windows Shell / WinForms limit on Windows 7/10) to prevent runtime tray crashes.

---

### 3. 🔔 Native Balloon Notifications
Instant toast notifications provide connection state feedback:
* **On Connected:**
  ```text
  Xray VPN: Connected
  VPN: 195.63.138.33 (NL)
  Orig: 185.100.197.0 (CZ)
  Profile: 4er-33-VladiMIR
  ```
* **On Configuration Error:**
  *Title:* `Xray VPN: Configuration Error`  
  *Text:* `No valid VLESS key found in link.txt. Right-click tray icon to edit key.`
* **On Timeout:**
  *Title:* `Xray VPN: Timeout`  
  *Text:* `Could not connect to server. Check network or key.`
* **On Core Crash:**
  *Title:* `Xray VPN: Stopped`  
  *Text:* `Xray process stopped. Right-click to view log or restart.`

---

### 4. 🖱️ Context Menu (Right-Click Tray)

```text
┌──────────────────────────────────────┐
│  VPN: 195.63.138.33 (NL)             │  (Connection status)
│  ID: 4er-33-VladiMIR                 │  (Server & profile name)
├──────────────────────────────────────┤
│  📝 Edit VLESS Key (link.txt)        │  (Open key config in Notepad)
│  📋 View Log (vpn.log)               │  (Inspect diagnostic log)
│  🔄 Restart VPN                      │  (Instant service restart)
├──────────────────────────────────────┤
│  ❌ Disconnect && Exit               │  (Reset system proxy & terminate)
└──────────────────────────────────────┘
```

---

### 5. ⏱️ Automated Installer with Auto-Close
* **Automatic UAC Elevation:** Requests administrator privileges via `fltmc`.
* **Proxy Sanitization:** Cleans stale WinHTTP and system proxy settings before installation.
* **OS Selection:** Interactive menu (Windows 10/11 vs Windows 7; Enter = default Windows 10/11).
* **Automated Setup:** Deploys `xray.exe`, generates `Start_VPN`, `Stop_VPN`, and `TrayVPN` shortcuts in `C:\XRAY_VPN\`.
* **Auto-Close Countdown:** 15-second countdown timer closes terminal automatically upon success.

---

## 🚀 Installation & Quick Start

1. Run **`XRAY-VPN_VladiMIR__Win-ALL_109_&&&.bat`** (or the OS-specific installer):
   - Confirm OS selection (`Enter` for Windows 10/11, or `2` for Windows 7).
2. Wait for automatic setup to complete (3–5 seconds).
3. In the opened Notepad window (`C:\XRAY_VPN\link.txt`), paste your VLESS reality key and save (`Ctrl+S`):
   ```text
   vless://uuid@server-ip:443?security=reality&...#server-name-username
   ```
4. Launch the **`Start_VPN`** shortcut in `C:\XRAY_VPN\`.
5. The **green shield** appears in the system tray: hover to view active IP and country.

---

## 🔧 Technical Requirements
* **Operating System:** Windows 7 SP1, Windows 8.1, Windows 10, Windows 11 (x64 / x86).
* **Runtime:** PowerShell 2.0+ (built-in Windows 7+), .NET Framework 3.5+.
* **Network:** HTTP/HTTPS protocols for IP telemetry validation.

---

*Maintained under [GinCz Infrastructure ↗](https://github.com/GinCz).*

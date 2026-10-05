# 🛡️ GIN-VPN (Windows System VPN Client & Tray Manager)

> **Repository:** [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)  
> **Current Version:** `v023`  
> **Desktop Executable:** `GIN-VPN_v023.exe`  
> **Icon:** Embedded Golden Shield with Dynamic Green/Red Tray Status (RGBA 32-bit PE Resource)

---

## ⚙️ Features & Architecture v023
* **Mandatory Live Tunnel Health Verification:**
  - Performs active end-to-end routing verification through `127.0.0.1:10809` before committing proxy settings.
  - **On Success:** Switches to `🟢 CONNECTED`, lights up **GREEN** tray badge, logs verified IP, waits 1.8s and smoothly minimizes to tray.
  - **On Failure:** Leaves direct ISP connection intact, sets status to `🔴 DISCONNECTED`, keeps tray icon **RED**, and keeps window open with error diagnostics.
* **Startup & Server Management:**
  - Shows connection diagnostics for 1.8s at launch, minimizing only upon verified connection.
  - Right-click server context menu (`⚡ Connect`, `★ Set Default`, `✏️ Rename`, `🗑 Delete`, `📋 Copy Key`).
  - Day & Night quick switches for Fluent Light and Dark OLED themes.

# 🛡️ GIN-VPN (Windows System VPN Client & Tray Manager)

> **Repository:** [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)  
> **Current Version:** `v022`  
> **Desktop Executable:** `GIN-VPN_v022.exe`  
> **Icon:** Embedded Golden Shield with Dynamic Green/Red Tray Status (RGBA 32-bit PE Resource)

---

## ⚙️ Features & Architecture v022
* **Dynamic Green/Red Tray Status Indicator:**
  - **🟢 Connected:** Tray icon shows a vibrant green active indicator badge and tooltip with protected IP and node name.
  - **🔴 Disconnected:** Icon dynamically toggles to disconnected indicator state.
* **Auto-Connect and Minimize on Launch:**
  - Starts up by establishing the tunnel to the default node and cleanly minimizing straight to tray (`SW_HIDE`).
  - Double-clicking any server in the list connects and minimizes to tray.
* **Active Xray Core Lifecycle Management:**
  - Dynamic `vless://` URI parser (Reality, XTLS-Vision, SNI, Flow, SPX).
  - Background daemon launch of `xray.exe` with no console window (`CREATE_NO_WINDOW`).
  - Active proxy port verification (`127.0.0.1:10809` HTTP / `10808` SOCKS).
* **Server Management & Themes:**
  - Right-click server context menu (`⚡ Connect`, `★ Set Default`, `✏️ Rename`, `🗑 Delete`, `📋 Copy Key`).
  - Day & Night quick switches for Fluent Light and Dark OLED themes.
  - Dual IP Checks in tray menu for RU and EU verification portals.

# 🛡️ GIN-VPN (Windows System VPN Client & Tray Manager)

> **Repository:** [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)  
> **Current Version:** `v021`  
> **Desktop Executable:** `GIN-VPN_v021.exe`  
> **Icon:** Embedded Golden Shield (RGBA 32-bit PE Resource)

---

## ⚙️ Features & Architecture v021
* **Active Xray Core Lifecycle Management:**
  - Dynamic `vless://` URI parser (Reality, XTLS-Vision, SNI, Flow, SPX).
  - Background daemon launch of `xray.exe` with no console window (`CREATE_NO_WINDOW`).
  - Active proxy port verification (`127.0.0.1:10809` HTTP / `10808` SOCKS).
  - Background live exit IP verification.
* **Server Management:**
  - **Double-Click:** Connect to chosen server and minimize to tray.
  - **Single-Click:** Safe row selection without reconnecting.
  - **Right-Click Context Menu:**
    - `⚡ Connect to this Server`
    - `★ Set as Default`
    - `✏️ Rename Profile`
    - `🗑 Delete Profile`
    - `📋 Copy VLESS Reality Key`
* **Day & Night Themes:**
  - `☀️ Day` and `🌙 Night` quick switches for Fluent Light and Dark OLED themes.
* **Dual IP Checks in Tray & GUI:**
  - Instant 1-Click access to RU (`prodvig-saita.ru/ip`) and EU (`eco-seo.cz/ip`) IP check portals.
  - Tray menu displays active exit node IP/country and original ISP IP.

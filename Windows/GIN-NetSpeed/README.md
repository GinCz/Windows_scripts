# 📊 GIN-NetSpeed (v002)
> **100% Portable Live Application Bandwidth Monitor, 15-Minute Traffic Graph & Multi-Cloud Engine Speed Benchmark for Windows 10/11**
> *Developed by VladiMIR+AI (Vladimir Bulantsev — GinCz)*

---

## 🚀 Key Features

* **📈 15-Minute Rolling Dual-Wave Bandwidth Graph (Task Manager / NetBalancer Style):**
  * Flicker-free double-buffered GDI matrix canvas showing **Download (`⬇ Emerald Green`)** and **Upload (`⬆ Vibrant Amber/Orange`)** speeds over the last **15 Minutes**, **5 Minutes**, or **60 Seconds**.
  * **Standby by Default & Double-Click Toggle:** Starts clean/empty by default. **Double-click** any application row in the table to attach it to the top 15-minute graph; **double-click** it again to detach and clear the graph.
* **📊 Excel-Style Column Sorting & Clean Zero-Scroll Layout:**
  * Clean 9-column layout with **zero horizontal scrolling** (`#`, `Cloud / Category`, `Application (.exe)`, `PID`, `⬇ Download`, `⬆ Upload`, `Total Downloaded`, `Total Uploaded`, `Channel %`).
  * Click **any column header** directly to sort ascending/descending (`▲` / `▼`) just like in Microsoft Excel.
  * Smooth dynamic window resizing (`WM_SIZE` & `WM_GETMINMAXINFO`) — stretches the graph, table, and status bar cleanly when dragging the window corner.
* **☁️ Automatic Cloud Engine Recognition & Color-Coding:**
  * Automatically highlights and categorizes major cloud synchronization clients:
    * ☁ ● **MEGA Cloud** (`MEGAsync.exe`, `mega-cmd`)
    * ☁ ▲ **Google Drive** (`GoogleDriveFS.exe`)
    * ☁ ■ **Microsoft OneDrive** (`OneDrive.exe`)
    * ☁ ◆ **Yandex.Disk** (`YandexDisk2.exe`)
    * ☁ ★ **Mail.Ru Cloud / Disk-O** (`CloudMailRu.exe`, `DiskO.exe`)
    * ☁ ◆ **Dropbox**, **Nextcloud**, **Apple iCloud**, **TeraBox**, **Rclone / Syncthing**
* **⚡ Built-in Cloud Engines Speed Benchmark (`☁ Cloud Speed Test`):**
  * **Mode 1 — Direct Cloud CDN Speed Test:** Benchmarks **Small Files (100 KB)** vs **Large Files (10 MB)** Upload & Download speeds and TCP Handshake Latency across **MEGA, Google Drive, Microsoft OneDrive, Yandex.Disk, Mail.Ru Cloud, Dropbox, and Cloudflare Edge**.
  * **Mode 2 — Local Cloud Sync Folder Benchmark:** Automatically detects installed local cloud sync folders, drops real temporary Small (`15 × 100 KB`) and Large (`10 MB`) payloads, measures real-time upload speed, and cleans up automatically.
* **🔒 100% Portable & Zero Background Processes:**
  * Standalone native 64-bit Windows `.exe` with **zero external dependencies** and **no kernel drivers**.
  * Guaranteed clean exit (`ExitProcess(0)` on window close) — leaves **zero background processes or services** running.

---

## 📥 Download & Usage

* Download the standalone portable executable: [`GIN-NetSpeed_v002.exe`](GIN-NetSpeed_v002.exe)
* Requires Windows 10 or Windows 11 (64-bit). Runs immediately as a portable app (optional 1-click `Install` button included).

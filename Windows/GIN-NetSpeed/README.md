# 📊 GIN-NetSpeed (v003)
> **100% Portable Live Application Bandwidth Monitor, Multi-App 15-Minute Traffic Graph & Multi-Cloud Engine Speed Benchmark for Windows 10/11**
> *Developed by VladiMIR+AI (Vladimir Bulantsev — GinCz)*

---

## 🚀 Key Features

* **📈 15-Minute Multi-App Rolling Bandwidth Graph (Task Manager / NetBalancer Style):**
  * **Multi-App Comparison (1–4 Apps Simultaneously):** Starts clean/empty by default. **Double-click** 1, 2, 3, or 4 application rows in the table (`[1]`, `[2]`, `[3]`, `[4]`) to overlay and compare their real-time Download & Upload curves on the top graph. **Double-click** an added row again to remove it from the graph.
  * **Interactive Download & Upload Toggle Buttons:** Click the green **`⬇ DOWNLOAD [✓ ON]`** button or the yellow/amber **`⬆ UPLOAD [✓ ON]`** button on the right side of the graph to independently show or hide Download and Upload curves and average lines.
  * **Vertical Y-Axis Speed Scale Markings:** Clear vertical speed scale labels (`100%`, `75%`, `50%`, `25%`, `0 B/s`) along the left edge of the graph.
  * **Horizontal Average Speed Line & Left Numerical Callout:** Draws a horizontal dashed line across the graph at the calculated average Download and Upload speeds, with a clear numerical callout badge on the left edge showing the exact average speed (`⬇ X.X KB/s` or `MB/s` and `⬆ X.X KB/s` or `MB/s`).
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

* Download the standalone portable executable: [`GIN-NetSpeed_v003.exe`](GIN-NetSpeed_v003.exe)
* Requires Windows 10 or Windows 11 (64-bit). Runs immediately as a portable app (optional 1-click `Install` button included).

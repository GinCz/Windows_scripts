# 📜 CHANGELOG — GIN-NetSpeed

## [v003] — 2026-11-08
### Added & Improved
- **Multi-Application Graph Comparison (2–4 Apps Simultaneously):** Double-clicking rows in the table adds/removes applications to the top 15-minute graph (up to 4 apps simultaneously, marked `[1]`, `[2]`, `[3]`, `[4]`) with distinct color curves and row highlights.
- **Interactive Download & Upload Toggle Buttons on the Right:** The green (`⬇ DOWNLOAD [✓ ON]`) and yellow/amber (`⬆ UPLOAD [✓ ON]`) cards on the right side of the graph are now interactive toggle buttons — click either card to turn Download or Upload curves and average lines ON/OFF independently.
- **Left Y-Axis Vertical Speed Markings:** Added clear vertical speed scale labels (`100%`, `75%`, `50%`, `25%`, `0 B/s`) along the left edge of the 15-minute graph.
- **Horizontal Dashed Average Speed Line & Left Numerical Callout Badge:** Dynamically calculates the average Download and Upload speeds across the active time window, draws horizontal dashed average lines across the graph, and displays a high-contrast numerical callout badge (`⬇ X.X KB/s` or `MB/s` and `⬆ X.X KB/s` or `MB/s`) on the left side at the exact height of the average line.

## [v002] — 2026-11-08
### Changed & Improved
- **Clean Table Layout (Zero Horizontal Scrollbar):** Removed `Sockets`, `Peak Down`, `Peak Up`, and `Remote Cloud / IP Endpoints` columns so the entire table fits cleanly on screen without horizontal scrolling.
- **Renamed Session Counters:** Renamed `Session Down` / `Session Up` to **`Total Downloaded`** and **`Total Uploaded`** (accumulated traffic downloaded/uploaded since program launch or last Reset).
- **Excel-Style Clickable Column Sorting (`LVN_COLUMNCLICK`):** Added direct sorting by clicking any column header (`#`, `Cloud / Category`, `Application (.exe)`, `PID`, `⬇ Download`, `⬆ Upload`, `Total Downloaded`, `Total Uploaded`, `Channel %`) with `▲` / `▼` sort indicators.
- **Empty Graph by Default + Double-Click Attach/Detach (`NM_DBLCLK`):** Graph starts clean/empty on startup. Double-clicking any row attaches/detaches that process on the top 15-minute graph (`★`).
- **Full Dynamic Window Resizing (`WM_SIZE`):** Dragging the bottom-right window corner smoothly resizes the 15-minute graph canvas, the ListView table, the last column width, and the bottom status bar / buttons.
- **Clean BMP Unicode Icons:** Replaced supplemental emojis that rendered as square boxes (`□`) in Windows GDI with crisp BMP symbols (`☁`, `●`, `▲`, `■`, `◆`, `★`, `⚡`, `⬇`, `⬆`).

## [v001] — 2026-11-08
### Added
- **Initial Release (`v001`)** built in the signature visual style of `GIN-NetScan`.
- **15-Minute Rolling Traffic Graph:** Double-buffered GDI matrix chart with selectable `15 Min`, `5 Min`, and `60 Sec` windows.
- **Per-Process Network Speed Monitor & Cloud Engine Benchmark (`☁ Cloud Speed Test`).**

# 📝 WORKLOG — GIN-Dock-Wallpaper Development

## Session: 2026-11-20
- **Requirement Analysis**: Analyzed request from Vladimir Bulantsev (@GinCz) to merge GIN-Dock and GIN-Wallpaper into a unified open-source utility `GIN-Dock-Wallpaper`.
- **Icon Engineering**: Designed multi-resolution Windows icon (`app.ico` and `icon_256.png`) featuring warm sand tones and modern ivory 'G' emblem.
- **Dock UI Enhancement**: Removed static left arrow icon next to the brand logo; implemented smooth mouse wheel scrolling for overflow handling.
- **Core Engine Development**:
  - Unified C# WinAPI / GDI+ architecture targeting .NET Framework 4.5+ (AnyCPU).
  - Built Wallhaven 4K wallpaper downloader and live calendar overlay HUD renderer.
  - Implemented 12 color themes and 12 multilingual localizations.
  - Added separate font size sliders for folders and shortcuts.
  - Added dock placement support (Top / Left).
  - Added sorting choices with alphabetical as default.
  - Added independent feature toggles for Dock and Wallpaper.
- **Installer & Uninstaller Construction**:
  - Built self-contained uninstaller `Uninstall.exe` and `uninstall.cmd`.
  - Built standalone installer `GIN-Dock-Wallpaper_v032_Setup.exe` with base64 payload embedding.
  - Built hybrid polyglot script installer `GIN-Dock-Wallpaper_Setup_v032.cmd`.
- **Public Repository Setup**: Created comprehensive documentation, build scripts (`build.cmd`, `build.sh`), and `version.json` in `Windows_scripts/GIN-Dock-Wallpaper`.

## Update: v033 (2026-11-20)
- Redesigned Settings dialog architecture with 4 dedicated tabs: Main, Wallpaper & Calendar, Dock Bar, and About.
- Integrated all 14 Wallpaper categories from legacy GIN-Wallpaper into dedicated checkboxes.
- Implemented vertical Font Accordion with 12 curated fonts and independent font size / family controls for folders and items.
- Added icon size configuration (16px to 64px) for the dock.
- Fixed language switching reactivity: real-time re-localization of all UI elements and context menu on dropdown change.
- Added Apply button to allow testing changes without closing settings.
- Uploaded v033 installers to MEGA Desktop and Flash drive; purged obsolete v002 files.

## Update: v034 (2026-11-20)
- Re-architected Auto-Update mechanism: eliminated browser redirect; implemented background download to `%TEMP%`, update confirmation prompt, installer execution, and silent app restart.
- Implemented double-click on system tray icon to immediately fetch a fresh 4K wallpaper and update the calendar HUD.
- Implemented master "Все" / "All" checkbox logic across wallpaper categories with bi-directional synchronization.
- Wired "Apply" button to immediately trigger new wallpaper download, calendar HUD rendering, and dock update on click.
- Added "Off" dock placement state alongside "Top" and "Left".
- Formatted signature footer `VladiMIR+AI  |||  v034` with interactive link and auto-update trigger.
- Enforced strict Rule 15 and user rule: deleted unversioned files from MEGA Desktop; strictly retained only 2 latest versioned installers (`v033` and `v034`).

## Update: v042 (2026-11-20)
- **Resolved Wallpaper Generation & Startup Sync**: Fixed defect where wallpaper engine only ran after timer elapsed; added automatic startup trigger (`TriggerNextWallpaperAsync`) 800ms after launch so desktop refreshes immediately.
- **Configured TLS 1.2 / TLS 1.3 Security Protocols**: Set `ServicePointManager.SecurityProtocol` to guarantee HTTPS connectivity with Cloudflare-protected Wallhaven API, Unsplash, and Picsum endpoints.
- **Multi-Tier Resilient 4K Downloader**: Engineered 6-tier fallback pipeline (Wallhaven Search with random candidate selection -> Lorem Picsum UHD CDN -> Curated Unsplash 4K pool -> Local Cache -> Existing Windows wallpaper -> Dark Gradient) with custom `TimeoutWebClient` (8-10s timeout).
- **Screen-Calibrated Wallpaper & HUD Rendering**: Wallpapers are dynamically scaled and cropped to the primary display resolution before overlaying the Calendar HUD, preventing clipping or distortion from Windows Fill scaling.
- **Dual Alternating Desktop Slots**: Replaced static file path with alternating slots (`active_desktop_hud_A.jpg` and `active_desktop_hud_B.jpg`), preventing GDI+ file lock exceptions and forcing Windows to immediately repaint the desktop.
- **Automated Cache Purge**: Added cleanup logic to limit cached wallpapers and purge stale temporary files.
- **Legacy GIN-Wallpaper Cleaner**: Installer terminates legacy processes (`GIN-Wallpaper-Calend`, `GIN-Wallpaper`), removes obsolete autostart registry entries, and cleans old desktop shortcuts.
- **Standalone Installer Build**: Compiled standalone `GIN-Dock-Wallpaper_v042_Setup.exe` (700KB), updated mirrors, and synced to MEGA Desktop (retaining strictly v041 and v042).

## Update: v041 (2026-11-20)
- **Eliminated Tab Scrollbars**: Disabled `AutoScroll` across all tab pages to completely remove the vertical scrollbar.
- **Compacted Tab 2 Vertical Rhythm**: Reduced spacing across categories, intervals, calendar scale, and font selection grid; all controls end at `Y=508px`, fitting comfortably within the 530px TabPage client height.
- **Button Width Calibration**: Expanded `Сохранить текущие обои в Изображения` to 350px width at `Point(355, 480)`.
- **Standalone Installer Build**: Compiled standalone `GIN-Dock-Wallpaper_v041_Setup.exe` (666KB), updated mirrors, and synced to MEGA Desktop (retaining v040 and v041).

## Update: v040 (2026-11-20)
- **Settings Form Height Recalibration**: Resolved issue where bottom footer bar containing `Применить`, `Сохранить и закрыть`, `Отмена`, and `VladiMIR+AI ||| v040` was positioned below form boundaries (Y=715 vs height 670).
- **Exact ClientSize Standard**: Set `this.ClientSize = new Size(760, 656)` (outer window ~694px) to ensure perfect fit across 1080p, 1080p@125% DPI, and 1366x768 laptop displays.
- **Compact Spacing on Tab 2 & Tab 3**: Compacted vertical intervals for categories, interval buttons, calendar scale, font selector, and dock settings, ensuring all controls are visible without clipping.
- **AutoScroll Resilience**: Added `AutoScroll = true` to all TabPages as defensive insurance against extreme Windows display scaling (150%+).
- **Category Localization Fix**: Reconciled `ApplyLocalization()` dictionary to cover all 20 categories.
- **Standalone Installer Build**: Compiled standalone `GIN-Dock-Wallpaper_v040_Setup.exe` (666KB), updated mirrors, and synced to MEGA Desktop (retaining v039 and v040).

## Update: v039 (2026-11-20)
- **Zero-CMD Distribution**: Eliminated all `.cmd` hybrid installers per user directive; distributed strictly as 660KB single-file binary installer `GIN-Dock-Wallpaper_v039_Setup.exe`.
- **24 Curated Fonts**: Expanded fonts palette from 12 to 24 curated typefaces, integrating expressive calligraphic and display typography (`Gabriola`, `Ink Free`, `Impact`, `Comic Sans MS`, `Sitka Banner`, `Palatino Linotype`, `Garamond`, etc.).
- **Calendar HUD 5-Button Scale & Deactivation**:
  - Simplified label to `Календарь:`.
  - Added `[ Нет ]` button to turn off calendar HUD without losing chosen font or scale settings.
  - Stretched buttons evenly across dialog width to eliminate text cutoff.
- **Dock Brand Button Customization**:
  - Removed `GIN` text from the dock button.
  - Implemented 20 selectable icons (`⊞`, `🚀`, `⚡`, `💎`, `🌟`, `🏠`, `⚙️`, etc.) in Tab 3.
- **Pulsing Cyan Download Animation**:
  - Added `DownloadStateChanged` event in `WallpaperEngine`.
  - Implemented 75ms pulsing cyan halo animation on the System Tray icon and Dock bar button while new 4K wallpapers are being downloaded and processed.
- **2-Column Wallpaper Themes & Dark Horse Expansion**:
  - Restructured category checkboxes into 2 wide 330px columns, resolving column overlap.
  - Added `🐴 Тёмная лошадка` (`Dark Horse`), `🔍 Макро`, `🏛️ Архитектура`, `✈️ Авиация`, `🌴 Ретровейв`, `🐉 Фэнтези`, `🐬 Подводный мир`.
- **Top-Left Placement**: Window opens with ~75px (~2 cm) top and left margin.
- **Auto-Update Engine Hardening**: Added integer version parsing and cache-busting ticks.
- **Cloud & Repo Mirroring**: Mirrored release artifacts, purged obsolete `.cmd` files and `v037`, retaining strictly `v038` and `v039`.

## Update: v038 (2026-11-20)
- **Relocated Font Palette to Wallpaper & Calendar Tab**:
  - Moved the 12 curated font buttons (`Segoe UI`, `Tahoma`, `Arial`, `Verdana`, `Georgia`, `Corbel`, `Consolas`, `Trebuchet MS`, `Cambria`, `Century Gothic`, `Candara`, `Calibri`) from Tab 1 to Tab 2 (`_tabWall`).
  - Returned Tab 1 (Главные) to a clean, focused control center for main toggles and the 10 theme presets.
- **Direct Wallpaper & Calendar Generation on Font Click**:
  - Clicking a font button no longer alters GUI fonts of the settings dialog.
  - Updates `CalendarFontFamily`, saves configuration, updates button active highlight, and immediately calls `TriggerNextWallpaperAsync()` to generate a fresh 4K wallpaper with the calendar HUD rendered in the chosen typeface.
- **4-Button Responsive Calendar Scale**:
  - Replaced trackbar with 4 responsive toggle buttons: `Маленький` (0.75x), `Средний` (1.0x), `Большой` (1.3x), `Крупный` (1.6x).
  - Clicking any scale button immediately saves the scale and triggers `TriggerNextWallpaperAsync()` to generate a new wallpaper and redraw the calendar at the requested scale.
- **Defensive Queueing in WallpaperEngine**:
  - Added `_queuedRequest` in `WallpaperEngine` so rapid clicks between fonts and scales are never dropped while a download is in progress.
  - Added fallback to `_lastDownloadedPath` if an image download fails or experiences network lag, ensuring the calendar HUD is always redrawn immediately.
- **Build & Cloud Deployment**:
  - Compiled `Uninstall.exe`, `GIN-Dock-Wallpaper.exe`, `GIN-Dock-Wallpaper_v038_Setup.exe`, and `GIN-Dock-Wallpaper_Setup_v038.cmd`.
  - Mirrored release artifacts to `Windows_scripts/GIN-Dock-Wallpaper/` and `Windows_scripts/GIN-Wallpaper/`.
  - Purged obsolete `v036` releases across local mirrors and MEGA storage; strictly retained the 2 latest versions (`v037` and `v038`).

## Update: v037 (2026-11-20)
- **Implemented Real-Time Settings Font Re-Styling**: Created `ApplyFontToForm(string fontName)` with recursive control styling preserving bold/regular styles, updating dialog controls immediately upon clicking any of the 12 font buttons on Tab 1.
- **Fixed Dock Folder Flicker**: Diagnosed cause of dropdown blinking (interaction between ToolTip window, `AutoClose = true`, and mouse coordinate re-checks). Set `AutoClose = false`, removed tooltip on folder buttons, and created `IsCursorOverDropDownHierarchy` for stable hover navigation.
- **Completed Tab 2 & Tab 4 Localization**: Connected all 13 wallpaper category checkboxes and the About tab controls to reactive dictionary lookups in `ApplyLocalization()`.
- **Compiled & Published v037**: Produced binaries and setup scripts; updated MEGA cloud mirrors; purged obsolete `v035` keeping strictly `v036` and `v037`.

## Update: v036 (2026-11-20)
- **Resolved WinForms Variable Font Bug**: Replaced `Bahnschrift` with `Tahoma` across the 12 font presets and stabilized dialog fonts on `Segoe UI` (9pt / 9.5pt), eliminating wide character gaps and overlapping letters.
- **Fixed Theme Engine**: Corrected `ThemeManager.GetTheme` logic to prioritize explicit theme IDs before falling back to time-of-day modes, enabling immediate theme color changes when clicking theme buttons.
- **Relocated Font Engine**: Moved the 12 live preview font buttons from Tab 2 to Tab 1 (Главные), streamlining configuration.
- **Live Real-Time Dock Resizing**: Added dynamic callback on icon size button clicks (`16`, `24`, `32`, `48`, `64` px) that clears shell icon cache and updates the dock instantly.
- **Hover-To-Open Dock Folders**: Implemented cursor tracking and `_folderMap` inspection in `DockBarForm` to display folder dropdowns automatically on hover without mouse clicks.
- **Localization Polish**: Verified and fixed dock position translations (`⬆ Вверху`, `⬅ Слева`).
- **Compiled & Released v036**: Produced `GIN-Dock-Wallpaper.exe`, `Uninstall.exe`, `GIN-Dock-Wallpaper_v036_Setup.exe`, and `GIN-Dock-Wallpaper_Setup_v036.cmd`. Synchronized to `GIN-Wallpaper` and MEGA cloud, purging obsolete `v034`.

## Update: v035 (2026-11-20)
- Transformed SettingsForm to GIN-VPN visual design language:
  - Top header bar with Day (`☼`), Evening (`☁`), Night (`☾`) mode buttons, Language (`EN`, `RU`, `CS`), and Sound (`♪`) toggle.
  - Replaced dropdowns with responsive toggle buttons: Dock placement (Top, Left), Wallpaper interval (1h, 3h, 6h, 24h), and 10 Theme buttons.
  - Implemented 12 curated Font buttons with typography preview that immediately style the whole Settings form live on click.
  - Fixed dock icon scaling: implemented 5 icon size buttons (16, 24, 32, 48, 64 px) with true un-clamped folder and shortcut icon rendering and dynamic dock bar height resizing.
  - Repositioned brand footer to bottom-right: `VladiMIR+AI ||| v035` in clean amber/gold typography without underline, matching GIN-VPN.
  - Guaranteed zero browser redirects during update checking: strictly downloads to `%TEMP%` and executes installer.
  - Purged v033 from deployment targets; retained strictly v034 and v035.

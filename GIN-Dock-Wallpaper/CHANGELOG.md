# 📋 CHANGELOG — GIN-Dock-Wallpaper

## [v032] — 2026-11-20
### 🌟 Major Release: Unified Dock & Dynamic 4K Wallpaper Engine
- **Product Merger**: Combined `GIN-Dock` and `GIN-Wallpaper` into a single, cohesive application: `GIN-Dock-Wallpaper`.
- **Open Source Transition**: Moved project from private development into the public open-source repository `Windows_scripts/GIN-Dock-Wallpaper`.
- **New Visual Identity**:
  - Designed custom sand-colored icon with bold typographic **G** for tray, executable, installer, and uninstaller.
  - Completely removed the redundant left arrow (`◀`) next to the GIN brand logo for a streamlined interface.
- **Dual Independent Toggles**:
  - Added individual settings checkboxes to enable or disable the Dock bar or Wallpaper engine independently.
- **Typographic Controls**:
  - Created separate font size controls for Folder items and open application icons (7–16 pt).
- **Placement & Orientation**:
  - Added option to position the dock along the screen **Top** (slide down) or screen **Left** (slide right).
- **Sorting Modes**:
  - Implemented configurable sorting: Alphabetical A–Z (default), Reverse Alphabetical Z–A, Folders First, File Type, and Date Modified.
- **Themes & Day/Night Mode**:
  - Added Day / Night mode selection (Auto system sync, Day light mode, Night dark mode).
  - Included 12 distinct color themes: Warm Sand, Midnight OLED, Cyberpunk Amber, Nordic Frost, Emerald Forest, Deep Space Navy, Solarized Desert, Tokyo Neon, Pure Glass, Rose Gold, Titanium, and Daylight Light.
- **Multilingual Support**:
  - Added language dropdown with instant switching across 12 languages: English (default), Russian, Czech, German, French, Spanish, Italian, Portuguese, Polish, Ukrainian, Chinese, and Japanese.
- **Installer & Uninstaller**:
  - Created standalone single-executable installer `GIN-Dock-Wallpaper_v032_Setup.exe` and 1-click hybrid script `GIN-Dock-Wallpaper_Setup_v032.cmd`.
  - Added dedicated `Uninstall.exe` and `uninstall.cmd` inside the program folder.
- **Update Checking**:
  - Added auto-update check on startup and manual check via system tray menu.

## [v033] — 2026-11-20
### 🌟 Tab Restructuring, 14 Wallpaper Themes, Font Accordion & Real-Time I18n
- **Dedicated Main Tab**: Features Day / Evening / Night time-of-day switcher, real-time Language selector, feature toggles, and autostart.
- **Dedicated Wallpaper Tab**: Fully restored all 14 curated categories with multi-select checkboxes (All Random, 3D, Flowers, Ocean, Space, Nature, Animals, Cars, Trucks, Fashion/Girls, City, Cyberpunk, Minimalism, Anime), interval, and calendar HUD controls.
- **Dedicated Dock Tab**: Complete dock controls with placement, root folder, icon size selector (16, 24, 32, 48, 64 px), sorting, and auto-hide delay.
- **Font Selection Accordion**: Expandable panel stretching window vertically with 12 curated fonts for Dock Folders, Dock Items, and Wallpaper Calendar.
- **Real-Time Localization Fix**: Switching language in the dropdown instantly translates the entire Settings dialog and System Tray menu in real time without restart.
- **Dedicated Apply Button**: Added `Apply` button alongside `Save & Close` and `Cancel` to immediately commit changes without dismissing the dialog.

## [v034] — 2026-11-20
### 🚀 1-Click Auto-Update, Tray Double-Click, Category Select-All & Immediate Apply
- **One-Click Seamless Auto-Updater**: Checking for updates (via tray menu or footer) downloads the new setup executable directly to `%TEMP%`, prompts confirmation with changelog, launches the installer, and cleanly restarts without opening browser URLs.
- **System Tray Double-Click**: Double-clicking the sand 'G' icon in the system tray immediately fetches a fresh 4K wallpaper, renders the live calendar HUD, and updates the desktop background.
- **Select-All Wallpaper Categories Checkbox**: The master "Все" ("All") checkbox dynamically checks or unchecks all 13 wallpaper theme categories; toggling child checkboxes reactively updates the master checkbox.
- **Immediate Apply Execution**: Clicking "Применить" (`Apply`) immediately downloads a new 4K wallpaper, renders the calendar HUD, and refreshes desktop and dock state on the fly.
- **Dock Placement Options**: Expanded dock placement to include `Top`, `Left`, and `Off`.
- **Interactive Signature Footer**: Form footer features `VladiMIR+AI  |||  v034` with clickable links: `VladiMIR+AI` links to GitHub profile; clicking `v034` initiates the auto-update check.
- **Deployment Streamlining**: Purged all unversioned files and shortcuts; retained strictly the 2 latest versions (`v033` and `v034`).

## [v035] — 2026-11-20
### 💎 GIN-VPN Heritage UI, Interactive Buttons, Zero-Browser Auto-Updater & Real Icon Sizing
- **GIN-VPN Styled Top Bar**: Integrated top header bar featuring Day (`☼`), Evening (`☁`), and Night (`☾`) mode buttons, Language switcher (`EN`, `RU`, `CS`), and Sound effects toggle (`♪`).
- **Zero-Browser In-App Auto-Updater**: Strictly eliminated any browser redirects on "Проверить обновление" / update checks. Directly queries `version.json`, prompts update confirmation, downloads `%TEMP%\GIN-Dock-Wallpaper_<version>_Setup.exe`, executes it, and cleanly restarts.
- **Button-Driven Controls**:
  - **Dock Placement**: Sleek `⬆ Сверху (Top)` and `⬅ Слева (Left)` toggle buttons replacing dropdown.
  - **Color Themes**: 10 responsive theme buttons with live, instant re-coloring of the Settings form on click.
  - **Wallpaper Interval**: 4 quick toggle buttons (`1 час`, `3 часа`, `6 часов`, `24 часа`).
  - **12 Curated Font Buttons with Live Preview**: Each button rendered in its own typeface; clicking immediately styles the entire Settings dialog in real time.
- **Real Dock Icon Sizing & Geometry**: 5 icon size buttons (`16 px`, `24 px`, `32 px`, `48 px`, `64 px`) with actual dynamic scaling of folder icons and shortcuts without clamp, adapting dock bar height and panel layout.
- **GIN-VPN Signature Footer**: Bottom-right clean gold typography `VladiMIR+AI ||| v035` without underline; left side hosts `Применить`, `Сохранить и закрыть`, and `Отмена`.
- **Deployment Retention**: Purged `v033`; retained strictly the 2 latest versions (`v034` and `v035`).

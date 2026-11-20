# 📋 CHANGELOG — GIN-Dock-Wallpaper

## [v039] — 2026-11-20
### 🌟 24 Curated Fonts, Calendar Toggle Off, Modernized Dock Icon & Animated Download Glow
- **Zero-CMD Standalone Distribution**: Discontinued hybrid `.cmd` scripts per user request; all installations and updates are now distributed strictly as ultra-compact native ~660KB executable installers (`GIN-Dock-Wallpaper_v039_Setup.exe`).
- **24 Curated Artistic & Graphic Fonts**: Doubled the font palette on Tab 2 (Wallpaper & Calendar) from 12 to 24 curated typefaces, adding flourishing script, graphic, and display fonts (`Gabriola`, `Ink Free`, `Impact`, `Comic Sans MS`, `Sitka Banner`, `Palatino Linotype`, `Garamond`, `Franklin Gothic Medium`, etc.).
- **Streamlined Calendar HUD Controls with "Off" Toggle**:
  - Simplified header to clean `Календарь:` (removing redundant word `Масштаб`).
  - Added dedicated `[ Нет ]` (`Off`) button allowing complete deactivation of the calendar HUD on the desktop wallpaper.
  - Stretched the 5 buttons (`Нет`, `Маленький`, `Средний`, `Большой`, `Крупный`) evenly across the full dialog width.
- **Modernized Dock Button & 20 Selectable Brand Icons**:
  - Removed `GIN` text from the dock bar button.
  - Replaced fixed lightning symbol with 20 selectable icons in Tab 3 (Docker Settings): `⊞` (Windows Start), `🚀`, `⚡`, `💎`, `🌟`, `🏠`, `⚙️`, `🧭`, `🍀`, `🔥`, `👑`, `🎯`, `🛸`, `🛡️`, `🎮`, `💻`, `💡`, `✨`, `🌀`, `⚓`.
  - Clicking any icon immediately updates the dock bar on the desktop.
- **Pulsing Cyan Glow Animation During Wallpaper Downloads**:
  - Implemented real-time breathing halo animation on the System Tray icon and dock brand button during wallpaper retrieval and rendering.
- **Expanded Wallpaper Themes & 2-Column Wide Layout**:
  - Eliminated text overlap and column clipping by re-architecting category checkboxes into 2 wide 330px columns.
  - Added new themes including `🐴 Тёмная лошадка (Таинственное)` (`Dark Horse`), `🔍 Макро и текстуры`, `🏛️ Архитектура и города`, `✈️ Авиация и истребители`, `🌴 Ретровейв и 80-е`, `🐉 Фэнтези и миры`, and `🐬 Подводный океан`.
- **Top-Left Initial Window Placement**: Configured SettingsForm to automatically open in the upper-left quadrant with a comfortable ~2 cm (~75px) margin from the screen edge.
- **Reliable Auto-Update Engine**: Replaced string comparison with integer version parsing and added cache-busting `?_t=` parameter to `version.json` queries to bypass GitHub CDN caching.

## [v038] — 2026-11-20
### 🎨 Relocated Fonts to Wallpaper Tab, Direct Desktop Wallpaper Generation & 4-Button Calendar Scale
- **Relocated Font Palette to Wallpaper & Calendar Tab**: Moved the 12 curated font buttons from Settings Tab 1 to Tab 2 (Обои и Календарь), returning Tab 1 to a clean, focused toggle and theme-selection dashboard.
- **Direct Desktop Wallpaper Generation on Font Selection**: Clicking any of the 12 font buttons preserves standard clean dialog typography in the settings window, updates `CalendarFontFamily`, and immediately triggers generation of a new 4K desktop wallpaper displaying the calendar HUD in the newly chosen typeface.
- **4-Button Responsive Calendar Scale**: Replaced the scale trackbar with 4 intuitive scale buttons:
  - `Маленький` (Small: 0.75x)
  - `Средний` (Medium: 1.0x)
  - `Большой` (Large: 1.3x)
  - `Крупный` (Huge / Extra Large: 1.6x)
  Clicking any scale button immediately generates a new wallpaper and redraws the calendar in the requested scale.
- **Non-Dropping Wallpaper Engine Queue**: Enhanced `TriggerNextWallpaperAsync` with non-blocking queued requests, ensuring rapid sequential clicks between fonts and scales are never dropped and always produce the final selected visual state on the desktop.
- **Strict 2-Version Retention**: Promoted release to `v038`; purged obsolete `v036` releases across local repositories and MEGA cloud storage, retaining strictly `v037` and `v038`.

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

## [v037] — 2026-11-20
### 🎯 Universal Font Application, Dock Menu Flicker Elimination & Full Localization
- **Universal Settings Font Styling**: Clicking any of the 12 font buttons on Tab 1 (Главные) instantly re-styles all controls, labels, checkboxes, buttons, and tab headers across the entire settings dialog in real time.
- **Dock Folder Hover Flicker Fix**: Eliminated the rapid blinking/closing of folder menus when hovering. Set `AutoClose = false` on the dropdown, removed conflicting tooltip windows on folder buttons, and implemented smart hierarchical bounds detection so menus stay open solidly until moving to another folder or leaving the dock.
- **Wallpaper Categories Localization**: Fixed category checkbox labels (`3D`, `Flowers`, `Ocean`, `Space`, `Nature`, `Animals`, `Cars`, `Trucks`, `Girls`, `City`, `Cyberpunk`, `Minimalism`, `Anime`) to update instantly in real time when toggling between Russian, English, and Czech.
- **About Tab Full Localization**: Added translated descriptions and button labels for the About tab in Russian, English, and Czech.
- **Version Lifecycle & Retention**: Promoted release to `v037`; purged `v035` across repository mirrors and MEGA storage; strictly retained the 2 latest versions (`v036` and `v037`).

## [v036] — 2026-11-20
### 🎨 Typography Fixes, Dynamic Theme Mapping, Centralized Font Engine & Hover Dock
- **Font Rendering & Kerning Fix**: Resolved severe letter-spacing distortions and font crawl caused by OpenType variable fonts (`Bahnschrift`). Replaced with rock-solid TrueType/OpenType `Tahoma` and pinned dialog controls cleanly to `Segoe UI` (9pt / 9.5pt) matching the crisp aesthetic of GIN-VPN.
- **Active Theme Engine**: Fixed `ThemeManager.GetTheme` to perform exact and prefix case-insensitive lookup against selected theme IDs (`Nordic Frost`, `Cyberpunk`, `Warm Sand`, `Midnight OLED`, etc.), ensuring full real-time window restyling on click and upon `Apply`.
- **Centralized Font Selector on Tab 1 (Главные)**: Moved the 12 curated font preview buttons to the main settings tab for unified typography control, completely decluttering Tab 2 (Wallpaper & Calendar).
- **Instant Real-Time Dock Resizing**: Clicking icon size buttons (`16 px`, `24 px`, `32 px`, `48 px`, `64 px`) now immediately flushes icon caches (`ShellHelper.ClearCache()`), triggers real-time dock bar recreation, and dynamically adjusts dock bar thickness on the desktop.
- **Fluid Mouse Hover Folder Opening**: Folders on the dock bar now open automatically and effortlessly as the cursor glides over them, eliminating the need to left-click.
- **Localized Dock Placement Buttons**: Corrected Russian button text to clean standard `⬆ Вверху` and `⬅ Слева` (replacing untranslated identifiers).
- **Deployment & Version Integrity**: Retained strictly the 2 latest versions (`v035` and `v036`); purged `v034` across repository mirrors and MEGA storage.

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

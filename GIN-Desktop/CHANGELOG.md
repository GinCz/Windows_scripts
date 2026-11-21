# 📋 CHANGELOG — GIN-Desktop

## [v050] — 2026-11-21
### 🛠️ Critical Windows .NET Framework Installer Launch & Compatibility Fix
- **Fixed Silent Launch Failure on Windows 10/11**:
  - Diagnosed and resolved the root cause of `GIN-Desktop_vXXX_Setup.exe` failing to launch or install silently on clean Windows workstations (`KK-02`, laptops):
  - In Mono's C# compiler (`mcs`), calling `arg.Substring(8).Trim('\"')` and `BaseDirectory.TrimEnd('\\')` with single character arguments generated IL `callvirt instance string [mscorlib]System.String::Trim(char)` and `TrimEnd(char)`.
  - While single `char` overloads exist in .NET Core / .NET Standard 2.1 / Mono, Windows .NET Framework 4.0/4.5/4.8 only supports `Trim(params char[])` and `TrimEnd(params char[])`. On Windows, the CLR threw `System.MissingMethodException: Method not found: 'System.String System.String.Trim(Char)'` during JIT compilation of `Program.Main`, silently aborting execution before any window could open.
  - Replaced all calls with explicit character array overloads: `Trim(new char[] { '\"', ' ' })` and `TrimEnd(new char[] { '\\', '/' })`.
  - Verified with `ikdasm` that the generated binary strictly targets `System.String::Trim(char[])`.
  - Verified live turnkey execution on Windows workstation (`VladiMIR-E14`), confirming clean installation and process startup.
- **Assembly Manifest Purification**:
  - Removed obsolete `[assembly: AssemblyCulture("")]` attribute from executables, conforming strictly to ECMA-335 / .NET standards.
- **Single Versioned Setup on MEGA Desktop**:
  - Build pipeline strictly delivers `GIN-Desktop_v050_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file.

## [v049] — 2026-11-21
### 📂 Single Clean Start Menu Shortcut & Direct Program Folder Quick Access
- **Single Clean Shortcut in Windows Start Menu**:
  - The installer now creates strictly ONE direct shortcut (`GIN Desktop.lnk`) in the root of `%AppData%\Microsoft\Windows\Start Menu\Programs\`.
  - Eliminated the separate `Programs\GIN Desktop\` subfolder and removed the redundant `Uninstall GIN Desktop.lnk` from the Start Menu.
  - Automatically cleans up any legacy Start Menu directories (`GIN Desktop` and `GIN Dock Wallpaper`) during install and update.
- **Direct Program Folder Access in Tray & Dock Menus**:
  - Added `📁 Открыть папку программы` / `📁 Otevřít složku programu` / `📁 Open Program Folder` directly to the system tray context menu and the Dock brand button menu.
  - One-click opens the installation directory in Windows Explorer where `Uninstall.exe` and program binaries reside.
- **Uninstaller Cleanup Overhaul**:
  - `Uninstall.exe` now completely purges the single shortcut in `Programs` root as well as any legacy directories.
- **Single Versioned Setup on MEGA Desktop**: Build pipeline strictly delivers `GIN-Desktop_v049_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file.

## [v048] — 2026-11-21
### 🔔 GIN-Wallpaper Celestial Shimmer Sound Restoration & Explicit Localized Sound Button
- **Restoration of GIN-Wallpaper Celestial Shimmer Chime**:
  - Re-implemented the signature peaceful velvet bells chime from the original `GIN-Wallpaper` (F#4 369.99 Hz, A#4 466.16 Hz, C#5 554.37 Hz, F5 698.46 Hz harmonic progression with 40ms attack and warm exponential decay).
  - The chime automatically plays upon every wallpaper transition (manual change, interval timer, midnight refresh) whenever sound is enabled.
  - Startup behavior: keeps the initial launch silent (`_suppressFirstChime = true`), activating audible feedback on subsequent wallpaper swaps.
- **Explicit Localized Sound Toggle Button**:
  - Replaced the ambiguous single-glyph `♪` button in the top header with a full-width state button displaying clear localized status:
    - Russian: `🔊 Со звуком` (ON) / `🔇 Без звука` (OFF)
    - Czech: `🔊 Se zvukem` (ON) / `🔇 Bez zvuku` (OFF)
    - English: `🔊 Sound ON` (ON) / `🔇 Sound OFF` (OFF)
  - Seamlessly styled with active theme accent border/highlight when enabled and muted gray when disabled.
  - Toggling sound to ON immediately triggers the celestial shimmer chime for instant audible confirmation.
- **Non-Disposal Asynchronous Audio Engine**:
  - Fixed Windows `.NET SoundPlayer` buffer truncation bug where disposing the `MemoryStream` immediately after calling asynchronous `sp.Play()` caused silence or audio driver aborts.
  - Audio playback now utilizes `sp.PlaySync()` within dedicated background `ThreadPool` tasks, ensuring 100% full playback without premature disposal and zero UI latency.
  - Replaced Windows system sound calls in `PlayClickSound()` with the clean in-memory sine wave `GentleSound.PlayNotice()` (350 Hz, 110 ms), guaranteeing audible feedback even on systems with disabled Windows system schemes.
- **Single Versioned Setup on MEGA Desktop**: Build pipeline strictly delivers `GIN-Desktop_v048_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file.

## [v047] — 2026-11-21
### ⚡ Hardware Monitor Relocation to Wallpaper HUD, Top-Left Dock Activation Fix & Settings Layout Polish
- **Hardware Monitor Under Weather Badge**:
  - Moved hardware monitoring metrics (CPU %, RAM %, GPU %, GPU Temp °C) from the Dock Bar directly onto the desktop wallpaper.
  - Positioned as a sleek rounded dark translucent pill directly below the Weather badge matching the existing Calendar HUD visual aesthetic.
  - Added fast in-memory `RefreshActiveWallpaperHUD()` to re-render the HUD on top of the active wallpaper in ~50ms upon toggling settings without downloading a new image.
  - Integrated a 30-second background watchdog timer to update live hardware metrics seamlessly.
- **Top-Left Dock Bar Hot-Corner Activation Overhaul**:
  - Fixed issue where the Dock Bar failed to appear when moving the mouse to the top-left corner after selecting a folder and enabling dock.
  - Redesigned hot-corner trigger zone: expanded threshold from rigid 15×15px to a generous, high-DPI friendly zone (`Math.Max(80, HotCornerWidth * 4)` and `Math.Max(40, HotCornerHeight * 2)` or `cursor.Y <= bounds.Top + 3 && cursor.X <= bounds.Left + 200`).
  - Added relative coordinate offsets (`screen.Bounds.Left`, `screen.Bounds.Top`) to support multi-monitor setups correctly.
  - Permanent watchdog timer startup ensures that toggling Dock ON in Settings immediately activates monitoring without requiring app restart.
  - Enforced Topmost Z-order via `NativeMethods.SetWindowPos` to prevent dock hiding behind other windows.
- **Settings Form UI & Spacing Calibration**:
  - Relocated Hardware Monitoring checkboxes from Tab 3 ("Панель Докер") to Tab 2 ("Обои и Календарь") directly under the Weather controls.
  - Fixed vertical label overlap on Tab 3: repositioned icon size label below the hide delay slider with proper breathing room, completely eliminating text clipping.
- **Single Versioned Setup on MEGA Desktop**: Build pipeline strictly delivers `GIN-Desktop_v047_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file.

## [v046] — 2026-11-21
### 📍 City Name in Weather HUD, Localized Geocoding & Dedicated City Settings Field
- **Explicit Localized City Name in Weather Badge**: The weather pill rendered directly under the Calendar HUD on the desktop wallpaper now explicitly includes the city name, fully localized according to the current UI language (e.g. `Прага: ☀ +18°C · Ясно` in Russian, `Praha: ☀ +18°C · Jasno` in Czech, and `Prague: ☀ +18°C · Clear` in English).
- **Intelligent Multilingual Geocoding**:
  - Open-Meteo queries geocoding with the active language code (`language=ru/cs/en`), extracting and displaying the city's native localized name.
  - wttr.in format is enhanced with `%l:` and sanitized to remove redundant administrative regional suffixes after commas, keeping clean readability.
  - Dynamic fallback gracefully handles offline states with localized city defaults (`Прага` / `Praha` / `Prague`).
- **Dedicated City Label in Settings Form**: Positioned an explicit `📍 Город:` / `📍 Město:` / `📍 City:` label before the city input box on the Wallpaper tab, providing clear ergonomics and visual affordance.
- **Single Versioned Setup on MEGA Desktop**: Build pipeline strictly delivers `GIN-Desktop_v046_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file and purging obsolete installers.

## [v045] — 2026-11-21
### 🔔 Silent Tray HUD Auto-Updater, Pure-Sine Gentle Sounds, Dynamic Version Transition & Clean Desktop Integrity
- **Silent Non-Activating Tray HUD**: Eliminated intrusive modal MessageBox dialogs for update checks. Implemented `TrayNotificationHUD` positioned right above the system tray in the bottom-right corner, featuring smooth fade-in/fade-out, gold accent border, and non-activating window style (`WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST`).
- **Pure-Sine Gentle Sound Generator (GIN-Voice Audio Signature)**: Embedded in-memory mathematical WAV tone generator (`GentleSound` 44.1kHz 16-bit mono PCM with half-sine envelope):
  - 350 Hz (110ms, volume 0.14) soft notice blip on update check or download start.
  - 620 Hz (90ms, volume 0.15) gentle confirmation chime upon up-to-date confirmation and successful post-update launch.
- **3-Second Auto-Dismiss Up-to-Date Notice**: When running the latest version, the HUD automatically notifies the user and disappears smoothly after 3 seconds with zero required clicks.
- **Dynamic Transition & Background Updater**:
  - When an update is detected, the HUD shows the exact transition badge (`44 ➔ 45`) and initiates automatic background download.
  - Halts services (`sc stop GIN-Desktop`) and stops active processes.
  - Executes update in `/update` mode, writes updated binaries, and restarts with `--updated`.
  - Upon restart, displays completion banner (`✅ Все готово! У вас установлена последняя версия.`) accompanied by the gentle confirmation sound.
- **Desktop Shortcut Preservation (Zero Clutter)**: The `/update` workflow strictly skips recreating desktop shortcuts, keeping the user's desktop layout 100% clean and intact.
- **Single Versioned Setup on MEGA Desktop**: Build pipeline strictly delivers `GIN-Desktop_v045_Setup.exe` to Vladimir's Desktop in MEGA (`/MEGA/DOCS/desktop/`), retaining strictly one versioned setup file and purging obsolete installers.

## [v044] — 2026-11-21
### 🎨 Spacious Breathable UI, Clean Font Buttons, Single-Row Intervals, Zero-Tofu Weather & Multilingual HUD Sync
- **Spacious Breathable Settings UI & Height Calibration**: Increased form height to 780px and tabs container to 680px, completely eliminating vertical crampedness.
- **Font Preview Buttons Ergonomics**: Expanded button height to 29px with 33px row spacing (4px gap), centered text alignment, and calibrated font sizes (8.0pt for Gabriola, 8.5pt for Impact/Sitka/Palatino, 9.0pt standard) to eliminate vertical clipping of font names.
- **Streamlined Single-Row Wallpaper Interval**: Replaced verbose description with concise `⏱️ Интервал:` / `⏱️ Interval:` and aligned 5 duration buttons (`1 час`, `3 часа`, `6 часов`, `12 часов`, `24 часа`) symmetrically with the Calendar scale buttons below.
- **Sleek Horizontal Section Dividers**: Added 5 thin 1px horizontal separator lines styled with `theme.Separator` between categories, interval, calendar, font preview, action buttons, and weather sections.
- **Generous Weather HUD Bottom Margins**: Repositioned weather controls with ample breathing room (16px bottom margin) so controls no longer touch the tab boundary.
- **Clean Unicode Weather Icons (Zero Tofu Boxes)**: Stripped Unicode Variation Selectors (`\uFE0F`, `\uFE0E`, `\u200D`, `\uFFFD`) and switched to standard Unicode weather glyphs (`☀`, `⛅`, `☁`, `🌧`, `❄`, `🌦`, `⚡`) rendered via crisp `Segoe UI Bold` font on desktop wallpaper.
- **Dynamic Multilingual Weather & Calendar Synchronization**:
  - Live language switching (EN / RU / CS) instantly invalidates cached weather and triggers immediate desktop wallpaper regeneration in the chosen language.
  - Passes localized language parameter (`&lang=ru/cs/en`) to wttr.in and queries localized Open-Meteo descriptions.
  - Dynamically localizes Calendar month (`MMMM yyyy`) and weekday headers (`Пн..Вс` / `Po..Ne` / `Mo..Su`) according to active language culture (`ru-RU`, `cs-CZ`, `en-US`).

## [v043] — 2026-11-20
### 🌟 Rebranding to GIN Desktop, Live Hardware Monitor, Weather HUD, Midnight Sync & Top Dock
- **Canonical Rebranding to GIN-Desktop**: Unified repository, binary targets, and installer under the official name `GIN-Desktop`.
- **Top-Only Dock Placement**: Removed side placements; dock bar is permanently anchored to the top of the screen, activating cleanly when cursor hovers in the top-left corner.
- **Configurable Shortcuts Path with Browse Dialog**: Set default path to `D:\UTIL\GIN-Desktop\` with an interactive `[Browse...]` button and clipboard copy/paste support.
- **Live Hardware Monitor on Dock Bar**: Checkboxes for CPU %, RAM %, GPU %, and GPU Temperature (°C) with zero-allocation WinAPI metric sampling (`GetSystemTimes`, `GlobalMemoryStatusEx`).
- **Real-Time Weather HUD under Calendar**: Optional weather badge under Calendar HUD supporting Open-Meteo and wttr.in sources with auto-geolocation.
- **Midnight Auto-Refresh at 00:03**: Independent timer guarantees automatic wallpaper refresh and calendar day progression at 00:03 daily.
- **Intelligent Cache Rotation**: Enforced 7-day age cutoff and 100 MB disk quota with automatic trimming to 80 MB.
- **Portable-First Storage**: Configuration is saved directly in application folder (`config.json`) with zero registry clutter.
- **SHA-256 Integrity Verification**: Auto-updater checks SHA-256 hash before executing downloaded setup packages.
- **Synchronized Uninstaller**: Both installer and uninstaller now inspect and sanitize both HKLM and HKCU registry keys, and offer optional cache/config cleanup.

## [v042] — 2026-11-20
### 🚀 Fixed Wallpaper Generation, Instant Startup Sync & Dual Alternating Buffer
- **Instant Wallpaper & Calendar Sync on Launch**: Fixed issue where the wallpaper engine waited for the full timer interval before running; `TriggerNextWallpaperAsync()` now executes automatically 800ms after startup so the desktop updates immediately.
- **Modern TLS 1.2 / TLS 1.3 Security Protocol**: Configured `ServicePointManager.SecurityProtocol` for compatibility with Cloudflare-protected APIs (Wallhaven.cc, Unsplash, Picsum), eliminating silent TLS handshake failures on Windows 10/11.
- **Multi-Tier Resilient 4K Downloader with Timeout**:
  - Replaced blocking `WebClient` with custom `TimeoutWebClient` (8–10s timeout).
  - Implemented 6-tier download pipeline: Wallhaven Random Search (collecting full page candidates) ➔ Lorem Picsum UHD CDN ➔ Curated Unsplash 4K pool ➔ Local Cache ➔ Existing Windows wallpaper ➔ Native Dark Gradient fallback.
- **Screen-Calibrated Wallpaper & HUD Rendering**: Source wallpapers are now dynamically scaled and center-cropped to the primary monitor resolution in memory before overlaying the Calendar HUD, preventing clipping or distortion caused by Windows Fill scaling.
- **Dual Alternating Desktop Slots (`active_desktop_hud_A.jpg` / `B.jpg`)**: Switched to alternating slots to completely eliminate GDI+ file-locking exceptions and force Windows Desktop to instantly recognize path changes and repaint.
- **Automated Cache Purge**: Added background cleanup routines keeping only active and recent temporary files, preventing unbounded cache growth.
- **Legacy GIN-Wallpaper Cleaner**: Installer now halts leftover `GIN-Wallpaper` / `GIN-Wallpaper-Calend` processes, removes stale autostart registry entries, and cleans up legacy desktop shortcuts.
- **Rebuilt Native Standalone Installer**: Updated compilation pipeline to inject the freshly built executable payload into `GIN-Dock-Wallpaper_v042_Setup.exe` (700KB).

## [v041] — 2026-11-20
### 🚫 Complete Elimination of Scrollbars & Clean Geometry Fit
- **Eliminated Tab Scrollbars**: Disabled `AutoScroll` across all tabs (`_tabWall`, `_tabDock`, `_tabMain`, `_tabAbout`), ensuring that no ugly vertical scrollbars ever appear on the right side of the settings dialog.
- **Harmonized Tab 2 Vertical Rhythm**:
  - Tightened category row step from 19px to 18px (`yPos = 42 + row * 18`), saving 10px.
  - Aligned interval title and buttons to `Y = 226..271px`.
  - Aligned calendar title and 5 buttons to `Y = 276..301px`.
  - Aligned font selector title to `Y = 307px` and 24 font preview buttons to `Y = 326..474px` (step 25px, height 23px).
  - Placed `Следующие обои сейчас` and `Сохранить текущие обои в Изображения` at `Y = 480px` (ending at 508px, leaving a comfortable 22px margin above the tab bottom).
- **Extended Button Width**: Expanded `Сохранить текущие обои в Изображения` to 350px width (`Location = (355, 480)`), preventing text truncation.
- **Pure Standalone Distribution**: Built 666KB standalone installer `GIN-Dock-Wallpaper_v041_Setup.exe`.

## [v040] — 2026-11-20
### 📐 Settings Form Height Calibration, Compact Layout & Footer Restoration
- **Settings Form Height Recalibration**: Fixed critical vertical cutoff where the bottom footer bar (`_bottomBar`) containing `Применить`, `Сохранить и закрыть`, `Отмена` and `VladiMIR+AI ||| v040` was pushed past the window boundary.
- **Harmonized 656px Client Window Height**: Recalibrated form geometry with exact `ClientSize = new Size(760, 656)` (outer window ~694px), ensuring full visibility on any standard 1080p, 1080p@125% DPI, and 1366x768 screens.
- **Tab 2 (Wallpaper & Calendar) Compact Spacing**:
  - Tightened category row rhythm to 19px while preserving the 2 wide 330px columns.
  - Aligned interval, calendar scale, and font selection grid to eliminate wasted vertical gaps.
  - Positioned `Следующие обои` and `Сохранить картинку` neatly within view above the bottom footer.
- **Tab 3 (Docker) Vertical Realignment**: Tightened placement, path, sorting, icon sizes, and brand icon selector within 412px, eliminating large empty gaps and restoring immediate visibility of action buttons.
- **AutoScroll Safety on All Tabs**: Enabled native `AutoScroll = true` on `_tabWall`, `_tabDock`, `_tabMain`, and `_tabAbout` to guarantee that no control is ever clipped or unreachable regardless of Windows system DPI scaling (125%, 150%, 175%).
- **Full 20-Category Localization Fix**: Updated `ApplyLocalization()` so that all 20 wallpaper categories (including Dark Horse, Macro, Architecture, Aircraft, Retrowave, Fantasy, Underwater) properly switch across English, Russian, and Czech.
- **Pure Standalone Distribution**: Built 666KB standalone installer `GIN-Dock-Wallpaper_v040_Setup.exe`.
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

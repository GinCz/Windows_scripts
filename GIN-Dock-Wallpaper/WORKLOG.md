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

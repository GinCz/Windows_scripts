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

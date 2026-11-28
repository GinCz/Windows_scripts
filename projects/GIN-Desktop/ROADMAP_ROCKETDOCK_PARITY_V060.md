# рџљЂ GIN-Desktop v060: RocketDock Visual Parity & Folder Stacks Architecture Plan

> **Target Release:** `GIN-Desktop v060`  
> **Repository:** [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> **Component:** `src/GIN-Desktop.cs` (`DockBarForm` Engine)  
> **Author:** Vladimir Bulantsev (@GinCz) & AI Assistant  
> **Status:** Approved for Implementation  

---

## рџ“Њ Executive Summary

Current `GIN-Desktop` (`v051`) features an auto-hiding Hot-Corner Dock Bar implemented with standard Windows Forms controls (`Button`, `Panel`, `ToolStripDropDown`). While functional, it lacks the fluid visual aesthetics, smooth magnification physics, and skinning capabilities of dedicated dock launchers like **RocketDock**.

Meanwhile, **RocketDock** (a legacy 32-bit utility last updated in 2008) suffers from modern Windows 10/11 compatibility flaws, high DWM overhead, and lacks the single most vital organizational feature: **cascading dropdown menus for folders directly on the dock**.

**Goal of v060:** Replace legacy RocketDock entirely by rebuilding `GIN-Desktop`'s dock module into a native 64-bit, zero-lag, hardware-accelerated dock with **complete visual parity to RocketDock** (parabolic zoom wave, glass shelf reflections, customizable skins) combined with **interactive cascading dropdown folder menus**.

---

## рџЋЁ 1. Visual & Physics Engine (RocketDock Parity)

### 1.1. Smooth Parabolic Magnification Wave (Zoom Physics)
* **Idle State:** Icons render at base size (e.g. 36Г—36 px or 42Г—42 px).
* **Hover State:** The hovered icon expands smoothly to `ZoomSize` (e.g. 72Г—72 px or 84Г—84 px).
* **Parabolic Bell Curve:** Neighboring icons scale proportionally based on Gaussian/Cosine distance:
  $$\text{Scale}(d) = 1.0 + (\text{MaxScale} - 1.0) \cdot \cos^2\left(\frac{\pi \cdot d}{2 \cdot R}\right) \quad \text{for } |d| < R$$
  where $d$ is the horizontal pixel distance from the cursor to the icon center, and $R$ is the influence radius (e.g. 140вЂ“180 px).
* **Animation Timing:** 60 FPS interpolation loop using high-resolution `System.Diagnostics.Stopwatch`. The loop runs **strictly while the mouse moves within the dock boundary**; when idle, CPU usage drops to **0.0%**.

### 1.2. Dynamic Glass Shelf Reflections
* **Mirror Rendering:** Each icon renders an inverted mirror copy below the shelf baseline.
* **Alpha Gradient:** Linear opacity fade from 35% at the baseline down to 0% at the reflection bottom.
* **Synchronized Scaling:** Reflections expand and contract synchronously with the magnification wave.

### 1.3. Layered Window Rendering (`UpdateLayeredWindow`)
* **Elimination of WinForms Control Hierarchy:** Deprecate individual `Button` and `Panel` child controls inside `DockBarForm`.
* **Single Surface:** The dock window is configured with Win32 extended styles:
  `WS_EX_LAYERED (0x00080000)` | `WS_EX_NOACTIVATE (0x08000000)` | `WS_EX_TOPMOST (0x00000008)`.
* **GDI+ 32-bit ARGB Backbuffer:** The entire dock (background skin, icons, reflections, labels) renders into a single 32-bit ARGB `Bitmap` with `PixelFormat.Format32bppPArgb` (Premultiplied Alpha) and is committed via `UpdateLayeredWindow`.
* **Zero Flickering & Zero DWM lag:** Eliminates GDI repaint queuing and prevents DWM compositor stalls.

### 1.4. Floating Labels
* Semi-transparent dark pill label with rounded corners rendered above or below the active icon with a soft drop shadow and ClearType font rendering (`Segoe UI Semibold`).

---

## рџ“‚ 2. Killer Feature: Interactive Folder Dropdown Stacks

RocketDock only opens folders in Windows Explorer. `GIN-Desktop v060` introduces **Folder Dropdown Menus (Stacks)** directly on the dock:

1. **Folder Icon Detection:**
   * Items pointing to directories (or `.lnk` shortcuts resolving to directories) are styled as interactive folders.
2. **Cascading Dropdown Menu:**
   * Clicking a folder icon smoothly deploys a vertical dropdown stack menu downward (or upward depending on dock alignment).
   * Displays all files and subdirectories with high-resolution system icons (`SHGetFileInfo` / `ExtractIconEx`).
   * Clicking any file executes it immediately and collapses the menu.
   * Hovering over a subdirectory cascades a flyout sub-menu to the right.
3. **Quick Action Header:**
   * Top entry in the dropdown: `рџ“‚ Open in File Explorer...` for full window access.
4. **Drag & Drop Reordering:**
   * Dragging any folder from Explorer onto the dock automatically registers it as a new interactive dropdown stack.

---

## рџ›  3. Configuration Schema Updates (`config.json`)

```json
{
  "EnableDock": true,
  "DockPosition": "Top",
  "DockBaseIconSize": 40,
  "DockZoomIconSize": 80,
  "DockZoomRange": 160,
  "DockShowReflection": true,
  "DockReflectionHeight": 0.40,
  "DockReflectionOpacity": 30,
  "DockShelfTheme": "MacGlass",
  "DockAutoHide": true,
  "DockAutoHideDelayMs": 400,
  "FolderDropdownClickMode": "Click",
  "FolderMenuMaxItems": 30,
  "FolderMenuFontFamily": "Segoe UI",
  "FolderMenuFontSize": 10
}
```

---

## рџ“… 4. Implementation Phasing & Task Checklist

- [ ] **Phase 1: Win32 Layered Window Skeleton**
  - Implement `UpdateLayeredWindow` wrapper with memory DC and `BLENDFUNCTION`.
  - Create Per-Monitor V2 DPI awareness hooks.
- [ ] **Phase 2: Parabolic Zoom Math & Icon Layout**
  - Implement mouse tracking coordinate mapping and bell-curve scaling formula.
  - Render pre-cached icons with bicubic interpolation.
- [ ] **Phase 3: Shelf Reflections & Theming**
  - Add vertical flip + alpha-gradient mask generator for icon reflections.
  - Implement 3-slice PNG background shelf rendering.
- [ ] **Phase 4: Folder Dropdown Menus Integration**
  - Modernize `ToolStripDropDown` / custom popup layered window for dark glass appearance.
  - Implement recursive directory scanning with icon caching.
- [ ] **Phase 5: Release Packaging & Verification**
  - Increment build to `v060`.
  - Compile standalone `.exe` and installer (`GIN-Desktop_v060_Setup.exe`).
  - Update `CHANGELOG.md` and `WORKLOG.md`.


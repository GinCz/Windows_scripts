#!/usr/bin/env python3
import os
import sys
import base64
import re
import hashlib
import json
import shutil
import subprocess

SCRIPT_DIR = r"D:\AI\GitHub\Windows_scripts\projects\GIN-Desktop\src"
ROOT_DIR = r"D:\AI\GitHub\Windows_scripts\projects\GIN-Desktop"
VERSION = "v052"
CSC_PATH = r"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

APP_EXE = os.path.join(SCRIPT_DIR, "GIN-Desktop.exe")
UNINST_EXE = os.path.join(SCRIPT_DIR, "Uninstall.exe")
ICO_FILE = os.path.join(SCRIPT_DIR, "app.ico")
SETUP_EXE = os.path.join(ROOT_DIR, f"GIN-Desktop_{VERSION}_Setup.exe")
INSTALLER_SRC = os.path.join(SCRIPT_DIR, "installer_setup.cs")
APP_SRC = os.path.join(SCRIPT_DIR, "GIN-Desktop.cs")
UNINST_SRC = os.path.join(SCRIPT_DIR, "Uninstall.cs")
VERSION_JSON = os.path.join(ROOT_DIR, "version.json")

print(f"=== Building GIN-Desktop {VERSION} ===")

# Step 1: Bump version in installer_setup.cs and Uninstall.cs
print("==> Bumping version strings in installer_setup.cs and Uninstall.cs...")
with open(INSTALLER_SRC, "r", encoding="utf-8") as f:
    inst_txt = f.read()

inst_txt = inst_txt.replace('AssemblyTitle("GIN-Desktop_v051")', 'AssemblyTitle("GIN-Desktop_v052")')
inst_txt = inst_txt.replace('AssemblyDescription("GIN-Desktop_v051 Setup")', 'AssemblyDescription("GIN-Desktop_v052 Setup")')
inst_txt = inst_txt.replace('AssemblyProduct("GIN-Desktop_v051")', 'AssemblyProduct("GIN-Desktop_v052")')
inst_txt = inst_txt.replace('AssemblyVersion("0.51.0.0")', 'AssemblyVersion("0.52.0.0")')
inst_txt = inst_txt.replace('AssemblyFileVersion("0.51.0.0")', 'AssemblyFileVersion("0.52.0.0")')
inst_txt = inst_txt.replace('"GIN Desktop v051"', '"GIN Desktop v052"')
inst_txt = inst_txt.replace('"DisplayVersion", "v051"', '"DisplayVersion", "v052"')
inst_txt = inst_txt.replace('GIN Desktop v051 has been successfully installed!', 'GIN Desktop v052 has been successfully installed!')

with open(INSTALLER_SRC, "w", encoding="utf-8") as f:
    f.write(inst_txt)

with open(UNINST_SRC, "r", encoding="utf-8") as f:
    uninst_txt = f.read()

uninst_txt = uninst_txt.replace('AssemblyTitle("GIN-Desktop_v051")', 'AssemblyTitle("GIN-Desktop_v052")')
uninst_txt = uninst_txt.replace('AssemblyDescription("GIN-Desktop_v051")', 'AssemblyDescription("GIN-Desktop_v052")')
uninst_txt = uninst_txt.replace('AssemblyProduct("GIN-Desktop_v051")', 'AssemblyProduct("GIN-Desktop_v052")')
uninst_txt = uninst_txt.replace('AssemblyVersion("0.51.0.0")', 'AssemblyVersion("0.52.0.0")')
uninst_txt = uninst_txt.replace('AssemblyFileVersion("0.51.0.0")', 'AssemblyFileVersion("0.52.0.0")')

with open(UNINST_SRC, "w", encoding="utf-8") as f:
    f.write(uninst_txt)

print("    Version strings updated to v052.")

# Step 2: Compile Uninstall.exe
print(f"==> [1/4] Compiling Uninstall.exe...")
cmd1 = [
    CSC_PATH, "/nologo", "/target:winexe", "/optimize+", "/platform:anycpu",
    f"/win32icon:{ICO_FILE}",
    "/r:System.dll,System.Windows.Forms.dll",
    f"/out:{UNINST_EXE}",
    UNINST_SRC
]
res1 = subprocess.run(cmd1, capture_output=True, text=False)
if res1.returncode != 0:
    print("Error compiling Uninstall.cs:\n", res1.stderr.decode('cp866', errors='replace'))
    sys.exit(1)
print(f"    Compiled Uninstall.exe ({os.path.getsize(UNINST_EXE)} bytes)")

# Step 3: Compile GIN-Desktop.exe
print(f"==> [2/4] Compiling GIN-Desktop.exe...")
cmd2 = [
    CSC_PATH, "/nologo", "/target:winexe", "/optimize+", "/platform:anycpu",
    f"/win32icon:{ICO_FILE}",
    "/r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll,Microsoft.CSharp.dll",
    f"/out:{APP_EXE}",
    APP_SRC
]
res2 = subprocess.run(cmd2, capture_output=True, text=False)
if res2.returncode != 0:
    print("Error compiling GIN-Desktop.cs:\n", res2.stderr.decode('cp866', errors='replace'))
    sys.exit(1)
print(f"    Compiled GIN-Desktop.exe ({os.path.getsize(APP_EXE)} bytes)")

# Step 4: Inject Base64
print(f"==> [3/4] Injecting base64 payload into installer_setup.cs...")
with open(APP_EXE, "rb") as f:
    app_b64 = base64.b64encode(f.read()).decode("ascii")
with open(UNINST_EXE, "rb") as f:
    uninst_b64 = base64.b64encode(f.read()).decode("ascii")
with open(ICO_FILE, "rb") as f:
    ico_b64 = base64.b64encode(f.read()).decode("ascii")

with open(INSTALLER_SRC, "r", encoding="utf-8") as f:
    inst_code = f.read()

inst_code = re.sub(
    r'private static readonly string AppExeB64 = "[^"]+";',
    f'private static readonly string AppExeB64 = "{app_b64}";',
    inst_code
)
inst_code = re.sub(
    r'private static readonly string UninstExeB64 = "[^"]+";',
    f'private static readonly string UninstExeB64 = "{uninst_b64}";',
    inst_code
)
inst_code = re.sub(
    r'private static readonly string IcoB64 = "[^"]+";',
    f'private static readonly string IcoB64 = "{ico_b64}";',
    inst_code
)

with open(INSTALLER_SRC, "w", encoding="utf-8") as f:
    f.write(inst_code)
print(f"    Injected base64 payload into {INSTALLER_SRC}")

# Step 5: Compile GIN-Desktop_v052_Setup.exe
print(f"==> [4/4] Compiling {SETUP_EXE}...")
cmd3 = [
    CSC_PATH, "/nologo", "/target:winexe", "/optimize+", "/platform:anycpu",
    f"/win32icon:{ICO_FILE}",
    "/r:System.dll,System.Windows.Forms.dll,Microsoft.CSharp.dll,System.Core.dll",
    f"/out:{SETUP_EXE}",
    INSTALLER_SRC
]
res3 = subprocess.run(cmd3, capture_output=True, text=False)
if res3.returncode != 0:
    print("Error compiling installer_setup.cs:\n", res3.stderr.decode('cp866', errors='replace'))
    sys.exit(1)

setup_size = os.path.getsize(SETUP_EXE)
with open(SETUP_EXE, "rb") as f:
    setup_sha256 = hashlib.sha256(f.read()).hexdigest()

print(f"==> Setup compiled successfully: {SETUP_EXE} ({setup_size} bytes)")
print(f"    SHA-256: {setup_sha256}")

# Update version.json
v_data = {
    "version": VERSION,
    "name": "GIN-Desktop",
    "installer": f"GIN-Desktop_{VERSION}_Setup.exe",
    "description": "Unified Windows Desktop Companion: RocketDock Parity Top Dock Bar with Downward Folder Menus, 4K Wallpaper Engine, Calendar HUD, Hardware Monitor & Real-Time Weather",
    "author": "GinCz / Vladimir Bulantsev & Antigravity",
    "github": "https://github.com/GinCz/Windows_scripts/tree/main/GIN-Desktop",
    "date": "2026-11-28",
    "sha256": setup_sha256,
    "download_url": f"https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Desktop/GIN-Desktop_{VERSION}_Setup.exe",
    "features": [
        "RocketDock Visual Parity: Centered top dock bar with sleek semi-transparent dark glass shelf (ARGB 220, 18, 20, 26), 20px rounded capsule corners (CreateRoundRectRgn Win32 API), and subtle top highlight line",
        "Floating Transparent Dock Icons: Pure borderless floating app and folder icons with smooth hover zoom effects and instant tooltip labels",
        "Interactive Downward Folder Dropdown Menus: Clicking or hovering folder shortcuts expands a sleek downward dark stack menu (ModernDarkMenuRenderer) displaying folder items directly on screen",
        "Top-Only Fluid Hot-Corner Dock Bar: Dedicated top position activated strictly on hover at top-left hot corner with zero visual clutter",
        "Full Multi-Language Dynamic Localization: Dynamic translation switching across all UI controls including Weather HUD ('Weather:', 'Enable Weather', 'City:'), Hardware Monitor, and Form title bar",
        "Localized City Name in Weather HUD: Weather badge under the Calendar HUD displays live localized city name (e.g. Прага: ☀ +18°C · Ясно / Praha / Prague)",
        "Silent Tray HUD Auto-Updater: Zero-popup quiet update workflow with subtle non-activating HUD toast near system tray and gentle pure-sine audio blips",
        "Seamless Transition Pipeline: Live version transition in tray HUD with automatic background download, process termination, service halt, and instant restart",
        "Configurable Shortcuts Path: Defaulted to D:\\UTIL\\GIN-Desktop\\ with interactive Browse button and clipboard path entry",
        "Live Hardware Monitor HUD: Optional CPU %, RAM %, GPU %, and GPU Temperature monitoring directly on Dock Bar",
        "Real-Time Weather HUD: Embedded weather badge under Calendar HUD supporting Open-Meteo and wttr.in with auto-geolocation",
        "Midnight Calendar & Wallpaper Refresh: Automatic wallpaper swap and calendar day advancement at 00:03 daily",
        "Intelligent Cache Rotation: Automatic 7-day age cutoff and 100 MB max disk quota management",
        "Portable-First Architecture: Settings saved strictly in application folder with zero registry clutter",
        "SHA-256 Checksum Verification: Cryptographic integrity validation on automatic updates"
    ]
}

with open(VERSION_JSON, "w", encoding="utf-8") as f:
    json.dump(v_data, f, indent=2, ensure_ascii=False)
print(f"==> Updated {VERSION_JSON}")

# Step 6: Deploy to Target 1 (Flash: D:\MEGA\WIN-FLASH\Util-WINDOWS\Graphics\)
flash_dir = r"D:\MEGA\WIN-FLASH\Util-WINDOWS\Graphics"
os.makedirs(flash_dir, exist_ok=True)
flash_target = os.path.join(flash_dir, f"GIN-Desktop_{VERSION}_Setup.exe")
shutil.copy2(SETUP_EXE, flash_target)
print(f"==> [Target 1: Flash] Deployed to: {flash_target}")

# Step 7: Deploy to Target 2 (Desktop: D:\MEGA\DOCS\desktop\)
desktop_dir = r"D:\MEGA\DOCS\desktop"
os.makedirs(desktop_dir, exist_ok=True)
desktop_target = os.path.join(desktop_dir, f"GIN-Desktop_{VERSION}_Setup.exe")
shutil.copy2(SETUP_EXE, desktop_target)
print(f"==> [Target 2: Desktop] Deployed to: {desktop_target}")

# Step 8: Retain strictly 2 latest versions (v051 and v052) in all targets
allowed_versions = ["v051", "v052"]

for target_folder, desc in [(ROOT_DIR, "Project Root"), (flash_dir, "Flash Graphics"), (desktop_dir, "Desktop")]:
    if os.path.exists(target_folder):
        for fname in os.listdir(target_folder):
            if fname.startswith("GIN-Desktop_") and fname.endswith("_Setup.exe"):
                ver_match = re.search(r"v\d{3}", fname)
                if ver_match:
                    ver = ver_match.group(0)
                    if ver not in allowed_versions:
                        obsolete_path = os.path.join(target_folder, fname)
                        try:
                            os.remove(obsolete_path)
                            print(f"    [{desc}] Purged obsolete release: {fname}")
                        except Exception as e:
                            print(f"    [{desc}] Error purging {fname}: {e}")

# Mirror to GIN-Wallpaper if exists
old_mirror = os.path.join(os.path.dirname(ROOT_DIR), "GIN-Wallpaper")
if os.path.exists(old_mirror):
    dest_setup = os.path.join(old_mirror, f"GIN-Desktop_{VERSION}_Setup.exe")
    shutil.copy2(SETUP_EXE, dest_setup)
    with open(os.path.join(old_mirror, "version.json"), "w", encoding="utf-8") as f:
        json.dump(v_data, f, indent=2, ensure_ascii=False)
    for fname in os.listdir(old_mirror):
        if fname.startswith("GIN-Desktop_") and fname.endswith("_Setup.exe"):
            ver_match = re.search(r"v\d{3}", fname)
            if ver_match and ver_match.group(0) not in allowed_versions:
                try:
                    os.remove(os.path.join(old_mirror, fname))
                    print(f"    [Mirror GIN-Wallpaper] Purged obsolete release: {fname}")
                except Exception:
                    pass
    print(f"==> Mirrored to {old_mirror}")

print(f"DONE! GIN-Desktop {VERSION} build and dual-target deployment completed.")

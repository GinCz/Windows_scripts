#!/usr/bin/env python3
import os
import sys
import base64
import re
import hashlib
import json
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

VERSION = "v049"
APP_EXE = os.path.join(SCRIPT_DIR, "GIN-Desktop.exe")
UNINST_EXE = os.path.join(SCRIPT_DIR, "Uninstall.exe")
ICO_FILE = os.path.join(SCRIPT_DIR, "app.ico")
SETUP_EXE = os.path.join(ROOT_DIR, f"GIN-Desktop_{VERSION}_Setup.exe")
INSTALLER_SRC = os.path.join(SCRIPT_DIR, "installer_setup.cs")
APP_SRC = os.path.join(SCRIPT_DIR, "GIN-Desktop.cs")
UNINST_SRC = os.path.join(SCRIPT_DIR, "Uninstall.cs")
VERSION_JSON = os.path.join(ROOT_DIR, "version.json")

print(f"==> [1/4] Compiling Uninstall.exe...")
cmd1 = [
    "mcs", "-target:winexe", "-optimize+", "-platform:anycpu",
    f"-win32icon:{ICO_FILE}",
    "-r:System.dll,System.Windows.Forms.dll",
    f"-out:{UNINST_EXE}",
    UNINST_SRC
]
res1 = subprocess.run(cmd1, capture_output=True, text=True)
if res1.returncode != 0:
    print("Error compiling Uninstall.cs:\n", res1.stderr)
    sys.exit(1)
print(f"    Compiled Uninstall.exe ({os.path.getsize(UNINST_EXE)} bytes)")

print(f"==> [2/4] Compiling GIN-Desktop.exe...")
cmd2 = [
    "mcs", "-target:winexe", "-optimize+", "-platform:anycpu",
    f"-win32icon:{ICO_FILE}",
    "-r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll",
    f"-out:{APP_EXE}",
    APP_SRC
]
res2 = subprocess.run(cmd2, capture_output=True, text=True)
if res2.returncode != 0:
    print("Error compiling GIN-Desktop.cs:\n", res2.stderr)
    sys.exit(1)
print(f"    Compiled GIN-Desktop.exe ({os.path.getsize(APP_EXE)} bytes)")

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
print(f"    Updated {INSTALLER_SRC}")

print(f"==> [4/4] Compiling {SETUP_EXE}...")
cmd3 = [
    "mcs", "-target:winexe", "-optimize+", "-platform:anycpu",
    f"-win32icon:{ICO_FILE}",
    "-r:System.dll,System.Windows.Forms.dll,Microsoft.CSharp.dll,System.Core.dll",
    f"-out:{SETUP_EXE}",
    INSTALLER_SRC
]
res3 = subprocess.run(cmd3, capture_output=True, text=True)
if res3.returncode != 0:
    print("Error compiling installer_setup.cs:\n", res3.stderr)
    sys.exit(1)

setup_size = os.path.getsize(SETUP_EXE)
with open(SETUP_EXE, "rb") as f:
    setup_sha256 = hashlib.sha256(f.read()).hexdigest()

print(f"✅ Setup created at: {SETUP_EXE} ({setup_size} bytes)")
print(f"   SHA-256: {setup_sha256}")

# Update version.json
v_data = {
    "version": VERSION,
    "name": "GIN-Desktop",
    "installer": f"GIN-Desktop_{VERSION}_Setup.exe",
    "description": "Unified Windows Desktop Companion: Hot-Corner Top Dock Bar, 4K Wallpaper Engine, Calendar HUD, Hardware Monitor & Real-Time Weather",
    "author": "GinCz / Vladimir Bulantsev & Antigravity",
    "github": "https://github.com/GinCz/Windows_scripts/tree/main/GIN-Desktop",
    "date": "2026-11-21",
    "sha256": setup_sha256,
    "download_url": f"https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Desktop/GIN-Desktop_{VERSION}_Setup.exe",
    "features": [
        "Localized City Name in Weather HUD: Weather badge under the Calendar HUD displays the live localized city name (e.g. Прага: ☀ +18°C · Ясно / Praha / Prague) with clear SettingsForm labeling",
        "Silent Tray HUD Auto-Updater: Zero-popup quiet update workflow with subtle non-activating HUD toast near system tray and gentle pure-sine audio blips identical to GIN-Voice",
        "Seamless Transition Pipeline: Live version transition (e.g. 44 ➔ 45) in tray HUD with automatic background download, process termination, service halt, and instant restart",
        "Clean Desktop Organization: Automatic updates strictly skip recreating desktop shortcuts, preserving user desktop integrity",
        "Rebranded as GIN Desktop: Single unified lightweight Windows suite (~2-4 MB RAM) with independent ON/OFF engines",
        "Top-Only Fluid Dock Bar: Dedicated top position activated strictly on hover at top-left hot corner with zero visual clutter",
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
print(f"✅ Updated {VERSION_JSON}")

# Mirror to GIN-Wallpaper if exists
old_mirror = os.path.join(os.path.dirname(ROOT_DIR), "GIN-Wallpaper")
if os.path.exists(old_mirror):
    dest_setup = os.path.join(old_mirror, f"GIN-Desktop_{VERSION}_Setup.exe")
    with open(SETUP_EXE, "rb") as sf, open(dest_setup, "wb") as df:
        df.write(sf.read())
    with open(os.path.join(old_mirror, "version.json"), "w", encoding="utf-8") as f:
        json.dump(v_data, f, indent=2, ensure_ascii=False)
    print(f"✅ Mirrored to {old_mirror}")

# Retain strictly 2 latest versions in ROOT_DIR: v048 and v049
for f in os.listdir(ROOT_DIR):
    if f.endswith("_Setup.exe"):
        if not (VERSION in f or "v048" in f):
            try:
                os.remove(os.path.join(ROOT_DIR, f))
                print(f"Purged obsolete release: {f}")
            except Exception as e:
                pass

if os.path.exists(old_mirror):
    for f in os.listdir(old_mirror):
        if f.endswith("_Setup.exe"):
            if not (VERSION in f or "v048" in f):
                try:
                    os.remove(os.path.join(old_mirror, f))
                    print(f"Purged obsolete mirror release: {f}")
                except Exception as e:
                    pass

# Deploy to Vladimir's Desktop in MEGA cloud (D:\MEGA\DOCS\desktop\ via DE-222)
# User specifically requested keeping strictly ONE copy on desktop with version in name
sync_script = os.path.join(os.path.dirname(ROOT_DIR), "scripts", "sync_mega_desktop.sh")
if os.path.exists(sync_script):
    print(f"==> Deploying to Vladimir's Desktop in MEGA cloud ({sync_script})...")
    try:
        subprocess.run([sync_script, SETUP_EXE, "GIN-Desktop", "1"], check=True)
    except Exception as e:
        print(f"⚠️ Warning: Auto-sync to MEGA Desktop failed: {e}")

print(f"🎉 Build pipeline completed successfully for {VERSION}!")

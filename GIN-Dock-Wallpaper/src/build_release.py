#!/usr/bin/env python3
import os
import sys
import base64
import re
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

VERSION = "v042"
APP_EXE = os.path.join(SCRIPT_DIR, "GIN-Dock-Wallpaper.exe")
UNINST_EXE = os.path.join(SCRIPT_DIR, "Uninstall.exe")
ICO_FILE = os.path.join(SCRIPT_DIR, "app.ico")
SETUP_EXE = os.path.join(ROOT_DIR, f"GIN-Dock-Wallpaper_{VERSION}_Setup.exe")
INSTALLER_SRC = os.path.join(SCRIPT_DIR, "installer_setup.cs")

print(f"==> [1/4] Compiling Uninstall.exe...")
cmd1 = [
    "mcs", "-target:winexe", "-optimize+", "-platform:anycpu",
    f"-win32icon:{ICO_FILE}",
    "-r:System.dll,System.Windows.Forms.dll",
    f"-out:{UNINST_EXE}",
    os.path.join(SCRIPT_DIR, "Uninstall.cs")
]
res1 = subprocess.run(cmd1, capture_output=True, text=True)
if res1.returncode != 0:
    print("Error compiling Uninstall.cs:\n", res1.stderr)
    sys.exit(1)
print(f"    Compiled Uninstall.exe ({os.path.getsize(UNINST_EXE)} bytes)")

print(f"==> [2/4] Compiling GIN-Dock-Wallpaper.exe...")
cmd2 = [
    "mcs", "-target:winexe", "-optimize+", "-platform:anycpu",
    f"-win32icon:{ICO_FILE}",
    "-r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll",
    f"-out:{APP_EXE}",
    os.path.join(SCRIPT_DIR, "GIN-Dock-Wallpaper.cs")
]
res2 = subprocess.run(cmd2, capture_output=True, text=True)
if res2.returncode != 0:
    print("Error compiling GIN-Dock-Wallpaper.cs:\n", res2.stderr)
    sys.exit(1)
print(f"    Compiled GIN-Dock-Wallpaper.exe ({os.path.getsize(APP_EXE)} bytes)")

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

print(f"✅ Build Complete! Setup created at: {SETUP_EXE} ({os.path.getsize(SETUP_EXE)} bytes)")

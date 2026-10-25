# 🚀 Windows 10/11 Ultimate Optimizer & Deep Cleaner Plus (`v013`)

[![Release](https://img.shields.io/badge/Release-v013-00b4d8?style=for-the-badge&logo=windows)](https://github.com/GinCz/Windows_scripts/releases)
[![Architecture](https://img.shields.io/badge/Architecture-Polyglot_CMD%2FPowerShell-1e3a5f?style=for-the-badge&logo=powershell)](https://github.com/GinCz/Windows_scripts)
[![Platform](https://img.shields.io/badge/Platform-Windows_10_%2F_11_x64-25282e?style=for-the-badge&logo=windows11)](https://github.com/GinCz/Windows_scripts)
[![Languages](https://img.shields.io/badge/Languages-EN_%7C_CS_%7C_RU-success?style=for-the-badge)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

> **Repository:** [Windows_scripts / Windows / WIN_Optimizator ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/WIN_Optimizator)  
> **Authors / Architects:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Target Systems:** Windows 10 (1903–22H2), Windows 11 (21H2, 22H2, 23H2, 24H2), Windows Server 2019/2022/2025  

---

## 📖 Overview

**WIN_Optimizator** is an enterprise-grade, standalone Windows optimization and deep system cleaning suite designed to eliminate telemetry, declutter the Windows shell, tune kernel responsiveness, strip pre-installed bloatware, and reclaim gigabytes of disk storage without breaking Windows updates or universal apps.

Engineered as a single-file polyglot hybrid (`.cmd` wrapper + embedded PowerShell 5.1 / WPF runtime), it requires **zero installation**, zero external DLLs, and zero internet dependencies. You can double-click it directly from a USB flash drive or desktop, elevate with a single UAC click, and execute comprehensive system tuning via a modern, dark-themed graphical interface.

---

## ⚡ Key Highlights & Architecture

- **Single-File Polyglot Hybrid (`.cmd` + WPF PowerShell):** Boots through a micro CMD launcher that verifies Administrator rights, auto-elevates via UAC if necessary, and compiles an embedded Base64-encoded XAML UI entirely in memory using .NET PresentationFramework.
- **Single-Window Modern Dark GUI:** Pure Win32/WPF interface with a dark palette (`#131518`), customizable real-time terminal emulator, progress indicators, and instant trilingual localization (English, Czech, Russian).
- **Thread-Safe Dispatcher Queue:** Prevents PowerShell 5.1 runspace deadlocks and multithreaded collision crashes (`PSInvalidOperationException`) during external operations like `cleanmgr`, `dism`, and `sfc` by using synchronous stream polling.
- **Persistent Results Log:** The optimization window **never** closes automatically upon task completion. All execution logs, task statuses, warnings, and success messages remain fully visible in the terminal log for review, clipboard copying, or disk export.
- **Hardware-Level Dual Audio Confirmation:** Fires two distinct, low-pitched confirmation tones (`320 Hz`, 180ms + 220ms) directly through `kernel32.dll!Beep`, guaranteeing audible confirmation on all sound devices and internal motherboard buzzers.
- **Windows 11 Taskbar Decluttering with Live Reload:** Fully suppresses taskbar clutter (Search Box, Widgets, Task View, Chat, Copilot) across all user hives (`HKCU`, `HKLM`, `HKEY_USERS`), and automatically restarts `explorer.exe` safely so changes apply instantly without requiring a full machine reboot.

---

## 🛠️ Complete Feature Breakdown (97 Modules)

### 1. 🔒 Privacy & Diagnostics Telemetry
- Disables Connected User Experiences and Telemetry (`DiagTrack`).
- Disables WAP Push Message Routing Service (`dmwappushservice`).
- Disables Windows Error Reporting Service (`WerSvc`).
- Restricts diagnostics data collection via Group Policy (`AllowTelemetry = 0`, `MaxTelemetryAllowed = 0`).
- Disables user Advertising ID across all user profiles.
- Disables inking and typing data collection / text harvest.
- Disables Windows Activity History (Timeline) and cloud synchronization.
- Disables Geolocation Sensor Service (`lfsvc`) and sensor permissions.
- Disables Windows Customer Experience Improvement Program (CEIP) scheduled tasks.
- Permanently blocks and disables Cortana assistant in the Windows Registry.

### 2. 🛡️ Security, UAC & SmartScreen
- **Silent UAC for Administrators:** Disables screen dimming and prompt popups for administrator accounts (`ConsentPromptBehaviorAdmin = 0`, `PromptOnSecureDesktop = 0`) while keeping modern UWP/Store apps functioning properly.
- Configures Admin Approval Mode for the built-in Administrator account.
- Disables SmartScreen filter for downloaded applications and File Explorer.
- Disables the annoying *"Open File - Security Warning"* dialog for trusted executable file types (`.exe`, `.bat`, `.cmd`, `.ps1`, `.msi`, `.zip`, `.rar`, `.7z`).

### 3. ☁️ Cloud & Consumer Features
- **OneDrive Uninstaller:** Completely uninstalls Microsoft OneDrive and blocks future reinstallations via policy (can be unchecked to preserve OneDrive).
- Disables Windows Settings synchronization with Microsoft Cloud Accounts.
- Disables Bing Web Search in the Start Menu (restores 100% local fast searching).
- Disables Windows Spotlight lock screen ads, quizzes, and sponsored tips.
- Blocks background silent installation of consumer bloatware and sponsored third-party store apps (`DisableWindowsConsumerFeatures = 1`).

### 4. 🌐 Microsoft Edge Optimization
- Disables Edge background execution after closing the browser window.
- Disables Edge Startup Boost to free up RAM at boot.
- Disables Edge telemetry reporting and shopping assistant / coupon scrapers.
- Disables the Edge sidebar and built-in promotional panels.
- Disables pre-launching Edge during Windows startup.
- Disables the mandatory First Run Experience and welcome wizard.
- Unpins Edge from the Taskbar and prevents automatic desktop shortcut creation.

### 5. 🪟 Explorer, Desktop, Taskbar & Start Menu (Dism++ Tweaks)
- **Windows 11 Taskbar Decluttering:**
  - Completely hides the Taskbar Search Box and Search Icon (`SearchboxTaskbarMode = 0`).
  - Disables Windows 11 Widgets and News Feed (`TaskbarDa = 0`, `Feeds = 2`).
  - Removes the Microsoft Teams Chat icon (`TaskbarMn = 0`).
  - Disables Windows Copilot AI button and sidebar integration.
  - Disables Windows Recall AI background screenshot collection.
  - Hides the Task View button (`ShowTaskViewButton = 0`).
- **Start Menu Cleanup:** Cleans the Windows 11 Start Menu, hides the "Recommended" section, clears recent documents history, and enables the compact layout mode.
- **Classic Context Menu:** Restores the Windows 10 classic context menu on Windows 11 (bypasses the cumbersome *"Show More Options"* extra click).
- **Taskbar & Tray Settings:**
  - Always displays all icons in the system tray (prevents hiding behind the chevron arrow).
  - Uncombines taskbar buttons (`Never Combine` mode).
  - Displays the classic "This PC" icon on the desktop.
  - Configures 24-hour clock format with live seconds in the system tray.
  - Locks the taskbar to prevent accidental layout shifts.
- **File Explorer Tuning:**
  - Opens File Explorer directly to "This PC" instead of "Quick Access".
  - Hides 6 redundant user folders (3D Objects, Music, Videos, etc.) from the "This PC" folder tree.
  - Disables the `"- Shortcut"` text suffix when generating new shortcuts.
  - Displays full folder paths in File Explorer title bars.
  - Launches folder windows in a separate memory process to prevent desktop crashes.

### 6. 📋 Context Menu Cleanup
- Removes redundant right-click clutter (Troubleshoot compatibility, Paint 3D, Disc Burn, Cast to Device).
- Removes WinRAR *"Compress and email..."* clutter entries.

### 7. 🔄 Windows Update, BSOD & System
- Excludes hardware device drivers from Windows Update (prevents broken OEM driver overwrites).
- Excludes Malicious Software Removal Tool (MSRT) downloads.
- Disables automatic reboot on Blue Screen of Death (BSOD), giving you time to read stop codes.
- Configures small kernel memory minidumps to save NVMe/SSD drive capacity.
- Disables Fast Startup (prevents kernel corruption and sleep/wake driver lockups).
- Disables Remote Assistance (`fAllowToGetHelp = 0`).
- Restores the classic, ultra-fast Windows Photo Viewer.
- Enables Word Wrap and Status Bar by default in classic Notepad.

### 8. 📦 App Debloater & Provisioned Packages
- Strips Xbox packages (Xbox App, GameBar, Gaming Services — uncheck for gaming rigs).
- Strips pre-installed promo games (Candy Crush, Solitaire Collection, TikTok, Disney stubs).
- Strips MSN News, Weather, Sports, and Money/Finance apps.
- Strips the Microsoft 365 / GetOffice promotion stub.
- Strips Clipchamp video editor.
- Strips legacy People components and mail stubs.
- Strips Feedback Hub and Get Help / Tips applications.
- Strips Phone Link (uncheck if using Android/iOS pairing).

### 9. ⚙️ System Performance & Services
- Disables SysMain / Superfetch (prolongs SSD lifespan and eliminates random 100% disk usage spikes).
- Disables Windows Search indexing service (WSearch) to reduce CPU and background I/O contention.
- Disables Remote Registry service for system hardening.
- Disables Delivery Optimization P2P bandwidth sharing.
- Disables Windows Reserved Storage to instantly reclaim ~7 GB of SSD storage.
- Disables Hibernation and deletes `hiberfil.sys` (frees gigabytes equal to physical RAM).
- Activates the hidden Windows **Ultimate Performance** power plan (`e9a42b02-d5df-448d-aa00-03f14749eb61`).
- Disables NTFS LastAccess updates and 8.3 short filename generation, then executes an SSD TRIM operation.
- Disables network Task Offload and TCP Chimney to prevent sudden online gaming latency spikes.
- Tunes visual effects for maximum responsiveness while strictly maintaining font smoothing (ClearType).
- Disables Program Compatibility Assistant (`PcaSvc`).
- Disables Distributed Link Tracking Client (`TrkWks`).

### 10. 🧹 Cache, Temp & Deep Component Cleaning
- Cleans user temporary folders (`%TEMP%` and `AppData\Local\Temp`).
- Cleans system temporary directory (`C:\Windows\Temp`).
- Cleans Windows Update download cache (`C:\Windows\SoftwareDistribution\Download`).
- Cleans thumbnail database caches (`thumbcache_*.db`).
- Flushes the local DNS client cache and clears DirectX shader cache (`D3DSCache`).
- Purges all Windows Event Viewer logs (`wevtutil cl`).
- Empties Recycle Bins on all mounted drives.
- **Sequential Disk Cleanup:** Executes automated system disk cleanup (`cleanmgr.exe /sagerun:6553 /d C:`) with intelligent disk lock detection.
- **Component Store Repair:** Runs DISM Component Store verification (`dism.exe /Online /Cleanup-Image /RestoreHealth`).
- **WinSxS Deep Cleanup:** Runs DISM ResetBase (`dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase`) to permanently discard superseded update backups.
- **System Integrity:** Runs SFC Scannow integrity verification (`sfc.exe /scannow`).

---

## 🎛️ Presets

The interface provides 4 one-click configuration presets:

| Preset Button | Description |
| :--- | :--- |
| **✓ Select All (Max Clean)** | Enables all 97 optimization, telemetry, debloat, and cleaning modules for a pristine, bloat-free system. |
| **🏢 Office (Keep OneDrive)** | Enables all optimizations while preserving Microsoft OneDrive, Microsoft 365, and Phone Link. |
| **⚡ Gaming (Keep Xbox)** | Enables all optimizations while preserving Xbox services, GameBar, and gamepad dependencies. |
| **✗ Deselect All** | Clears all checkboxes to allow granular custom selection. |

---

## 🚀 How to Run

1. Download [`WIN_Optimizator_v013.cmd`](https://github.com/GinCz/Windows_scripts/raw/main/Windows/WIN_Optimizator/WIN_Optimizator_v013.cmd).
2. Right-click and choose **Run as administrator** (or simply double-click; the script will prompt for elevation automatically).
3. Select your language preference in the top-right corner (**English**, **Čeština**, or **Русский**).
4. Choose a Preset or toggle individual options.
5. Click **🚀 START OPTIMIZATION**.
6. Track live progress in the integrated terminal. When finished, you will hear two short low-pitched confirmation beeps (`320 Hz`), and the detailed log will remain open for your inspection.
7. Reboot your PC to finalize all kernel and shell changes.

---

## 📋 System Requirements

- **Operating System:** Windows 10 (1903 or newer), Windows 11 (all versions), Windows Server 2019/2022/2025.
- **Architecture:** x86_64 (64-bit) or x86 (32-bit).
- **Runtime:** PowerShell 5.1 (pre-installed natively on all modern Windows versions) with .NET Framework 4.5+ (built-in).
- **Privileges:** Administrator privileges (script auto-elevates via UAC).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — free for both personal and commercial use.

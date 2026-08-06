# Windows Batch Script Standard

**Status:** mandatory standard for every new or refactored `.bat` / `.cmd` script in this repository.  
**Target environment:** Windows CMD, executed from a local console with PowerShell available.  
**Goal:** consistent, safe, UTF-8-friendly scripts with automatic UAC elevation and the Cyber Parking Zone interface.

## Mandatory rules

1. Start every script with the exact initialization sequence below: `@echo off`, UTF-8 console activation, then `cls`.
2. Check elevation with `fltmc`. If the process is not elevated, relaunch the same script through `powershell -NoProfile` with `Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs` (to safely support paths and filenames containing spaces and special characters like `&`); immediately terminate the unelevated process with `exit /b`.
3. After elevation, always force the working directory to the directory containing the script: `cd /d "%~dp0"`. Never rely on the inherited directory, because an elevated process may otherwise run from `C:\Windows\System32`.
4. Set a descriptive `title` in the form `<Script Purpose> - <MODE>` so the running window is recognizable in the taskbar.
5. Render the Cyber Parking Zone before the main output: exactly four blank lines, one dark-gray 89-character parking line beginning with one leading space, then exactly three blank lines.
6. Use yellow, 90-character PowerShell separator lines around each main execution stage. Keep normal status messages as plain English `echo` output.
7. Handle expected failures explicitly. Print a clear red PowerShell error message, preserve a meaningful non-zero exit code, and pause when interactive diagnostics are required.
8. Finish successful runs with a yellow completion block, `timeout /t 10 /NOBREAK >nul`, and `exit /b 0`.
9. Keep each file single-purpose. Use quoted `set "NAME=value"` assignments for paths and values that may contain spaces.
10. Do not place secrets, credentials, tokens, personal paths, or host-specific values in this public repository. Retrieve them only from the private secrets source at execution time or use an approved local protected configuration file.

## Required skeleton

Copy this skeleton first, then replace placeholders without changing the initialization, elevation, directory, UI, or completion conventions.

```bat
:: ==========================================================================================
:: FILE: <Script_Name>.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-elevate to Administrator
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :ELEVATE
goto :ADMIN_OK

:ELEVATE
powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
exit /b

:ADMIN_OK
cd /d "%~dp0"
title <Script Purpose> - <MODE>

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' <89-character Cyber Parking Zone line goes here>' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' <Script Execution Started>' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

:: Define configuration only after elevation and before the action.
set "EXAMPLE_PATH=C:\Path With Spaces"

:: Main commands go here. Status text must be in English.
echo Processing data, please wait...

:: Example failure pattern:
:: if %errorlevel% neq 0 (
::     powershell -NoProfile -Command "Write-Host ' ERROR: <meaningful failure message>' -ForegroundColor Red"
::     timeout /t 10 /NOBREAK >nul
::     exit /b 1
:: )

:: ------------------------------------------------------------------------------------------
:: END OF SCRIPT
:: ------------------------------------------------------------------------------------------
echo.
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' Execution completed successfully!' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.YYYY.MM.DD | github.com/GinCz =
```

## UI requirements

- **Parking Zone:** It is a visual buffer for any PowerShell invocation. Do not move, remove, or alter its spacing. The line must contain 89 characters including the mandatory leading space so it is visually centered in a 90-column console.
- **Stage framing:** Use the yellow separator before and after an operation, with a concise English label such as `Hiddify Portable Restore Started` or `Execution completed successfully!`.
- **Messages:** Use `echo` for normal progress and `Write-Host` only when color is needed. Do not mix languages in user-facing messages within the same script.
- **Timing:** Use `timeout /t <seconds> /NOBREAK >nul`; do not use an unbounded `pause` on a successful path.

## Engineering requirements

- Validate required files, directories, commands, and prerequisites before destructive or long-running work.
- Quote every path and executable that can contain spaces.
- Stop or restart a process only when the script's purpose requires it; tolerate an already-stopped process where appropriate.
- For archive, download, installer, scheduled-task, registry, service, or network operations, check `%errorlevel%` immediately after the command that must succeed.
- Prefer idempotent operations: a rerun should either converge to the desired state or fail with a precise explanation.
- Do not suppress errors unless the failure is explicitly expected and handled.
- Use `-NoProfile` for every non-interactive PowerShell call to keep behavior deterministic.

## Review checklist

Before committing a new or changed CMD script, verify:

- It starts with `@echo off`, `chcp 65001 >nul`, and `cls`.
- UAC self-elevation uses `fltmc` and exits the original unelevated process.
- `cd /d "%~dp0"` executes only after elevation.
- A meaningful title is present.
- The parking zone has exactly 4 blank lines above and 3 below; its line is exactly 89 characters with one leading space.
- Yellow UI separators are 90 characters wide.
- Status text is English and errors are clearly colored red.
- All paths are quoted and configuration uses `set "NAME=value"`.
- Secrets are absent from public code, documentation, examples, command history, and commits.
- The script has explicit error handling and exits with `0` on success or a non-zero status on failure.
- The final 10-second timeout and `exit /b 0` are present on the success path.

## Reference implementation

The Hiddify backup/restore scripts are the current functional reference for the intended elevation flow, parking-zone layout, yellow execution blocks, quoted variables, process handling, archive operations, and final timeout. Future refactoring should preserve their behavior while bringing their structure fully in line with this standard.

---

Maintainer: **VladiMIR Bulantsev (GinCz)**  
Standard version: **2026.08.06
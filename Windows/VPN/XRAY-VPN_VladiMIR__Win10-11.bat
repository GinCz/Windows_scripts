@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (fltmc method - reliable Win7+10+11)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title XRAY VPN Installer - LOADING...

for /L %%i in (1,1,4) do echo.
powershell -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ' [POWERSHELL STARTING...]' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: Extract and run the embedded PowerShell section from this file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "XRAY VPN Installer - EXECUTE"

Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''
Write-Host '                       X R A Y   V P N   I N S T A L L E R' -ForegroundColor Yellow
Write-Host '                         Works on Windows 7 / 10 / 11' -ForegroundColor DarkGray
Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''

Write-Host '[*] Resetting proxy settings...' -ForegroundColor Cyan
& netsh winhttp reset proxy | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null

Write-Host '[*] Downloading installer script from server...' -ForegroundColor Cyan
try {
    (New-Object Net.WebClient).DownloadFile('http://prodvig-saita.ru/vpn/install.ps1', "$env:TEMP\xray_install.ps1")
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    Write-Host 'Press Enter to exit...' -ForegroundColor DarkGray
    Read-Host | Out-Null
    exit 1
}

Write-Host '[*] Running installer...' -ForegroundColor Cyan
& "$env:TEMP\xray_install.ps1"
Remove-Item "$env:TEMP\xray_install.ps1" -Force -ErrorAction SilentlyContinue

# Save original external IP before VPN connects
try { (New-Object Net.WebClient).DownloadString('http://api.ipify.org').Trim() | Out-File "C:\XRAY_VPN\orig_ip.txt" -Encoding ASCII } catch {}

# Deploy enhanced TrayVPN with IP tooltip
[System.IO.File]::WriteAllBytes("C:\XRAY_VPN\TrayVPN.ps1", [Convert]::FromBase64String('W3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgiU3lzdGVtLldpbmRvd3MuRm9ybXMiKQ0KW3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgiU3lzdGVtLkRyYXdpbmciKQ0KDQojIFdyaXRlIGVtYmVkZGVkIGdyZWVuIHNoaWVsZCBpY29uIHRvIHRlbXAgZmlsZQ0KJGljb25CeXRlcyA9IFtDb252ZXJ0XTo6RnJvbUJhc2U2NFN0cmluZygnQUFBQkFBRUFFQkFBQUFFQUlBQm9CQUFBRmdBQUFDZ0FBQUFRQUFBQUlBQUFBQUVBSUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUhITUx2OXh6QzcvQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBSEhNTHY5eHpDNy9jY3d1LzNITUx2OEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFISE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1L3dBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJ4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQnh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1L3dBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQWNjd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1MdjhBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQWNjd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3Uvd0FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUhITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBSEhNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1L3dBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJ4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY4QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L0FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUhITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS93QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCeHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY5eHpDNy9jY3d1LzNITUx2OEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBSEhNTHY5eHpDNy9jY3d1LzNITUx2OXh6QzcvY2N3dS8zSE1Mdjl4ekM3L2Njd3UvM0hNTHY4QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUEvLzhBQVA1L0FBRDhQd0FBK0I4QUFQZ2ZBQUR3RHdBQThBOEFBT0FIQUFEZ0J3QUF3QU1BQU1BREFBREFBd0FBd0FNQUFNQURBQURnQndBQS8vOEFBQT09JykNCiRpY29uUGF0aCA9ICIkZW52OlRFTVBceHJheV9zaGllbGQuaWNvIg0KW1N5c3RlbS5JTy5GaWxlXTo6V3JpdGVBbGxCeXRlcygkaWNvblBhdGgsICRpY29uQnl0ZXMpDQoNCiRpY29uID0gJG51bGwNCnRyeSB7DQogICAgJGljb24gPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLkljb24oJGljb25QYXRoKQ0KfSBjYXRjaCB7DQogICAgIyBGYWxsYmFjayB0byBzeXN0ZW0gaWNvbg0KICAgIHRyeSB7DQogICAgICAgICRpY29uID0gW1N5c3RlbS5EcmF3aW5nLkljb25dOjpFeHRyYWN0QXNzb2NpYXRlZEljb24oIiRlbnY6U3lzdGVtUm9vdFxTeXN0ZW0zMlxzaGVsbDMyLmRsbCIpDQogICAgfSBjYXRjaCB7fQ0KfQ0KDQokbm90aWZ5ID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5Ob3RpZnlJY29uDQppZiAoJGljb24pIHsgJG5vdGlmeS5JY29uID0gJGljb24gfQ0KJG9yaWdJcCA9ICJVbmtub3duIgppZiAoVGVzdC1QYXRoICJDOlxYUkFZX1ZQTlxvcmlnX2lwLnR4dCIpIHsKICAgIHRyeSB7ICRvcmlnSXAgPSBbU3lzdGVtLklPLkZpbGVdOjpSZWFkQWxsVGV4dCgiQzpcWFJBWV9WUE5cb3JpZ19pcC50eHQiKS5UcmltKCkgfSBjYXRjaCB7fQp9CiR1c2VyID0gJGVudjpVU0VSTkFNRQokbm90aWZ5LlRleHQgPSAiVlBOOiBDb25uZWN0ZWRgbk9yaWc6ICRvcmlnSXBgblVzZXI6ICR1c2VyIgoKJGlwVGltZXIgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLlRpbWVyCiRpcFRpbWVyLkludGVydmFsID0gMTAwMAokaXBUaW1lci5hZGRfVGljayh7CiAgICAkdnBuSXAgPSB0cnkgeyAoTmV3LU9iamVjdCBOZXQuV2ViQ2xpZW50KS5Eb3dubG9hZFN0cmluZygiaHR0cDovL2FwaS5pcGlmeS5vcmciKS5UcmltKCkgfSBjYXRjaCB7ICIiIH0KICAgIGlmICgkdnBuSXApIHsKICAgICAgICAkaXBUaW1lci5JbnRlcnZhbCA9IDMwMDAwCiAgICAgICAgJHN0ciA9ICJWUE46ICR2cG5JcGBuT3JpZzogJG9yaWdJcGBuVXNlcjogJHVzZXIiCiAgICAgICAgaWYgKCRzdHIuTGVuZ3RoIC1ndCA2MykgeyAkc3RyID0gJHN0ci5TdWJzdHJpbmcoMCwgNjApICsgIi4uLiIgfQogICAgICAgICRub3RpZnkuVGV4dCA9ICRzdHIKICAgIH0KfSkKJGlwVGltZXIuU3RhcnQoKQ0KJG5vdGlmeS5WaXNpYmxlID0gJHRydWUNCg0KJG1lbnUgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLkNvbnRleHRNZW51DQokaXRlbVN0YXR1cyA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuTWVudUl0ZW0gIlhyYXkgVlBOOiBDb25uZWN0ZWQiDQokaXRlbVN0YXR1cy5FbmFibGVkID0gJGZhbHNlDQokaXRlbVNlcCA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuTWVudUl0ZW0gIi0iDQokaXRlbVN0b3AgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLk1lbnVJdGVtICJEaXNjb25uZWN0ICYmIEV4aXQiDQoNCiRpdGVtU3RvcC5hZGRfQ2xpY2soew0KICAgICRub3RpZnkuVmlzaWJsZSA9ICRmYWxzZQ0KICAgICRub3RpZnkuRGlzcG9zZSgpDQogICAgU3RhcnQtUHJvY2VzcyAid3NjcmlwdC5leGUiIC1Bcmd1bWVudExpc3QgJyJDOlxYUkFZX1ZQTlxTdG9wX1ZQTi52YnMiJyAtV2luZG93U3R5bGUgSGlkZGVuDQogICAgW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkFwcGxpY2F0aW9uXTo6RXhpdCgpDQp9KQ0KDQpbdm9pZF0kbWVudS5NZW51SXRlbXMuQWRkKCRpdGVtU3RhdHVzKQ0KW3ZvaWRdJG1lbnUuTWVudUl0ZW1zLkFkZCgkaXRlbVNlcCkNClt2b2lkXSRtZW51Lk1lbnVJdGVtcy5BZGQoJGl0ZW1TdG9wKQ0KJG5vdGlmeS5Db250ZXh0TWVudSA9ICRtZW51DQoNCiMgV2F0Y2hkb2c6IGlmIHhyYXkuZXhlIGRpZXMsIGNsb3NlIHRyYXkgdG9vDQokdGltZXIgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLlRpbWVyDQokdGltZXIuSW50ZXJ2YWwgPSAyMDAwDQokdGltZXIuYWRkX1RpY2soew0KICAgICRwcm9jID0gR2V0LVByb2Nlc3MgeHJheSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQ0KICAgIGlmICgtbm90ICRwcm9jKSB7DQogICAgICAgICR0aW1lci5TdG9wKCkNCiAgICAgICAgJG5vdGlmeS5WaXNpYmxlID0gJGZhbHNlDQogICAgICAgICRub3RpZnkuRGlzcG9zZSgpDQogICAgICAgIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5BcHBsaWNhdGlvbl06OkV4aXQoKQ0KICAgIH0NCn0pDQokdGltZXIuU3RhcnQoKQ0KDQokbm90aWZ5LlNob3dCYWxsb29uVGlwKDMwMDAsICJYcmF5IFZQTiIsICJDb25uZWN0ZWQhIFNoaWVsZCBhY3RpdmUgaW4gdHJheS4iLCBbU3lzdGVtLldpbmRvd3MuRm9ybXMuVG9vbFRpcEljb25dOjpJbmZvKQ0KW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkFwcGxpY2F0aW9uXTo6UnVuKCkNCg=='))

Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ' [OK] Done! Next steps:' -ForegroundColor Green
Write-Host '      1. Paste your VLESS key into Notepad (link.txt) and Save (Ctrl+S)' -ForegroundColor Green
Write-Host '      2. Double-click Start_VPN shortcut in C:\XRAY_VPN' -ForegroundColor Green
Write-Host '      3. Click Check_IP to verify your new IP' -ForegroundColor Green
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Press Enter to exit...' -ForegroundColor DarkGray
Read-Host | Out-Null
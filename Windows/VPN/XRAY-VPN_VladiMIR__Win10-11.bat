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

# Deploy enhanced TrayVPN with bright green shield icon + IP tooltip
[System.IO.File]::WriteAllBytes("C:\XRAY_VPN\TrayVPN.ps1", [Convert]::FromBase64String('77u/W3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgiU3lzdGVtLldpbmRvd3MuRm9ybXMiKQpbdm9pZF1bU3lzdGVtLlJlZmxlY3Rpb24uQXNzZW1ibHldOjpMb2FkV2l0aFBhcnRpYWxOYW1lKCJTeXN0ZW0uRHJhd2luZyIpCgojIENyZWF0ZSBjcmlzcCBncmVlbiBzaGllbGQgaWNvbiB3aXRoIGJsYWNrIG91dGxpbmUKZnVuY3Rpb24gR2V0LVNoaWVsZEljb24gewogICAgJGdyaWQgPSBAKAogICAgICAgICIuLi4uLi4uLi4uLi4uLi4uIiwKICAgICAgICAiLi4jIyMjIyMjIyMjIyMuLiIsCiAgICAgICAgIi4jSEhISEhISEhISEhIIy4iLAogICAgICAgICIuI0hHR0dHR0dHR0dHSCMuIiwKICAgICAgICAiLiNIR0dHR0dHR0dHR0gjLiIsCiAgICAgICAgIi4jSEdHR0dHR0dHR0dIIy4iLAogICAgICAgICIuI0hHR0dHR0dHR0dHSCMuIiwKICAgICAgICAiLiNIR0dHR0dHR0dHR0gjLiIsCiAgICAgICAgIi4uI0hHR0dHR0dHR0gjLi4iLAogICAgICAgICIuLiNIR0dHR0dHR0dIIy4uIiwKICAgICAgICAiLi4uI0hHR0dHR0dIIy4uLiIsCiAgICAgICAgIi4uLiNIR0dHR0dHSCMuLi4iLAogICAgICAgICIuLi4uI0hHR0dHSCMuLi4uIiwKICAgICAgICAiLi4uLi4jSEdHSCMuLi4uLiIsCiAgICAgICAgIi4uLi4uLiNISCMuLi4uLi4iLAogICAgICAgICIuLi4uLi4uIyMuLi4uLi4uIgogICAgKQogICAgJGJtcCA9IE5ldy1PYmplY3QgU3lzdGVtLkRyYXdpbmcuQml0bWFwIDE2LCAxNiwgKFtTeXN0ZW0uRHJhd2luZy5JbWFnaW5nLlBpeGVsRm9ybWF0XTo6Rm9ybWF0MzJicHBBcmdiKQogICAgJFQgPSBbU3lzdGVtLkRyYXdpbmcuQ29sb3JdOjpUcmFuc3BhcmVudAogICAgJEIgPSBbU3lzdGVtLkRyYXdpbmcuQ29sb3JdOjpGcm9tQXJnYigyNTUsIDEyLCAyOCwgMTIpCiAgICAkSCA9IFtTeXN0ZW0uRHJhd2luZy5Db2xvcl06OkZyb21BcmdiKDI1NSwgNjUsIDI0NSwgOTUpCiAgICAkRyA9IFtTeXN0ZW0uRHJhd2luZy5Db2xvcl06OkZyb21BcmdiKDI1NSwgMCwgMjA1LCA1MCkKICAgIGZvciAoJHkgPSAwOyAkeSAtbHQgMTY7ICR5KyspIHsKICAgICAgICAkcm93ID0gJGdyaWRbJHldCiAgICAgICAgZm9yICgkeCA9IDA7ICR4IC1sdCAxNjsgJHgrKykgewogICAgICAgICAgICAkYyA9IHN3aXRjaCAoJHJvd1skeF0pIHsKICAgICAgICAgICAgICAgICcjJyB7ICRCIH0KICAgICAgICAgICAgICAgICdIJyB7ICRIIH0KICAgICAgICAgICAgICAgICdHJyB7ICRHIH0KICAgICAgICAgICAgICAgIGRlZmF1bHQgeyAkVCB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaWYgKCRjIC1uZSAkVCkgeyAkYm1wLlNldFBpeGVsKCR4LCAkeSwgJGMpIH0KICAgICAgICB9CiAgICB9CiAgICByZXR1cm4gW1N5c3RlbS5EcmF3aW5nLkljb25dOjpGcm9tSGFuZGxlKCRibXAuR2V0SGljb24oKSkKfQoKJG5vdGlmeSA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuTm90aWZ5SWNvbgokbm90aWZ5Lkljb24gPSBHZXQtU2hpZWxkSWNvbgokbm90aWZ5LlZpc2libGUgPSAkdHJ1ZQoKIyBJUCBhbmQgVXNlcm5hbWUgVG9vbHRpcAokb3JpZ0lwID0gIlVua25vd24iCmlmIChUZXN0LVBhdGggIkM6XFhSQVlfVlBOXG9yaWdfaXAudHh0IikgewogICAgdHJ5IHsgJG9yaWdJcCA9IFtTeXN0ZW0uSU8uRmlsZV06OlJlYWRBbGxUZXh0KCJDOlxYUkFZX1ZQTlxvcmlnX2lwLnR4dCIpLlRyaW0oKSB9IGNhdGNoIHt9Cn0KJHVzZXIgPSAkZW52OlVTRVJOQU1FCiRub3RpZnkuVGV4dCA9ICJWUE46IENvbm5lY3RlZGBuT3JpZzogJG9yaWdJcGBuVXNlcjogJHVzZXIiCgokaXBUaW1lciA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuVGltZXIKJGlwVGltZXIuSW50ZXJ2YWwgPSAxMDAwCiRpcFRpbWVyLmFkZF9UaWNrKHsKICAgICR2cG5JcCA9IHRyeSB7IChOZXctT2JqZWN0IE5ldC5XZWJDbGllbnQpLkRvd25sb2FkU3RyaW5nKCJodHRwOi8vYXBpLmlwaWZ5Lm9yZyIpLlRyaW0oKSB9IGNhdGNoIHsgIiIgfQogICAgaWYgKCR2cG5JcCkgewogICAgICAgICRpcFRpbWVyLkludGVydmFsID0gMzAwMDAKICAgICAgICAkc3RyID0gIlZQTjogJHZwbklwYG5PcmlnOiAkb3JpZ0lwYG5Vc2VyOiAkdXNlciIKICAgICAgICBpZiAoJHN0ci5MZW5ndGggLWd0IDYzKSB7ICRzdHIgPSAkc3RyLlN1YnN0cmluZygwLCA2MCkgKyAiLi4uIiB9CiAgICAgICAgJG5vdGlmeS5UZXh0ID0gJHN0cgogICAgfQp9KQokaXBUaW1lci5TdGFydCgpCgokbWVudSA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuQ29udGV4dE1lbnUKJGl0ZW1TdGF0dXMgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLk1lbnVJdGVtICJYcmF5IFZQTjogQ29ubmVjdGVkIgokaXRlbVN0YXR1cy5FbmFibGVkID0gJGZhbHNlCiRpdGVtU2VwID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZW51SXRlbSAiLSIKJGl0ZW1TdG9wID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZW51SXRlbSAiRGlzY29ubmVjdCAmJiBFeGl0IgoKJGl0ZW1TdG9wLmFkZF9DbGljayh7CiAgICAkbm90aWZ5LlZpc2libGUgPSAkZmFsc2UKICAgICRub3RpZnkuRGlzcG9zZSgpCiAgICBTdGFydC1Qcm9jZXNzICJ3c2NyaXB0LmV4ZSIgLUFyZ3VtZW50TGlzdCAnIkM6XFhSQVlfVlBOXFN0b3BfVlBOLnZicyInIC1XaW5kb3dTdHlsZSBIaWRkZW4KICAgIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5BcHBsaWNhdGlvbl06OkV4aXQoKQp9KQoKW3ZvaWRdJG1lbnUuTWVudUl0ZW1zLkFkZCgkaXRlbVN0YXR1cykKW3ZvaWRdJG1lbnUuTWVudUl0ZW1zLkFkZCgkaXRlbVNlcCkKW3ZvaWRdJG1lbnUuTWVudUl0ZW1zLkFkZCgkaXRlbVN0b3ApCiRub3RpZnkuQ29udGV4dE1lbnUgPSAkbWVudQoKIyBXYXRjaGRvZzogaWYgeHJheS5leGUgZGllcywgY2xvc2UgdHJheSB0b28KJHRpbWVyID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5UaW1lcgokdGltZXIuSW50ZXJ2YWwgPSAyMDAwCiR0aW1lci5hZGRfVGljayh7CiAgICAkcHJvYyA9IEdldC1Qcm9jZXNzIHhyYXkgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUKICAgIGlmICgtbm90ICRwcm9jKSB7CiAgICAgICAgJHRpbWVyLlN0b3AoKQogICAgICAgICRub3RpZnkuVmlzaWJsZSA9ICRmYWxzZQogICAgICAgICRub3RpZnkuRGlzcG9zZSgpCiAgICAgICAgW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkFwcGxpY2F0aW9uXTo6RXhpdCgpCiAgICB9Cn0pCiR0aW1lci5TdGFydCgpCgokbm90aWZ5LlNob3dCYWxsb29uVGlwKDMwMDAsICJYcmF5IFZQTiIsICJDb25uZWN0ZWQhIFNoaWVsZCBhY3RpdmUgaW4gdHJheS4iLCBbU3lzdGVtLldpbmRvd3MuRm9ybXMuVG9vbFRpcEljb25dOjpJbmZvKQpbU3lzdGVtLldpbmRvd3MuRm9ybXMuQXBwbGljYXRpb25dOjpSdW4oKQ=='))

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
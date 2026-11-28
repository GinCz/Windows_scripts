# Unmount MEGA Cloud Drive M:
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Disconnect MEGA Cloud (Drive M:)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Disconnect network drive M:
Write-Host "1. Disconnecting drive M: ..." -ForegroundColor Yellow
net use M: /delete /yes 2>$null | Out-Null

# 2. Stop WebDAV in MEGAcmd
Write-Host "2. Stopping WebDAV server..." -ForegroundColor Yellow
$megaClient = "$env:LOCALAPPDATA\MEGAcmd\MegaClient.exe"
& $megaClient webdav -d --all 2>&1 | Out-Null

Write-Host "[SUCCESS] Drive M: disconnected, WebDAV stopped." -ForegroundColor Green

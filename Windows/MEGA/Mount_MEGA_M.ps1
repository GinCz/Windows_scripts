# Mount MEGA Cloud Drive as M:
param (
    [string]$Password = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Mount MEGA Cloud Storage as Drive M:" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Optional password check (prompt if needed)
# Set your desired verification password below, or leave empty to disable
$configuredPass = ""
if ($configuredPass) {
    if (-not $Password) {
        $securePass = Read-Host "Enter disk access password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

    if ($Password -ne $configuredPass) {
        Write-Host "[ERROR] Incorrect password!" -ForegroundColor Red
        Pause
        exit 1
    }
}

$megaClient = "$env:LOCALAPPDATA\MEGAcmd\MegaClient.exe"

# Ensure MEGAcmdServer is running in current user session
$serverProc = Get-Process MEGAcmdServer -ErrorAction SilentlyContinue
if (-not $serverProc) {
    Write-Host "Starting background MEGAcmdServer..." -ForegroundColor Yellow
    Start-Process "$env:LOCALAPPDATA\MEGAcmd\MEGAcmdServer.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 4
}

Write-Host "1. Getting WebDAV server status..." -ForegroundColor Yellow
$webdavOutput = & $megaClient webdav 2>&1 | Out-String

# If not running or not found, start WebDAV
if ($webdavOutput -notmatch "http://") {
    Write-Host "Starting WebDAV service..." -ForegroundColor Yellow
    $webdavOutput = & $megaClient webdav / 2>&1 | Out-String
    
    if ($webdavOutput -notmatch "http://") {
        Start-Sleep -Seconds 2
        $webdavOutput = & $megaClient webdav / 2>&1 | Out-String
    }
}

Write-Host "$webdavOutput"

# Extract URL
$match = [regex]::Match($webdavOutput, "http://[^\s\r\n]+")
if ($match.Success) {
    $url = $match.Value
    Write-Host "2. Connecting drive M: to $url ..." -ForegroundColor Yellow
    
    # Remove old drive M: if exists
    net use M: /delete /yes 2>$null | Out-Null
    
    # Connect network drive
    net use M: $url /persistent:no
    
    Start-Sleep -Seconds 2
    if (Test-Path "M:\") {
        Write-Host "[SUCCESS] Drive M: connected successfully!" -ForegroundColor Green
        Start-Process "explorer.exe" "M:\"
    } else {
        Write-Host "[INFO] net use command executed. Drive M: should appear in 'This PC'." -ForegroundColor Green
    }
} else {
    Write-Host "[ERROR] Failed to get WebDAV URL from MEGAcmd." -ForegroundColor Red
}

Write-Host "`nTo disconnect drive, run Unmount_MEGA_M.bat or right-click Drive M: -> Disconnect." -ForegroundColor Cyan

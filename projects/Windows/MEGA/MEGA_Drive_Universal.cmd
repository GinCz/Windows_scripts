<# :
@echo off
setlocal
chcp 65001 >nul
cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"
pause
exit /b %errorlevel%
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Header {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "   MEGA Cloud Universal Network Drive (Drive M:)      " -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Ensure-MEGAcmdInstalled {
    $clientPath = "$env:LOCALAPPDATA\MEGAcmd\MegaClient.exe"
    if (Test-Path $clientPath) {
        return $clientPath
    }
    
    Write-Host "[INFO] MEGAcmd is not installed on this PC. Installing automatically..." -ForegroundColor Yellow
    $setupPath = "$env:TEMP\MEGAcmdSetup64.exe"
    
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        curl.exe -L -o "$setupPath" "https://mega.nz/MEGAcmdSetup64.exe"
    } else {
        Invoke-WebRequest -Uri "https://mega.nz/MEGAcmdSetup64.exe" -OutFile "$setupPath" -UseBasicParsing
    }
    
    if (Test-Path $setupPath) {
        Write-Host "Running silent installation..." -ForegroundColor Yellow
        Start-Process "$setupPath" -ArgumentList "/S" -Wait
        Start-Sleep -Seconds 5
        Remove-Item "$setupPath" -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path $clientPath) {
        Write-Host "[SUCCESS] MEGAcmd installed successfully in user profile!" -ForegroundColor Green
        $env:Path += ";$env:LOCALAPPDATA\MEGAcmd"
        return $clientPath
    } else {
        Write-Host "[ERROR] Failed to install MEGAcmd automatically." -ForegroundColor Red
        return $null
    }
}

function Ensure-ServerRunning {
    param($clientPath)
    Get-Service WebClient -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne "Running" } | Start-Service -ErrorAction SilentlyContinue

    $proc = Get-Process MEGAcmdServer -ErrorAction SilentlyContinue
    if (-not $proc) {
        Write-Host "Starting background MEGAcmdServer..." -ForegroundColor Yellow
        Start-Process "$env:LOCALAPPDATA\MEGAcmd\MEGAcmdServer.exe" -WindowStyle Hidden
        Start-Sleep -Seconds 4
    }
}

function Mount-DriveM {
    param($clientPath)
    Write-Host "`n1. Checking WebDAV server status..." -ForegroundColor Yellow
    $webdavOutput = & $clientPath webdav 2>&1 | Out-String
    
    if ($webdavOutput -notmatch "http://") {
        Write-Host "Starting WebDAV stream..." -ForegroundColor Yellow
        $webdavOutput = & $clientPath webdav / 2>&1 | Out-String
        if ($webdavOutput -notmatch "http://") {
            Start-Sleep -Seconds 2
            $webdavOutput = & $clientPath webdav / 2>&1 | Out-String
        }
    }
    
    $match = [regex]::Match($webdavOutput, "http://[^\s\r\n]+")
    if ($match.Success) {
        $url = $match.Value
        Write-Host "2. Connecting network drive M: to $url ..." -ForegroundColor Yellow
        
        net use M: /delete /yes 2>$null | Out-Null
        net use M: $url /persistent:no
        
        Start-Sleep -Seconds 2
        if (Test-Path "M:\") {
            Write-Host "`n[SUCCESS] Drive M: connected successfully!" -ForegroundColor Green
            Start-Process "explorer.exe" "M:\"
        } else {
            Write-Host "`n[INFO] net use command executed. Check Drive M: in 'This PC'." -ForegroundColor Green
        }
    } else {
        Write-Host "`n[ERROR] Failed to get WebDAV URL: $webdavOutput" -ForegroundColor Red
    }
}

function Unmount-DriveM {
    param($clientPath)
    Write-Host "`nDisconnecting Drive M: ..." -ForegroundColor Yellow
    net use M: /delete /yes 2>$null | Out-Null
    
    if (Test-Path $clientPath) {
        & $clientPath webdav -d --all 2>&1 | Out-Null
    }
    Write-Host "[SUCCESS] Drive M: disconnected, WebDAV stopped." -ForegroundColor Green
}

# MAIN EXECUTION
$client = Ensure-MEGAcmdInstalled
if (-not $client) {
    Pause
    exit 1
}

Ensure-ServerRunning $client

Show-Header

$whoami = (& $client whoami 2>&1 | Out-String).Trim()
if ($whoami -match "Account e-mail:\s*([^\s]+)") {
    Write-Host "Current active account: $($matches[1])" -ForegroundColor Green
} else {
    Write-Host "Current status: Not logged in" -ForegroundColor DarkGray
}

Write-Host "`nSelect an option:" -ForegroundColor White
Write-Host " [1] Mount currently logged in account as Drive M:" -ForegroundColor Cyan
Write-Host " [2] Log in with another account (supports 2FA / TOTP)" -ForegroundColor Cyan
Write-Host " [3] Disconnect Drive M: (Unmount)" -ForegroundColor Yellow
Write-Host " [4] View storage quota (mega-df)" -ForegroundColor White
Write-Host " [0] Exit" -ForegroundColor DarkGray
Write-Host ""

$choice = Read-Host "Your choice [1-4, 0]"

switch ($choice) {
    "1" {
        Mount-DriveM $client
    }
    "2" {
        Write-Host "`n--- Login to MEGA Account ---" -ForegroundColor Cyan
        $customEmail = Read-Host "Enter Email"
        $secPass = Read-Host "Enter Password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass)
        $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        $code2FA = Read-Host "If 2FA is enabled, enter 6-digit Authenticator code (or press Enter if disabled)"
        
        Write-Host "Logging into MEGA..." -ForegroundColor Yellow
        if ($code2FA -and ($code2FA.Trim() -ne "")) {
            $loginRes = & $client login "--auth-code=$($code2FA.Trim())" $customEmail $plainPass 2>&1 | Out-String
        } else {
            $loginRes = & $client login $customEmail $plainPass 2>&1 | Out-String
        }
        
        if ($loginRes -match "ERR" -or $loginRes -match "Error") {
            Write-Host "[LOGIN ERROR] $loginRes" -ForegroundColor Red
        } else {
            Write-Host "[SUCCESS] Logged in successfully!" -ForegroundColor Green
            Mount-DriveM $client
        }
    }
    "3" {
        Unmount-DriveM $client
    }
    "4" {
        Write-Host ""
        & $client df -h
    }
    default {
        Write-Host "Exiting." -ForegroundColor DarkGray
    }
}
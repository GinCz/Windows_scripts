function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs WinGet if not already installed.

    .DESCRIPTION
        Installs WinGet with all required dependencies silently and robustly.
    #>
    param(
        [switch]$Force
    )

    if (-not $Force -and (Test-WinUtilPackageManager -winget) -eq "installed") {
        return
    }

    if ($Force) {
        Write-Host "Repairing the WinGet installation..." -ForegroundColor Yellow
    } else {
        Write-Host "WinGet is not installed. Installing now..." -ForegroundColor Red
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

    $tempDir = Join-Path $env:TEMP "WinGet_Setup"
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

    $vclibsPath = Join-Path $tempDir "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $xamlPath   = Join-Path $tempDir "Microsoft.UI.Xaml.2.8.x64.appx"
    $wingetPath = Join-Path $tempDir "Microsoft.DesktopAppInstaller.msixbundle"
    $sourcePath = Join-Path $tempDir "source.msix"

    try {
        if (-not (Test-Path $vclibsPath) -or (Get-Item $vclibsPath).Length -lt 1000000) {
            Write-Host "Downloading VCLibs dependency..." -ForegroundColor Cyan
            curl.exe -4 -s -L "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -o $vclibsPath
        }
        if (-not (Test-Path $xamlPath) -or (Get-Item $xamlPath).Length -lt 1000000) {
            Write-Host "Downloading UI.Xaml dependency..." -ForegroundColor Cyan
            curl.exe -4 -s -L "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" -o $xamlPath
        }
        if (-not (Test-Path $wingetPath) -or (Get-Item $wingetPath).Length -lt 10000000) {
            Write-Host "Downloading WinGet package..." -ForegroundColor Cyan
            curl.exe -4 -s -L "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -o $wingetPath
        }

        Write-Host "Installing WinGet Appx packages..." -ForegroundColor Cyan
        Add-AppxPackage -Path $vclibsPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $xamlPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $wingetPath -DependencyPath @($vclibsPath, $xamlPath) -ErrorAction SilentlyContinue

        # Refresh local PATH
        $localApps = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        if (Test-Path (Join-Path $localApps "winget.exe")) {
            if ($env:Path -notlike "*$localApps*") {
                $env:Path = "$localApps;$env:Path"
            }
        }

        # Configure settings.json to disable autoUpdateIntervalInMinutes to prevent network hangs
        $settingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
        if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
        $settingsFile = Join-Path $settingsDir "settings.json"
        $cfg = '{"$schema":"https://aka.ms/winget-settings.schema.json","source":{"autoUpdateIntervalInMinutes":0}}'
        Set-Content -Path $settingsFile -Value $cfg -Encoding UTF8 -Force

        # Initialize source index directly if not registered yet
        if (-not (Test-Path $sourcePath) -or (Get-Item $sourcePath).Length -lt 1000000) {
            curl.exe -4 -s -L "https://cdn.winget.microsoft.com/cache/source.msix" -o $sourcePath
        }
        if (Test-Path $sourcePath) {
            Add-AppxPackage -Path $sourcePath -ErrorAction SilentlyContinue
        }

        Write-Host "WinGet successfully installed and initialized!" -ForegroundColor Green
    } catch {
        Write-Host "Direct WinGet install failed, trying PowerShellGet fallback: $_" -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction SilentlyContinue
        Install-Module -Name Microsoft.WinGet.Client -Force -Confirm:$false -Scope CurrentUser -ErrorAction SilentlyContinue
        Repair-WinGetPackageManager -AllUsers -ErrorAction SilentlyContinue
    }
}

@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title GIN-Wallpaper-Calend Installer & Launcher

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GIN-Wallpaper-Calend v001 — Установка"

Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host "             GIN-Wallpaper-Calend v001 — Установка и Настройка                 " -ForegroundColor Yellow
Write-Host "          Умные обои с русским календарём для Windows by VladiMIR+AI           " -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host ""

$progFiles = $env:ProgramFiles
if (-not $progFiles) { $progFiles = "C:\Program Files" }
$targetDir = Join-Path $progFiles "GIN-Wallpaper-Calend"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$desktopPath = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs"

Write-Host "[1/5] Закрытие предыдущих экземпляров..." -ForegroundColor Cyan
Get-Process -Name "GIN-Wallpaper-Calend" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[2/5] Загрузка компонентов с GitHub..." -ForegroundColor Cyan
$repoBase = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper"
$files = @(
    "gin_wallpaper.py",
    "version.json",
    "GIN-Wallpaper-Calend_v001_Setup.exe"
)

foreach ($f in $files) {
    $dest = Join-Path $targetDir $f
    $url = "$repoBase/$f"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "GIN-Wallpaper-Installer")
        $wc.DownloadFile($url, $dest)
        Write-Host "  -> Загружен: $f" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Ошибка загрузки $f : $_" -ForegroundColor DarkYellow
    }
}

Copy-Item -Path (Join-Path $targetDir "GIN-Wallpaper-Calend_v001_Setup.exe") -Destination (Join-Path $targetDir "Uninstall.exe") -Force -ErrorAction SilentlyContinue

Write-Host "[3/5] Проверка библиотек Python (Pillow, pystray)..." -ForegroundColor Cyan
Start-Process -FilePath "cmd.exe" -ArgumentList "/c pip install Pillow pystray requests --quiet" -Wait -WindowStyle Hidden

Write-Host "[4/5] Создание VBS-лаунчера без консоли..." -ForegroundColor Cyan
$scriptPath = Join-Path $targetDir "gin_wallpaper.py"
$vbsPath = Join-Path $targetDir "launcher.vbs"
$vbsContent = "Set WshShell = CreateObject(`"WScript.Shell`")`r`nWshShell.Run `"pythonw.exe `"`"`"$scriptPath`"`"`"`, 0, False`r`n"
[System.IO.File]::WriteAllText($vbsPath, $vbsContent, [System.Text.Encoding]::UTF8)

# Регистрация в реестре (Add/Remove Programs)
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "GIN-Wallpaper-Calend — Умные обои с календарём"
    Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "v001"
    Set-ItemProperty -Path $regPath -Name "Publisher" -Value "VladiMIR+AI (Vladimir Bulantsev)"
    Set-ItemProperty -Path $regPath -Name "InstallLocation" -Value $targetDir
    Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "`"$targetDir\Uninstall.exe`" --uninstall"
    Set-ItemProperty -Path $regPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $regPath -Name "NoRepair" -Value 1 -Type DWord
} catch {}

# Автозагрузка
try {
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $runPath -Name "GIN-Wallpaper-Calend" -Value "wscript.exe `"$vbsPath`""
} catch {}

Write-Host "[5/5] Создание ярлыков..." -ForegroundColor Cyan
$w = New-Object -ComObject WScript.Shell

# Ярлык на Рабочем столе
$dtLnk = $w.CreateShortcut((Join-Path $desktopPath "GIN-Wallpaper-Calend.lnk"))
$dtLnk.TargetPath = "wscript.exe"
$dtLnk.Arguments = "`"$vbsPath`""
$dtLnk.WorkingDirectory = $targetDir
$dtLnk.Description = "Умные обои с русским календарём"
$dtLnk.Save()

# Ярлык в меню Пуск
if (Test-Path $startMenu) {
    $smLnk = $w.CreateShortcut((Join-Path $startMenu "GIN-Wallpaper-Calend.lnk"))
    $smLnk.TargetPath = "wscript.exe"
    $smLnk.Arguments = "`"$vbsPath`""
    $smLnk.WorkingDirectory = $targetDir
    $smLnk.Description = "Умные обои с русским календарём"
    $smLnk.Save()
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host " [+] УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!" -ForegroundColor Green
Write-Host " Программа установлена в: $targetDir" -ForegroundColor White
Write-Host " Ярлык создан на Рабочем столе: $(Join-Path $desktopPath 'GIN-Wallpaper-Calend.lnk')" -ForegroundColor White
Write-Host " Запуск обоев в фоновом режиме..." -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Green

Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`"" -WorkingDirectory $targetDir

Start-Sleep -Seconds 2
Write-Host ""
Write-Host "Программа работает в системном трее (в правом нижнем углу возле часов)." -ForegroundColor Yellow
Write-Host "Двойной клик по иконке мгновенно обновит обои и календарь." -ForegroundColor Yellow
Write-Host ""
Write-Host "Нажмите любую клавишу для закрытия..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

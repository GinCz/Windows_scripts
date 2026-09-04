@echo off
:: ==============================================================================
:: Universal Installer for ChatGPT / OpenAI Codex (Windows 10 / 11)
:: Auto-Elevate to Administrator & Direct Install without Microsoft Store GUI
:: Author: VladiMIR Bulantsev (GinCz) | https://github.com/GinCz/Windows_scripts
:: ==============================================================================
cls
chcp 65001 >nul

:: Проверка прав Администратора и автоматический перезапуск с повышением прав
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Запрос прав Администратора (UAC)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

title Установка ChatGPT Codex (OpenAI Agent) - Администратор
cd /d "%~dp0"

echo ==============================================================================
echo   Установка официального ChatGPT Codex на Windows (Автономный установщик)
echo   Автор: VladiMIR Bulantsev (GinCz) | GitHub: https://github.com/GinCz
echo ==============================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$ErrorActionPreference = 'Stop'; " ^
"[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; " ^
"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
"function Install-Codex { " ^
"    Write-Host '[1/4] Поиск официального пакета OpenAI Codex в Microsoft Store CDN...' -ForegroundColor Cyan; " ^
"    $url = 'https://store.rg-adguard.net/api/GetFiles'; " ^
"    $body = 'type=ProductId&url=9PLM9XGG6VKS&ring=RP'; " ^
"    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body); " ^
"    $req = [System.Net.HttpWebRequest]::Create($url); " ^
"    $req.Method = 'POST'; " ^
"    $req.ContentType = 'application/x-www-form-urlencoded'; " ^
"    $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'; " ^
"    $req.Headers.Add('Origin', 'https://store.rg-adguard.net'); " ^
"    $req.Referer = 'https://store.rg-adguard.net/'; " ^
"    $req.ContentLength = $bytes.Length; " ^
"    $stream = $req.GetRequestStream(); " ^
"    $stream.Write($bytes, 0, $bytes.Length); " ^
"    $stream.Close(); " ^
"    $resp = $req.GetResponse(); " ^
"    $reader = New-Object System.IO.StreamReader($resp.GetResponseStream()); " ^
"    $html = $reader.ReadToEnd(); " ^
"    $reader.Close(); " ^
"    $resp.Close(); " ^
"    $matches = [regex]::Matches($html, '<a href=\"\"([^\"\"]+)\"\"[^>]*>([^<]+)</a>'); " ^
"    $targetLink = $null; $targetName = $null; " ^
"    foreach ($m in $matches) { " ^
"        $fname = $m.Groups[2].Value; " ^
"        if ($fname -like '*OpenAI*' -and ($fname -like '*msixbundle*' -or $fname -like '*x64.msix*')) { " ^
"            $targetLink = $m.Groups[1].Value; " ^
"            $targetName = $fname; " ^
"            break; " ^
"        } " ^
"    } " ^
"    if (-not $targetLink) { " ^
"        Write-Host '[ВНИМАНИЕ] Прямой поиск пакета не удался, пробуем установку через WinGet...' -ForegroundColor Yellow; " ^
"        winget install --id 9PLM9XGG6VKS --source msstore --accept-source-agreements --accept-package-agreements; " ^
"        return; " ^
"    } " ^
"    $dest = Join-Path $env:TEMP $targetName; " ^
"    Write-Host \"[2/4] Скачивание официального пакета: $targetName...\" -ForegroundColor Cyan; " ^
"    $wc = New-Object System.Net.WebClient; " ^
"    $wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'); " ^
"    $wc.DownloadFile($targetLink, $dest); " ^
"    $sizeMB = ((Get-Item $dest).Length / 1MB).ToString('0.00'); " ^
"    Write-Host \"[OK] Файл успешно скачан ($sizeMB MB)\" -ForegroundColor Green; " ^
"    Write-Host '[3/4] Развертывание приложения OpenAI Codex в систему (Add-AppxPackage)...' -ForegroundColor Cyan; " ^
"    Add-AppxPackage -Path $dest -ErrorAction Stop; " ^
"    Write-Host '[4/4] Очистка временных файлов...' -ForegroundColor Cyan; " ^
"    Remove-Item $dest -Force -ErrorAction SilentlyContinue; " ^
"    Write-Host '[ГОТОВО] ChatGPT Codex успешно установлен и готов к работе!' -ForegroundColor Green; " ^
"}; " ^
"try { Install-Codex } catch { Write-Host \"[ОШИБКА] $($_.Exception.Message)\" -ForegroundColor Red; exit 1 }"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ОШИБКА] Во время установки произошел сбой.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ==============================================================================
echo   УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!
echo   Приложение доступно в меню «Пуск» (Start Menu) - OpenAI Codex / ChatGPT.
echo ==============================================================================
echo.

powershell -NoProfile -Command "if (Test-Path 'C:\Windows\Media\chimes.wav') { (New-Object System.Media.SoundPlayer 'C:\Windows\Media\chimes.wav').PlaySync() }"

pause

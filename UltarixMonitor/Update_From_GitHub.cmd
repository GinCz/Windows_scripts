@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: ULTARIX s.r.o. - 1-Click Update From GitHub (All-in-One Updater)
:: Author  : VladiMIR + Antigravity AI
:: Version : v2.3.0 (2026-11)
:: Target  : C:\UTIL\UltarixMonitor (Server ULPS1 & Admin PCs)
:: ============================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c pushd \"\"%~dp0\"\" && \"\"%~f0\"\" admin' -Verb RunAs"
    exit /b
)

title ULTARIX - Aktualizace monitoringu z GitHub [VladiMIR + Antigravity]

pushd "%~dp0" 2>nul
set "TARGET_DIR=%~dp0"
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"

echo ================================================================================
echo       ULTARIX s.r.o. - Automaticka aktualizace souboru z GitHub
echo ================================================================================
echo Cilova slozka : %TARGET_DIR%
echo Repozitar     : GinCz/Windows_scripts (vetev main)
echo ================================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$target = '%TARGET_DIR%';" + ^
"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" + ^
"$baseUri = 'https://raw.githubusercontent.com/GinCz/Windows_scripts/main/UltarixMonitor';" + ^
"$files = @('dashboard.html', '0_Server_Setup.cmd', '1_Client_Install.cmd', '2_Ulyana_Dashboard.cmd', 'employees.json', 'README.md', 'Update_From_GitHub.cmd');" + ^
"foreach ($f in $files) {" + ^
"    $url = \"$baseUri/$f?v=\" + [DateTime]::UtcNow.Ticks;" + ^
"    $dest = \"$target\$f\";" + ^
"    try {" + ^
"        $wc = New-Object System.Net.WebClient;" + ^
"        $wc.Headers.Add('User-Agent', 'Mozilla/5.0');" + ^
"        $bytes = $wc.DownloadData($url);" + ^
"        if ($bytes.Length -gt 100) {" + ^
"            [System.IO.File]::WriteAllBytes($dest, $bytes);" + ^
"            Write-Host (\"    [OK] {0,-25} : Stazeno ({1} B)\" -f $f, $bytes.Length) -ForegroundColor Green;" + ^
"        } else {" + ^
"            Write-Host (\"    [-] {0,-25} : Soubor je prilis maly nebo prazdny\" -f $f) -ForegroundColor Yellow;" + ^
"        }" + ^
"    } catch {" + ^
"        Write-Host (\"    [!] {0,-25} : Chyba stahovani: {1}\" -f $f, $_.Exception.Message) -ForegroundColor Red;" + ^
"    }" + ^
"}"

echo.
echo ================================================================================
echo       AKTUALIZACE Z GITHUB BYLA USPESNE DOKONCENA!
echo ================================================================================
echo  Vsechny skripty, dashboard.html a nastaveni byly prepsany na nejnovejsi verzi.
echo  Vase ulozene logy v podslozce \logs zustaly nedotceny.
echo ================================================================================
echo.

popd 2>nul
if /i not "%~1"=="-silent" if /i not "%~1"=="/silent" (
    pause
)
exit /b 0

@echo off
chcp 65001 >nul
cls

:: ════════════════════════════════════════════════════════════════
::  GIN-Wallpaper-Calend v001 — Build Setup EXE
::  Собирает: GIN-Wallpaper-Calend_v001_Setup.exe
::  Запускать от имени Администратора на Windows
:: ════════════════════════════════════════════════════════════════

set "APP_NAME=GIN-Wallpaper-Calend"
set "VERSION=v001"
set "OUT_EXE=%APP_NAME%_%VERSION%_Setup.exe"

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   GIN-Wallpaper-Calend %VERSION% — Build Setup EXE    ║
echo  ║   github.com/GinCz/Windows_scripts/GIN-Wallpaper     ║
echo  ╚══════════════════════════════════════════════════════╝
echo.

:: ── Поиск csc.exe ────────────────────────────────────────────────────────────
set "CSC="
for %%p in (
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) do (
    if exist %%p set "CSC=%%p"
)
:: Также ищем Roslyn / MSBuild csc
for /f "delims=" %%i in ('where csc 2^>nul') do set "CSC=%%i"

if "%CSC%"=="" (
    echo [ERROR] csc.exe не найден!
    echo Убедитесь что установлен .NET Framework 4.x
    echo.
    echo Попытка использовать PowerShell fallback...
    goto :PS_BUILD
)

echo [1/3] Компилятор найден: %CSC%
echo.

:: ── Шаг 1: Скачать иконку (если нет) ────────────────────────────────────────
if not exist "assets\icon.ico" (
    echo [*] Загрузка иконки...
    powershell -NoProfile -Command ^
        "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/assets/icon.ico' -OutFile 'assets\icon.ico' -UseBasicParsing" 2>nul
)

:: ── Шаг 2: Компиляция Setup EXE через csc ────────────────────────────────────
echo [2/3] Компиляция %OUT_EXE%...
echo.

%CSC% ^
    /target:winexe ^
    /out:"%OUT_EXE%" ^
    /reference:System.Windows.Forms.dll ^
    /reference:System.Drawing.dll ^
    /reference:System.dll ^
    /reference:Microsoft.Win32.Registry.dll ^
    /optimize+ ^
    /warn:0 ^
    installer_setup.cs

if errorlevel 1 (
    echo.
    echo [ERROR] Компиляция не удалась!
    pause
    exit /b 1
)

echo.
echo [3/3] Проверка артефакта...
if not exist "%OUT_EXE%" (
    echo [ERROR] Файл не создан!
    pause
    exit /b 1
)

for %%A in ("%OUT_EXE%") do (
    echo.
    echo ════════════════════════════════════════════
    echo  ✅ ГОТОВО!
    echo ════════════════════════════════════════════
    echo  Файл:   %OUT_EXE%
    echo  Размер: %%~zA байт
    echo ════════════════════════════════════════════
)

echo.
set /p LAUNCH=Запустить установщик сейчас? [Y/N]: 
if /i "%LAUNCH%"=="Y" start "" "%OUT_EXE%"
pause
exit /b 0

:: ── PowerShell fallback (если нет csc) ───────────────────────────────────────
:PS_BUILD
echo [2/3] Сборка через PowerShell Add-Type...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "
    \$ErrorActionPreference = 'Stop'
    \$src = Get-Content -Path 'installer_setup.cs' -Raw -Encoding UTF8
    Add-Type -TypeDefinition \$src ^
        -ReferencedAssemblies 'System.Windows.Forms','System.Drawing','Microsoft.Win32.Registry' ^
        -OutputAssembly '%OUT_EXE%' ^
        -OutputType WindowsApplication
    Write-Host ' Сборка завершена: %OUT_EXE%' -ForegroundColor Green
"

if errorlevel 1 (
    echo [ERROR] PowerShell сборка не удалась!
    pause
    exit /b 1
)

echo.
echo ════════════════════════════════════════════
echo  ✅ ГОТОВО: %OUT_EXE%
echo ════════════════════════════════════════════
pause

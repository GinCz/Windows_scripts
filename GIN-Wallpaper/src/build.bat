@echo off
chcp 65001 >nul
echo ═══════════════════════════════════════════
echo   GIN-Wallpaper v001 — Сборка EXE
echo ═══════════════════════════════════════════

:: Проверка Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python не найден! Установите Python 3.11+
    pause & exit /b 1
)

:: Установка зависимостей
echo [1/3] Установка зависимостей...
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

:: Сборка EXE
echo [2/3] Сборка EXE (PyInstaller)...
pyinstaller --noconfirm --onefile --windowed ^
    --name "GIN-Wallpaper_v001" ^
    --icon "assets\icon.ico" ^
    --add-data "assets;assets" ^
    --hidden-import "PIL._tkinter_finder" ^
    --hidden-import "pystray._win32" ^
    gin_wallpaper.py

:: Копируем в корень
echo [3/3] Копирование артефакта...
if exist "dist\GIN-Wallpaper_v001.exe" (
    copy /Y "dist\GIN-Wallpaper_v001.exe" "GIN-Wallpaper_v001.exe"
    echo.
    echo ✅ Готово: GIN-Wallpaper_v001.exe
) else (
    echo [ERROR] Сборка не удалась!
)

pause

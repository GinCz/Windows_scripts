@echo off
:: Установить в автозагрузку Windows
set "SCRIPT=%~dp0gin_wallpaper.py"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP%\GIN-Wallpaper.lnk"

powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $s = $ws.CreateShortcut('%SHORTCUT%'); ^
   $s.TargetPath = 'pythonw.exe'; ^
   $s.Arguments = '%SCRIPT%'; ^
   $s.WorkingDirectory = '%~dp0'; ^
   $s.WindowStyle = 7; ^
   $s.Save()"

echo ✅ GIN-Wallpaper добавлен в автозагрузку!
echo Путь: %SHORTCUT%
pause

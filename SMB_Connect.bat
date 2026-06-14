@echo off
cls
chcp 65001 >nul

:: ==========================================================================================
:: FILE    : SMB_Connect.bat
:: VERSION : v2026.06.14
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Параллельное монтирование всех Samba-хранилищ инфраструктуры gincz.com.
::   Пользователь: vlad / sa4434
::
::   Диски:
::     A: — AWS_42        3.79.14.42
::     E: — IONOS_38      82.223.116.38
::     I: — ILYA_176      146.103.110.176
::     N: — PILIK_178     91.84.118.178
::     O: — 4TON_237      144.124.228.237
::     Q: — SO_38         144.124.233.38
::     T: — TATRA_9       144.124.232.9
::     V: — SHAHIN_227    144.124.228.227
::     W: — STOLB_24      144.124.239.24
::     Y: — ALEX_47       109.234.38.47
:: ==========================================================================================

set "ESC="
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "CYAN=%ESC%[96m"
set "YELLOW=%ESC%[93m"
set "GREEN=%ESC%[92m"
set "RESET=%ESC%[0m"

echo %CYAN%==========================================================================================%RESET%
echo %YELLOW%                  ПОДКЛЮЧЕНИЕ СЕТЕВЫХ ХРАНИЛИЩ (v.2026.06.14)                         %RESET%
echo %CYAN%==========================================================================================%RESET%
echo.
echo %YELLOW%[ STATUS ]%RESET% Сохранение учётных данных в системе...

cmdkey /add:3.79.14.42       /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:82.223.116.38    /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:109.234.38.47    /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.228.237  /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.232.9    /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.228.227  /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.239.24   /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:91.84.118.178    /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:146.103.110.176  /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.233.38   /user:vlad /pass:sa4434 >nul 2>&1

echo %YELLOW%[ STATUS ]%RESET% Учётные данные сохранены. Запуск параллельного подключения дисков...
echo %CYAN%------------------------------------------------------------------------------------------%RESET%

start /b cmd /c "ping -n 1 -w 800 3.79.14.42       >nul 2>&1 && net use A: \\3.79.14.42\soft       /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##3.79.14.42#soft\"       /v _LabelFromReg /t REG_SZ /d \"AWS_42\"      /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 3.79.14.42 (AWS_42)"
start /b cmd /c "ping -n 1 -w 800 82.223.116.38     >nul 2>&1 && net use E: \\82.223.116.38\soft     /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##82.223.116.38#soft\"     /v _LabelFromReg /t REG_SZ /d \"IONOS_38\"    /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 82.223.116.38 (IONOS_38)"
start /b cmd /c "ping -n 1 -w 800 109.234.38.47     >nul 2>&1 && net use Y: \\109.234.38.47\soft     /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##109.234.38.47#soft\"     /v _LabelFromReg /t REG_SZ /d \"ALEX_47\"     /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 109.234.38.47 (ALEX_47)"
start /b cmd /c "ping -n 1 -w 800 144.124.228.237   >nul 2>&1 && net use O: \\144.124.228.237\soft   /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.237#soft\"   /v _LabelFromReg /t REG_SZ /d \"4TON_237\"    /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 144.124.228.237 (4TON_237)"
start /b cmd /c "ping -n 1 -w 800 144.124.232.9     >nul 2>&1 && net use T: \\144.124.232.9\soft     /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.232.9#soft\"     /v _LabelFromReg /t REG_SZ /d \"TATRA_9\"     /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 144.124.232.9 (TATRA_9)"
start /b cmd /c "ping -n 1 -w 800 144.124.228.227   >nul 2>&1 && net use V: \\144.124.228.227\soft   /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.227#soft\"   /v _LabelFromReg /t REG_SZ /d \"SHAHIN_227\"  /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 144.124.228.227 (SHAHIN_227)"
start /b cmd /c "ping -n 1 -w 800 144.124.239.24    >nul 2>&1 && net use W: \\144.124.239.24\soft    /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.239.24#soft\"    /v _LabelFromReg /t REG_SZ /d \"STOLB_24\"    /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 144.124.239.24 (STOLB_24)"
start /b cmd /c "ping -n 1 -w 800 91.84.118.178     >nul 2>&1 && net use N: \\91.84.118.178\soft     /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##91.84.118.178#soft\"     /v _LabelFromReg /t REG_SZ /d \"PILIK_178\"   /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 91.84.118.178 (PILIK_178)"
start /b cmd /c "ping -n 1 -w 800 146.103.110.176   >nul 2>&1 && net use I: \\146.103.110.176\soft   /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##146.103.110.176#soft\"   /v _LabelFromReg /t REG_SZ /d \"ILYA_176\"    /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 146.103.110.176 (ILYA_176)"
start /b cmd /c "ping -n 1 -w 800 144.124.233.38    >nul 2>&1 && net use Q: \\144.124.233.38\soft    /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.233.38#soft\"    /v _LabelFromReg /t REG_SZ /d \"SO_38\"       /f >nul 2>&1 || echo %YELLOW%[ПРОПУСК]%RESET% 144.124.233.38 (SO_38)"

timeout /t 5 /nobreak >nul

echo.
echo %CYAN%==========================================================================================%RESET%
echo %YELLOW%                            ОБРАБОТКА ДИСКОВ ЗАВЕРШЕНА!                               %RESET%
echo %CYAN%==========================================================================================%RESET%
echo.

net use
echo.
pause

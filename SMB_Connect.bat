@echo off
cls
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==========================================================================================
:: FILE    : SMB_Connect.bat
:: VERSION : v2026.06.14b
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Параллельное монтирование всех Samba-хранилищ инфраструктуры gincz.com.
::   Пользователь: vlad / sa4434
::
::   ИСПРАВЛЕНИЯ v2026.06.14b:
::     - Перед каждым mount выполняется net use X: /delete — устраняет ошибку
::       "диск уже используется" при повторном запуске (была причина [ПРОПУСК])
::     - [ПРОПУСК] теперь только если ping не прошёл — сервер недоступен
::     - Финальная таблица показывает OK / ПРОПУСК / ОШИБКА по каждому диску
::     - timeout подключения увеличен до 8 сек, ping до 1500ms
::
::   Диски:
::     A: — AWS_42        3.79.14.42
::     E: — IONOS_38      82.223.116.38
::     I: — ILYA_176      146.103.110.176
::     N: — PILIK_33      195.63.138.33
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
set "RED=%ESC%[91m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

set "TMPDIR=%TEMP%\smb_connect_%RANDOM%"
mkdir "%TMPDIR%" >nul 2>&1

echo %CYAN%==========================================================================================%RESET%
echo %YELLOW%                  ПОДКЛЮЧЕНИЕ СЕТЕВЫХ ХРАНИЛИЩ (v.2026.06.14b)                        %RESET%
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
cmdkey /add:195.63.138.33    /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:146.103.110.176  /user:vlad /pass:sa4434 >nul 2>&1
cmdkey /add:144.124.233.38   /user:vlad /pass:sa4434 >nul 2>&1

echo %YELLOW%[ STATUS ]%RESET% Учётные данные сохранены.
echo %YELLOW%[ STATUS ]%RESET% Отключение старых дисков и запуск параллельного подключения...
echo %CYAN%------------------------------------------------------------------------------------------%RESET%

:: ==========================================================================================
:: Каждый start /b cmd /c выполняет:
::   1. net use DRIVE: /delete /yes  — отключить если был подключён (игнорируем ошибку)
::   2. ping -n 1 -w 1500 IP         — проверить доступность (1 пакет, 1500ms таймаут)
::   3. Если ping прошёл → net use   — монтировать
::   4. Если ping не прошёл → [ПРОПУСК]
::   5. Результат сохранить в %TMPDIR%\DRIVE.txt для финальной таблицы
:: ==========================================================================================

start /b cmd /c "net use A: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 3.79.14.42 >nul 2>&1 && (net use A: \\3.79.14.42\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##3.79.14.42#soft\" /v _LabelFromReg /t REG_SZ /d \"AWS_42\" /f >nul 2>&1 && echo OK>""%TMPDIR%\A.txt"" || echo ОШИБКА>""%TMPDIR%\A.txt"") || echo ПРОПУСК>""%TMPDIR%\A.txt"""

start /b cmd /c "net use E: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 82.223.116.38 >nul 2>&1 && (net use E: \\82.223.116.38\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##82.223.116.38#soft\" /v _LabelFromReg /t REG_SZ /d \"IONOS_38\" /f >nul 2>&1 && echo OK>""%TMPDIR%\E.txt"" || echo ОШИБКА>""%TMPDIR%\E.txt"") || echo ПРОПУСК>""%TMPDIR%\E.txt"""

start /b cmd /c "net use I: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 146.103.110.176 >nul 2>&1 && (net use I: \\146.103.110.176\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##146.103.110.176#soft\" /v _LabelFromReg /t REG_SZ /d \"ILYA_176\" /f >nul 2>&1 && echo OK>""%TMPDIR%\I.txt"" || echo ОШИБКА>""%TMPDIR%\I.txt"") || echo ПРОПУСК>""%TMPDIR%\I.txt"""

start /b cmd /c "net use N: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 195.63.138.33 >nul 2>&1 && (net use N: \\195.63.138.33\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##195.63.138.33#soft\" /v _LabelFromReg /t REG_SZ /d \"PILIK_33\" /f >nul 2>&1 && echo OK>""%TMPDIR%\N.txt"" || echo ОШИБКА>""%TMPDIR%\N.txt"") || echo ПРОПУСК>""%TMPDIR%\N.txt"""

start /b cmd /c "net use O: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.228.237 >nul 2>&1 && (net use O: \\144.124.228.237\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.237#soft\" /v _LabelFromReg /t REG_SZ /d \"4TON_237\" /f >nul 2>&1 && echo OK>""%TMPDIR%\O.txt"" || echo ОШИБКА>""%TMPDIR%\O.txt"") || echo ПРОПУСК>""%TMPDIR%\O.txt"""

start /b cmd /c "net use Q: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.233.38 >nul 2>&1 && (net use Q: \\144.124.233.38\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.233.38#soft\" /v _LabelFromReg /t REG_SZ /d \"SO_38\" /f >nul 2>&1 && echo OK>""%TMPDIR%\Q.txt"" || echo ОШИБКА>""%TMPDIR%\Q.txt"") || echo ПРОПУСК>""%TMPDIR%\Q.txt"""

start /b cmd /c "net use T: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.232.9 >nul 2>&1 && (net use T: \\144.124.232.9\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.232.9#soft\" /v _LabelFromReg /t REG_SZ /d \"TATRA_9\" /f >nul 2>&1 && echo OK>""%TMPDIR%\T.txt"" || echo ОШИБКА>""%TMPDIR%\T.txt"") || echo ПРОПУСК>""%TMPDIR%\T.txt"""

start /b cmd /c "net use V: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.228.227 >nul 2>&1 && (net use V: \\144.124.228.227\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.227#soft\" /v _LabelFromReg /t REG_SZ /d \"SHAHIN_227\" /f >nul 2>&1 && echo OK>""%TMPDIR%\V.txt"" || echo ОШИБКА>""%TMPDIR%\V.txt"") || echo ПРОПУСК>""%TMPDIR%\V.txt"""

start /b cmd /c "net use W: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 144.124.239.24 >nul 2>&1 && (net use W: \\144.124.239.24\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.239.24#soft\" /v _LabelFromReg /t REG_SZ /d \"STOLB_24\" /f >nul 2>&1 && echo OK>""%TMPDIR%\W.txt"" || echo ОШИБКА>""%TMPDIR%\W.txt"") || echo ПРОПУСК>""%TMPDIR%\W.txt"""

start /b cmd /c "net use Y: /delete /yes >nul 2>&1 & ping -n 1 -w 1500 109.234.38.47 >nul 2>&1 && (net use Y: \\109.234.38.47\soft /persistent:yes >nul 2>&1 && reg add \"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##109.234.38.47#soft\" /v _LabelFromReg /t REG_SZ /d \"ALEX_47\" /f >nul 2>&1 && echo OK>""%TMPDIR%\Y.txt"" || echo ОШИБКА>""%TMPDIR%\Y.txt"") || echo ПРОПУСК>""%TMPDIR%\Y.txt"""

:: Ждём завершения всех фоновых процессов (8 сек — запас для медленных серверов)
timeout /t 8 /nobreak >nul

echo.
echo %CYAN%==========================================================================================%RESET%
echo %YELLOW%                            РЕЗУЛЬТАТ ПОДКЛЮЧЕНИЯ                                      %RESET%
echo %CYAN%==========================================================================================%RESET%
echo.
echo %WHITE%  Диск   Сервер             IP                  Статус%RESET%
echo %CYAN%  ----------------------------------------------------------------%RESET%

call :STATUS A  AWS_42      3.79.14.42
call :STATUS E  IONOS_38    82.223.116.38
call :STATUS I  ILYA_176    146.103.110.176
call :STATUS N  PILIK_33    195.63.138.33
call :STATUS O  4TON_237    144.124.228.237
call :STATUS Q  SO_38       144.124.233.38
call :STATUS T  TATRA_9     144.124.232.9
call :STATUS V  SHAHIN_227  144.124.228.227
call :STATUS W  STOLB_24    144.124.239.24
call :STATUS Y  ALEX_47     109.234.38.47

echo.
echo %CYAN%==========================================================================================%RESET%
echo %YELLOW%  = Rooted by VladiMIR + AI | v2026.06.14b | github.com/GinCz =                       %RESET%
echo %CYAN%==========================================================================================%RESET%
echo.

:: Очистка временной папки
rmdir /s /q "%TMPDIR%" >nul 2>&1

pause
exit /b

:: ==========================================================================================
:: :STATUS DRIVE LABEL IP
:: Читает файл результата и выводит цветную строку
:: ==========================================================================================
:STATUS
set "DRIVE=%~1"
set "LABEL=%~2"
set "IP=%~3"
set "RESULT=ОЖИДАНИЕ"
if exist "%TMPDIR%\%DRIVE%.txt" (
    set /p RESULT=<"%TMPDIR%\%DRIVE%.txt"
)
set "RESULT=!RESULT: =!"

if "!RESULT!"=="OK" (
    echo   %GREEN%[  OK  ]%RESET%  %DRIVE%:  %-12s%LABEL%  %IP%
) else if "!RESULT!"=="ПРОПУСК" (
    echo   %YELLOW%[ПРОПУСК]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(сервер недоступен^)
) else if "!RESULT!"=="ОШИБКА" (
    echo   %RED%[ОШИБКА ]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(ping OK, SMB отказал^)
) else (
    echo   %RED%[ТАЙМАУТ]%RESET% %DRIVE%:  %-12s%LABEL%  %IP%  ^(не успел за 8 сек^)
)
exit /b

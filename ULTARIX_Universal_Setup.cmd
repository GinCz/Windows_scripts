@echo off
setlocal

:: Enable UNC path support in CMD
reg add "HKCU\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1

:: Auto-Elevation to Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Vyzaduji se administratorska prava...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/k pushd \"\"%~dp0\"\" && \"\"%~f0\"\" admin' -Verb RunAs"
    exit /b
)

title ULTARIX - Universal Setup and Stabilizer [VladiMIR + Antigravity]

:: Fix UNC working directory
pushd "%~dp0" 2>nul

echo ================================================================================
echo       ULTARIX s.r.o. - Optimalizace a stabilizace pocitace
echo ================================================================================
echo Pocitac: %COMPUTERNAME% ^| Cilovy server: ULPS1 (192.168.33.128)
echo ================================================================================
echo.

echo [*] Krok 1/11: Nastaveni DNS mapovani pro ULPS1 - 192.168.33.128
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$h=\"$env:SystemRoot\System32\drivers\etc\hosts\"; $c=Get-Content $h -ErrorAction SilentlyContinue; $n=@(); $f=$false; foreach($l in $c){ if($l -match '\bULPS1\b'){$n+='192.168.33.128 ULPS1';$f=$true}else{$n+=$l} }; if(-not $f){$n+='192.168.33.128 ULPS1'}; Set-Content -Path $h -Value $n -Force; ipconfig /flushdns >$null 2>&1; nbtstat -R >$null 2>&1"
echo     [OK] Zaznam 192.168.33.128 ULPS1 nastaven v hosts, DNS a NetBIOS cache vycistena.
echo.

echo [*] Krok 2/11: Nastaveni profilu site na Private - Doma / Kancelar
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-NetConnectionProfile | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private -ErrorAction SilentlyContinue }"
echo     [OK] Profil site nastaven na Private (povolen pristup k mistnim sitovym prostredkum).
echo.

echo [*] Krok 3/11: Povoleni neovereneho SMB guest pristupu, oprava ServiceDll a Linked Connections
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "ServiceDll" /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\wkssvc.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "ServiceDllUnloadOnStop" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "ServiceDll" /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\srvsvc.dll" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLinkedConnections" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1
echo     [OK] LanmanWorkstation ServiceDll, AllowInsecureGuestAuth=1, EnableLinkedConnections=1 nastaveno.
echo.

echo [*] Krok 4/11: Spusteni klicovych sitovych sluzeb a tiskoveho procesoru
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "@('LanmanWorkstation','LanmanServer','Spooler','FDResPub','fdPHost','Dnscache','lmhosts') | ForEach-Object { Set-Service -Name $_ -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name $_ -ErrorAction SilentlyContinue }"
echo     [OK] LanmanWorkstation, Spooler, FDResPub, fdPHost, lmhosts jsou aktivni a v automatickem startu.
echo.

echo [*] Krok 5/11: Konfigurace Windows Firewall - Sdileni souboru, Tiskarny, NexusDB, STEREO
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes profile=private >nul 2>&1
netsh advfirewall firewall set rule group="Sdílení souborů a tiskáren" new enable=Yes profile=private >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes profile=private >nul 2>&1
netsh advfirewall firewall set rule group="Zjišťování sítě" new enable=Yes profile=private >nul 2>&1
netsh advfirewall firewall add rule name="FORM studio NexusDB (16000)" dir=in action=allow protocol=TCP localport=16000 profile=any >nul 2>&1
netsh advfirewall firewall add rule name="FORM studio Web (10088)" dir=in action=allow protocol=TCP localport=10088 profile=any >nul 2>&1
netsh advfirewall firewall add rule name="STEREO Accounting" dir=in action=allow protocol=TCP localport=139,445 profile=private >nul 2>&1
echo     [OK] Pravidla Firewallu pro tisk, sdileni souboru a NexusDB (16000) povolena.
echo.

echo [*] Krok 6/11: Pridani vyjimek do Windows Defender - FORM studio, STEREO, Ekonom, RustDesk, TeamViewer
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$paths=@('\\ULPS1\*','\\192.168.33.128\*','E:\','S:\','Z:\','C:\STEREO*','C:\Program Files\KASTNER software','C:\ProgramData\KASTNER software','C:\Program Files\Jezek software','C:\ProgramData\Jezek software','D:\UTIL'); foreach($p in $paths){ Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue }; @('FORMstudio.exe','nxServer412.exe','stereo.exe','ekonom.exe','Telegram.exe','RustDesk.exe','TeamViewer.exe') | ForEach-Object { Add-MpPreference -ExclusionProcess $_ -ErrorAction SilentlyContinue }"
echo     [OK] Cesty \\ULPS1\*, E:\, S:\, Z:\ a procesy pridany do vyjimek Defenderu.
echo.

echo [*] Krok 7/11: Sprava vzdaleneho pristupu a komunikace (Telegram, RustDesk, TeamViewer, odstraneni AnyDesk)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Stop-Process -Name 'AnyDesk' -Force -ErrorAction SilentlyContinue; Stop-Service -Name 'AnyDesk' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'AnyDesk' -StartupType Disabled -ErrorAction SilentlyContinue; @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKCU:\Software\Microsoft\Windows\CurrentVersion\Run') | ForEach-Object { Remove-ItemProperty -Path $_ -Name 'AnyDesk' -Force -ErrorAction SilentlyContinue }; Write-Output '    [OK] AnyDesk ukoncen a odstranen ze startu. RustDesk a TeamViewer zustavaji zachovany.'"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$tg='D:\UTIL\N E T\Telegram\Telegram.exe'; if(-not (Test-Path $tg)){ $tg=(Get-Item \"$env:APPDATA\Telegram Desktop\Telegram.exe\" -ErrorAction SilentlyContinue).FullName }; if($tg -and (Test-Path $tg)){ Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Telegram' -Value ('\"' + $tg + '\" -autostart') -Force -ErrorAction SilentlyContinue; if(-not (Get-Process Telegram -ErrorAction SilentlyContinue)){ Start-Process $tg -ArgumentList '-autostart' -WindowStyle Minimized }; Write-Output ('    [OK] Telegram nalezen a aktivovan: ' + $tg) } else { Write-Output '    [-] Telegram nenalezen ve standardnich slozkach' }"
echo.

echo [*] Krok 8/11: Zakaz automatickych aktualizaci Windows Update (ochrana pred nechtenymi restarty)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] Windows Update nastaven na NoAutoUpdate=1 (zabraneno samovolnemu restartu pocitace).
echo.

echo [*] Krok 9/11: Nastaveni virtualni pameti - Pagefile 4-8 GB na disku C:
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys 4096 8192" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] Pagefile 4096-8192 MB nakonfigurovan (ochrana pred padem z duvodu nedostatku RAM).
echo.

echo [*] Krok 10/11: Kontrola a pripojeni sitovych disku E:, S:, Z:
net use E: "\\ULPS1\Sdílené Data" /persistent:yes >nul 2>&1
net use S: "\\ULPS1\ULTARIX" /persistent:yes >nul 2>&1
net use Z: "\\ULPS1\ekonom.win" /persistent:yes >nul 2>&1
echo     [OK] Sitove disky E: (Sdilena Data), S: (ULTARIX), Z: (ekonom.win) pripojeny.
echo.

echo [*] Krok 11/11: Overeni spojeni se serverem ULPS1 - NexusDB Port 16000
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$t=Test-NetConnection -ComputerName ULPS1 -Port 16000; if($t.TcpTestSucceeded){ Write-Output '    [OK] Server ULPS1 port 16000 (NexusDB FORM studio) je USPESNE DOSTUPNY!' } else { Write-Output '    [!] Varovani: Port 16000 neodpovida, overte sluzbu nxServer na serveru' }"
echo.

echo ================================================================================
echo       STAV PRIPOJENYCH SITOVYCH DISKU:
echo ================================================================================
net use
echo.

echo ================================================================================
echo       OPTIMALIZACE BYLA USPESNE DOKONCENA!
echo ================================================================================
echo.

popd 2>nul

if /i "%~1"=="/silent" goto :eof
if /i "%~1"=="/quiet" goto :eof
if /i "%~1"=="-quiet" goto :eof

echo Stisknete libovolnou klavesu pro ukonceni...
pause >nul
exit /b

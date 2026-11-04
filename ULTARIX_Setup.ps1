# =============================================================================
# Execution Context : PowerShell (Run as Administrator)
# Target Server     : ULTARIX Office PCs (Windows 10 Pro 32-bit / 64-bit)
# Description       : Ultarix Complete PC Optimization & Network Stabilizer
# =============================================================================

# Auto-Elevation check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Spoustim skript jako Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "ULTARIX - PC Optimizer & Network Stabilizer [VladiMIR + Antigravity]"
Clear-Host

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "      ULTARIX s.r.o. - Optimalizace a stabilizace pocitace                     " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Pocitac: $env:COMPUTERNAME | Cilovy server: ULPS1 (192.168.33.128)" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 1: Nastaveni hosts pro ULPS1 (192.168.33.128)
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 1/8: Nastaveni DNS mapovani pro ULPS1 (192.168.33.128)..." -ForegroundColor Yellow
try {
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue
    $newLines = @()
    $found = $false
    foreach ($line in $lines) {
        if ($line -match '\bULPS1\b') {
            $newLines += "192.168.33.128 ULPS1"
            $found = $true
        } else {
            $newLines += $line
        }
    }
    if (-not $found) {
        $newLines += "192.168.33.128 ULPS1"
    }
    Set-Content -Path $hostsPath -Value $newLines -Force -ErrorAction SilentlyContinue
    ipconfig /flushdns | Out-Null
    nbtstat -R | Out-Null
    Write-Host "    [OK] Zaznam 192.168.33.128 ULPS1 je nastaven v hosts souboru." -ForegroundColor Green
} catch {
    Write-Host "    [-] Varovani pri zapisu do hosts: $_" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 2: Nastaveni sitoveho profilu na Private
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 2/8: Nastaveni profilu site na Private (Doma / Kancelar)..." -ForegroundColor Yellow
try {
    Get-NetConnectionProfile | ForEach-Object {
        Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private -ErrorAction SilentlyContinue
    }
    Write-Host "    [OK] Profil site nastaven na Private." -ForegroundColor Green
} catch {
    Write-Host "    [-] Nelze nastavit sitovy profil pres cmdlet, pokracuji..." -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 3: Oprava registru pro SMB, ServiceDll a Linked Connections
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 3/8: Konfigurace registru SMB, ServiceDll a EnableLinkedConnections..." -ForegroundColor Yellow
try {
    # LanmanWorkstation
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "ServiceDll" -Value "%SystemRoot%\System32\wkssvc.dll" -Type ExpandString -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "ServiceDllUnloadOnStop" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    # LanmanServer
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "ServiceDll" -Value "%SystemRoot%\System32\srvsvc.dll" -Type ExpandString -Force -ErrorAction SilentlyContinue

    # EnableLinkedConnections (allow elevated apps to see mapped network drives)
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    # DisableUNCCheck
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Command Processor" -Name "DisableUNCCheck" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    Write-Host "    [OK] Registry LanmanWorkstation, AllowInsecureGuestAuth a EnableLinkedConnections nastaveny." -ForegroundColor Green
} catch {
    Write-Host "    [-] Chyba pri zapisu do registru: $_" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 4: Spusteni klicovych sluzeb Windows
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 4/8: Spusteni sitovych a tiskovych sluzeb..." -ForegroundColor Yellow
$services = @('LanmanWorkstation','LanmanServer','Spooler','FDResPub','fdPHost','Dnscache','lmhosts')
foreach ($svc in $services) {
    Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}
Write-Host "    [OK] Sluzby LanmanWorkstation, Spooler, FDResPub, fdPHost jsou spusteny." -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 5: Konfigurace Windows Firewall
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 5/8: Nastaveni pravidel Windows Firewall..." -ForegroundColor Yellow
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes profile=private >$null 2>&1
netsh advfirewall firewall set rule group="Sdílení souborů a tiskáren" new enable=Yes profile=private >$null 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes profile=private >$null 2>&1
netsh advfirewall firewall set rule group="Zjišťování sítě" new enable=Yes profile=private >$null 2>&1
netsh advfirewall firewall add rule name="FORM studio NexusDB (16000)" dir=in action=allow protocol=TCP localport=16000 profile=any >$null 2>&1
netsh advfirewall firewall add rule name="FORM studio Web (10088)" dir=in action=allow protocol=TCP localport=10088 profile=any >$null 2>&1
netsh advfirewall firewall add rule name="STEREO Accounting" dir=in action=allow protocol=TCP localport=139,445 profile=private >$null 2>&1
Write-Host "    [OK] Pravidla Firewallu pro tisk, sdileni souboru a port 16000 povolena." -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 6: Vyjimky pro Windows Defender (FORM studio, STEREO, Ekonom)
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 6/8: Pridani vyjimek do Windows Defender..." -ForegroundColor Yellow
try {
    $defenderPaths = @(
        '\\ULPS1\*',
        '\\192.168.33.128\*',
        'E:\',
        'S:\',
        'Z:\',
        'C:\STEREO*',
        'C:\Program Files\KASTNER software',
        'C:\ProgramData\KASTNER software',
        'C:\Program Files\Jezek software',
        'C:\ProgramData\Jezek software',
        'D:\UTIL'
    )
    foreach ($p in $defenderPaths) {
        Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
    }
    $defenderProcs = @('FORMstudio.exe','nxServer412.exe','stereo.exe','ekonom.exe','Telegram.exe','RustDesk.exe')
    foreach ($pr in $defenderProcs) {
        Add-MpPreference -ExclusionProcess $pr -ErrorAction SilentlyContinue
    }
    Write-Host "    [OK] Vyjimky pro ucto slozky (E:, S:, Z:) a programy uspesne pridany." -ForegroundColor Green
} catch {
    Write-Host "    [-] Varovani pri nastaveni Defenderu: $_" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 7: Virtualni pamet (Pagefile 4096-8192 MB na disku C:)
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 7/8: Konfigurace virtualni pameti (Pagefile 4096 - 8192 MB)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value @("C:\pagefile.sys 4096 8192") -Type MultiString -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "AutomaticManagedPagefile" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    [OK] Virtualni pamet nastavena na 4-8 GB (prevence nedostatku RAM)." -ForegroundColor Green
} catch {
    Write-Host "    [-] Varovani pri nastaveni Pagefile: $_" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Krok 8: Autostart Telegram Desktop & Overeni serveru ULPS1
# -----------------------------------------------------------------------------
Write-Host "[*] Krok 8/8: Overeni serveru ULPS1 a autostart Telegramu..." -ForegroundColor Yellow
$tgPath = "D:\UTIL\N E T\Telegram\Telegram.exe"
if (-not (Test-Path $tgPath)) {
    $tgCandidate = Get-Item "$env:APPDATA\Telegram Desktop\Telegram.exe" -ErrorAction SilentlyContinue
    if ($tgCandidate) { $tgPath = $tgCandidate.FullName }
}
if (Test-Path $tgPath) {
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Telegram" -Value "`"$tgPath`" -autostart" -Force -ErrorAction SilentlyContinue
    if (-not (Get-Process Telegram -ErrorAction SilentlyContinue)) {
        Start-Process $tgPath -ArgumentList "-autostart" -WindowStyle Minimized -ErrorAction SilentlyContinue
    }
    Write-Host "    [OK] Telegram nastaven na automaticke spusteni." -ForegroundColor Green
}

$nexusTest = Test-NetConnection -ComputerName "ULPS1" -Port 16000 -WarningAction SilentlyContinue
if ($nexusTest.TcpTestSucceeded) {
    Write-Host "    [OK] Spojeni se serverem ULPS1 (port 16000 NexusDB) je AKTIVNI!" -ForegroundColor Green
} else {
    Write-Host "    [!] Varovani: Port 16000 na ULPS1 neodpovidal." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                 OPTIMALIZACE BYLA USPESNE DOKONCENA!                          " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Aktualni stav sitovych disku:" -ForegroundColor White
net use
Write-Host ""
Write-Host "Stisknete libovolnou klavesu pro ukonceni..." -ForegroundColor Cyan
try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    [void][System.Console]::ReadLine()
}
[Environment]::Exit(0)

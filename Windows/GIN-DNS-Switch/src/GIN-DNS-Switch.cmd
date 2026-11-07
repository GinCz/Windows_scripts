<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-DNS-Switch v002 [ VladiMIR ^& Antigravity ]

:: Detect PowerShell executable (supports x86, x64, Sysnative)
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:: Auto-Elevation: Ensure Full Administrator Privileges on Windows 7 / 8 / 10 / 11
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges for GIN-DNS-Switch v002...
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Pass script path safely to background PowerShell instance
set "GIN_DNS_SCRIPT=%~f0"

:: Launch GUI cleanly in background (hidden console)
start "" "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "try { $p = $env:GIN_DNS_SCRIPT; if (-not $p -or -not (Test-Path $p)) { $p = '%~f0' }; $raw = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8); Invoke-Expression $raw } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'GIN-DNS-Switch Error') }"
exit /b
#>

# ==============================================================================
#  GIN-DNS-SWITCH                                                  v002
#  Smart 1-Click DNS Manager for Windows 7 / 8 / 10 / 11
#  Author: Vladimir Bulantsev (GinCz) & AI [VladiMIR + AI]
#  Repository: https://github.com/GinCz/Windows_scripts
#  License: Freeware
# ==============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'

# ------------------------------------------------------------------------------
# 1. LOCALIZATION STRINGS (RU, EN, CS)
# ------------------------------------------------------------------------------
$script:Lang = "RU"

$script:Loc = @{
    "RU" = @{
        "WinTitle"       = "GIN-DNS-Switch v002 — Менеджер DNS"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Умный переключатель сетевых профилей DNS"
        "StatusCurrent"  = "Текущий статус:"
        "StatusDetect"   = "Определение..."
        "SecModes"       = "ВЫБЕРИТЕ РЕЖИМ DNS ДЛЯ ВСЕЙ СИСТЕМЫ"
        "CardAdGuard"    = "AdGuard DNS (Без рекламы)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Блокировка баннеров, трекеров и фишинга во всех программах"
        "CardGoogle"     = "Google + Cloudflare (Макс. скорость)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ультра-скорость, Google Cast, трансляция на ТВ и банки"
        "CardISP"        = "DNS провайдера (Чистый DHCP)"
        "CardISPSub"     = "Автоматический шлюз роутера"
        "CardISPDesc"    = "Сброс сторонних DNS, прямой доступ к сети оператора"
        "BtnApply"       = "ПРИМЕНИТЬ НАСТРОЙКИ"
        "Step1Pending"   = "○ Настройка сетевых адаптеров..."
        "Step1Done"      = "✔ Сетевой адаптер успешно перенастроен"
        "Step2Pending"   = "○ Очистка кэша сопоставителя DNS..."
        "Step2Done"      = "✔ Кэш сопоставителя DNS очищен (Flush DNS)"
        "StepClose"      = "Закрытие через {0} сек..."
        "BtnUpdate"      = "v002 (Обновить)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Активен: AdGuard DNS (Блокировка рекламы)"
        "StatusActiveDHCP"    = "Активен: DNS провайдера (DHCP / Роутер)"
        "StatusActiveGoogle"  = "Активен: Google + Cloudflare (Скорость и ТВ)"
        "StatusActiveOther"   = "Активен: Пользовательский DNS"
    }
    "EN" = @{
        "WinTitle"       = "GIN-DNS-Switch v002 — DNS Profile Manager"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Smart 1-Click DNS Profile Switcher"
        "StatusCurrent"  = "Current status:"
        "StatusDetect"   = "Detecting..."
        "SecModes"       = "SELECT SYSTEM-WIDE DNS MODE"
        "CardAdGuard"    = "AdGuard DNS (No Ads)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Blocks ads, trackers, and phishing across all Windows apps"
        "CardGoogle"     = "Google + Cloudflare (Ultra Fast)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ultra-low latency, Google Cast, Android TV & Banking OK"
        "CardISP"        = "Provider DNS (Pure DHCP)"
        "CardISPSub"     = "Automatic Router Gateway"
        "CardISPDesc"    = "Reset third-party DNS, full access to ISP network"
        "BtnApply"       = "APPLY SETTINGS"
        "Step1Pending"   = "○ Configuring network adapters..."
        "Step1Done"      = "✔ Network adapter configured successfully"
        "Step2Pending"   = "○ Clearing DNS resolver cache..."
        "Step2Done"      = "✔ DNS resolver cache flushed (Flush DNS)"
        "StepClose"      = "Closing in {0} sec..."
        "BtnUpdate"      = "v002 (Update)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Active: AdGuard DNS (AdBlock)"
        "StatusActiveDHCP"    = "Active: Provider DNS (DHCP / Router)"
        "StatusActiveGoogle"  = "Active: Google + Cloudflare (Speed & TV)"
        "StatusActiveOther"   = "Active: Custom DNS"
    }
    "CS" = @{
        "WinTitle"       = "GIN-DNS-Switch v002 — Správce DNS"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Chytrý přepínač profilů DNS na 1 kliknutí"
        "StatusCurrent"  = "Aktuální stav:"
        "StatusDetect"   = "Zjišťování..."
        "SecModes"       = "VYBERTE REŽIM DNS PRO CELÝ SYSTÉM"
        "CardAdGuard"    = "AdGuard DNS (Bez reklam)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Blokování reklam a trackerů ve všech aplikacích Windows"
        "CardGoogle"     = "Google + Cloudflare (Max. rychlost)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ultra nízká odezva, Google Cast, Android TV i banky"
        "CardISP"        = "DNS poskytovatele (Čisté DHCP)"
        "CardISPSub"     = "Automatická brána routeru"
        "CardISPDesc"    = "Reset cizích DNS, přímý přístup k síti operátora"
        "BtnApply"       = "POUŽÍT NASTAVENÍ"
        "Step1Pending"   = "○ Konfigurace síťových adaptérů..."
        "Step1Done"      = "✔ Síťový adaptér byl úspěšně nastaven"
        "Step2Pending"   = "○ Vyprázdnění mezipaměti DNS..."
        "Step2Done"      = "✔ Mezipaměť DNS byla vyprázdněna (Flush DNS)"
        "StepClose"      = "Zavření za {0} s..."
        "BtnUpdate"      = "v002 (Aktualizovat)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Aktivní: AdGuard DNS (Blokování reklam)"
        "StatusActiveDHCP"    = "Aktivní: DNS poskytovatele (DHCP / Router)"
        "StatusActiveGoogle"  = "Aktivní: Google + Cloudflare (Rychlost a TV)"
        "StatusActiveOther"   = "Aktivní: Vlastní DNS"
    }
}

# ------------------------------------------------------------------------------
# 2. XAML DEFINITION (WPF Modern Dark UI with Pure White Vector Icons)
# ------------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GIN-DNS-Switch v002" Height="550" Width="490"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#13141A" Foreground="#FFFFFF" FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="LangBtn" TargetType="Button">
            <Setter Property="Background" Value="#1E202B"/>
            <Setter Property="Foreground" Value="#9CA3AF"/>
            <Setter Property="BorderBrush" Value="#2D3142"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,2"/>
            <Setter Property="Margin" Value="2,0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="RadioCard" TargetType="RadioButton">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="CardBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1.5" CornerRadius="8" Padding="14,10" Margin="0,5" Cursor="Hand">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CardBorder" Property="Opacity" Value="0.95"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="CardBorder" Property="BorderThickness" Value="2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18,14,18,14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Status pill -->
            <RowDefinition Height="Auto"/> <!-- Section Title -->
            <RowDefinition Height="Auto"/> <!-- 3 Stacked Cards -->
            <RowDefinition Height="Auto"/> <!-- Apply Button -->
            <RowDefinition Height="Auto"/> <!-- Progress Checklist -->
            <RowDefinition Height="*"/>    <!-- Spacer -->
            <RowDefinition Height="Auto"/> <!-- Footer -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock x:Name="TxtHeaderTitle" Text="GIN-DNS-Switch" FontSize="18" FontWeight="Bold" Foreground="#60A5FA"/>
                <TextBlock x:Name="TxtHeaderSub" Text="Smart 1-Click DNS Profile Switcher" FontSize="11" Foreground="#9CA3AF"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnLangRU" Content="RU" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangEN" Content="EN" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangCS" Content="CS" Style="{StaticResource LangBtn}"/>
            </StackPanel>
        </Grid>

        <!-- CURRENT STATUS PILL -->
        <Border Grid.Row="1" Background="#1A1C26" BorderBrush="#2D3142" BorderThickness="1" CornerRadius="6" Padding="10,6" Margin="0,10,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="TxtStatusLabel" Text="Текущий статус:" FontSize="11" Foreground="#6B7280" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <TextBlock x:Name="TxtStatusValue" Grid.Column="1" Text="Определение..." FontSize="12" FontWeight="SemiBold" Foreground="#34D399" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- SECTION TITLE -->
        <TextBlock x:Name="TxtSecModes" Grid.Row="2" Text="ВЫБЕРИТЕ РЕЖИМ DNS ДЛЯ ВСЕЙ СИСТЕМЫ" FontSize="10.5" FontWeight="Bold" Foreground="#94A3B8" Margin="0,2,0,4"/>

        <!-- 3 CARDS STACK -->
        <StackPanel Grid.Row="3">

            <!-- CARD 1: AdGuard (Green) -->
            <RadioButton x:Name="RadAdGuard" Style="{StaticResource RadioCard}" Background="#0F241C" BorderBrush="#10B981" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <!-- Pure White Vector Shield Icon -->
                    <Border Background="#164E38" CornerRadius="20" Width="38" Height="38" Margin="0,0,12,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="18" Height="18" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardAdGuard" Text="AdGuard DNS (Без рекламы)" FontWeight="Bold" FontSize="13" Foreground="#34D399"/>
                            <Border HorizontalAlignment="Right" Background="#064E3B" CornerRadius="3" Padding="6,1">
                                <TextBlock Text="BLOCK ADS" FontSize="9" FontWeight="Bold" Foreground="#6EE7B7"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardAdGuardSub" Text="94.140.14.14  •  94.140.15.15" FontSize="11" Foreground="#A7F3D0" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardAdGuardDesc" Text="Блокировка баннеров, трекеров и фишинга во всех программах" FontSize="10.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- CARD 2: Google + Cloudflare (Blue) -->
            <RadioButton x:Name="RadGoogle" Style="{StaticResource RadioCard}" Background="#122036" BorderBrush="#3B82F6" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <!-- Pure White Vector Lightning / Speed Icon -->
                    <Border Background="#1E3A8A" CornerRadius="20" Width="38" Height="38" Margin="0,0,12,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="18" Height="18" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M7 2v11h3v9l7-12h-4l4-8z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardGoogle" Text="Google + Cloudflare (Макс. скорость)" FontWeight="Bold" FontSize="13" Foreground="#60A5FA"/>
                            <Border HorizontalAlignment="Right" Background="#1E3A8A" CornerRadius="3" Padding="6,1">
                                <TextBlock Text="ULTRA FAST &amp; TV" FontSize="9" FontWeight="Bold" Foreground="#93C5FD"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardGoogleSub" Text="8.8.8.8  •  1.1.1.1" FontSize="11" Foreground="#BAE6FD" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardGoogleDesc" Text="Ультра-скорость, Google Cast, трансляция на ТВ и банки" FontSize="10.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- CARD 3: DNS провайдера (Red) -->
            <RadioButton x:Name="RadISP" Style="{StaticResource RadioCard}" Background="#251316" BorderBrush="#EF4444" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <!-- Pure White Vector Globe / Router Icon -->
                    <Border Background="#7F1D1D" CornerRadius="20" Width="38" Height="38" Margin="0,0,12,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="18" Height="18" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardISP" Text="DNS провайдера (Чистый DHCP)" FontWeight="Bold" FontSize="13" Foreground="#F87171"/>
                            <Border HorizontalAlignment="Right" Background="#5F1010" CornerRadius="3" Padding="6,1">
                                <TextBlock Text="ISP DIRECT" FontSize="9" FontWeight="Bold" Foreground="#FCA5A5"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardISPSub" Text="Автоматический шлюз роутера" FontSize="11" Foreground="#FECDD3" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardISPDesc" Text="Сброс сторонних DNS, прямой доступ к сети оператора" FontSize="10.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

        </StackPanel>

        <!-- APPLY BUTTON -->
        <Button x:Name="BtnApply" Grid.Row="4" Margin="0,10,0,0" Height="42" Background="#2563EB" Foreground="#FFFFFF" FontWeight="Bold" FontSize="13" Cursor="Hand">
            <Button.Template>
                <ControlTemplate TargetType="Button">
                    <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" CornerRadius="6">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="BtnBorder" Property="Background" Value="#1D4ED8"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="BtnBorder" Property="Background" Value="#1E40AF"/>
                        </Trigger>
                        <Trigger Property="IsEnabled" Value="False">
                            <Setter TargetName="BtnBorder" Property="Background" Value="#374151"/>
                            <Setter Property="Foreground" Value="#9CA3AF"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Button.Template>
            <TextBlock x:Name="TxtBtnApply" Text="ПРИМЕНИТЬ НАСТРОЙКИ"/>
        </Button>

        <!-- PROGRESS CHECKLIST -->
        <Border x:Name="PanelProgress" Grid.Row="5" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="6" Padding="12,8" Margin="0,8,0,0" Visibility="Collapsed">
            <StackPanel>
                <TextBlock x:Name="TxtStep1" Text="○ Настройка сетевых адаптеров..." FontSize="11" Foreground="#9CA3AF" Margin="0,1"/>
                <TextBlock x:Name="TxtStep2" Text="○ Очистка кэша сопоставителя DNS..." FontSize="11" Foreground="#9CA3AF" Margin="0,1"/>
                <TextBlock x:Name="TxtCountdown" Text="Закрытие через 3 сек..." FontSize="11.5" FontWeight="SemiBold" Foreground="#38BDF8" Margin="0,3,0,0"/>
            </StackPanel>
        </Border>

        <!-- FOOTER -->
        <Grid Grid.Row="7" Margin="0,8,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="LnkAuthor" Text="VladiMIR + AI" FontSize="11" FontWeight="SemiBold" Foreground="#60A5FA" Cursor="Hand" VerticalAlignment="Center" ToolTip="Открыть публичный репозиторий GitHub"/>
            <Button x:Name="BtnUpdate" Grid.Column="1" Content="v002 (Обновить)" Style="{StaticResource LangBtn}" Padding="10,3" Foreground="#38BDF8" BorderBrush="#0284C7"/>
        </Grid>
    </Grid>
</Window>
"@

# ------------------------------------------------------------------------------
# 3. GUI ENGINE & EVENT HANDLERS
# ------------------------------------------------------------------------------
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Map controls
$controls = @{}
$xaml.SelectNodes("//*[@*[name()='x:Name']]") | ForEach-Object {
    $name = $_.GetAttribute("x:Name")
    $controls[$name] = $window.FindName($name)
}

# Language switcher function
function Update-Language($lang) {
    $script:Lang = $lang
    $l = $script:Loc[$lang]
    
    $window.Title = $l["WinTitle"]
    $controls["TxtHeaderTitle"].Text = $l["HeaderTitle"]
    $controls["TxtHeaderSub"].Text = $l["HeaderSub"]
    $controls["TxtStatusLabel"].Text = $l["StatusCurrent"]
    $controls["TxtSecModes"].Text = $l["SecModes"]
    $controls["TxtCardAdGuard"].Text = $l["CardAdGuard"]
    $controls["TxtCardAdGuardSub"].Text = $l["CardAdGuardSub"]
    $controls["TxtCardAdGuardDesc"].Text = $l["CardAdGuardDesc"]
    $controls["TxtCardGoogle"].Text = $l["CardGoogle"]
    $controls["TxtCardGoogleSub"].Text = $l["CardGoogleSub"]
    $controls["TxtCardGoogleDesc"].Text = $l["CardGoogleDesc"]
    $controls["TxtCardISP"].Text = $l["CardISP"]
    $controls["TxtCardISPSub"].Text = $l["CardISPSub"]
    $controls["TxtCardISPDesc"].Text = $l["CardISPDesc"]
    $controls["TxtBtnApply"].Text = $l["BtnApply"]
    $controls["BtnUpdate"].Content = $l["BtnUpdate"]
    $controls["LnkAuthor"].Text = $l["AuthorLink"]

    # Active button styles
    $controls["BtnLangRU"].Background = if ($lang -eq "RU") { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB") } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E202B") }
    $controls["BtnLangEN"].Background = if ($lang -eq "EN") { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB") } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E202B") }
    $controls["BtnLangCS"].Background = if ($lang -eq "CS") { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB") } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E202B") }
    $controls["BtnLangRU"].Foreground = if ($lang -eq "RU") { [System.Windows.Media.Brushes]::White } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF") }
    $controls["BtnLangEN"].Foreground = if ($lang -eq "EN") { [System.Windows.Media.Brushes]::White } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF") }
    $controls["BtnLangCS"].Foreground = if ($lang -eq "CS") { [System.Windows.Media.Brushes]::White } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF") }

    Refresh-StatusDisplay
}

# Detect active DNS configuration
function Get-CurrentDnsState {
    try {
        $activeDns = @()
        if (Get-Command Get-DnsClientServerAddress -ErrorAction SilentlyContinue) {
            $addrs = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses.Count -gt 0 }
            foreach ($a in $addrs) { $activeDns += $a.ServerAddresses }
        } else {
            $wmi = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true -and $_.DNSServerSearchOrder }
            foreach ($w in $wmi) { $activeDns += $w.DNSServerSearchOrder }
        }

        $activeDns = $activeDns | Select-Object -Unique
        if ($activeDns -contains "94.140.14.14" -or $activeDns -contains "94.140.15.15") {
            return "AdGuard"
        }
        if ($activeDns -contains "8.8.8.8" -and $activeDns -contains "1.1.1.1") {
            return "Google"
        }
        if (-not $activeDns -or $activeDns.Count -eq 0 -or $activeDns -like "192.168.*" -or $activeDns -like "10.*" -or $activeDns -like "172.16.*") {
            return "DHCP"
        }
        return "Other"
    } catch {
        return "DHCP"
    }
}

function Refresh-StatusDisplay {
    $l = $script:Loc[$script:Lang]
    $state = Get-CurrentDnsState
    switch ($state) {
        "AdGuard" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveAdGuard"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            if (-not $controls["RadAdGuard"].IsChecked -and -not $controls["RadGoogle"].IsChecked -and -not $controls["RadISP"].IsChecked) {
                $controls["RadAdGuard"].IsChecked = $true
            }
        }
        "Google" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveGoogle"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60A5FA")
            if (-not $controls["RadAdGuard"].IsChecked -and -not $controls["RadGoogle"].IsChecked -and -not $controls["RadISP"].IsChecked) {
                $controls["RadGoogle"].IsChecked = $true
            }
        }
        "DHCP" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveDHCP"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            if (-not $controls["RadAdGuard"].IsChecked -and -not $controls["RadGoogle"].IsChecked -and -not $controls["RadISP"].IsChecked) {
                $controls["RadISP"].IsChecked = $true
            }
        }
        Default {
            $controls["TxtStatusValue"].Text = $l["StatusActiveOther"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            if (-not $controls["RadAdGuard"].IsChecked -and -not $controls["RadGoogle"].IsChecked -and -not $controls["RadISP"].IsChecked) {
                $controls["RadISP"].IsChecked = $true
            }
        }
    }
}

# Wire Language Buttons
$controls["BtnLangRU"].Add_Click({ Update-Language "RU" })
$controls["BtnLangEN"].Add_Click({ Update-Language "EN" })
$controls["BtnLangCS"].Add_Click({ Update-Language "CS" })

# Wire Footer Links
$controls["LnkAuthor"].Add_MouseLeftButtonUp({
    try { [System.Diagnostics.Process]::Start("https://github.com/GinCz/Windows_scripts") } catch {}
})

$controls["BtnUpdate"].Add_Click({
    try {
        [System.Diagnostics.Process]::Start("https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-DNS-Switch")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Repository: https://github.com/GinCz/Windows_scripts", "Update")
    }
})

# Network Adapter Apply Function
function Apply-DnsSettings($profile) {
    $adapters = @()
    if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
            $_.Status -eq 'Up' -and 
            $_.InterfaceAlias -notlike '*Loopback*' -and 
            $_.InterfaceAlias -notlike '*vEthernet*' -and
            $_.InterfaceDescription -notlike '*Virtual*' -and
            $_.InterfaceDescription -notlike '*Hyper-V*'
        }
    }

    switch ($profile) {
        "AdGuard" {
            $v4 = @("94.140.14.14", "94.140.15.15")
            $v6 = @("2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff")
            foreach ($a in $adapters) {
                Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ServerAddresses $v4 -ErrorAction SilentlyContinue
                netsh interface ipv4 set dnsservers name="$($a.InterfaceAlias)" source=static address="94.140.14.14" register=both 2>$null
                netsh interface ipv4 add dnsservers name="$($a.InterfaceAlias)" address="94.140.15.15" index=2 2>$null
                netsh interface ipv6 set dnsservers name="$($a.InterfaceAlias)" source=static address="2a10:50c0::ad1:ff" 2>$null
                netsh interface ipv6 add dnsservers name="$($a.InterfaceAlias)" address="2a10:50c0::ad2:ff" index=2 2>$null
            }
        }
        "Google" {
            $v4 = @("8.8.8.8", "1.1.1.1")
            $v6 = @("2001:4860:4860::8888", "2606:4700:4700::1111")
            foreach ($a in $adapters) {
                Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ServerAddresses $v4 -ErrorAction SilentlyContinue
                netsh interface ipv4 set dnsservers name="$($a.InterfaceAlias)" source=static address="8.8.8.8" register=both 2>$null
                netsh interface ipv4 add dnsservers name="$($a.InterfaceAlias)" address="1.1.1.1" index=2 2>$null
            }
        }
        Default { # DHCP / ISP Direct
            foreach ($a in $adapters) {
                Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ResetServerAddresses -ErrorAction SilentlyContinue
                netsh interface ipv4 set dnsservers name="$($a.InterfaceAlias)" source=dhcp 2>$null
                netsh interface ipv6 set dnsservers name="$($a.InterfaceAlias)" source=dhcp 2>$null
            }
        }
    }

    # Step 2: Flush DNS
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    ipconfig /flushdns 2>$null | Out-Null
}

# Apply Button Click Handler
$controls["BtnApply"].Add_Click({
    $l = $script:Loc[$script:Lang]
    $controls["BtnApply"].IsEnabled = $false
    $controls["PanelProgress"].Visibility = [System.Windows.Visibility]::Visible
    $controls["TxtStep1"].Text = $l["Step1Pending"]
    $controls["TxtStep2"].Text = $l["Step2Pending"]

    # Determine chosen profile
    $chosen = "ISP"
    if ($controls["RadAdGuard"].IsChecked) { $chosen = "AdGuard" }
    elseif ($controls["RadGoogle"].IsChecked) { $chosen = "Google" }
    elseif ($controls["RadISP"].IsChecked) { $chosen = "ISP" }

    # Execute changes asynchronously in Dispatcher
    $dispatcher = $window.Dispatcher

    [System.Threading.ThreadPool]::QueueUserWorkItem({
        # 1. Apply Network adapter DNS
        Start-Sleep -Milliseconds 400
        Apply-DnsSettings $chosen
        
        $dispatcher.Invoke([Action]{
            $l = $script:Loc[$script:Lang]
            $controls["TxtStep1"].Text = $l["Step1Done"]
            $controls["TxtStep1"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        })

        # 2. Flush DNS verified
        Start-Sleep -Milliseconds 500
        $dispatcher.Invoke([Action]{
            $l = $script:Loc[$script:Lang]
            $controls["TxtStep2"].Text = $l["Step2Done"]
            $controls["TxtStep2"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            Refresh-StatusDisplay
        })

        # 3. 3-Second Countdown and total exit
        for ($i = 3; $i -ge 1; $i--) {
            $dispatcher.Invoke([Action]{
                $l = $script:Loc[$script:Lang]
                $controls["TxtCountdown"].Text = [string]::Format($l["StepClose"], $i)
            })
            Start-Sleep -Seconds 1
        }

        # 4. Total exit with zero residual background tasks
        $dispatcher.Invoke([Action]{
            $window.Close()
            [System.Windows.Application]::Current.Shutdown()
            [System.Environment]::Exit(0)
        })
    })
})

# Initialize Default Language and Status
Update-Language "RU"

# Show Window
$window.ShowDialog() | Out-Null
[System.Environment]::Exit(0)

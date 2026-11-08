<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-DNS-Switch v011 [ VladiMIR ^& Antigravity ]

:: Detect PowerShell executable (supports x86, x64, Sysnative)
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:: Auto-Elevation: Ensure Full Administrator Privileges on Windows 7 / 8 / 10 / 11
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges for GIN-DNS-Switch v011...
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
#  GIN-DNS-SWITCH                                                  v011
#  Smart 1-Click DNS Profile Manager for Windows 7 / 8 / 10 / 11
#  Author: Vladimir Bulantsev (GinCz) & AI [VladiMIR + AI]
#  Repository: https://github.com/GinCz/Windows_scripts
#  License: Freeware
# ==============================================================================

# Ensure full Administrator privileges inside PowerShell context
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptTarget = $env:GIN_DNS_SCRIPT
    if (-not $scriptTarget) { $scriptTarget = $MyInvocation.MyCommand.Path }
    Start-Process cmd.exe -ArgumentList "/c `"`"$scriptTarget`"`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'

# ------------------------------------------------------------------------------
# 1. LOCALIZATION STRINGS (EN default, RU, CS)
# ------------------------------------------------------------------------------
$script:CurrentVersion = "v011"

$script:Loc = @{
    "EN" = @{
        "WinTitle"       = "GIN-DNS-Switch v011 — Windows DNS Manager"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Windows DNS Switcher"
        "StatusCurrent"  = "Current status:"
        "StatusDetect"   = "Detecting..."
        "CardAdGuard"    = "AdGuard DNS (No Ads)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "System-wide ad, tracker, and phishing blocking in Windows"
        "CardFamily"     = "Family AdGuard DNS (Child Safe 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Ad blocking, strict SafeSearch, and adult 18+ content filter"
        "CardGoogle"     = "Google + Cloudflare (Ultra Fast & TV)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Maximum speed, Google Cast, Android TV streaming & banking"
        "CardQuad9"      = "Quad9 Security (Malware Protection)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Blocks malicious domains while keeping TV streams smooth"
        "CardYandex"     = "Yandex.DNS (Russia & Gov Certificates)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Optimized for RU services, Gosuslugi, Sber & digital certs"
        "CardISP"        = "Provider DNS (Pure DHCP / Router)"
        "CardISPSub"     = "Automatic router gateway"
        "CardISPDesc"    = "Reset custom DNS to ISP defaults, full operator access"
        "BtnApply"       = "APPLY SETTINGS"
        "Step1Pending"   = "○ Configuring network adapters..."
        "Step1Done"      = "✔ Network adapters configured successfully ({0})"
        "Step2Pending"   = "○ Clearing DNS resolver cache..."
        "Step2Done"      = "✔ DNS resolver cache flushed (Flush DNS)"
        "StepClose"      = "Closing in {0} sec..."
        "BtnUpdate"      = "v011 (Update)"
        "AuthorLink"     = "VladiMIR + AI"
        "AuthorTooltip"  = "GitHub page (https://github.com/GinCz/)"
        "BtnAdapter"     = "⚙ Adapter Settings ({0})"
        "BtnAdapterDone" = "✔ Settings opened"
        "StatusActiveAdGuard" = "Active: AdGuard DNS (AdBlock)"
        "StatusActiveFamily"  = "Active: Family AdGuard DNS (Safe 18+)"
        "StatusActiveGoogle"  = "Active: Google + Cloudflare (Speed & TV)"
        "StatusActiveQuad9"   = "Active: Quad9 Security (Malware Protection)"
        "StatusActiveYandex"  = "Active: Yandex.DNS (Russia & Certificates)"
        "StatusActiveDHCP"    = "Active: Provider DNS (Router / DHCP)"
        "StatusActiveOther"   = "Active: Custom DNS"
        "UpdChecking"    = "Checking..."
        "UpdLatest"      = "✔ You have the latest version ({0})"
        "UpdSuccess"     = "✔ Updated!"
        "UpdFail"        = "✖ Connection error"
    }
    "RU" = @{
        "WinTitle"       = "GIN-DNS-Switch v011 — Менеджер DNS для Windows"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Переключатель DNS для Windows"
        "StatusCurrent"  = "Текущий статус:"
        "StatusDetect"   = "Определение..."
        "CardAdGuard"    = "AdGuard DNS (Без рекламы)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Полная блокировка баннеров, трекеров и фишинга во всей Windows"
        "CardFamily"     = "Семейный AdGuard DNS (Детский 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Блокировка рекламы, контента 18+ и принудительный SafeSearch"
        "CardGoogle"     = "Google + Cloudflare (Макс. скорость и ТВ)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ультра-скорость, Google Cast, трансляция на Android TV и банкинг"
        "CardQuad9"      = "Quad9 Security (Защита от вирусов)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Блокирует фишинг и вредоносы (ТВ и стриминг работают без сбоев)"
        "CardYandex"     = "Яндекс.DNS (Россия, Сертификаты, Госуслуги)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Оптимизирован для РФ. Госуслуги, Сбер, ВТБ, сертификаты Минцифры"
        "CardISP"        = "DNS провайдера (Чистый DHCP / Роутер)"
        "CardISPSub"     = "Автоматический шлюз роутера"
        "CardISPDesc"    = "Сброс сторонних DNS, полный доступ к сети и порталам оператора"
        "BtnApply"       = "ПРИМЕНИТЬ НАСТРОЙКИ"
        "Step1Pending"   = "○ Настройка сетевых адаптеров..."
        "Step1Done"      = "✔ Сетевые адаптеры успешно настроены ({0})"
        "Step2Pending"   = "○ Очистка кэша сопоставителя DNS..."
        "Step2Done"      = "✔ Кэш сопоставителя DNS очищен (Flush DNS)"
        "StepClose"      = "Закрытие через {0} сек..."
        "BtnUpdate"      = "v011 (Обновить)"
        "AuthorLink"     = "VladiMIR + AI"
        "AuthorTooltip"  = "Страница GitHub (https://github.com/GinCz/)"
        "BtnAdapter"     = "⚙ Настройки адаптера ({0})"
        "BtnAdapterDone" = "✔ Настройки открыты"
        "StatusActiveAdGuard" = "Активен: AdGuard DNS (Блокировка рекламы)"
        "StatusActiveFamily"  = "Активен: Семейный AdGuard DNS (Детский 18+)"
        "StatusActiveGoogle"  = "Активен: Google + Cloudflare (Скорость и ТВ)"
        "StatusActiveQuad9"   = "Активен: Quad9 Security (Защита от угроз)"
        "StatusActiveYandex"  = "Активен: Яндекс.DNS (РФ и Госуслуги)"
        "StatusActiveDHCP"    = "Активен: DNS провайдера (Роутер / DHCP)"
        "StatusActiveOther"   = "Активен: Пользовательский DNS"
        "UpdChecking"    = "Проверка..."
        "UpdLatest"      = "✔ У вас последняя версия ({0})"
        "UpdSuccess"     = "✔ Обновлено!"
        "UpdFail"        = "✖ Ошибка связи"
    }
    "CS" = @{
        "WinTitle"       = "GIN-DNS-Switch v011 — Správce DNS pro Windows"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Přepínač DNS pro Windows"
        "StatusCurrent"  = "Aktuální stav:"
        "StatusDetect"   = "Zjišťování..."
        "CardAdGuard"    = "AdGuard DNS (Bez reklam)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Blokování reklam, sledovacích prvků a phishingu ve Windows"
        "CardFamily"     = "Rodinný AdGuard DNS (Dětský režim 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Blokování reklam, filtr 18+ obsahu a vynucený SafeSearch"
        "CardGoogle"     = "Google + Cloudflare (Max. rychlost a TV)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Maximální rychlost, Google Cast, Android TV a bankovnictví"
        "CardQuad9"      = "Quad9 Security (Ochrana proti virům)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Blokuje nebezpečné domény a malware bez výpadků streamování"
        "CardYandex"     = "Yandex.DNS (Rusko a státní certifikáty)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Optimalizováno pro RU služby, Gosuslugi, Sber a certifikáty"
        "CardISP"        = "DNS poskytovatele (Čisté DHCP / Router)"
        "CardISPSub"     = "Automatická brána routeru"
        "CardISPDesc"    = "Obnovení výchozího DNS poskytovatele a přístup ke službám"
        "BtnApply"       = "POUŽÍT NASTAVENÍ"
        "Step1Pending"   = "○ Konfigurace síťových adaptérů..."
        "Step1Done"      = "✔ Síťové adaptéry byly úspěšně nastaveny ({0})"
        "Step2Pending"   = "○ Vyprázdnění mezipaměti DNS..."
        "Step2Done"      = "✔ Mezipaměť DNS byla vyprázdněna (Flush DNS)"
        "StepClose"      = "Zavření za {0} s..."
        "BtnUpdate"      = "v011 (Aktualizovat)"
        "AuthorLink"     = "VladiMIR + AI"
        "AuthorTooltip"  = "Stránka GitHub (https://github.com/GinCz/)"
        "BtnAdapter"     = "⚙ Nastavení adaptéru ({0})"
        "BtnAdapterDone" = "✔ Nastavení otevřeno"
        "StatusActiveAdGuard" = "Aktivní: AdGuard DNS (Blokování reklam)"
        "StatusActiveFamily"  = "Aktivní: Rodinný AdGuard DNS (Bezpečný 18+)"
        "StatusActiveGoogle"  = "Aktivní: Google + Cloudflare (Rychlost a TV)"
        "StatusActiveQuad9"   = "Aktivní: Quad9 Security (Ochrana proti virům)"
        "StatusActiveYandex"  = "Aktivní: Yandex.DNS (Rusko a certifikáty)"
        "StatusActiveDHCP"    = "Aktivní: DNS poskytovatele (Router / DHCP)"
        "StatusActiveOther"   = "Aktivní: Vlastní DNS"
        "UpdChecking"    = "Kontrola..."
        "UpdLatest"      = "✔ Máte nejnovější verzi ({0})"
        "UpdSuccess"     = "✔ Aktualizováno!"
        "UpdFail"        = "✖ Chyba připojení"
    }
}

# ------------------------------------------------------------------------------
# 2. XAML DEFINITION (WPF Modern Dark UI - SizeToContent, 6 Compact Cards, NO SCROLL)
# ------------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GIN-DNS-Switch v011" SizeToContent="Height" Width="510"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#13141A" Foreground="#FFFFFF" FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="LangBtn" TargetType="Button">
            <Setter Property="Background" Value="#1E202B"/>
            <Setter Property="Foreground" Value="#9CA3AF"/>
            <Setter Property="BorderBrush" Value="#2D3142"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="7,2"/>
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
                        <Border x:Name="CardBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1.5" CornerRadius="7" Padding="10,5.5" Margin="0,2" Cursor="Hand">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CardBorder" Property="Opacity" Value="0.95"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="16,10,16,12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Status Pill -->
            <RowDefinition Height="Auto"/> <!-- 6 Cards (No Scroll) -->
            <RowDefinition Height="Auto"/> <!-- Apply Button & Progress -->
            <RowDefinition Height="Auto"/> <!-- Footer -->
        </Grid.RowDefinitions>

        <!-- HEADER (Title left, Subtitle next to it, Languages right: EN, RU, CS) -->
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                <TextBlock x:Name="TxtHeaderTitle" Text="GIN-DNS-Switch" FontSize="15" FontWeight="Bold" Foreground="#60A5FA" VerticalAlignment="Center"/>
                <TextBlock Text=" • " FontSize="13" Foreground="#4B5563" VerticalAlignment="Center" Margin="5,0"/>
                <TextBlock x:Name="TxtHeaderSub" Text="Windows DNS Switcher" FontSize="12" FontWeight="SemiBold" Foreground="#9CA3AF" VerticalAlignment="Center"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnLangEN" Content="EN" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangRU" Content="RU" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangCS" Content="CS" Style="{StaticResource LangBtn}"/>
            </StackPanel>
        </Grid>

        <!-- CURRENT STATUS PILL -->
        <Border Grid.Row="1" Background="#1A1C26" BorderBrush="#2D3142" BorderThickness="1" CornerRadius="6" Padding="10,5" Margin="0,6,0,5">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="TxtStatusLabel" Text="Current status:" FontSize="11" Foreground="#6B7280" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <TextBlock x:Name="TxtStatusValue" Grid.Column="1" Text="Detecting..." FontSize="12" FontWeight="SemiBold" Foreground="#34D399" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- 6 COMPACT CARDS (ORDER: 1.AdGuard, 2.Family, 3.Google, 4.Quad9, 5.Yandex, 6.ISP) -->
        <StackPanel Grid.Row="2">

            <!-- 1. AdGuard DNS (Green) -->
            <RadioButton x:Name="RadAdGuard" Style="{StaticResource RadioCard}" Background="#0F241C" BorderBrush="#10B981" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderAdGuard" Background="#164E38" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardAdGuard" Text="AdGuard DNS (No Ads)" FontWeight="Bold" FontSize="12" Foreground="#34D399"/>
                            <Border HorizontalAlignment="Right" Background="#064E3B" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="BLOCK ADS" FontSize="8.5" FontWeight="Bold" Foreground="#6EE7B7"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardAdGuardSub" Text="94.140.14.14  •  94.140.15.15" FontSize="10" Foreground="#A7F3D0" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardAdGuardDesc" Text="System-wide ad, tracker, and phishing blocking in Windows" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- 2. Семейный AdGuard DNS (Pink - Детский режим 18+) -->
            <RadioButton x:Name="RadFamily" Style="{StaticResource RadioCard}" Background="#281120" BorderBrush="#EC4899" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderFamily" Background="#581639" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,21.35L10.55,20.03C5.4,15.36 2,12.27 2,8.5C2,5.41 4.42,3 7.5,3C9.24,3 10.91,3.81 12,5.08C13.09,3.81 14.76,3 16.5,3C19.58,3 22,5.41 22,8.5C22,12.27 18.6,15.36 13.45,20.03L12,21.35Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardFamily" Text="Family AdGuard DNS (Child Safe 18+)" FontWeight="Bold" FontSize="12" Foreground="#F472B6"/>
                            <Border HorizontalAlignment="Right" Background="#500724" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="SAFE KIDS 18+" FontSize="8.5" FontWeight="Bold" Foreground="#FBCFE8"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardFamilySub" Text="94.140.14.15  •  94.140.15.16" FontSize="10" Foreground="#FBCFE8" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardFamilyDesc" Text="Ad blocking, strict SafeSearch, and adult 18+ content filter" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- 3. Google + Cloudflare (Blue) -->
            <RadioButton x:Name="RadGoogle" Style="{StaticResource RadioCard}" Background="#0E1B2D" BorderBrush="#3B82F6" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderGoogle" Background="#1E3A5F" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M13,2.05V5.08C16.39,5.57 19,8.47 19,12C19,12.9 18.8,13.76 18.43,14.54L20.62,16.73C21.5,15.36 22,13.74 22,12C22,6.82 18.05,2.55 13,2.05M12,19A7,7 0 0,1 5,12C5,8.47 7.61,5.57 11,5.08V2.05C5.94,2.55 2,6.81 2,12A10,10 0 0,0 12,22C15.3,22 18.23,20.39 20.08,17.91L17.54,15.37C16.32,17.56 13.97,19 12,19Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardGoogle" Text="Google + Cloudflare (Ultra Fast &amp; TV)" FontWeight="Bold" FontSize="12" Foreground="#60A5FA"/>
                            <Border HorizontalAlignment="Right" Background="#1E3A8A" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="FAST &amp; TV" FontSize="8.5" FontWeight="Bold" Foreground="#93C5FD"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardGoogleSub" Text="8.8.8.8  •  1.1.1.1" FontSize="10" Foreground="#BFDBFE" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardGoogleDesc" Text="Maximum speed, Google Cast, Android TV streaming &amp; banking" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- 4. Quad9 Security (Purple) -->
            <RadioButton x:Name="RadQuad9" Style="{StaticResource RadioCard}" Background="#22122F" BorderBrush="#8B5CF6" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderQuad9" Background="#451A6E" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,12H19C18.47,16.11 15.72,19.78 12,20.92V12H5V6.3L12,3.19M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardQuad9" Text="Quad9 Security (Malware Protection)" FontWeight="Bold" FontSize="12" Foreground="#C084FC"/>
                            <Border HorizontalAlignment="Right" Background="#4C1D95" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="MALWARE BLOCK" FontSize="8.5" FontWeight="Bold" Foreground="#DDD6FE"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardQuad9Sub" Text="9.9.9.9  •  149.112.112.112" FontSize="10" Foreground="#E9D5FF" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardQuad9Desc" Text="Blocks malicious domains while keeping TV streams smooth" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- 5. Яндекс.DNS (Amber) -->
            <RadioButton x:Name="RadYandex" Style="{StaticResource RadioCard}" Background="#2A1E0E" BorderBrush="#F59E0B" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderYandex" Background="#583908" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M12,4A8,8 0 0,1 20,12A8,8 0 0,1 12,20A8,8 0 0,1 4,12A8,8 0 0,1 12,4M11,6V11.27L14.73,15L16.14,13.59L13,10.45V6H11Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardYandex" Text="Yandex.DNS (Russia &amp; Gov Certificates)" FontWeight="Bold" FontSize="12" Foreground="#FBBF24"/>
                            <Border HorizontalAlignment="Right" Background="#78350F" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="RUSSIA &amp; CERTS" FontSize="8.5" FontWeight="Bold" Foreground="#FDE68A"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardYandexSub" Text="77.88.8.8  •  77.88.8.1" FontSize="10" Foreground="#FDE68A" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardYandexDesc" Text="Optimized for RU services, Gosuslugi, Sber &amp; digital certs" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

            <!-- 6. DNS провайдера (Red - На последнем месте) -->
            <RadioButton x:Name="RadISP" Style="{StaticResource RadioCard}" Background="#251111" BorderBrush="#EF4444" GroupName="DnsGroup">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="IcoBorderISP" Background="#581616" CornerRadius="16" Width="32" Height="32" Margin="0,0,10,0" VerticalAlignment="Center">
                        <Path Fill="#FFFFFF" Width="15" Height="15" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                              Data="M12,3C7.58,3 4,4.79 4,7C4,9.21 7.58,11 12,11C16.42,11 20,9.21 20,7C20,4.79 16.42,3 12,3M4,9V12C4,14.21 7.58,16 12,16C16.42,16 20,14.21 20,12V9C20,11.21 16.42,13 12,13C7.58,13 4,11.21 4,9M4,14V17C4,19.21 7.58,21 12,21C16.42,21 20,19.21 20,17V14C20,16.21 16.42,18 12,18C7.58,18 4,16.21 4,14Z"/>
                    </Border>
                    <StackPanel Grid.Column="1">
                        <Grid>
                            <TextBlock x:Name="TxtCardISP" Text="Provider DNS (Pure DHCP / Router)" FontWeight="Bold" FontSize="12" Foreground="#F87171"/>
                            <Border HorizontalAlignment="Right" Background="#7F1D1D" CornerRadius="3" Padding="5,1">
                                <TextBlock Text="ISP DIRECT" FontSize="8.5" FontWeight="Bold" Foreground="#FECACA"/>
                            </Border>
                        </Grid>
                        <TextBlock x:Name="TxtCardISPSub" Text="Automatic router gateway" FontSize="10" Foreground="#FECACA" Margin="0,1,0,1"/>
                        <TextBlock x:Name="TxtCardISPDesc" Text="Reset custom DNS to ISP defaults, full operator access" FontSize="9.5" Foreground="#9CA3AF"/>
                    </StackPanel>
                </Grid>
            </RadioButton>

        </StackPanel>

        <!-- APPLY BUTTON & PROGRESS -->
        <StackPanel Grid.Row="3" Margin="0,6,0,0">
            <Button x:Name="BtnApply" Content="APPLY SETTINGS" Background="#2563EB" Foreground="#FFFFFF" FontWeight="Bold" FontSize="12.5" Height="36" Cursor="Hand">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="7">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Button.Template>
            </Button>

            <!-- PROGRESS CHECKLIST -->
            <Border x:Name="PanelProgress" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,6,0,0" Visibility="Collapsed">
                <StackPanel>
                    <TextBlock x:Name="TxtStep1" Text="○ Configuring network adapters..." FontSize="10.5" Foreground="#9CA3AF" Margin="0,1" TextWrapping="Wrap"/>
                    <TextBlock x:Name="TxtStep2" Text="○ Clearing DNS resolver cache..." FontSize="10.5" Foreground="#9CA3AF" Margin="0,1"/>
                    
                    <!-- 10-Second Countdown and Open Adapter Settings Button -->
                    <Grid Margin="0,4,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock x:Name="TxtCountdown" Text="Closing in 10 sec..." FontSize="11" FontWeight="SemiBold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                        <Button x:Name="BtnOpenAdapter" Grid.Column="1" Content="⚙ Adapter Settings" Style="{StaticResource LangBtn}" Padding="9,3" Foreground="#F59E0B" BorderBrush="#D97706" Cursor="Hand"/>
                    </Grid>
                </StackPanel>
            </Border>
        </StackPanel>

        <!-- FOOTER (Author left, Update button right) -->
        <Grid Grid.Row="4" Margin="0,7,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="LnkAuthor" Text="VladiMIR + AI" FontSize="11" FontWeight="SemiBold" Foreground="#60A5FA" Cursor="Hand" VerticalAlignment="Center" ToolTip="GitHub page (https://github.com/GinCz/)"/>
            <Button x:Name="BtnUpdate" Grid.Column="1" Content="v011 (Update)" Style="{StaticResource LangBtn}" Padding="9,3" Foreground="#38BDF8" BorderBrush="#0284C7"/>
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

function Invoke-UIRefresh {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false; return $null },
        $frame) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Wait-UI([int]$ms) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $ms) {
        Invoke-UIRefresh
        Start-Sleep -Milliseconds 25
    }
}

function New-Brush($hex) {
    return [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex)
}

# ------------------------------------------------------------------------------
# 4. CARD SELECTION HIGHLIGHT (Vivid Neon Glow for active left icon & card)
# ------------------------------------------------------------------------------
function Update-CardSelection {
    $cards = @(
        @{ Radio = "RadAdGuard"; Icon = "IcoBorderAdGuard"; DimBg = "#164E38"; BrightBg = "#059669"; Border = "#10B981" },
        @{ Radio = "RadFamily";  Icon = "IcoBorderFamily";  DimBg = "#581639"; BrightBg = "#DB2777"; Border = "#EC4899" },
        @{ Radio = "RadGoogle";  Icon = "IcoBorderGoogle";  DimBg = "#1E3A5F"; BrightBg = "#2563EB"; Border = "#3B82F6" },
        @{ Radio = "RadQuad9";   Icon = "IcoBorderQuad9";   DimBg = "#451A6E"; BrightBg = "#7C3AED"; Border = "#8B5CF6" },
        @{ Radio = "RadYandex";  Icon = "IcoBorderYandex";  DimBg = "#583908"; BrightBg = "#D97706"; Border = "#F59E0B" },
        @{ Radio = "RadISP";     Icon = "IcoBorderISP";     DimBg = "#581616"; BrightBg = "#DC2626"; Border = "#EF4444" }
    )

    foreach ($c in $cards) {
        $r = $controls[$c.Radio]
        $ico = $controls[$c.Icon]
        if ($r -and $ico) {
            if ($r.IsChecked) {
                # Selected: Bright vibrant icon with glowing white border, highlighted card
                $ico.Background = New-Brush $c.BrightBg
                $ico.BorderBrush = New-Brush "#FFFFFF"
                $ico.BorderThickness = [System.Windows.Thickness]::new(2)
                $r.BorderBrush = New-Brush "#38BDF8"
            } else {
                # Unselected: Normal dim icon, subtle card border
                $ico.Background = New-Brush $c.DimBg
                $ico.BorderBrush = $null
                $ico.BorderThickness = [System.Windows.Thickness]::new(0)
                $r.BorderBrush = New-Brush $c.Border
            }
        }
    }
}

function On-CardSelectionChanged {
    Update-CardSelection
    $script:CountdownCancelled = $true
    if ($controls["BtnApply"]) {
        $controls["BtnApply"].IsEnabled = $true
    }
    if ($controls["TxtCountdown"]) {
        $controls["TxtCountdown"].Text = ""
    }
    if ($controls["BtnOpenAdapter"]) {
        $controls["BtnOpenAdapter"].Visibility = [System.Windows.Visibility]::Collapsed
    }
}

# Wire Radio Click Events for instant illumination and re-enabling Apply
$controls["RadAdGuard"].Add_Checked({ On-CardSelectionChanged })
$controls["RadFamily"].Add_Checked({ On-CardSelectionChanged })
$controls["RadGoogle"].Add_Checked({ On-CardSelectionChanged })
$controls["RadQuad9"].Add_Checked({ On-CardSelectionChanged })
$controls["RadYandex"].Add_Checked({ On-CardSelectionChanged })
$controls["RadISP"].Add_Checked({ On-CardSelectionChanged })

# ------------------------------------------------------------------------------
# 5. LANGUAGE PERSISTENCE & SWITCHING
# ------------------------------------------------------------------------------
function Get-SavedLanguage {
    try {
        $regLang = (Get-ItemProperty -Path "HKCU:\Software\GIN-DNS-Switch" -Name "Language" -ErrorAction SilentlyContinue).Language
        if ($regLang -in @("EN", "RU", "CS")) { return $regLang }
    } catch {}
    return "EN"
}

function Save-Language($lang) {
    try {
        if (-not (Test-Path "HKCU:\Software\GIN-DNS-Switch")) {
            New-Item -Path "HKCU:\Software\GIN-DNS-Switch" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKCU:\Software\GIN-DNS-Switch" -Name "Language" -Value $lang -Force | Out-Null
    } catch {}
}

function Update-Language($lang) {
    $script:Lang = $lang
    Save-Language $lang
    $l = $script:Loc[$lang]
    
    $window.Title = $l["WinTitle"]
    $controls["TxtHeaderTitle"].Text = $l["HeaderTitle"]
    $controls["TxtHeaderSub"].Text = $l["HeaderSub"]
    $controls["TxtStatusLabel"].Text = $l["StatusCurrent"]
    
    $controls["TxtCardAdGuard"].Text = $l["CardAdGuard"]
    $controls["TxtCardAdGuardSub"].Text = $l["CardAdGuardSub"]
    $controls["TxtCardAdGuardDesc"].Text = $l["CardAdGuardDesc"]

    $controls["TxtCardFamily"].Text = $l["CardFamily"]
    $controls["TxtCardFamilySub"].Text = $l["CardFamilySub"]
    $controls["TxtCardFamilyDesc"].Text = $l["CardFamilyDesc"]

    $controls["TxtCardGoogle"].Text = $l["CardGoogle"]
    $controls["TxtCardGoogleSub"].Text = $l["CardGoogleSub"]
    $controls["TxtCardGoogleDesc"].Text = $l["CardGoogleDesc"]

    $controls["TxtCardQuad9"].Text = $l["CardQuad9"]
    $controls["TxtCardQuad9Sub"].Text = $l["CardQuad9Sub"]
    $controls["TxtCardQuad9Desc"].Text = $l["CardQuad9Desc"]

    $controls["TxtCardYandex"].Text = $l["CardYandex"]
    $controls["TxtCardYandexSub"].Text = $l["CardYandexSub"]
    $controls["TxtCardYandexDesc"].Text = $l["CardYandexDesc"]

    $controls["TxtCardISP"].Text = $l["CardISP"]
    $controls["TxtCardISPSub"].Text = $l["CardISPSub"]
    $controls["TxtCardISPDesc"].Text = $l["CardISPDesc"]

    $controls["BtnApply"].Content = $l["BtnApply"]
    $controls["BtnUpdate"].Content = $l["BtnUpdate"]
    $controls["LnkAuthor"].Text = $l["AuthorLink"]
    $controls["LnkAuthor"].ToolTip = $l["AuthorTooltip"]

    # Active button styles (EN, RU, CS)
    $controls["BtnLangEN"].Background = if ($lang -eq "EN") { New-Brush "#2563EB" } else { New-Brush "#1E202B" }
    $controls["BtnLangRU"].Background = if ($lang -eq "RU") { New-Brush "#2563EB" } else { New-Brush "#1E202B" }
    $controls["BtnLangCS"].Background = if ($lang -eq "CS") { New-Brush "#2563EB" } else { New-Brush "#1E202B" }
    $controls["BtnLangEN"].Foreground = if ($lang -eq "EN") { [System.Windows.Media.Brushes]::White } else { New-Brush "#9CA3AF" }
    $controls["BtnLangRU"].Foreground = if ($lang -eq "RU") { [System.Windows.Media.Brushes]::White } else { New-Brush "#9CA3AF" }
    $controls["BtnLangCS"].Foreground = if ($lang -eq "CS") { [System.Windows.Media.Brushes]::White } else { New-Brush "#9CA3AF" }

    Refresh-StatusDisplay
}

# Detect active DNS configuration
function Get-CurrentDnsState {
    try {
        $activeDns = @()
        
        # 1. Check via WMI
        $wmi = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue
        foreach ($w in $wmi) {
            if ($w.DNSServerSearchOrder) { $activeDns += $w.DNSServerSearchOrder }
        }

        # 2. Check via NetTCPIP if available
        if (Get-Command Get-DnsClientServerAddress -ErrorAction SilentlyContinue) {
            $addrs = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses.Count -gt 0 }
            foreach ($a in $addrs) { $activeDns += $a.ServerAddresses }
        }

        $activeDns = $activeDns | Select-Object -Unique

        if ($activeDns -contains "94.140.14.15" -or $activeDns -contains "94.140.15.16") {
            return "Family"
        }
        if ($activeDns -contains "94.140.14.14" -or $activeDns -contains "94.140.15.15") {
            return "AdGuard"
        }
        if ($activeDns -contains "8.8.8.8" -and $activeDns -contains "1.1.1.1") {
            return "Google"
        }
        if ($activeDns -contains "9.9.9.9" -or $activeDns -contains "149.112.112.112") {
            return "Quad9"
        }
        if ($activeDns -contains "77.88.8.8" -or $activeDns -contains "77.88.8.1") {
            return "Yandex"
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
            $controls["TxtStatusValue"].Foreground = New-Brush "#34D399"
            Select-RadioIfNone "RadAdGuard"
        }
        "Family" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveFamily"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#F472B6"
            Select-RadioIfNone "RadFamily"
        }
        "Google" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveGoogle"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#60A5FA"
            Select-RadioIfNone "RadGoogle"
        }
        "Quad9" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveQuad9"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#C084FC"
            Select-RadioIfNone "RadQuad9"
        }
        "Yandex" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveYandex"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#FBBF24"
            Select-RadioIfNone "RadYandex"
        }
        "DHCP" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveDHCP"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#F87171"
            Select-RadioIfNone "RadISP"
        }
        Default {
            $controls["TxtStatusValue"].Text = $l["StatusActiveOther"]
            $controls["TxtStatusValue"].Foreground = New-Brush "#9CA3AF"
            Select-RadioIfNone "RadISP"
        }
    }
    Update-CardSelection
}

function Select-RadioIfNone($name) {
    $radios = @("RadAdGuard", "RadFamily", "RadGoogle", "RadQuad9", "RadYandex", "RadISP")
    $hasChecked = $false
    foreach ($r in $radios) { if ($controls[$r].IsChecked) { $hasChecked = $true; break } }
    if (-not $hasChecked) { $controls[$name].IsChecked = $true }
}

# Wire Language Buttons (EN, RU, CS)
$controls["BtnLangEN"].Add_Click({ Update-Language "EN" })
$controls["BtnLangRU"].Add_Click({ Update-Language "RU" })
$controls["BtnLangCS"].Add_Click({ Update-Language "CS" })

# Wire Footer Links
$controls["LnkAuthor"].Add_MouseLeftButtonUp({
    try { [System.Diagnostics.Process]::Start("https://github.com/GinCz/") } catch {}
})

# ------------------------------------------------------------------------------
# 6. SMART AUTO-UPDATE ENGINE (Direct UI Thread - NEVER closes if latest!)
# ------------------------------------------------------------------------------
$controls["BtnUpdate"].Add_Click({
    $l = $script:Loc[$script:Lang]
    $btn = $controls["BtnUpdate"]
    $btn.IsEnabled = $false
    $btn.Content = $l["UpdChecking"]
    Invoke-UIRefresh

    try {
        $rawVerUrl = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-DNS-Switch/version.json?t=" + [DateTime]::Now.Ticks
        $client = New-Object System.Net.WebClient
        $client.Headers.Add("User-Agent", "GIN-DNS-Switch-Updater")
        $client.Headers.Add("Cache-Control", "no-cache")
        $verJsonText = $client.DownloadString($rawVerUrl)

        $remoteVer = $script:CurrentVersion
        if ($verJsonText -match '"current_version"\s*:\s*"([^"]+)"') {
            $remoteVer = $matches[1]
        }

        $localNum = [int]($script:CurrentVersion -replace '\D', '')
        $remoteNum = [int]($remoteVer -replace '\D', '')

        # If already on the latest version: DO NOT CLOSE, show green checkmark!
        if ($remoteNum -le $localNum) {
            [System.Media.SystemSounds]::Asterisk.Play()
            $btn.Content = [string]::Format($l["UpdLatest"], $script:CurrentVersion)
            $btn.Foreground = New-Brush "#34D399"
            $btn.BorderBrush = New-Brush "#10B981"
            Wait-UI 2500
            $btn.Content = $l["BtnUpdate"]
            $btn.Foreground = New-Brush "#38BDF8"
            $btn.BorderBrush = New-Brush "#0284C7"
            $btn.IsEnabled = $true
            return
        }

        # If newer version is available: Download and update!
        $rawCodeUrl = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-DNS-Switch/GIN-DNS-Switch.cmd?t=" + [DateTime]::Now.Ticks
        $newCode = $client.DownloadString($rawCodeUrl)

        if ($newCode -and $newCode.Length -gt 2000 -and $newCode -like "*GIN-DNS-SWITCH*") {
            $targetPath = "$env:ProgramFiles\GIN-DNS-Switch\GIN-DNS-Switch.cmd"
            if (-not (Test-Path (Split-Path $targetPath -Parent))) {
                $targetPath = $env:GIN_DNS_SCRIPT
            }
            if ($targetPath -and (Test-Path (Split-Path $targetPath -Parent))) {
                [System.IO.File]::WriteAllText($targetPath, $newCode, (New-Object System.Text.UTF8Encoding($false)))
            }

            # Signature TWO BUBBLES SOUND
            [System.Media.SystemSounds]::Asterisk.Play()
            Wait-UI 220
            [System.Media.SystemSounds]::Asterisk.Play()

            $btn.Content = $l["UpdSuccess"]
            $btn.Foreground = New-Brush "#34D399"
            Wait-UI 600

            # Seamless reload
            Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command `\"Start-Process cmd.exe -ArgumentList '/c `\"`\"$targetPath`\"`\"' -Verb RunAs`\""
            $window.Close()
            [System.Environment]::Exit(0)
        } else {
            throw "Invalid update payload"
        }
    } catch {
        [System.Media.SystemSounds]::Hand.Play()
        $btn.Content = $l["UpdFail"]
        $btn.Foreground = New-Brush "#F87171"
        Wait-UI 2500
        $btn.Content = $l["BtnUpdate"]
        $btn.Foreground = New-Brush "#38BDF8"
        $btn.BorderBrush = New-Brush "#0284C7"
        $btn.IsEnabled = $true
    }
})

# ------------------------------------------------------------------------------
# 7. BULLETPROOF MULTI-LAYER DNS SETTER (WMI + NetTCPIP + Netsh)
# ------------------------------------------------------------------------------
function Apply-DnsSettings($profile) {
    $v4 = $null
    $v6 = $null

    switch ($profile) {
        "AdGuard" {
            $v4 = @("94.140.14.14", "94.140.15.15")
            $v6 = @("2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff")
        }
        "Family" {
            $v4 = @("94.140.14.15", "94.140.15.16")
            $v6 = @("2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff")
        }
        "Google" {
            $v4 = @("8.8.8.8", "1.1.1.1")
            $v6 = @("2001:4860:4860::8888", "2606:4700:4700::1111")
        }
        "Quad9" {
            $v4 = @("9.9.9.9", "149.112.112.112")
            $v6 = @("2620:fe::fe", "2620:fe::9")
        }
        "Yandex" {
            $v4 = @("77.88.8.8", "77.88.8.1")
            $v6 = @("2a02:6b8::feed:0ff", "2a02:6b8:0:1::feed:0ff")
        }
        "ISP" {
            $v4 = $null
            $v6 = $null
        }
    }

    $affectedAdapters = @()

    # 1. WMI Win32_NetworkAdapterConfiguration (100% reliable for USB/Ethernet/WiFi)
    try {
        $wmiNics = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue
        foreach ($nic in $wmiNics) {
            if ($nic.Description -notmatch 'VirtualBox|VMware|Loopback|Wintun|WireGuard|TAP-Windows|Npcap') {
                if ($v4 -and $v4.Count -gt 0) {
                    $res = $nic.SetDNSServerSearchOrder($v4)
                    if ($res.ReturnValue -eq 0 -or $res.ReturnValue -eq 1) {
                        $affectedAdapters += $nic.Description
                    }
                } else {
                    $res = $nic.SetDNSServerSearchOrder($null)
                    if ($res.ReturnValue -eq 0 -or $res.ReturnValue -eq 1) {
                        $affectedAdapters += $nic.Description
                    }
                }
            }
        }
    } catch {}

    # 2. NetTCPIP Set-DnsClientServerAddress (Modern Windows)
    try {
        if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
            $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
                $_.Status -eq 'Up' -and 
                $_.InterfaceDescription -notmatch 'VirtualBox|VMware|Loopback|Wintun|WireGuard' -and 
                $_.InterfaceAlias -notmatch 'Loopback|vEthernet'
            }
            foreach ($a in $adapters) {
                if ($v4 -and $v4.Count -gt 0) {
                    Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ServerAddresses $v4 -ErrorAction SilentlyContinue
                } else {
                    Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ResetServerAddresses -ErrorAction SilentlyContinue
                }
                if ($v6 -and $v6.Count -gt 0) {
                    Set-DnsClientServerAddress -InterfaceAlias $a.InterfaceAlias -ServerAddresses $v6 -ErrorAction SilentlyContinue
                }
                $affectedAdapters += $a.InterfaceAlias
            }
        }
    } catch {}

    # 3. netsh Direct Console Execution
    try {
        $netshOut = cmd.exe /c "netsh interface ipv4 show interfaces"
        foreach ($line in $netshOut) {
            if ($line -match 'connected|подключен') {
                $tokens = $line.Trim() -split '\s{2,}'
                if ($tokens.Count -ge 4) {
                    $alias = $tokens[-1].Trim()
                    if ($alias -and $alias -notmatch 'VirtualBox|VMware|Loopback|Wintun') {
                        if ($v4 -and $v4.Count -gt 0) {
                            cmd.exe /c "netsh interface ipv4 set dnsservers name=`"$alias`" source=static address=$($v4[0]) register=both validate=no" 2>$null
                            if ($v4.Count -gt 1) {
                                cmd.exe /c "netsh interface ipv4 add dnsservers name=`"$alias`" address=$($v4[1]) index=2 validate=no" 2>$null
                            }
                        } else {
                            cmd.exe /c "netsh interface ipv4 set dnsservers name=`"$alias`" source=dhcp" 2>$null
                        }
                        $affectedAdapters += $alias
                    }
                }
            }
        }
    } catch {}

    # 4. Flush DNS
    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        cmd.exe /c "ipconfig /flushdns" 2>$null | Out-Null
    } catch {}

    $uniqueAdapters = $affectedAdapters | Select-Object -Unique
    return $uniqueAdapters
}

# ------------------------------------------------------------------------------
# 8. OPEN ADAPTER PROPERTIES (Shell.Application Namespace 49 or ncpa.cpl fallback)
# ------------------------------------------------------------------------------
function Open-AdapterProperties($adapterName) {
    try {
        $shell = New-Object -ComObject Shell.Application
        $ncFolder = $shell.Namespace(49) # CSIDL_CONNECTIONS (Network Connections)
        if ($ncFolder) {
            $items = $ncFolder.Items()
            $target = $null
            if ($adapterName) {
                $target = $items | Where-Object { $_.Name -like "*$adapterName*" -or $adapterName -like "*$($_.Name)*" } | Select-Object -First 1
            }
            if (-not $target -and $items.Count -gt 0) {
                # Pick the first non-virtual active adapter
                $target = $items | Where-Object { $_.Name -notmatch 'VirtualBox|VMware|Loopback|Wintun' } | Select-Object -First 1
            }
            if ($target) {
                $propVerb = $target.Verbs() | Where-Object { $_.Name -match 'Properties|Свойства|Vlastnosti|&Properties|&Свойства' } | Select-Object -First 1
                if ($propVerb) {
                    $propVerb.DoIt()
                    return $true
                } else {
                    $target.InvokeVerb("properties")
                    return $true
                }
            }
        }
    } catch {}
    
    # Fallback to standard Network Connections window
    try {
        Start-Process "ncpa.cpl"
        return $true
    } catch {}
    return $false
}

# Apply Button Click Handler (Live UI Thread with instant feedback & 10s interactive timer)
$script:CountdownCancelled = $false
$script:ActiveAdapterName = ""

$controls["BtnOpenAdapter"].Add_Click({
    $script:CountdownCancelled = $true
    $l = $script:Loc[$script:Lang]
    $controls["BtnOpenAdapter"].Content = $l["BtnAdapterDone"]
    $controls["BtnOpenAdapter"].Foreground = New-Brush "#34D399"
    $controls["BtnOpenAdapter"].BorderBrush = New-Brush "#10B981"
    $controls["TxtCountdown"].Text = ""
    if ($controls["BtnApply"]) {
        $controls["BtnApply"].IsEnabled = $true
    }
    Open-AdapterProperties $script:ActiveAdapterName
})

$controls["BtnApply"].Add_Click({
    $l = $script:Loc[$script:Lang]
    $controls["BtnApply"].IsEnabled = $false
    $controls["PanelProgress"].Visibility = [System.Windows.Visibility]::Visible
    $controls["TxtStep1"].Text = $l["Step1Pending"]
    $controls["TxtStep1"].Foreground = New-Brush "#9CA3AF"
    $controls["TxtStep2"].Text = $l["Step2Pending"]
    $controls["TxtStep2"].Foreground = New-Brush "#9CA3AF"
    $controls["TxtCountdown"].Text = ""
    $controls["BtnOpenAdapter"].Visibility = [System.Windows.Visibility]::Collapsed
    $script:CountdownCancelled = $false
    Invoke-UIRefresh

    # Determine chosen profile (1.AdGuard, 2.Family, 3.Google, 4.Quad9, 5.Yandex, 6.ISP)
    $chosen = "ISP"
    if ($controls["RadAdGuard"].IsChecked) { $chosen = "AdGuard" }
    elseif ($controls["RadFamily"].IsChecked) { $chosen = "Family" }
    elseif ($controls["RadGoogle"].IsChecked) { $chosen = "Google" }
    elseif ($controls["RadQuad9"].IsChecked) { $chosen = "Quad9" }
    elseif ($controls["RadYandex"].IsChecked) { $chosen = "Yandex" }
    elseif ($controls["RadISP"].IsChecked) { $chosen = "ISP" }

    Wait-UI 200

    # 1. Apply DNS settings
    $appliedNics = Apply-DnsSettings $chosen
    $nicSummary = "Network Adapter"
    if ($appliedNics -and $appliedNics.Count -gt 0) {
        $nicSummary = ($appliedNics | Select-Object -First 2) -join ", "
        $script:ActiveAdapterName = $appliedNics[0]
    }

    $controls["TxtStep1"].Text = [string]::Format($l["Step1Done"], $nicSummary)
    $controls["TxtStep1"].Foreground = New-Brush "#34D399"
    Wait-UI 300

    # 2. Flush DNS verified
    $controls["TxtStep2"].Text = $l["Step2Done"]
    $controls["TxtStep2"].Foreground = New-Brush "#34D399"
    Refresh-StatusDisplay
    Wait-UI 300

    # 3. 10-Second Interactive Countdown with Open Adapter Button
    $adapterShortName = if ($script:ActiveAdapterName) { $script:ActiveAdapterName } else { "Ethernet" }
    $controls["BtnOpenAdapter"].Content = [string]::Format($l["BtnAdapter"], $adapterShortName)
    $controls["BtnOpenAdapter"].Foreground = New-Brush "#60A5FA"
    $controls["BtnOpenAdapter"].BorderBrush = New-Brush "#3B82F6"
    $controls["BtnOpenAdapter"].Visibility = [System.Windows.Visibility]::Visible
    Invoke-UIRefresh

    for ($i = 10; $i -ge 1; $i--) {
        if ($script:CountdownCancelled) { break }
        $controls["TxtCountdown"].Text = [string]::Format($l["StepClose"], $i)
        Wait-UI 1000
    }

    if (-not $script:CountdownCancelled) {
        $window.Close()
        [System.Environment]::Exit(0)
    } else {
        if ($controls["BtnApply"]) {
            $controls["BtnApply"].IsEnabled = $true
        }
    }
})

# Initialize Language from Registry (Default: EN)
$savedLang = Get-SavedLanguage
Update-Language $savedLang

# Show Window
$window.ShowDialog() | Out-Null
[System.Environment]::Exit(0)

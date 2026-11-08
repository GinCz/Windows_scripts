<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-DNS-Switch v006 [ VladiMIR ^& Antigravity ]

:: Detect PowerShell executable (supports x86, x64, Sysnative)
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:: Auto-Elevation: Ensure Full Administrator Privileges on Windows 7 / 8 / 10 / 11
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges for GIN-DNS-Switch v006...
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
#  GIN-DNS-SWITCH                                                  v006
#  Smart 1-Click DNS Profile Manager for Windows 7 / 8 / 10 / 11
#  Author: Vladimir Bulantsev (GinCz) & AI [VladiMIR + AI]
#  Repository: https://github.com/GinCz/
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
# 1. LOCALIZATION STRINGS (RU, EN, CS)
# ------------------------------------------------------------------------------
$script:Lang = "RU"
$script:CurrentVersion = "v006"

$script:Loc = @{
    "RU" = @{
        "WinTitle"       = "GIN-DNS-Switch v006 — Менеджер DNS для Windows"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Умный переключатель DNS"
        "StatusCurrent"  = "Текущий статус:"
        "StatusDetect"   = "Определение..."
        "SecModes"       = "ВЫБЕРИТЕ ПРОФИЛЬ DNS ДЛЯ ВСЕЙ СИСТЕМЫ (6 РЕЖИМОВ):"
        "CardAdGuard"    = "AdGuard DNS (Без рекламы)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Полная блокировка баннеров, трекеров и фишинга во всей Windows"
        "CardGoogle"     = "Google + Cloudflare (Макс. скорость и ТВ)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ультра-скорость, Google Cast, трансляция на Android TV и банкинг"
        "CardISP"        = "DNS провайдера (Чистый DHCP / Роутер)"
        "CardISPSub"     = "Автоматический шлюз роутера"
        "CardISPDesc"    = "Сброс сторонних DNS, полный доступ к сети и порталам оператора"
        "CardYandex"     = "Яндекс.DNS (Россия, Сертификаты, Госуслуги)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Оптимизирован для РФ. Госуслуги, Сбер, ВТБ, сертификаты Минцифры"
        "CardQuad9"      = "Quad9 Security (Защита от вирусов)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Блокирует фишинг и вредоносы (ТВ и стриминг работают без сбоев)"
        "CardFamily"     = "Семейный DNS (Детский режим 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Блокировка рекламы, контента 18+ и принудительный SafeSearch"
        "BtnApply"       = "ПРИМЕНИТЬ НАСТРОЙКИ"
        "Step1Pending"   = "○ Настройка сетевых адаптеров..."
        "Step1Done"      = "✔ DNS прописан: {0}"
        "Step2Pending"   = "○ Очистка кэша сопоставителя DNS..."
        "Step2Done"      = "✔ Кэш сопоставителя DNS очищен (Flush DNS)"
        "StepClose"      = "Закрытие через {0} сек..."
        "BtnUpdate"      = "v006 (Обновить)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Активен: AdGuard DNS (Блокировка рекламы)"
        "StatusActiveGoogle"  = "Активен: Google + Cloudflare (Скорость и ТВ)"
        "StatusActiveDHCP"    = "Активен: DNS провайдера (DHCP / Роутер)"
        "StatusActiveYandex"  = "Активен: Яндекс.DNS (Россия и Госуслуги)"
        "StatusActiveQuad9"   = "Активен: Quad9 Security (Защита)"
        "StatusActiveFamily"  = "Активен: Семейный DNS (Детский режим)"
        "StatusActiveOther"   = "Активен: Пользовательский DNS"
        "UpdChecking"    = "Проверка..."
        "UpdLatest"      = "✔ У вас последняя версия ({0})"
        "UpdSuccess"     = "✔ Обновлено до {0}!"
        "Step1Fail"      = "✖ DNS НЕ применился: {0} (см. лог)"
        "UpdFail"        = "✖ Нет связи с GitHub"
    }
    "EN" = @{
        "WinTitle"       = "GIN-DNS-Switch v006 — Windows DNS Manager"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Smart DNS Switcher"
        "StatusCurrent"  = "Current status:"
        "StatusDetect"   = "Detecting..."
        "SecModes"       = "SELECT SYSTEM-WIDE DNS PROFILE (6 MODES):"
        "CardAdGuard"    = "AdGuard DNS (No Ads)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Blocks ads, trackers, and phishing across all Windows apps"
        "CardGoogle"     = "Google + Cloudflare (Ultra Fast & TV)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ultra-low latency, Google Cast, Android TV & Banking OK"
        "CardISP"        = "Provider DNS (Pure DHCP / Router)"
        "CardISPSub"     = "Automatic Router Gateway"
        "CardISPDesc"    = "Reset third-party DNS, full access to ISP network portals"
        "CardYandex"     = "Yandex.DNS (Russia & Gov Certificates)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Optimized for RU services, Gosuslugi, Sberbank, Russian certs"
        "CardQuad9"      = "Quad9 Security (Malware Protection)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Blocks malware and phishing (TV & streaming work reliably)"
        "CardFamily"     = "Family DNS (Child Safe 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Ad blocking, strict SafeSearch, and adult 18+ content filter"
        "BtnApply"       = "APPLY SETTINGS"
        "Step1Pending"   = "○ Configuring network adapters..."
        "Step1Done"      = "✔ DNS set: {0}"
        "Step2Pending"   = "○ Clearing DNS resolver cache..."
        "Step2Done"      = "✔ DNS resolver cache flushed (Flush DNS)"
        "StepClose"      = "Closing in {0} sec..."
        "BtnUpdate"      = "v006 (Update)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Active: AdGuard DNS (AdBlock)"
        "StatusActiveGoogle"  = "Active: Google + Cloudflare (Speed & TV)"
        "StatusActiveDHCP"    = "Active: Provider DNS (DHCP / Router)"
        "StatusActiveYandex"  = "Active: Yandex.DNS (Russia & Certs)"
        "StatusActiveQuad9"   = "Active: Quad9 Security (Protection)"
        "StatusActiveFamily"  = "Active: Family DNS (Child Safe)"
        "StatusActiveOther"   = "Active: Custom DNS"
        "UpdChecking"    = "Checking..."
        "UpdLatest"      = "✔ You have the latest version ({0})"
        "UpdSuccess"     = "✔ Updated to {0}!"
        "Step1Fail"      = "✖ DNS NOT applied: {0} (see log)"
        "UpdFail"        = "✖ GitHub unreachable"
    }
    "CS" = @{
        "WinTitle"       = "GIN-DNS-Switch v006 — Správce DNS pro Windows"
        "HeaderTitle"    = "GIN-DNS-Switch"
        "HeaderSub"      = "Chytrý přepínač DNS"
        "StatusCurrent"  = "Aktuální stav:"
        "StatusDetect"   = "Zjišťování..."
        "SecModes"       = "VYBERTE PROFIL DNS PRO CELÝ SYSTÉM (6 REŽIMŮ):"
        "CardAdGuard"    = "AdGuard DNS (Bez reklam)"
        "CardAdGuardSub" = "94.140.14.14  •  94.140.15.15"
        "CardAdGuardDesc"= "Blokování reklam a trackerů ve všech aplikacích Windows"
        "CardGoogle"     = "Google + Cloudflare (Max. rychlost a TV)"
        "CardGoogleSub"  = "8.8.8.8  •  1.1.1.1"
        "CardGoogleDesc" = "Ultra nízká odezva, Google Cast, Android TV i banky"
        "CardISP"        = "DNS poskytovatele (Čisté DHCP / Router)"
        "CardISPSub"     = "Automatická brána routeru"
        "CardISPDesc"    = "Reset cizích DNS, přímý přístup k síti operátora"
        "CardYandex"     = "Yandex.DNS (Rusko a státní certifikáty)"
        "CardYandexSub"  = "77.88.8.8  •  77.88.8.1"
        "CardYandexDesc" = "Optimalizováno pro RU služby, Gosuslugi, Sber a ruské certifikáty"
        "CardQuad9"      = "Quad9 Security (Ochrana proti virům)"
        "CardQuad9Sub"   = "9.9.9.9  •  149.112.112.112"
        "CardQuad9Desc"  = "Blokuje phishing a malware (TV a streamování fungují spolehlivě)"
        "CardFamily"     = "Rodinný DNS (Dětský režim 18+)"
        "CardFamilySub"  = "94.140.14.15  •  94.140.15.16"
        "CardFamilyDesc" = "Blokování reklam, filtr 18+ obsahu a vynucený SafeSearch"
        "BtnApply"       = "POUŽÍT NASTAVENÍ"
        "Step1Pending"   = "○ Konfigurace síťových adaptérů..."
        "Step1Done"      = "✔ DNS nastaven: {0}"
        "Step2Pending"   = "○ Vyprázdnění mezipaměti DNS..."
        "Step2Done"      = "✔ Mezipaměť DNS byla vyprázdněna (Flush DNS)"
        "StepClose"      = "Zavření za {0} s..."
        "BtnUpdate"      = "v006 (Aktualizovat)"
        "AuthorLink"     = "VladiMIR + AI"
        "StatusActiveAdGuard" = "Aktivní: AdGuard DNS (Blokování reklam)"
        "StatusActiveGoogle"  = "Aktivní: Google + Cloudflare (Rychlost a TV)"
        "StatusActiveDHCP"    = "Aktivní: DNS poskytovatele (DHCP / Router)"
        "StatusActiveYandex"  = "Aktivní: Yandex.DNS (Rusko a certifikáty)"
        "StatusActiveQuad9"   = "Aktivní: Quad9 Security (Ochrana)"
        "StatusActiveFamily"  = "Aktivní: Rodinný DNS (Dětský režim)"
        "StatusActiveOther"   = "Aktivní: Vlastní DNS"
        "UpdChecking"    = "Kontrola..."
        "UpdLatest"      = "✔ Máte nejnovější verzi ({0})"
        "UpdSuccess"     = "✔ Aktualizováno na {0}!"
        "Step1Fail"      = "✖ DNS NEBYL použit: {0} (viz log)"
        "UpdFail"        = "✖ GitHub nedostupný"
    }
}

# ------------------------------------------------------------------------------
# 2. XAML DEFINITION (WPF Modern Dark UI with 6 Clean Stacked Cards)
# ------------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GIN-DNS-Switch v006" SizeToContent="Height" Width="510"
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
                        <Border x:Name="CardBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1.5" CornerRadius="8" Padding="12,8" Margin="0,3" Cursor="Hand">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CardBorder" Property="Opacity" Value="0.95"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="CardBorder" Property="BorderThickness" Value="2.2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18,12,18,12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Status pill -->
            <RowDefinition Height="Auto"/> <!-- Section Title -->
            <RowDefinition Height="Auto"/> <!-- 6 Cards -->
            <RowDefinition Height="Auto"/> <!-- Apply Button -->
            <RowDefinition Height="Auto"/> <!-- Progress Checklist -->
            <RowDefinition Height="Auto"/> <!-- Footer -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                <TextBlock x:Name="TxtHeaderTitle" Text="" Visibility="Collapsed"/>
                <TextBlock x:Name="TxtHeaderSub" Text="Умный переключатель DNS" FontSize="16" FontWeight="Bold" Foreground="#60A5FA" VerticalAlignment="Center"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnLangRU" Content="RU" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangEN" Content="EN" Style="{StaticResource LangBtn}"/>
                <Button x:Name="BtnLangCS" Content="CS" Style="{StaticResource LangBtn}"/>
            </StackPanel>
        </Grid>

        <!-- CURRENT STATUS PILL -->
        <Border Grid.Row="1" Background="#1A1C26" BorderBrush="#2D3142" BorderThickness="1" CornerRadius="6" Padding="10,5" Margin="0,8,0,6">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="TxtStatusLabel" Text="Текущий статус:" FontSize="11" Foreground="#6B7280" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <TextBlock x:Name="TxtStatusValue" Grid.Column="1" Text="Определение..." FontSize="12" FontWeight="SemiBold" Foreground="#34D399" VerticalAlignment="Center"/>
            </Grid>
        </Border>
        <TextBlock x:Name="TxtSecModes" Grid.Row="2" Visibility="Collapsed"/>

        <!-- 6 CARDS (no scroll) -->
        <StackPanel Grid.Row="3">

                <!-- CARD 1: AdGuard (Green) -->
                <RadioButton x:Name="RadAdGuard" Style="{StaticResource RadioCard}" Background="#0F241C" BorderBrush="#10B981" GroupName="DnsGroup">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border Background="#164E38" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="17" Height="17" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1Z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardAdGuard" Text="AdGuard DNS (Без рекламы)" FontWeight="Bold" FontSize="12.5" Foreground="#34D399"/>
                                <Border HorizontalAlignment="Right" Background="#064E3B" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="BLOCK ADS" FontSize="8.5" FontWeight="Bold" Foreground="#6EE7B7"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardAdGuardSub" Text="94.140.14.14  •  94.140.15.15" FontSize="10.5" Foreground="#A7F3D0" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardAdGuardDesc" Text="Полная блокировка баннеров, трекеров и фишинга во всей Windows" FontSize="10" Foreground="#9CA3AF"/>
                        </StackPanel>
                    </Grid>
                </RadioButton>

                <!-- CARD 6: Семейный DNS (Pink - Детский режим) -->
                <RadioButton x:Name="RadFamily" Style="{StaticResource RadioCard}" Background="#281120" BorderBrush="#EC4899" GroupName="DnsGroup">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border Background="#831843" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="16" Height="16" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M12,21.35L10.55,20.03C5.4,15.36 2,12.27 2,8.5C2,5.41 4.42,3 7.5,3C9.24,3 10.91,3.81 12,5.08C13.09,3.81 14.76,3 16.5,3C19.58,3 22,5.41 22,8.5C22,12.27 18.6,15.36 13.45,20.03L12,21.35Z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardFamily" Text="Семейный DNS (Детский режим 18+)" FontWeight="Bold" FontSize="12.5" Foreground="#F472B6"/>
                                <Border HorizontalAlignment="Right" Background="#831843" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="SAFE KIDS 18+" FontSize="8.5" FontWeight="Bold" Foreground="#FBCFE8"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardFamilySub" Text="94.140.14.15  •  94.140.15.16" FontSize="10.5" Foreground="#FBCFE8" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardFamilyDesc" Text="Блокировка рекламы, контента 18+ и принудительный SafeSearch" FontSize="10" Foreground="#9CA3AF"/>
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
                        <Border Background="#1E3A8A" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="16" Height="16" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M7 2v11h3v9l7-12h-4l4-8z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardGoogle" Text="Google + Cloudflare (Макс. скорость и ТВ)" FontWeight="Bold" FontSize="12.5" Foreground="#60A5FA"/>
                                <Border HorizontalAlignment="Right" Background="#1E3A8A" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="FAST &amp; TV" FontSize="8.5" FontWeight="Bold" Foreground="#93C5FD"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardGoogleSub" Text="8.8.8.8  •  1.1.1.1" FontSize="10.5" Foreground="#BAE6FD" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardGoogleDesc" Text="Ультра-скорость, Google Cast, трансляция на Android TV и банкинг" FontSize="10" Foreground="#9CA3AF"/>
                        </StackPanel>
                    </Grid>
                </RadioButton>

                <!-- CARD 5: Quad9 Security (Purple - Антивирус) -->
                <RadioButton x:Name="RadQuad9" Style="{StaticResource RadioCard}" Background="#1E142B" BorderBrush="#A855F7" GroupName="DnsGroup">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border Background="#581C87" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="16" Height="16" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M12,17A2,2 0 0,0 14,15C14,13.89 13.1,13 12,13A2,2 0 0,0 10,15A2,2 0 0,0 12,17M18,8A2,2 0 0,1 20,10V20A2,2 0 0,1 18,22H6A2,2 0 0,1 4,20V10C4,8.89 4.89,8 6,8H7V6A5,5 0 0,1 12,1A5,5 0 0,1 17,6V8H18M12,3A3,3 0 0,0 9,6V8H15V6A3,3 0 0,0 12,3Z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardQuad9" Text="Quad9 Security (Защита от вирусов)" FontWeight="Bold" FontSize="12.5" Foreground="#C084FC"/>
                                <Border HorizontalAlignment="Right" Background="#581C87" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="MALWARE BLOCK" FontSize="8.5" FontWeight="Bold" Foreground="#E9D5FF"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardQuad9Sub" Text="9.9.9.9  •  149.112.112.112" FontSize="10.5" Foreground="#E9D5FF" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardQuad9Desc" Text="Блокирует фишинг и вредоносы (ТВ и стриминг работают без сбоев)" FontSize="10" Foreground="#9CA3AF"/>
                        </StackPanel>
                    </Grid>
                </RadioButton>

                <!-- CARD 4: Яндекс.DNS (Amber/Gold - Россия) -->
                <RadioButton x:Name="RadYandex" Style="{StaticResource RadioCard}" Background="#271E0F" BorderBrush="#F59E0B" GroupName="DnsGroup">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border Background="#78350F" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="17" Height="17" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardYandex" Text="Яндекс.DNS (Россия, Сертификаты, Госуслуги)" FontWeight="Bold" FontSize="12.5" Foreground="#FBBF24"/>
                                <Border HorizontalAlignment="Right" Background="#78350F" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="RUSSIA &amp; CERTS" FontSize="8.5" FontWeight="Bold" Foreground="#FDE68A"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardYandexSub" Text="77.88.8.8  •  77.88.8.1" FontSize="10.5" Foreground="#FDE68A" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardYandexDesc" Text="Оптимизирован для РФ. Госуслуги, Сбер, ВТБ, сертификаты Минцифры" FontSize="10" Foreground="#9CA3AF"/>
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
                        <Border Background="#7F1D1D" CornerRadius="18" Width="36" Height="36" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Fill="#FFFFFF" Width="17" Height="17" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Data="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
                        </Border>
                        <StackPanel Grid.Column="1">
                            <Grid>
                                <TextBlock x:Name="TxtCardISP" Text="DNS провайдера (Чистый DHCP / Роутер)" FontWeight="Bold" FontSize="12.5" Foreground="#F87171"/>
                                <Border HorizontalAlignment="Right" Background="#5F1010" CornerRadius="3" Padding="5,1">
                                    <TextBlock Text="ISP DIRECT" FontSize="8.5" FontWeight="Bold" Foreground="#FCA5A5"/>
                                </Border>
                            </Grid>
                            <TextBlock x:Name="TxtCardISPSub" Text="Автоматический шлюз роутера" FontSize="10.5" Foreground="#FECDD3" Margin="0,1,0,1"/>
                            <TextBlock x:Name="TxtCardISPDesc" Text="Сброс сторонних DNS, полный доступ к сети и порталам оператора" FontSize="10" Foreground="#9CA3AF"/>
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
        <Border x:Name="PanelProgress" Grid.Row="5" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="6" Padding="12,7" Margin="0,6,0,0" Visibility="Collapsed">
            <StackPanel>
                <TextBlock x:Name="TxtStep1" Text="○ Настройка сетевых адаптеров..." FontSize="11" Foreground="#9CA3AF" Margin="0,1" TextWrapping="Wrap"/>
                <TextBlock x:Name="TxtStep2" Text="○ Очистка кэша сопоставителя DNS..." FontSize="11" Foreground="#9CA3AF" Margin="0,1"/>
                <TextBlock x:Name="TxtCountdown" Text="Закрытие через 3 сек..." FontSize="11.5" FontWeight="SemiBold" Foreground="#38BDF8" Margin="0,2,0,0"/>
            </StackPanel>
        </Border>

        <!-- FOOTER -->
        <Grid Grid.Row="6" Margin="0,8,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="LnkAuthor" Text="VladiMIR + AI" FontSize="11" FontWeight="SemiBold" Foreground="#60A5FA" Cursor="Hand" VerticalAlignment="Center" ToolTip="Открыть главную страницу GitHub (https://github.com/GinCz/)"/>
            <Button x:Name="BtnUpdate" Grid.Column="1" Content="v006 (Обновить)" Style="{StaticResource LangBtn}" Padding="10,3" Foreground="#38BDF8" BorderBrush="#0284C7"/>
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

    $controls["TxtCardYandex"].Text = $l["CardYandex"]
    $controls["TxtCardYandexSub"].Text = $l["CardYandexSub"]
    $controls["TxtCardYandexDesc"].Text = $l["CardYandexDesc"]

    $controls["TxtCardQuad9"].Text = $l["CardQuad9"]
    $controls["TxtCardQuad9Sub"].Text = $l["CardQuad9Sub"]
    $controls["TxtCardQuad9Desc"].Text = $l["CardQuad9Desc"]

    $controls["TxtCardFamily"].Text = $l["CardFamily"]
    $controls["TxtCardFamilySub"].Text = $l["CardFamilySub"]
    $controls["TxtCardFamilyDesc"].Text = $l["CardFamilyDesc"]

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
        
        # 1. Check via WMI (Always works regardless of PowerShell modules)
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
        if ($activeDns -contains "77.88.8.8" -or $activeDns -contains "77.88.8.1") {
            return "Yandex"
        }
        if ($activeDns -contains "9.9.9.9" -or $activeDns -contains "149.112.112.112") {
            return "Quad9"
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
            Select-RadioIfNone "RadAdGuard"
        }
        "Google" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveGoogle"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60A5FA")
            Select-RadioIfNone "RadGoogle"
        }
        "DHCP" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveDHCP"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            Select-RadioIfNone "RadISP"
        }
        "Yandex" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveYandex"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            Select-RadioIfNone "RadYandex"
        }
        "Quad9" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveQuad9"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C084FC")
            Select-RadioIfNone "RadQuad9"
        }
        "Family" {
            $controls["TxtStatusValue"].Text = $l["StatusActiveFamily"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F472B6")
            Select-RadioIfNone "RadFamily"
        }
        Default {
            $controls["TxtStatusValue"].Text = $l["StatusActiveOther"]
            $controls["TxtStatusValue"].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF")
            Select-RadioIfNone "RadISP"
        }
    }
}

function Select-RadioIfNone($name) {
    $radios = @("RadAdGuard", "RadGoogle", "RadISP", "RadYandex", "RadQuad9", "RadFamily")
    $hasChecked = $false
    foreach ($r in $radios) { if ($controls[$r].IsChecked) { $hasChecked = $true; break } }
    if (-not $hasChecked) { $controls[$name].IsChecked = $true }
}

# Wire Language Buttons
$controls["BtnLangRU"].Add_Click({ Update-Language "RU" })
$controls["BtnLangEN"].Add_Click({ Update-Language "EN" })
$controls["BtnLangCS"].Add_Click({ Update-Language "CS" })

# Wire Footer Links
$controls["LnkAuthor"].Add_MouseLeftButtonUp({
    try { [System.Diagnostics.Process]::Start("https://github.com/GinCz/") } catch {}
})

# ------------------------------------------------------------------------------
# 4. UI HELPERS (all work runs on the UI thread - PowerShell scriptblocks have
#    NO runspace on ThreadPool threads, which silently killed v003-v005 actions)
# ------------------------------------------------------------------------------
function Write-Log($msg) {
    try { Add-Content -Path (Join-Path $env:TEMP "GIN-DNS-Switch.log") -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
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
    while ($sw.ElapsedMilliseconds -lt $ms) { Invoke-UIRefresh; Start-Sleep -Milliseconds 25 }
}

function New-Brush($hex) { return [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex) }

# ------------------------------------------------------------------------------
# 5. SMART UPDATE (checks version.json; shows green check if already latest)
# ------------------------------------------------------------------------------
$controls["BtnUpdate"].Add_Click({
    $l = $script:Loc[$script:Lang]
    $btn = $controls["BtnUpdate"]
    $btn.IsEnabled = $false
    $btn.Content = $l["UpdChecking"]
    Invoke-UIRefresh
    try {
        $base = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-DNS-Switch"
        $client = New-Object System.Net.WebClient
        $client.Headers.Add("User-Agent", "GIN-DNS-Switch-Updater")
        $client.Headers.Add("Cache-Control", "no-cache")
        $verJson = $client.DownloadString("$base/version.json?t=" + [DateTime]::Now.Ticks)
        $remoteVer = $script:CurrentVersion
        if ($verJson -match '"current_version"\s*:\s*"([^"]+)"') { $remoteVer = $matches[1] }
        Write-Log "Update check: local=$($script:CurrentVersion) remote=$remoteVer"

        if ([int]($remoteVer -replace '\D', '') -le [int]($script:CurrentVersion -replace '\D', '')) {
            [System.Media.SystemSounds]::Asterisk.Play()
            $btn.Content = [string]::Format($l["UpdLatest"], $script:CurrentVersion)
            $btn.Foreground = New-Brush "#34D399"
            $btn.BorderBrush = New-Brush "#10B981"
            Wait-UI 3000
            $btn.Content = $l["BtnUpdate"]
            $btn.Foreground = New-Brush "#38BDF8"
            $btn.BorderBrush = New-Brush "#0284C7"
            $btn.IsEnabled = $true
            return
        }

        $newCode = $client.DownloadString("$base/GIN-DNS-Switch.cmd?t=" + [DateTime]::Now.Ticks)
        if (-not $newCode -or $newCode.Length -lt 2000 -or $newCode -notlike "*GIN-DNS-SWITCH*") { throw "Invalid payload" }

        $instDir = Join-Path $env:ProgramFiles "GIN-DNS-Switch"
        $targets = @((Join-Path $instDir "GIN-DNS-Switch.cmd"), $env:GIN_DNS_SCRIPT) | Where-Object { $_ } | Select-Object -Unique
        foreach ($p in $targets) {
            if (Test-Path (Split-Path $p -Parent)) { [System.IO.File]::WriteAllText($p, $newCode, (New-Object System.Text.UTF8Encoding($false))) }
        }

        # Signature TWO BUBBLES (два булька)
        [System.Media.SystemSounds]::Asterisk.Play()
        Wait-UI 250
        [System.Media.SystemSounds]::Asterisk.Play()
        $btn.Content = [string]::Format($l["UpdSuccess"], $remoteVer)
        $btn.Foreground = New-Brush "#34D399"
        Wait-UI 900

        $launch = Join-Path $instDir "GIN-DNS-Switch.cmd"
        if (-not (Test-Path $launch)) { $launch = $env:GIN_DNS_SCRIPT }
        Start-Process cmd.exe -ArgumentList "/c `"`"$launch`"`"" -WindowStyle Hidden
        $window.Close()
    } catch {
        Write-Log "Update error: $($_.Exception.Message)"
        [System.Media.SystemSounds]::Hand.Play()
        $btn.Content = $l["UpdFail"]
        $btn.Foreground = New-Brush "#F87171"
        Wait-UI 3000
        $btn.Content = $l["BtnUpdate"]
        $btn.Foreground = New-Brush "#38BDF8"
        $btn.IsEnabled = $true
    }
})

# ------------------------------------------------------------------------------
# 6. DNS ENGINE: Registry (what the IPv4 dialog shows) + WMI + netsh + NetTCPIP,
#    then READ-BACK verification from the registry.
# ------------------------------------------------------------------------------
function Get-ProfileDns($profile) {
    switch ($profile) {
        "AdGuard" { return @{ v4 = @("94.140.14.14", "94.140.15.15"); v6 = @("2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff") } }
        "Family"  { return @{ v4 = @("94.140.14.15", "94.140.15.16"); v6 = @("2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff") } }
        "Google"  { return @{ v4 = @("8.8.8.8", "1.1.1.1"); v6 = @("2001:4860:4860::8888", "2606:4700:4700::1111") } }
        "Quad9"   { return @{ v4 = @("9.9.9.9", "149.112.112.112"); v6 = @("2620:fe::fe", "2620:fe::9") } }
        "Yandex"  { return @{ v4 = @("77.88.8.8", "77.88.8.1"); v6 = @("2a02:6b8::feed:0ff", "2a02:6b8:0:1::feed:0ff") } }
        default   { return @{ v4 = @(); v6 = @() } }
    }
}

function Get-TargetNics {
    $result = @()
    $cfgs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue
    foreach ($c in $cfgs) {
        $desc = [string]$c.Description
        if ($desc -match 'VirtualBox|VMware|Hyper-V|Loopback|WAN Miniport|Wintun|WireGuard|TAP-Windows|Npcap') { continue }
        $ad = Get-WmiObject -Class Win32_NetworkAdapter -Filter "Index = $($c.Index)" -ErrorAction SilentlyContinue
        $result += [pscustomobject]@{ Cfg = $c; Name = [string]$ad.NetConnectionID; Desc = $desc; Guid = [string]$c.SettingID; IfIndex = [int]$c.InterfaceIndex }
    }
    return $result
}

function Apply-DnsSettings($profile) {
    $dns = Get-ProfileDns $profile
    $v4 = [string[]]$dns.v4
    $v6 = [string[]]$dns.v6
    $isStatic = ($v4.Count -gt 0)
    $report = @()

    $nics = Get-TargetNics
    Write-Log "Apply profile=$profile nics=$(($nics | ForEach-Object { $_.Name + ' [' + $_.Desc + ']' }) -join '; ')"

    foreach ($n in $nics) {
        # 1) Registry - exactly what "Use the following DNS server addresses" reads
        try {
            $k4 = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.Guid)"
            if (Test-Path $k4) { Set-ItemProperty -Path $k4 -Name "NameServer" -Value ($(if ($isStatic) { $v4 -join "," } else { "" })) -Type String -Force }
            $k6 = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$($n.Guid)"
            if (Test-Path $k6) { Set-ItemProperty -Path $k6 -Name "NameServer" -Value ($(if ($isStatic) { $v6 -join "," } else { "" })) -Type String -Force }
        } catch { Write-Log "Registry error $($n.Name): $($_.Exception.Message)" }

        # 2) WMI
        try {
            if ($isStatic) { $r = $n.Cfg.SetDNSServerSearchOrder($v4) } else { $r = $n.Cfg.SetDNSServerSearchOrder() }
            Write-Log "WMI $($n.Name) rc=$($r.ReturnValue)"
        } catch { Write-Log "WMI error $($n.Name): $($_.Exception.Message)" }

        # 3) netsh (validate=no -> instant, no DNS probing)
        if ($n.Name) {
            if ($isStatic) {
                & netsh.exe interface ipv4 set dnsservers "name=$($n.Name)" source=static "address=$($v4[0])" register=primary validate=no | Out-Null
                for ($i = 1; $i -lt $v4.Count; $i++) { & netsh.exe interface ipv4 add dnsservers "name=$($n.Name)" "address=$($v4[$i])" "index=$($i + 1)" validate=no | Out-Null }
                if ($v6.Count -gt 0) {
                    & netsh.exe interface ipv6 set dnsservers "name=$($n.Name)" source=static "address=$($v6[0])" register=primary validate=no | Out-Null
                    for ($i = 1; $i -lt $v6.Count; $i++) { & netsh.exe interface ipv6 add dnsservers "name=$($n.Name)" "address=$($v6[$i])" "index=$($i + 1)" validate=no | Out-Null }
                }
            } else {
                & netsh.exe interface ipv4 set dnsservers "name=$($n.Name)" source=dhcp | Out-Null
                & netsh.exe interface ipv6 set dnsservers "name=$($n.Name)" source=dhcp | Out-Null
            }
        }

        # 4) NetTCPIP (Win8+): v4 and v6 in ONE call so one list never wipes the other
        try {
            if (Get-Command Set-DnsClientServerAddress -ErrorAction SilentlyContinue) {
                if ($isStatic) { Set-DnsClientServerAddress -InterfaceIndex $n.IfIndex -ServerAddresses (@($v4) + @($v6)) -ErrorAction Stop }
                else { Set-DnsClientServerAddress -InterfaceIndex $n.IfIndex -ResetServerAddresses -ErrorAction Stop }
            }
        } catch { Write-Log "NetTCPIP $($n.Name): $($_.Exception.Message)" }

        # 5) READ-BACK verification from registry
        $actual = ""
        try { $actual = [string](Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.Guid)" -Name NameServer -ErrorAction Stop).NameServer } catch {}
        $ok = $(if ($isStatic) { $actual -eq ($v4 -join ",") -or $actual -eq ($v4 -join " ") } else { [string]::IsNullOrWhiteSpace($actual) })
        Write-Log "Verify $($n.Name): NameServer='$actual' ok=$ok"
        $label = $(if ($n.Name) { $n.Name } else { $n.Desc })
        $report += [pscustomobject]@{ Name = $label; Ok = $ok; Actual = $actual }
    }

    try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch {}
    & ipconfig.exe /flushdns | Out-Null
    return ,$report
}

# Apply Button Click Handler (synchronous on UI thread with live refresh)
$controls["BtnApply"].Add_Click({
    $l = $script:Loc[$script:Lang]
    $controls["BtnApply"].IsEnabled = $false
    $controls["PanelProgress"].Visibility = [System.Windows.Visibility]::Visible
    $controls["TxtStep1"].Text = $l["Step1Pending"]
    $controls["TxtStep1"].Foreground = New-Brush "#9CA3AF"
    $controls["TxtStep2"].Text = $l["Step2Pending"]
    $controls["TxtStep2"].Foreground = New-Brush "#9CA3AF"
    $controls["TxtCountdown"].Text = ""
    Invoke-UIRefresh

    $chosen = "ISP"
    if ($controls["RadAdGuard"].IsChecked) { $chosen = "AdGuard" }
    elseif ($controls["RadFamily"].IsChecked) { $chosen = "Family" }
    elseif ($controls["RadGoogle"].IsChecked) { $chosen = "Google" }
    elseif ($controls["RadQuad9"].IsChecked) { $chosen = "Quad9" }
    elseif ($controls["RadYandex"].IsChecked) { $chosen = "Yandex" }

    $report = @()
    try { $report = Apply-DnsSettings $chosen } catch { Write-Log "Apply fatal: $($_.Exception.Message)" }

    $okNics = @($report | Where-Object { $_.Ok })
    $badNics = @($report | Where-Object { -not $_.Ok })
    if ($report.Count -gt 0 -and $badNics.Count -eq 0) {
        $dnsText = $(if ($chosen -eq "ISP") { "DHCP" } else { (Get-ProfileDns $chosen).v4 -join ", " })
        $controls["TxtStep1"].Text = [string]::Format($l["Step1Done"], (($okNics | ForEach-Object { $_.Name }) -join ", ") + " → " + $dnsText)
        $controls["TxtStep1"].Foreground = New-Brush "#34D399"
    } else {
        $names = $(if ($badNics.Count -gt 0) { ($badNics | ForEach-Object { $_.Name }) -join ", " } else { "—" })
        $controls["TxtStep1"].Text = [string]::Format($l["Step1Fail"], $names)
        $controls["TxtStep1"].Foreground = New-Brush "#F87171"
        [System.Media.SystemSounds]::Hand.Play()
    }
    Wait-UI 300

    $controls["TxtStep2"].Text = $l["Step2Done"]
    $controls["TxtStep2"].Foreground = New-Brush "#34D399"
    Refresh-StatusDisplay
    Invoke-UIRefresh

    if ($badNics.Count -gt 0 -or $report.Count -eq 0) {
        $controls["TxtCountdown"].Text = "Log: %TEMP%\GIN-DNS-Switch.log"
        $controls["TxtCountdown"].Foreground = New-Brush "#F87171"
        $controls["BtnApply"].IsEnabled = $true
        return
    }

    for ($i = 3; $i -ge 1; $i--) {
        $controls["TxtCountdown"].Text = [string]::Format($l["StepClose"], $i)
        Wait-UI 1000
    }
    $window.Close()
})

# Initialize Default Language and Status
Update-Language "RU"

# Show Window
$window.ShowDialog() | Out-Null
[System.Environment]::Exit(0)

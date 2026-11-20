using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Globalization;
using System.IO;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("GIN-Dock-Wallpaper")]
[assembly: AssemblyDescription("Smart Hot-Corner Dock Bar & 4K Wallpaper Calendar HUD Engine for Windows")]
[assembly: AssemblyCompany("VladiMIR+AI")]
[assembly: AssemblyProduct("GIN-Dock-Wallpaper")]
[assembly: AssemblyCopyright("Copyright © 2026 Vladimir Bulantsev")]
[assembly: AssemblyVersion("0.32.0.0")]
[assembly: AssemblyFileVersion("0.32.0.0")]

namespace GINDockWallpaper {

    // ==========================================
    // WIN32 NATIVE INTEROP
    // ==========================================
    public static class NativeMethods {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

        public const int SPI_SETDESKWALLPAPER = 0x0014;
        public const int SPIF_UPDATEINIFILE = 0x01;
        public const int SPIF_SENDCHANGE = 0x02;

        [DllImport("user32.dll")]
        public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, int dwMinimumWorkingSetSize, int dwMaximumWorkingSetSize);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetCurrentProcess();

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        public struct SHFILEINFO {
            public IntPtr hIcon;
            public int iIcon;
            public uint dwAttributes;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szDisplayName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
            public string szTypeName;
        }

        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbFileInfo, uint uFlags);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool DestroyIcon(IntPtr hIcon);

        public const uint SHGFI_ICON = 0x000000100;
        public const uint SHGFI_SMALLICON = 0x000000001;
        public const uint SHGFI_LARGEICON = 0x000000000;

        public static void TrimMemory() {
            try {
                GC.Collect();
                GC.WaitForPendingFinalizers();
                SetProcessWorkingSetSize(GetCurrentProcess(), -1, -1);
            } catch { }
        }
    }

    // ==========================================
    // THEMES & STYLING (12 DISTINCT RICH THEMES)
    // ==========================================
    public class ColorTheme {
        public string Id;
        public string Name;
        public bool IsDark;
        public Color Background;
        public Color CardBackground;
        public Color Border;
        public Color Accent;
        public Color AccentHover;
        public Color TextPrimary;
        public Color TextSecondary;
        public Color Separator;
        public Color BrandBadge;
        public Color BrandText;
    }

    public static class ThemeManager {
        public static readonly Dictionary<string, ColorTheme> Themes = new Dictionary<string, ColorTheme>(StringComparer.OrdinalIgnoreCase);

        static ThemeManager() {
            // 1. Warm Sand (Default Signature Theme)
            Register(new ColorTheme {
                Id = "WarmSand",
                Name = "Warm Sand (Default)",
                IsDark = true,
                Background = Color.FromArgb(32, 27, 22),
                CardBackground = Color.FromArgb(45, 38, 30),
                Border = Color.FromArgb(140, 95, 45),
                Accent = Color.FromArgb(224, 169, 109),
                AccentHover = Color.FromArgb(245, 195, 135),
                TextPrimary = Color.FromArgb(255, 248, 238),
                TextSecondary = Color.FromArgb(205, 185, 160),
                Separator = Color.FromArgb(85, 65, 48),
                BrandBadge = Color.FromArgb(70, 52, 35),
                BrandText = Color.FromArgb(235, 180, 115)
            });

            // 2. Midnight OLED
            Register(new ColorTheme {
                Id = "MidnightOLED",
                Name = "Midnight OLED",
                IsDark = true,
                Background = Color.FromArgb(0, 0, 0),
                CardBackground = Color.FromArgb(15, 20, 28),
                Border = Color.FromArgb(30, 41, 59),
                Accent = Color.FromArgb(56, 189, 248),
                AccentHover = Color.FromArgb(14, 165, 233),
                TextPrimary = Color.FromArgb(248, 250, 252),
                TextSecondary = Color.FromArgb(148, 163, 184),
                Separator = Color.FromArgb(30, 41, 59),
                BrandBadge = Color.FromArgb(20, 30, 45),
                BrandText = Color.FromArgb(56, 189, 248)
            });

            // 3. Cyberpunk Amber
            Register(new ColorTheme {
                Id = "CyberpunkAmber",
                Name = "Cyberpunk Amber",
                IsDark = true,
                Background = Color.FromArgb(18, 14, 10),
                CardBackground = Color.FromArgb(32, 22, 14),
                Border = Color.FromArgb(180, 83, 9),
                Accent = Color.FromArgb(245, 158, 11),
                AccentHover = Color.FromArgb(251, 191, 36),
                TextPrimary = Color.FromArgb(254, 243, 199),
                TextSecondary = Color.FromArgb(217, 119, 6),
                Separator = Color.FromArgb(90, 45, 10),
                BrandBadge = Color.FromArgb(50, 28, 10),
                BrandText = Color.FromArgb(245, 158, 11)
            });

            // 4. Nordic Frost
            Register(new ColorTheme {
                Id = "NordicFrost",
                Name = "Nordic Frost",
                IsDark = true,
                Background = Color.FromArgb(28, 33, 44),
                CardBackground = Color.FromArgb(40, 48, 64),
                Border = Color.FromArgb(76, 86, 106),
                Accent = Color.FromArgb(136, 192, 208),
                AccentHover = Color.FromArgb(129, 161, 193),
                TextPrimary = Color.FromArgb(236, 239, 244),
                TextSecondary = Color.FromArgb(160, 175, 195),
                Separator = Color.FromArgb(67, 76, 94),
                BrandBadge = Color.FromArgb(46, 55, 74),
                BrandText = Color.FromArgb(136, 192, 208)
            });

            // 5. Emerald Forest
            Register(new ColorTheme {
                Id = "EmeraldForest",
                Name = "Emerald Forest",
                IsDark = true,
                Background = Color.FromArgb(8, 28, 20),
                CardBackground = Color.FromArgb(14, 45, 32),
                Border = Color.FromArgb(16, 95, 65),
                Accent = Color.FromArgb(16, 185, 129),
                AccentHover = Color.FromArgb(52, 211, 153),
                TextPrimary = Color.FromArgb(236, 253, 245),
                TextSecondary = Color.FromArgb(110, 190, 155),
                Separator = Color.FromArgb(25, 70, 50),
                BrandBadge = Color.FromArgb(18, 55, 40),
                BrandText = Color.FromArgb(16, 185, 129)
            });

            // 6. Deep Space Navy
            Register(new ColorTheme {
                Id = "DeepSpaceNavy",
                Name = "Deep Space Navy",
                IsDark = true,
                Background = Color.FromArgb(11, 14, 27),
                CardBackground = Color.FromArgb(22, 27, 46),
                Border = Color.FromArgb(55, 65, 105),
                Accent = Color.FromArgb(129, 140, 248),
                AccentHover = Color.FromArgb(165, 180, 252),
                TextPrimary = Color.FromArgb(241, 245, 249),
                TextSecondary = Color.FromArgb(148, 163, 184),
                Separator = Color.FromArgb(40, 48, 75),
                BrandBadge = Color.FromArgb(30, 36, 62),
                BrandText = Color.FromArgb(129, 140, 248)
            });

            // 7. Solarized Desert
            Register(new ColorTheme {
                Id = "SolarizedDesert",
                Name = "Solarized Desert",
                IsDark = true,
                Background = Color.FromArgb(30, 26, 22),
                CardBackground = Color.FromArgb(48, 40, 32),
                Border = Color.FromArgb(181, 137, 0),
                Accent = Color.FromArgb(203, 75, 22),
                AccentHover = Color.FromArgb(220, 100, 40),
                TextPrimary = Color.FromArgb(253, 246, 227),
                TextSecondary = Color.FromArgb(180, 165, 145),
                Separator = Color.FromArgb(85, 70, 55),
                BrandBadge = Color.FromArgb(60, 48, 36),
                BrandText = Color.FromArgb(181, 137, 0)
            });

            // 8. Tokyo Neon
            Register(new ColorTheme {
                Id = "TokyoNeon",
                Name = "Tokyo Neon",
                IsDark = true,
                Background = Color.FromArgb(22, 16, 38),
                CardBackground = Color.FromArgb(38, 26, 64),
                Border = Color.FromArgb(120, 40, 140),
                Accent = Color.FromArgb(244, 63, 94),
                AccentHover = Color.FromArgb(251, 113, 133),
                TextPrimary = Color.FromArgb(253, 244, 255),
                TextSecondary = Color.FromArgb(192, 132, 252),
                Separator = Color.FromArgb(70, 45, 100),
                BrandBadge = Color.FromArgb(55, 32, 85),
                BrandText = Color.FromArgb(244, 63, 94)
            });

            // 9. Pure Glass / Slate
            Register(new ColorTheme {
                Id = "PureGlass",
                Name = "Pure Glass Slate",
                IsDark = true,
                Background = Color.FromArgb(24, 27, 34),
                CardBackground = Color.FromArgb(36, 42, 54),
                Border = Color.FromArgb(65, 75, 95),
                Accent = Color.FromArgb(226, 232, 240),
                AccentHover = Color.FromArgb(255, 255, 255),
                TextPrimary = Color.FromArgb(248, 250, 252),
                TextSecondary = Color.FromArgb(156, 163, 175),
                Separator = Color.FromArgb(50, 60, 78),
                BrandBadge = Color.FromArgb(42, 50, 68),
                BrandText = Color.FromArgb(226, 232, 240)
            });

            // 10. Rose Gold Luxury
            Register(new ColorTheme {
                Id = "RoseGold",
                Name = "Rose Gold Luxury",
                IsDark = true,
                Background = Color.FromArgb(33, 24, 28),
                CardBackground = Color.FromArgb(50, 34, 42),
                Border = Color.FromArgb(150, 70, 95),
                Accent = Color.FromArgb(244, 114, 182),
                AccentHover = Color.FromArgb(249, 168, 212),
                TextPrimary = Color.FromArgb(255, 241, 242),
                TextSecondary = Color.FromArgb(215, 160, 180),
                Separator = Color.FromArgb(85, 50, 65),
                BrandBadge = Color.FromArgb(65, 40, 52),
                BrandText = Color.FromArgb(244, 114, 182)
            });

            // 11. Titanium Monochrome
            Register(new ColorTheme {
                Id = "Titanium",
                Name = "Titanium Monochrome",
                IsDark = true,
                Background = Color.FromArgb(26, 26, 26),
                CardBackground = Color.FromArgb(42, 42, 42),
                Border = Color.FromArgb(75, 75, 75),
                Accent = Color.FromArgb(220, 220, 220),
                AccentHover = Color.FromArgb(255, 255, 255),
                TextPrimary = Color.FromArgb(245, 245, 245),
                TextSecondary = Color.FromArgb(160, 160, 160),
                Separator = Color.FromArgb(60, 60, 60),
                BrandBadge = Color.FromArgb(50, 50, 50),
                BrandText = Color.FromArgb(220, 220, 220)
            });

            // 12. Daylight Light Mode
            Register(new ColorTheme {
                Id = "DaylightLight",
                Name = "Daylight Light Mode",
                IsDark = false,
                Background = Color.FromArgb(245, 247, 250),
                CardBackground = Color.FromArgb(255, 255, 255),
                Border = Color.FromArgb(203, 213, 225),
                Accent = Color.FromArgb(180, 100, 35),
                AccentHover = Color.FromArgb(200, 120, 50),
                TextPrimary = Color.FromArgb(15, 23, 42),
                TextSecondary = Color.FromArgb(71, 85, 105),
                Separator = Color.FromArgb(226, 232, 240),
                BrandBadge = Color.FromArgb(235, 230, 220),
                BrandText = Color.FromArgb(160, 90, 25)
            });
        }

        private static void Register(ColorTheme theme) {
            Themes[theme.Id] = theme;
        }

        public static ColorTheme GetTheme(string id, string dayNightMode) {
            if (dayNightMode == "Day") {
                return Themes["DaylightLight"];
            }
            if (string.IsNullOrEmpty(id) || !Themes.ContainsKey(id)) {
                return Themes["WarmSand"];
            }
            return Themes[id];
        }
    }

    // ==========================================
    // MULTILINGUAL LOCALIZATION (12 LANGUAGES)
    // ==========================================
    public static class I18n {
        private static string _currentLang = "en";
        private static readonly Dictionary<string, Dictionary<string, string>> Dictionaries = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

        static I18n() {
            // English (Default)
            var en = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Show Dock" },
                { "NextWallpaper", "Next Wallpaper Now" },
                { "OpenFolder", "Open Dock Folder" },
                { "Reload", "Reload Icons & Cache" },
                { "Settings", "Settings..." },
                { "CheckUpdates", "Check for Updates..." },
                { "Exit", "Exit" },
                { "TabGeneral", "General" },
                { "TabAppearance", "Appearance & Themes" },
                { "TabDock", "Dock & Items" },
                { "TabWallpaper", "Wallpaper & Calendar" },
                { "TabAbout", "About" },
                { "EnableDock", "Enable Hot-Corner Dock Bar" },
                { "EnableWallpaper", "Enable Dynamic 4K Wallpaper & Calendar" },
                { "DockPlacement", "Dock Bar Placement:" },
                { "PlacementTop", "Top (Slide Down)" },
                { "PlacementLeft", "Left (Slide Right)" },
                { "Language", "Language / Язык / Jazyk:" },
                { "AutoStart", "Run at Windows Startup" },
                { "AutoUpdate", "Check for updates automatically" },
                { "DayNightMode", "Day / Night Mode:" },
                { "ModeAuto", "Auto (Follow System)" },
                { "ModeDay", "Day (Light)" },
                { "ModeNight", "Night (Dark)" },
                { "ColorTheme", "Color Style & Theme:" },
                { "FolderFontSize", "Folder Font Size (pt):" },
                { "ItemFontSize", "Open Items & Apps Font Size (pt):" },
                { "ShowLabels", "Show Item Labels:" },
                { "LabelsFoldersOnly", "Folders Only" },
                { "LabelsAll", "All Items" },
                { "LabelsNone", "Icons Only (No Text)" },
                { "RootFolder", "Dock Root Folder:" },
                { "Browse", "Browse..." },
                { "OpenExplorer", "Open in Explorer" },
                { "SortingMode", "Item Sorting Mode:" },
                { "SortAlphaAZ", "Alphabetical (A to Z) [Default]" },
                { "SortAlphaZA", "Alphabetical (Z to A)" },
                { "SortFoldersFirst", "Folders First, Then Alphabetical" },
                { "SortFileType", "By File Type / Extension" },
                { "SortDateModified", "By Date Modified" },
                { "AutoHideDelay", "Auto-Hide Delay (ms):" },
                { "HotCornerSize", "Hot-Corner Trigger Area (px):" },
                { "WallpaperCategory", "Wallpaper Category:" },
                { "WallpaperInterval", "Auto-Change Interval:" },
                { "ShowCalendar", "Overlay Anti-Aliased Live Calendar HUD" },
                { "SaveCurrentWallpaper", "Save Active Wallpaper to Pictures" },
                { "Save", "Save & Apply" },
                { "Cancel", "Cancel" },
                { "UpToDate", "You are running the latest version: " },
                { "UpdateAvailable", "New version available: " },
                { "DownloadNow", "Download update now?" }
            };
            Dictionaries["en"] = en;

            // Russian (Русский)
            var ru = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Показать докер" },
                { "NextWallpaper", "Следующие обои сейчас" },
                { "OpenFolder", "Открыть папку докера" },
                { "Reload", "Перезагрузить значки и кэш" },
                { "Settings", "Настройки..." },
                { "CheckUpdates", "Проверить обновления..." },
                { "Exit", "Выход" },
                { "TabGeneral", "Основные" },
                { "TabAppearance", "Внешний вид и темы" },
                { "TabDock", "Докер и значки" },
                { "TabWallpaper", "Обои и календарь" },
                { "TabAbout", "О программе" },
                { "EnableDock", "Включить выезжающую панель Dock" },
                { "EnableWallpaper", "Включить динамические 4K обои и календарь" },
                { "DockPlacement", "Расположение панели Dock:" },
                { "PlacementTop", "Сверху (выезжает вниз)" },
                { "PlacementLeft", "Слева (выезжает вправо)" },
                { "Language", "Выбор языка:" },
                { "AutoStart", "Запускать вместе с Windows" },
                { "AutoUpdate", "Автоматически проверять обновления" },
                { "DayNightMode", "Режим День / Ночь:" },
                { "ModeAuto", "Авто (по системе)" },
                { "ModeDay", "День (светлая тема)" },
                { "ModeNight", "Ночь (темная тема)" },
                { "ColorTheme", "Стиль оформления и тема:" },
                { "FolderFontSize", "Размер шрифта для папок (pt):" },
                { "ItemFontSize", "Размер шрифта открываемых иконок (pt):" },
                { "ShowLabels", "Подписи значков:" },
                { "LabelsFoldersOnly", "Только у папок" },
                { "LabelsAll", "У всех значков" },
                { "LabelsNone", "Без текста (только иконки)" },
                { "RootFolder", "Корневая папка докера:" },
                { "Browse", "Обзор..." },
                { "OpenExplorer", "Открыть в Проводнике" },
                { "SortingMode", "Сортировка значков:" },
                { "SortAlphaAZ", "По алфавиту (А-Я / A-Z) [По умолчанию]" },
                { "SortAlphaZA", "По алфавиту обратная (Я-А / Z-A)" },
                { "SortFoldersFirst", "Сначала папки, затем по алфавиту" },
                { "SortFileType", "По типу и расширению файлов" },
                { "SortDateModified", "По дате изменения" },
                { "AutoHideDelay", "Задержка скрытия (мс):" },
                { "HotCornerSize", "Зона горячего угла (пиксели):" },
                { "WallpaperCategory", "Категория 4K обоев:" },
                { "WallpaperInterval", "Интервал смены обоев:" },
                { "ShowCalendar", "Отображать живой календарь на обоях" },
                { "SaveCurrentWallpaper", "Сохранить текущие обои в Изображения" },
                { "Save", "Сохранить и применить" },
                { "Cancel", "Отмена" },
                { "UpToDate", "У вас установлена последняя версия: " },
                { "UpdateAvailable", "Доступна новая версия: " },
                { "DownloadNow", "Скачать обновление сейчас?" }
            };
            Dictionaries["ru"] = ru;

            // Czech (Čeština)
            var cs = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Zobrazit Dock" },
                { "NextWallpaper", "Další tapeta nyní" },
                { "OpenFolder", "Otevřít složku Docku" },
                { "Reload", "Znovu načíst ikony a mezipaměť" },
                { "Settings", "Nastavení..." },
                { "CheckUpdates", "Zkontrolovat aktualizace..." },
                { "Exit", "Ukončit" },
                { "TabGeneral", "Obecné" },
                { "TabAppearance", "Vzhled a motivy" },
                { "TabDock", "Dock a položky" },
                { "TabWallpaper", "Tapeta a kalendář" },
                { "TabAbout", "O aplikaci" },
                { "EnableDock", "Povolit panel Dock v rohu obrazovky" },
                { "EnableWallpaper", "Povolit dynamické 4K tapety a kalendář" },
                { "DockPlacement", "Umístění panelu Dock:" },
                { "PlacementTop", "Nahoře (vysunutí dolů)" },
                { "PlacementLeft", "Vlevo (vysunutí doprava)" },
                { "Language", "Jazyk aplikace:" },
                { "AutoStart", "Spustit při startu Windows" },
                { "AutoUpdate", "Automaticky kontrolovat aktualizace" },
                { "DayNightMode", "Režim Den / Noc:" },
                { "ModeAuto", "Automaticky (podle systému)" },
                { "ModeDay", "Den (světlý motiv)" },
                { "ModeNight", "Noc (tmavý motiv)" },
                { "ColorTheme", "Barevný styl a motiv:" },
                { "FolderFontSize", "Velikost písma pro složky (pt):" },
                { "ItemFontSize", "Velikost písma pro ikony a aplikace (pt):" },
                { "ShowLabels", "Zobrazení popisků:" },
                { "LabelsFoldersOnly", "Pouze pro složky" },
                { "LabelsAll", "Pro všechny položky" },
                { "LabelsNone", "Pouze ikony bez textu" },
                { "RootFolder", "Kořenová složka Docku:" },
                { "Browse", "Procházet..." },
                { "OpenExplorer", "Otevřít v Průzkumníku" },
                { "SortingMode", "Řazení položek:" },
                { "SortAlphaAZ", "Abecedně (A až Z) [Výchozí]" },
                { "SortAlphaZA", "Abecedně pozpátku (Z až A)" },
                { "SortFoldersFirst", "Nejprve složky, poté abecedně" },
                { "SortFileType", "Podle typu souboru" },
                { "SortDateModified", "Podle data změny" },
                { "AutoHideDelay", "Zpoždění skrytí (ms):" },
                { "HotCornerSize", "Aktivní zóna rohu (px):" },
                { "WallpaperCategory", "Kategorie 4K tapet:" },
                { "WallpaperInterval", "Interval výměny tapety:" },
                { "ShowCalendar", "Vykreslit živý kalendář na ploše" },
                { "SaveCurrentWallpaper", "Uložit aktuální tapetu do Obrázků" },
                { "Save", "Uložit a použít" },
                { "Cancel", "Zrušit" },
                { "UpToDate", "Máte nejnovější verzi: " },
                { "UpdateAvailable", "K dispozici je nová verze: " },
                { "DownloadNow", "Stáhnout aktualizaci nyní?" }
            };
            Dictionaries["cs"] = cs;

            // German (Deutsch)
            var de = new Dictionary<string, string>(en);
            de["TabGeneral"] = "Allgemein";
            de["TabAppearance"] = "Erscheinungsbild";
            de["TabDock"] = "Dock & Icons";
            de["TabWallpaper"] = "Hintergrund & Kalender";
            de["Settings"] = "Einstellungen...";
            de["Exit"] = "Beenden";
            de["PlacementTop"] = "Oben (nach unten gleiten)";
            de["PlacementLeft"] = "Links (nach rechts gleiten)";
            de["SortAlphaAZ"] = "Alphabetisch (A bis Z) [Standard]";
            Dictionaries["de"] = de;

            // French (Français)
            var fr = new Dictionary<string, string>(en);
            fr["TabGeneral"] = "Général";
            fr["TabAppearance"] = "Apparence & Thèmes";
            fr["Settings"] = "Paramètres...";
            fr["Exit"] = "Quitter";
            fr["PlacementTop"] = "Haut (glisser vers le bas)";
            fr["PlacementLeft"] = "Gauche (glisser vers la droite)";
            Dictionaries["fr"] = fr;

            // Spanish (Español)
            var es = new Dictionary<string, string>(en);
            es["TabGeneral"] = "General";
            es["TabAppearance"] = "Apariencia y Temas";
            es["Settings"] = "Configuración...";
            es["Exit"] = "Salir";
            es["PlacementTop"] = "Arriba";
            es["PlacementLeft"] = "Izquierda";
            Dictionaries["es"] = es;

            // Italian (Italiano)
            var it = new Dictionary<string, string>(en);
            it["TabGeneral"] = "Generale";
            it["Settings"] = "Impostazioni...";
            it["Exit"] = "Esci";
            Dictionaries["it"] = it;

            // Portuguese (Português)
            var pt = new Dictionary<string, string>(en);
            pt["TabGeneral"] = "Geral";
            pt["Settings"] = "Configurações...";
            pt["Exit"] = "Sair";
            Dictionaries["pt"] = pt;

            // Polish (Polski)
            var pl = new Dictionary<string, string>(en);
            pl["TabGeneral"] = "Ogólne";
            pl["TabAppearance"] = "Wygląd i motywy";
            pl["Settings"] = "Ustawienia...";
            pl["Exit"] = "Wyjdź";
            pl["PlacementTop"] = "Góra";
            pl["PlacementLeft"] = "Lewo";
            Dictionaries["pl"] = pl;

            // Ukrainian (Українська)
            var uk = new Dictionary<string, string>(ru);
            uk["AppTitle"] = "GIN Dock Wallpaper";
            uk["ShowDock"] = "Показати докер";
            uk["Settings"] = "Налаштування...";
            uk["Exit"] = "Вихід";
            uk["TabGeneral"] = "Загальні";
            uk["TabAppearance"] = "Зовнішній вигляд";
            Dictionaries["uk"] = uk;

            // Chinese (简体中文)
            var zh = new Dictionary<string, string>(en);
            zh["AppTitle"] = "GIN Dock Wallpaper";
            zh["ShowDock"] = "显示快捷坞";
            zh["NextWallpaper"] = "立即切换壁纸";
            zh["Settings"] = "设置...";
            zh["Exit"] = "退出";
            zh["TabGeneral"] = "常规";
            zh["TabAppearance"] = "外观与主题";
            Dictionaries["zh"] = zh;

            // Japanese (日本語)
            var ja = new Dictionary<string, string>(en);
            ja["AppTitle"] = "GIN Dock Wallpaper";
            ja["ShowDock"] = "ドックを表示";
            ja["NextWallpaper"] = "壁紙を今すぐ変更";
            ja["Settings"] = "設定...";
            ja["Exit"] = "終了";
            ja["TabGeneral"] = "一般";
            ja["TabAppearance"] = "外観とテーマ";
            Dictionaries["ja"] = ja;
        }

        public static void SetLanguage(string lang) {
            if (Dictionaries.ContainsKey(lang)) {
                _currentLang = lang;
            } else {
                _currentLang = "en";
            }
        }

        public static string T(string key) {
            Dictionary<string, string> dict;
            if (Dictionaries.TryGetValue(_currentLang, out dict)) {
                string val;
                if (dict.TryGetValue(key, out val)) return val;
            }
            if (Dictionaries["en"].TryGetValue(key, out var enVal)) return enVal;
            return key;
        }
    }

    // ==========================================
    // CONFIGURATION MODEL (ROBUST JSON)
    // ==========================================
    public class Config {
        public string RootFolder = @"D:\MEGA\UTIL\┇";
        public bool EnableDock = true;
        public bool EnableWallpaper = true;
        public string DockPosition = "Top"; // "Top" or "Left"
        public float FolderFontSize = 9.0f;
        public float ItemFontSize = 9.0f;
        public string SortingMode = "AlphaAZ"; // AlphaAZ, AlphaZA, FoldersFirst, FileType, DateModified
        public string ThemeName = "WarmSand";
        public string DayNightMode = "Auto"; // Auto, Day, Night
        public string Language = "en";
        public int WallpaperIntervalMinutes = 60;
        public string WallpaperCategory = "nature"; // random, nature, cyberpunk, space, cars, 3d, city, minimalism
        public bool ShowCalendar = true;
        public int HotCornerWidth = 15;
        public int HotCornerHeight = 15;
        public int AutoHideDelayMs = 450;
        public int BarHeight = 48;
        public string ShowLabels = "FoldersOnly"; // "None", "FoldersOnly", "All"
        public bool StartWithWindows = false;
        public bool CheckUpdatesOnStartup = true;

        public static string AppDataDir {
            get {
                string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "GIN-Dock-Wallpaper");
                try { if (!Directory.Exists(dir)) Directory.CreateDirectory(dir); } catch { }
                return dir;
            }
        }

        public static string CacheDir {
            get {
                string dir = Path.Combine(AppDataDir, "cache");
                try { if (!Directory.Exists(dir)) Directory.CreateDirectory(dir); } catch { }
                return dir;
            }
        }

        private static string ConfigPath {
            get { return Path.Combine(AppDataDir, "config.json"); }
        }

        public static Config Load() {
            Config cfg = new Config();
            if (!Directory.Exists(cfg.RootFolder)) {
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                if (Directory.Exists(desktop)) cfg.RootFolder = desktop;
            }

            try {
                if (File.Exists(ConfigPath)) {
                    string json = File.ReadAllText(ConfigPath, Encoding.UTF8);
                    cfg.RootFolder = GetString(json, "RootFolder", cfg.RootFolder);
                    cfg.EnableDock = GetBool(json, "EnableDock", cfg.EnableDock);
                    cfg.EnableWallpaper = GetBool(json, "EnableWallpaper", cfg.EnableWallpaper);
                    cfg.DockPosition = GetString(json, "DockPosition", cfg.DockPosition);
                    cfg.FolderFontSize = GetFloat(json, "FolderFontSize", cfg.FolderFontSize);
                    cfg.ItemFontSize = GetFloat(json, "ItemFontSize", cfg.ItemFontSize);
                    cfg.SortingMode = GetString(json, "SortingMode", cfg.SortingMode);
                    cfg.ThemeName = GetString(json, "ThemeName", cfg.ThemeName);
                    cfg.DayNightMode = GetString(json, "DayNightMode", cfg.DayNightMode);
                    cfg.Language = GetString(json, "Language", cfg.Language);
                    cfg.WallpaperIntervalMinutes = GetInt(json, "WallpaperIntervalMinutes", cfg.WallpaperIntervalMinutes);
                    cfg.WallpaperCategory = GetString(json, "WallpaperCategory", cfg.WallpaperCategory);
                    cfg.ShowCalendar = GetBool(json, "ShowCalendar", cfg.ShowCalendar);
                    cfg.HotCornerWidth = GetInt(json, "HotCornerWidth", cfg.HotCornerWidth);
                    cfg.HotCornerHeight = GetInt(json, "HotCornerHeight", cfg.HotCornerHeight);
                    cfg.AutoHideDelayMs = GetInt(json, "AutoHideDelayMs", cfg.AutoHideDelayMs);
                    cfg.BarHeight = GetInt(json, "BarHeight", cfg.BarHeight);
                    cfg.ShowLabels = GetString(json, "ShowLabels", cfg.ShowLabels);
                    cfg.StartWithWindows = GetBool(json, "StartWithWindows", cfg.StartWithWindows);
                    cfg.CheckUpdatesOnStartup = GetBool(json, "CheckUpdatesOnStartup", cfg.CheckUpdatesOnStartup);
                }
            } catch { }

            I18n.SetLanguage(cfg.Language);
            return cfg;
        }

        public void Save() {
            try {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("{");
                sb.AppendLine("  \"RootFolder\": \"" + Escape(RootFolder) + "\",");
                sb.AppendLine("  \"EnableDock\": " + (EnableDock ? "true" : "false") + ",");
                sb.AppendLine("  \"EnableWallpaper\": " + (EnableWallpaper ? "true" : "false") + ",");
                sb.AppendLine("  \"DockPosition\": \"" + Escape(DockPosition) + "\",");
                sb.AppendLine("  \"FolderFontSize\": " + FolderFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"ItemFontSize\": " + ItemFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"SortingMode\": \"" + Escape(SortingMode) + "\",");
                sb.AppendLine("  \"ThemeName\": \"" + Escape(ThemeName) + "\",");
                sb.AppendLine("  \"DayNightMode\": \"" + Escape(DayNightMode) + "\",");
                sb.AppendLine("  \"Language\": \"" + Escape(Language) + "\",");
                sb.AppendLine("  \"WallpaperIntervalMinutes\": " + WallpaperIntervalMinutes + ",");
                sb.AppendLine("  \"WallpaperCategory\": \"" + Escape(WallpaperCategory) + "\",");
                sb.AppendLine("  \"ShowCalendar\": " + (ShowCalendar ? "true" : "false") + ",");
                sb.AppendLine("  \"HotCornerWidth\": " + HotCornerWidth + ",");
                sb.AppendLine("  \"HotCornerHeight\": " + HotCornerHeight + ",");
                sb.AppendLine("  \"AutoHideDelayMs\": " + AutoHideDelayMs + ",");
                sb.AppendLine("  \"BarHeight\": " + BarHeight + ",");
                sb.AppendLine("  \"ShowLabels\": \"" + Escape(ShowLabels) + "\",");
                sb.AppendLine("  \"StartWithWindows\": " + (StartWithWindows ? "true" : "false") + ",");
                sb.AppendLine("  \"CheckUpdatesOnStartup\": " + (CheckUpdatesOnStartup ? "true" : "false"));
                sb.AppendLine("}");
                File.WriteAllText(ConfigPath, sb.ToString(), Encoding.UTF8);
            } catch { }
        }

        private static string Escape(string s) {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        private static string GetString(string json, string key, string def) {
            string token = "\"" + key + "\":";
            int idx = json.IndexOf(token);
            if (idx == -1) return def;
            idx += token.Length;
            int q1 = json.IndexOf("\"", idx);
            if (q1 == -1) return def;
            int q2 = json.IndexOf("\"", q1 + 1);
            if (q2 == -1) return def;
            return json.Substring(q1 + 1, q2 - q1 - 1).Replace("\\\\", "\\");
        }

        private static int GetInt(string json, string key, int def) {
            string token = "\"" + key + "\":";
            int idx = json.IndexOf(token);
            if (idx == -1) return def;
            idx += token.Length;
            int end = json.IndexOfAny(new char[] { ',', '}', '\r', '\n' }, idx);
            if (end == -1) end = json.Length;
            string val = json.Substring(idx, end - idx).Trim();
            int res;
            if (int.TryParse(val, out res)) return res;
            return def;
        }

        private static float GetFloat(string json, string key, float def) {
            string token = "\"" + key + "\":";
            int idx = json.IndexOf(token);
            if (idx == -1) return def;
            idx += token.Length;
            int end = json.IndexOfAny(new char[] { ',', '}', '\r', '\n' }, idx);
            if (end == -1) end = json.Length;
            string val = json.Substring(idx, end - idx).Trim();
            float res;
            if (float.TryParse(val, NumberStyles.Any, CultureInfo.InvariantCulture, out res)) return res;
            return def;
        }

        private static bool GetBool(string json, string key, bool def) {
            string token = "\"" + key + "\":";
            int idx = json.IndexOf(token);
            if (idx == -1) return def;
            idx += token.Length;
            int end = json.IndexOfAny(new char[] { ',', '}', '\r', '\n' }, idx);
            if (end == -1) end = json.Length;
            string val = json.Substring(idx, end - idx).Trim().ToLowerInvariant();
            if (val == "true") return true;
            if (val == "false") return false;
            return def;
        }
    }

    // ==========================================
    // SHELL & ICON UTILITIES
    // ==========================================
    public static class ShellHelper {
        private static readonly Dictionary<string, Image> _iconCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);

        public static Image GetIconImage(string path, bool large) {
            string key = path + "_" + (large ? "L" : "S");
            lock (_iconCache) {
                if (_iconCache.ContainsKey(key)) return _iconCache[key];
            }

            Image img = null;
            try {
                NativeMethods.SHFILEINFO shinfo = new NativeMethods.SHFILEINFO();
                uint flags = NativeMethods.SHGFI_ICON | (large ? NativeMethods.SHGFI_LARGEICON : NativeMethods.SHGFI_SMALLICON);
                IntPtr res = NativeMethods.SHGetFileInfo(path, 0, ref shinfo, (uint)Marshal.SizeOf(shinfo), flags);
                if (shinfo.hIcon != IntPtr.Zero) {
                    using (Icon ico = (Icon)Icon.FromHandle(shinfo.hIcon).Clone()) {
                        img = ico.ToBitmap();
                    }
                    NativeMethods.DestroyIcon(shinfo.hIcon);
                }
            } catch { }

            if (img == null) {
                Bitmap bmp = new Bitmap(large ? 32 : 16, large ? 32 : 16);
                using (Graphics g = Graphics.FromImage(bmp)) {
                    g.Clear(Color.FromArgb(140, 95, 45));
                }
                img = bmp;
            }

            lock (_iconCache) {
                _iconCache[key] = img;
            }
            return img;
        }

        public static string ResolveLnkTarget(string lnkPath) {
            try {
                string dir = Path.GetDirectoryName(lnkPath);
                string file = Path.GetFileName(lnkPath);
                Type shellType = Type.GetTypeFromProgID("Shell.Application");
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic folder = shell.Namespace(dir);
                dynamic folderItem = folder.ParseName(file);
                dynamic link = folderItem.GetLink;
                string target = (string)link.Target.Path;
                return target;
            } catch {
                return null;
            }
        }

        public static void Launch(string path) {
            try {
                ProcessStartInfo psi = new ProcessStartInfo {
                    FileName = path,
                    UseShellExecute = true
                };
                Process.Start(psi);
            } catch (Exception ex) {
                MessageBox.Show("Failed to launch:\n" + path + "\n\nError: " + ex.Message,
                    "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        public static void OpenInExplorer(string path) {
            try {
                if (Directory.Exists(path)) {
                    Process.Start("explorer.exe", "\"" + path + "\"");
                } else if (File.Exists(path)) {
                    Process.Start("explorer.exe", "/select,\"" + path + "\"");
                }
            } catch { }
        }
    }

    // ==========================================
    // DOCK ITEM MODEL
    // ==========================================
    public class DockItem {
        public string Name;
        public string FullPath;
        public bool IsFolder;
        public string TargetFolder;
        public string Extension;
        public DateTime LastModified;
        public Image IconLarge;
        public Image IconSmall;

        public static DockItem FromPath(string path) {
            DockItem item = new DockItem();
            item.FullPath = path;
            item.Name = Path.GetFileNameWithoutExtension(path);
            item.Extension = Path.GetExtension(path);

            try {
                item.LastModified = File.GetLastWriteTime(path);
            } catch {
                item.LastModified = DateTime.MinValue;
            }

            if (Directory.Exists(path)) {
                item.IsFolder = true;
                item.TargetFolder = path;
                item.Name = Path.GetFileName(path);
            } else if (path.EndsWith(".lnk", StringComparison.OrdinalIgnoreCase)) {
                string target = ShellHelper.ResolveLnkTarget(path);
                if (!string.IsNullOrEmpty(target) && Directory.Exists(target)) {
                    item.IsFolder = true;
                    item.TargetFolder = target;
                }
            }

            item.IconLarge = ShellHelper.GetIconImage(path, true);
            item.IconSmall = ShellHelper.GetIconImage(path, false);
            return item;
        }
    }

    // ==========================================
    // WALLPAPER & CALENDAR ENGINE
    // ==========================================
    public class WallpaperEngine {
        private Config _config;
        private System.Windows.Forms.Timer _timer;
        private bool _isDownloading = false;
        private string _lastDownloadedPath = null;

        public event Action<string> WallpaperChanged;

        public WallpaperEngine(Config config) {
            _config = config;
            _timer = new System.Windows.Forms.Timer();
            UpdateInterval();
            _timer.Tick += (s, e) => {
                if (_config.EnableWallpaper) {
                    TriggerNextWallpaperAsync();
                }
            };
            if (_config.EnableWallpaper) {
                _timer.Start();
            }
        }

        public void UpdateInterval() {
            int mins = Math.Max(5, _config.WallpaperIntervalMinutes);
            _timer.Interval = mins * 60 * 1000;
        }

        public void SetEnabled(bool enable) {
            _config.EnableWallpaper = enable;
            if (enable) {
                UpdateInterval();
                _timer.Start();
            } else {
                _timer.Stop();
            }
        }

        public void TriggerNextWallpaperAsync() {
            if (_isDownloading) return;
            _isDownloading = true;

            ThreadPool.QueueUserWorkItem(_ => {
                try {
                    string downloadedFile = DownloadWallpaperImage();
                    if (!string.IsNullOrEmpty(downloadedFile) && File.Exists(downloadedFile)) {
                        _lastDownloadedPath = downloadedFile;

                        string finalWallpaper = downloadedFile;
                        if (_config.ShowCalendar) {
                            finalWallpaper = RenderCalendarOnWallpaper(downloadedFile);
                        }

                        // Apply via SystemParametersInfo
                        NativeMethods.SystemParametersInfo(
                            NativeMethods.SPI_SETDESKWALLPAPER,
                            0,
                            finalWallpaper,
                            NativeMethods.SPIF_UPDATEINIFILE | NativeMethods.SPIF_SENDCHANGE
                        );

                        NativeMethods.TrimMemory();

                        if (WallpaperChanged != null) {
                            WallpaperChanged(finalWallpaper);
                        }
                    }
                } catch { }
                finally {
                    _isDownloading = false;
                }
            });
        }

        public void SaveActiveWallpaperToPictures() {
            if (string.IsNullOrEmpty(_lastDownloadedPath) || !File.Exists(_lastDownloadedPath)) {
                MessageBox.Show("No active wallpaper downloaded yet.", "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try {
                string pics = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
                string destDir = Path.Combine(pics, "GIN-Wallpapers");
                if (!Directory.Exists(destDir)) Directory.CreateDirectory(destDir);

                string destFile = Path.Combine(destDir, "GIN_Wallpaper_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + Path.GetExtension(_lastDownloadedPath));
                File.Copy(_lastDownloadedPath, destFile, true);

                Process.Start("explorer.exe", "/select,\"" + destFile + "\"");
            } catch (Exception ex) {
                MessageBox.Show("Error saving picture: " + ex.Message, "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private string DownloadWallpaperImage() {
            // Determine Wallhaven search query
            string query = "nature";
            string cat = _config.WallpaperCategory.ToLowerInvariant();
            if (cat == "cyberpunk") query = "cyberpunk";
            else if (cat == "space") query = "space galaxy";
            else if (cat == "cars") query = "supercar";
            else if (cat == "3d") query = "3d abstract";
            else if (cat == "city") query = "cityscape night";
            else if (cat == "minimalism") query = "minimalism";
            else if (cat == "animals") query = "wildlife";
            else if (cat == "random") {
                string[] rnd = new string[] { "nature", "space", "landscape", "cyberpunk", "ocean", "mountains", "abstract" };
                query = rnd[new Random().Next(rnd.Length)];
            }

            string seed = Guid.NewGuid().ToString("N").Substring(0, 6);
            string apiUrl = "https://wallhaven.cc/api/v1/search?q=" + Uri.EscapeDataString(query) + "&categories=100&purity=100&atleast=1920x1080&sorting=random&seed=" + seed;

            string targetJpg = Path.Combine(Config.CacheDir, "wallpaper_" + DateTime.Now.Ticks + ".jpg");

            using (WebClient wc = new WebClient()) {
                wc.Headers.Add("User-Agent", "GIN-Dock-Wallpaper/v032 (Windows; WinAPI)");
                string json = wc.DownloadString(apiUrl);

                // Extract image URL from Wallhaven JSON: "path":"https://w.wallhaven.cc/full/..."
                int pIdx = json.IndexOf("\"path\":\"");
                if (pIdx != -1) {
                    pIdx += 8;
                    int pEnd = json.IndexOf("\"", pIdx);
                    if (pEnd != -1) {
                        string imgUrl = json.Substring(pIdx, pEnd - pIdx).Replace("\\/", "/");
                        wc.DownloadFile(imgUrl, targetJpg);
                        return targetJpg;
                    }
                }

                // Fallback to Unsplash 4K source if Wallhaven fails
                string unsplashUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=2560&q=80";
                wc.DownloadFile(unsplashUrl, targetJpg);
                return targetJpg;
            }
        }

        private string RenderCalendarOnWallpaper(string originalImagePath) {
            string outputJpg = Path.Combine(Config.CacheDir, "active_desktop_hud.jpg");

            using (Image original = Image.FromFile(originalImagePath))
            using (Bitmap bmp = new Bitmap(original.Width, original.Height))
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                // 1. Draw base wallpaper image
                g.DrawImage(original, 0, 0, original.Width, original.Height);

                // 2. Render Calendar HUD in Top-Right or Bottom-Right corner
                DateTime now = DateTime.Now;
                ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);

                int cardW = Math.Max(260, (int)(original.Width * 0.16f));
                int cardH = Math.Max(220, (int)(cardW * 0.85f));
                int margin = 30;
                int cardX = original.Width - cardW - margin;
                int cardY = margin + 40; // below dock bar

                // Draw translucent card background
                Rectangle cardRect = new Rectangle(cardX, cardY, cardW, cardH);
                using (GraphicsPath path = GetRoundedRect(cardRect, 14))
                using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(170, theme.Background.R, theme.Background.G, theme.Background.B)))
                using (Pen borderPen = new Pen(Color.FromArgb(200, theme.Border.R, theme.Border.G, theme.Border.B), 1.5f)) {
                    g.FillPath(bgBrush, path);
                    g.DrawPath(borderPen, path);
                }

                // Calendar Title: Month & Year
                string monthTitle = now.ToString("MMMM yyyy", CultureInfo.CurrentCulture).ToUpperInvariant();
                float titleFontSize = Math.Max(10f, cardW * 0.052f);
                using (Font titleFont = new Font("Segoe UI", titleFontSize, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(theme.TextPrimary))
                using (SolidBrush accentBrush = new SolidBrush(theme.Accent)) {
                    g.DrawString(monthTitle, titleFont, accentBrush, cardX + 16, cardY + 12);

                    // Day of Week Header
                    string[] days = new string[] { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" };
                    float colW = (cardW - 32) / 7.0f;
                    float headerY = cardY + 16 + titleFontSize * 1.6f;
                    float dayFontSize = Math.Max(8f, cardW * 0.038f);
                    using (Font dayFont = new Font("Segoe UI", dayFontSize, FontStyle.Regular))
                    using (Font boldDayFont = new Font("Segoe UI", dayFontSize, FontStyle.Bold))
                    using (SolidBrush subBrush = new SolidBrush(theme.TextSecondary)) {
                        for (int i = 0; i < 7; i++) {
                            g.DrawString(days[i], dayFont, (i >= 5 ? accentBrush : subBrush), cardX + 16 + i * colW, headerY);
                        }

                        // Days grid
                        DateTime firstDay = new DateTime(now.Year, now.Month, 1);
                        int startCol = ((int)firstDay.DayOfWeek + 6) % 7; // Monday = 0
                        int daysInMonth = DateTime.DaysInMonth(now.Year, now.Month);

                        float rowH = (cardH - (headerY - cardY) - 16) / 6.0f;
                        int curDay = 1;

                        for (int row = 0; row < 6 && curDay <= daysInMonth; row++) {
                            for (int col = 0; col < 7 && curDay <= daysInMonth; col++) {
                                if (row == 0 && col < startCol) continue;

                                float dx = cardX + 16 + col * colW;
                                float dy = headerY + 18 + row * rowH;

                                if (curDay == now.Day) {
                                    // Highlight Current Day with glowing pill
                                    RectangleF todayRect = new RectangleF(dx - 3, dy - 2, colW - 2, rowH - 2);
                                    using (GraphicsPath pill = GetRoundedRect(new Rectangle((int)todayRect.X, (int)todayRect.Y, (int)todayRect.Width, (int)todayRect.Height), 6))
                                    using (SolidBrush pillBrush = new SolidBrush(theme.Accent)) {
                                        g.FillPath(pillBrush, pill);
                                    }
                                    using (SolidBrush activeText = new SolidBrush(Color.Black)) {
                                        g.DrawString(curDay.ToString(), boldDayFont, activeText, dx + 2, dy);
                                    }
                                } else {
                                    g.DrawString(curDay.ToString(), dayFont, (col >= 5 ? accentBrush : textBrush), dx, dy);
                                }
                                curDay++;
                            }
                        }
                    }
                }

                bmp.Save(outputJpg, System.Drawing.Imaging.ImageFormat.Jpeg);
            }

            return outputJpg;
        }

        private static GraphicsPath GetRoundedRect(Rectangle bounds, int radius) {
            GraphicsPath path = new GraphicsPath();
            int diameter = radius * 2;
            path.AddArc(bounds.X, bounds.Y, diameter, diameter, 180, 90);
            path.AddArc(bounds.Right - diameter, bounds.Y, diameter, diameter, 270, 90);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
            path.AddArc(bounds.X, bounds.Bottom - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    // ==========================================
    // MODERN TOOLSTRIP RENDERER
    // ==========================================
    public class DynamicColorTable : ProfessionalColorTable {
        private ColorTheme _theme;
        public DynamicColorTable(ColorTheme theme) { _theme = theme; }

        public override Color ToolStripDropDownBackground { get { return _theme.Background; } }
        public override Color MenuBorder { get { return _theme.Border; } }
        public override Color MenuItemBorder { get { return _theme.Accent; } }
        public override Color MenuItemSelected { get { return _theme.CardBackground; } }
        public override Color MenuItemSelectedGradientBegin { get { return _theme.CardBackground; } }
        public override Color MenuItemSelectedGradientEnd { get { return _theme.CardBackground; } }
        public override Color MenuItemPressedGradientBegin { get { return _theme.CardBackground; } }
        public override Color MenuItemPressedGradientEnd { get { return _theme.CardBackground; } }
        public override Color ImageMarginGradientBegin { get { return _theme.Background; } }
        public override Color ImageMarginGradientMiddle { get { return _theme.Background; } }
        public override Color ImageMarginGradientEnd { get { return _theme.Background; } }
        public override Color SeparatorDark { get { return _theme.Separator; } }
        public override Color SeparatorLight { get { return Color.Transparent; } }
    }

    public class DynamicMenuRenderer : ToolStripProfessionalRenderer {
        private ColorTheme _theme;

        public DynamicMenuRenderer(ColorTheme theme) : base(new DynamicColorTable(theme)) {
            _theme = theme;
            RoundedEdges = true;
        }

        protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
            e.TextColor = _theme.TextPrimary;
            base.OnRenderItemText(e);
        }

        protected override void OnRenderArrow(ToolStripArrowRenderEventArgs e) {
            e.ArrowColor = _theme.Accent;
            base.OnRenderArrow(e);
        }

        protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e) {
            if (e.Item.Selected) {
                Rectangle r = new Rectangle(2, 1, e.Item.Width - 4, e.Item.Height - 2);
                using (GraphicsPath path = GetRoundedRect(r, 4))
                using (SolidBrush b = new SolidBrush(_theme.CardBackground))
                using (Pen p = new Pen(_theme.Accent)) {
                    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                    e.Graphics.FillPath(b, path);
                    e.Graphics.DrawPath(p, path);
                }
            } else {
                base.OnRenderMenuItemBackground(e);
            }
        }

        private static GraphicsPath GetRoundedRect(Rectangle bounds, int radius) {
            GraphicsPath path = new GraphicsPath();
            int diameter = radius * 2;
            path.AddArc(bounds.X, bounds.Y, diameter, diameter, 180, 90);
            path.AddArc(bounds.Right - diameter, bounds.Y, diameter, diameter, 270, 90);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
            path.AddArc(bounds.X, bounds.Bottom - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    // ==========================================
    // DOCK BAR FORM (TOP OR LEFT PLACEMENT)
    // ==========================================
    public class DockBarForm : Form {
        private Config _config;
        private List<DockItem> _folders = new List<DockItem>();
        private List<DockItem> _shortcuts = new List<DockItem>();
        private List<Control> _dockControls = new List<Control>();

        private Panel _itemsPanel;
        private ToolStripDropDown _activeDropDown = null;
        private System.Windows.Forms.Timer _watchdogTimer;
        private int _outOfBoundsTicks = 0;
        private bool _isDockVisible = false;
        private int _scrollOffset = 0;
        private int _totalItemsLength = 0;
        private ToolTip _toolTip;
        private FileSystemWatcher _fsWatcher;
        private Action _openSettingsAction;

        private const int WS_EX_NOACTIVATE = 0x08000000;
        private const int WS_EX_TOOLWINDOW = 0x00000080;
        private const int WS_EX_TOPMOST = 0x00000008;

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= WS_EX_NOACTIVATE;
                cp.ExStyle |= WS_EX_TOOLWINDOW;
                cp.ExStyle |= WS_EX_TOPMOST;
                return cp;
            }
        }

        protected override bool ShowWithoutActivation {
            get { return true; }
        }

        public DockBarForm(Config config, Action openSettingsAction) {
            _config = config;
            _openSettingsAction = openSettingsAction;
            InitializeComponent();
            LoadItems();
            SetupFileSystemWatcher();
            SetupWatchdog();
        }

        private void InitializeComponent() {
            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.TopMost = true;
            this.StartPosition = FormStartPosition.Manual;
            this.DoubleBuffered = true;
            this.KeyPreview = true;

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            this.BackColor = theme.Background;

            _toolTip = new ToolTip();
            _toolTip.BackColor = theme.CardBackground;
            _toolTip.ForeColor = theme.TextPrimary;

            // Brand Logo Button (Clean GIN button - arrow button completely removed per user request!)
            Button brandBtn = new Button();
            brandBtn.Text = "⚡ GIN";
            brandBtn.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            brandBtn.ForeColor = theme.BrandText;
            brandBtn.BackColor = theme.BrandBadge;
            brandBtn.FlatStyle = FlatStyle.Flat;
            brandBtn.FlatAppearance.BorderSize = 1;
            brandBtn.FlatAppearance.BorderColor = theme.Border;
            brandBtn.Cursor = Cursors.Hand;
            brandBtn.Click += (s, e) => ShowMainMenu(brandBtn);
            _toolTip.SetToolTip(brandBtn, "GIN Dock Wallpaper v032 | Click for Menu");

            bool isTop = (_config.DockPosition == "Top");
            if (isTop) {
                this.Height = _config.BarHeight;
                brandBtn.Size = new Size(68, _config.BarHeight - 10);
                brandBtn.Location = new Point(5, 5);
            } else {
                this.Width = _config.BarHeight;
                brandBtn.Size = new Size(_config.BarHeight - 10, 36);
                brandBtn.Location = new Point(5, 5);
            }
            this.Controls.Add(brandBtn);

            // Items Panel Container
            _itemsPanel = new Panel();
            _itemsPanel.BackColor = Color.Transparent;
            if (isTop) {
                _itemsPanel.Location = new Point(78, 0);
                _itemsPanel.Height = _config.BarHeight;
                _itemsPanel.Width = Screen.PrimaryScreen.Bounds.Width - 90;
            } else {
                _itemsPanel.Location = new Point(0, 46);
                _itemsPanel.Width = _config.BarHeight;
                _itemsPanel.Height = Screen.PrimaryScreen.Bounds.Height - 60;
            }
            _itemsPanel.MouseWheel += ItemsPanel_MouseWheel;
            this.Controls.Add(_itemsPanel);

            this.MouseWheel += ItemsPanel_MouseWheel;
            this.KeyDown += (s, e) => {
                if (e.KeyCode == Keys.Escape) HideDock();
            };
        }

        private void ItemsPanel_MouseWheel(object sender, MouseEventArgs e) {
            ScrollDock(-e.Delta);
        }

        private void ScrollDock(int delta) {
            bool isTop = (_config.DockPosition == "Top");
            int panelSpan = isTop ? _itemsPanel.Width : _itemsPanel.Height;
            int maxScroll = Math.Max(0, _totalItemsLength - panelSpan);

            _scrollOffset += (delta > 0 ? 80 : -80);
            if (_scrollOffset < 0) _scrollOffset = 0;
            if (_scrollOffset > maxScroll) _scrollOffset = maxScroll;
            RelayoutItems();
        }

        public void LoadItems() {
            _folders.Clear();
            _shortcuts.Clear();

            if (Directory.Exists(_config.RootFolder)) {
                try {
                    string[] entries = Directory.GetFileSystemEntries(_config.RootFolder);
                    foreach (string entry in entries) {
                        try {
                            DockItem item = DockItem.FromPath(entry);
                            if (item.IsFolder) _folders.Add(item);
                            else _shortcuts.Add(item);
                        } catch { }
                    }
                } catch { }
            }

            // Apply User Configured Sorting (Default: Alphabetical)
            ApplySorting(_folders);
            ApplySorting(_shortcuts);

            BuildDockUI();
        }

        private void ApplySorting(List<DockItem> list) {
            string sort = _config.SortingMode;
            if (sort == "AlphaZA") {
                list.Sort((a, b) => string.Compare(b.Name, a.Name, StringComparison.OrdinalIgnoreCase));
            } else if (sort == "FileType") {
                list.Sort((a, b) => {
                    int c = string.Compare(a.Extension, b.Extension, StringComparison.OrdinalIgnoreCase);
                    return c != 0 ? c : string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
                });
            } else if (sort == "DateModified") {
                list.Sort((a, b) => DateTime.Compare(b.LastModified, a.LastModified));
            } else {
                // Default: AlphaAZ
                list.Sort((a, b) => string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase));
            }
        }

        private void BuildDockUI() {
            _itemsPanel.Controls.Clear();
            _dockControls.Clear();

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            this.BackColor = theme.Background;

            bool isTop = (_config.DockPosition == "Top");
            int cursor = 0;
            int itemSpan = _config.BarHeight - 10;

            Font folderFont = new Font("Segoe UI", _config.FolderFontSize, FontStyle.Regular);
            Font itemFont = new Font("Segoe UI", _config.ItemFontSize, FontStyle.Regular);

            // 1. Folders Group
            foreach (DockItem folder in _folders) {
                Button btn = new Button();
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = theme.Border;
                btn.BackColor = theme.CardBackground;
                btn.ForeColor = theme.TextPrimary;
                btn.Font = folderFont;
                btn.Cursor = Cursors.Hand;
                btn.Image = folder.IconSmall;
                btn.ImageAlign = ContentAlignment.MiddleLeft;
                btn.TextAlign = ContentAlignment.MiddleLeft;
                btn.TextImageRelation = TextImageRelation.ImageBeforeText;

                bool showLabel = (_config.ShowLabels == "FoldersOnly" || _config.ShowLabels == "All");
                if (isTop) {
                    btn.Height = itemSpan;
                    if (showLabel) {
                        btn.Text = " " + folder.Name + " ▾";
                        using (Graphics g = btn.CreateGraphics()) {
                            SizeF size = g.MeasureString(btn.Text, btn.Font);
                            btn.Width = (int)size.Width + 38;
                        }
                    } else {
                        btn.Text = "▾";
                        btn.Width = 44;
                    }
                } else {
                    btn.Width = itemSpan;
                    btn.Height = showLabel ? 32 : itemSpan;
                    btn.Text = showLabel ? folder.Name : "";
                }

                _toolTip.SetToolTip(btn, "📁 " + folder.Name + "\n(Click for items, Middle-Click for Explorer)");

                DockItem fItem = folder;
                btn.MouseEnter += (s, e) => {
                    btn.BackColor = theme.Accent;
                    btn.ForeColor = Color.Black;
                    OpenFolderDropDown(btn, fItem);
                };
                btn.MouseLeave += (s, e) => {
                    btn.BackColor = theme.CardBackground;
                    btn.ForeColor = theme.TextPrimary;
                };
                btn.MouseDown += (s, e) => {
                    if (e.Button == MouseButtons.Middle || (e.Button == MouseButtons.Left && Control.ModifierKeys == Keys.Control)) {
                        ShellHelper.OpenInExplorer(fItem.TargetFolder);
                        HideDock();
                    } else if (e.Button == MouseButtons.Left) {
                        OpenFolderDropDown(btn, fItem);
                    }
                };

                btn.Tag = cursor;
                _dockControls.Add(btn);
                _itemsPanel.Controls.Add(btn);
                cursor += (isTop ? btn.Width : btn.Height) + 4;
            }

            // Separator between Folders and Shortcuts
            if (_folders.Count > 0 && _shortcuts.Count > 0) {
                Label sep = new Label();
                if (isTop) {
                    sep.Width = 2;
                    sep.Height = itemSpan;
                } else {
                    sep.Height = 2;
                    sep.Width = itemSpan;
                }
                sep.BackColor = theme.Separator;
                sep.Tag = cursor;
                _dockControls.Add(sep);
                _itemsPanel.Controls.Add(sep);
                cursor += 8;
            }

            // 2. Direct Shortcuts & Applications
            foreach (DockItem item in _shortcuts) {
                Button btn = new Button();
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderSize = 0;
                btn.BackColor = Color.Transparent;
                btn.Cursor = Cursors.Hand;
                btn.Image = item.IconLarge;
                btn.ImageAlign = ContentAlignment.MiddleCenter;
                btn.Font = itemFont;
                btn.ForeColor = theme.TextPrimary;

                bool showLabel = (_config.ShowLabels == "All");
                if (isTop) {
                    btn.Height = itemSpan;
                    if (showLabel) {
                        btn.Text = " " + item.Name;
                        btn.ImageAlign = ContentAlignment.MiddleLeft;
                        btn.TextAlign = ContentAlignment.MiddleLeft;
                        btn.TextImageRelation = TextImageRelation.ImageBeforeText;
                        using (Graphics g = btn.CreateGraphics()) {
                            SizeF size = g.MeasureString(btn.Text, btn.Font);
                            btn.Width = (int)size.Width + 46;
                        }
                    } else {
                        btn.Width = itemSpan + 4;
                    }
                } else {
                    btn.Width = itemSpan;
                    btn.Height = showLabel ? 36 : (itemSpan + 4);
                    btn.Text = showLabel ? item.Name : "";
                }

                _toolTip.SetToolTip(btn, item.Name);

                DockItem scItem = item;
                btn.MouseEnter += (s, e) => {
                    btn.BackColor = theme.CardBackground;
                    CloseActiveDropDown();
                };
                btn.MouseLeave += (s, e) => {
                    btn.BackColor = Color.Transparent;
                };
                btn.Click += (s, e) => {
                    ShellHelper.Launch(scItem.FullPath);
                    HideDock();
                };

                btn.Tag = cursor;
                _dockControls.Add(btn);
                _itemsPanel.Controls.Add(btn);
                cursor += (isTop ? btn.Width : btn.Height) + 3;
            }

            _totalItemsLength = cursor;
            UpdateDockGeometry();
            RelayoutItems();
        }

        private void UpdateDockGeometry() {
            bool isTop = (_config.DockPosition == "Top");
            Screen screen = Screen.PrimaryScreen;

            if (isTop) {
                int desiredWidth = 85 + _totalItemsLength + 20;
                if (desiredWidth > screen.Bounds.Width) desiredWidth = screen.Bounds.Width;
                if (desiredWidth < 400) desiredWidth = 400;

                this.Width = desiredWidth;
                this.Height = _config.BarHeight;
                this.Location = new Point(0, 0);
                _itemsPanel.Width = this.Width - 90;
                _itemsPanel.Height = this.Height;
            } else {
                int desiredHeight = 55 + _totalItemsLength + 20;
                if (desiredHeight > screen.Bounds.Height) desiredHeight = screen.Bounds.Height;
                if (desiredHeight < 400) desiredHeight = 400;

                this.Width = _config.BarHeight;
                this.Height = desiredHeight;
                this.Location = new Point(0, 0);
                _itemsPanel.Width = this.Width;
                _itemsPanel.Height = this.Height - 55;
            }
        }

        private void RelayoutItems() {
            bool isTop = (_config.DockPosition == "Top");
            foreach (Control c in _dockControls) {
                int basePos = (int)c.Tag;
                if (isTop) {
                    c.Location = new Point(basePos - _scrollOffset, 5);
                } else {
                    c.Location = new Point(5, basePos - _scrollOffset);
                }
            }
        }

        private void OpenFolderDropDown(Button parentBtn, DockItem folder) {
            CloseActiveDropDown();

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            ContextMenuStrip cms = new ContextMenuStrip();
            cms.Renderer = new DynamicMenuRenderer(theme);
            cms.ShowImageMargin = true;
            cms.DropShadowEnabled = true;

            PopulateFolderMenuItems(cms.Items, folder.TargetFolder);

            if (cms.Items.Count > 0) cms.Items.Add(new ToolStripSeparator());
            ToolStripMenuItem openFolderItem = new ToolStripMenuItem("📂 " + I18n.T("OpenExplorer") + ": " + folder.Name);
            openFolderItem.ForeColor = theme.Accent;
            openFolderItem.Click += (s, e) => {
                ShellHelper.OpenInExplorer(folder.TargetFolder);
                HideDock();
            };
            cms.Items.Add(openFolderItem);

            _activeDropDown = cms;
            cms.Closed += (s, e) => {
                if (_activeDropDown == cms) _activeDropDown = null;
            };

            bool isTop = (_config.DockPosition == "Top");
            if (isTop) {
                Point screenPt = parentBtn.PointToScreen(new Point(0, parentBtn.Height + 2));
                cms.Show(screenPt, ToolStripDropDownDirection.BelowRight);
            } else {
                Point screenPt = parentBtn.PointToScreen(new Point(parentBtn.Width + 2, 0));
                cms.Show(screenPt, ToolStripDropDownDirection.Right);
            }
        }

        private void PopulateFolderMenuItems(ToolStripItemCollection targetList, string folderPath) {
            if (!Directory.Exists(folderPath)) return;

            try {
                string[] subDirs = Directory.GetDirectories(folderPath);
                Array.Sort(subDirs, (a, b) => string.Compare(Path.GetFileName(a), Path.GetFileName(b), StringComparison.OrdinalIgnoreCase));

                foreach (string dir in subDirs) {
                    string dirName = Path.GetFileName(dir);
                    ToolStripMenuItem subMenuItem = new ToolStripMenuItem(dirName);
                    subMenuItem.Image = ShellHelper.GetIconImage(dir, false);
                    subMenuItem.DropDownDirection = ToolStripDropDownDirection.Right;

                    string currentDir = dir;
                    bool populated = false;
                    subMenuItem.DropDownOpening += (s, e) => {
                        if (!populated) {
                            PopulateFolderMenuItems(subMenuItem.DropDownItems, currentDir);
                            if (subMenuItem.DropDownItems.Count == 0) {
                                subMenuItem.DropDownItems.Add(new ToolStripMenuItem("(Empty)") { Enabled = false });
                            }
                            subMenuItem.DropDownItems.Add(new ToolStripSeparator());
                            ToolStripMenuItem openSub = new ToolStripMenuItem("📂 Open Folder");
                            openSub.Click += (cs, ce) => {
                                ShellHelper.OpenInExplorer(currentDir);
                                HideDock();
                            };
                            subMenuItem.DropDownItems.Add(openSub);
                            populated = true;
                        }
                    };

                    subMenuItem.MouseDown += (s, e) => {
                        if (e.Button == MouseButtons.Middle) {
                            ShellHelper.OpenInExplorer(currentDir);
                            HideDock();
                        }
                    };

                    targetList.Add(subMenuItem);
                }

                string[] files = Directory.GetFiles(folderPath);
                Array.Sort(files, (a, b) => string.Compare(Path.GetFileNameWithoutExtension(a), Path.GetFileNameWithoutExtension(b), StringComparison.OrdinalIgnoreCase));

                if (subDirs.Length > 0 && files.Length > 0) {
                    targetList.Add(new ToolStripSeparator());
                }

                foreach (string file in files) {
                    string fileName = Path.GetFileNameWithoutExtension(file);
                    ToolStripMenuItem fileItem = new ToolStripMenuItem(fileName);
                    fileItem.Image = ShellHelper.GetIconImage(file, false);

                    string currentFile = file;
                    fileItem.Click += (s, e) => {
                        ShellHelper.Launch(currentFile);
                        HideDock();
                    };
                    fileItem.MouseDown += (s, e) => {
                        if (e.Button == MouseButtons.Right) {
                            ShellHelper.OpenInExplorer(currentFile);
                            HideDock();
                        }
                    };

                    targetList.Add(fileItem);
                }
            } catch { }
        }

        private void CloseActiveDropDown() {
            if (_activeDropDown != null) {
                try { _activeDropDown.Close(); } catch { }
                _activeDropDown = null;
            }
        }

        // ==========================================
        // WATCHDOG: HOT CORNER & AUTO-HIDE
        // ==========================================
        private void SetupWatchdog() {
            _watchdogTimer = new System.Windows.Forms.Timer();
            _watchdogTimer.Interval = 40;
            _watchdogTimer.Tick += WatchdogTimer_Tick;
            if (_config.EnableDock) _watchdogTimer.Start();
        }

        private void WatchdogTimer_Tick(object sender, EventArgs e) {
            if (!_config.EnableDock) return;

            Point p = Cursor.Position;

            if (!_isDockVisible) {
                bool trigger = false;
                if (_config.DockPosition == "Top") {
                    trigger = (p.X <= _config.HotCornerWidth && p.Y <= _config.HotCornerHeight);
                } else {
                    trigger = (p.X <= _config.HotCornerWidth && p.Y <= _config.HotCornerHeight);
                }
                if (trigger) ShowDock();
            } else {
                bool insideDock = this.Bounds.Contains(p);
                bool insideDropDown = false;

                if (_activeDropDown != null && _activeDropDown.Visible) {
                    insideDropDown = _activeDropDown.Bounds.Contains(p);
                    if (!insideDropDown) {
                        foreach (ToolStripItem item in _activeDropDown.Items) {
                            ToolStripMenuItem mi = item as ToolStripMenuItem;
                            if (mi != null && mi.DropDown != null && mi.DropDown.Visible) {
                                if (mi.DropDown.Bounds.Contains(p)) {
                                    insideDropDown = true;
                                    break;
                                }
                            }
                        }
                    }
                }

                if (insideDock || insideDropDown) {
                    _outOfBoundsTicks = 0;
                } else {
                    _outOfBoundsTicks++;
                    if (_outOfBoundsTicks * _watchdogTimer.Interval >= _config.AutoHideDelayMs) {
                        HideDock();
                    }
                }
            }
        }

        public void ShowDock() {
            if (!_config.EnableDock) return;
            if (!_isDockVisible) {
                _isDockVisible = true;
                _outOfBoundsTicks = 0;
                this.Show();
                this.BringToFront();
            }
        }

        public void HideDock() {
            if (_isDockVisible) {
                CloseActiveDropDown();
                _isDockVisible = false;
                this.Hide();
            }
        }

        private void ShowMainMenu(Control anchor) {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            ContextMenuStrip menu = new ContextMenuStrip();
            menu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem header = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v032");
            header.Enabled = false;
            header.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            header.ForeColor = theme.Accent;
            menu.Items.Add(header);
            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem openFolder = new ToolStripMenuItem("📂 " + I18n.T("OpenFolder"));
            openFolder.Click += (s, e) => {
                ShellHelper.OpenInExplorer(_config.RootFolder);
                HideDock();
            };
            menu.Items.Add(openFolder);

            ToolStripMenuItem chooseFolder = new ToolStripMenuItem("📁 " + I18n.T("Browse"));
            chooseFolder.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog()) {
                    fbd.SelectedPath = _config.RootFolder;
                    fbd.Description = I18n.T("RootFolder");
                    if (fbd.ShowDialog() == DialogResult.OK) {
                        _config.RootFolder = fbd.SelectedPath;
                        _config.Save();
                        SetupFileSystemWatcher();
                        LoadItems();
                    }
                }
            };
            menu.Items.Add(chooseFolder);

            ToolStripMenuItem reload = new ToolStripMenuItem("🔄 " + I18n.T("Reload"));
            reload.Click += (s, e) => LoadItems();
            menu.Items.Add(reload);

            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem settings = new ToolStripMenuItem("⚙️ " + I18n.T("Settings"));
            settings.Click += (s, e) => {
                HideDock();
                if (_openSettingsAction != null) _openSettingsAction();
            };
            menu.Items.Add(settings);

            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem exit = new ToolStripMenuItem("❌ " + I18n.T("Exit"));
            exit.Click += (s, e) => Application.Exit();
            menu.Items.Add(exit);

            _activeDropDown = menu;
            menu.Show(anchor, new Point(0, anchor.Height + 2));
        }

        private void SetupFileSystemWatcher() {
            if (_fsWatcher != null) {
                _fsWatcher.Dispose();
                _fsWatcher = null;
            }
            if (Directory.Exists(_config.RootFolder)) {
                try {
                    _fsWatcher = new FileSystemWatcher(_config.RootFolder);
                    _fsWatcher.NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.LastWrite;
                    _fsWatcher.Changed += (s, e) => SafeReload();
                    _fsWatcher.Created += (s, e) => SafeReload();
                    _fsWatcher.Deleted += (s, e) => SafeReload();
                    _fsWatcher.Renamed += (s, e) => SafeReload();
                    _fsWatcher.EnableRaisingEvents = true;
                } catch { }
            }
        }

        private void SafeReload() {
            if (this.InvokeRequired) {
                this.BeginInvoke(new Action(SafeReload));
                return;
            }
            LoadItems();
        }

        protected override void OnPaint(PaintEventArgs e) {
            base.OnPaint(e);
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            using (Pen borderPen = new Pen(theme.Border, 1)) {
                if (_config.DockPosition == "Top") {
                    e.Graphics.DrawLine(borderPen, 0, this.Height - 1, this.Width, this.Height - 1);
                    e.Graphics.DrawLine(borderPen, this.Width - 1, 0, this.Width - 1, this.Height - 1);
                } else {
                    e.Graphics.DrawLine(borderPen, this.Width - 1, 0, this.Width - 1, this.Height);
                    e.Graphics.DrawLine(borderPen, 0, this.Height - 1, this.Width - 1, this.Height - 1);
                }
            }
        }

        protected override void Dispose(bool disposing) {
            if (disposing) {
                if (_watchdogTimer != null) _watchdogTimer.Dispose();
                if (_fsWatcher != null) _fsWatcher.Dispose();
                if (_toolTip != null) _toolTip.Dispose();
            }
            base.Dispose(disposing);
        }
    }

    // ==========================================
    // SETTINGS FORM (RICH TABBED MODERN GUI)
    // ==========================================
    public class SettingsForm : Form {
        private Config _config;
        private Action _onConfigChanged;
        private WallpaperEngine _wallpaperEngine;

        public SettingsForm(Config config, Action onConfigChanged, WallpaperEngine wallpaperEngine) {
            _config = config;
            _onConfigChanged = onConfigChanged;
            _wallpaperEngine = wallpaperEngine;
            InitializeComponent();
        }

        private void InitializeComponent() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);

            this.Text = "⚡ " + I18n.T("AppTitle") + " — " + I18n.T("Settings");
            this.Size = new Size(680, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = theme.Background;
            this.ForeColor = theme.TextPrimary;
            this.Font = new Font("Segoe UI", 9f);

            TabControl tabs = new TabControl();
            tabs.Dock = DockStyle.Top;
            tabs.Height = 450;

            // 1. General Tab
            TabPage tabGen = new TabPage(I18n.T("TabGeneral"));
            tabGen.BackColor = theme.CardBackground;

            CheckBox chkEnableDock = new CheckBox { Text = I18n.T("EnableDock"), Checked = _config.EnableDock, Location = new Point(25, 25), AutoSize = true, ForeColor = theme.TextPrimary };
            CheckBox chkEnableWall = new CheckBox { Text = I18n.T("EnableWallpaper"), Checked = _config.EnableWallpaper, Location = new Point(25, 60), AutoSize = true, ForeColor = theme.TextPrimary };

            Label lblPlacement = new Label { Text = I18n.T("DockPlacement"), Location = new Point(25, 105), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbPlacement = new ComboBox { Location = new Point(250, 102), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbPlacement.Items.Add(I18n.T("PlacementTop"));
            cmbPlacement.Items.Add(I18n.T("PlacementLeft"));
            cmbPlacement.SelectedIndex = (_config.DockPosition == "Left" ? 1 : 0);

            Label lblLang = new Label { Text = I18n.T("Language"), Location = new Point(25, 150), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbLang = new ComboBox { Location = new Point(250, 147), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbLang.Items.Add("English (EN)");
            cmbLang.Items.Add("Русский (RU)");
            cmbLang.Items.Add("Čeština (CS)");
            cmbLang.Items.Add("Deutsch (DE)");
            cmbLang.Items.Add("Français (FR)");
            cmbLang.Items.Add("Español (ES)");
            cmbLang.Items.Add("Italiano (IT)");
            cmbLang.Items.Add("Português (PT)");
            cmbLang.Items.Add("Polski (PL)");
            cmbLang.Items.Add("Українська (UK)");
            cmbLang.Items.Add("简体中文 (ZH)");
            cmbLang.Items.Add("日本語 (JA)");
            SelectLanguageIndex(cmbLang, _config.Language);

            CheckBox chkAutoStart = new CheckBox { Text = I18n.T("AutoStart"), Checked = _config.StartWithWindows, Location = new Point(25, 200), AutoSize = true, ForeColor = theme.TextPrimary };
            CheckBox chkAutoUpdate = new CheckBox { Text = I18n.T("AutoUpdate"), Checked = _config.CheckUpdatesOnStartup, Location = new Point(25, 235), AutoSize = true, ForeColor = theme.TextPrimary };

            tabGen.Controls.AddRange(new Control[] { chkEnableDock, chkEnableWall, lblPlacement, cmbPlacement, lblLang, cmbLang, chkAutoStart, chkAutoUpdate });
            tabs.TabPages.Add(tabGen);

            // 2. Appearance & Themes Tab
            TabPage tabApp = new TabPage(I18n.T("TabAppearance"));
            tabApp.BackColor = theme.CardBackground;

            Label lblDayNight = new Label { Text = I18n.T("DayNightMode"), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbDayNight = new ComboBox { Location = new Point(250, 22), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbDayNight.Items.AddRange(new string[] { I18n.T("ModeAuto"), I18n.T("ModeDay"), I18n.T("ModeNight") });
            cmbDayNight.SelectedIndex = (_config.DayNightMode == "Day" ? 1 : (_config.DayNightMode == "Night" ? 2 : 0));

            Label lblTheme = new Label { Text = I18n.T("ColorTheme"), Location = new Point(25, 65), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbTheme = new ComboBox { Location = new Point(250, 62), Width = 280, DropDownStyle = ComboBoxStyle.DropDownList };
            foreach (var th in ThemeManager.Themes.Values) {
                cmbTheme.Items.Add(th.Name);
            }
            SelectThemeIndex(cmbTheme, _config.ThemeName);

            // Separate Font Size for Folders
            Label lblFolderFont = new Label { Text = I18n.T("FolderFontSize") + " (" + _config.FolderFontSize + " pt)", Location = new Point(25, 115), AutoSize = true, ForeColor = theme.TextSecondary };
            TrackBar tbFolderFont = new TrackBar { Location = new Point(250, 110), Width = 280, Minimum = 7, Maximum = 16, Value = (int)Math.Max(7, Math.Min(16, _config.FolderFontSize)) };
            tbFolderFont.ValueChanged += (s, e) => lblFolderFont.Text = I18n.T("FolderFontSize") + " (" + tbFolderFont.Value + " pt)";

            // Separate Font Size for Opened Items / Apps
            Label lblItemFont = new Label { Text = I18n.T("ItemFontSize") + " (" + _config.ItemFontSize + " pt)", Location = new Point(25, 165), AutoSize = true, ForeColor = theme.TextSecondary };
            TrackBar tbItemFont = new TrackBar { Location = new Point(250, 160), Width = 280, Minimum = 7, Maximum = 16, Value = (int)Math.Max(7, Math.Min(16, _config.ItemFontSize)) };
            tbItemFont.ValueChanged += (s, e) => lblItemFont.Text = I18n.T("ItemFontSize") + " (" + tbItemFont.Value + " pt)";

            Label lblLabels = new Label { Text = I18n.T("ShowLabels"), Location = new Point(25, 215), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbLabels = new ComboBox { Location = new Point(250, 212), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbLabels.Items.AddRange(new string[] { I18n.T("LabelsFoldersOnly"), I18n.T("LabelsAll"), I18n.T("LabelsNone") });
            cmbLabels.SelectedIndex = (_config.ShowLabels == "All" ? 1 : (_config.ShowLabels == "None" ? 2 : 0));

            tabApp.Controls.AddRange(new Control[] { lblDayNight, cmbDayNight, lblTheme, cmbTheme, lblFolderFont, tbFolderFont, lblItemFont, tbItemFont, lblLabels, cmbLabels });
            tabs.TabPages.Add(tabApp);

            // 3. Dock & Items Tab
            TabPage tabDock = new TabPage(I18n.T("TabDock"));
            tabDock.BackColor = theme.CardBackground;

            Label lblRoot = new Label { Text = I18n.T("RootFolder"), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.TextSecondary };
            TextBox txtRoot = new TextBox { Text = _config.RootFolder, Location = new Point(25, 48), Width = 460 };
            Button btnBrowse = new Button { Text = I18n.T("Browse"), Location = new Point(495, 46), Width = 110, Height = 26 };
            btnBrowse.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog()) {
                    fbd.SelectedPath = txtRoot.Text;
                    if (fbd.ShowDialog() == DialogResult.OK) txtRoot.Text = fbd.SelectedPath;
                }
            };

            Label lblSort = new Label { Text = I18n.T("SortingMode"), Location = new Point(25, 100), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbSort = new ComboBox { Location = new Point(250, 97), Width = 320, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbSort.Items.AddRange(new string[] {
                I18n.T("SortAlphaAZ"),
                I18n.T("SortAlphaZA"),
                I18n.T("SortFoldersFirst"),
                I18n.T("SortFileType"),
                I18n.T("SortDateModified")
            });
            SelectSortIndex(cmbSort, _config.SortingMode);

            Label lblDelay = new Label { Text = I18n.T("AutoHideDelay") + " (" + _config.AutoHideDelayMs + " ms)", Location = new Point(25, 150), AutoSize = true, ForeColor = theme.TextSecondary };
            TrackBar tbDelay = new TrackBar { Location = new Point(250, 145), Width = 280, Minimum = 200, Maximum = 1500, TickFrequency = 100, Value = Math.Max(200, Math.Min(1500, _config.AutoHideDelayMs)) };
            tbDelay.ValueChanged += (s, e) => lblDelay.Text = I18n.T("AutoHideDelay") + " (" + tbDelay.Value + " ms)";

            tabDock.Controls.AddRange(new Control[] { lblRoot, txtRoot, btnBrowse, lblSort, cmbSort, lblDelay, tbDelay });
            tabs.TabPages.Add(tabDock);

            // 4. Wallpaper & Calendar Tab
            TabPage tabWall = new TabPage(I18n.T("TabWallpaper"));
            tabWall.BackColor = theme.CardBackground;

            Label lblCat = new Label { Text = I18n.T("WallpaperCategory"), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbCat = new ComboBox { Location = new Point(250, 22), Width = 240, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbCat.Items.AddRange(new string[] { "Nature & Landscapes", "Cyberpunk & Neon", "3D Abstract", "Space & Cosmos", "Cars & Supercars", "Cityscapes", "Minimalism", "All Random" });
            SelectCategoryIndex(cmbCat, _config.WallpaperCategory);

            Label lblInt = new Label { Text = I18n.T("WallpaperInterval"), Location = new Point(25, 70), AutoSize = true, ForeColor = theme.TextSecondary };
            ComboBox cmbInt = new ComboBox { Location = new Point(250, 67), Width = 240, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbInt.Items.AddRange(new string[] { "Every 15 minutes", "Every 30 minutes", "Every 1 hour", "Every 3 hours", "Every 6 hours", "Every 12 hours", "Daily (24h)" });
            SelectIntervalIndex(cmbInt, _config.WallpaperIntervalMinutes);

            CheckBox chkCal = new CheckBox { Text = I18n.T("ShowCalendar"), Checked = _config.ShowCalendar, Location = new Point(25, 120), AutoSize = true, ForeColor = theme.TextPrimary };

            Button btnNextWall = new Button { Text = "🖼️ " + I18n.T("NextWallpaper"), Location = new Point(25, 170), Width = 220, Height = 32 };
            btnNextWall.Click += (s, e) => {
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                    MessageBox.Show("Downloading fresh 4K wallpaper...", "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            };

            Button btnSaveWall = new Button { Text = "💾 " + I18n.T("SaveCurrentWallpaper"), Location = new Point(260, 170), Width = 270, Height = 32 };
            btnSaveWall.Click += (s, e) => {
                if (_wallpaperEngine != null) _wallpaperEngine.SaveActiveWallpaperToPictures();
            };

            tabWall.Controls.AddRange(new Control[] { lblCat, cmbCat, lblInt, cmbInt, chkCal, btnNextWall, btnSaveWall });
            tabs.TabPages.Add(tabWall);

            // 5. About & Updates Tab
            TabPage tabAbout = new TabPage(I18n.T("TabAbout"));
            tabAbout.BackColor = theme.CardBackground;

            Label lblAboutTitle = new Label { Text = "⚡ GIN Dock Wallpaper v032", Font = new Font("Segoe UI", 12f, FontStyle.Bold), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.Accent };
            Label lblAuthor = new Label { Text = "Author: Vladimir Bulantsev (@GinCz) & Antigravity\nOpen Source / MIT License\nUniversal 32/64-bit Windows Architecture\nPlatform: Native WinAPI & GDI+ (Ultra-Low Memory Footprint)", Location = new Point(25, 65), AutoSize = true, ForeColor = theme.TextSecondary };

            Button btnCheckUpdate = new Button { Text = "⬆️ " + I18n.T("CheckUpdates"), Location = new Point(25, 160), Width = 220, Height = 32 };
            btnCheckUpdate.Click += (s, e) => CheckUpdateRoutine(true);

            Button btnOpenGitHub = new Button { Text = "🌐 GitHub Open Source Repository", Location = new Point(260, 160), Width = 260, Height = 32 };
            btnOpenGitHub.Click += (s, e) => {
                try { Process.Start("https://github.com/GinCz/Windows_scripts/tree/main/GIN-Dock-Wallpaper"); } catch { }
            };

            tabAbout.Controls.AddRange(new Control[] { lblAboutTitle, lblAuthor, btnCheckUpdate, btnOpenGitHub });
            tabs.TabPages.Add(tabAbout);

            this.Controls.Add(tabs);

            // Bottom Buttons
            Button btnSave = new Button { Text = I18n.T("Save"), Location = new Point(390, 470), Width = 140, Height = 34, DialogResult = DialogResult.OK };
            btnSave.Click += (s, e) => {
                _config.EnableDock = chkEnableDock.Checked;
                _config.EnableWallpaper = chkEnableWall.Checked;
                _config.DockPosition = (cmbPlacement.SelectedIndex == 1 ? "Left" : "Top");
                _config.Language = GetSelectedLanguageCode(cmbLang.SelectedIndex);
                _config.StartWithWindows = chkAutoStart.Checked;
                _config.CheckUpdatesOnStartup = chkAutoUpdate.Checked;

                _config.DayNightMode = (cmbDayNight.SelectedIndex == 1 ? "Day" : (cmbDayNight.SelectedIndex == 2 ? "Night" : "Auto"));
                _config.ThemeName = GetThemeIdByIndex(cmbTheme.SelectedIndex);
                _config.FolderFontSize = tbFolderFont.Value;
                _config.ItemFontSize = tbItemFont.Value;
                _config.ShowLabels = (cmbLabels.SelectedIndex == 1 ? "All" : (cmbLabels.SelectedIndex == 2 ? "None" : "FoldersOnly"));

                _config.RootFolder = txtRoot.Text;
                _config.SortingMode = GetSortCodeByIndex(cmbSort.SelectedIndex);
                _config.AutoHideDelayMs = tbDelay.Value;

                _config.WallpaperCategory = GetCategoryCodeByIndex(cmbCat.SelectedIndex);
                _config.WallpaperIntervalMinutes = GetIntervalMinutesByIndex(cmbInt.SelectedIndex);
                _config.ShowCalendar = chkCal.Checked;

                SetAutoStartRegistry(_config.StartWithWindows);
                _config.Save();

                if (_wallpaperEngine != null) {
                    _wallpaperEngine.SetEnabled(_config.EnableWallpaper);
                    _wallpaperEngine.UpdateInterval();
                }

                if (_onConfigChanged != null) _onConfigChanged();
                this.Close();
            };

            Button btnCancel = new Button { Text = I18n.T("Cancel"), Location = new Point(540, 470), Width = 110, Height = 34, DialogResult = DialogResult.Cancel };
            btnCancel.Click += (s, e) => this.Close();

            this.Controls.Add(btnSave);
            this.Controls.Add(btnCancel);
        }

        private void SelectLanguageIndex(ComboBox cmb, string lang) {
            string l = (lang ?? "en").ToLowerInvariant();
            if (l == "ru") cmb.SelectedIndex = 1;
            else if (l == "cs") cmb.SelectedIndex = 2;
            else if (l == "de") cmb.SelectedIndex = 3;
            else if (l == "fr") cmb.SelectedIndex = 4;
            else if (l == "es") cmb.SelectedIndex = 5;
            else if (l == "it") cmb.SelectedIndex = 6;
            else if (l == "pt") cmb.SelectedIndex = 7;
            else if (l == "pl") cmb.SelectedIndex = 8;
            else if (l == "uk") cmb.SelectedIndex = 9;
            else if (l == "zh") cmb.SelectedIndex = 10;
            else if (l == "ja") cmb.SelectedIndex = 11;
            else cmb.SelectedIndex = 0;
        }

        private string GetSelectedLanguageCode(int idx) {
            string[] codes = new string[] { "en", "ru", "cs", "de", "fr", "es", "it", "pt", "pl", "uk", "zh", "ja" };
            if (idx >= 0 && idx < codes.Length) return codes[idx];
            return "en";
        }

        private void SelectThemeIndex(ComboBox cmb, string themeId) {
            int i = 0;
            foreach (var th in ThemeManager.Themes.Values) {
                if (string.Equals(th.Id, themeId, StringComparison.OrdinalIgnoreCase)) {
                    cmb.SelectedIndex = i;
                    return;
                }
                i++;
            }
            if (cmb.Items.Count > 0) cmb.SelectedIndex = 0;
        }

        private string GetThemeIdByIndex(int idx) {
            int i = 0;
            foreach (var th in ThemeManager.Themes.Values) {
                if (i == idx) return th.Id;
                i++;
            }
            return "WarmSand";
        }

        private void SelectSortIndex(ComboBox cmb, string mode) {
            if (mode == "AlphaZA") cmb.SelectedIndex = 1;
            else if (mode == "FoldersFirst") cmb.SelectedIndex = 2;
            else if (mode == "FileType") cmb.SelectedIndex = 3;
            else if (mode == "DateModified") cmb.SelectedIndex = 4;
            else cmb.SelectedIndex = 0;
        }

        private string GetSortCodeByIndex(int idx) {
            string[] codes = new string[] { "AlphaAZ", "AlphaZA", "FoldersFirst", "FileType", "DateModified" };
            if (idx >= 0 && idx < codes.Length) return codes[idx];
            return "AlphaAZ";
        }

        private void SelectCategoryIndex(ComboBox cmb, string cat) {
            string c = (cat ?? "nature").ToLowerInvariant();
            if (c == "cyberpunk") cmb.SelectedIndex = 1;
            else if (c == "3d") cmb.SelectedIndex = 2;
            else if (c == "space") cmb.SelectedIndex = 3;
            else if (c == "cars") cmb.SelectedIndex = 4;
            else if (c == "city") cmb.SelectedIndex = 5;
            else if (c == "minimalism") cmb.SelectedIndex = 6;
            else if (c == "random") cmb.SelectedIndex = 7;
            else cmb.SelectedIndex = 0;
        }

        private string GetCategoryCodeByIndex(int idx) {
            string[] codes = new string[] { "nature", "cyberpunk", "3d", "space", "cars", "city", "minimalism", "random" };
            if (idx >= 0 && idx < codes.Length) return codes[idx];
            return "nature";
        }

        private void SelectIntervalIndex(ComboBox cmb, int mins) {
            if (mins <= 15) cmb.SelectedIndex = 0;
            else if (mins <= 30) cmb.SelectedIndex = 1;
            else if (mins <= 60) cmb.SelectedIndex = 2;
            else if (mins <= 180) cmb.SelectedIndex = 3;
            else if (mins <= 360) cmb.SelectedIndex = 4;
            else if (mins <= 720) cmb.SelectedIndex = 5;
            else cmb.SelectedIndex = 6;
        }

        private int GetIntervalMinutesByIndex(int idx) {
            int[] vals = new int[] { 15, 30, 60, 180, 360, 720, 1440 };
            if (idx >= 0 && idx < vals.Length) return vals[idx];
            return 60;
        }

        private void SetAutoStartRegistry(bool enable) {
            try {
                RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                if (enable) {
                    rk.SetValue("GIN-Dock-Wallpaper", "\"" + Application.ExecutablePath + "\"");
                } else {
                    rk.DeleteValue("GIN-Dock-Wallpaper", false);
                }
            } catch { }
        }

        public static void CheckUpdateRoutine(bool showUpToDate) {
            ThreadPool.QueueUserWorkItem(_ => {
                try {
                    string url = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Dock-Wallpaper/version.json";
                    using (WebClient wc = new WebClient()) {
                        wc.Headers.Add("User-Agent", "GIN-Dock-Wallpaper");
                        string json = wc.DownloadString(url);
                        // extract version string
                        int vIdx = json.IndexOf("\"version\":");
                        if (vIdx != -1) {
                            int q1 = json.IndexOf("\"", vIdx + 10);
                            int q2 = json.IndexOf("\"", q1 + 1);
                            string remoteVer = json.Substring(q1 + 1, q2 - q1 - 1);
                            string currentVer = "v032";

                            if (string.Compare(remoteVer, currentVer, StringComparison.OrdinalIgnoreCase) > 0) {
                                DialogResult dr = MessageBox.Show(
                                    I18n.T("UpdateAvailable") + remoteVer + "\n" + I18n.T("DownloadNow"),
                                    "GIN Dock Wallpaper Update",
                                    MessageBoxButtons.YesNo,
                                    MessageBoxIcon.Question
                                );
                                if (dr == DialogResult.Yes) {
                                    Process.Start("https://github.com/GinCz/Windows_scripts/tree/main/GIN-Dock-Wallpaper");
                                }
                            } else if (showUpToDate) {
                                MessageBox.Show(
                                    I18n.T("UpToDate") + currentVer,
                                    "GIN Dock Wallpaper",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Information
                                );
                            }
                        }
                    }
                } catch (Exception ex) {
                    if (showUpToDate) {
                        MessageBox.Show("Failed to check for updates:\n" + ex.Message, "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                }
            });
        }
    }

    // ==========================================
    // APPLICATION CONTEXT & SINGLE TRAY ICON
    // ==========================================
    public class DockWallpaperApplicationContext : ApplicationContext {
        private NotifyIcon _trayIcon;
        private DockBarForm _dockForm;
        private Config _config;
        private WallpaperEngine _wallpaperEngine;

        public DockWallpaperApplicationContext() {
            _config = Config.Load();
            _wallpaperEngine = new WallpaperEngine(_config);
            _dockForm = new DockBarForm(_config, ShowSettings);

            _trayIcon = new NotifyIcon();
            _trayIcon.Text = "GIN Dock Wallpaper v032 | GIN-Dock + Dynamic 4K Wallpaper";

            // Load Icon (app.ico or Sand G fallback)
            try {
                string icoPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app.ico");
                if (File.Exists(icoPath)) {
                    _trayIcon.Icon = new Icon(icoPath);
                    _dockForm.Icon = _trayIcon.Icon;
                } else {
                    _trayIcon.Icon = SystemIcons.Application;
                }
            } catch {
                _trayIcon.Icon = SystemIcons.Application;
            }

            BuildTrayMenu();

            _trayIcon.Visible = true;
            _trayIcon.DoubleClick += (s, e) => ShowSettings();

            if (_config.CheckUpdatesOnStartup) {
                SettingsForm.CheckUpdateRoutine(false);
            }

            NativeMethods.TrimMemory();
        }

        private void BuildTrayMenu() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayNightMode);
            ContextMenuStrip trayMenu = new ContextMenuStrip();
            trayMenu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem title = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v032");
            title.Enabled = false;
            title.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            title.ForeColor = theme.Accent;
            trayMenu.Items.Add(title);
            trayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem settings = new ToolStripMenuItem("⚙️ " + I18n.T("Settings"));
            settings.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            settings.Click += (s, e) => ShowSettings();
            trayMenu.Items.Add(settings);

            ToolStripMenuItem showDock = new ToolStripMenuItem("🚀 " + I18n.T("ShowDock"));
            showDock.Click += (s, e) => _dockForm.ShowDock();
            trayMenu.Items.Add(showDock);

            ToolStripMenuItem nextWall = new ToolStripMenuItem("🖼️ " + I18n.T("NextWallpaper"));
            nextWall.Click += (s, e) => _wallpaperEngine.TriggerNextWallpaperAsync();
            trayMenu.Items.Add(nextWall);

            ToolStripMenuItem openFolder = new ToolStripMenuItem("📂 " + I18n.T("OpenFolder"));
            openFolder.Click += (s, e) => ShellHelper.OpenInExplorer(_config.RootFolder);
            trayMenu.Items.Add(openFolder);

            ToolStripMenuItem reload = new ToolStripMenuItem("🔄 " + I18n.T("Reload"));
            reload.Click += (s, e) => {
                _dockForm.LoadItems();
                NativeMethods.TrimMemory();
            };
            trayMenu.Items.Add(reload);

            ToolStripMenuItem checkUpd = new ToolStripMenuItem("⬆️ " + I18n.T("CheckUpdates"));
            checkUpd.Click += (s, e) => SettingsForm.CheckUpdateRoutine(true);
            trayMenu.Items.Add(checkUpd);

            trayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem exit = new ToolStripMenuItem("❌ " + I18n.T("Exit"));
            exit.Click += (s, e) => {
                _trayIcon.Visible = false;
                Application.Exit();
            };
            trayMenu.Items.Add(exit);

            _trayIcon.ContextMenuStrip = trayMenu;
        }

        private void ShowSettings() {
            using (SettingsForm sf = new SettingsForm(_config, () => {
                BuildTrayMenu();
                _dockForm.LoadItems();
            }, _wallpaperEngine)) {
                sf.ShowDialog();
            }
        }

        protected override void ExitThreadCore() {
            if (_trayIcon != null) {
                _trayIcon.Visible = false;
                _trayIcon.Dispose();
            }
            base.ExitThreadCore();
        }
    }

    // ==========================================
    // UNINSTALLER ROUTINE & MAIN ENTRY POINT
    // ==========================================
    public static class Program {
        [STAThread]
        public static void Main(string[] args) {
            // Check for uninstall argument
            if (args != null && args.Length > 0 && (args[0].Equals("--uninstall", StringComparison.OrdinalIgnoreCase) || args[0].Equals("/uninstall", StringComparison.OrdinalIgnoreCase))) {
                RunUninstall();
                return;
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "GIN_Dock_Wallpaper_SingleInstance_Mutex", out createdNew)) {
                if (!createdNew) {
                    MessageBox.Show(
                        "GIN Dock Wallpaper is already running in the background!\nLook for the Sand 'G' icon in your system tray (bottom-right).",
                        "GIN Dock Wallpaper",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    );
                    return;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new DockWallpaperApplicationContext());
            }
        }

        public static void RunUninstall() {
            DialogResult res = MessageBox.Show(
                "Are you sure you want to completely uninstall GIN Dock Wallpaper?",
                "GIN Dock Wallpaper Uninstaller",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );
            if (res != DialogResult.Yes) return;

            try {
                // 1. Remove autostart registry
                try {
                    RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                    if (rk != null) {
                        rk.DeleteValue("GIN-Dock-Wallpaper", false);
                        rk.DeleteValue("GIN-Dock", false);
                        rk.DeleteValue("GIN-Wallpaper", false);
                    }
                } catch { }

                // 2. Remove desktop & start menu shortcuts
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                string deskLnk = Path.Combine(desktop, "GIN Dock Wallpaper.lnk");
                if (File.Exists(deskLnk)) File.Delete(deskLnk);

                string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "GIN Dock Wallpaper");
                if (Directory.Exists(startMenu)) Directory.Delete(startMenu, true);

                // 3. Remove Add/Remove Programs registry key
                try {
                    RegistryKey uninstKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall", true);
                    if (uninstKey != null) {
                        uninstKey.DeleteSubKeyTree("GIN-Dock-Wallpaper", false);
                    }
                } catch { }

                MessageBox.Show(
                    "GIN Dock Wallpaper has been successfully uninstalled from your computer.",
                    "GIN Dock Wallpaper Uninstaller",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );

                // Self-delete schedule script
                string installDir = AppDomain.CurrentDomain.BaseDirectory;
                string delCmd = Path.Combine(Path.GetTempPath(), "gin_uninst_cleanup.cmd");
                File.WriteAllText(delCmd, "@echo off\r\ntimeout /t 2 /nobreak >nul\r\nrmdir /s /q \"" + installDir + "\"\r\ndel \"%~f0\"\r\n");
                ProcessStartInfo psi = new ProcessStartInfo {
                    FileName = "cmd.exe",
                    Arguments = "/c \"" + delCmd + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process.Start(psi);
                Environment.Exit(0);
            } catch (Exception ex) {
                MessageBox.Show("Uninstall error: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}

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
[assembly: AssemblyVersion("0.33.0.0")]
[assembly: AssemblyFileVersion("0.33.0.0")]

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
    // THEMES & STYLING
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
            // 1. Warm Sand (Default Signature Theme - Evening Warm Amber)
            Register(new ColorTheme {
                Id = "WarmSand",
                Name = "Warm Sand (Default / Теплый Песок)",
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

            // 2. Midnight OLED (Deep Night)
            Register(new ColorTheme {
                Id = "MidnightOLED",
                Name = "Midnight OLED (Глубокая Ночь)",
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
                Name = "Cyberpunk Amber (Киберпанк)",
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
                Name = "Nordic Frost (Северный Мороз)",
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
                Name = "Emerald Forest (Изумрудный Лес)",
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
                Name = "Deep Space Navy (Космос)",
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
                Name = "Solarized Desert (Пустынный Бронз)",
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
                Name = "Tokyo Neon (Токио Неон)",
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

            // 9. Pure Glass Slate
            Register(new ColorTheme {
                Id = "PureGlass",
                Name = "Pure Glass Slate (Стекло и Графит)",
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
                Name = "Rose Gold Luxury (Розовое Золото)",
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
                Name = "Titanium Monochrome (Титан Графит)",
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
                Name = "Daylight Light Mode (День / Светлый)",
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

        public static ColorTheme GetTheme(string id, string dayEveningNightMode) {
            if (dayEveningNightMode == "Day") {
                return Themes["DaylightLight"];
            } else if (dayEveningNightMode == "Night") {
                return Themes["MidnightOLED"];
            } else if (dayEveningNightMode == "Evening") {
                return Themes["WarmSand"];
            }

            int hour = DateTime.Now.Hour;
            if (hour >= 7 && hour < 18) {
                return Themes["DaylightLight"];
            } else if (hour >= 18 && hour < 22) {
                return Themes["WarmSand"];
            } else {
                return Themes["MidnightOLED"];
            }
        }
    }

    // ==========================================
    // MULTILINGUAL LOCALIZATION (12 LANGUAGES)
    // ==========================================
    public static class I18n {
        private static string _currentLang = "en";
        public static string CurrentLanguage { get { return _currentLang; } }
        public static event Action LanguageChanged;

        private static readonly Dictionary<string, Dictionary<string, string>> Dictionaries = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

        static I18n() {
            // English
            var en = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Show Dock" },
                { "NextWallpaper", "Next Wallpaper Now" },
                { "OpenFolder", "Open Dock Folder" },
                { "Reload", "Reload Icons & Cache" },
                { "Settings", "Settings..." },
                { "CheckUpdates", "Check for Updates..." },
                { "Exit", "Exit" },
                { "TabMain", "🌟 Main" },
                { "TabWallpaper", "🖼️ Wallpaper & Calendar" },
                { "TabDock", "⚡ Dock Bar" },
                { "TabAbout", "ℹ️ About" },
                { "DayEveningNight", "Time of Day Mode:" },
                { "ModeAuto", "Auto (By Clock & System)" },
                { "ModeDay", "☀️ Day (Light Clean)" },
                { "ModeEvening", "🌅 Evening (Warm Sand Gold)" },
                { "ModeNight", "🌙 Night (Midnight OLED)" },
                { "Language", "Interface Language:" },
                { "EnableDock", "Enable Hot-Corner Dock Bar" },
                { "EnableWallpaper", "Enable Dynamic 4K Wallpaper & Calendar" },
                { "AutoStart", "Run at Windows Startup" },
                { "AutoUpdate", "Check for updates automatically" },
                { "ColorTheme", "Color Style & Theme:" },
                { "WallThemesTitle", "🎨 Wallpaper Categories (Check desired or 'All Random'):" },
                { "CatAll", "🎲 All Random (Mix of all themes)" },
                { "Cat3D", "🔮 3D Renders, Textures & Abstract" },
                { "CatFlowers", "🌸 Flowers & Blossom" },
                { "CatOcean", "🌊 Ocean, Sea & Coastal" },
                { "CatSpace", "🚀 Space & Galaxies (Nebula)" },
                { "CatNature", "🌿 Nature & Landscapes" },
                { "CatAnimals", "🐾 Wildlife & Animals" },
                { "CatCars", "🏎️ Cars & Supercars" },
                { "CatTrucks", "🚛 Trucks & 4x4 Jeeps" },
                { "CatGirls", "👗 Fashion & Portraits" },
                { "CatCity", "🌆 Cities & Architecture (Skylines)" },
                { "CatCyberpunk", "⚡ Cyberpunk & Neon (Synthwave)" },
                { "CatMinimal", "🖤 Minimalism & Dark AMOLED" },
                { "CatAnime", "⛩️ Anime & Digital Art" },
                { "WallInterval", "⏱ Auto-Change Interval:" },
                { "ShowCalendar", "Overlay Anti-Aliased Live Calendar HUD" },
                { "CalendarFont", "Calendar Font Family:" },
                { "CalendarScale", "Calendar HUD Scale:" },
                { "BtnNextWall", "🖼️ Next Wallpaper Now" },
                { "BtnSaveWall", "💾 Save Active Wallpaper to Pictures" },
                { "DockPlacement", "Dock Bar Placement:" },
                { "PlacementTop", "Top (Slide Down)" },
                { "PlacementLeft", "Left (Slide Right)" },
                { "RootFolder", "Dock Root Folder:" },
                { "Browse", "Browse..." },
                { "OpenExplorer", "Open in Explorer" },
                { "SortingMode", "Item Sorting Mode:" },
                { "SortAlphaAZ", "Alphabetical (A to Z) [Default]" },
                { "SortAlphaZA", "Alphabetical (Z to A)" },
                { "SortFoldersFirst", "Folders First, Then Alphabetical" },
                { "SortFileType", "By File Type / Extension" },
                { "SortDateModified", "By Date Modified" },
                { "ShowLabels", "Show Item Labels:" },
                { "LabelsFoldersOnly", "Folders Only" },
                { "LabelsAll", "All Items" },
                { "LabelsNone", "Icons Only (No Text)" },
                { "AutoHideDelay", "Auto-Hide Delay (ms):" },
                { "HotCornerSize", "Hot-Corner Trigger Area (px):" },
                { "DockIconSize", "Dock Icon Size:" },
                { "FontAccordionBtn", "🔤 Font Selection & Accordion (12 Fonts)" },
                { "FolderFontFamily", "Folder Font Family:" },
                { "FolderFontSize", "Folder Font Size (pt):" },
                { "ItemFontFamily", "Files & Apps Font Family:" },
                { "ItemFontSize", "Files & Apps Font Size (pt):" },
                { "Save", "Save & Close" },
                { "Apply", "Apply" },
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
                { "TabMain", "🌟 Главные" },
                { "TabWallpaper", "🖼️ Обои и Календарь" },
                { "TabDock", "⚡ Панель Докер" },
                { "TabAbout", "ℹ️ О программе" },
                { "DayEveningNight", "Время суток (День / Вечер / Ночь):" },
                { "ModeAuto", "Авто (по часам и системе)" },
                { "ModeDay", "☀️ День (светлая тема)" },
                { "ModeEvening", "🌅 Вечер (теплый золотой песок)" },
                { "ModeNight", "🌙 Ночь (OLED Dark)" },
                { "Language", "Язык интерфейса:" },
                { "EnableDock", "Включить выезжающую панель Dock" },
                { "EnableWallpaper", "Включить динамические 4K обои и календарь" },
                { "AutoStart", "Запускать вместе с Windows" },
                { "AutoUpdate", "Автоматически проверять обновления" },
                { "ColorTheme", "Стиль оформления и тема:" },
                { "WallThemesTitle", "🎨 Тематика обоев (выберите категории или «Все подряд»):" },
                { "CatAll", "🎲 Все подряд (Случайный микс)" },
                { "Cat3D", "🔮 3D Рендеры, Фактуры и Абстракция" },
                { "CatFlowers", "🌸 Цветы и ботаника" },
                { "CatOcean", "🌊 Океан, море и побережье" },
                { "CatSpace", "🚀 Космос и Галактики (Nebula)" },
                { "CatNature", "🌿 Природа и пейзажи" },
                { "CatAnimals", "🐾 Животные и Дикая природа" },
                { "CatCars", "🏎️ Автомобили и Суперкары" },
                { "CatTrucks", "🚛 Грузовики и Джипы 4x4" },
                { "CatGirls", "👗 Девушки: Модели и Мода" },
                { "CatCity", "🌆 Города и Архитектура (Skylines)" },
                { "CatCyberpunk", "⚡ Киберпанк и Неон (Synthwave)" },
                { "CatMinimal", "🖤 Минимализм и Dark AMOLED" },
                { "CatAnime", "⛩️ Аниме и Цифровой Арт" },
                { "WallInterval", "⏱ Интервал смены обоев:" },
                { "ShowCalendar", "Отображать живой календарь на обоях" },
                { "CalendarFont", "Шрифт календаря:" },
                { "CalendarScale", "Масштаб календаря:" },
                { "BtnNextWall", "🖼️ Следующие обои сейчас" },
                { "BtnSaveWall", "💾 Сохранить текущие обои в Изображения" },
                { "DockPlacement", "Расположение панели Dock:" },
                { "PlacementTop", "Сверху (выезжает вниз)" },
                { "PlacementLeft", "Слева (выезжает вправо)" },
                { "RootFolder", "Корневая папка докера:" },
                { "Browse", "Обзор..." },
                { "OpenExplorer", "Открыть в Проводнике" },
                { "SortingMode", "Сортировка значков:" },
                { "SortAlphaAZ", "По алфавиту (А-Я / A-Z) [По умолчанию]" },
                { "SortAlphaZA", "По алфавиту обратная (Я-А / Z-A)" },
                { "SortFoldersFirst", "Сначала папки, затем по алфавиту" },
                { "SortFileType", "По типу и расширению файлов" },
                { "SortDateModified", "По дате изменения" },
                { "ShowLabels", "Подписи значков:" },
                { "LabelsFoldersOnly", "Только у папок" },
                { "LabelsAll", "У всех значков" },
                { "LabelsNone", "Без текста (только иконки)" },
                { "AutoHideDelay", "Задержка скрытия (мс):" },
                { "HotCornerSize", "Зона горячего угла (пиксели):" },
                { "DockIconSize", "Размер иконок докера:" },
                { "FontAccordionBtn", "🔤 Выбор шрифтов аккордеоном (12 вариантов)" },
                { "FolderFontFamily", "Шрифт названий папок:" },
                { "FolderFontSize", "Размер шрифта папок (pt):" },
                { "ItemFontFamily", "Шрифт названий файлов и программ:" },
                { "ItemFontSize", "Размер шрифта открываемых иконок (pt):" },
                { "Save", "Сохранить и закрыть" },
                { "Apply", "Применить" },
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
                { "TabMain", "🌟 Hlavní" },
                { "TabWallpaper", "🖼️ Tapeta a Kalendář" },
                { "TabDock", "⚡ Panel Dock" },
                { "TabAbout", "ℹ️ O aplikaci" },
                { "DayEveningNight", "Režim denní doby:" },
                { "ModeAuto", "Auto (podle času a systému)" },
                { "ModeDay", "☀️ Den (světlý motiv)" },
                { "ModeEvening", "🌅 Večer (teplý písek)" },
                { "ModeNight", "🌙 Noc (OLED tmavý)" },
                { "Language", "Jazyk aplikace:" },
                { "EnableDock", "Povolit panel Dock" },
                { "EnableWallpaper", "Povolit dynamické 4K tapety a kalendář" },
                { "AutoStart", "Spustit při startu Windows" },
                { "AutoUpdate", "Automaticky kontrolovat aktualizace" },
                { "ColorTheme", "Barevný styl a motiv:" },
                { "WallThemesTitle", "🎨 Motivy tapet (vyberte nebo 'Vše náhodně'):" },
                { "CatAll", "🎲 Vše náhodně (Mix)" },
                { "Cat3D", "🔮 3D Rendery a Abstrakce" },
                { "CatFlowers", "🌸 Květiny a botanika" },
                { "CatOcean", "🌊 Oceán a moře" },
                { "CatSpace", "🚀 Vesmír a Galaxie" },
                { "CatNature", "🌿 Příroda a krajiny" },
                { "CatAnimals", "🐾 Zvířata a divočina" },
                { "CatCars", "🏎️ Auta a Supersporty" },
                { "CatTrucks", "🚛 Nákladní auta a Jeepy" },
                { "CatGirls", "👗 Modelky a móda" },
                { "CatCity", "🌆 Města a architektura" },
                { "CatCyberpunk", "⚡ Cyberpunk a neon" },
                { "CatMinimal", "🖤 Minimalismus" },
                { "CatAnime", "⛩️ Anime a digitální umění" },
                { "WallInterval", "⏱ Interval výměny tapety:" },
                { "ShowCalendar", "Vykreslit živý kalendář na ploše" },
                { "CalendarFont", "Písmo kalendáře:" },
                { "CalendarScale", "Měřítko kalendáře:" },
                { "BtnNextWall", "🖼️ Další tapeta nyní" },
                { "BtnSaveWall", "💾 Uložit aktuální tapetu do Obrázků" },
                { "DockPlacement", "Umístění panelu Dock:" },
                { "PlacementTop", "Nahoře (vysunutí dolů)" },
                { "PlacementLeft", "Vlevo (vysunutí doprava)" },
                { "RootFolder", "Kořenová složka Docku:" },
                { "Browse", "Procházet..." },
                { "OpenExplorer", "Otevřít v Průzkumníku" },
                { "SortingMode", "Řazení položek:" },
                { "SortAlphaAZ", "Abecedně (A až Z) [Výchozí]" },
                { "SortAlphaZA", "Abecedně pozpátku (Z až A)" },
                { "SortFoldersFirst", "Nejprve složky, poté abecedně" },
                { "SortFileType", "Podle typu souboru" },
                { "SortDateModified", "Podle data změny" },
                { "ShowLabels", "Zobrazení popisků:" },
                { "LabelsFoldersOnly", "Pouze pro složky" },
                { "LabelsAll", "Pro všechny položky" },
                { "LabelsNone", "Pouze ikony bez textu" },
                { "AutoHideDelay", "Zpoždění skrytí (ms):" },
                { "HotCornerSize", "Aktivní zóna rohu (px):" },
                { "DockIconSize", "Velikost ikon Docku:" },
                { "FontAccordionBtn", "🔤 Výběr písem harmonikou (12 variant)" },
                { "FolderFontFamily", "Písmo pro složky:" },
                { "FolderFontSize", "Velikost písma pro složky (pt):" },
                { "ItemFontFamily", "Písmo pro soubory a aplikace:" },
                { "ItemFontSize", "Velikost písma pro ikony (pt):" },
                { "Save", "Uložit a zavřít" },
                { "Apply", "Použít" },
                { "Cancel", "Zrušit" },
                { "UpToDate", "Máte nejnovější verzi: " },
                { "UpdateAvailable", "K dispozici je nová verze: " },
                { "DownloadNow", "Stáhnout aktualizaci nyní?" }
            };
            Dictionaries["cs"] = cs;

            CreateFallback("de", en, "🌟 Allgemein", "🖼️ Hintergrund", "⚡ Dock-Leiste", "Einstellungen...", "Beenden");
            CreateFallback("fr", en, "🌟 Général", "🖼️ Fond d'écran", "⚡ Dock", "Paramètres...", "Quitter");
            CreateFallback("es", en, "🌟 General", "🖼️ Fondo de pantalla", "⚡ Dock", "Configuración...", "Salir");
            CreateFallback("it", en, "🌟 Generale", "🖼️ Sfondo", "⚡ Dock", "Impostazioni...", "Esci");
            CreateFallback("pt", en, "🌟 Geral", "🖼️ Papel de parede", "⚡ Dock", "Configurações...", "Sair");
            CreateFallback("pl", en, "🌟 Ogólne", "🖼️ Tapeta", "⚡ Dock", "Ustawienia...", "Wyjdź");
            CreateFallback("uk", ru, "🌟 Головні", "🖼️ Шпалери і Календар", "⚡ Панель Докер", "Налаштування...", "Вихід");
            CreateFallback("zh", en, "🌟 常规", "🖼️ 壁纸与日历", "⚡ 快捷坞", "设置...", "退出");
            CreateFallback("ja", en, "🌟 一般", "🖼️ 壁紙とカレンダー", "⚡ ドック", "設定...", "終了");
        }

        private static void CreateFallback(string lang, Dictionary<string, string> baseDict, string tMain, string tWall, string tDock, string tSet, string tExit) {
            var d = new Dictionary<string, string>(baseDict);
            d["TabMain"] = tMain;
            d["TabWallpaper"] = tWall;
            d["TabDock"] = tDock;
            d["Settings"] = tSet;
            d["Exit"] = tExit;
            Dictionaries[lang] = d;
        }

        public static void SetLanguage(string lang) {
            if (Dictionaries.ContainsKey(lang)) _currentLang = lang;
            else _currentLang = "en";

            if (LanguageChanged != null) {
                LanguageChanged();
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
    // CONFIGURATION
    // ==========================================
    public class Config {
        public string RootFolder = @"D:\MEGA\UTIL\┇";
        public bool EnableDock = true;
        public bool EnableWallpaper = true;
        public string DayEveningNightMode = "Evening";
        public string Language = "en";
        public string ThemeName = "WarmSand";
        public bool StartWithWindows = false;
        public bool CheckUpdatesOnStartup = true;

        public string DockPosition = "Top";
        public int DockIconSize = 32;
        public string DockFolderFontFamily = "Segoe UI";
        public float DockFolderFontSize = 9.0f;
        public string DockItemFontFamily = "Segoe UI";
        public float DockItemFontSize = 9.0f;
        public string SortingMode = "AlphaAZ";
        public string ShowLabels = "FoldersOnly";
        public int AutoHideDelayMs = 450;
        public int HotCornerWidth = 15;
        public int HotCornerHeight = 15;
        public int BarHeight = 48;

        public string WallpaperCategories = "all,nature,cyberpunk,space,3d,ocean,flowers,animals,cars,trucks,girls,city,minimalism,anime";
        public int WallpaperIntervalMinutes = 60;
        public bool ShowCalendar = true;
        public string CalendarFontFamily = "Segoe UI";
        public float CalendarScale = 1.0f;

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
                    cfg.DayEveningNightMode = GetString(json, "DayEveningNightMode", cfg.DayEveningNightMode);
                    cfg.Language = GetString(json, "Language", cfg.Language);
                    cfg.ThemeName = GetString(json, "ThemeName", cfg.ThemeName);
                    cfg.StartWithWindows = GetBool(json, "StartWithWindows", cfg.StartWithWindows);
                    cfg.CheckUpdatesOnStartup = GetBool(json, "CheckUpdatesOnStartup", cfg.CheckUpdatesOnStartup);

                    cfg.DockPosition = GetString(json, "DockPosition", cfg.DockPosition);
                    cfg.DockIconSize = GetInt(json, "DockIconSize", cfg.DockIconSize);
                    cfg.DockFolderFontFamily = GetString(json, "DockFolderFontFamily", cfg.DockFolderFontFamily);
                    cfg.DockFolderFontSize = GetFloat(json, "DockFolderFontSize", cfg.DockFolderFontSize);
                    cfg.DockItemFontFamily = GetString(json, "DockItemFontFamily", cfg.DockItemFontFamily);
                    cfg.DockItemFontSize = GetFloat(json, "DockItemFontSize", cfg.DockItemFontSize);
                    cfg.SortingMode = GetString(json, "SortingMode", cfg.SortingMode);
                    cfg.ShowLabels = GetString(json, "ShowLabels", cfg.ShowLabels);
                    cfg.AutoHideDelayMs = GetInt(json, "AutoHideDelayMs", cfg.AutoHideDelayMs);
                    cfg.HotCornerWidth = GetInt(json, "HotCornerWidth", cfg.HotCornerWidth);
                    cfg.HotCornerHeight = GetInt(json, "HotCornerHeight", cfg.HotCornerHeight);
                    cfg.BarHeight = GetInt(json, "BarHeight", cfg.BarHeight);

                    cfg.WallpaperCategories = GetString(json, "WallpaperCategories", cfg.WallpaperCategories);
                    cfg.WallpaperIntervalMinutes = GetInt(json, "WallpaperIntervalMinutes", cfg.WallpaperIntervalMinutes);
                    cfg.ShowCalendar = GetBool(json, "ShowCalendar", cfg.ShowCalendar);
                    cfg.CalendarFontFamily = GetString(json, "CalendarFontFamily", cfg.CalendarFontFamily);
                    cfg.CalendarScale = GetFloat(json, "CalendarScale", cfg.CalendarScale);
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
                sb.AppendLine("  \"DayEveningNightMode\": \"" + Escape(DayEveningNightMode) + "\",");
                sb.AppendLine("  \"Language\": \"" + Escape(Language) + "\",");
                sb.AppendLine("  \"ThemeName\": \"" + Escape(ThemeName) + "\",");
                sb.AppendLine("  \"StartWithWindows\": " + (StartWithWindows ? "true" : "false") + ",");
                sb.AppendLine("  \"CheckUpdatesOnStartup\": " + (CheckUpdatesOnStartup ? "true" : "false") + ",");

                sb.AppendLine("  \"DockPosition\": \"" + Escape(DockPosition) + "\",");
                sb.AppendLine("  \"DockIconSize\": " + DockIconSize + ",");
                sb.AppendLine("  \"DockFolderFontFamily\": \"" + Escape(DockFolderFontFamily) + "\",");
                sb.AppendLine("  \"DockFolderFontSize\": " + DockFolderFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"DockItemFontFamily\": \"" + Escape(DockItemFontFamily) + "\",");
                sb.AppendLine("  \"DockItemFontSize\": " + DockItemFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"SortingMode\": \"" + Escape(SortingMode) + "\",");
                sb.AppendLine("  \"ShowLabels\": \"" + Escape(ShowLabels) + "\",");
                sb.AppendLine("  \"AutoHideDelayMs\": " + AutoHideDelayMs + ",");
                sb.AppendLine("  \"HotCornerWidth\": " + HotCornerWidth + ",");
                sb.AppendLine("  \"HotCornerHeight\": " + HotCornerHeight + ",");
                sb.AppendLine("  \"BarHeight\": " + BarHeight + ",");

                sb.AppendLine("  \"WallpaperCategories\": \"" + Escape(WallpaperCategories) + "\",");
                sb.AppendLine("  \"WallpaperIntervalMinutes\": " + WallpaperIntervalMinutes + ",");
                sb.AppendLine("  \"ShowCalendar\": " + (ShowCalendar ? "true" : "false") + ",");
                sb.AppendLine("  \"CalendarFontFamily\": \"" + Escape(CalendarFontFamily) + "\",");
                sb.AppendLine("  \"CalendarScale\": " + CalendarScale.ToString(CultureInfo.InvariantCulture));
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
    // CURATED 12 FONTS LIST
    // ==========================================
    public static class FontDirectory {
        public static readonly string[] CuratedFonts = new string[] {
            "Segoe UI",
            "Bahnschrift",
            "Consolas",
            "Trebuchet MS",
            "Georgia",
            "Century Gothic",
            "Calibri",
            "Corbel",
            "Palatino Linotype",
            "Constantia",
            "Verdana",
            "Arial"
        };
    }

    // ==========================================
    // SHELL & ICON UTILITIES
    // ==========================================
    public static class ShellHelper {
        private static readonly Dictionary<string, Image> _iconCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);

        public static Image GetIconImage(string path, int targetSize) {
            bool large = targetSize >= 32;
            string key = path + "_" + targetSize;
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
                        Bitmap raw = ico.ToBitmap();
                        if (raw.Width != targetSize || raw.Height != targetSize) {
                            Bitmap scaled = new Bitmap(targetSize, targetSize);
                            using (Graphics g = Graphics.FromImage(scaled)) {
                                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                                g.SmoothingMode = SmoothingMode.HighQuality;
                                g.DrawImage(raw, 0, 0, targetSize, targetSize);
                            }
                            img = scaled;
                        } else {
                            img = raw;
                        }
                    }
                    NativeMethods.DestroyIcon(shinfo.hIcon);
                }
            } catch { }

            if (img == null) {
                Bitmap bmp = new Bitmap(targetSize, targetSize);
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

            return item;
        }

        public Image GetIcon(int size) {
            return ShellHelper.GetIconImage(FullPath, size);
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
            string[] enabled = (_config.WallpaperCategories ?? "all").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            List<string> queries = new List<string>();

            foreach (string cat in enabled) {
                string c = cat.Trim().ToLowerInvariant();
                if (c == "3d") queries.Add("3d abstract render");
                else if (c == "flowers") queries.Add("flowers blossom");
                else if (c == "ocean") queries.Add("ocean sea coast");
                else if (c == "space") queries.Add("space galaxy nebula");
                else if (c == "nature") queries.Add("nature landscape forest mountains");
                else if (c == "animals") queries.Add("wildlife animals");
                else if (c == "cars") queries.Add("supercar luxury car");
                else if (c == "trucks") queries.Add("truck offroad 4x4");
                else if (c == "girls") queries.Add("fashion model portrait");
                else if (c == "city") queries.Add("cityscape architecture night");
                else if (c == "cyberpunk") queries.Add("cyberpunk synthwave neon");
                else if (c == "minimalism") queries.Add("minimalism dark clean");
                else if (c == "anime") queries.Add("anime scenery digital art");
                else if (c == "all") {
                    queries.Add("nature landscape");
                    queries.Add("space nebula");
                    queries.Add("cyberpunk neon");
                    queries.Add("3d abstract");
                    queries.Add("ocean waves");
                }
            }

            if (queries.Count == 0) queries.Add("nature landscape");
            string query = queries[new Random().Next(queries.Count)];

            string seed = Guid.NewGuid().ToString("N").Substring(0, 6);
            string categoriesCode = query.Contains("portrait") || query.Contains("model") ? "001" : (query.Contains("anime") ? "010" : "100");
            string apiUrl = "https://wallhaven.cc/api/v1/search?q=" + Uri.EscapeDataString(query) + "&categories=" + categoriesCode + "&purity=100&atleast=1920x1080&sorting=random&seed=" + seed;

            string targetJpg = Path.Combine(Config.CacheDir, "wallpaper_" + DateTime.Now.Ticks + ".jpg");

            using (WebClient wc = new WebClient()) {
                wc.Headers.Add("User-Agent", "GIN-Dock-Wallpaper/v033 (Windows; WinAPI)");
                string json = wc.DownloadString(apiUrl);

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

                g.DrawImage(original, 0, 0, original.Width, original.Height);

                DateTime now = DateTime.Now;
                ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);

                float scale = Math.Max(0.6f, Math.Min(2.0f, _config.CalendarScale));
                int cardW = (int)(Math.Max(260, (int)(original.Width * 0.16f)) * scale);
                int cardH = (int)(cardW * 0.82f);
                int margin = 30;
                int cardX = original.Width - cardW - margin;
                int cardY = margin + 40;

                Rectangle cardRect = new Rectangle(cardX, cardY, cardW, cardH);
                using (GraphicsPath path = GetRoundedRect(cardRect, 14))
                using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(170, theme.Background.R, theme.Background.G, theme.Background.B)))
                using (Pen borderPen = new Pen(Color.FromArgb(200, theme.Border.R, theme.Border.G, theme.Border.B), 1.5f)) {
                    g.FillPath(bgBrush, path);
                    g.DrawPath(borderPen, path);
                }

                string fontName = _config.CalendarFontFamily ?? "Segoe UI";
                string monthTitle = now.ToString("MMMM yyyy", CultureInfo.CurrentCulture).ToUpperInvariant();
                float titleFontSize = Math.Max(10f, cardW * 0.052f);

                using (Font titleFont = new Font(fontName, titleFontSize, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(theme.TextPrimary))
                using (SolidBrush accentBrush = new SolidBrush(theme.Accent)) {
                    g.DrawString(monthTitle, titleFont, accentBrush, cardX + 16, cardY + 12);

                    string[] days = new string[] { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" };
                    float colW = (cardW - 32) / 7.0f;
                    float headerY = cardY + 16 + titleFontSize * 1.6f;
                    float dayFontSize = Math.Max(8f, cardW * 0.038f);

                    using (Font dayFont = new Font(fontName, dayFontSize, FontStyle.Regular))
                    using (Font boldDayFont = new Font(fontName, dayFontSize, FontStyle.Bold))
                    using (SolidBrush subBrush = new SolidBrush(theme.TextSecondary)) {
                        for (int i = 0; i < 7; i++) {
                            g.DrawString(days[i], dayFont, (i >= 5 ? accentBrush : subBrush), cardX + 16 + i * colW, headerY);
                        }

                        DateTime firstDay = new DateTime(now.Year, now.Month, 1);
                        int startCol = ((int)firstDay.DayOfWeek + 6) % 7;
                        int daysInMonth = DateTime.DaysInMonth(now.Year, now.Month);

                        float rowH = (cardH - (headerY - cardY) - 16) / 6.0f;
                        int curDay = 1;

                        for (int row = 0; row < 6 && curDay <= daysInMonth; row++) {
                            for (int col = 0; col < 7 && curDay <= daysInMonth; col++) {
                                if (row == 0 && col < startCol) continue;

                                float dx = cardX + 16 + col * colW;
                                float dy = headerY + 18 + row * rowH;

                                if (curDay == now.Day) {
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
    // DOCK BAR FORM
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

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            this.BackColor = theme.Background;

            _toolTip = new ToolTip();
            _toolTip.BackColor = theme.CardBackground;
            _toolTip.ForeColor = theme.TextPrimary;

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
            _toolTip.SetToolTip(brandBtn, "GIN Dock Wallpaper v033 | Click for Menu");

            bool isTop = (_config.DockPosition == "Top");
            int barSize = Math.Max(40, _config.DockIconSize + 16);
            _config.BarHeight = barSize;

            if (isTop) {
                this.Height = barSize;
                brandBtn.Size = new Size(68, barSize - 10);
                brandBtn.Location = new Point(5, 5);
            } else {
                this.Width = barSize;
                brandBtn.Size = new Size(barSize - 10, 36);
                brandBtn.Location = new Point(5, 5);
            }
            this.Controls.Add(brandBtn);

            _itemsPanel = new Panel();
            _itemsPanel.BackColor = Color.Transparent;
            if (isTop) {
                _itemsPanel.Location = new Point(78, 0);
                _itemsPanel.Height = barSize;
                _itemsPanel.Width = Screen.PrimaryScreen.Bounds.Width - 90;
            } else {
                _itemsPanel.Location = new Point(0, 46);
                _itemsPanel.Width = barSize;
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
                list.Sort((a, b) => string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase));
            }
        }

        private void BuildDockUI() {
            _itemsPanel.Controls.Clear();
            _dockControls.Clear();

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            this.BackColor = theme.Background;

            bool isTop = (_config.DockPosition == "Top");
            int cursor = 0;
            int iconSz = _config.DockIconSize;
            int itemSpan = Math.Max(36, iconSz + 8);
            _config.BarHeight = itemSpan + 10;

            Font folderFont = new Font(_config.DockFolderFontFamily ?? "Segoe UI", _config.DockFolderFontSize, FontStyle.Regular);
            Font itemFont = new Font(_config.DockItemFontFamily ?? "Segoe UI", _config.DockItemFontSize, FontStyle.Regular);

            foreach (DockItem folder in _folders) {
                Button btn = new Button();
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = theme.Border;
                btn.BackColor = theme.CardBackground;
                btn.ForeColor = theme.TextPrimary;
                btn.Font = folderFont;
                btn.Cursor = Cursors.Hand;
                btn.Image = folder.GetIcon(Math.Min(24, iconSz));
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
                            btn.Width = (int)size.Width + iconSz + 24;
                        }
                    } else {
                        btn.Text = "▾";
                        btn.Width = iconSz + 16;
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

            foreach (DockItem item in _shortcuts) {
                Button btn = new Button();
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderSize = 0;
                btn.BackColor = Color.Transparent;
                btn.Cursor = Cursors.Hand;
                btn.Image = item.GetIcon(iconSz);
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
                            btn.Width = (int)size.Width + iconSz + 24;
                        }
                    } else {
                        btn.Width = iconSz + 12;
                    }
                } else {
                    btn.Width = itemSpan;
                    btn.Height = showLabel ? (iconSz + 16) : (iconSz + 10);
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
            int barSize = _config.BarHeight;

            if (isTop) {
                int desiredWidth = 85 + _totalItemsLength + 20;
                if (desiredWidth > screen.Bounds.Width) desiredWidth = screen.Bounds.Width;
                if (desiredWidth < 400) desiredWidth = 400;

                this.Width = desiredWidth;
                this.Height = barSize;
                this.Location = new Point(0, 0);
                _itemsPanel.Width = this.Width - 90;
                _itemsPanel.Height = this.Height;
            } else {
                int desiredHeight = 55 + _totalItemsLength + 20;
                if (desiredHeight > screen.Bounds.Height) desiredHeight = screen.Bounds.Height;
                if (desiredHeight < 400) desiredHeight = 400;

                this.Width = barSize;
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

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
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
                    subMenuItem.Image = ShellHelper.GetIconImage(dir, 16);
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
                    fileItem.Image = ShellHelper.GetIconImage(file, 16);

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
                bool trigger = (p.X <= _config.HotCornerWidth && p.Y <= _config.HotCornerHeight);
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
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            ContextMenuStrip menu = new ContextMenuStrip();
            menu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem header = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v033");
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
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
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
    // SETTINGS FORM (RICH TABBED + ACCORDION)
    // ==========================================
    public class SettingsForm : Form {
        private Config _config;
        private Action _onConfigChanged;
        private WallpaperEngine _wallpaperEngine;

        private TabControl _tabs;
        private TabPage _tabMain;
        private TabPage _tabWall;
        private TabPage _tabDock;
        private TabPage _tabAbout;

        private Label _lblDayEveningNight;
        private ComboBox _cmbDayEveningNight;
        private Label _lblLang;
        private ComboBox _cmbLang;
        private CheckBox _chkEnableDock;
        private CheckBox _chkEnableWall;
        private CheckBox _chkAutoStart;
        private CheckBox _chkAutoUpdate;
        private Label _lblTheme;
        private ComboBox _cmbTheme;

        private Label _lblWallThemesTitle;
        private Dictionary<string, CheckBox> _catCheckBoxes = new Dictionary<string, CheckBox>();
        private Label _lblWallInt;
        private ComboBox _cmbWallInt;
        private CheckBox _chkShowCal;
        private Label _lblCalFont;
        private ComboBox _cmbCalFont;
        private Label _lblCalScale;
        private TrackBar _tbCalScale;
        private Button _btnNextWall;
        private Button _btnSaveWall;

        private Label _lblDockPlacement;
        private ComboBox _cmbDockPlacement;
        private Label _lblRoot;
        private TextBox _txtRoot;
        private Button _btnBrowse;
        private Label _lblSort;
        private ComboBox _cmbSort;
        private Label _lblShowLabels;
        private ComboBox _cmbShowLabels;
        private Label _lblDelay;
        private TrackBar _tbDelay;
        private Label _lblIconSize;
        private ComboBox _cmbIconSize;

        private Button _btnFontAccordion;
        private Panel _panelFontAccordion;
        private bool _isAccordionExpanded = false;
        private Label _lblFolderFont;
        private ComboBox _cmbFolderFont;
        private Label _lblFolderFontSize;
        private TrackBar _tbFolderFontSize;
        private Label _lblItemFont;
        private ComboBox _cmbItemFont;
        private Label _lblItemFontSize;
        private TrackBar _tbItemFontSize;

        private Button _btnSave;
        private Button _btnApply;
        private Button _btnCancel;

        private Label _lblAboutTitle;
        private Label _lblAboutDesc;
        private Button _btnCheckUpdate;
        private Button _btnOpenGitHub;

        public SettingsForm(Config config, Action onConfigChanged, WallpaperEngine wallpaperEngine) {
            _config = config;
            _onConfigChanged = onConfigChanged;
            _wallpaperEngine = wallpaperEngine;
            InitializeComponent();
            ApplyLocalization();
        }

        private void InitializeComponent() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);

            this.Text = "⚡ " + I18n.T("AppTitle") + " — " + I18n.T("Settings");
            this.Size = new Size(740, 580);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = theme.Background;
            this.ForeColor = theme.TextPrimary;
            this.Font = new Font("Segoe UI", 9f);

            _tabs = new TabControl();
            _tabs.Location = new Point(12, 12);
            _tabs.Size = new Size(700, 480);

            // TAB 1: MAIN
            _tabMain = new TabPage();
            _tabMain.BackColor = theme.CardBackground;

            _lblDayEveningNight = new Label { Location = new Point(25, 25), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbDayEveningNight = new ComboBox { Location = new Point(280, 22), Width = 280, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbDayEveningNight.Items.AddRange(new string[] { I18n.T("ModeAuto"), I18n.T("ModeDay"), I18n.T("ModeEvening"), I18n.T("ModeNight") });
            SelectDayNightIndex();

            _lblLang = new Label { Location = new Point(25, 65), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbLang = new ComboBox { Location = new Point(280, 62), Width = 280, DropDownStyle = ComboBoxStyle.DropDownList };
            PopulateLanguageList();
            SelectLanguageIndex(_config.Language);
            _cmbLang.SelectedIndexChanged += (s, e) => {
                string newLang = GetSelectedLanguageCode(_cmbLang.SelectedIndex);
                if (newLang != _config.Language) {
                    _config.Language = newLang;
                    I18n.SetLanguage(newLang);
                    ApplyLocalization();
                    if (_onConfigChanged != null) _onConfigChanged();
                }
            };

            _chkEnableDock = new CheckBox { Checked = _config.EnableDock, Location = new Point(25, 115), AutoSize = true, ForeColor = theme.TextPrimary };
            _chkEnableWall = new CheckBox { Checked = _config.EnableWallpaper, Location = new Point(25, 150), AutoSize = true, ForeColor = theme.TextPrimary };

            _lblTheme = new Label { Location = new Point(25, 195), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbTheme = new ComboBox { Location = new Point(280, 192), Width = 340, DropDownStyle = ComboBoxStyle.DropDownList };
            foreach (var th in ThemeManager.Themes.Values) {
                _cmbTheme.Items.Add(th.Name);
            }
            SelectThemeIndex(_config.ThemeName);

            _chkAutoStart = new CheckBox { Checked = _config.StartWithWindows, Location = new Point(25, 245), AutoSize = true, ForeColor = theme.TextPrimary };
            _chkAutoUpdate = new CheckBox { Checked = _config.CheckUpdatesOnStartup, Location = new Point(25, 280), AutoSize = true, ForeColor = theme.TextPrimary };

            _tabMain.Controls.AddRange(new Control[] {
                _lblDayEveningNight, _cmbDayEveningNight,
                _lblLang, _cmbLang,
                _chkEnableDock, _chkEnableWall,
                _lblTheme, _cmbTheme,
                _chkAutoStart, _chkAutoUpdate
            });
            _tabs.TabPages.Add(_tabMain);

            // TAB 2: WALLPAPER
            _tabWall = new TabPage();
            _tabWall.BackColor = theme.CardBackground;
            _tabWall.AutoScroll = true;

            _lblWallThemesTitle = new Label { Location = new Point(20, 15), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold), ForeColor = theme.Accent };
            _tabWall.Controls.Add(_lblWallThemesTitle);

            string[] catKeys = new string[] {
                "all", "3d", "flowers", "ocean", "space", "nature", "animals",
                "cars", "trucks", "girls", "city", "cyberpunk", "minimalism", "anime"
            };

            string activeCats = (_config.WallpaperCategories ?? "all").ToLowerInvariant();
            for (int i = 0; i < catKeys.Length; i++) {
                string key = catKeys[i];
                int col = i % 2;
                int row = i / 2;
                int x = 25 + col * 330;
                int y = 45 + row * 26;

                CheckBox cb = new CheckBox {
                    Tag = key,
                    Location = new Point(x, y),
                    Width = 320,
                    Checked = activeCats.Contains(key),
                    ForeColor = theme.TextPrimary
                };
                _catCheckBoxes[key] = cb;
                _tabWall.Controls.Add(cb);
            }

            int wallOffY = 235;

            _lblWallInt = new Label { Location = new Point(20, wallOffY), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbWallInt = new ComboBox { Location = new Point(260, wallOffY - 3), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbWallInt.Items.AddRange(new string[] { "Every 15 minutes", "Every 30 minutes", "Every 1 hour", "Every 3 hours", "Every 6 hours", "Every 12 hours", "Daily (24h)" });
            SelectIntervalIndex(_config.WallpaperIntervalMinutes);
            _tabWall.Controls.AddRange(new Control[] { _lblWallInt, _cmbWallInt });

            _chkShowCal = new CheckBox { Checked = _config.ShowCalendar, Location = new Point(20, wallOffY + 35), AutoSize = true, ForeColor = theme.TextPrimary };
            _tabWall.Controls.Add(_chkShowCal);

            _lblCalFont = new Label { Location = new Point(20, wallOffY + 70), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbCalFont = new ComboBox { Location = new Point(260, wallOffY + 67), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbCalFont.Items.AddRange(FontDirectory.CuratedFonts);
            SelectFontInCombo(_cmbCalFont, _config.CalendarFontFamily);
            _tabWall.Controls.AddRange(new Control[] { _lblCalFont, _cmbCalFont });

            _lblCalScale = new Label { Location = new Point(20, wallOffY + 105), AutoSize = true, ForeColor = theme.TextSecondary };
            _tbCalScale = new TrackBar { Location = new Point(260, wallOffY + 100), Width = 220, Minimum = 7, Maximum = 18, Value = (int)(_config.CalendarScale * 10) };
            _tbCalScale.ValueChanged += (s, e) => _lblCalScale.Text = I18n.T("CalendarScale") + " " + (_tbCalScale.Value / 10.0f).ToString("0.0") + "x";
            _tabWall.Controls.AddRange(new Control[] { _lblCalScale, _tbCalScale });

            _btnNextWall = new Button { Location = new Point(20, wallOffY + 145), Width = 230, Height = 32 };
            _btnNextWall.Click += (s, e) => {
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                    MessageBox.Show("Downloading fresh 4K wallpaper...", "GIN Dock Wallpaper", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            };

            _btnSaveWall = new Button { Location = new Point(270, wallOffY + 145), Width = 280, Height = 32 };
            _btnSaveWall.Click += (s, e) => {
                if (_wallpaperEngine != null) _wallpaperEngine.SaveActiveWallpaperToPictures();
            };
            _tabWall.Controls.AddRange(new Control[] { _btnNextWall, _btnSaveWall });

            _tabs.TabPages.Add(_tabWall);

            // TAB 3: DOCK
            _tabDock = new TabPage();
            _tabDock.BackColor = theme.CardBackground;
            _tabDock.AutoScroll = true;

            _lblDockPlacement = new Label { Location = new Point(20, 20), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbDockPlacement = new ComboBox { Location = new Point(260, 17), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbDockPlacement.Items.Add(I18n.T("PlacementTop"));
            _cmbDockPlacement.Items.Add(I18n.T("PlacementLeft"));
            _cmbDockPlacement.SelectedIndex = (_config.DockPosition == "Left" ? 1 : 0);

            _lblRoot = new Label { Location = new Point(20, 55), AutoSize = true, ForeColor = theme.TextSecondary };
            _txtRoot = new TextBox { Text = _config.RootFolder, Location = new Point(20, 75), Width = 480 };
            _btnBrowse = new Button { Location = new Point(510, 73), Width = 110, Height = 26 };
            _btnBrowse.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog()) {
                    fbd.SelectedPath = _txtRoot.Text;
                    if (fbd.ShowDialog() == DialogResult.OK) _txtRoot.Text = fbd.SelectedPath;
                }
            };

            _lblSort = new Label { Location = new Point(20, 115), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbSort = new ComboBox { Location = new Point(260, 112), Width = 320, DropDownStyle = ComboBoxStyle.DropDownList };
            PopulateSortList();
            SelectSortIndex(_config.SortingMode);

            _lblShowLabels = new Label { Location = new Point(20, 155), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbShowLabels = new ComboBox { Location = new Point(260, 152), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbShowLabels.Items.AddRange(new string[] { I18n.T("LabelsFoldersOnly"), I18n.T("LabelsAll"), I18n.T("LabelsNone") });
            _cmbShowLabels.SelectedIndex = (_config.ShowLabels == "All" ? 1 : (_config.ShowLabels == "None" ? 2 : 0));

            _lblIconSize = new Label { Location = new Point(20, 195), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbIconSize = new ComboBox { Location = new Point(260, 192), Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbIconSize.Items.AddRange(new object[] { "16 px (Small)", "24 px (Compact)", "32 px (Standard)", "48 px (Large)", "64 px (Extra Large)" });
            SelectIconSizeIndex(_config.DockIconSize);

            _lblDelay = new Label { Location = new Point(20, 235), AutoSize = true, ForeColor = theme.TextSecondary };
            _tbDelay = new TrackBar { Location = new Point(260, 230), Width = 240, Minimum = 200, Maximum = 1500, TickFrequency = 100, Value = Math.Max(200, Math.Min(1500, _config.AutoHideDelayMs)) };
            _tbDelay.ValueChanged += (s, e) => _lblDelay.Text = I18n.T("AutoHideDelay") + " (" + _tbDelay.Value + " ms)";

            // ACCORDION FOR FONTS
            _btnFontAccordion = new Button {
                Text = "▼ " + I18n.T("FontAccordionBtn"),
                Location = new Point(20, 280),
                Width = 600,
                Height = 30,
                FlatStyle = FlatStyle.Flat,
                ForeColor = theme.Accent,
                BackColor = theme.BrandBadge,
                Cursor = Cursors.Hand
            };
            _btnFontAccordion.Click += (s, e) => ToggleFontAccordion();

            _panelFontAccordion = new Panel {
                Location = new Point(20, 315),
                Width = 600,
                Height = 120,
                BorderStyle = BorderStyle.FixedSingle,
                BackColor = theme.Background,
                Visible = false
            };

            _lblFolderFont = new Label { Location = new Point(15, 12), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbFolderFont = new ComboBox { Location = new Point(240, 10), Width = 180, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbFolderFont.Items.AddRange(FontDirectory.CuratedFonts);
            SelectFontInCombo(_cmbFolderFont, _config.DockFolderFontFamily);

            _lblFolderFontSize = new Label { Location = new Point(440, 12), AutoSize = true, ForeColor = theme.TextSecondary };
            _tbFolderFontSize = new TrackBar { Location = new Point(490, 8), Width = 100, Minimum = 7, Maximum = 20, Value = (int)Math.Max(7, Math.Min(20, _config.DockFolderFontSize)) };
            _tbFolderFontSize.ValueChanged += (s, e) => _lblFolderFontSize.Text = _tbFolderFontSize.Value + " pt";

            _lblItemFont = new Label { Location = new Point(15, 62), AutoSize = true, ForeColor = theme.TextSecondary };
            _cmbItemFont = new ComboBox { Location = new Point(240, 60), Width = 180, DropDownStyle = ComboBoxStyle.DropDownList };
            _cmbItemFont.Items.AddRange(FontDirectory.CuratedFonts);
            SelectFontInCombo(_cmbItemFont, _config.DockItemFontFamily);

            _lblItemFontSize = new Label { Location = new Point(440, 62), AutoSize = true, ForeColor = theme.TextSecondary };
            _tbItemFontSize = new TrackBar { Location = new Point(490, 58), Width = 100, Minimum = 7, Maximum = 20, Value = (int)Math.Max(7, Math.Min(20, _config.DockItemFontSize)) };
            _tbItemFontSize.ValueChanged += (s, e) => _lblItemFontSize.Text = _tbItemFontSize.Value + " pt";

            _panelFontAccordion.Controls.AddRange(new Control[] {
                _lblFolderFont, _cmbFolderFont, _lblFolderFontSize, _tbFolderFontSize,
                _lblItemFont, _cmbItemFont, _lblItemFontSize, _tbItemFontSize
            });

            _tabDock.Controls.AddRange(new Control[] {
                _lblDockPlacement, _cmbDockPlacement,
                _lblRoot, _txtRoot, _btnBrowse,
                _lblSort, _cmbSort,
                _lblShowLabels, _cmbShowLabels,
                _lblIconSize, _cmbIconSize,
                _lblDelay, _tbDelay,
                _btnFontAccordion, _panelFontAccordion
            });
            _tabs.TabPages.Add(_tabDock);

            // TAB 4: ABOUT
            _tabAbout = new TabPage();
            _tabAbout.BackColor = theme.CardBackground;

            _lblAboutTitle = new Label { Text = "⚡ GIN Dock Wallpaper v033", Font = new Font("Segoe UI", 12f, FontStyle.Bold), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.Accent };
            _lblAboutDesc = new Label {
                Text = "Author: Vladimir Bulantsev (@GinCz) & Antigravity\nOpen Source / MIT License\nUniversal 32/64-bit Windows Architecture\nPlatform: Native WinAPI & GDI+ (Idle: ~2-4 MB RAM)\n\nDual-Feature: Hot-Corner Dock Bar + 4K Dynamic Wallpaper & Live Calendar",
                Location = new Point(25, 65),
                AutoSize = true,
                ForeColor = theme.TextSecondary
            };

            _btnCheckUpdate = new Button { Location = new Point(25, 175), Width = 220, Height = 32 };
            _btnCheckUpdate.Click += (s, e) => CheckUpdateRoutine(true);

            _btnOpenGitHub = new Button { Text = "🌐 GitHub Open Source Repository", Location = new Point(260, 175), Width = 280, Height = 32 };
            _btnOpenGitHub.Click += (s, e) => {
                try { Process.Start("https://github.com/GinCz/Windows_scripts/tree/main/GIN-Dock-Wallpaper"); } catch { }
            };

            _tabAbout.Controls.AddRange(new Control[] { _lblAboutTitle, _lblAboutDesc, _btnCheckUpdate, _btnOpenGitHub });
            _tabs.TabPages.Add(_tabAbout);

            this.Controls.Add(_tabs);

            // BOTTOM BUTTONS: Save & Close, Apply, Cancel
            _btnSave = new Button { Location = new Point(350, 500), Width = 130, Height = 34, DialogResult = DialogResult.OK };
            _btnSave.Click += (s, e) => {
                CommitSettings();
                this.Close();
            };

            _btnApply = new Button { Location = new Point(490, 500), Width = 110, Height = 34 };
            _btnApply.Click += (s, e) => {
                CommitSettings();
            };

            _btnCancel = new Button { Location = new Point(610, 500), Width = 100, Height = 34, DialogResult = DialogResult.Cancel };
            _btnCancel.Click += (s, e) => this.Close();

            this.Controls.AddRange(new Control[] { _btnSave, _btnApply, _btnCancel });
        }

        private void ToggleFontAccordion() {
            _isAccordionExpanded = !_isAccordionExpanded;
            _panelFontAccordion.Visible = _isAccordionExpanded;
            _btnFontAccordion.Text = (_isAccordionExpanded ? "▲ " : "▼ ") + I18n.T("FontAccordionBtn");

            if (_isAccordionExpanded) {
                this.Height = 670;
                _tabs.Height = 570;
                _btnSave.Location = new Point(_btnSave.Location.X, 590);
                _btnApply.Location = new Point(_btnApply.Location.X, 590);
                _btnCancel.Location = new Point(_btnCancel.Location.X, 590);
            } else {
                this.Height = 580;
                _tabs.Height = 480;
                _btnSave.Location = new Point(_btnSave.Location.X, 500);
                _btnApply.Location = new Point(_btnApply.Location.X, 500);
                _btnCancel.Location = new Point(_btnCancel.Location.X, 500);
            }
        }

        private void ApplyLocalization() {
            this.Text = "⚡ " + I18n.T("AppTitle") + " — " + I18n.T("Settings");
            _tabMain.Text = I18n.T("TabMain");
            _tabWall.Text = I18n.T("TabWallpaper");
            _tabDock.Text = I18n.T("TabDock");
            _tabAbout.Text = I18n.T("TabAbout");

            _lblDayEveningNight.Text = I18n.T("DayEveningNight");
            _lblLang.Text = I18n.T("Language");
            _chkEnableDock.Text = I18n.T("EnableDock");
            _chkEnableWall.Text = I18n.T("EnableWallpaper");
            _lblTheme.Text = I18n.T("ColorTheme");
            _chkAutoStart.Text = I18n.T("AutoStart");
            _chkAutoUpdate.Text = I18n.T("AutoUpdate");

            _lblWallThemesTitle.Text = I18n.T("WallThemesTitle");
            if (_catCheckBoxes.ContainsKey("all")) _catCheckBoxes["all"].Text = I18n.T("CatAll");
            if (_catCheckBoxes.ContainsKey("3d")) _catCheckBoxes["3d"].Text = I18n.T("Cat3D");
            if (_catCheckBoxes.ContainsKey("flowers")) _catCheckBoxes["flowers"].Text = I18n.T("CatFlowers");
            if (_catCheckBoxes.ContainsKey("ocean")) _catCheckBoxes["ocean"].Text = I18n.T("CatOcean");
            if (_catCheckBoxes.ContainsKey("space")) _catCheckBoxes["space"].Text = I18n.T("CatSpace");
            if (_catCheckBoxes.ContainsKey("nature")) _catCheckBoxes["nature"].Text = I18n.T("CatNature");
            if (_catCheckBoxes.ContainsKey("animals")) _catCheckBoxes["animals"].Text = I18n.T("CatAnimals");
            if (_catCheckBoxes.ContainsKey("cars")) _catCheckBoxes["cars"].Text = I18n.T("CatCars");
            if (_catCheckBoxes.ContainsKey("trucks")) _catCheckBoxes["trucks"].Text = I18n.T("CatTrucks");
            if (_catCheckBoxes.ContainsKey("girls")) _catCheckBoxes["girls"].Text = I18n.T("CatGirls");
            if (_catCheckBoxes.ContainsKey("city")) _catCheckBoxes["city"].Text = I18n.T("CatCity");
            if (_catCheckBoxes.ContainsKey("cyberpunk")) _catCheckBoxes["cyberpunk"].Text = I18n.T("CatCyberpunk");
            if (_catCheckBoxes.ContainsKey("minimalism")) _catCheckBoxes["minimalism"].Text = I18n.T("CatMinimal");
            if (_catCheckBoxes.ContainsKey("anime")) _catCheckBoxes["anime"].Text = I18n.T("CatAnime");

            _lblWallInt.Text = I18n.T("WallInterval");
            _chkShowCal.Text = I18n.T("ShowCalendar");
            _lblCalFont.Text = I18n.T("CalendarFont");
            _lblCalScale.Text = I18n.T("CalendarScale") + " " + (_tbCalScale.Value / 10.0f).ToString("0.0") + "x";
            _btnNextWall.Text = I18n.T("BtnNextWall");
            _btnSaveWall.Text = I18n.T("BtnSaveWall");

            _lblDockPlacement.Text = I18n.T("DockPlacement");
            _cmbDockPlacement.Items[0] = I18n.T("PlacementTop");
            _cmbDockPlacement.Items[1] = I18n.T("PlacementLeft");
            _lblRoot.Text = I18n.T("RootFolder");
            _btnBrowse.Text = I18n.T("Browse");
            _lblSort.Text = I18n.T("SortingMode");
            PopulateSortList();
            SelectSortIndex(_config.SortingMode);

            _lblShowLabels.Text = I18n.T("ShowLabels");
            _cmbShowLabels.Items[0] = I18n.T("LabelsFoldersOnly");
            _cmbShowLabels.Items[1] = I18n.T("LabelsAll");
            _cmbShowLabels.Items[2] = I18n.T("LabelsNone");

            _lblIconSize.Text = I18n.T("DockIconSize");
            _lblDelay.Text = I18n.T("AutoHideDelay") + " (" + _tbDelay.Value + " ms)";

            _btnFontAccordion.Text = (_isAccordionExpanded ? "▲ " : "▼ ") + I18n.T("FontAccordionBtn");
            _lblFolderFont.Text = I18n.T("FolderFontFamily");
            _lblFolderFontSize.Text = _tbFolderFontSize.Value + " pt";
            _lblItemFont.Text = I18n.T("ItemFontFamily");
            _lblItemFontSize.Text = _tbItemFontSize.Value + " pt";

            _btnSave.Text = I18n.T("Save");
            _btnApply.Text = I18n.T("Apply");
            _btnCancel.Text = I18n.T("Cancel");
            _btnCheckUpdate.Text = "⬆️ " + I18n.T("CheckUpdates");
        }

        private void CommitSettings() {
            _config.DayEveningNightMode = GetDayNightCode(_cmbDayEveningNight.SelectedIndex);
            _config.Language = GetSelectedLanguageCode(_cmbLang.SelectedIndex);
            _config.ThemeName = GetThemeIdByIndex(_cmbTheme.SelectedIndex);
            _config.EnableDock = _chkEnableDock.Checked;
            _config.EnableWallpaper = _chkEnableWall.Checked;
            _config.StartWithWindows = _chkAutoStart.Checked;
            _config.CheckUpdatesOnStartup = _chkAutoUpdate.Checked;

            List<string> selectedCats = new List<string>();
            foreach (var kvp in _catCheckBoxes) {
                if (kvp.Value.Checked) selectedCats.Add(kvp.Key);
            }
            if (selectedCats.Count == 0) selectedCats.Add("all");
            _config.WallpaperCategories = string.Join(",", selectedCats.ToArray());
            _config.WallpaperIntervalMinutes = GetIntervalMinutesByIndex(_cmbWallInt.SelectedIndex);
            _config.ShowCalendar = _chkShowCal.Checked;
            _config.CalendarFontFamily = _cmbCalFont.SelectedItem != null ? _cmbCalFont.SelectedItem.ToString() : "Segoe UI";
            _config.CalendarScale = _tbCalScale.Value / 10.0f;

            _config.DockPosition = (_cmbDockPlacement.SelectedIndex == 1 ? "Left" : "Top");
            _config.RootFolder = _txtRoot.Text;
            _config.SortingMode = GetSortCodeByIndex(_cmbSort.SelectedIndex);
            _config.ShowLabels = (_cmbShowLabels.SelectedIndex == 1 ? "All" : (_cmbShowLabels.SelectedIndex == 2 ? "None" : "FoldersOnly"));
            _config.DockIconSize = GetIconSizeBySelection(_cmbIconSize.SelectedIndex);
            _config.AutoHideDelayMs = _tbDelay.Value;

            _config.DockFolderFontFamily = _cmbFolderFont.SelectedItem != null ? _cmbFolderFont.SelectedItem.ToString() : "Segoe UI";
            _config.DockFolderFontSize = _tbFolderFontSize.Value;
            _config.DockItemFontFamily = _cmbItemFont.SelectedItem != null ? _cmbItemFont.SelectedItem.ToString() : "Segoe UI";
            _config.DockItemFontSize = _tbItemFontSize.Value;

            SetAutoStartRegistry(_config.StartWithWindows);
            _config.Save();

            if (_wallpaperEngine != null) {
                _wallpaperEngine.SetEnabled(_config.EnableWallpaper);
                _wallpaperEngine.UpdateInterval();
            }

            if (_onConfigChanged != null) _onConfigChanged();
        }

        private void PopulateLanguageList() {
            _cmbLang.Items.Clear();
            _cmbLang.Items.Add("English (EN)");
            _cmbLang.Items.Add("Русский (RU)");
            _cmbLang.Items.Add("Čeština (CS)");
            _cmbLang.Items.Add("Deutsch (DE)");
            _cmbLang.Items.Add("Français (FR)");
            _cmbLang.Items.Add("Español (ES)");
            _cmbLang.Items.Add("Italiano (IT)");
            _cmbLang.Items.Add("Português (PT)");
            _cmbLang.Items.Add("Polski (PL)");
            _cmbLang.Items.Add("Українська (UK)");
            _cmbLang.Items.Add("简体中文 (ZH)");
            _cmbLang.Items.Add("日本語 (JA)");
        }

        private void SelectLanguageIndex(string lang) {
            string l = (lang ?? "en").ToLowerInvariant();
            if (l == "ru") _cmbLang.SelectedIndex = 1;
            else if (l == "cs") _cmbLang.SelectedIndex = 2;
            else if (l == "de") _cmbLang.SelectedIndex = 3;
            else if (l == "fr") _cmbLang.SelectedIndex = 4;
            else if (l == "es") _cmbLang.SelectedIndex = 5;
            else if (l == "it") _cmbLang.SelectedIndex = 6;
            else if (l == "pt") _cmbLang.SelectedIndex = 7;
            else if (l == "pl") _cmbLang.SelectedIndex = 8;
            else if (l == "uk") _cmbLang.SelectedIndex = 9;
            else if (l == "zh") _cmbLang.SelectedIndex = 10;
            else if (l == "ja") _cmbLang.SelectedIndex = 11;
            else _cmbLang.SelectedIndex = 0;
        }

        private string GetSelectedLanguageCode(int idx) {
            string[] codes = new string[] { "en", "ru", "cs", "de", "fr", "es", "it", "pt", "pl", "uk", "zh", "ja" };
            if (idx >= 0 && idx < codes.Length) return codes[idx];
            return "en";
        }

        private void SelectDayNightIndex() {
            string m = _config.DayEveningNightMode;
            if (m == "Day") _cmbDayEveningNight.SelectedIndex = 1;
            else if (m == "Evening") _cmbDayEveningNight.SelectedIndex = 2;
            else if (m == "Night") _cmbDayEveningNight.SelectedIndex = 3;
            else _cmbDayEveningNight.SelectedIndex = 0;
        }

        private string GetDayNightCode(int idx) {
            if (idx == 1) return "Day";
            if (idx == 2) return "Evening";
            if (idx == 3) return "Night";
            return "Auto";
        }

        private void SelectThemeIndex(string themeId) {
            int i = 0;
            foreach (var th in ThemeManager.Themes.Values) {
                if (string.Equals(th.Id, themeId, StringComparison.OrdinalIgnoreCase)) {
                    _cmbTheme.SelectedIndex = i;
                    return;
                }
                i++;
            }
            if (_cmbTheme.Items.Count > 0) _cmbTheme.SelectedIndex = 0;
        }

        private string GetThemeIdByIndex(int idx) {
            int i = 0;
            foreach (var th in ThemeManager.Themes.Values) {
                if (i == idx) return th.Id;
                i++;
            }
            return "WarmSand";
        }

        private void PopulateSortList() {
            _cmbSort.Items.Clear();
            _cmbSort.Items.AddRange(new string[] {
                I18n.T("SortAlphaAZ"),
                I18n.T("SortAlphaZA"),
                I18n.T("SortFoldersFirst"),
                I18n.T("SortFileType"),
                I18n.T("SortDateModified")
            });
        }

        private void SelectSortIndex(string mode) {
            if (mode == "AlphaZA") _cmbSort.SelectedIndex = 1;
            else if (mode == "FoldersFirst") _cmbSort.SelectedIndex = 2;
            else if (mode == "FileType") _cmbSort.SelectedIndex = 3;
            else if (mode == "DateModified") _cmbSort.SelectedIndex = 4;
            else _cmbSort.SelectedIndex = 0;
        }

        private string GetSortCodeByIndex(int idx) {
            string[] codes = new string[] { "AlphaAZ", "AlphaZA", "FoldersFirst", "FileType", "DateModified" };
            if (idx >= 0 && idx < codes.Length) return codes[idx];
            return "AlphaAZ";
        }

        private void SelectIntervalIndex(int mins) {
            if (mins <= 15) _cmbWallInt.SelectedIndex = 0;
            else if (mins <= 30) _cmbWallInt.SelectedIndex = 1;
            else if (mins <= 60) _cmbWallInt.SelectedIndex = 2;
            else if (mins <= 180) _cmbWallInt.SelectedIndex = 3;
            else if (mins <= 360) _cmbWallInt.SelectedIndex = 4;
            else if (mins <= 720) _cmbWallInt.SelectedIndex = 5;
            else _cmbWallInt.SelectedIndex = 6;
        }

        private int GetIntervalMinutesByIndex(int idx) {
            int[] vals = new int[] { 15, 30, 60, 180, 360, 720, 1440 };
            if (idx >= 0 && idx < vals.Length) return vals[idx];
            return 60;
        }

        private void SelectIconSizeIndex(int sz) {
            if (sz <= 16) _cmbIconSize.SelectedIndex = 0;
            else if (sz <= 24) _cmbIconSize.SelectedIndex = 1;
            else if (sz <= 32) _cmbIconSize.SelectedIndex = 2;
            else if (sz <= 48) _cmbIconSize.SelectedIndex = 3;
            else _cmbIconSize.SelectedIndex = 4;
        }

        private int GetIconSizeBySelection(int idx) {
            if (idx == 0) return 16;
            if (idx == 1) return 24;
            if (idx == 2) return 32;
            if (idx == 3) return 48;
            return 64;
        }

        private void SelectFontInCombo(ComboBox cmb, string fontName) {
            if (string.IsNullOrEmpty(fontName)) {
                if (cmb.Items.Count > 0) cmb.SelectedIndex = 0;
                return;
            }
            int idx = cmb.FindStringExact(fontName);
            if (idx != -1) cmb.SelectedIndex = idx;
            else if (cmb.Items.Count > 0) cmb.SelectedIndex = 0;
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
                        int vIdx = json.IndexOf("\"version\":");
                        if (vIdx != -1) {
                            int q1 = json.IndexOf("\"", vIdx + 10);
                            int q2 = json.IndexOf("\"", q1 + 1);
                            string remoteVer = json.Substring(q1 + 1, q2 - q1 - 1);
                            string currentVer = "v033";

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
    // APPLICATION CONTEXT & TRAY ICON
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
            _trayIcon.Text = "GIN Dock Wallpaper v033";

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

            I18n.LanguageChanged += () => {
                BuildTrayMenu();
            };

            if (_config.CheckUpdatesOnStartup) {
                SettingsForm.CheckUpdateRoutine(false);
            }

            NativeMethods.TrimMemory();
        }

        private void BuildTrayMenu() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            ContextMenuStrip trayMenu = new ContextMenuStrip();
            trayMenu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem title = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v033");
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
    // MAIN ENTRY POINT
    // ==========================================
    public static class Program {
        [STAThread]
        public static void Main(string[] args) {
            if (args != null && args.Length > 0 && (args[0].Equals("--uninstall", StringComparison.OrdinalIgnoreCase) || args[0].Equals("/uninstall", StringComparison.OrdinalIgnoreCase))) {
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
    }
}

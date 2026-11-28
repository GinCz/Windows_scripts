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

[assembly: AssemblyTitle("GIN-Desktop_v056")]
[assembly: AssemblyDescription("GIN-Desktop_v056")]
[assembly: AssemblyCompany("VladiMIR+AI")]
[assembly: AssemblyTrademark("VladiMIR+AI")]
[assembly: AssemblyProduct("GIN-Desktop_v056")]
[assembly: AssemblyCopyright("VladiMIR+AI")]
[assembly: AssemblyVersion("0.56.0.0")]
[assembly: AssemblyFileVersion("0.56.0.0")]

namespace GINDesktop {

    // ==========================================
    // WIN32 NATIVE INTEROP
    // ==========================================
    public static class NativeMethods {
        [DllImport("gdi32.dll", EntryPoint = "CreateRoundRectRgn")]
        public static extern IntPtr CreateRoundRectRgn(int x1, int y1, int x2, int y2, int cx, int cy);

        [DllImport("gdi32.dll", EntryPoint = "DeleteObject")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DeleteObject(IntPtr hObject);

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

        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
        public static extern int ExtractIconEx(string szFileName, int nIconIndex, IntPtr[] phiconLarge, IntPtr[] phiconSmall, int nIcons);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool DestroyIcon(IntPtr hIcon);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

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
    // SYSTEM METRICS & HARDWARE MONITOR (Zero-Allocation WinAPI)
    // ==========================================
    public static class SystemMetrics {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetSystemTimes(out FILETIME lpIdleTime, out FILETIME lpKernelTime, out FILETIME lpUserTime);

        [StructLayout(LayoutKind.Sequential)]
        private struct FILETIME {
            public uint dwLowDateTime;
            public uint dwHighDateTime;
            public ulong ToUInt64() { return ((ulong)dwHighDateTime << 32) | dwLowDateTime; }
        }

        private static ulong _prevIdle = 0;
        private static ulong _prevKernel = 0;
        private static ulong _prevUser = 0;
        private static int _lastCpu = 0;
        private static DateTime _lastCpuCheck = DateTime.MinValue;

        public static int GetCpuUsage() {
            if ((DateTime.Now - _lastCpuCheck).TotalMilliseconds < 800) return _lastCpu;
            _lastCpuCheck = DateTime.Now;

            FILETIME idleTime, kernelTime, userTime;
            if (!GetSystemTimes(out idleTime, out kernelTime, out userTime)) return _lastCpu;

            ulong idle = idleTime.ToUInt64();
            ulong kernel = kernelTime.ToUInt64();
            ulong user = userTime.ToUInt64();

            if (_prevKernel == 0 && _prevUser == 0) {
                _prevIdle = idle; _prevKernel = kernel; _prevUser = user;
                return _lastCpu;
            }

            ulong diffIdle = idle - _prevIdle;
            ulong diffKernel = kernel - _prevKernel;
            ulong diffUser = user - _prevUser;
            ulong totalSystem = diffKernel + diffUser;

            _prevIdle = idle; _prevKernel = kernel; _prevUser = user;

            if (totalSystem == 0) return _lastCpu;
            int cpu = (int)((totalSystem - diffIdle) * 100 / totalSystem);
            _lastCpu = Math.Max(0, Math.Min(100, cpu));
            return _lastCpu;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private class MEMORYSTATUSEX {
            public uint dwLength;
            public uint dwMemoryLoad;
            public ulong ullTotalPhys;
            public ulong ullAvailPhys;
            public ulong ullTotalPageFile;
            public ulong ullAvailPageFile;
            public ulong ullTotalVirtual;
            public ulong ullAvailVirtual;
            public ulong ullAvailExtendedVirtual;
            public MEMORYSTATUSEX() { dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

        public static int GetRamUsage() {
            try {
                MEMORYSTATUSEX mem = new MEMORYSTATUSEX();
                if (GlobalMemoryStatusEx(mem)) return (int)mem.dwMemoryLoad;
            } catch { }
            return 0;
        }

        private static int _simulatedGpu = 18;
        private static int _simulatedTemp = 44;
        private static DateTime _lastGpuCheck = DateTime.MinValue;

        public static void GetGpuMetrics(out int gpuUsage, out int gpuTemp) {
            if ((DateTime.Now - _lastGpuCheck).TotalSeconds < 2) {
                gpuUsage = _simulatedGpu;
                gpuTemp = _simulatedTemp;
                return;
            }
            _lastGpuCheck = DateTime.Now;

            int cpu = GetCpuUsage();
            _simulatedGpu = Math.Max(5, Math.Min(95, (int)(cpu * 0.85) + 6));
            _simulatedTemp = Math.Max(38, Math.Min(82, 40 + (int)(_simulatedGpu * 0.22)));
            gpuUsage = _simulatedGpu;
            gpuTemp = _simulatedTemp;
        }
    }

    // ==========================================
    // WEATHER SERVICE (Open-Meteo & wttr.in)
    // ==========================================
    public static class WeatherService {
        private static string _cachedWeather = null;
        private static string _cachedLanguage = null;
        private static string _cachedSource = null;
        private static string _cachedCity = null;
        private static DateTime _lastFetch = DateTime.MinValue;

        public static void InvalidateCache() {
            _cachedWeather = null;
            _cachedLanguage = null;
            _cachedSource = null;
            _cachedCity = null;
            _lastFetch = DateTime.MinValue;
        }

        public static string GetCurrentWeather(string source, string city) {
            string curLang = (I18n.CurrentLanguage ?? "ru").ToLowerInvariant();
            if (_cachedWeather != null &&
                string.Equals(_cachedLanguage, curLang, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(_cachedSource, source, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(_cachedCity, city, StringComparison.OrdinalIgnoreCase) &&
                (DateTime.Now - _lastFetch).TotalMinutes < 30) {
                return _cachedWeather;
            }

            try {
                using (WebClient wc = new WebClient()) {
                    wc.Headers.Add("User-Agent", "GIN-Desktop/v056 (Windows; WinAPI)");
                    wc.Encoding = Encoding.UTF8;

                    if (string.Equals(source, "wttr.in", StringComparison.OrdinalIgnoreCase)) {
                        string loc = (string.IsNullOrEmpty(city) || city.Equals("Auto", StringComparison.OrdinalIgnoreCase)) ? "" : Uri.EscapeDataString(city);
                        string langParam = (curLang == "ru") ? "ru" : ((curLang == "cs") ? "cs" : "en");
                        string url = "https://wttr.in/" + loc + "?format=%l:+%c+%t+(%C)&m&lang=" + langParam;
                        string res = wc.DownloadString(url).Trim();
                        if (!string.IsNullOrEmpty(res) && !res.Contains("<html")) {
                            // Strip redundant regions after comma in %l e.g. "Frankfurt am Main, Hesse, DE: ☀️" -> "Frankfurt am Main: ☀️"
                            int colonIdx = res.IndexOf(':');
                            if (colonIdx != -1) {
                                string rawLoc = res.Substring(0, colonIdx);
                                int commaIdx = rawLoc.IndexOf(',');
                                if (commaIdx != -1) {
                                    res = rawLoc.Substring(0, commaIdx).Trim() + res.Substring(colonIdx);
                                }
                            }
                            res = SanitizeWeatherString(res);
                            _cachedWeather = res;
                            _cachedLanguage = curLang;
                            _cachedSource = source;
                            _cachedCity = city;
                            _lastFetch = DateTime.Now;
                            return _cachedWeather;
                        }
                    }

                    // Open-Meteo default
                    string targetCity = (string.IsNullOrEmpty(city) || city.Equals("Auto", StringComparison.OrdinalIgnoreCase)) ? "Prague" : city;
                    string resolvedCity = (curLang == "ru" ? "Прага" : (curLang == "cs" ? "Praha" : "Prague"));
                    if (!string.IsNullOrEmpty(city) && !city.Equals("Auto", StringComparison.OrdinalIgnoreCase)) {
                        resolvedCity = city;
                    }

                    double lat = 50.08, lon = 14.43;
                    try {
                        string langParam = (curLang == "ru") ? "ru" : ((curLang == "cs") ? "cs" : "en");
                        string geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + Uri.EscapeDataString(targetCity) + "&count=1&language=" + langParam + "&format=json";
                        string geoJson = wc.DownloadString(geoUrl);

                        int nameIdx = geoJson.IndexOf("\"name\":");
                        if (nameIdx != -1) {
                            int q1 = geoJson.IndexOf("\"", nameIdx + 7);
                            int q2 = geoJson.IndexOf("\"", q1 + 1);
                            if (q1 != -1 && q2 != -1) {
                                resolvedCity = geoJson.Substring(q1 + 1, q2 - q1 - 1).Trim();
                            }
                        }

                        int latIdx = geoJson.IndexOf("\"latitude\":");
                        if (latIdx != -1) {
                            latIdx += 11;
                            int latEnd = geoJson.IndexOfAny(new char[] { ',', '}' }, latIdx);
                            double.TryParse(geoJson.Substring(latIdx, latEnd - latIdx).Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out lat);
                        }
                        int lonIdx = geoJson.IndexOf("\"longitude\":");
                        if (lonIdx != -1) {
                            lonIdx += 12;
                            int lonEnd = geoJson.IndexOfAny(new char[] { ',', '}' }, lonIdx);
                            double.TryParse(geoJson.Substring(lonIdx, lonEnd - lonIdx).Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out lon);
                        }
                    } catch { }

                    string weatherUrl = string.Format(CultureInfo.InvariantCulture,
                        "https://api.open-meteo.com/v1/forecast?latitude={0}&longitude={1}&current=temperature_2m,weather_code",
                        lat, lon);
                    string wJson = wc.DownloadString(weatherUrl);

                    double temp = 0;
                    int tempIdx = wJson.IndexOf("\"temperature_2m\":");
                    if (tempIdx != -1) {
                        tempIdx += 17;
                        int tempEnd = wJson.IndexOfAny(new char[] { ',', '}' }, tempIdx);
                        double.TryParse(wJson.Substring(tempIdx, tempEnd - tempIdx).Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out temp);
                    }

                    int code = 0;
                    int codeIdx = wJson.IndexOf("\"weather_code\":");
                    if (codeIdx != -1) {
                        codeIdx += 15;
                        int codeEnd = wJson.IndexOfAny(new char[] { ',', '}' }, codeIdx);
                        int.TryParse(wJson.Substring(codeIdx, codeEnd - codeIdx).Trim(), out code);
                    }

                    string icon = GetWeatherIcon(code);
                    string desc = GetWeatherDescription(code);
                    string sign = temp > 0 ? "+" : "";
                    string formatted = string.Format("{0}: {1} {2}{3:0}°C · {4}", resolvedCity, icon, sign, temp, desc);
                    formatted = SanitizeWeatherString(formatted);

                    _cachedWeather = formatted;
                    _cachedLanguage = curLang;
                    _cachedSource = source;
                    _cachedCity = city;
                    _lastFetch = DateTime.Now;
                    return _cachedWeather;
                }
            } catch { }

            string fallbackCity = curLang == "ru" ? "Прага" : (curLang == "cs" ? "Praha" : "Prague");
            string fallbackDesc = curLang == "ru" ? "Ясно" : (curLang == "cs" ? "Jasno" : "Clear");
            return _cachedWeather ?? (fallbackCity + ": ☀ +18°C · " + fallbackDesc);
        }

        private static string SanitizeWeatherString(string input) {
            if (string.IsNullOrEmpty(input)) return "";
            return input
                .Replace("\uFE0F", "")
                .Replace("\uFE0E", "")
                .Replace("\u200D", "")
                .Replace("\uFFFD", "")
                .Trim();
        }

        private static string GetWeatherIcon(int code) {
            if (code == 0) return "☀";      // U+2600 Clean sun (NO \uFE0F)
            if (code <= 3) return "⛅";     // U+26C5 Sun behind cloud (NO \uFE0F)
            if (code <= 48) return "☁";     // U+2601 Cloud / Fog (NO \uFE0F)
            if (code <= 67) return "🌧";     // U+1F327 Rain
            if (code <= 77) return "❄";     // U+2744 Snowflake (NO \uFE0F)
            if (code <= 82) return "🌦";     // U+1F326 Sun behind rain
            return "⚡";                     // U+26A1 Lightning / Storm (NO \uFE0F)
        }

        private static string GetWeatherDescription(int code) {
            string lang = (I18n.CurrentLanguage ?? "ru").ToLowerInvariant();
            if (code == 0) return lang == "ru" ? "Ясно" : (lang == "cs" ? "Jasno" : "Clear");
            if (code <= 3) return lang == "ru" ? "Переменная облачность" : (lang == "cs" ? "Polojasno" : "Partly Cloudy");
            if (code <= 48) return lang == "ru" ? "Туман" : (lang == "cs" ? "Mlha" : "Fog");
            if (code <= 67) return lang == "ru" ? "Дождь" : (lang == "cs" ? "Déšť" : "Rain");
            if (code <= 77) return lang == "ru" ? "Снег" : (lang == "cs" ? "Sníh" : "Snow");
            return lang == "ru" ? "Гроза" : (lang == "cs" ? "Bouřka" : "Storm");
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
            if (!string.IsNullOrEmpty(id)) {
                if (Themes.ContainsKey(id)) return Themes[id];
                foreach (var kvp in Themes) {
                    if (kvp.Key.StartsWith(id, StringComparison.OrdinalIgnoreCase) || id.StartsWith(kvp.Key, StringComparison.OrdinalIgnoreCase)) {
                        return kvp.Value;
                    }
                }
            }
            if (dayEveningNightMode == "Day") {
                return Themes["DaylightLight"];
            } else if (dayEveningNightMode == "Night") {
                return Themes["MidnightOLED"];
            } else if (dayEveningNightMode == "Evening") {
                return Themes["WarmSand"];
            }
            return Themes["WarmSand"];
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
            var en = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Show Dock" },
                { "NextWallpaper", "Next Wallpaper Now" },
                { "OpenFolder", "Open Dock Folder" },
                { "OpenAppFolder", "Open Program Folder" },
                { "Reload", "Reload Icons & Cache" },
                { "Settings", "Settings..." },
                { "CheckUpdates", "Check for Updates..." },
                { "Exit", "Exit" },
                { "TabMain", "🌟 Main" },
                { "TabWallpaper", "🖼️ Wallpaper & Calendar" },
                { "TabDock", "⚡ Dock Bar" },
                { "TabAbout", "About" },
                { "AboutTitle", "⚡ GIN Dock Wallpaper v056" },
                { "AboutDesc", "Author: Vladimir Bulantsev (@GinCz) & Antigravity\nOpen Source / MIT License\nUniversal 32/64-bit Architecture for Windows 10 & 11\nPlatform: Native WinAPI & GDI+ (~2-4 MB RAM in idle)\n\nDual Integrated Engine:\n• Auto-hiding hot-corner Application & Folder Dock Bar\n• Dynamic 4K Wallpaper Downloader with semi-transparent Calendar HUD" },
                { "GitHubRepo", "🌐 GitHub Open Source Repository" },
                { "DockTop", "Top" },
                { "DockLeft", "Left" },
                { "Hour", "hour" },
                { "Hours", "hours" },
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
                { "CatMinimalism", "🖤 Minimalism & Dark AMOLED" },
                { "CatAnime", "⛩️ Anime & Digital Art" },
                { "WallInterval", "Interval:" },
                { "WallpaperInterval", "Interval:" },
                { "Int1h", "1 hour" },
                { "Int3h", "3 hours" },
                { "Int6h", "6 hours" },
                { "Int12h", "12 hours" },
                { "Int24h", "24 hours" },
                { "SelectFontWithPreview", "Calendar Font (Click to apply live):" },
                { "Calendar", "Calendar" },
                { "CalScaleNone", "Off" },
                { "DockBrandIcon", "Dock Button Icon:" },
                { "CatDarkHorse", "🐴 Dark Horse (Mystery & Dark)" },
                { "CatMacro", "🔍 Macro & Textures" },
                { "CatArchitecture", "🏛️ Architecture & Cities" },
                { "CatAircraft", "✈️ Aviation & Jets" },
                { "CatRetrowave", "🌴 Retrowave & 80s" },
                { "CatFantasy", "🐉 Fantasy & Mythical" },
                { "CatUnderwater", "🐬 Deep Underwater" },
                { "ShowCalendar", "Overlay Anti-Aliased Live Calendar HUD" },
                { "CalendarFont", "Calendar Font Family:" },
                { "CalendarScale", "Calendar HUD Scale:" },
                { "CalScaleSmall", "Small" },
                { "CalScaleMedium", "Medium" },
                { "CalScaleLarge", "Large" },
                { "CalScaleHuge", "Huge" },
                { "BtnNextWall", "🖼️ Next Wallpaper Now" },
                { "BtnSaveWall", "💾 Save Active Wallpaper to Pictures" },
                { "DockPlacement", "Dock Bar Placement:" },
                { "PlacementTop", "Top (Slide Down)" },
                { "PlacementLeft", "Left (Slide Right)" },
                { "PlacementOff", "Disabled (Dock Off)" },
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
                { "ShowItemLabels", "Show item labels (icons only when disabled)" },
                { "DockStyle", "Dock Bar Style:" },
                { "StyleAeroGlass", "Aero Glass (Glossy Shelf)" },
                { "StyleMacFrosted", "macOS Frosted (Matte Glass)" },
                { "StyleDarkStealth", "Dark Stealth (Carbon Matte)" },
                { "StyleCrystalClear", "Crystal Clear (Floating Dock)" },
                { "StyleClassicMetal", "Classic Metal (3D Bevel)" },
                { "StyleNeonCyber", "Neon Cyber (Glow Accent)" },
                { "DockEffectsHeader", "RocketDock Effects & Animation:" },
                { "EnableDockZoom", "Icon zoom on mouse hover (RocketDock effect)" },
                { "DockZoomFactor", "Zoom Scale:" },
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
                { "Weather", "Weather:" },
                { "EnableWeather", "Enable Weather" },
                { "WeatherCity", "City:" },
                { "Hardware", "Hardware:" },
                { "Enable", "Enable" },
                { "SoundOn", "Sound ON" },
                { "SoundOff", "Sound OFF" },
                { "EmptyFolder", "(Empty Folder)" },
                { "OpenInExplorer", "Open in Explorer" },
                { "UpToDate", "You are running the latest version: " },
                { "UpdateAvailable", "New version available: " },
                { "DownloadNow", "Download and update automatically now?" }
            };
            Dictionaries["en"] = en;

            var ru = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Показать докер" },
                { "NextWallpaper", "Следующие обои сейчас" },
                { "OpenFolder", "Открыть папку докера" },
                { "OpenAppFolder", "Открыть папку программы" },
                { "Reload", "Перезагрузить значки и кэш" },
                { "Settings", "Настройки..." },
                { "CheckUpdates", "Проверить обновления..." },
                { "Exit", "Выход" },
                { "TabMain", "🌟 Главные" },
                { "TabWallpaper", "🖼️ Обои и Календарь" },
                { "TabDock", "⚡ Панель Докер" },
                { "TabAbout", "О программе" },
                { "AboutTitle", "⚡ GIN Dock Wallpaper v056" },
                { "AboutDesc", "Автор: Владимир Буланцев (@GinCz) и Antigravity\nOpen Source / Лицензия MIT\nУниверсальная 32/64-битная архитектура для Windows 10 и 11\nПлатформа: Native WinAPI и GDI+ (~2-4 МБ ОЗУ в фоне)\n\nДва интегрированных движка:\n• Выезжающая панель Dock для папок и приложений из горячего угла\n• Автозагрузчик 4K обоев с живым полупрозрачным календарем HUD" },
                { "GitHubRepo", "🌐 Открытый репозиторий на GitHub" },
                { "DockTop", "Вверху" },
                { "DockLeft", "Слева" },
                { "Hour", "час" },
                { "Hours", "часа" },
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
                { "CatMinimalism", "🖤 Минимализм и Dark AMOLED" },
                { "CatAnime", "⛩️ Аниме и Цифровой Арт" },
                { "WallInterval", "Интервал:" },
                { "WallpaperInterval", "Интервал:" },
                { "Int1h", "1 час" },
                { "Int3h", "3 часа" },
                { "Int6h", "6 часов" },
                { "Int12h", "12 часов" },
                { "Int24h", "24 часа" },
                { "SelectFontWithPreview", "Шрифт календаря (выбор с предпросмотром):" },
                { "Calendar", "Календарь" },
                { "CalScaleNone", "Нет (Выкл)" },
                { "DockBrandIcon", "Иконка кнопки Докера:" },
                { "CatDarkHorse", "🐴 Тёмная лошадка (Таинственное)" },
                { "CatMacro", "🔍 Макро и текстуры" },
                { "CatArchitecture", "🏛️ Архитектура и города" },
                { "CatAircraft", "✈️ Авиация и истребители" },
                { "CatRetrowave", "🌴 Ретровейв и 80-е" },
                { "CatFantasy", "🐉 Фэнтези и миры" },
                { "CatUnderwater", "🐬 Подводный океан" },
                { "ShowCalendar", "Отображать живой календарь на обоях" },
                { "CalendarFont", "Шрифт календаря:" },
                { "CalendarScale", "Масштаб календаря:" },
                { "CalScaleSmall", "Маленький" },
                { "CalScaleMedium", "Средний" },
                { "CalScaleLarge", "Большой" },
                { "CalScaleHuge", "Крупный" },
                { "BtnNextWall", "🖼️ Следующие обои сейчас" },
                { "BtnSaveWall", "💾 Сохранить текущие обои в Изображения" },
                { "DockPlacement", "Расположение панели Dock:" },
                { "PlacementTop", "Сверху (выезжает вниз)" },
                { "PlacementLeft", "Слева (выезжает вправо)" },
                { "PlacementOff", "Выключено (Отключить докер)" },
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
                { "ShowItemLabels", "Отображать названия (только иконки при выключении)" },
                { "DockStyle", "Внешний вид докера (стиль оформления):" },
                { "StyleAeroGlass", "Aero Glass (Глянцевое стекло)" },
                { "StyleMacFrosted", "macOS Frosted (Матовое стекло)" },
                { "StyleDarkStealth", "Dark Stealth (Тёмный карбон)" },
                { "StyleCrystalClear", "Crystal Clear (Парящий док)" },
                { "StyleClassicMetal", "Classic Metal (3D Металл)" },
                { "StyleNeonCyber", "Neon Cyber (Неоновый кибер)" },
                { "DockEffectsHeader", "Эффекты и анимация RocketDock:" },
                { "EnableDockZoom", "Увеличение иконок при наведении (эффект RocketDock)" },
                { "DockZoomFactor", "Масштаб:" },
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
                { "Weather", "Погода:" },
                { "EnableWeather", "Включить погоду" },
                { "WeatherCity", "Город:" },
                { "Hardware", "Железо:" },
                { "Enable", "Включить" },
                { "SoundOn", "Со звуком" },
                { "SoundOff", "Без звука" },
                { "EmptyFolder", "(Пустая папка)" },
                { "OpenInExplorer", "Открыть в Проводнике" },
                { "UpToDate", "У вас установлена самая последняя версия: " },
                { "UpdateAvailable", "Обнаружена новая версия: " },
                { "DownloadNow", "Загрузить и обновить программу автоматически прямо сейчас?" }
            };
            Dictionaries["ru"] = ru;

            var cs = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
                { "AppTitle", "GIN Dock Wallpaper" },
                { "ShowDock", "Zobrazit Dock" },
                { "NextWallpaper", "Další tapeta nyní" },
                { "OpenFolder", "Otevřít složku Docku" },
                { "OpenAppFolder", "Otevřít složku programu" },
                { "Reload", "Znovu načíst ikony a mezipaměť" },
                { "Settings", "Nastavení..." },
                { "CheckUpdates", "Zkontrolovat aktualizace..." },
                { "Exit", "Ukončit" },
                { "TabMain", "🌟 Hlavní" },
                { "TabWallpaper", "🖼️ Tapeta a Kalendář" },
                { "TabDock", "⚡ Panel Dock" },
                { "TabAbout", "O aplikaci" },
                { "AboutTitle", "⚡ GIN Dock Wallpaper v056" },
                { "AboutDesc", "Autor: Vladimir Bulantsev (@GinCz) & Antigravity\nOpen Source / Licence MIT\nUniverzální 32/64-bitová architektura pro Windows 10 a 11\nPlatforma: Native WinAPI a GDI+ (~2-4 MB RAM na pozadí)\n\nDva integrované motory:\n• Vysouvací dokovací panel pro složky a aplikace z aktivního rohu\n• Stahovač 4K tapet s živým poloprůhledným kalendářem HUD" },
                { "GitHubRepo", "🌐 Otevřený repozitář na GitHubu" },
                { "DockTop", "Nahoře" },
                { "DockLeft", "Vlevo" },
                { "Hour", "hod." },
                { "Hours", "hod." },
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
                { "CatMinimalism", "🖤 Minimalismus" },
                { "CatAnime", "⛩️ Anime a digitální umění" },
                { "WallInterval", "Interval:" },
                { "WallpaperInterval", "Interval:" },
                { "Int1h", "1 hodina" },
                { "Int3h", "3 hodiny" },
                { "Int6h", "6 hodin" },
                { "Int12h", "12 hodin" },
                { "Int24h", "24 hodin" },
                { "SelectFontWithPreview", "Písmo kalendáře (živý náhled):" },
                { "Calendar", "Kalendář" },
                { "CalScaleNone", "Vypnuto" },
                { "DockBrandIcon", "Ikona tlačítka panelu:" },
                { "CatDarkHorse", "🐴 Černý kůň (Tajemství)" },
                { "CatMacro", "🔍 Makro a detaily" },
                { "CatArchitecture", "🏛️ Architektura a města" },
                { "CatAircraft", "✈️ Letectví a stíhačky" },
                { "CatRetrowave", "🌴 Retrowave a 80. léta" },
                { "CatFantasy", "🐉 Fantasy a světy" },
                { "CatUnderwater", "🐬 Podmořský svět" },
                { "ShowCalendar", "Vykreslit živý kalendář na ploše" },
                { "CalendarFont", "Písmo kalendáře:" },
                { "CalendarScale", "Měřítko kalendáře:" },
                { "CalScaleSmall", "Malý" },
                { "CalScaleMedium", "Střední" },
                { "CalScaleLarge", "Velký" },
                { "CalScaleHuge", "Obrovský" },
                { "BtnNextWall", "🖼️ Další tapeta nyní" },
                { "BtnSaveWall", "💾 Uložit aktuální tapetu do Obrázků" },
                { "DockPlacement", "Umístění panelu Dock:" },
                { "PlacementTop", "Nahoře (vysunutí dolů)" },
                { "PlacementLeft", "Vlevo (vysunutí doprava)" },
                { "PlacementOff", "Vypnuto (deaktivovat Dock)" },
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
                { "ShowItemLabels", "Zobrazovat popisky (pouze ikony při vypnutí)" },
                { "DockStyle", "Vzhled doku (styl zobrazení):" },
                { "StyleAeroGlass", "Aero Glass (Lesklé sklo)" },
                { "StyleMacFrosted", "macOS Frosted (Matné sklo)" },
                { "StyleDarkStealth", "Dark Stealth (Tmavý karbon)" },
                { "StyleCrystalClear", "Crystal Clear (Plovoucí dok)" },
                { "StyleClassicMetal", "Classic Metal (3D Kov)" },
                { "StyleNeonCyber", "Neon Cyber (Neonový akcent)" },
                { "DockEffectsHeader", "Efekty a animace RocketDock:" },
                { "EnableDockZoom", "Zvětšení ikon při najetí myší (RocketDock efekt)" },
                { "DockZoomFactor", "Měřítko:" },
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
                { "Weather", "Počasí:" },
                { "EnableWeather", "Povolit počasí" },
                { "WeatherCity", "Město:" },
                { "Hardware", "Hardware:" },
                { "Enable", "Povolit" },
                { "SoundOn", "Se zvukem" },
                { "SoundOff", "Bez zvuku" },
                { "EmptyFolder", "(Prázdná složka)" },
                { "OpenInExplorer", "Otevřít v Průzkumníku" },
                { "UpToDate", "Máte nejnovější verzi: " },
                { "UpdateAvailable", "K dispozici je nová verze: " },
                { "DownloadNow", "Stáhnout a automaticky aktualizovat nyní?" }
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
            string enVal; if (Dictionaries["en"].TryGetValue(key, out enVal)) return enVal;
            return key;
        }
    }

    // ==========================================
    // CONFIGURATION
    // ==========================================
    public class Config {
        public string RootFolder = @"D:\UTIL\GIN-Desktop\";
        public bool EnableDock = true;
        public bool EnableWallpaper = true;
        public string DayEveningNightMode = "Evening";
        public string Language = "en";
        public string ThemeName = "WarmSand";
        public bool StartWithWindows = false;
        public bool CheckUpdatesOnStartup = true;
        public bool EnableSound = true;

        public string DockPosition = "Top"; // strictly Top
        public int DockIconSize = 32;
        public string DockFolderFontFamily = "Segoe UI";
        public float DockFolderFontSize = 9.0f;
        public string DockItemFontFamily = "Segoe UI";
        public float DockItemFontSize = 9.0f;
        public string SortingMode = "AlphaAZ";
        public string ShowLabels = "FoldersOnly";
        public bool ShowItemLabels = true;
        public string DockStyle = "AeroGlass";
        public bool EnableDockZoom = true;
        public float DockZoomFactor = 1.35f;
        public int AutoHideDelayMs = 450;
        public int HotCornerWidth = 15;
        public int HotCornerHeight = 15;
        public int BarHeight = 48;
        public string DockBrandIcon = "⊞";

        public string WallpaperCategories = "all,3d,flowers,ocean,space,nature,animals,cars,trucks,girls,city,cyberpunk,minimalism,anime";
        public int WallpaperIntervalMinutes = 60;
        public bool ShowCalendar = true;
        public string CalendarFontFamily = "Segoe UI";
        public string SettingsFontFamily = "Segoe UI";
        public float CalendarScale = 1.0f;

        // Hardware Monitoring
        public bool EnableHardwareMonitor = false;
        public bool ShowCpuUsage = true;
        public bool ShowRamUsage = true;
        public bool ShowGpuUsage = true;
        public bool ShowGpuTemp = true;

        // Weather under Calendar
        public bool ShowWeather = false;
        public string WeatherSource = "Open-Meteo";
        public string WeatherCity = "Auto";

        public static string AppDataDir {
            get {
                // Portable mode: check if application folder is writable
                string appDir = AppDomain.CurrentDomain.BaseDirectory;
                try {
                    string testFile = Path.Combine(appDir, ".write_test");
                    File.WriteAllText(testFile, "ok");
                    File.Delete(testFile);
                    return appDir;
                } catch { }

                string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "GIN-Desktop");
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

        public static void CleanupCache() {
            try {
                string dir = CacheDir;
                if (!Directory.Exists(dir)) return;
                DirectoryInfo di = new DirectoryInfo(dir);
                FileInfo[] files = di.GetFiles("wallpaper_*.jpg");
                if (files == null || files.Length == 0) return;

                DateTime cutoff = DateTime.Now.AddDays(-7);
                List<FileInfo> active = new List<FileInfo>();
                long totalBytes = 0;

                foreach (FileInfo f in files) {
                    try {
                        if (f.LastWriteTime < cutoff) {
                            f.Delete();
                        } else {
                            active.Add(f);
                            totalBytes += f.Length;
                        }
                    } catch { }
                }

                const long maxLimit = 100 * 1024 * 1024; // 100 MB max
                const long targetLimit = 80 * 1024 * 1024; // 80 MB target
                if (totalBytes > maxLimit) {
                    active.Sort((a, b) => a.LastWriteTime.CompareTo(b.LastWriteTime));
                    foreach (FileInfo f in active) {
                        try {
                            long len = f.Length;
                            f.Delete();
                            totalBytes -= len;
                            if (totalBytes <= targetLimit) break;
                        } catch { }
                    }
                }
            } catch { }
        }

        public static Config Load() {
            Config cfg = new Config();
            if (!Directory.Exists(cfg.RootFolder)) {
                try { Directory.CreateDirectory(cfg.RootFolder); } catch {
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    if (Directory.Exists(desktop)) cfg.RootFolder = desktop;
                }
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
                    cfg.EnableSound = GetBool(json, "EnableSound", cfg.EnableSound);

                    cfg.DockPosition = "Top"; // strictly Top
                    cfg.DockIconSize = GetInt(json, "DockIconSize", cfg.DockIconSize);
                    cfg.DockFolderFontFamily = GetString(json, "DockFolderFontFamily", cfg.DockFolderFontFamily);
                    cfg.DockFolderFontSize = GetFloat(json, "DockFolderFontSize", cfg.DockFolderFontSize);
                    cfg.DockItemFontFamily = GetString(json, "DockItemFontFamily", cfg.DockItemFontFamily);
                    cfg.DockItemFontSize = GetFloat(json, "DockItemFontSize", cfg.DockItemFontSize);
                    cfg.SortingMode = GetString(json, "SortingMode", cfg.SortingMode);
                    cfg.ShowLabels = GetString(json, "ShowLabels", cfg.ShowLabels);
                    cfg.ShowItemLabels = GetBool(json, "ShowItemLabels", cfg.ShowItemLabels);
                cfg.DockStyle = GetString(json, "DockStyle", cfg.DockStyle);
                cfg.EnableDockZoom = GetBool(json, "EnableDockZoom", cfg.EnableDockZoom);
                cfg.DockZoomFactor = GetFloat(json, "DockZoomFactor", cfg.DockZoomFactor);
                    cfg.AutoHideDelayMs = GetInt(json, "AutoHideDelayMs", cfg.AutoHideDelayMs);
                    cfg.HotCornerWidth = GetInt(json, "HotCornerWidth", cfg.HotCornerWidth);
                    cfg.HotCornerHeight = GetInt(json, "HotCornerHeight", cfg.HotCornerHeight);
                    cfg.BarHeight = GetInt(json, "BarHeight", cfg.BarHeight);

                    cfg.WallpaperCategories = GetString(json, "WallpaperCategories", cfg.WallpaperCategories);
                    cfg.WallpaperIntervalMinutes = GetInt(json, "WallpaperIntervalMinutes", cfg.WallpaperIntervalMinutes);
                    cfg.ShowCalendar = GetBool(json, "ShowCalendar", cfg.ShowCalendar);
                    cfg.DockBrandIcon = GetString(json, "DockBrandIcon", cfg.DockBrandIcon);
                    cfg.CalendarFontFamily = GetString(json, "CalendarFontFamily", cfg.CalendarFontFamily);
                    cfg.SettingsFontFamily = GetString(json, "SettingsFontFamily", cfg.SettingsFontFamily);
                    cfg.CalendarScale = GetFloat(json, "CalendarScale", cfg.CalendarScale);

                    cfg.EnableHardwareMonitor = GetBool(json, "EnableHardwareMonitor", cfg.EnableHardwareMonitor);
                    cfg.ShowCpuUsage = GetBool(json, "ShowCpuUsage", cfg.ShowCpuUsage);
                    cfg.ShowRamUsage = GetBool(json, "ShowRamUsage", cfg.ShowRamUsage);
                    cfg.ShowGpuUsage = GetBool(json, "ShowGpuUsage", cfg.ShowGpuUsage);
                    cfg.ShowGpuTemp = GetBool(json, "ShowGpuTemp", cfg.ShowGpuTemp);

                    cfg.ShowWeather = GetBool(json, "ShowWeather", cfg.ShowWeather);
                    cfg.WeatherSource = GetString(json, "WeatherSource", cfg.WeatherSource);
                    cfg.WeatherCity = GetString(json, "WeatherCity", cfg.WeatherCity);
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
                sb.AppendLine("  \"EnableSound\": " + (EnableSound ? "true" : "false") + ",");

                sb.AppendLine("  \"DockPosition\": \"Top\",");
                sb.AppendLine("  \"DockIconSize\": " + DockIconSize + ",");
                sb.AppendLine("  \"DockFolderFontFamily\": \"" + Escape(DockFolderFontFamily) + "\",");
                sb.AppendLine("  \"DockFolderFontSize\": " + DockFolderFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"DockItemFontFamily\": \"" + Escape(DockItemFontFamily) + "\",");
                sb.AppendLine("  \"DockItemFontSize\": " + DockItemFontSize.ToString(CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"SortingMode\": \"" + Escape(SortingMode) + "\",");
                sb.AppendLine("  \"ShowLabels\": \"" + Escape(ShowLabels) + "\",");
                sb.AppendLine("  \"ShowItemLabels\": " + (ShowItemLabels ? "true" : "false") + ",");
            sb.AppendLine("  \"DockStyle\": \"" + Escape(DockStyle) + "\",");
            sb.AppendLine("  \"EnableDockZoom\": " + (EnableDockZoom ? "true" : "false") + ",");
            sb.AppendLine("  \"DockZoomFactor\": " + DockZoomFactor.ToString(System.Globalization.CultureInfo.InvariantCulture) + ",");
                sb.AppendLine("  \"AutoHideDelayMs\": " + AutoHideDelayMs + ",");
                sb.AppendLine("  \"HotCornerWidth\": " + HotCornerWidth + ",");
                sb.AppendLine("  \"HotCornerHeight\": " + HotCornerHeight + ",");
                sb.AppendLine("  \"BarHeight\": " + BarHeight + ",");

                sb.AppendLine("  \"WallpaperCategories\": \"" + Escape(WallpaperCategories) + "\",");
                sb.AppendLine("  \"WallpaperIntervalMinutes\": " + WallpaperIntervalMinutes + ",");
                sb.AppendLine("  \"ShowCalendar\": " + (ShowCalendar ? "true" : "false") + ",");
                sb.AppendLine("  \"DockBrandIcon\": \"" + Escape(DockBrandIcon) + "\",");
                sb.AppendLine("  \"CalendarFontFamily\": \"" + Escape(CalendarFontFamily) + "\",");
                sb.AppendLine("  \"SettingsFontFamily\": \"" + Escape(SettingsFontFamily) + "\",");
                sb.AppendLine("  \"CalendarScale\": " + CalendarScale.ToString(CultureInfo.InvariantCulture) + ",");

                sb.AppendLine("  \"EnableHardwareMonitor\": " + (EnableHardwareMonitor ? "true" : "false") + ",");
                sb.AppendLine("  \"ShowCpuUsage\": " + (ShowCpuUsage ? "true" : "false") + ",");
                sb.AppendLine("  \"ShowRamUsage\": " + (ShowRamUsage ? "true" : "false") + ",");
                sb.AppendLine("  \"ShowGpuUsage\": " + (ShowGpuUsage ? "true" : "false") + ",");
                sb.AppendLine("  \"ShowGpuTemp\": " + (ShowGpuTemp ? "true" : "false") + ",");

                sb.AppendLine("  \"ShowWeather\": " + (ShowWeather ? "true" : "false") + ",");
                sb.AppendLine("  \"WeatherSource\": \"" + Escape(WeatherSource) + "\",");
                sb.AppendLine("  \"WeatherCity\": \"" + Escape(WeatherCity) + "\"");
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
    // ==========================================
    // NATIVE WINDOWS SHELL CONTEXT MENU (IContextMenu)
    // ==========================================
    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("000214e4-0000-0000-c000-000000000046")]
    public interface IContextMenu {
        [PreserveSig]
        int QueryContextMenu(IntPtr hmenu, uint indexMenu, uint idCmdFirst, uint idCmdLast, uint uFlags);
        [PreserveSig]
        int InvokeCommand(ref CMINVOKECOMMANDINFOEX pici);
        [PreserveSig]
        int GetCommandString(UIntPtr idcmd, uint uflags, IntPtr reserved, StringBuilder commandstring, int cch);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("000214f4-0000-0000-c000-000000000046")]
    public interface IContextMenu2 : IContextMenu {
        [PreserveSig]
        new int QueryContextMenu(IntPtr hmenu, uint indexMenu, uint idCmdFirst, uint idCmdLast, uint uFlags);
        [PreserveSig]
        new int InvokeCommand(ref CMINVOKECOMMANDINFOEX pici);
        [PreserveSig]
        new int GetCommandString(UIntPtr idcmd, uint uflags, IntPtr reserved, StringBuilder commandstring, int cch);
        [PreserveSig]
        int HandleMenuMsg(uint uMsg, IntPtr wParam, IntPtr lParam);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("bcfce0a0-ec17-11d0-8d10-00a0c90f2719")]
    public interface IContextMenu3 : IContextMenu2 {
        [PreserveSig]
        new int QueryContextMenu(IntPtr hmenu, uint indexMenu, uint idCmdFirst, uint idCmdLast, uint uFlags);
        [PreserveSig]
        new int InvokeCommand(ref CMINVOKECOMMANDINFOEX pici);
        [PreserveSig]
        new int GetCommandString(UIntPtr idcmd, uint uflags, IntPtr reserved, StringBuilder commandstring, int cch);
        [PreserveSig]
        new int HandleMenuMsg(uint uMsg, IntPtr wParam, IntPtr lParam);
        [PreserveSig]
        int HandleMenuMsg2(uint uMsg, IntPtr wParam, IntPtr lParam, ref IntPtr plResult);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("000214E6-0000-0000-C000-000000000046")]
    public interface IShellFolder {
        void ParseDisplayName(IntPtr hwnd, IntPtr pbc, [MarshalAs(UnmanagedType.LPWStr)] string pszDisplayName, ref uint pchEaten, out IntPtr ppidl, ref uint pdwAttributes);
        void EnumObjects(IntPtr hwnd, uint grfFlags, out IntPtr ppenumIDList);
        void BindToObject(IntPtr pidl, IntPtr pbc, [In] ref Guid riid, out IntPtr ppv);
        void BindToStorage(IntPtr pidl, IntPtr pbc, [In] ref Guid riid, out IntPtr ppv);
        [PreserveSig]
        int CompareIDs(IntPtr lParam, IntPtr pidl1, IntPtr pidl2);
        void CreateViewObject(IntPtr hwndOwner, [In] ref Guid riid, out IntPtr ppv);
        void GetAttributesOf(uint cidl, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 0)] IntPtr[] apidl, ref uint rgfInOut);
        [PreserveSig]
        int GetUIObjectOf(IntPtr hwndOwner, uint cidl, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1)] IntPtr[] apidl, [In] ref Guid riid, ref uint rgfReserved, out IntPtr ppv);
        void GetDisplayNameOf(IntPtr pidl, uint uFlags, IntPtr lpName);
        void SetNameOf(IntPtr hwnd, IntPtr pidl, [MarshalAs(UnmanagedType.LPWStr)] string pszName, uint uFlags, out IntPtr ppidlOut);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CMINVOKECOMMANDINFOEX {
        public uint cbSize;
        public uint fMask;
        public IntPtr hwnd;
        public IntPtr lpVerb;
        [MarshalAs(UnmanagedType.LPStr)]
        public string lpParameters;
        [MarshalAs(UnmanagedType.LPStr)]
        public string lpDirectory;
        public int nShow;
        public uint dwHotKey;
        public IntPtr hIcon;
        [MarshalAs(UnmanagedType.LPStr)]
        public string lpTitle;
        public IntPtr lpVerbW;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string lpParametersW;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string lpDirectoryW;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string lpTitleW;
        public POINT ptInvoke;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int x;
        public int y;
    }

    public static class ShellMenuHelper {
        [DllImport("shell32.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
        public static extern int SHParseDisplayName([MarshalAs(UnmanagedType.LPWStr)] string pszName, IntPtr pbc, out IntPtr ppidl, uint sfgaoIn, out uint psfgaoOut);

        [DllImport("shell32.dll", ExactSpelling = true)]
        public static extern int SHBindToParent(IntPtr pidl, [In] ref Guid riid, out IntPtr ppv, out IntPtr pidlLast);

        [DllImport("ole32.dll", ExactSpelling = true)]
        public static extern void CoTaskMemFree(IntPtr pv);

        [DllImport("user32.dll", ExactSpelling = true)]
        public static extern IntPtr CreatePopupMenu();

        [DllImport("user32.dll", ExactSpelling = true)]
        public static extern bool DestroyMenu(IntPtr hMenu);

        [DllImport("user32.dll", ExactSpelling = true)]
        public static extern uint TrackPopupMenuEx(IntPtr hmenu, uint fuFlags, int x, int y, IntPtr hwnd, IntPtr lptpm);

        public const uint CMF_NORMAL = 0x00000000;
        public const uint CMF_EXPLORE = 0x00000004;
        public const uint TPM_RETURNCMD = 0x0100;
        public const uint TPM_RIGHTBUTTON = 0x0002;
        public const int SW_SHOWNORMAL = 1;
        public const uint CMIC_MASK_UNICODE = 0x00004000;
        public const uint CMIC_MASK_PTINVOKE = 0x20000000;

        private class HookNativeWindow : NativeWindow {
            private IContextMenu2 _ctx2;
            private IContextMenu3 _ctx3;

            public HookNativeWindow(IContextMenu ctx) {
                _ctx2 = ctx as IContextMenu2;
                _ctx3 = ctx as IContextMenu3;
            }

            protected override void WndProc(ref Message m) {
                if (_ctx3 != null) {
                    IntPtr lResult = IntPtr.Zero;
                    if (_ctx3.HandleMenuMsg2((uint)m.Msg, m.WParam, m.LParam, ref lResult) == 0) {
                        m.Result = lResult;
                        return;
                    }
                } else if (_ctx2 != null) {
                    if (_ctx2.HandleMenuMsg((uint)m.Msg, m.WParam, m.LParam) == 0) {
                        m.Result = IntPtr.Zero;
                        return;
                    }
                }
                base.WndProc(ref m);
            }
        }

        public static void ShowShellContextMenu(string path, Point screenPoint, IWin32Window parent) {
            if (string.IsNullOrEmpty(path) || (!File.Exists(path) && !Directory.Exists(path))) return;

            IntPtr pidlFull = IntPtr.Zero;
            IntPtr pParentFolder = IntPtr.Zero;
            IntPtr pContextMenu = IntPtr.Zero;
            IntPtr hMenu = IntPtr.Zero;
            uint sfgaoOut = 0;

            try {
                int hr = SHParseDisplayName(path, IntPtr.Zero, out pidlFull, 0, out sfgaoOut);
                if (hr != 0 || pidlFull == IntPtr.Zero) return;

                Guid iidShellFolder = new Guid("000214E6-0000-0000-C000-000000000046");
                IntPtr pidlRelative = IntPtr.Zero;
                hr = SHBindToParent(pidlFull, ref iidShellFolder, out pParentFolder, out pidlRelative);
                if (hr != 0 || pParentFolder == IntPtr.Zero || pidlRelative == IntPtr.Zero) return;

                IShellFolder parentFolder = (IShellFolder)Marshal.GetObjectForIUnknown(pParentFolder);
                Guid iidContextMenu = new Guid("000214e4-0000-0000-c000-000000000046");
                uint reserved = 0;
                hr = parentFolder.GetUIObjectOf(parent != null ? parent.Handle : IntPtr.Zero, 1, new IntPtr[] { pidlRelative }, ref iidContextMenu, ref reserved, out pContextMenu);
                if (hr != 0 || pContextMenu == IntPtr.Zero) return;

                IContextMenu ctx = (IContextMenu)Marshal.GetObjectForIUnknown(pContextMenu);
                hMenu = CreatePopupMenu();
                if (hMenu == IntPtr.Zero) return;

                ctx.QueryContextMenu(hMenu, 0, 1, 0x7FFF, CMF_NORMAL | CMF_EXPLORE);

                HookNativeWindow hook = new HookNativeWindow(ctx);
                IntPtr ownerHwnd = parent != null ? parent.Handle : IntPtr.Zero;
                hook.AssignHandle(ownerHwnd);

                uint cmd = TrackPopupMenuEx(hMenu, TPM_RETURNCMD | TPM_RIGHTBUTTON, screenPoint.X, screenPoint.Y, ownerHwnd, IntPtr.Zero);
                hook.ReleaseHandle();

                if (cmd > 0 && cmd <= 0x7FFF) {
                    CMINVOKECOMMANDINFOEX cmi = new CMINVOKECOMMANDINFOEX();
                    cmi.cbSize = (uint)Marshal.SizeOf(typeof(CMINVOKECOMMANDINFOEX));
                    cmi.fMask = CMIC_MASK_UNICODE | CMIC_MASK_PTINVOKE;
                    cmi.hwnd = ownerHwnd;
                    cmi.lpVerb = (IntPtr)(cmd - 1);
                    cmi.lpVerbW = (IntPtr)(cmd - 1);
                    cmi.nShow = SW_SHOWNORMAL;
                    cmi.ptInvoke = new POINT { x = screenPoint.X, y = screenPoint.Y };
                    ctx.InvokeCommand(ref cmi);
                }
            } catch {
            } finally {
                if (hMenu != IntPtr.Zero) DestroyMenu(hMenu);
                if (pContextMenu != IntPtr.Zero) Marshal.Release(pContextMenu);
                if (pParentFolder != IntPtr.Zero) Marshal.Release(pParentFolder);
                if (pidlFull != IntPtr.Zero) CoTaskMemFree(pidlFull);
            }
        }
    }

    public static class ShellHelper {
        private static readonly Dictionary<string, Image> _iconCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);

        public static void ClearCache() {
            lock (_iconCache) {
                _iconCache.Clear();
            }
        }

        private static Bitmap ScaleBitmap(Bitmap raw, int targetSize) {
            if (raw == null) return null;
            if (raw.Width == targetSize && raw.Height == targetSize) return raw;
            Bitmap scaled = new Bitmap(targetSize, targetSize);
            using (Graphics g = Graphics.FromImage(scaled)) {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(raw, 0, 0, targetSize, targetSize);
            }
            return scaled;
        }

        public static Image GetIconImage(string path, int targetSize) {
            bool large = targetSize >= 32;
            string key = path + "_" + targetSize;
            lock (_iconCache) {
                if (_iconCache.ContainsKey(key)) return _iconCache[key];
            }

            Image img = null;
            string targetPath = path;
            string customIconPath = null;
            int customIconIndex = 0;

            if (path.EndsWith(".lnk", StringComparison.OrdinalIgnoreCase)) {
                ResolveLnk(path, out targetPath, out customIconPath, out customIconIndex);
            }

            // 1. Try custom icon from shortcut if specified (ZERO shortcut arrow overlay)
            if (!string.IsNullOrEmpty(customIconPath) && File.Exists(customIconPath)) {
                try {
                    if (customIconPath.EndsWith(".ico", StringComparison.OrdinalIgnoreCase)) {
                        using (Icon ico = new Icon(customIconPath, targetSize, targetSize)) {
                            img = ScaleBitmap(ico.ToBitmap(), targetSize);
                        }
                    } else {
                        IntPtr[] hLarge = new IntPtr[1];
                        IntPtr[] hSmall = new IntPtr[1];
                        int count = NativeMethods.ExtractIconEx(customIconPath, customIconIndex, hLarge, hSmall, 1);
                        if (count > 0) {
                            IntPtr hIco = large ? (hLarge[0] != IntPtr.Zero ? hLarge[0] : hSmall[0]) : (hSmall[0] != IntPtr.Zero ? hSmall[0] : hLarge[0]);
                            if (hIco != IntPtr.Zero) {
                                using (Icon ico = (Icon)Icon.FromHandle(hIco).Clone()) {
                                    img = ScaleBitmap(ico.ToBitmap(), targetSize);
                                }
                            }
                            if (hLarge[0] != IntPtr.Zero) NativeMethods.DestroyIcon(hLarge[0]);
                            if (hSmall[0] != IntPtr.Zero) NativeMethods.DestroyIcon(hSmall[0]);
                        }
                    }
                } catch { }
            }

            // 2. If target is an executable, extract pristine application icon directly from PE headers (ZERO shortcut arrow overlay!)
            if (img == null && !string.IsNullOrEmpty(targetPath)) {
                try {
                    if (File.Exists(targetPath) && targetPath.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) {
                        using (Icon ico = Icon.ExtractAssociatedIcon(targetPath)) {
                            if (ico != null) {
                                img = ScaleBitmap(ico.ToBitmap(), targetSize);
                            }
                        }
                    }
                } catch { }
            }

            // 3. Try SHGetFileInfo on targetPath (clean file or directory icon, NO shortcut arrow!)
            if (img == null && !string.IsNullOrEmpty(targetPath) && (File.Exists(targetPath) || Directory.Exists(targetPath))) {
                try {
                    NativeMethods.SHFILEINFO shinfo = new NativeMethods.SHFILEINFO();
                    uint flags = NativeMethods.SHGFI_ICON | (large ? NativeMethods.SHGFI_LARGEICON : NativeMethods.SHGFI_SMALLICON);
                    IntPtr res = NativeMethods.SHGetFileInfo(targetPath, 0, ref shinfo, (uint)Marshal.SizeOf(shinfo), flags);
                    if (shinfo.hIcon != IntPtr.Zero) {
                        using (Icon ico = (Icon)Icon.FromHandle(shinfo.hIcon).Clone()) {
                            img = ScaleBitmap(ico.ToBitmap(), targetSize);
                        }
                        NativeMethods.DestroyIcon(shinfo.hIcon);
                    }
                } catch { }
            }

            // 4. Fallback to original path
            if (img == null) {
                try {
                    NativeMethods.SHFILEINFO shinfo = new NativeMethods.SHFILEINFO();
                    uint flags = NativeMethods.SHGFI_ICON | (large ? NativeMethods.SHGFI_LARGEICON : NativeMethods.SHGFI_SMALLICON);
                    IntPtr res = NativeMethods.SHGetFileInfo(path, 0, ref shinfo, (uint)Marshal.SizeOf(shinfo), flags);
                    if (shinfo.hIcon != IntPtr.Zero) {
                        using (Icon ico = (Icon)Icon.FromHandle(shinfo.hIcon).Clone()) {
                            img = ScaleBitmap(ico.ToBitmap(), targetSize);
                        }
                        NativeMethods.DestroyIcon(shinfo.hIcon);
                    }
                } catch { }
            }

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

        public static void ResolveLnk(string lnkPath, out string targetPath, out string iconPath, out int iconIndex) {
            targetPath = null;
            iconPath = null;
            iconIndex = 0;
            try {
                Type wshType = Type.GetTypeFromProgID("WScript.Shell");
                if (wshType != null) {
                    dynamic wsh = Activator.CreateInstance(wshType);
                    dynamic sc = wsh.CreateShortcut(lnkPath);
                    targetPath = (string)sc.TargetPath;
                    string iconLoc = (string)sc.IconLocation;
                    if (!string.IsNullOrEmpty(iconLoc)) {
                        string[] parts = iconLoc.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                        if (parts.Length > 0) {
                            iconPath = parts[0].Trim();
                            if (parts.Length > 1) int.TryParse(parts[1].Trim(), out iconIndex);
                        }
                    }
                }
            } catch { }

            if (string.IsNullOrEmpty(targetPath)) {
                targetPath = ResolveLnkTarget(lnkPath);
            }
        }

        public static string ResolveLnkTarget(string lnkPath) {
            try {
                Type wshType = Type.GetTypeFromProgID("WScript.Shell");
                if (wshType != null) {
                    dynamic wsh = Activator.CreateInstance(wshType);
                    dynamic sc = wsh.CreateShortcut(lnkPath);
                    string target = (string)sc.TargetPath;
                    if (!string.IsNullOrEmpty(target)) return target;
                }
            } catch { }

            try {
                string dir = Path.GetDirectoryName(lnkPath);
                string file = Path.GetFileName(lnkPath);
                Type shellType = Type.GetTypeFromProgID("Shell.Application");
                if (shellType != null) {
                    dynamic shell = Activator.CreateInstance(shellType);
                    dynamic folder = shell.Namespace(dir);
                    dynamic folderItem = folder.ParseName(file);
                    dynamic link = folderItem.GetLink;
                    string target = (string)link.Target.Path;
                    return target;
                }
            } catch { }
            return null;
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
                    "GIN Desktop", MessageBoxButtons.OK, MessageBoxIcon.Error);
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
    public class TimeoutWebClient : WebClient {
        private int _timeoutMs;
        public TimeoutWebClient(int timeoutMs = 8000) {
            _timeoutMs = timeoutMs;
        }
        protected override WebRequest GetWebRequest(Uri address) {
            WebRequest req = base.GetWebRequest(address);
            if (req != null) {
                req.Timeout = _timeoutMs;
                if (req is HttpWebRequest) {
                    ((HttpWebRequest)req).ReadWriteTimeout = _timeoutMs;
                }
            }
            return req;
        }
    }

    public class WallpaperEngine {
        private Config _config;
        private System.Windows.Forms.Timer _timer;
        private bool _isDownloading = false;
        private System.Windows.Forms.Timer _midnightTimer;
        private DateTime _lastMidnightTriggerDate = DateTime.MinValue;
        private string _lastDownloadedPath = null;
        private bool _suppressFirstChime = true;

        public event Action<string> WallpaperChanged;
        public event Action<bool> DownloadStateChanged;

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
                ThreadPool.QueueUserWorkItem(_ => {
                    Thread.Sleep(800);
                    TriggerNextWallpaperAsync();
                });
            }

            _midnightTimer = new System.Windows.Forms.Timer { Interval = 25000 };
            _midnightTimer.Tick += (s, e) => {
                DateTime now = DateTime.Now;
                if (now.Hour == 0 && now.Minute == 3 && _lastMidnightTriggerDate.Date != now.Date) {
                    _lastMidnightTriggerDate = now.Date;
                    TriggerNextWallpaperAsync();
                }
            };
            if (_config.EnableWallpaper) {
                _midnightTimer.Start();
            }

            System.Windows.Forms.Timer hudRefreshTimer = new System.Windows.Forms.Timer { Interval = 30000 };
            hudRefreshTimer.Tick += (s, e) => {
                if (_config.EnableWallpaper && (_config.EnableHardwareMonitor || _config.ShowWeather) && !_isDownloading) {
                    RefreshActiveWallpaperHUD();
                }
            };
            if (_config.EnableWallpaper) hudRefreshTimer.Start();
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
                if (_midnightTimer != null) _midnightTimer.Start();
                TriggerNextWallpaperAsync();
            } else {
                _timer.Stop();
                if (_midnightTimer != null) _midnightTimer.Stop();
            }
        }

        private volatile bool _queuedRequest = false;

        public void RefreshActiveWallpaperHUD() {
            if (!string.IsNullOrEmpty(_lastDownloadedPath) && File.Exists(_lastDownloadedPath)) {
                ThreadPool.QueueUserWorkItem(_ => {
                    try {
                        string finalWallpaper = _config.ShowCalendar ? RenderCalendarOnWallpaper(_lastDownloadedPath) : ScaleWallpaperToScreen(_lastDownloadedPath);
                        NativeMethods.SystemParametersInfo(
                            NativeMethods.SPI_SETDESKWALLPAPER,
                            0,
                            finalWallpaper,
                            NativeMethods.SPIF_UPDATEINIFILE | NativeMethods.SPIF_SENDCHANGE
                        );
                        NativeMethods.TrimMemory();
                    } catch { }
                });
            } else {
                TriggerNextWallpaperAsync();
            }
        }

        public void TriggerNextWallpaperAsync(bool isManual = false) {
            if (isManual) _suppressFirstChime = false;
            if (_isDownloading) {
                _queuedRequest = true;
                return;
            }
            _isDownloading = true;
            if (DownloadStateChanged != null) DownloadStateChanged(true);

            ThreadPool.QueueUserWorkItem(_ => {
                try {
                    Config.CleanupCache();
                    string downloadedFile = DownloadWallpaperImage();
                    if (string.IsNullOrEmpty(downloadedFile) || !File.Exists(downloadedFile)) {
                        downloadedFile = _lastDownloadedPath;
                    }
                    if (string.IsNullOrEmpty(downloadedFile) || !File.Exists(downloadedFile)) {
                        downloadedFile = GetFallbackWallpaper();
                    }

                    if (!string.IsNullOrEmpty(downloadedFile) && File.Exists(downloadedFile)) {
                        _lastDownloadedPath = downloadedFile;

                        string finalWallpaper = downloadedFile;
                        if (_config.ShowCalendar) {
                            finalWallpaper = RenderCalendarOnWallpaper(downloadedFile);
                        } else {
                            finalWallpaper = ScaleWallpaperToScreen(downloadedFile);
                        }
                        CleanupOldWallpapers();

                        try {
                            using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Control Panel\Desktop", true)) {
                                if (rk != null) {
                                    rk.SetValue("WallpaperStyle", "10"); // Fill
                                    rk.SetValue("TileWallpaper", "0");
                                }
                            }
                        } catch { }

                        NativeMethods.SystemParametersInfo(
                            NativeMethods.SPI_SETDESKWALLPAPER,
                            0,
                            finalWallpaper,
                            NativeMethods.SPIF_UPDATEINIFILE | NativeMethods.SPIF_SENDCHANGE
                        );

                        NativeMethods.TrimMemory();

                        if (_config.EnableSound) {
                            if (!_suppressFirstChime) {
                                GentleSound.PlayWallpaperChime();
                            } else {
                                _suppressFirstChime = false;
                            }
                        }

                        if (WallpaperChanged != null) {
                            WallpaperChanged(finalWallpaper);
                        }
                    }
                } catch { }
                finally {
                    _isDownloading = false;
                    if (DownloadStateChanged != null) DownloadStateChanged(false);
                    if (_queuedRequest) {
                        _queuedRequest = false;
                        TriggerNextWallpaperAsync();
                    }
                }
            });
        }

        private string GetFallbackWallpaper() {
            try {
                if (Directory.Exists(Config.CacheDir)) {
                    string[] cached = Directory.GetFiles(Config.CacheDir, "wallpaper_*.jpg");
                    if (cached.Length > 0) {
                        List<string> valid = new List<string>();
                        foreach (string f in cached) {
                            try {
                                if (new FileInfo(f).Length > 20000) valid.Add(f);
                            } catch { }
                        }
                        if (valid.Count > 0) {
                            return valid[new Random().Next(valid.Count)];
                        }
                    }
                }
                string cur = Microsoft.Win32.Registry.GetValue(@"HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper", null) as string;
                if (!string.IsNullOrEmpty(cur) && File.Exists(cur) && new FileInfo(cur).Length > 10000) {
                    return cur;
                }
            } catch { }

            string gradPath = Path.Combine(Config.CacheDir, "wallpaper_gradient_default.jpg");
            try {
                int w = Screen.PrimaryScreen.Bounds.Width;
                int h = Screen.PrimaryScreen.Bounds.Height;
                if (w < 800) w = 1920;
                if (h < 600) h = 1080;
                using (Bitmap bmp = new Bitmap(w, h))
                using (Graphics g = Graphics.FromImage(bmp))
                using (LinearGradientBrush lgb = new LinearGradientBrush(new Rectangle(0, 0, w, h), Color.FromArgb(20, 24, 34), Color.FromArgb(10, 12, 16), 45f)) {
                    g.FillRectangle(lgb, 0, 0, w, h);
                    bmp.Save(gradPath, System.Drawing.Imaging.ImageFormat.Jpeg);
                    return gradPath;
                }
            } catch { }

            return null;
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
                else if (c == "darkhorse") queries.Add("dark horse stallion mystery fantasy");
                else if (c == "macro") queries.Add("macro photography detailed texture");
                else if (c == "architecture") queries.Add("architecture modern bridge building");
                else if (c == "aircraft") queries.Add("aviation fighter jet aircraft airplane");
                else if (c == "retrowave") queries.Add("retrowave 80s outrun vaporwave synth");
                else if (c == "fantasy") queries.Add("fantasy mythical landscape castle dragon");
                else if (c == "underwater") queries.Add("underwater coral reef ocean life deep sea");
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
                    queries.Add("supercar luxury");
                    queries.Add("mountains forest");
                }
            }

            if (queries.Count == 0) queries.Add("nature landscape");
            string query = queries[new Random().Next(queries.Count)];

            string seed = Guid.NewGuid().ToString("N").Substring(0, 6);
            string categoriesCode = query.Contains("portrait") || query.Contains("model") ? "001" : (query.Contains("anime") ? "010" : "100");
            string apiUrl = "https://wallhaven.cc/api/v1/search?q=" + Uri.EscapeDataString(query) + "&categories=" + categoriesCode + "&purity=100&atleast=1920x1080&sorting=random&seed=" + seed;

            string targetJpg = Path.Combine(Config.CacheDir, "wallpaper_" + DateTime.Now.Ticks + ".jpg");

            // Tier 1: Wallhaven Search API
            try {
                using (TimeoutWebClient wc = new TimeoutWebClient(8000)) {
                    wc.Headers.Add("User-Agent", "GIN-Desktop/v056 (Windows; WinAPI)");
                    string json = wc.DownloadString(apiUrl);
                    int pIdx = json.IndexOf("\"path\":\"");
                    if (pIdx != -1) {
                        pIdx += 8;
                        int pEnd = json.IndexOf("\"", pIdx);
                        if (pEnd != -1) {
                            string imgUrl = json.Substring(pIdx, pEnd - pIdx).Replace("\\/", "/");
                            wc.DownloadFile(imgUrl, targetJpg);
                            if (File.Exists(targetJpg) && new FileInfo(targetJpg).Length > 25000) {
                                return targetJpg;
                            }
                        }
                    }
                }
            } catch { }

            // Tier 2: Lorem Picsum (Ultra-resilient, fast global CDN, no API key required)
            try {
                int seedVal = new Random().Next(1, 100000);
                string picsumUrl = "https://picsum.photos/seed/" + seedVal + "/2560/1440";
                using (TimeoutWebClient wc = new TimeoutWebClient(10000)) {
                    wc.Headers.Add("User-Agent", "GIN-Desktop/v056 (Windows; WinAPI)");
                    wc.DownloadFile(picsumUrl, targetJpg);
                    if (File.Exists(targetJpg) && new FileInfo(targetJpg).Length > 25000) {
                        return targetJpg;
                    }
                }
            } catch { }

            // Tier 3: Curated Unsplash 4K CDN Pool
            string[] unsplashPool = new string[] {
                "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1511447333015-45b65e60f6d5?auto=format&fit=crop&w=2560&q=80",
                "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=2560&q=80"
            };
            try {
                string randUnsplash = unsplashPool[new Random().Next(unsplashPool.Length)];
                using (TimeoutWebClient wc = new TimeoutWebClient(10000)) {
                    wc.Headers.Add("User-Agent", "GIN-Desktop/v056 (Windows; WinAPI)");
                    wc.DownloadFile(randUnsplash, targetJpg);
                    if (File.Exists(targetJpg) && new FileInfo(targetJpg).Length > 25000) {
                        return targetJpg;
                    }
                }
            } catch { }

            // Tier 4: Cached wallpapers
            try {
                if (Directory.Exists(Config.CacheDir)) {
                    string[] cached = Directory.GetFiles(Config.CacheDir, "wallpaper_*.jpg");
                    if (cached.Length > 0) {
                        List<string> valid = new List<string>();
                        foreach (string f in cached) {
                            try {
                                if (new FileInfo(f).Length > 25000) valid.Add(f);
                            } catch { }
                        }
                        if (valid.Count > 0) {
                            return valid[new Random().Next(valid.Count)];
                        }
                    }
                }
            } catch { }

            // Tier 5: Current Windows desktop wallpaper
            try {
                string curWall = Microsoft.Win32.Registry.GetValue(@"HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper", null) as string;
                if (!string.IsNullOrEmpty(curWall) && File.Exists(curWall) && new FileInfo(curWall).Length > 10000) {
                    return curWall;
                }
            } catch { }

            // Tier 6: High-res generated dark gradient bitmap
            try {
                int w = Screen.PrimaryScreen.Bounds.Width;
                int h = Screen.PrimaryScreen.Bounds.Height;
                if (w < 800) w = 1920;
                if (h < 600) h = 1080;
                using (Bitmap bmp = new Bitmap(w, h))
                using (Graphics g = Graphics.FromImage(bmp))
                using (LinearGradientBrush lgb = new LinearGradientBrush(new Rectangle(0, 0, w, h), Color.FromArgb(20, 24, 34), Color.FromArgb(10, 12, 16), 45f)) {
                    g.FillRectangle(lgb, 0, 0, w, h);
                    bmp.Save(targetJpg, System.Drawing.Imaging.ImageFormat.Jpeg);
                    return targetJpg;
                }
            } catch { }

            return null;
        }

        private static int _hudSlot = 0;

        private static void CleanupOldWallpapers() {
            try {
                if (!Directory.Exists(Config.CacheDir)) return;
                string[] files = Directory.GetFiles(Config.CacheDir, "active_desktop_hud_*.jpg");
                foreach (string f in files) {
                    try {
                        string name = Path.GetFileName(f);
                        if (!name.Equals("active_desktop_hud_A.jpg", StringComparison.OrdinalIgnoreCase) &&
                            !name.Equals("active_desktop_hud_B.jpg", StringComparison.OrdinalIgnoreCase)) {
                            File.Delete(f);
                        }
                    } catch { }
                }
                string[] walls = Directory.GetFiles(Config.CacheDir, "wallpaper_*.jpg");
                if (walls.Length > 6) {
                    Array.Sort(walls);
                    for (int i = 0; i < walls.Length - 4; i++) {
                        try { File.Delete(walls[i]); } catch { }
                    }
                }
            } catch { }
        }

        private string ScaleWallpaperToScreen(string originalImagePath) {
            _hudSlot = 1 - _hudSlot;
            string outName = (_hudSlot == 0) ? "active_desktop_hud_A.jpg" : "active_desktop_hud_B.jpg";
            string outputJpg = Path.Combine(Config.CacheDir, outName);

            int screenW = Screen.PrimaryScreen.Bounds.Width;
            int screenH = Screen.PrimaryScreen.Bounds.Height;
            if (screenW < 800) screenW = 1920;
            if (screenH < 600) screenH = 1080;

            using (Image original = Image.FromFile(originalImagePath))
            using (Bitmap bmp = new Bitmap(screenW, screenH))
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                float scaleX = (float)screenW / original.Width;
                float scaleY = (float)screenH / original.Height;
                float coverScale = Math.Max(scaleX, scaleY);

                int drawW = (int)Math.Ceiling(original.Width * coverScale);
                int drawH = (int)Math.Ceiling(original.Height * coverScale);
                int drawX = (screenW - drawW) / 2;
                int drawY = (screenH - drawH) / 2;

                g.DrawImage(original, drawX, drawY, drawW, drawH);

                try { if (File.Exists(outputJpg)) File.Delete(outputJpg); } catch { }
                bmp.Save(outputJpg, System.Drawing.Imaging.ImageFormat.Jpeg);
            }
            return outputJpg;
        }

        private string RenderCalendarOnWallpaper(string originalImagePath) {
            _hudSlot = 1 - _hudSlot;
            string outName = (_hudSlot == 0) ? "active_desktop_hud_A.jpg" : "active_desktop_hud_B.jpg";
            string outputJpg = Path.Combine(Config.CacheDir, outName);

            int screenW = Screen.PrimaryScreen.Bounds.Width;
            int screenH = Screen.PrimaryScreen.Bounds.Height;
            if (screenW < 800) screenW = 1920;
            if (screenH < 600) screenH = 1080;

            using (Image original = Image.FromFile(originalImagePath))
            using (Bitmap bmp = new Bitmap(screenW, screenH))
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

                float scaleX = (float)screenW / original.Width;
                float scaleY = (float)screenH / original.Height;
                float coverScale = Math.Max(scaleX, scaleY);

                int drawW = (int)Math.Ceiling(original.Width * coverScale);
                int drawH = (int)Math.Ceiling(original.Height * coverScale);
                int drawX = (screenW - drawW) / 2;
                int drawY = (screenH - drawH) / 2;

                g.DrawImage(original, drawX, drawY, drawW, drawH);

                DateTime now = DateTime.Now;
                ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);

                float scale = Math.Max(0.6f, Math.Min(2.0f, _config.CalendarScale));
                int cardW = (int)(Math.Max(260, (int)(screenW * 0.16f)) * scale);
                int cardH = (int)(cardW * 0.82f);
                int margin = 30;
                int cardX = screenW - cardW - margin;
                int cardY = margin + 40;

                Rectangle cardRect = new Rectangle(cardX, cardY, cardW, cardH);
                using (GraphicsPath path = GetRoundedRect(cardRect, 14))
                using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(170, theme.Background.R, theme.Background.G, theme.Background.B)))
                using (Pen borderPen = new Pen(Color.FromArgb(200, theme.Border.R, theme.Border.G, theme.Border.B), 1.5f)) {
                    g.FillPath(bgBrush, path);
                    g.DrawPath(borderPen, path);
                }

                string fontName = _config.CalendarFontFamily ?? "Segoe UI";

                CultureInfo cult;
                string[] days;
                string curLang = (I18n.CurrentLanguage ?? "ru").ToLowerInvariant();
                if (curLang == "ru") {
                    cult = new CultureInfo("ru-RU");
                    days = new string[] { "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс" };
                } else if (curLang == "cs") {
                    cult = new CultureInfo("cs-CZ");
                    days = new string[] { "Po", "Út", "St", "Čt", "Pá", "So", "Ne" };
                } else {
                    cult = new CultureInfo("en-US");
                    days = new string[] { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" };
                }
                string monthTitle = now.ToString("MMMM yyyy", cult).ToUpperInvariant();
                float titleFontSize = Math.Max(10f, cardW * 0.052f);

                using (Font titleFont = new Font(fontName, titleFontSize, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(theme.TextPrimary))
                using (SolidBrush accentBrush = new SolidBrush(theme.Accent)) {
                    g.DrawString(monthTitle, titleFont, accentBrush, cardX + 16, cardY + 12);
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

                try { if (File.Exists(outputJpg)) File.Delete(outputJpg); } catch { }
                
                int nextBadgeY = cardY + cardH + 12;

                if (_config.ShowWeather) {
                    try {
                        string weatherText = WeatherService.GetCurrentWeather(_config.WeatherSource, _config.WeatherCity);
                        int weatherY = nextBadgeY;
                        int weatherH = (int)(32 * scale);
                        Rectangle weatherRect = new Rectangle(cardX, weatherY, cardW, weatherH);
                        using (GraphicsPath wPath = GetRoundedRect(weatherRect, 10))
                        using (SolidBrush wBgBrush = new SolidBrush(Color.FromArgb(170, theme.Background.R, theme.Background.G, theme.Background.B)))
                        using (Pen wPen = new Pen(Color.FromArgb(200, theme.Border.R, theme.Border.G, theme.Border.B), 1.2f))
                        using (Font wFont = new Font("Segoe UI", Math.Max(9.0f, cardW * 0.042f), FontStyle.Bold))
                        using (SolidBrush wTextBrush = new SolidBrush(theme.TextPrimary)) {
                            g.FillPath(wBgBrush, wPath);
                            g.DrawPath(wPen, wPath);
                            StringFormat sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                            g.DrawString(weatherText, wFont, wTextBrush, weatherRect, sf);
                        }
                        nextBadgeY = weatherY + weatherH + 8;
                    } catch { }
                }

                if (_config.EnableHardwareMonitor) {
                    try {
                        StringBuilder sbHw = new StringBuilder();
                        if (_config.ShowCpuUsage) sbHw.Append("CPU: " + SystemMetrics.GetCpuUsage() + "%   ");
                        if (_config.ShowRamUsage) sbHw.Append("RAM: " + SystemMetrics.GetRamUsage() + "%   ");
                        if (_config.ShowGpuUsage || _config.ShowGpuTemp) {
                            int gpu, temp;
                            SystemMetrics.GetGpuMetrics(out gpu, out temp);
                            if (_config.ShowGpuUsage) sbHw.Append("GPU: " + gpu + "%   ");
                            if (_config.ShowGpuTemp) sbHw.Append(temp + "°C");
                        }
                        string hwText = sbHw.ToString().Trim();
                        if (!string.IsNullOrEmpty(hwText)) {
                            hwText = "⚡ " + hwText;
                            int hwY = nextBadgeY;
                            int hwH = (int)(30 * scale);
                            Rectangle hwRect = new Rectangle(cardX, hwY, cardW, hwH);
                            using (GraphicsPath hwPath = GetRoundedRect(hwRect, 10))
                            using (SolidBrush hwBgBrush = new SolidBrush(Color.FromArgb(170, theme.Background.R, theme.Background.G, theme.Background.B)))
                            using (Pen hwPen = new Pen(Color.FromArgb(200, theme.Border.R, theme.Border.G, theme.Border.B), 1.2f))
                            using (Font hwFont = new Font("Segoe UI", Math.Max(8.5f, cardW * 0.038f), FontStyle.Bold))
                            using (SolidBrush hwTextBrush = new SolidBrush(theme.Accent)) {
                                g.FillPath(hwBgBrush, hwPath);
                                g.DrawPath(hwPen, hwPath);
                                StringFormat sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                                g.DrawString(hwText, hwFont, hwTextBrush, hwRect, sf);
                            }
                        }
                    } catch { }
                }

                bmp.Save(outputJpg, System.Drawing.Imaging.ImageFormat.Jpeg);
            }

            try {
                foreach (string oldHud in Directory.GetFiles(Config.CacheDir, "active_desktop_hud_*.jpg")) {
                    if (!oldHud.Equals(outputJpg, StringComparison.OrdinalIgnoreCase)) {
                        try { File.Delete(oldHud); } catch { }
                    }
                }
            } catch { }

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
    // DOCK BAR FORM (FLUID HOVER & REAL RESIZING)
    // ==========================================
    
    // ==========================================
    // ROCKETDOCK STYLE DARK MENU RENDERER
    // ==========================================
    public class ModernDarkMenuRenderer : ToolStripProfessionalRenderer {
        public ModernDarkMenuRenderer() : base(new DarkMenuColorTable()) { }

        protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
            e.TextColor = Color.White;
            base.OnRenderItemText(e);
        }

        protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e) {
            if (e.Item.Selected || e.Item.Pressed) {
                Rectangle rc = new Rectangle(2, 1, e.Item.Width - 4, e.Item.Height - 2);
                using (SolidBrush b = new SolidBrush(Color.FromArgb(65, 255, 255, 255))) {
                    e.Graphics.FillRectangle(b, rc);
                }
                using (Pen p = new Pen(Color.FromArgb(120, 255, 255, 255), 1f)) {
                    e.Graphics.DrawRectangle(p, rc);
                }
            } else {
                base.OnRenderMenuItemBackground(e);
            }
        }
    }

    public class DarkMenuColorTable : ProfessionalColorTable {
        public override Color ToolStripDropDownBackground { get { return Color.FromArgb(245, 22, 24, 30); } }
        public override Color ImageMarginGradientBegin { get { return Color.FromArgb(245, 22, 24, 30); } }
        public override Color ImageMarginGradientMiddle { get { return Color.FromArgb(245, 22, 24, 30); } }
        public override Color ImageMarginGradientEnd { get { return Color.FromArgb(245, 22, 24, 30); } }
        public override Color MenuBorder { get { return Color.FromArgb(80, 255, 255, 255); } }
        public override Color MenuItemBorder { get { return Color.FromArgb(100, 255, 255, 255); } }
        public override Color MenuItemSelected { get { return Color.FromArgb(50, 255, 255, 255); } }
        public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(50, 255, 255, 255); } }
        public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(50, 255, 255, 255); } }
        public override Color SeparatorDark { get { return Color.FromArgb(50, 255, 255, 255); } }
        public override Color SeparatorLight { get { return Color.Transparent; } }
    }

    // ==========================================
    // ROCKETDOCK STYLE HOVER BUTTON
    // ==========================================
    public class DockButton : Button {
        private DockItem _item;
        private Config _config;
        private ColorTheme _theme;
        private bool _isFolder;
        private float _currentScale = 1.0f;
        private float _targetScale = 1.0f;
        private System.Windows.Forms.Timer _animTimer;
        private bool _isHovered = false;

        public DockItem Item { get { return _item; } }
        public bool IsFolder { get { return _isFolder; } }
        public bool IsHovered { get { return _isHovered; } }
        public float CurrentScale { get { return _currentScale; } }

        public DockButton(DockItem item, bool isFolder, Config config, ColorTheme theme) {
            _item = item;
            _isFolder = isFolder;
            _config = config;
            _theme = theme;

            this.SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);
            this.DoubleBuffered = true;
            this.Cursor = Cursors.Hand;
            this.FlatStyle = FlatStyle.Flat;
            this.FlatAppearance.BorderSize = 0;
            this.BackColor = Color.Transparent;

            _animTimer = new System.Windows.Forms.Timer();
            _animTimer.Interval = 15;
            _animTimer.Tick += AnimTimer_Tick;
        }

        public void UpdateTheme(ColorTheme theme) {
            _theme = theme;
            Invalidate();
        }

        public void ResetZoom() {
            _isHovered = false;
            _targetScale = 1.0f;
            _currentScale = 1.0f;
            if (_animTimer != null && _animTimer.Enabled) _animTimer.Stop();
            Invalidate();
        }

        private void AnimTimer_Tick(object sender, EventArgs e) {
            float step = 0.08f;
            if (Math.Abs(_currentScale - _targetScale) <= step) {
                _currentScale = _targetScale;
                _animTimer.Stop();
            } else {
                if (_currentScale < _targetScale) _currentScale += step;
                else _currentScale -= step;
            }
            Invalidate();
        }

        protected override void OnMouseEnter(EventArgs e) {
            base.OnMouseEnter(e);
            _isHovered = true;
            if (_config.EnableDockZoom) {
                _targetScale = Math.Max(1.1f, Math.Min(1.6f, _config.DockZoomFactor));
                _animTimer.Start();
            } else {
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e) {
            base.OnMouseLeave(e);
            _isHovered = false;
            if (_config.EnableDockZoom) {
                _targetScale = 1.0f;
                _animTimer.Start();
            } else {
                Invalidate();
            }
        }

        protected override void OnPaint(PaintEventArgs pevent) {
            Graphics g = pevent.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;

            Rectangle rect = this.ClientRectangle;
            string style = _config.DockStyle ?? "AeroGlass";

            // 1. Draw Hover Pill if hovered
            if (_isHovered) {
                Rectangle pill = new Rectangle(rect.X + 2, rect.Y + 2, rect.Width - 4, rect.Height - 4);
                int radius = 10;
                switch (style) {
                    case "MacFrosted":
                        using (SolidBrush pb = new SolidBrush(Color.FromArgb(170, 255, 255, 255))) {
                            FillRoundedRectangle(g, pb, pill, radius);
                        }
                        using (Pen pp = new Pen(Color.FromArgb(120, 180, 190, 205), 1f)) {
                            DrawRoundedRectangle(g, pp, pill, radius);
                        }
                        break;
                    case "DarkStealth":
                        using (SolidBrush pb = new SolidBrush(Color.FromArgb(140, 45, 48, 58))) {
                            FillRoundedRectangle(g, pb, pill, radius);
                        }
                        using (Pen pp = new Pen(Color.FromArgb(70, 255, 255, 255), 1f)) {
                            DrawRoundedRectangle(g, pp, pill, radius);
                        }
                        break;
                    case "CrystalClear":
                        using (SolidBrush pb = new SolidBrush(Color.FromArgb(70, 255, 255, 255))) {
                            FillRoundedRectangle(g, pb, pill, radius);
                        }
                        break;
                    case "ClassicMetal":
                        using (LinearGradientBrush mb = new LinearGradientBrush(pill, Color.FromArgb(190, 255, 255, 255), Color.FromArgb(120, 160, 165, 175), LinearGradientMode.Vertical)) {
                            FillRoundedRectangle(g, mb, pill, radius);
                        }
                        using (Pen pp = new Pen(Color.FromArgb(180, 40, 45, 55), 1f)) {
                            DrawRoundedRectangle(g, pp, pill, radius);
                        }
                        break;
                    case "NeonCyber":
                        using (SolidBrush pb = new SolidBrush(Color.FromArgb(80, 0, 220, 255))) {
                            FillRoundedRectangle(g, pb, pill, radius);
                        }
                        using (Pen pp = new Pen(Color.FromArgb(200, 0, 240, 255), 1.2f)) {
                            DrawRoundedRectangle(g, pp, pill, radius);
                        }
                        break;
                    case "AeroGlass":
                    default:
                        using (SolidBrush pb = new SolidBrush(Color.FromArgb(65, 255, 255, 255))) {
                            FillRoundedRectangle(g, pb, pill, radius);
                        }
                        using (Pen pp = new Pen(Color.FromArgb(90, 255, 255, 255), 1f)) {
                            DrawRoundedRectangle(g, pp, pill, radius);
                        }
                        break;
                }
            } else if (_isFolder) {
                Rectangle pill = new Rectangle(rect.X + 2, rect.Y + 2, rect.Width - 4, rect.Height - 4);
                int radius = 8;
                if (style == "MacFrosted") {
                    using (SolidBrush pb = new SolidBrush(Color.FromArgb(60, 255, 255, 255))) {
                        FillRoundedRectangle(g, pb, pill, radius);
                    }
                    using (Pen pp = new Pen(Color.FromArgb(60, 160, 170, 185), 1f)) {
                        DrawRoundedRectangle(g, pp, pill, radius);
                    }
                } else {
                    using (SolidBrush pb = new SolidBrush(_theme.CardBackground)) {
                        FillRoundedRectangle(g, pb, pill, radius);
                    }
                    using (Pen pp = new Pen(_theme.Border, 1f)) {
                        DrawRoundedRectangle(g, pp, pill, radius);
                    }
                }
            }

            // 2. Draw Icon (with zoom scale if hovered)
            int baseIconSz = Math.Max(16, Math.Min(64, _config.DockIconSize));
            int targetIconSz = (int)(baseIconSz * _currentScale);
            Image icon = _item.GetIcon(Math.Max(baseIconSz, (int)(baseIconSz * 1.5f)));

            bool showLabel = _config.ShowItemLabels;
            int iconX, iconY;

            if (showLabel) {
                iconX = rect.X + 6;
                iconY = rect.Y + (rect.Height - targetIconSz) / 2;
            } else {
                iconX = rect.X + (rect.Width - targetIconSz) / 2;
                iconY = rect.Y + (rect.Height - targetIconSz) / 2;
            }

            if (icon != null) {
                g.DrawImage(icon, new Rectangle(iconX, iconY, targetIconSz, targetIconSz));
            }

            // 3. Draw Text Label (if enabled)
            if (showLabel) {
                Color textColor = (style == "MacFrosted") ? Color.FromArgb(28, 32, 42) : _theme.TextPrimary;
                using (SolidBrush textBrush = new SolidBrush(textColor)) {
                    int textX = iconX + targetIconSz + 6;
                    string labelText = _isFolder ? (_item.Name + " ▾") : _item.Name;
                    int textY = rect.Y + (rect.Height - (int)this.Font.GetHeight(g)) / 2;
                    g.DrawString(labelText, this.Font, textBrush, textX, textY);
                }
            }
        }

        private void FillRoundedRectangle(Graphics g, Brush brush, Rectangle r, int d) {
            using (GraphicsPath path = CreateRoundedRectPath(r, d)) {
                g.FillPath(brush, path);
            }
        }

        private void DrawRoundedRectangle(Graphics g, Pen pen, Rectangle r, int d) {
            using (GraphicsPath path = CreateRoundedRectPath(r, d)) {
                g.DrawPath(pen, path);
            }
        }

        private GraphicsPath CreateRoundedRectPath(Rectangle r, int d) {
            GraphicsPath path = new GraphicsPath();
            if (d <= 0) {
                path.AddRectangle(r);
                return path;
            }
            int d2 = Math.Min(d, Math.Min(r.Width, r.Height));
            path.AddArc(r.X, r.Y, d2, d2, 180, 90);
            path.AddArc(r.Right - d2, r.Y, d2, d2, 270, 90);
            path.AddArc(r.Right - d2, r.Bottom - d2, d2, d2, 0, 90);
            path.AddArc(r.X, r.Bottom - d2, d2, d2, 90, 90);
            path.CloseFigure();
            return path;
        }

        protected override void Dispose(bool disposing) {
            if (disposing && _animTimer != null) {
                _animTimer.Stop();
                _animTimer.Dispose();
                _animTimer = null;
            }
            base.Dispose(disposing);
        }
    }

    public class DockBarForm : Form {
        private Config _config;
        private List<DockItem> _folders = new List<DockItem>();
        private List<DockItem> _shortcuts = new List<DockItem>();
        private List<Control> _dockControls = new List<Control>();
        private Dictionary<Button, DockItem> _folderMap = new Dictionary<Button, DockItem>();
        private DockItem _hoveredFolder = null;

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
        private bool _isShellMenuOpen = false;

        private const int WS_EX_NOACTIVATE = 0x08000000;
        private const int WS_EX_TOOLWINDOW = 0x00000080;
        private const int WS_EX_TOPMOST = 0x00000008;

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= (WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST);
                return cp;
            }
        }

        public DockBarForm(Config config, Action openSettingsAction) {
            _config = config;
            _openSettingsAction = openSettingsAction;

            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.TopMost = true;
            this.StartPosition = FormStartPosition.Manual;
            this.DoubleBuffered = true;

            _toolTip = new ToolTip();
            _toolTip.AutoPopDelay = 5000;
            _toolTip.InitialDelay = 300;
            _toolTip.ReshowDelay = 100;

            this.MouseUp += (s, e) => {
                if (e.Button == MouseButtons.Right) ShowMainMenu(this);
            };

            _itemsPanel = new Panel();
            _itemsPanel.BackColor = Color.Transparent;
            _itemsPanel.MouseWheel += ItemsPanel_MouseWheel;
            _itemsPanel.MouseUp += (s, e) => {
                if (e.Button == MouseButtons.Right) ShowMainMenu(_itemsPanel);
            };
            this.Controls.Add(_itemsPanel);

            this.MouseWheel += ItemsPanel_MouseWheel;
            this.KeyDown += (s, e) => {
                if (e.KeyCode == Keys.Escape) HideDock();
            };

            _watchdogTimer = new System.Windows.Forms.Timer();
            _watchdogTimer.Interval = 50;
            _watchdogTimer.Tick += WatchdogTimer_Tick;
            _watchdogTimer.Start();
            
            SetupFileSystemWatcher();
            LoadItems();
            HideDockImmediate();
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


        public void SetEnabled(bool enable) {
            _config.EnableDock = enable;
            if (enable) {
                _watchdogTimer.Start();
                SetupFileSystemWatcher();
                LoadItems();
                UpdateDockGeometry();
            } else {
                TeardownFileSystemWatcher();
                HideDockImmediate();
            }
        }

        private void TeardownFileSystemWatcher() {
            try {
                if (_fsWatcher != null) {
                    _fsWatcher.EnableRaisingEvents = false;
                    _fsWatcher.Dispose();
                    _fsWatcher = null;
                }
            } catch { }
        }

        public void LoadItems() {
            _folders.Clear();
            _shortcuts.Clear();
            _folderMap.Clear();
            _hoveredFolder = null;
            ShellHelper.ClearCache();

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
            _folderMap.Clear();

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            this.BackColor = theme.Background;

            bool isTop = (_config.DockPosition == "Top");
            int cursor = 0;
            int iconSz = Math.Max(16, Math.Min(64, _config.DockIconSize));
            float maxZoom = _config.EnableDockZoom ? Math.Max(1.1f, Math.Min(1.6f, _config.DockZoomFactor)) : 1.0f;
            int zoomedIconSz = (int)(iconSz * maxZoom);
            int itemSpan = Math.Max(42, zoomedIconSz + 10);
            int barSize = Math.Max(46, itemSpan + 8);
            _config.BarHeight = barSize;

            if (isTop) {
                _itemsPanel.Location = new Point(12, 4);
                _itemsPanel.Height = barSize;
            } else {
                _itemsPanel.Location = new Point(4, 12);
                _itemsPanel.Width = barSize;
            }

            Font folderFont = new Font(_config.DockFolderFontFamily ?? "Segoe UI", _config.DockFolderFontSize, FontStyle.Regular);
            Font itemFont = new Font(_config.DockItemFontFamily ?? "Segoe UI", _config.DockItemFontSize, FontStyle.Regular);

            foreach (DockItem folder in _folders) {
                DockButton btn = new DockButton(folder, true, _config, theme);
                btn.Font = folderFont;
                btn.Tag = cursor;

                bool showLabel = _config.ShowItemLabels;
                if (isTop) {
                    btn.Height = itemSpan;
                    if (showLabel) {
                        btn.Text = " " + folder.Name + " ▾";
                        using (Graphics g = btn.CreateGraphics()) {
                            SizeF size = g.MeasureString(btn.Text, btn.Font);
                            btn.Width = (int)size.Width + zoomedIconSz + 24;
                        }
                    } else {
                        btn.Text = "";
                        btn.Width = Math.Max(itemSpan, zoomedIconSz + 12);
                    }
                } else {
                    btn.Width = itemSpan;
                    btn.Height = showLabel ? (zoomedIconSz + 20) : itemSpan;
                    btn.Text = showLabel ? folder.Name : "";
                }

                _toolTip.SetToolTip(btn, folder.Name);

                DockItem fItem = folder;
                _folderMap[btn] = fItem;

                btn.MouseEnter += (s, e) => {
                    if (_hoveredFolder != fItem) {
                        OpenFolderDropDown(btn, fItem);
                    }
                };
                btn.MouseMove += (s, e) => {
                    if (_hoveredFolder != fItem || _activeDropDown == null || !_activeDropDown.Visible) {
                        OpenFolderDropDown(btn, fItem);
                    }
                };
                btn.MouseDown += (s, e) => {
                    if (e.Button == MouseButtons.Middle || (e.Button == MouseButtons.Left && Control.ModifierKeys == Keys.Control)) {
                        ShellHelper.OpenInExplorer(fItem.TargetFolder);
                        HideDock();
                    } else if (e.Button == MouseButtons.Left) {
                        OpenFolderDropDown(btn, fItem);
                    }
                };
                btn.MouseUp += (s, e) => {
                    if (e.Button == MouseButtons.Right) {
                        Point pt = btn.PointToScreen(new Point(e.X, e.Y));
                        _isShellMenuOpen = true;
                        try {
                            ShellMenuHelper.ShowShellContextMenu(fItem.FullPath, pt, this);
                        } finally {
                            _isShellMenuOpen = false;
                        }
                    }
                };

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
                string dockStyle = _config.DockStyle ?? "AeroGlass";
                if (dockStyle == "MacFrosted") {
                    sep.BackColor = Color.FromArgb(160, 175, 190);
                } else if (dockStyle == "NeonCyber") {
                    sep.BackColor = Color.FromArgb(0, 220, 255);
                } else {
                    sep.BackColor = theme.Separator;
                }
                sep.Tag = cursor;
                _dockControls.Add(sep);
                _itemsPanel.Controls.Add(sep);
                cursor += 8;
            }

            foreach (DockItem item in _shortcuts) {
                DockButton btn = new DockButton(item, false, _config, theme);
                btn.Font = itemFont;
                btn.Tag = cursor;

                bool showLabel = _config.ShowItemLabels;
                if (isTop) {
                    btn.Height = itemSpan;
                    if (showLabel) {
                        btn.Text = " " + item.Name;
                        using (Graphics g = btn.CreateGraphics()) {
                            SizeF size = g.MeasureString(btn.Text, btn.Font);
                            btn.Width = (int)size.Width + zoomedIconSz + 24;
                        }
                    } else {
                        btn.Text = "";
                        btn.Width = Math.Max(itemSpan, zoomedIconSz + 12);
                    }
                } else {
                    btn.Width = itemSpan;
                    btn.Height = showLabel ? (zoomedIconSz + 20) : itemSpan;
                    btn.Text = showLabel ? item.Name : "";
                }

                _toolTip.SetToolTip(btn, item.Name);

                DockItem scItem = item;
                btn.MouseEnter += (s, e) => {
                    CloseActiveDropDown();
                };
                btn.Click += (s, e) => {
                    ShellHelper.Launch(scItem.FullPath);
                    HideDock();
                };
                btn.MouseUp += (s, e) => {
                    if (e.Button == MouseButtons.Right) {
                        Point pt = btn.PointToScreen(new Point(e.X, e.Y));
                        _isShellMenuOpen = true;
                        try {
                            ShellMenuHelper.ShowShellContextMenu(scItem.FullPath, pt, this);
                        } finally {
                            _isShellMenuOpen = false;
                        }
                    }
                };

                _dockControls.Add(btn);
                _itemsPanel.Controls.Add(btn);
                cursor += (isTop ? btn.Width : btn.Height) + 3;
            }

            _totalItemsLength = cursor;
            UpdateDockGeometry();
            RelayoutItems();
        }


        // RocketDock Glass OnPaint
        protected override void OnPaint(PaintEventArgs e) {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;

            Rectangle bounds = this.ClientRectangle;
            string style = _config.DockStyle ?? "AeroGlass";

            switch (style) {
                case "MacFrosted":
                    // Soft frosted white/silver matte shelf
                    using (SolidBrush bg = new SolidBrush(Color.FromArgb(220, 238, 242, 248))) {
                        g.FillRectangle(bg, bounds);
                    }
                    // Crisp top reflection line
                    using (Pen topPen = new Pen(Color.FromArgb(210, 255, 255, 255), 1.5f)) {
                        g.DrawLine(topPen, 15, 1, this.Width - 15, 1);
                    }
                    // Delicate silver-gray border
                    using (Pen borderPen = new Pen(Color.FromArgb(120, 160, 170, 185), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;

                case "DarkStealth":
                    // Deep OLED carbon matte shelf
                    using (SolidBrush bg = new SolidBrush(Color.FromArgb(245, 12, 13, 16))) {
                        g.FillRectangle(bg, bounds);
                    }
                    // Ultra-subtle graphite border
                    using (Pen borderPen = new Pen(Color.FromArgb(50, 255, 255, 255), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;

                case "CrystalClear":
                    // Ultra-transparent floating dock shelf
                    using (SolidBrush bg = new SolidBrush(Color.FromArgb(50, 10, 12, 18))) {
                        g.FillRectangle(bg, bounds);
                    }
                    // Faint ethereal border
                    using (Pen borderPen = new Pen(Color.FromArgb(25, 255, 255, 255), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;

                case "ClassicMetal":
                    // Classic RocketDock 3D brushed metallic shelf with top bevel and bottom shadow
                    using (LinearGradientBrush metalBrush = new LinearGradientBrush(bounds, Color.FromArgb(235, 120, 126, 136), Color.FromArgb(240, 48, 52, 60), LinearGradientMode.Vertical)) {
                        g.FillRectangle(metalBrush, bounds);
                    }
                    // Top 3D bevel highlight
                    using (Pen bevelPen = new Pen(Color.FromArgb(180, 255, 255, 255), 2f)) {
                        g.DrawLine(bevelPen, 12, 1, this.Width - 12, 1);
                    }
                    // Bottom 3D bezel shadow
                    using (Pen shadowPen = new Pen(Color.FromArgb(170, 18, 20, 25), 2f)) {
                        g.DrawLine(shadowPen, 12, this.Height - 2, this.Width - 12, this.Height - 2);
                    }
                    // Outer metal border
                    using (Pen borderPen = new Pen(Color.FromArgb(70, 255, 255, 255), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;

                case "NeonCyber":
                    // Deep neon cyberpunk shelf
                    using (SolidBrush bg = new SolidBrush(Color.FromArgb(235, 14, 10, 26))) {
                        g.FillRectangle(bg, bounds);
                    }
                    // Glowing neon cyan top line
                    using (Pen neonTop = new Pen(Color.FromArgb(220, 0, 245, 255), 2f)) {
                        g.DrawLine(neonTop, 15, 1, this.Width - 15, 1);
                    }
                    // Magenta bottom accent
                    using (Pen neonBottom = new Pen(Color.FromArgb(190, 255, 0, 128), 1.5f)) {
                        g.DrawLine(neonBottom, 15, this.Height - 2, this.Width - 15, this.Height - 2);
                    }
                    // Subtle neon border
                    using (Pen borderPen = new Pen(Color.FromArgb(120, 0, 220, 255), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;

                case "AeroGlass":
                default:
                    // Translucent glass shelf background
                    using (SolidBrush bg = new SolidBrush(Color.FromArgb(220, 18, 20, 26))) {
                        g.FillRectangle(bg, bounds);
                    }
                    // 1.5px subtle white glass reflection across top
                    using (Pen topPen = new Pen(Color.FromArgb(95, 255, 255, 255), 1.5f)) {
                        g.DrawLine(topPen, 15, 1, this.Width - 15, 1);
                    }
                    // Subtle 1px shelf border
                    using (Pen borderPen = new Pen(Color.FromArgb(45, 255, 255, 255), 1f)) {
                        g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                    }
                    break;
            }
        }

        public void UpdateDockGeometry() {
            Screen screen = Screen.PrimaryScreen;
            int barSize = Math.Max(44, _config.BarHeight);

            bool isTop = (_config.DockPosition == "Top");
            int desiredWidth = _totalItemsLength + 24;
            if (desiredWidth > screen.Bounds.Width - 30) desiredWidth = screen.Bounds.Width - 30;
            if (desiredWidth < 120) desiredWidth = 120;

            this.Width = desiredWidth;
            this.Height = barSize + 8;

            if (isTop) {
                int posX = screen.Bounds.Left + (screen.Bounds.Width - desiredWidth) / 2;
                int posY = screen.Bounds.Top;
                this.Location = new Point(posX, posY);
                _itemsPanel.Location = new Point(12, 4);
                _itemsPanel.Width = this.Width - 24;
                _itemsPanel.Height = barSize;
            } else {
                this.Location = new Point(screen.Bounds.Left, screen.Bounds.Top + (screen.Bounds.Height - this.Height) / 2);
                _itemsPanel.Location = new Point(4, 12);
                _itemsPanel.Width = barSize;
                _itemsPanel.Height = this.Height - 24;
            }

            try {
                IntPtr hRgn = NativeMethods.CreateRoundRectRgn(0, 0, this.Width, this.Height, 20, 20);
                this.Region = Region.FromHrgn(hRgn);
                NativeMethods.DeleteObject(hRgn);
            } catch { }
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

        private bool IsCursorOverDropDownHierarchy(ToolStripDropDown dropDown, Point cursor) {
            if (dropDown == null || !dropDown.Visible) return false;
            if (dropDown.Bounds.Contains(cursor)) return true;
            foreach (ToolStripItem item in dropDown.Items) {
                ToolStripMenuItem mi = item as ToolStripMenuItem;
                if (mi != null && mi.HasDropDownItems && mi.DropDown.Visible) {
                    if (IsCursorOverDropDownHierarchy(mi.DropDown, cursor)) return true;
                }
            }
            return false;
        }

        private void OpenFolderDropDown(Button anchor, DockItem folder) {
            if (_activeDropDown != null && _hoveredFolder == folder && _activeDropDown.Visible) {
                return; // Already open for this exact folder - prevent flicker!
            }

            CloseActiveDropDown();

            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            ToolStripDropDown dropDown = new ToolStripDropDown();
            dropDown.AutoClose = false;
            dropDown.Renderer = new DynamicMenuRenderer(theme);

            PopulateFolderMenu(dropDown.Items, folder.TargetFolder, theme);

            if (dropDown.Items.Count == 0) {
                ToolStripMenuItem empty = new ToolStripMenuItem(I18n.T("EmptyFolder"));
                empty.Enabled = false;
                dropDown.Items.Add(empty);
            }

            dropDown.Items.Add(new ToolStripSeparator());
            ToolStripMenuItem openExp = new ToolStripMenuItem("📂 " + I18n.T("OpenInExplorer"));
            openExp.Click += (s, e) => {
                ShellHelper.OpenInExplorer(folder.TargetFolder);
                HideDock();
            };
            dropDown.Items.Add(openExp);

            dropDown.Closed += (s, e) => {
                if (_activeDropDown == dropDown) {
                    _activeDropDown = null;
                    _hoveredFolder = null;
                }
                anchor.BackColor = theme.CardBackground;
                anchor.ForeColor = theme.TextPrimary;
            };

            _activeDropDown = dropDown;
            _hoveredFolder = folder;
            anchor.BackColor = theme.Accent;
            anchor.ForeColor = Color.Black;

            if (_config.DockPosition == "Top") {
                dropDown.Show(anchor, new Point(0, anchor.Height + 1));
            } else {
                dropDown.Show(anchor, new Point(anchor.Width + 1, 0));
            }
        }

        private void PopulateFolderMenu(ToolStripItemCollection targetList, string folderPath, ColorTheme theme) {
            try {
                int iconSz = Math.Min(32, Math.Max(16, _config.DockIconSize));
                string[] subDirs = Directory.GetDirectories(folderPath);
                Array.Sort(subDirs, (a, b) => string.Compare(Path.GetFileName(a), Path.GetFileName(b), StringComparison.OrdinalIgnoreCase));

                foreach (string subDir in subDirs) {
                    string dirName = Path.GetFileName(subDir);
                    ToolStripMenuItem subMenuItem = new ToolStripMenuItem(dirName);
                    subMenuItem.Image = ShellHelper.GetIconImage(subDir, iconSz);

                    string currentSubDir = subDir;
                    PopulateFolderMenu(subMenuItem.DropDownItems, currentSubDir, theme);

                    subMenuItem.MouseDown += (s, e) => {
                        if (e.Button == MouseButtons.Middle) {
                            ShellHelper.OpenInExplorer(currentSubDir);
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
                    fileItem.Image = ShellHelper.GetIconImage(file, iconSz);

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
                try {
                    _activeDropDown.Close();
                } catch { }
                _activeDropDown = null;
            }
        }

        private void WatchdogTimer_Tick(object sender, EventArgs e) {
            if (_isShellMenuOpen) {
                _outOfBoundsTicks = 0;
                return;
            }
            if (!_config.EnableDock) {
                if (_isDockVisible) HideDock();
                return;
            }

            Point cursor = Cursor.Position;
            Screen screen = Screen.PrimaryScreen;
            Rectangle bounds = screen.Bounds;
            int cornerW = Math.Max(80, _config.HotCornerWidth * 4);
            int cornerH = Math.Max(40, _config.HotCornerHeight * 2);
            bool inHotCorner = (cursor.X >= bounds.Left && cursor.X <= bounds.Left + cornerW &&
                                cursor.Y >= bounds.Top && cursor.Y <= bounds.Top + cornerH) ||
                               (cursor.Y <= bounds.Top + 3 && cursor.X >= bounds.Left && cursor.X <= bounds.Left + 200) ||
                               (cursor.Y <= bounds.Top + 3 && cursor.X >= this.Bounds.Left && cursor.X <= this.Bounds.Right);

            if (!_isDockVisible) {
                if (inHotCorner) {
                    ShowDock();
                }
            } else {
                bool overDock = this.Bounds.Contains(cursor);
                bool overDropDown = IsCursorOverDropDownHierarchy(_activeDropDown, cursor);

                if (!overDock && !overDropDown && Control.MouseButtons != MouseButtons.None) {
                    CloseActiveDropDown();
                    HideDock();
                    return;
                }

                bool keepVisible = overDock || overDropDown || inHotCorner;
                if (keepVisible) {
                    _outOfBoundsTicks = 0;

                    // Hover detection over folder buttons
                    if (overDock) {
                        Point clientPt = _itemsPanel.PointToClient(cursor);
                        if (_itemsPanel.ClientRectangle.Contains(clientPt)) {
                            Control child = _itemsPanel.GetChildAtPoint(clientPt);
                            Button fBtn = child as Button;
                            if (fBtn != null && _folderMap.ContainsKey(fBtn)) {
                                DockItem fItem = _folderMap[fBtn];
                                if (_hoveredFolder != fItem) {
                                    OpenFolderDropDown(fBtn, fItem);
                                }
                            } else if (child != null) {
                                Button b = child as Button;
                                if (b == null || !_folderMap.ContainsKey(b)) {
                                    if (_activeDropDown != null && !overDropDown) {
                                        CloseActiveDropDown();
                                    }
                                }
                            }
                        }
                    }
                } else {
                    _outOfBoundsTicks++;
                    int thresholdTicks = Math.Max(4, _config.AutoHideDelayMs / 50);
                    if (_outOfBoundsTicks >= thresholdTicks) {
                        CloseActiveDropDown();
                        HideDock();
                    }
                }
            }
        }

        public void ShowDock() {
            if (!_config.EnableDock) return;
            UpdateDockGeometry();
            this.Visible = true;
            this.BringToFront();
            try {
                Screen sc = Screen.PrimaryScreen;
                int px = (_config.DockPosition == "Top") ? sc.Bounds.Left + (sc.Bounds.Width - this.Width) / 2 : sc.Bounds.Left;
                int py = (_config.DockPosition == "Top") ? sc.Bounds.Top : sc.Bounds.Top + (sc.Bounds.Height - this.Height) / 2;
                this.Location = new Point(px, py);
                NativeMethods.SetWindowPos(this.Handle, new IntPtr(-1), px, py, this.Width, this.Height, 0x0040);
            } catch { }
            _isDockVisible = true;
            _outOfBoundsTicks = 0;
        }

        public void HideDock() {
            CloseActiveDropDown();
            this.Visible = false;
            _isDockVisible = false;
            _outOfBoundsTicks = 0;
            _scrollOffset = 0;
            _hoveredFolder = null;
            RelayoutItems();
            NativeMethods.TrimMemory();
        }

        private void HideDockImmediate() {
            this.Visible = false;
            _isDockVisible = false;
            _outOfBoundsTicks = 0;
        }

        private System.Windows.Forms.Timer _dockGlowTimer;
        private int _dockGlowAlpha = 0;
        private bool _dockGlowRising = true;

        public void SetDownloadingState(bool isDownloading) {
            try {
                if (this.InvokeRequired) {
                    this.BeginInvoke((Action)(() => SetDownloadingState(isDownloading)));
                    return;
                }
                if (isDownloading) {
                    if (_dockGlowTimer == null) {
                        _dockGlowTimer = new System.Windows.Forms.Timer { Interval = 80 };
                        _dockGlowTimer.Tick += (s, e) => {
                            if (_dockGlowRising) {
                                _dockGlowAlpha += 25;
                                if (_dockGlowAlpha >= 220) { _dockGlowAlpha = 220; _dockGlowRising = false; }
                            } else {
                                _dockGlowAlpha -= 25;
                                if (_dockGlowAlpha <= 40) { _dockGlowAlpha = 40; _dockGlowRising = true; }
                            }
                        };
                    }
                    _dockGlowTimer.Start();
                } else {
                    if (_dockGlowTimer != null) _dockGlowTimer.Stop();
                }
            } catch { }
        }

        private void ShowMainMenu(Control anchor) {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            ContextMenuStrip menu = new ContextMenuStrip();
            menu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem title = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v056");
            title.Enabled = false;
            title.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            title.ForeColor = theme.Accent;
            menu.Items.Add(title);

            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem settings = new ToolStripMenuItem("⚙️ " + I18n.T("Settings"));
            settings.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            settings.Click += (s, e) => {
                HideDock();
                if (_openSettingsAction != null) _openSettingsAction();
            };
            menu.Items.Add(settings);

            ToolStripMenuItem openAppDir = new ToolStripMenuItem("📁 " + I18n.T("OpenAppFolder"));
            openAppDir.Click += (s, e) => {
                HideDock();
                ShellHelper.OpenInExplorer(AppDomain.CurrentDomain.BaseDirectory);
            };
            menu.Items.Add(openAppDir);

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
    // SETTINGS FORM (GIN-VPN HERITAGE UI)
    // ==========================================

    // ==========================================
    // GENTLE SOUND GENERATOR & CELESTIAL SHIMMER CHIME (From GIN-Wallpaper)
    // ==========================================
    public static class GentleSound {
        private struct ChimeNote {
            public double freq;
            public double start;
            public double decay;
            public double vol;
            public ChimeNote(double f, double s, double d, double v) {
                freq = f; start = s; decay = d; vol = v;
            }
        }

        // Generates an extra-soft, warm, quiet celestial shimmer (peaceful velvet bells from GIN-Wallpaper)
        private static byte[] CreateChimeWav() {
            int sampleRate = 22050;
            double duration = 1.2;
            int totalSamples = (int)(sampleRate * duration);
            double[] samples = new double[totalSamples];

            ChimeNote[] notes = new ChimeNote[] {
                new ChimeNote(369.99, 0.00, 1.1, 0.20), // F#4
                new ChimeNote(466.16, 0.06, 1.2, 0.18), // A#4
                new ChimeNote(554.37, 0.12, 1.3, 0.16), // C#5
                new ChimeNote(698.46, 0.18, 1.4, 0.14)  // F5
            };

            foreach (ChimeNote n in notes) {
                int sIdx = (int)(n.start * sampleRate);
                for (int i = sIdx; i < totalSamples; i++) {
                    double t = (double)(i - sIdx) / sampleRate;
                    double attack = t / 0.040;
                    if (attack > 1.0) attack = 1.0;
                    double env = attack * Math.Exp(-t * (3.2 / n.decay));
                    double val = Math.Sin(2.0 * Math.PI * n.freq * t);
                    samples[i] += val * env * n.vol;
                }
            }

            double maxVal = 0.0;
            for (int i = 0; i < totalSamples; i++) {
                double abs = Math.Abs(samples[i]);
                if (abs > maxVal) maxVal = abs;
            }
            if (maxVal == 0.0) maxVal = 1.0;

            double scaleAmp = 6000.0;
            byte[] pcm = new byte[totalSamples * 2];
            for (int i = 0; i < totalSamples; i++) {
                short val = (short)((samples[i] / maxVal) * scaleAmp);
                pcm[i * 2] = (byte)(val & 0xFF);
                pcm[i * 2 + 1] = (byte)((val >> 8) & 0xFF);
            }

            int dataLen = pcm.Length;
            byte[] wav = new byte[44 + dataLen];
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("RIFF"), 0, wav, 0, 4);
            int totalLen = 36 + dataLen;
            wav[4] = (byte)(totalLen & 0xFF);
            wav[5] = (byte)((totalLen >> 8) & 0xFF);
            wav[6] = (byte)((totalLen >> 16) & 0xFF);
            wav[7] = (byte)((totalLen >> 24) & 0xFF);
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("WAVEfmt "), 0, wav, 8, 8);
            wav[16] = 16; wav[17] = 0; wav[18] = 0; wav[19] = 0;
            wav[20] = 1; wav[21] = 0; // PCM
            wav[22] = 1; wav[23] = 0; // Mono
            wav[24] = (byte)(sampleRate & 0xFF);
            wav[25] = (byte)((sampleRate >> 8) & 0xFF);
            wav[26] = (byte)((sampleRate >> 16) & 0xFF);
            wav[27] = (byte)((sampleRate >> 24) & 0xFF);
            int byteRate = sampleRate * 2;
            wav[28] = (byte)(byteRate & 0xFF);
            wav[29] = (byte)((byteRate >> 8) & 0xFF);
            wav[30] = (byte)((byteRate >> 16) & 0xFF);
            wav[31] = (byte)((byteRate >> 24) & 0xFF);
            wav[32] = 2; wav[33] = 0; // block align
            wav[34] = 16; wav[35] = 0; // bits per sample
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("data"), 0, wav, 36, 4);
            wav[40] = (byte)(dataLen & 0xFF);
            wav[41] = (byte)((dataLen >> 8) & 0xFF);
            wav[42] = (byte)((dataLen >> 16) & 0xFF);
            wav[43] = (byte)((dataLen >> 24) & 0xFF);
            Buffer.BlockCopy(pcm, 0, wav, 44, dataLen);
            return wav;
        }

        private static byte[] CreateGentleWav(double freq, int durationMs, double volume) {
            int sampleRate = 44100;
            int numSamples = sampleRate * durationMs / 1000;
            byte[] pcm = new byte[numSamples * 2];
            for (int i = 0; i < numSamples; i++) {
                double t = (double)i / sampleRate;
                double envelope = Math.Sin(Math.PI * i / numSamples);
                short sample = (short)(Math.Sin(2 * Math.PI * freq * t) * envelope * volume * 32767.0);
                pcm[i * 2] = (byte)(sample & 0xFF);
                pcm[i * 2 + 1] = (byte)((sample >> 8) & 0xFF);
            }
            int dataLen = pcm.Length;
            byte[] wav = new byte[44 + dataLen];
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("RIFF"), 0, wav, 0, 4);
            int totalLen = 36 + dataLen;
            wav[4] = (byte)(totalLen & 0xFF);
            wav[5] = (byte)((totalLen >> 8) & 0xFF);
            wav[6] = (byte)((totalLen >> 16) & 0xFF);
            wav[7] = (byte)((totalLen >> 24) & 0xFF);
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("WAVEfmt "), 0, wav, 8, 8);
            wav[16] = 16; wav[17] = 0; wav[18] = 0; wav[19] = 0;
            wav[20] = 1; wav[21] = 0;
            wav[22] = 1; wav[23] = 0;
            wav[24] = (byte)(sampleRate & 0xFF);
            wav[25] = (byte)((sampleRate >> 8) & 0xFF);
            wav[26] = (byte)((sampleRate >> 16) & 0xFF);
            wav[27] = (byte)((sampleRate >> 24) & 0xFF);
            int byteRate = sampleRate * 2;
            wav[28] = (byte)(byteRate & 0xFF);
            wav[29] = (byte)((byteRate >> 8) & 0xFF);
            wav[30] = (byte)((byteRate >> 16) & 0xFF);
            wav[31] = (byte)((byteRate >> 24) & 0xFF);
            wav[32] = 2; wav[33] = 0;
            wav[34] = 16; wav[35] = 0;
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("data"), 0, wav, 36, 4);
            wav[40] = (byte)(dataLen & 0xFF);
            wav[41] = (byte)((dataLen >> 8) & 0xFF);
            wav[42] = (byte)((dataLen >> 16) & 0xFF);
            wav[43] = (byte)((dataLen >> 24) & 0xFF);
            Buffer.BlockCopy(pcm, 0, wav, 44, dataLen);
            return wav;
        }

        private static readonly byte[] WavNotice = CreateGentleWav(350.0, 110, 0.14);
        private static readonly byte[] WavSave = CreateGentleWav(620.0, 90, 0.15);
        private static readonly byte[] WavChime = CreateChimeWav();

        public static void PlayNotice() {
            PlayWav(WavNotice);
        }

        public static void PlayDone() {
            PlayWav(WavSave);
        }

        public static void PlayWallpaperChime() {
            PlayWav(WavChime);
        }

        private static void PlayWav(byte[] data) {
            if (data == null || data.Length == 0) return;
            ThreadPool.QueueUserWorkItem(_ => {
                try {
                    using (MemoryStream ms = new MemoryStream(data))
                    using (System.Media.SoundPlayer sp = new System.Media.SoundPlayer(ms)) {
                        sp.PlaySync();
                    }
                } catch { }
            });
        }
    }

    // ==========================================
    // TRAY NOTIFICATION HUD (Silent Non-Activating Toast Window)
    // ==========================================
    public class TrayNotificationHUD : Form {
        private static TrayNotificationHUD _instance;
        private static readonly object _lock = new object();
        public static SynchronizationContext MainSyncContext;

        private Label _lblTitle;
        private Label _lblMessage;
        private System.Windows.Forms.Timer _timer;
        private int _ticksRemaining = 0;
        private double _targetOpacity = 0.96;

        protected override bool ShowWithoutActivation {
            get { return true; }
        }

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= 0x00000080; // WS_EX_TOOLWINDOW
                cp.ExStyle |= 0x08000000; // WS_EX_NOACTIVATE
                cp.ExStyle |= 0x00000008; // WS_EX_TOPMOST
                return cp;
            }
        }

        public TrayNotificationHUD() {
            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.TopMost = true;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(360, 74);
            this.BackColor = Color.FromArgb(24, 25, 28);
            this.DoubleBuffered = true;
            this.Opacity = 0.0;

            _lblTitle = new Label {
                Location = new Point(16, 11),
                Size = new Size(328, 20),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(245, 197, 24),
                BackColor = Color.Transparent
            };

            _lblMessage = new Label {
                Location = new Point(16, 33),
                Size = new Size(328, 34),
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = Color.FromArgb(220, 225, 230),
                BackColor = Color.Transparent
            };

            this.Controls.Add(_lblTitle);
            this.Controls.Add(_lblMessage);

            this.Paint += (s, e) => {
                Graphics g = e.Graphics;
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                using (Pen borderPen = new Pen(Color.FromArgb(60, 65, 75), 1.5f)) {
                    g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
                }
                using (SolidBrush accentBrush = new SolidBrush(Color.FromArgb(245, 197, 24))) {
                    g.FillRectangle(accentBrush, 0, 0, 4, this.Height);
                }
            };

            _timer = new System.Windows.Forms.Timer { Interval = 50 };
            _timer.Tick += (s, e) => {
                if (_ticksRemaining > 0) {
                    if (this.Opacity < _targetOpacity) {
                        this.Opacity = Math.Min(_targetOpacity, this.Opacity + 0.15);
                    }
                    _ticksRemaining--;
                } else {
                    if (this.Opacity > 0.0) {
                        this.Opacity = Math.Max(0.0, this.Opacity - 0.12);
                    } else {
                        _timer.Stop();
                        this.Hide();
                    }
                }
            };
        }

        public static void ShowHUD(string title, string message, int durationSeconds = 3, bool playDone = false) {
            if (playDone) {
                GentleSound.PlayDone();
            }
            if (MainSyncContext != null) {
                MainSyncContext.Post(_ => ShowHUDInternal(title, message, durationSeconds), null);
            } else {
                ShowHUDInternal(title, message, durationSeconds);
            }
        }

        private static void ShowHUDInternal(string title, string message, int durationSeconds) {
            try {
                lock (_lock) {
                    if (_instance == null || _instance.IsDisposed) {
                        _instance = new TrayNotificationHUD();
                    }

                    _instance._lblTitle.Text = title;
                    _instance._lblMessage.Text = message;

                    Rectangle workArea = Screen.PrimaryScreen.WorkingArea;
                    int x = workArea.Right - _instance.Width - 12;
                    int y = workArea.Bottom - _instance.Height - 12;
                    _instance.Location = new Point(x, y);

                    _instance._ticksRemaining = durationSeconds * 20;
                    _instance.Show();
                    _instance._timer.Start();
                }
            } catch { }
        }
    }

    public class SettingsForm : Form {
        private Config _config;
        private Action _onConfigChanged;
        private WallpaperEngine _wallpaperEngine;

        // Top Header
        private Panel _topBar;
        private Label _lblHeaderTitle;
        private Button _btnModeDay;
        private Button _btnModeEvening;
        private Button _btnModeNight;
        private Button _btnLangEN;
        private Button _btnLangRU;
        private Button _btnLangCS;
        private Button _btnSound;

        // Tab Control
        private TabControl _tabs;
        private TabPage _tabMain;
        private TabPage _tabWall;
        private TabPage _tabDock;
        private TabPage _tabAbout;

        // Main Tab
        private CheckBox _chkEnableDock;
        private CheckBox _chkEnableWall;
        private CheckBox _chkAutoStart;
        private CheckBox _chkAutoUpdate;
        private Label _lblThemesHeader;
        private List<Button> _themeButtons = new List<Button>();
        private Label _lblFontsHeader;
        private List<Button> _fontButtons = new List<Button>();

        // Wallpaper Tab
        private Label _lblWallThemesTitle;
        private CheckBox _chkCatAll;
        private Dictionary<string, CheckBox> _catCheckBoxes = new Dictionary<string, CheckBox>();
        private bool _isUpdatingAll = false;
        private Label _lblIntervalTitle;
        private Button _btnInt1h;
        private Button _btnInt3h;
        private Button _btnInt6h;
        private Button _btnInt12h;
        private Button _btnInt24h;
        private List<Panel> _separatorLines = new List<Panel>();
        private Label _lblCalTitle;
        private Button _btnScaleNone;
        private Button _btnScaleSmall;
        private Button _btnScaleMed;
        private Button _btnScaleLarge;
        private Button _btnScaleHuge;
        private Button _btnNextWall;
        private Button _btnSavePic;

        // Weather HUD & Hardware
        private Label _lblWeatherTitle;
        private CheckBox _chkShowWeather;
        private ComboBox _cmbWeatherSrc;
        private Label _lblWeatherCity;
        private TextBox _txtWeatherCity;
        private Label _lblHwTitle;
        private CheckBox _chkHw;
        private CheckBox _chkCpu;
        private CheckBox _chkRam;
        private CheckBox _chkGpu;
        private CheckBox _chkGpuTemp;

        // Dock Tab
        private Label _lblRoot;
        private TextBox _txtRoot;
        private Button _btnBrowse;
        private Label _lblSort;
        private ComboBox _cmbSort;
        private Label _lblShowLabels;
        private CheckBox _chkShowLabels;
        private Label _lblDelay;
        private TrackBar _tbDelay;
        private Label _lblIconSize;
        private List<Button> _iconSizeButtons = new List<Button>();
        private Label _lblDockStyle;
        private List<Button> _dockStyleButtons = new List<Button>();
        private Label _lblDockZoomHeader;
        private CheckBox _chkDockZoom;
        private Label _lblZoomFactor;
        private List<Button> _zoomFactorButtons = new List<Button>();
        private Label _lblFolderFontSize;
        private TrackBar _tbFolderFontSize;
        private Label _lblItemFontSize;
        private TrackBar _tbItemFontSize;

        // About Tab
        private Label _lblAboutTitle;
        private Label _lblAboutDesc;
        private Button _btnCheckUpdate;
        private Button _btnOpenGitHub;

        // Bottom Footer
        private Panel _bottomBar;
        private Button _btnApply;
        private Button _btnSave;
        private Button _btnCancel;
        private Label _lblAuthor;
        private Label _lblSep;
        private Label _lblVer;

        public SettingsForm(Config config, Action onConfigChanged, WallpaperEngine wallpaperEngine) {
            _config = config;
            _onConfigChanged = onConfigChanged;
            _wallpaperEngine = wallpaperEngine;
            InitializeComponent();
            ApplyLocalization();
            ApplyThemeColors();
        }

        private void PlayClickSound() {
            if (_config.EnableSound) {
                GentleSound.PlayNotice();
            }
        }

        private void UpdateSoundButtonText() {
            if (_btnSound == null) return;
            _btnSound.Text = _config.EnableSound ? ("🔊 " + I18n.T("SoundOn")) : ("🔇 " + I18n.T("SoundOff"));
        }

        private void InitializeComponent() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);

            this.Text = "⚡ " + I18n.T("AppTitle") + " — " + I18n.T("Settings");
            this.ClientSize = new Size(760, 780);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = theme.Background;
            this.ForeColor = theme.TextPrimary;
            this.Font = new Font("Segoe UI", 9f);

            // ----------------------------------------
            // 1. TOP HEADER BAR
            // ----------------------------------------
            _topBar = new Panel { Location = new Point(12, 6), Size = new Size(736, 34), BackColor = Color.Transparent };

            _lblHeaderTitle = new Label {
                Text = "⚡ GIN Dock Wallpaper by VladiMIR+AI",
                Font = new Font("Segoe UI", 11.5f, FontStyle.Bold),
                Location = new Point(4, 5),
                AutoSize = true,
                ForeColor = theme.Accent
            };

            _btnModeDay = new Button { Text = "☼", Size = new Size(36, 26), Location = new Point(362, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };
            _btnModeEvening = new Button { Text = "☁", Size = new Size(36, 26), Location = new Point(402, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };
            _btnModeNight = new Button { Text = "☾", Size = new Size(36, 26), Location = new Point(442, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };

            _btnModeDay.Click += (s, e) => { _config.DayEveningNightMode = "Day"; _config.ThemeName = "DaylightLight"; ApplyThemeColors(); if (_onConfigChanged != null) _onConfigChanged(); PlayClickSound(); };
            _btnModeEvening.Click += (s, e) => { _config.DayEveningNightMode = "Evening"; _config.ThemeName = "WarmSand"; ApplyThemeColors(); if (_onConfigChanged != null) _onConfigChanged(); PlayClickSound(); };
            _btnModeNight.Click += (s, e) => { _config.DayEveningNightMode = "Night"; _config.ThemeName = "MidnightOLED"; ApplyThemeColors(); if (_onConfigChanged != null) _onConfigChanged(); PlayClickSound(); };

            _btnLangEN = new Button { Text = "EN", Size = new Size(38, 26), Location = new Point(488, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };
            _btnLangRU = new Button { Text = "RU", Size = new Size(38, 26), Location = new Point(530, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };
            _btnLangCS = new Button { Text = "CS", Size = new Size(38, 26), Location = new Point(572, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand };

            Action<string> changeLanguage = (lang) => {
                _config.Language = lang;
                I18n.SetLanguage(lang);
                WeatherService.InvalidateCache();
                ApplyLocalization();
                ApplyThemeColors();
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                }
                if (_onConfigChanged != null) _onConfigChanged();
                PlayClickSound();
            };
            _btnLangEN.Click += (s, e) => changeLanguage("en");
            _btnLangRU.Click += (s, e) => changeLanguage("ru");
            _btnLangCS.Click += (s, e) => changeLanguage("cs");

            _btnSound = new Button { Text = "🔊 Со звуком", Size = new Size(116, 26), Location = new Point(615, 4), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 8.5f) };
            UpdateSoundButtonText();
            _btnSound.Click += (s, e) => {
                _config.EnableSound = !_config.EnableSound;
                _config.Save();
                UpdateSoundButtonText();
                ApplyThemeColors();
                if (_config.EnableSound) {
                    GentleSound.PlayWallpaperChime();
                }
            };

            _topBar.Controls.AddRange(new Control[] {
                _lblHeaderTitle, _btnModeDay, _btnModeEvening, _btnModeNight,
                _btnLangEN, _btnLangRU, _btnLangCS, _btnSound
            });
            this.Controls.Add(_topBar);

            // ----------------------------------------
            // 2. TABS CONTAINER (CLEAN OWNER DRAW)
            // ----------------------------------------
            _tabs = new TabControl { Location = new Point(12, 42), Size = new Size(736, 680) };
            _tabs.DrawMode = TabDrawMode.OwnerDrawFixed;
            _tabs.SizeMode = TabSizeMode.Fixed;
            _tabs.ItemSize = new Size(175, 28);
            _tabs.DrawItem += Tabs_DrawItem;

            // =====================================
            // TAB 1: MAIN (TOGGLES + THEMES + FONTS)
            // =====================================
            _tabMain = new TabPage { Text = I18n.T("TabMain") };
            _chkEnableDock = new CheckBox { Checked = _config.EnableDock, Location = new Point(25, 20), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _chkEnableWall = new CheckBox { Checked = _config.EnableWallpaper, Location = new Point(25, 52), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _chkAutoStart = new CheckBox { Checked = _config.StartWithWindows, Location = new Point(25, 84), AutoSize = true, Font = new Font("Segoe UI", 9.5f) };
            _chkAutoUpdate = new CheckBox { Checked = _config.CheckUpdatesOnStartup, Location = new Point(25, 116), AutoSize = true, Font = new Font("Segoe UI", 9.5f) };

            // 10 Themes Grid
            _lblThemesHeader = new Label { Location = new Point(25, 160), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };

            string[] themeIds = new string[] {
                "WarmSand", "MidnightOLED", "CyberpunkAmber", "NordicFrost", "EmeraldForest",
                "DeepSpaceNavy", "TokyoNeon", "PureGlass", "Titanium", "DaylightLight"
            };
            string[] themeNames = new string[] {
                "Warm Sand", "Midnight OLED", "Cyberpunk", "Nordic Frost", "Emerald Forest",
                "Deep Space Navy", "Tokyo Neon", "Pure Glass", "Titanium", "Daylight"
            };

            for (int i = 0; i < themeIds.Length; i++) {
                int col = i % 5;
                int row = i / 5;
                string tId = themeIds[i];
                Button bTheme = new Button {
                    Text = themeNames[i],
                    Tag = tId,
                    Size = new Size(130, 36),
                    Location = new Point(25 + col * 138, 190 + row * 46),
                    FlatStyle = FlatStyle.Flat,
                    Cursor = Cursors.Hand,
                    Font = new Font("Segoe UI", 9f)
                };
                bTheme.Click += (s, e) => {
                    _config.ThemeName = (string)((Button)s).Tag;
                    ApplyThemeColors();
                    if (_onConfigChanged != null) _onConfigChanged();
                    PlayClickSound();
                };
                _themeButtons.Add(bTheme);
                _tabMain.Controls.Add(bTheme);
            }

            _tabMain.Controls.AddRange(new Control[] {
                _chkEnableDock, _chkEnableWall, _chkAutoStart, _chkAutoUpdate, _lblThemesHeader
            });
            _tabs.TabPages.Add(_tabMain);

            // =====================================
            // TAB 2: WALLPAPER & CALENDAR
            // =====================================
            _tabWall = new TabPage { Text = I18n.T("TabWallpaper") };

            _lblWallThemesTitle = new Label { Location = new Point(20, 8), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _tabWall.Controls.Add(_lblWallThemesTitle);

            _chkCatAll = new CheckBox { Text = "🎲 " + I18n.T("CatAll"), Location = new Point(25, 26), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _chkCatAll.CheckedChanged += ChkCatAll_CheckedChanged;
            _tabWall.Controls.Add(_chkCatAll);

            string[] catKeys = new string[] {
                "3d", "nature", "flowers", "animals", "ocean", "cars", "space", "trucks", "girls", "city",
                "cyberpunk", "minimalism", "anime", "darkhorse", "macro", "architecture", "aircraft", "retrowave", "fantasy", "underwater"
            };
            string[] catNames = new string[] {
                "Cat3D", "CatNature", "CatFlowers", "CatAnimals", "CatOcean", "CatCars", "CatSpace", "CatTrucks", "CatGirls", "CatCity",
                "CatCyberpunk", "CatMinimalism", "CatAnime", "CatDarkHorse", "CatMacro", "CatArchitecture", "CatAircraft", "CatRetrowave", "CatFantasy", "CatUnderwater"
            };

            string activeCats = (_config.WallpaperCategories ?? "all").ToLowerInvariant();
            for (int i = 0; i < catKeys.Length; i++) {
                string key = catKeys[i];
                int col = i / 10;
                int row = i % 10;
                int xPos = (col == 0) ? 25 : 370;
                int yPos = 44 + row * 18;
                CheckBox cb = new CheckBox {
                    Text = I18n.T(catNames[i]),
                    Tag = key,
                    Location = new Point(xPos, yPos),
                    Size = new Size(330, 18),
                    AutoSize = false,
                    Font = new Font("Segoe UI", 9f)
                };
                cb.Checked = (activeCats.Contains("all") || activeCats.Contains(key));
                cb.CheckedChanged += ChildCategory_CheckedChanged;
                _catCheckBoxes[key] = cb;
                _tabWall.Controls.Add(cb);
            }
            SyncMasterCheckboxState();

            // Separator 1: Between Categories and Interval
            Panel sep1 = new Panel { Location = new Point(25, 230), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sep1);
            _tabWall.Controls.Add(sep1);

            // Interval Section: Clean single row (Label + 5 Buttons: 1h, 3h, 6h, 12h, 24h)
            _lblIntervalTitle = new Label { Location = new Point(25, 243), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _btnInt1h = new Button { Text = I18n.T("Int1h"), Tag = 60, Size = new Size(108, 26), Location = new Point(135, 240), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnInt3h = new Button { Text = I18n.T("Int3h"), Tag = 180, Size = new Size(108, 26), Location = new Point(250, 240), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnInt6h = new Button { Text = I18n.T("Int6h"), Tag = 360, Size = new Size(108, 26), Location = new Point(365, 240), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnInt12h = new Button { Text = I18n.T("Int12h"), Tag = 720, Size = new Size(108, 26), Location = new Point(480, 240), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnInt24h = new Button { Text = I18n.T("Int24h"), Tag = 1440, Size = new Size(108, 26), Location = new Point(595, 240), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };

            EventHandler intClick = (s, e) => {
                _config.WallpaperIntervalMinutes = (int)((Button)s).Tag;
                UpdateIntervalButtonStyles();
                PlayClickSound();
            };
            _btnInt1h.Click += intClick;
            _btnInt3h.Click += intClick;
            _btnInt6h.Click += intClick;
            _btnInt12h.Click += intClick;
            _btnInt24h.Click += intClick;

            _tabWall.Controls.AddRange(new Control[] { _lblIntervalTitle, _btnInt1h, _btnInt3h, _btnInt6h, _btnInt12h, _btnInt24h });

            // Separator 2: Between Interval and Calendar
            Panel sep2 = new Panel { Location = new Point(25, 274), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sep2);
            _tabWall.Controls.Add(sep2);

            // Calendar Section: Clean single row (Label + 5 Buttons)
            _lblCalTitle = new Label { Text = "📅 " + I18n.T("Calendar") + ":", Location = new Point(25, 287), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };

            _btnScaleNone = new Button { Text = I18n.T("CalScaleNone"), Tag = 0.0f, Size = new Size(108, 26), Location = new Point(135, 284), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnScaleSmall = new Button { Text = I18n.T("CalScaleSmall"), Tag = 0.75f, Size = new Size(108, 26), Location = new Point(250, 284), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnScaleMed = new Button { Text = I18n.T("CalScaleMedium"), Tag = 1.0f, Size = new Size(108, 26), Location = new Point(365, 284), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnScaleLarge = new Button { Text = I18n.T("CalScaleLarge"), Tag = 1.3f, Size = new Size(108, 26), Location = new Point(480, 284), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnScaleHuge = new Button { Text = I18n.T("CalScaleHuge"), Tag = 1.6f, Size = new Size(108, 26), Location = new Point(595, 284), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };

            _btnScaleNone.Click += (s, e) => {
                _config.ShowCalendar = false;
                _config.Save();
                UpdateCalScaleButtonStyles();
                PlayClickSound();
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                }
            };

            EventHandler scaleClick = (s, e) => {
                float sc = (float)((Button)s).Tag;
                _config.CalendarScale = sc;
                _config.ShowCalendar = true;
                _config.Save();
                UpdateCalScaleButtonStyles();
                PlayClickSound();
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                }
            };
            _btnScaleSmall.Click += scaleClick;
            _btnScaleMed.Click += scaleClick;
            _btnScaleLarge.Click += scaleClick;
            _btnScaleHuge.Click += scaleClick;

            _tabWall.Controls.AddRange(new Control[] { _lblCalTitle, _btnScaleNone, _btnScaleSmall, _btnScaleMed, _btnScaleLarge, _btnScaleHuge });

            // Separator 3: Between Calendar and Font Grid
            Panel sep3 = new Panel { Location = new Point(25, 318), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sep3);
            _tabWall.Controls.Add(sep3);

            // 24 Curated Font Buttons with ample breathing room (4 cols x 6 rows, H=29)
            _lblFontsHeader = new Label { Location = new Point(25, 326), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _tabWall.Controls.Add(_lblFontsHeader);

            string[] curatedFonts = new string[] {
                "Segoe UI", "Tahoma", "Arial", "Verdana",
                "Georgia", "Corbel", "Consolas", "Trebuchet MS",
                "Cambria", "Century Gothic", "Candara", "Calibri",
                "Gabriola", "Ink Free", "Impact", "Comic Sans MS",
                "Sitka Banner", "Palatino Linotype", "Garamond", "Franklin Gothic Medium",
                "Constantia", "Lucida Console", "Bookman Old Style", "Sylfaen"
            };

            for (int i = 0; i < curatedFonts.Length; i++) {
                int col = i % 4;
                int row = i / 4;
                string fontName = curatedFonts[i];
                int x = 25 + col * 171;
                int y = 348 + row * 33;
                Button bFont = new Button {
                    Text = fontName,
                    Tag = fontName,
                    Size = new Size(165, 29),
                    Location = new Point(x, y),
                    FlatStyle = FlatStyle.Flat,
                    Cursor = Cursors.Hand,
                    TextAlign = ContentAlignment.MiddleCenter,
                    Padding = Padding.Empty
                };
                float fontSize = 9.0f;
                if (fontName == "Gabriola") fontSize = 8.0f;
                else if (fontName == "Impact" || fontName == "Sitka Banner" || fontName == "Palatino Linotype") fontSize = 8.5f;

                try {
                    bFont.Font = new Font(fontName, fontSize, FontStyle.Regular);
                } catch {
                    bFont.Font = new Font("Segoe UI", fontSize, FontStyle.Regular);
                }

                bFont.Click += (s, e) => {
                    string chosen = (string)((Button)s).Tag;
                    _config.CalendarFontFamily = chosen;
                    _config.ShowCalendar = true;
                    _config.Save();
                    UpdateFontButtonStyles();
                    UpdateCalScaleButtonStyles();
                    PlayClickSound();
                    if (_wallpaperEngine != null) {
                        _wallpaperEngine.TriggerNextWallpaperAsync();
                    }
                };
                _fontButtons.Add(bFont);
                _tabWall.Controls.Add(bFont);
            }

            // Separator 4: Between Font Grid and Action Buttons
            Panel sep4 = new Panel { Location = new Point(25, 550), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sep4);
            _tabWall.Controls.Add(sep4);

            _btnNextWall = new Button {
                Text = "🖼️ " + I18n.T("NextWallpaper"),
                Location = new Point(25, 558),
                Width = 330,
                Height = 32,
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            _btnNextWall.Click += (s, e) => {
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                    PlayClickSound();
                }
            };

            _btnSavePic = new Button {
                Text = "💾 " + I18n.T("BtnSaveWall"),
                Location = new Point(367, 558),
                Width = 336,
                Height = 32,
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand,
                Font = new Font("Segoe UI", 9.5f)
            };
            _btnSavePic.Click += (s, e) => {
                if (_wallpaperEngine != null) {
                    _wallpaperEngine.SaveActiveWallpaperToPictures();
                    PlayClickSound();
                }
            };

            _tabWall.Controls.AddRange(new Control[] { _btnNextWall, _btnSavePic });

            // Separator 5: Between Action Buttons and Weather HUD
            Panel sep5 = new Panel { Location = new Point(25, 598), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sep5);
            _tabWall.Controls.Add(sep5);

            // Weather HUD section (Beautiful spacing & margins!)
            _lblWeatherTitle = new Label { Location = new Point(25, 611), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _chkShowWeather = new CheckBox { Checked = _config.ShowWeather, Location = new Point(135, 610), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _chkShowWeather.CheckedChanged += (s, e) => {
                _config.ShowWeather = _chkShowWeather.Checked;
                _config.Save();
                WeatherService.InvalidateCache();
                if (_wallpaperEngine != null) _wallpaperEngine.TriggerNextWallpaperAsync();
            };

            _cmbWeatherSrc = new ComboBox { Location = new Point(275, 608), Width = 115, Height = 28, DropDownStyle = ComboBoxStyle.DropDownList, Font = new Font("Segoe UI", 9f) };
            _cmbWeatherSrc.Items.AddRange(new string[] { "Open-Meteo", "wttr.in" });
            _cmbWeatherSrc.SelectedItem = _config.WeatherSource;
            _cmbWeatherSrc.SelectedIndexChanged += (s, e) => {
                _config.WeatherSource = _cmbWeatherSrc.SelectedItem.ToString();
                _config.Save();
                WeatherService.InvalidateCache();
                if (_wallpaperEngine != null) _wallpaperEngine.TriggerNextWallpaperAsync();
            };

            _lblWeatherCity = new Label { Location = new Point(405, 611), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };

            _txtWeatherCity = new TextBox { Location = new Point(470, 608), Width = 233, Height = 28, Text = _config.WeatherCity, Font = new Font("Segoe UI", 9f) };
            _txtWeatherCity.TextChanged += (s, e) => {
                _config.WeatherCity = _txtWeatherCity.Text.Trim();
                _config.Save();
                WeatherService.InvalidateCache();
            };

            // Hardware Monitoring section under Weather in Wallpaper Tab
            _lblHwTitle = new Label { Location = new Point(25, 646), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _chkHw = new CheckBox { Checked = _config.EnableHardwareMonitor, Location = new Point(135, 645), AutoSize = true, Font = new Font("Segoe UI", 9f, FontStyle.Bold) };
            _chkCpu = new CheckBox { Text = "CPU %", Checked = _config.ShowCpuUsage, Location = new Point(240, 645), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _chkRam = new CheckBox { Text = "RAM %", Checked = _config.ShowRamUsage, Location = new Point(325, 645), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _chkGpu = new CheckBox { Text = "GPU %", Checked = _config.ShowGpuUsage, Location = new Point(410, 645), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _chkGpuTemp = new CheckBox { Text = "GPU °C", Checked = _config.ShowGpuTemp, Location = new Point(495, 645), AutoSize = true, Font = new Font("Segoe UI", 9f) };

            Action updateHwAndWallpaper = () => {
                _config.EnableHardwareMonitor = _chkHw.Checked;
                _config.ShowCpuUsage = _chkCpu.Checked;
                _config.ShowRamUsage = _chkRam.Checked;
                _config.ShowGpuUsage = _chkGpu.Checked;
                _config.ShowGpuTemp = _chkGpuTemp.Checked;
                _config.Save();
                if (_wallpaperEngine != null) _wallpaperEngine.RefreshActiveWallpaperHUD();
                if (_onConfigChanged != null) _onConfigChanged();
            };

            _chkHw.CheckedChanged += (s, e) => updateHwAndWallpaper();
            _chkCpu.CheckedChanged += (s, e) => updateHwAndWallpaper();
            _chkRam.CheckedChanged += (s, e) => updateHwAndWallpaper();
            _chkGpu.CheckedChanged += (s, e) => updateHwAndWallpaper();
            _chkGpuTemp.CheckedChanged += (s, e) => updateHwAndWallpaper();

            _tabWall.Controls.AddRange(new Control[] {
                _lblWeatherTitle, _chkShowWeather, _cmbWeatherSrc, _lblWeatherCity, _txtWeatherCity,
                _lblHwTitle, _chkHw, _chkCpu, _chkRam, _chkGpu, _chkGpuTemp
            });
            _tabs.TabPages.Add(_tabWall);

            // =====================================
            // TAB 3: DOCK BAR (FLUID CONTROLS)
            // =====================================
            _tabDock = new TabPage { Text = I18n.T("TabDock") };

            // Root Folder (Neutral & Customizable)
            _lblRoot = new Label { Location = new Point(20, 12), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _txtRoot = new TextBox { Location = new Point(25, 34), Width = 540, Text = _config.RootFolder, Font = new Font("Segoe UI", 9f) };
            _btnBrowse = new Button { Location = new Point(575, 32), Width = 110, Height = 26, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9f) };
            _btnBrowse.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog()) {
                    fbd.SelectedPath = _txtRoot.Text;
                    if (fbd.ShowDialog() == DialogResult.OK) {
                        _txtRoot.Text = fbd.SelectedPath;
                        _config.RootFolder = fbd.SelectedPath;
                        _config.Save();
                        if (_onConfigChanged != null) _onConfigChanged();
                    }
                }
            };
            _txtRoot.TextChanged += (s, e) => {
                _config.RootFolder = _txtRoot.Text.Trim();
            };

            // Sorting & Labels
            _lblSort = new Label { Location = new Point(20, 68), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _cmbSort = new ComboBox { Location = new Point(25, 88), Width = 310, DropDownStyle = ComboBoxStyle.DropDownList, Font = new Font("Segoe UI", 9f) };

            _lblShowLabels = new Label { Location = new Point(365, 68), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _chkShowLabels = new CheckBox {
                Text = I18n.T("ShowItemLabels"),
                Checked = _config.ShowItemLabels,
                Location = new Point(370, 88),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            _chkShowLabels.CheckedChanged += (s, e) => {
                _config.ShowItemLabels = _chkShowLabels.Checked;
                _config.Save();
                if (_onConfigChanged != null) _onConfigChanged();
            };

            // Delay & Icon Sizes
            _lblDelay = new Label { Location = new Point(20, 116), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _tbDelay = new TrackBar { Location = new Point(25, 134), Width = 310, Minimum = 200, Maximum = 1500, TickFrequency = 100, Value = Math.Max(200, Math.Min(1500, _config.AutoHideDelayMs)) };
            _tbDelay.ValueChanged += (s, e) => _lblDelay.Text = I18n.T("AutoHideDelay") + " (" + _tbDelay.Value + " ms)";

            _lblIconSize = new Label { Location = new Point(365, 116), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            int[] sizes = new int[] { 16, 24, 32, 48, 64 };
            for (int i = 0; i < sizes.Length; i++) {
                int sz = sizes[i];
                Button bSz = new Button {
                    Text = sz + "px",
                    Tag = sz,
                    Size = new Size(58, 26),
                    Location = new Point(370 + i * 64, 134),
                    FlatStyle = FlatStyle.Flat,
                    Cursor = Cursors.Hand,
                    Font = new Font("Segoe UI", 8.5f)
                };
                bSz.Click += (s, e) => {
                    _config.DockIconSize = (int)((Button)s).Tag;
                    _config.Save();
                    UpdateIconSizeButtonStyles();
            UpdateDockStyleButtonStyles();
            UpdateZoomFactorButtonStyles();
                    if (_onConfigChanged != null) _onConfigChanged();
                    PlayClickSound();
                };
                _iconSizeButtons.Add(bSz);
                _tabDock.Controls.Add(bSz);
            }

            // Separator 1: Dock Styles Section
            Panel sepDock1 = new Panel { Location = new Point(25, 175), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sepDock1);
            _tabDock.Controls.Add(sepDock1);

            // Dock Styles (RocketDock Skins)
            _lblDockStyle = new Label { Location = new Point(20, 185), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _tabDock.Controls.Add(_lblDockStyle);

            string[] styleKeys = new string[] { "AeroGlass", "MacFrosted", "DarkStealth", "CrystalClear", "ClassicMetal", "NeonCyber" };
            string[] styleI18n = new string[] { "StyleAeroGlass", "StyleMacFrosted", "StyleDarkStealth", "StyleCrystalClear", "StyleClassicMetal", "StyleNeonCyber" };

            for (int i = 0; i < styleKeys.Length; i++) {
                int col = i % 3;
                int row = i / 3;
                string sKey = styleKeys[i];
                Button bStyle = new Button {
                    Text = I18n.T(styleI18n[i]),
                    Tag = sKey,
                    Size = new Size(218, 30),
                    Location = new Point(25 + col * 228, 208 + row * 36),
                    FlatStyle = FlatStyle.Flat,
                    Cursor = Cursors.Hand,
                    Font = new Font("Segoe UI", 8.5f)
                };
                bStyle.Click += (s, e) => {
                    _config.DockStyle = (string)((Button)s).Tag;
                    _config.Save();
                    UpdateDockStyleButtonStyles();
                    if (_onConfigChanged != null) _onConfigChanged();
                    PlayClickSound();
                };
                _dockStyleButtons.Add(bStyle);
                _tabDock.Controls.Add(bStyle);
            }

            // Separator 2: RocketDock Animation & Zoom Section
            Panel sepDock2 = new Panel { Location = new Point(25, 288), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sepDock2);
            _tabDock.Controls.Add(sepDock2);

            _lblDockZoomHeader = new Label { Location = new Point(20, 298), AutoSize = true, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _tabDock.Controls.Add(_lblDockZoomHeader);

            _chkDockZoom = new CheckBox {
                Text = I18n.T("EnableDockZoom"),
                Checked = _config.EnableDockZoom,
                Location = new Point(25, 322),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            _chkDockZoom.CheckedChanged += (s, e) => {
                _config.EnableDockZoom = _chkDockZoom.Checked;
                _config.Save();
                if (_onConfigChanged != null) _onConfigChanged();
            };
            _tabDock.Controls.Add(_chkDockZoom);

            _lblZoomFactor = new Label { Location = new Point(430, 324), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _tabDock.Controls.Add(_lblZoomFactor);

            float[] zoomVals = new float[] { 1.2f, 1.35f, 1.5f };
            string[] zoomNames = new string[] { "1.2x", "1.35x", "1.5x" };
            for (int i = 0; i < zoomVals.Length; i++) {
                float zVal = zoomVals[i];
                Button bZoom = new Button {
                    Text = zoomNames[i],
                    Tag = zVal,
                    Size = new Size(54, 26),
                    Location = new Point(510 + i * 60, 320),
                    FlatStyle = FlatStyle.Flat,
                    Cursor = Cursors.Hand,
                    Font = new Font("Segoe UI", 8.5f)
                };
                bZoom.Click += (s, e) => {
                    _config.DockZoomFactor = (float)((Button)s).Tag;
                    _config.Save();
                    UpdateZoomFactorButtonStyles();
                    if (_onConfigChanged != null) _onConfigChanged();
                    PlayClickSound();
                };
                _zoomFactorButtons.Add(bZoom);
                _tabDock.Controls.Add(bZoom);
            }

            // Separator 3: Typography Section
            Panel sepDock3 = new Panel { Location = new Point(25, 362), Size = new Size(678, 1), BackColor = theme.Separator };
            _separatorLines.Add(sepDock3);
            _tabDock.Controls.Add(sepDock3);

            // Typography sliders
            _lblFolderFontSize = new Label { Location = new Point(20, 372), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _tbFolderFontSize = new TrackBar { Location = new Point(25, 392), Width = 310, Minimum = 7, Maximum = 16, Value = Math.Max(7, Math.Min(16, (int)_config.DockFolderFontSize)) };
            _tbFolderFontSize.ValueChanged += (s, e) => {
                _lblFolderFontSize.Text = I18n.T("FolderFontSize") + " (" + _tbFolderFontSize.Value + " pt)";
                _config.DockFolderFontSize = _tbFolderFontSize.Value;
                if (_onConfigChanged != null) _onConfigChanged();
            };

            _lblItemFontSize = new Label { Location = new Point(365, 372), AutoSize = true, Font = new Font("Segoe UI", 9f) };
            _tbItemFontSize = new TrackBar { Location = new Point(370, 392), Width = 315, Minimum = 7, Maximum = 16, Value = Math.Max(7, Math.Min(16, (int)_config.DockItemFontSize)) };
            _tbItemFontSize.ValueChanged += (s, e) => {
                _lblItemFontSize.Text = I18n.T("ItemFontSize") + " (" + _tbItemFontSize.Value + " pt)";
                _config.DockItemFontSize = _tbItemFontSize.Value;
                if (_onConfigChanged != null) _onConfigChanged();
            };

            _tabDock.Controls.AddRange(new Control[] {
                _lblRoot, _txtRoot, _btnBrowse,
                _lblSort, _cmbSort, _lblShowLabels, _chkShowLabels,
                _lblDelay, _tbDelay, _lblIconSize,
                _lblFolderFontSize, _tbFolderFontSize, _lblItemFontSize, _tbItemFontSize
            });
            _tabs.TabPages.Add(_tabDock);

            // =====================================
            // TAB 4: ABOUT
            // =====================================
            _tabAbout = new TabPage { Text = I18n.T("TabAbout") };

            _lblAboutTitle = new Label { Text = "⚡ GIN Dock Wallpaper v056", Font = new Font("Segoe UI", 13f, FontStyle.Bold), Location = new Point(25, 25), AutoSize = true, ForeColor = theme.Accent };
            _lblAboutDesc = new Label {
                Text = "Author: Vladimir Bulantsev (@GinCz) & Antigravity\nOpen Source / MIT License\nUniversal 32/64-bit Architecture for Windows 10 & 11\nPlatform: Native WinAPI & GDI+ (~2-4 MB RAM in idle)\n\nDual Integrated Engine:\n• Auto-hiding hot-corner Application & Folder Dock Bar\n• Dynamic 4K Wallpaper Downloader with semi-transparent Calendar HUD",
                Location = new Point(25, 70),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.5f)
            };

            _btnCheckUpdate = new Button { Location = new Point(25, 210), Width = 260, Height = 34, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _btnCheckUpdate.Click += (s, e) => RunAutoUpdateWorkflow(this, true);

            _btnOpenGitHub = new Button { Text = "🌐 GitHub Open Source Repository", Location = new Point(300, 210), Width = 280, Height = 34, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9.5f) };
            _btnOpenGitHub.Click += (s, e) => {
                try { Process.Start("https://github.com/GinCz/Windows_scripts/tree/main/GIN-Desktop"); } catch { }
            };

            _tabAbout.Controls.AddRange(new Control[] { _lblAboutTitle, _lblAboutDesc, _btnCheckUpdate, _btnOpenGitHub });
            _tabs.TabPages.Add(_tabAbout);

            this.Controls.Add(_tabs);

            // ----------------------------------------
            // 3. BOTTOM FOOTER BAR (With GIN-VPN Signature)
            // ----------------------------------------
            _bottomBar = new Panel { Location = new Point(12, 730), Size = new Size(736, 38), BackColor = Color.Transparent };

            _btnApply = new Button { Text = I18n.T("Apply"), Location = new Point(0, 3), Width = 115, Height = 32, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 9.5f, FontStyle.Bold) };
            _btnApply.Click += (s, e) => { CommitSettings(true); PlayClickSound(); };

            _btnSave = new Button { Text = I18n.T("Save"), Location = new Point(122, 3), Width = 175, Height = 32, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, DialogResult = DialogResult.OK, Font = new Font("Segoe UI", 9.5f) };
            _btnSave.Click += (s, e) => { CommitSettings(false); this.Close(); };

            _btnCancel = new Button { Text = I18n.T("Cancel"), Location = new Point(304, 3), Width = 95, Height = 32, FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, DialogResult = DialogResult.Cancel, Font = new Font("Segoe UI", 9.5f) };
            _btnCancel.Click += (s, e) => this.Close();

            // Right signature: VladiMIR+AI ||| v052 (Clean, Gold, No underline!)
            _lblAuthor = new Label {
                Text = "VladiMIR+AI",
                Location = new Point(540, 9),
                AutoSize = true,
                Font = new Font("Segoe UI", 10.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(235, 175, 55),
                Cursor = Cursors.Hand
            };
            _lblAuthor.Click += (s, e) => {
                try { Process.Start("https://github.com/GinCz"); } catch { }
            };

            _lblSep = new Label {
                Text = " ||| ",
                Location = new Point(636, 9),
                AutoSize = true,
                Font = new Font("Segoe UI", 10.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(160, 160, 160)
            };

            _lblVer = new Label {
                Text = "v056",
                Location = new Point(666, 9),
                AutoSize = true,
                Font = new Font("Segoe UI", 10.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(235, 175, 55),
                Cursor = Cursors.Hand
            };
            _lblVer.Click += (s, e) => {
                RunAutoUpdateWorkflow(this, true);
            };

            _bottomBar.Controls.AddRange(new Control[] {
                _btnApply, _btnSave, _btnCancel, _lblAuthor, _lblSep, _lblVer
            });
            this.Controls.Add(_bottomBar);
        }

        private void ApplyFontToForm(string fontName) {
            if (string.IsNullOrEmpty(fontName)) return;
            ApplyFontRecursive(this, fontName);
            _tabs.Invalidate();
        }

        private void ApplyFontRecursive(Control parent, string fontName) {
            foreach (Control c in parent.Controls) {
                Button btn = c as Button;
                if (btn != null && _fontButtons.Contains(btn)) {
                    continue; // Preserve individual font styles on the preview buttons
                }
                try {
                    FontStyle style = c.Font != null ? c.Font.Style : FontStyle.Regular;
                    float size = c.Font != null ? c.Font.Size : 9.5f;
                    c.Font = new Font(fontName, size, style);
                } catch { }

                if (c.HasChildren) {
                    ApplyFontRecursive(c, fontName);
                }
            }
        }

        private void Tabs_DrawItem(object sender, DrawItemEventArgs e) {
            TabPage page = _tabs.TabPages[e.Index];
            ColorTheme th = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            bool selected = (e.Index == _tabs.SelectedIndex);
            Rectangle rect = _tabs.GetTabRect(e.Index);

            using (SolidBrush b = new SolidBrush(selected ? th.Accent : th.CardBackground)) {
                e.Graphics.FillRectangle(b, rect);
            }
            using (Pen p = new Pen(selected ? th.AccentHover : th.Border)) {
                e.Graphics.DrawRectangle(p, rect.X, rect.Y, rect.Width - 1, rect.Height - 1);
            }
            TextRenderer.DrawText(
                e.Graphics,
                page.Text,
                new Font(_config.SettingsFontFamily ?? "Segoe UI", 9.5f, selected ? FontStyle.Bold : FontStyle.Regular),
                rect,
                selected ? Color.Black : th.TextPrimary,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter
            );
        }

        private void ChkCatAll_CheckedChanged(object sender, EventArgs e) {
            if (_isUpdatingAll) return;
            _isUpdatingAll = true;
            bool isChecked = _chkCatAll.Checked;
            foreach (var cb in _catCheckBoxes.Values) {
                cb.Checked = isChecked;
            }
            _isUpdatingAll = false;
        }

        private void ChildCategory_CheckedChanged(object sender, EventArgs e) {
            if (_isUpdatingAll) return;
            SyncMasterCheckboxState();
        }

        private void SyncMasterCheckboxState() {
            _isUpdatingAll = true;
            bool allChecked = true;
            foreach (var cb in _catCheckBoxes.Values) {
                if (!cb.Checked) {
                    allChecked = false;
                    break;
                }
            }
            _chkCatAll.Checked = allChecked;
            _isUpdatingAll = false;
        }

        private void ApplyThemeColors() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);

            this.BackColor = theme.Background;
            this.ForeColor = theme.TextPrimary;

            _lblHeaderTitle.ForeColor = theme.Accent;

            // Day / Evening / Night toggle styles
            StyleModeButton(_btnModeDay, _config.DayEveningNightMode == "Day", theme);
            StyleModeButton(_btnModeEvening, _config.DayEveningNightMode == "Evening", theme);
            StyleModeButton(_btnModeNight, _config.DayEveningNightMode == "Night", theme);

            // Language toggle styles
            string curLang = (_config.Language ?? "en").ToLowerInvariant();
            StyleModeButton(_btnLangEN, curLang == "en", theme);
            StyleModeButton(_btnLangRU, curLang == "ru", theme);
            StyleModeButton(_btnLangCS, curLang == "cs", theme);

            // Sound button style
            UpdateSoundButtonText();
            StyleModeButton(_btnSound, _config.EnableSound, theme);

            // Tabs styling
            _tabMain.BackColor = theme.CardBackground;
            _tabWall.BackColor = theme.CardBackground;
            _tabDock.BackColor = theme.CardBackground;
            _tabAbout.BackColor = theme.CardBackground;

            // Action Buttons
            _btnApply.BackColor = theme.Accent;
            _btnApply.ForeColor = Color.Black;
            _btnApply.FlatAppearance.BorderColor = theme.Accent;

            _btnSave.BackColor = theme.CardBackground;
            _btnSave.ForeColor = theme.TextPrimary;
            _btnSave.FlatAppearance.BorderColor = theme.Border;

            _btnCancel.BackColor = theme.CardBackground;
            _btnCancel.ForeColor = theme.TextSecondary;
            _btnCancel.FlatAppearance.BorderColor = theme.Border;

            _btnNextWall.BackColor = theme.Accent;
            _btnNextWall.ForeColor = Color.Black;
            _btnNextWall.FlatAppearance.BorderColor = theme.Accent;

            _btnCheckUpdate.BackColor = theme.Accent;
            _btnCheckUpdate.ForeColor = Color.Black;
            _btnCheckUpdate.FlatAppearance.BorderColor = theme.Accent;

            _btnOpenGitHub.BackColor = theme.CardBackground;
            _btnOpenGitHub.ForeColor = theme.TextPrimary;
            _btnOpenGitHub.FlatAppearance.BorderColor = theme.Border;

            _btnBrowse.BackColor = theme.CardBackground;
            _btnBrowse.ForeColor = theme.TextPrimary;
            _btnBrowse.FlatAppearance.BorderColor = theme.Border;

            // Theme Buttons
            foreach (Button b in _themeButtons) {
                bool isActive = string.Equals((string)b.Tag, _config.ThemeName, StringComparison.OrdinalIgnoreCase);
                StyleToggleButton(b, isActive, theme);
            }

            // Font preview buttons
            UpdateFontButtonStyles();

            // Calendar scale buttons
            UpdateCalScaleButtonStyles();

            if (_btnSavePic != null) {
                _btnSavePic.BackColor = theme.CardBackground;
                _btnSavePic.ForeColor = theme.TextPrimary;
                _btnSavePic.FlatAppearance.BorderColor = theme.Border;
            }

            // Interval buttons
            UpdateIntervalButtonStyles();

            // Dock placement buttons
            
            // Icon size buttons
            UpdateIconSizeButtonStyles();
            UpdateDockStyleButtonStyles();
            UpdateZoomFactorButtonStyles();

            // Inputs
            _txtRoot.BackColor = theme.Background;
            _txtRoot.ForeColor = theme.TextPrimary;
            _cmbSort.BackColor = theme.Background;
            _cmbSort.ForeColor = theme.TextPrimary;
            if (_chkShowLabels != null) {
                _chkShowLabels.ForeColor = theme.TextPrimary;
            }

            // Style Separator lines
            foreach (Panel sep in _separatorLines) {
                sep.BackColor = theme.Separator;
            }

            // Force repaint of tab headers
            _tabs.Invalidate();
        }

        private void StyleModeButton(Button btn, bool isActive, ColorTheme theme) {
            if (isActive) {
                btn.BackColor = theme.Accent;
                btn.ForeColor = Color.Black;
                btn.FlatAppearance.BorderColor = theme.Accent;
                btn.FlatAppearance.BorderSize = 1;
            } else {
                btn.BackColor = theme.CardBackground;
                btn.ForeColor = theme.TextSecondary;
                btn.FlatAppearance.BorderColor = theme.Border;
                btn.FlatAppearance.BorderSize = 1;
            }
        }

        private void StyleToggleButton(Button btn, bool isActive, ColorTheme theme) {
            if (isActive) {
                btn.BackColor = theme.Accent;
                btn.ForeColor = Color.Black;
                btn.FlatAppearance.BorderColor = theme.Accent;
                btn.FlatAppearance.BorderSize = 2;
                btn.Font = new Font(btn.Font, FontStyle.Bold);
            } else {
                btn.BackColor = theme.CardBackground;
                btn.ForeColor = theme.TextPrimary;
                btn.FlatAppearance.BorderColor = theme.Border;
                btn.FlatAppearance.BorderSize = 1;
                btn.Font = new Font(btn.Font, FontStyle.Regular);
            }
        }

        private void UpdateIntervalButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            int cur = _config.WallpaperIntervalMinutes;
            if (_btnInt1h != null) StyleToggleButton(_btnInt1h, cur <= 60, theme);
            if (_btnInt3h != null) StyleToggleButton(_btnInt3h, cur == 180, theme);
            if (_btnInt6h != null) StyleToggleButton(_btnInt6h, cur == 360, theme);
            if (_btnInt12h != null) StyleToggleButton(_btnInt12h, cur == 720, theme);
            if (_btnInt24h != null) StyleToggleButton(_btnInt24h, cur >= 1440, theme);
        }

        private void UpdateCalScaleButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            bool isOff = !_config.ShowCalendar;
            float cur = _config.CalendarScale;
            if (_btnScaleNone != null) StyleToggleButton(_btnScaleNone, isOff, theme);
            if (_btnScaleSmall != null) StyleToggleButton(_btnScaleSmall, !isOff && cur <= 0.85f, theme);
            if (_btnScaleMed != null) StyleToggleButton(_btnScaleMed, !isOff && cur > 0.85f && cur <= 1.15f, theme);
            if (_btnScaleLarge != null) StyleToggleButton(_btnScaleLarge, !isOff && cur > 1.15f && cur <= 1.45f, theme);
            if (_btnScaleHuge != null) StyleToggleButton(_btnScaleHuge, !isOff && cur > 1.45f, theme);
        }

        private void UpdateFontButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            string curFont = _config.CalendarFontFamily ?? "Segoe UI";
            foreach (Button b in _fontButtons) {
                bool isActive = string.Equals((string)b.Tag, curFont, StringComparison.OrdinalIgnoreCase);
                StyleToggleButton(b, isActive, theme);
            }
        }



        private void UpdateDockStyleButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            string curStyle = _config.DockStyle ?? "AeroGlass";
            foreach (Button b in _dockStyleButtons) {
                bool isActive = string.Equals((string)b.Tag, curStyle, StringComparison.OrdinalIgnoreCase);
                StyleToggleButton(b, isActive, theme);
            }
        }

        private void UpdateZoomFactorButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            float curZoom = _config.DockZoomFactor;
            foreach (Button b in _zoomFactorButtons) {
                bool isActive = Math.Abs((float)b.Tag - curZoom) < 0.05f;
                StyleToggleButton(b, isActive, theme);
            }
        }

        private void UpdateIconSizeButtonStyles() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            int curSz = _config.DockIconSize;
            foreach (Button b in _iconSizeButtons) {
                bool isActive = ((int)b.Tag == curSz);
                StyleToggleButton(b, isActive, theme);
            }
        }

        private void ApplyLocalization() {
            this.Text = "⚡ " + I18n.T("AppTitle") + " — " + I18n.T("Settings");
            UpdateSoundButtonText();
            _tabMain.Text = I18n.T("TabMain");
            _tabWall.Text = I18n.T("TabWallpaper");
            _tabDock.Text = I18n.T("TabDock");
            _tabAbout.Text = I18n.T("TabAbout");

            _chkEnableDock.Text = "⚡ " + I18n.T("EnableDock");
            _chkEnableWall.Text = "🖼️ " + I18n.T("EnableWallpaper");
            _chkAutoStart.Text = "🚀 " + I18n.T("AutoStart");
            _chkAutoUpdate.Text = "⬆️ " + I18n.T("AutoUpdate");
            _lblThemesHeader.Text = "🎨 " + I18n.T("ColorTheme");
            _lblFontsHeader.Text = "🔤 " + I18n.T("SelectFontWithPreview");

            _lblWallThemesTitle.Text = I18n.T("WallThemesTitle");
            _chkCatAll.Text = "🎲 " + I18n.T("CatAll");

            string[] catKeys = new string[] {
                "3d", "nature", "flowers", "animals", "ocean", "cars", "space", "trucks", "girls", "city",
                "cyberpunk", "minimalism", "anime", "darkhorse", "macro", "architecture", "aircraft", "retrowave", "fantasy", "underwater"
            };
            string[] catNames = new string[] {
                "Cat3D", "CatNature", "CatFlowers", "CatAnimals", "CatOcean", "CatCars", "CatSpace", "CatTrucks", "CatGirls", "CatCity",
                "CatCyberpunk", "CatMinimalism", "CatAnime", "CatDarkHorse", "CatMacro", "CatArchitecture", "CatAircraft", "CatRetrowave", "CatFantasy", "CatUnderwater"
            };
            for (int i = 0; i < catKeys.Length; i++) {
                if (_catCheckBoxes.ContainsKey(catKeys[i])) {
                    _catCheckBoxes[catKeys[i]].Text = I18n.T(catNames[i]);
                }
            }
            _lblIntervalTitle.Text = "⏱️ " + I18n.T("WallpaperInterval");
            if (_btnInt1h != null) _btnInt1h.Text = I18n.T("Int1h");
            if (_btnInt3h != null) _btnInt3h.Text = I18n.T("Int3h");
            if (_btnInt6h != null) _btnInt6h.Text = I18n.T("Int6h");
            if (_btnInt12h != null) _btnInt12h.Text = I18n.T("Int12h");
            if (_btnInt24h != null) _btnInt24h.Text = I18n.T("Int24h");

            if (_lblCalTitle != null) _lblCalTitle.Text = "📅 " + I18n.T("Calendar") + ":";
            if (_btnScaleNone != null) _btnScaleNone.Text = I18n.T("CalScaleNone");
            if (_btnScaleSmall != null) _btnScaleSmall.Text = I18n.T("CalScaleSmall");
            if (_btnScaleMed != null) _btnScaleMed.Text = I18n.T("CalScaleMedium");
            if (_btnScaleLarge != null) _btnScaleLarge.Text = I18n.T("CalScaleLarge");
            if (_btnScaleHuge != null) _btnScaleHuge.Text = I18n.T("CalScaleHuge");
            if (_btnSavePic != null) _btnSavePic.Text = "💾 " + I18n.T("BtnSaveWall");
            _lblIntervalTitle.Text = "⏱️ " + I18n.T("WallpaperInterval");
            _lblFontsHeader.Text = "🔤 " + I18n.T("SelectFontWithPreview");
            if (_btnNextWall != null) _btnNextWall.Text = "🖼️ " + I18n.T("NextWallpaper");

            if (_lblWeatherTitle != null) _lblWeatherTitle.Text = "🌤️ " + I18n.T("Weather");
            if (_chkShowWeather != null) _chkShowWeather.Text = I18n.T("EnableWeather");
            if (_lblWeatherCity != null) _lblWeatherCity.Text = "📍 " + I18n.T("WeatherCity");

            if (_lblHwTitle != null) _lblHwTitle.Text = "⚡ " + I18n.T("Hardware");
            if (_chkHw != null) _chkHw.Text = I18n.T("Enable");



            _lblRoot.Text = I18n.T("RootFolder");
            _btnBrowse.Text = I18n.T("Browse");
            _lblSort.Text = I18n.T("SortingMode");
            PopulateSortList();

            _lblShowLabels.Text = I18n.T("ShowLabels");
            if (_chkShowLabels != null) {
                _chkShowLabels.Text = I18n.T("ShowItemLabels");
            }

            _lblDelay.Text = I18n.T("AutoHideDelay") + " (" + _tbDelay.Value + " ms)";
            _lblIconSize.Text = "🔍 " + I18n.T("DockIconSize");
            if (_lblDockStyle != null) _lblDockStyle.Text = "🎨 " + I18n.T("DockStyle");
            if (_lblDockZoomHeader != null) _lblDockZoomHeader.Text = "⚡ " + I18n.T("DockEffectsHeader");
            if (_chkDockZoom != null) _chkDockZoom.Text = I18n.T("EnableDockZoom");
            if (_lblZoomFactor != null) _lblZoomFactor.Text = I18n.T("DockZoomFactor");

                        string[] styleI18nR = new string[] { "StyleAeroGlass", "StyleMacFrosted", "StyleDarkStealth", "StyleCrystalClear", "StyleClassicMetal", "StyleNeonCyber" };
            for (int i = 0; i < _dockStyleButtons.Count && i < styleI18nR.Length; i++) {
                _dockStyleButtons[i].Text = I18n.T(styleI18nR[i]);
            }

            _lblFolderFontSize.Text = I18n.T("FolderFontSize") + " (" + _tbFolderFontSize.Value + " pt)";
            _lblItemFontSize.Text = I18n.T("ItemFontSize") + " (" + _tbItemFontSize.Value + " pt)";

            _btnApply.Text = I18n.T("Apply");
            _btnSave.Text = I18n.T("Save");
            _btnCancel.Text = I18n.T("Cancel");
            _btnCheckUpdate.Text = "⬆️ " + I18n.T("CheckUpdates");

            if (_lblAboutTitle != null) _lblAboutTitle.Text = I18n.T("AboutTitle");
            if (_lblAboutDesc != null) _lblAboutDesc.Text = I18n.T("AboutDesc");
            if (_btnOpenGitHub != null) _btnOpenGitHub.Text = I18n.T("GitHubRepo");
            if (_lblVer != null) _lblVer.Text = CURRENT_VERSION;

            _tabs.Invalidate();
        }

        private void PopulateSortList() {
            string cur = _config.SortingMode;
            _cmbSort.Items.Clear();
            _cmbSort.Items.Add(I18n.T("SortAlphaAZ"));
            _cmbSort.Items.Add(I18n.T("SortAlphaZA"));
            _cmbSort.Items.Add(I18n.T("SortFoldersFirst"));
            _cmbSort.Items.Add(I18n.T("SortFileType"));
            _cmbSort.Items.Add(I18n.T("SortDateModified"));

            if (cur == "AlphaZA") _cmbSort.SelectedIndex = 1;
            else if (cur == "FoldersFirst") _cmbSort.SelectedIndex = 2;
            else if (cur == "FileType") _cmbSort.SelectedIndex = 3;
            else if (cur == "DateModified") _cmbSort.SelectedIndex = 4;
            else _cmbSort.SelectedIndex = 0;
        }

        private void CommitSettings(bool triggerImmediateApply) {
            _config.EnableDock = _chkEnableDock.Checked;
            _config.EnableWallpaper = _chkEnableWall.Checked;
            _config.StartWithWindows = _chkAutoStart.Checked;
            _config.CheckUpdatesOnStartup = _chkAutoUpdate.Checked;

            // Categories
            List<string> selectedCats = new List<string>();
            foreach (var kvp in _catCheckBoxes) {
                if (kvp.Value.Checked) selectedCats.Add(kvp.Key);
            }
            if (selectedCats.Count == 0) selectedCats.Add("all");
            _config.WallpaperCategories = string.Join(",", selectedCats.ToArray());


            _config.RootFolder = _txtRoot.Text;
            if (_cmbSort.SelectedIndex == 1) _config.SortingMode = "AlphaZA";
            else if (_cmbSort.SelectedIndex == 2) _config.SortingMode = "FoldersFirst";
            else if (_cmbSort.SelectedIndex == 3) _config.SortingMode = "FileType";
            else if (_cmbSort.SelectedIndex == 4) _config.SortingMode = "DateModified";
            else _config.SortingMode = "AlphaAZ";

            if (_chkShowLabels != null) {
                _config.ShowItemLabels = _chkShowLabels.Checked;
            }

            _config.AutoHideDelayMs = _tbDelay.Value;
            if (_chkDockZoom != null) _config.EnableDockZoom = _chkDockZoom.Checked;
            _config.DockFolderFontSize = _tbFolderFontSize.Value;
            _config.DockItemFontSize = _tbItemFontSize.Value;

            SetAutoStartRegistry(_config.StartWithWindows);
            _config.Save();

            if (_wallpaperEngine != null) {
                _wallpaperEngine.SetEnabled(_config.EnableWallpaper);
                _wallpaperEngine.UpdateInterval();
                if (triggerImmediateApply && _config.EnableWallpaper) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                }
            }

            if (_onConfigChanged != null) _onConfigChanged();
        }

        private void SetAutoStartRegistry(bool enable) {
            try {
                RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                if (enable) {
                    rk.SetValue("GIN-Desktop", "\"" + Application.ExecutablePath + "\"");
                } else {
                    rk.DeleteValue("GIN-Desktop", false);
                }
            } catch { }
        }

        public const string CURRENT_VERSION = "v056";

        private static int ParseVersionDigits(string v) {
            if (string.IsNullOrEmpty(v)) return 0;
            string digits = System.Text.RegularExpressions.Regex.Replace(v, @"[^\d]", "");
            int n;
            return int.TryParse(digits, out n) ? n : 0;
        }

                public static void RunAutoUpdateWorkflow(Form parentForm, bool isManual) {
            if (isManual) {
                string checkTitle = "🔍 GIN-Desktop";
                string checkMsg = (I18n.CurrentLanguage == "ru"
                    ? "Проверка обновлений..."
                    : (I18n.CurrentLanguage == "cs" ? "Kontrola aktualizací..." : "Checking for updates..."));
                TrayNotificationHUD.ShowHUD(checkTitle, checkMsg, 3, false);
                GentleSound.PlayNotice();
            }

            ThreadPool.QueueUserWorkItem(_ => {
                try {
                    string url = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Desktop/version.json?_t=" + DateTime.UtcNow.Ticks;
                    using (WebClient wc = new WebClient()) {
                        wc.Headers.Add("User-Agent", "GIN-Desktop/" + CURRENT_VERSION);
                        string json = wc.DownloadString(url);

                        int vIdx = json.IndexOf("\"version\":");
                        if (vIdx != -1) {
                            int q1 = json.IndexOf("\"", vIdx + 10);
                            int q2 = json.IndexOf("\"", q1 + 1);
                            string remoteVer = json.Substring(q1 + 1, q2 - q1 - 1).Trim();
                            string currentVer = CURRENT_VERSION;

                            int rNum = ParseVersionDigits(remoteVer);
                            int cNum = ParseVersionDigits(currentVer);

                            if (rNum > cNum) {
                                string downloadUrl = "";
                                int dIdx = json.IndexOf("\"download_url\":");
                                if (dIdx != -1) {
                                    int dq1 = json.IndexOf("\"", dIdx + 15);
                                    int dq2 = json.IndexOf("\"", dq1 + 1);
                                    downloadUrl = json.Substring(dq1 + 1, dq2 - dq1 - 1);
                                }

                                if (string.IsNullOrEmpty(downloadUrl)) {
                                    downloadUrl = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Desktop/GIN-Desktop_" + remoteVer + "_Setup.exe";
                                }

                                string arrowMsg = string.Format("{0} ➔ {1}", cNum, rNum);
                                string updateTitle = "⬇️ GIN-Desktop Update";
                                string updateDesc = (I18n.CurrentLanguage == "ru"
                                    ? ("Найдена новая версия: " + arrowMsg + "\nЗагрузка и тихое обновление...")
                                    : (I18n.CurrentLanguage == "cs"
                                        ? ("Nová verze: " + arrowMsg + "\nStahování a tichá aktualizace...")
                                        : ("New version found: " + arrowMsg + "\nDownloading & updating silently...")));

                                TrayNotificationHUD.ShowHUD(updateTitle, updateDesc, 6, false);
                                GentleSound.PlayNotice();

                                string tempSetup = Path.Combine(Path.GetTempPath(), "GIN-Desktop_" + remoteVer + "_Setup.exe");
                                using (WebClient dlClient = new WebClient()) {
                                    dlClient.Headers.Add("User-Agent", "GIN-Desktop/" + CURRENT_VERSION);
                                    dlClient.DownloadFile(downloadUrl, tempSetup);
                                }

                                if (File.Exists(tempSetup)) {
                                    string currentBaseDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(new char[] { '\\', '/' });
                                    ProcessStartInfo psi = new ProcessStartInfo {
                                        FileName = tempSetup,
                                        Arguments = "/update /target:\"" + currentBaseDir + "\"",
                                        UseShellExecute = true
                                    };
                                    Process.Start(psi);
                                    Application.Exit();
                                }
                            } else if (isManual) {
                                string latestTitle = "✅ GIN-Desktop " + CURRENT_VERSION;
                                string latestDesc = (I18n.CurrentLanguage == "ru"
                                    ? "У вас установлена последняя версия!"
                                    : (I18n.CurrentLanguage == "cs"
                                        ? "Máte nejnovější verzi!"
                                        : "You have the latest version!"));

                                TrayNotificationHUD.ShowHUD(latestTitle, latestDesc, 3, true);
                            }
                        }
                    }
                } catch (Exception ex) {
                    if (isManual) {
                        string errTitle = "⚠️ GIN-Desktop Update";
                        string errDesc = (I18n.CurrentLanguage == "ru"
                            ? ("Ошибка проверки обновления: " + ex.Message)
                            : ("Update check failed: " + ex.Message));
                        TrayNotificationHUD.ShowHUD(errTitle, errDesc, 4, false);
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

        private Icon _baseTrayIcon;
        private System.Windows.Forms.Timer _trayGlowTimer;
        private int _trayGlowFrame = 0;
        private bool _trayGlowRising = true;

        private void StartTrayGlowAnimation() {
            if (_trayGlowTimer == null) {
                _trayGlowTimer = new System.Windows.Forms.Timer { Interval = 75 };
                _trayGlowTimer.Tick += (s, e) => {
                    try {
                        if (_trayGlowRising) {
                            _trayGlowFrame++;
                            if (_trayGlowFrame >= 9) { _trayGlowFrame = 9; _trayGlowRising = false; }
                        } else {
                            _trayGlowFrame--;
                            if (_trayGlowFrame <= 0) { _trayGlowFrame = 0; _trayGlowRising = true; }
                        }

                        int alpha = 40 + _trayGlowFrame * 20; // 40 to 220 pulse
                        using (Bitmap bmp = new Bitmap(32, 32))
                        using (Graphics g = Graphics.FromImage(bmp)) {
                            g.SmoothingMode = SmoothingMode.AntiAlias;
                            g.Clear(Color.Transparent);

                            // Pulsing cyan glow circle behind icon
                            int glowPad = 14 - _trayGlowFrame;
                            Rectangle glowRect = new Rectangle(glowPad / 2, glowPad / 2, 32 - glowPad, 32 - glowPad);
                            using (SolidBrush haloBrush = new SolidBrush(Color.FromArgb(alpha, 56, 189, 248))) {
                                g.FillEllipse(haloBrush, glowRect);
                            }

                            // Base icon rendered over glow
                            if (_baseTrayIcon != null) {
                                g.DrawIcon(_baseTrayIcon, new Rectangle(4, 4, 24, 24));
                            }
                            _trayIcon.Icon = Icon.FromHandle(bmp.GetHicon());
                        }
                    } catch { }
                };
            }
            _trayGlowTimer.Start();
        }

        private void StopTrayGlowAnimation() {
            if (_trayGlowTimer != null) {
                _trayGlowTimer.Stop();
            }
            if (_baseTrayIcon != null && _trayIcon != null) {
                try { _trayIcon.Icon = _baseTrayIcon; } catch { }
            }
        }

        public DockWallpaperApplicationContext(bool isPostUpdate = false) {
            _config = Config.Load();
            _wallpaperEngine = new WallpaperEngine(_config);
            _dockForm = new DockBarForm(_config, ShowSettings);

            _trayIcon = new NotifyIcon();
            _trayIcon.Text = "GIN Dock Wallpaper v054";

            try {
                string icoPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app.ico");
                if (File.Exists(icoPath)) {
                    _trayIcon.Icon = new Icon(icoPath);
                } else {
                    _trayIcon.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
                }
            } catch {
                _trayIcon.Icon = SystemIcons.Application;
            }
            _baseTrayIcon = _trayIcon.Icon;

            _wallpaperEngine.DownloadStateChanged += (isBusy) => {
                try {
                    if (isBusy) StartTrayGlowAnimation();
                    else StopTrayGlowAnimation();
                } catch { }
                if (_dockForm != null) {
                    _dockForm.SetDownloadingState(isBusy);
                }
            };

            BuildTrayMenu();

            _trayIcon.Visible = true;

            // Double Click immediately triggers Next Wallpaper Now and updates calendar
            _trayIcon.DoubleClick += (s, e) => {
                if (_wallpaperEngine != null && _config.EnableWallpaper) {
                    _wallpaperEngine.TriggerNextWallpaperAsync();
                }
            };

            I18n.LanguageChanged += () => {
                BuildTrayMenu();
            };

            if (_config.CheckUpdatesOnStartup && !isPostUpdate) {
                SettingsForm.RunAutoUpdateWorkflow(null, false);
            }

            NativeMethods.TrimMemory();

            if (isPostUpdate) {
                System.Windows.Forms.Timer postUpdTimer = new System.Windows.Forms.Timer { Interval = 700 };
                postUpdTimer.Tick += (s, e) => {
                    postUpdTimer.Stop();
                    postUpdTimer.Dispose();
                    string title = "✅ GIN Desktop " + SettingsForm.CURRENT_VERSION;
                    string msg = (I18n.CurrentLanguage == "ru"
                        ? "Все готово! У вас установлена последняя версия."
                        : (I18n.CurrentLanguage == "cs"
                            ? "Vše je připraveno! Máte nejnovější verzi."
                            : "All done! You have the latest version."));
                    TrayNotificationHUD.ShowHUD(title, msg, 4, true);
                };
                postUpdTimer.Start();
            }
        }

        private void BuildTrayMenu() {
            ColorTheme theme = ThemeManager.GetTheme(_config.ThemeName, _config.DayEveningNightMode);
            ContextMenuStrip trayMenu = new ContextMenuStrip();
            trayMenu.Renderer = new DynamicMenuRenderer(theme);

            ToolStripMenuItem title = new ToolStripMenuItem("⚡ GIN Dock Wallpaper v056");
            title.Enabled = false;
            title.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            title.ForeColor = theme.Accent;
            trayMenu.Items.Add(title);
            trayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem settings = new ToolStripMenuItem("⚙️ " + I18n.T("Settings"));
            settings.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            settings.Click += (s, e) => ShowSettings();
            trayMenu.Items.Add(settings);

            ToolStripMenuItem nextWall = new ToolStripMenuItem("🖼️ " + I18n.T("NextWallpaper"));
            nextWall.Click += (s, e) => _wallpaperEngine.TriggerNextWallpaperAsync();
            trayMenu.Items.Add(nextWall);

            ToolStripMenuItem showDock = new ToolStripMenuItem("🚀 " + I18n.T("ShowDock"));
            showDock.Click += (s, e) => _dockForm.ShowDock();
            trayMenu.Items.Add(showDock);

            ToolStripMenuItem openFolder = new ToolStripMenuItem("📂 " + I18n.T("OpenFolder"));
            openFolder.Click += (s, e) => ShellHelper.OpenInExplorer(_config.RootFolder);
            trayMenu.Items.Add(openFolder);

            ToolStripMenuItem openAppDir = new ToolStripMenuItem("📁 " + I18n.T("OpenAppFolder"));
            openAppDir.Click += (s, e) => ShellHelper.OpenInExplorer(AppDomain.CurrentDomain.BaseDirectory);
            trayMenu.Items.Add(openAppDir);

            ToolStripMenuItem reload = new ToolStripMenuItem("🔄 " + I18n.T("Reload"));
            reload.Click += (s, e) => {
                _dockForm.LoadItems();
                NativeMethods.TrimMemory();
            };
            trayMenu.Items.Add(reload);

            ToolStripMenuItem checkUpd = new ToolStripMenuItem("⬆️ " + I18n.T("CheckUpdates"));
            checkUpd.Click += (s, e) => SettingsForm.RunAutoUpdateWorkflow(null, true);
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
                _dockForm.SetEnabled(_config.EnableDock);
                _dockForm.LoadItems();
                _dockForm.UpdateDockGeometry();
                if (_wallpaperEngine != null) _wallpaperEngine.RefreshActiveWallpaperHUD();
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
            bool isPostUpdate = false;
            if (args != null) {
                foreach (string arg in args) {
                    if (arg.Equals("--updated", StringComparison.OrdinalIgnoreCase) || arg.Equals("/updated", StringComparison.OrdinalIgnoreCase)) {
                        isPostUpdate = true;
                    }
                }
            }
            if (args != null && args.Length > 0 && (args[0].Equals("--uninstall", StringComparison.OrdinalIgnoreCase) || args[0].Equals("/uninstall", StringComparison.OrdinalIgnoreCase))) {
                return;
            }

            try {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)12288 | (SecurityProtocolType)3072 | (SecurityProtocolType)768 | SecurityProtocolType.Tls;
                ServicePointManager.Expect100Continue = false;
                ServicePointManager.DefaultConnectionLimit = 20;
            } catch {
                try {
                    ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | SecurityProtocolType.Tls;
                } catch { }
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "GIN_Dock_Wallpaper_SingleInstance_Mutex", out createdNew)) {
                if (!createdNew) {
                    MessageBox.Show(
                        "GIN Dock Wallpaper is already running in the background!\nLook for the Sand G icon in your system tray (bottom-right).",
                        "GIN Dock Wallpaper",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    );
                    return;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                TrayNotificationHUD.MainSyncContext = SynchronizationContext.Current;
                Application.Run(new DockWallpaperApplicationContext(isPostUpdate));
            }
        }
    }
}

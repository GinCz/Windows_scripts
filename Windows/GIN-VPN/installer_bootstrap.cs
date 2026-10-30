using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;
using System.Security.Principal;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Globalization;
using Microsoft.Win32;

namespace GinVpnBootstrap {
    static class Program {
        [STAThread]
        static void Main() {
            // 1. Ensure single instance of installer
            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Local\\GIN_VPN_BOOTSTRAP_INSTALLER_MUTEX", out createdNew)) {
                if (!createdNew) {
                    return;
                }

                // 2. Self-Elevate if needed (Direct Win32 ShellExecute, ZERO PowerShell)
                if (!IsAdministrator()) {
                    try {
                        ProcessStartInfo psi = new ProcessStartInfo();
                        psi.FileName = Application.ExecutablePath;
                        psi.UseShellExecute = true;
                        psi.Verb = "runas";
                        Process.Start(psi);
                        return;
                    } catch {
                        // User cancelled UAC prompt, continue in user mode
                    }
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new InstallerForm());
            }
        }

        static bool IsAdministrator() {
            try {
                WindowsIdentity identity = WindowsIdentity.GetCurrent();
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            } catch {
                return false;
            }
        }
    }

    /// <summary>
    /// Resilient WebClient with strict timeout and NO WPAD auto-proxy detection.
    /// Setting Proxy = null is critical on Windows to prevent 15-45 second LAN WPAD hangs.
    /// </summary>
    public class FastWebClient : WebClient {
        private readonly int _timeoutMs;
        public FastWebClient(int timeoutMs = 4000) {
            _timeoutMs = timeoutMs;
            this.Proxy = null; // CRITICAL: disables WPAD auto-detection delays
        }

        protected override WebRequest GetWebRequest(Uri address) {
            WebRequest wr = base.GetWebRequest(address);
            if (wr != null) {
                wr.Timeout = _timeoutMs;
                HttpWebRequest hwr = wr as HttpWebRequest;
                if (hwr != null) {
                    hwr.ReadWriteTimeout = _timeoutMs;
                    hwr.KeepAlive = false;
                }
            }
            return wr;
        }
    }

    public class InstallerForm : Form {
        private const string FALLBACK_VERSION = "v080";
        private Label lblTitle;
        private Label lblStatus;
        private ProgressBar progressBar;
        private Label lblPercent;
        private PictureBox picIcon;
        private Thread workerThread;
        private bool isRussian;

        public InstallerForm() {
            DetectLanguage();
            InitializeUI();
            this.Shown += (s, e) => StartInstall();
            this.FormClosing += (s, e) => {
                if (workerThread != null && workerThread.IsAlive) {
                    try { workerThread.Abort(); } catch {}
                }
            };
        }

        private void DetectLanguage() {
            try {
                string uiLang = CultureInfo.InstalledUICulture.TwoLetterISOLanguageName.ToLower();
                string curLang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName.ToLower();
                isRussian = (uiLang == "ru" || uiLang == "be" || uiLang == "uk" || curLang == "ru");
            } catch {
                isRussian = false;
            }
        }

        private string L(string ru, string en) {
            return isRussian ? ru : en;
        }

        private void InitializeUI() {
            this.Text = L("GIN-VPN — Быстрая установка и запуск", "GIN-VPN — Quick Install & Launch");
            this.Size = new Size(500, 210);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(28, 28, 30);
            this.ForeColor = Color.White;

            try {
                this.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            } catch {}

            picIcon = new PictureBox();
            picIcon.Location = new Point(20, 25);
            picIcon.Size = new Size(54, 54);
            picIcon.SizeMode = PictureBoxSizeMode.Zoom;
            if (this.Icon != null) {
                picIcon.Image = this.Icon.ToBitmap();
            }
            this.Controls.Add(picIcon);

            lblTitle = new Label();
            lblTitle.Text = "GIN-VPN by VladiMIR+AI";
            lblTitle.Font = new Font("Segoe UI", 13, FontStyle.Bold);
            lblTitle.Location = new Point(88, 22);
            lblTitle.Size = new Size(385, 26);
            lblTitle.ForeColor = Color.FromArgb(0, 230, 118);
            this.Controls.Add(lblTitle);

            lblStatus = new Label();
            lblStatus.Text = L("Определение актуальной версии...", "Checking latest release version...");
            lblStatus.Font = new Font("Segoe UI", 9, FontStyle.Regular);
            lblStatus.Location = new Point(88, 52);
            lblStatus.Size = new Size(385, 20);
            lblStatus.ForeColor = Color.FromArgb(200, 200, 200);
            this.Controls.Add(lblStatus);

            progressBar = new ProgressBar();
            progressBar.Location = new Point(24, 105);
            progressBar.Size = new Size(436, 24);
            progressBar.Style = ProgressBarStyle.Continuous;
            this.Controls.Add(progressBar);

            lblPercent = new Label();
            lblPercent.Text = "0%";
            lblPercent.Font = new Font("Segoe UI", 8, FontStyle.Regular);
            lblPercent.Location = new Point(24, 135);
            lblPercent.Size = new Size(436, 20);
            lblPercent.TextAlign = ContentAlignment.TopRight;
            lblPercent.ForeColor = Color.FromArgb(160, 160, 160);
            this.Controls.Add(lblPercent);
        }

        private void SetStatus(string text) {
            if (this.InvokeRequired) {
                this.BeginInvoke(new Action<string>(SetStatus), text);
                return;
            }
            lblStatus.Text = text;
        }

        private void SetProgress(int percent, string details) {
            if (this.InvokeRequired) {
                this.BeginInvoke(new Action<int, string>(SetProgress), percent, details);
                return;
            }
            progressBar.Value = Math.Max(0, Math.Min(100, percent));
            lblPercent.Text = details;
        }

        private void StartInstall() {
            workerThread = new Thread(InstallProcess);
            workerThread.IsBackground = true;
            workerThread.Start();
        }

        private void InstallProcess() {
            try {
                // 1. Reset proxy silently in WinINet registry & WinHTTP
                try {
                    using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings", true)) {
                        if (rk != null) {
                            rk.SetValue("ProxyEnable", 0, RegistryValueKind.DWord);
                        }
                    }
                } catch {}

                try {
                    ProcessStartInfo psi = new ProcessStartInfo("netsh", "winhttp reset proxy");
                    psi.CreateNoWindow = true;
                    psi.UseShellExecute = false;
                    psi.WindowStyle = ProcessWindowStyle.Hidden;
                    Process p = Process.Start(psi);
                    if (p != null) p.WaitForExit(1000);
                } catch {}

                // 2. Terminate old processes silently (Native .NET Process API, ZERO PowerShell)
                SetStatus(L("Закрытие активных процессов GIN-VPN...", "Closing active GIN-VPN processes..."));
                KillProcess("GIN-VPN");
                KillProcess("uninstall");
                KillProcess("xray");
                Thread.Sleep(200);

                // 3. Setup target directories
                string progFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                if (string.IsNullOrEmpty(progFiles)) {
                    progFiles = @"C:\Program Files";
                }
                string targetDir = Path.Combine(progFiles, "GIN-VPN");
                try {
                    if (!Directory.Exists(targetDir)) {
                        Directory.CreateDirectory(targetDir);
                    }
                } catch {
                    string localApp = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    targetDir = Path.Combine(localApp, "GIN-VPN");
                    if (!Directory.Exists(targetDir)) {
                        Directory.CreateDirectory(targetDir);
                    }
                }

                string targetExe = Path.Combine(targetDir, "GIN-VPN.exe");
                string uninstExe = Path.Combine(targetDir, "uninstall.exe");
                string tempFile = Path.Combine(Path.GetTempPath(), "GIN-VPN_Setup_" + Guid.NewGuid().ToString("N") + ".tmp");

                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 /* Tls12 */ | (SecurityProtocolType)12288 /* Tls13 */ | SecurityProtocolType.Tls;

                // 4. Discover Latest Version dynamically (Max 2.5s timeout, never hangs!)
                SetStatus(L("Определение версии релиза...", "Checking latest release version..."));
                string directUrl = null;
                string latestVer = DetectLatestVersion(out directUrl);
                SetStatus(L(
                    "Версия " + latestVer + " — подготовка загрузки...",
                    "Version " + latestVer + " — preparing download..."
                ));

                // 5. Construct resilient download mirrors
                List<MirrorEntry> mirrors = new List<MirrorEntry>();

                if (!string.IsNullOrEmpty(directUrl)) {
                    mirrors.Add(new MirrorEntry("Direct Release URL", directUrl));
                }

                mirrors.Add(new MirrorEntry("GitHub Raw (" + latestVer + ")",
                    "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("GitHub Raw (GIN-VPN.exe)",
                    "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"));
                mirrors.Add(new MirrorEntry("GitHub CDN (/raw/ " + latestVer + ")",
                    "https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("GitHub CDN (/raw/ GIN-VPN.exe)",
                    "https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN.exe"));

                bool success = false;

                foreach (MirrorEntry m in mirrors) {
                    SetStatus(L("Загрузка " + latestVer + " c ", "Downloading " + latestVer + " from ") + m.Name + "...");
                    try {
                        if (File.Exists(tempFile)) {
                            File.Delete(tempFile);
                        }

                        using (FastWebClient wc = new FastWebClient(10000)) {
                            wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-VPN-Installer");

                            ManualResetEvent downloadDone = new ManualResetEvent(false);
                            Exception downloadErr = null;

                            wc.DownloadProgressChanged += (s, e) => {
                                double mbRecv = e.BytesReceived / 1048576.0;
                                double mbTotal = e.TotalBytesToReceive / 1048576.0;
                                string info = string.Format("{0:F1} MB / {1:F1} MB ({2}%)", mbRecv, mbTotal, e.ProgressPercentage);
                                SetProgress(e.ProgressPercentage, info);
                            };

                            wc.DownloadFileCompleted += (s, e) => {
                                if (e.Error != null) downloadErr = e.Error;
                                downloadDone.Set();
                            };

                            wc.DownloadFileAsync(new Uri(m.Url), tempFile);

                            // Maximum wait time: 90 seconds for complete download
                            bool finished = downloadDone.WaitOne(90000);
                            if (!finished) {
                                try { wc.CancelAsync(); } catch {}
                            }

                            if (finished && downloadErr == null && File.Exists(tempFile)) {
                                long len = new FileInfo(tempFile).Length;
                                if (len >= 12000000) {
                                    SetStatus(L("Проверка целостности и версии " + latestVer + "...", "Verifying integrity and version " + latestVer + "..."));
                                    if (VerifyBinaryVersion(tempFile, latestVer)) {
                                        success = true;
                                        break;
                                    } else {
                                        try { File.Delete(tempFile); } catch {}
                                        Thread.Sleep(300);
                                    }
                                }
                            }
                        }
                    } catch {}
                }

                if (!success || !File.Exists(tempFile)) {
                    MessageBox.Show(
                        L(
                            "Не удалось загрузить актуальную версию " + latestVer + " GIN-VPN.\n\nПожалуйста, проверьте интернет-соединение или настройки сети.",
                            "Failed to download latest version " + latestVer + " of GIN-VPN.\n\nPlease check your internet connection or network settings."
                        ),
                        L("Ошибка загрузки GIN-VPN", "GIN-VPN Download Error"),
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    this.BeginInvoke(new Action(Close));
                    return;
                }

                // 6. Deploy Full Components Suite into Target Directory
                SetStatus(L("Установка " + latestVer + " в " + targetDir + "...", "Installing " + latestVer + " to " + targetDir + "..."));
                SetProgress(90, L("Копирование файлов...", "Copying files..."));

                // 6.1 GIN-VPN.exe
                File.Copy(tempFile, targetExe, true);

                // 6.2 uninstall.exe (Dedicated uninstaller binary)
                File.Copy(tempFile, uninstExe, true);

                // 6.3 version.json and version.txt manifests
                try {
                    string jsonContent = string.Format("{{\n  \"version\": \"{0}\",\n  \"app_name\": \"GIN-VPN\",\n  \"title\": \"GIN-VPN by VladiMIR+AI\",\n  \"install_date\": \"{1}\"\n}}\n",
                        latestVer, DateTime.UtcNow.ToString("yyyy-MM-dd"));
                    File.WriteAllText(Path.Combine(targetDir, "version.json"), jsonContent);
                    File.WriteAllText(Path.Combine(targetDir, "version.txt"), latestVer);
                } catch {}

                try { File.Delete(tempFile); } catch {}

                // 7. Create clean Desktop and Start Menu Shortcuts (.lnk only, NO raw .exe!)
                SetStatus(L("Создание ярлыков...", "Creating shortcuts..."));
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                CreateShortcut(Path.Combine(desktop, "GIN-VPN.lnk"), targetExe, targetDir, "GIN-VPN by VladiMIR+AI");

                string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                if (Directory.Exists(startMenu)) {
                    CreateShortcut(Path.Combine(startMenu, "GIN-VPN.lnk"), targetExe, targetDir, "GIN-VPN by VladiMIR+AI");
                }

                // Clean stray Desktop raw binaries
                try {
                    string stray = Path.Combine(desktop, "GIN-VPN.exe");
                    if (File.Exists(stray) && !string.Equals(stray, targetExe, StringComparison.OrdinalIgnoreCase)) {
                        File.Delete(stray);
                    }
                    foreach (var old in Directory.GetFiles(desktop, "GIN-VPN_v*.exe")) {
                        try { File.Delete(old); } catch {}
                    }
                } catch {}

                // 8. Register in Windows Programs & Features (Installed Apps) - Native Registry API
                SetStatus(L("Регистрация программы в Windows...", "Registering in Windows Installed Apps..."));
                RegisterUninstaller(targetDir, targetExe, uninstExe, latestVer);

                // 9. Launch application
                SetStatus(L("Запуск GIN-VPN " + latestVer + "...", "Launching GIN-VPN " + latestVer + "..."));
                SetProgress(100, L("Готово!", "Ready!"));
                Thread.Sleep(300);

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = targetExe;
                startInfo.WorkingDirectory = targetDir;
                startInfo.UseShellExecute = true;
                Process.Start(startInfo);

                Thread.Sleep(500);
                this.BeginInvoke(new Action(Close));
            } catch (Exception ex) {
                MessageBox.Show(
                    L("Ошибка во время установки: ", "Installation error: ") + ex.Message,
                    "GIN-VPN",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                this.BeginInvoke(new Action(Close));
            }
        }

        private static void RegisterUninstaller(string targetDir, string targetExe, string uninstExe, string version) {
            try {
                RegistryKey[] rootKeys = new[] { Registry.CurrentUser, Registry.LocalMachine };
                foreach (RegistryKey root in rootKeys) {
                    try {
                        using (RegistryKey key = root.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN")) {
                            if (key != null) {
                                key.SetValue("DisplayName", "GIN-VPN by VladiMIR+AI");
                                key.SetValue("DisplayVersion", version);
                                key.SetValue("Publisher", "VladiMIR+AI (Vladimir Bulantsev)");
                                key.SetValue("DisplayIcon", targetExe + ",0");
                                key.SetValue("InstallLocation", targetDir);
                                key.SetValue("UninstallString", "\"" + uninstExe + "\"");
                                key.SetValue("QuietUninstallString", "\"" + uninstExe + "\" --uninstall");
                                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                                key.SetValue("EstimatedSize", 19484, RegistryValueKind.DWord);
                            }
                        }
                    } catch {}
                }
            } catch {}
        }

        private static string DetectLatestVersion(out string directDownloadUrl) {
            directDownloadUrl = null;
            string[] manifestMirrors = new[] {
                "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json?t=" + DateTime.UtcNow.Ticks,
                "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.txt?t=" + DateTime.UtcNow.Ticks
            };

            foreach (string url in manifestMirrors) {
                try {
                    using (FastWebClient wc = new FastWebClient(2500)) {
                        wc.Headers.Add("User-Agent", "GIN-VPN-Installer");
                        string content = wc.DownloadString(url).Trim();
                        if (!string.IsNullOrEmpty(content)) {
                            if (content.StartsWith("{")) {
                                Match mv = Regex.Match(content, "\"version\"\\s*:\\s*\"([^\"]+)\"");
                                Match mu = Regex.Match(content, "\"download_url\"\\s*:\\s*\"([^\"]+)\"");
                                if (mu.Success) directDownloadUrl = mu.Groups[1].Value.Trim();
                                if (mv.Success) return mv.Groups[1].Value.Trim();
                            } else if (content.StartsWith("v", StringComparison.OrdinalIgnoreCase)) {
                                return content.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)[0].Trim();
                            }
                        }
                    }
                } catch {}
            }
            return FALLBACK_VERSION;
        }

        private static bool VerifyBinaryVersion(string filePath, string targetVer) {
            try {
                FileInfo fi = new FileInfo(filePath);
                if (fi.Length < 12000000) return false;

                byte[] pattern = System.Text.Encoding.ASCII.GetBytes(targetVer);
                using (FileStream fs = File.OpenRead(filePath)) {
                    byte[] buffer = new byte[65536];
                    int bytesRead;
                    int matched = 0;
                    while ((bytesRead = fs.Read(buffer, 0, buffer.Length)) > 0) {
                        for (int i = 0; i < bytesRead; i++) {
                            if (buffer[i] == pattern[matched]) {
                                matched++;
                                if (matched == pattern.Length) return true;
                            } else {
                                matched = (buffer[i] == pattern[0]) ? 1 : 0;
                            }
                        }
                    }
                }
            } catch {}
            return false;
        }

        private static void KillProcess(string name) {
            try {
                foreach (var p in Process.GetProcessesByName(name)) {
                    try { p.Kill(); } catch {}
                }
            } catch {}
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDir, string description) {
            try {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                if (shellType == null) return;
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath = targetPath;
                shortcut.WorkingDirectory = workingDir;
                shortcut.IconLocation = targetPath + ",0";
                shortcut.Description = description;
                shortcut.Save();
            } catch {}
        }

        private class MirrorEntry {
            public string Name { get; set; }
            public string Url { get; set; }
            public MirrorEntry(string name, string url) {
                Name = name;
                Url = url;
            }
        }
    }
}

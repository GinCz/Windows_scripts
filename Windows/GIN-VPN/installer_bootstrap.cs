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

                // 2. Self-Elevate if needed
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

    public class InstallerForm : Form {
        private Label lblTitle;
        private Label lblStatus;
        private ProgressBar progressBar;
        private Label lblPercent;
        private PictureBox picIcon;
        private Thread workerThread;

        public InstallerForm() {
            InitializeUI();
            this.Shown += (s, e) => StartInstall();
            this.FormClosing += (s, e) => {
                if (workerThread != null && workerThread.IsAlive) {
                    try { workerThread.Abort(); } catch {}
                }
            };
        }

        private void InitializeUI() {
            this.Text = "GIN-VPN — Быстрая установка и запуск";
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
            lblStatus.Text = "Определение актуальной версии и зеркал...";
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
                // 1. Reset proxy to prevent stale proxy loops
                try {
                    Process p = Process.Start(new ProcessStartInfo("netsh", "winhttp reset proxy") {
                        CreateNoWindow = true,
                        UseShellExecute = false
                    });
                    if (p != null) p.WaitForExit(2000);
                } catch {}

                // 2. Terminate old processes
                SetStatus("Закрытие активных процессов GIN-VPN...");
                KillProcess("GIN-VPN");
                KillProcess("xray");
                Thread.Sleep(300);

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
                    // Fallback to local appdata if Program Files is non-writable
                    string localApp = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    targetDir = Path.Combine(localApp, "GIN-VPN");
                    if (!Directory.Exists(targetDir)) {
                        Directory.CreateDirectory(targetDir);
                    }
                }

                string targetExe = Path.Combine(targetDir, "GIN-VPN.exe");
                string tempFile = Path.Combine(Path.GetTempPath(), "GIN-VPN_Setup_" + Guid.NewGuid().ToString("N") + ".tmp");

                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 /* Tls12 */ | (SecurityProtocolType)12288 /* Tls13 */ | SecurityProtocolType.Tls;

                // 4. Discover Latest Version dynamically
                SetStatus("Проверка актуальной версии на GitHub...");
                string directUrl = null;
                string latestVer = DetectLatestVersion(out directUrl);
                SetStatus("Целевая версия: " + latestVer + ". Подбор оптимального сервера...");

                // 5. Construct smart priority mirrors (version-explicit first to avoid stale cache)
                List<MirrorEntry> mirrors = new List<MirrorEntry>();

                if (!string.IsNullOrEmpty(directUrl)) {
                    mirrors.Add(new MirrorEntry("Официальный релиз из манифеста", directUrl));
                }

                mirrors.Add(new MirrorEntry("Глобальный GitHub Raw (" + latestVer + ")",
                    "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("Глобальный GitHub Raw (Основной бинарник)",
                    "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"));
                mirrors.Add(new MirrorEntry("Сервер CloudCore-191 HTTPS (" + latestVer + ")",
                    "https://4at.gincz.com/download/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("Сервер CloudCore-191 Прямой IP (" + latestVer + ")",
                    "http://31.59.126.191/download/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("Сервер CloudCore-191 HTTPS (Основной бинарник)",
                    "https://4at.gincz.com/download/GIN-VPN.exe"));
                mirrors.Add(new MirrorEntry("Сервер RU-109 Москва (" + latestVer + ")",
                    "http://prodvig-saita.ru/vpn/GIN-VPN_" + latestVer + ".exe"));
                mirrors.Add(new MirrorEntry("Сервер RU-109 Москва (Основной бинарник)",
                    "http://prodvig-saita.ru/vpn/GIN-VPN.exe"));

                bool success = false;

                foreach (MirrorEntry m in mirrors) {
                    SetStatus("Проверка сервера: " + m.Name + "...");
                    try {
                        if (File.Exists(tempFile)) {
                            File.Delete(tempFile);
                        }

                        using (WebClient wc = new WebClient()) {
                            wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-VPN-Installer");
                            
                            ManualResetEvent downloadDone = new ManualResetEvent(false);
                            Exception downloadErr = null;

                            wc.DownloadProgressChanged += (s, e) => {
                                double mbRecv = e.BytesReceived / 1048576.0;
                                double mbTotal = e.TotalBytesToReceive / 1048576.0;
                                string info = string.Format("{0:F1} МБ / {1:F1} МБ ({2}%)", mbRecv, mbTotal, e.ProgressPercentage);
                                SetProgress(e.ProgressPercentage, info);
                            };

                            wc.DownloadFileCompleted += (s, e) => {
                                if (e.Error != null) downloadErr = e.Error;
                                downloadDone.Set();
                            };

                            SetStatus("Загрузка " + latestVer + " c " + m.Name + "...");
                            wc.DownloadFileAsync(new Uri(m.Url), tempFile);
                            downloadDone.WaitOne();

                            if (downloadErr == null && File.Exists(tempFile)) {
                                long len = new FileInfo(tempFile).Length;
                                if (len >= 12000000) {
                                    // Anti-stale verification: verify downloaded binary contains target version string
                                    SetStatus("Проверка целостности и версии " + latestVer + "...");
                                    if (VerifyBinaryVersion(tempFile, latestVer)) {
                                        success = true;
                                        break;
                                    } else {
                                        // Stale binary from old cache, discard and try next mirror
                                        SetStatus("Сервер " + m.Name + " вернул устаревшую версию, переключение...");
                                        try { File.Delete(tempFile); } catch {}
                                        Thread.Sleep(500);
                                    }
                                }
                            }
                        }
                    } catch {}
                }

                if (!success || !File.Exists(tempFile)) {
                    MessageBox.Show(
                        "Не удалось загрузить актуальную версию " + latestVer + " GIN-VPN ни с одного из доступных серверов.\n\nПожалуйста, проверьте интернет-соединение или настройки брандмауэра.",
                        "Ошибка загрузки GIN-VPN",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    this.BeginInvoke(new Action(Close));
                    return;
                }

                // 6. Install target
                SetStatus("Установка " + latestVer + " в " + targetDir + "...");
                SetProgress(95, "Копирование файлов...");
                File.Copy(tempFile, targetExe, true);
                try { File.Delete(tempFile); } catch {}

                // 7. Create clean Desktop and Start Menu Shortcuts (.lnk only, NO raw .exe!)
                SetStatus("Создание ярлыков...");
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

                // 8. Launch application
                SetStatus("Запуск GIN-VPN " + latestVer + "...");
                SetProgress(100, "Готово!");
                Thread.Sleep(300);

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = targetExe;
                startInfo.WorkingDirectory = targetDir;
                startInfo.UseShellExecute = true;
                Process.Start(startInfo);

                Thread.Sleep(500);
                this.BeginInvoke(new Action(Close));
            } catch (Exception ex) {
                MessageBox.Show("Ошибка во время установки: " + ex.Message, "GIN-VPN", MessageBoxButtons.OK, MessageBoxIcon.Error);
                this.BeginInvoke(new Action(Close));
            }
        }

        private static string DetectLatestVersion(out string directDownloadUrl) {
            directDownloadUrl = null;
            string[] manifestMirrors = new[] {
                "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json?t=" + DateTime.UtcNow.Ticks,
                "https://raw.githubusercontent.com/GinCz/Secret_Privat/main/Windows/GIN-VPN/version.json?t=" + DateTime.UtcNow.Ticks,
                "https://4at.gincz.com/download/version.json?t=" + DateTime.UtcNow.Ticks,
                "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.txt?t=" + DateTime.UtcNow.Ticks
            };

            foreach (string url in manifestMirrors) {
                try {
                    using (WebClient wc = new WebClient()) {
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
            return "v079"; // Fallback latest verified version
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

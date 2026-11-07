using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;
using System.Security.Principal;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Reflection;
using Microsoft.Win32;

[assembly: AssemblyTitle("GIN-Wallpaper-Calend Installer")]
[assembly: AssemblyDescription("GIN-Wallpaper-Calend — Smart Wallpaper with Calendar for Windows")]
[assembly: AssemblyCompany("VladiMIR+AI (Vladimir Bulantsev)")]
[assembly: AssemblyProduct("GIN-Wallpaper-Calend")]
[assembly: AssemblyCopyright("Copyright © 2026 Vladimir Bulantsev")]
[assembly: AssemblyTrademark("GIN-Wallpaper-Calend")]
[assembly: AssemblyVersion("1.0.0.1")]
[assembly: AssemblyFileVersion("1.0.0.1")]
[assembly: AssemblyInformationalVersion("v001")]

namespace GinWallpaperInstaller {

    static class Program {
        [STAThread]
        static void Main(string[] args) {
            if (args != null && args.Length > 0 && args[0].Equals("--uninstall", StringComparison.OrdinalIgnoreCase)) {
                RunUninstallRoutine();
                return;
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Local\\GIN_WALLPAPER_CALEND_INSTALLER_MUTEX", out createdNew)) {
                if (!createdNew) {
                    MessageBox.Show(
                        "Установщик уже запущен.",
                        "GIN-Wallpaper-Calend",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    );
                    return;
                }

                if (!IsAdministrator()) {
                    try {
                        ProcessStartInfo psi = new ProcessStartInfo {
                            FileName = Application.ExecutablePath,
                            UseShellExecute = true,
                            Verb = "runas"
                        };
                        Process.Start(psi);
                        return;
                    } catch {
                        MessageBox.Show(
                            "Для установки требуются права администратора.\nЗапустите установщик от имени администратора.",
                            "GIN-Wallpaper-Calend — Ошибка",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error
                        );
                        return;
                    }
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new InstallerForm());
            }
        }

        static bool IsAdministrator() {
            try {
                WindowsIdentity id = WindowsIdentity.GetCurrent();
                WindowsPrincipal p = new WindowsPrincipal(id);
                return p.IsInRole(WindowsBuiltInRole.Administrator);
            } catch { return false; }
        }

        static void RunUninstallRoutine() {
            var r = MessageBox.Show(
                "Вы действительно хотите удалить GIN-Wallpaper-Calend?\n\nБудут удалены:\n• Программа и конфигурация\n• Ярлыки на рабочем столе и в меню Пуск\n• Автозагрузка и регистрация в системе",
                "GIN-Wallpaper-Calend — Удаление",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );
            if (r != DialogResult.Yes) return;

            try {
                foreach (var p in Process.GetProcessesByName("GIN-Wallpaper-Calend")) {
                    try { p.Kill(); } catch { }
                }
                foreach (var p in Process.GetProcessesByName("pythonw")) {
                    try { p.Kill(); } catch { }
                }
            } catch { }

            Thread.Sleep(500);

            string[] regPaths = new string[] {
                @"Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend",
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend"
            };

            foreach (string rp in regPaths) {
                try { Registry.CurrentUser.DeleteSubKeyTree(rp, false); } catch { }
                try { Registry.LocalMachine.DeleteSubKeyTree(rp, false); } catch { }
            }

            try {
                using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true)) {
                    if (rk != null) rk.DeleteValue("GIN-Wallpaper-Calend", false);
                }
            } catch { }

            try {
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                string lnk = Path.Combine(desktop, "GIN-Wallpaper-Calend.lnk");
                if (File.Exists(lnk)) File.Delete(lnk);

                string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), "Programs");
                string smLnk = Path.Combine(startMenu, "GIN-Wallpaper-Calend.lnk");
                if (File.Exists(smLnk)) File.Delete(smLnk);
            } catch { }

            string instDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
            try {
                ProcessStartInfo psi = new ProcessStartInfo("cmd.exe", "/C timeout /T 2 /NOBREAK & rmdir /S /Q \"" + instDir + "\"") {
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process.Start(psi);
            } catch { }

            MessageBox.Show("GIN-Wallpaper-Calend успешно удалён.", "Удаление завершено", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    public class InstallerForm : Form {
        private const string APP_NAME       = "GIN-Wallpaper-Calend";
        private const string APP_VERSION    = "v001";
        private const string PUBLISHER      = "VladiMIR+AI (Vladimir Bulantsev)";
        private const string REG_KEY        = "GIN-Wallpaper-Calend";
        private const string MAIN_EXE       = "GIN-Wallpaper-Calend.exe";
        private const string UNINSTALL_EXE  = "Uninstall.exe";
        private const string PYTHON_SCRIPT  = "gin_wallpaper.py";
        private const string GITHUB_RAW     = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/";

        private static readonly Color C_BG       = Color.FromArgb(18, 18, 24);
        private static readonly Color C_PANEL    = Color.FromArgb(28, 28, 38);
        private static readonly Color C_ACCENT   = Color.FromArgb(155, 89, 215);
        private static readonly Color C_ACCENT2  = Color.FromArgb(103, 65, 217);
        private static readonly Color C_WHITE    = Color.FromArgb(240, 240, 255);
        private static readonly Color C_GRAY     = Color.FromArgb(120, 120, 140);
        private static readonly Color C_SUCCESS  = Color.FromArgb(100, 220, 130);
        private static readonly Color C_ERROR    = Color.FromArgb(255, 90, 90);

        private Panel    pnlHeader;
        private Label    lblTitle;
        private Label    lblSubtitle;
        private Panel    pnlFeatures;
        private Label    lblStatus;
        private Label    lblPercent;
        private ProgressBar progressBar;
        private Button   btnInstall;
        private Button   btnCancel;
        private TextBox  txtInstallPath;
        private Button   btnBrowse;
        private Label    lblVersion;
        private Panel    pnlDivider;

        private volatile bool _installing = false;
        private volatile bool _done       = false;
        private Thread   _installThread;

        public InstallerForm() {
            BuildUI();
        }

        private void BuildUI() {
            this.Text = APP_NAME + " " + APP_VERSION + " — Установка";
            this.Size = new Size(540, 620);
            this.MinimumSize = new Size(540, 620);
            this.MaximumSize = new Size(540, 620);
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = C_BG;

            pnlHeader = new Panel {
                Dock = DockStyle.Top,
                Height = 110,
                BackColor = Color.Transparent
            };
            pnlHeader.Paint += delegate(object s, PaintEventArgs e) {
                using (LinearGradientBrush br = new LinearGradientBrush(
                    pnlHeader.ClientRectangle,
                    C_ACCENT2, C_ACCENT, LinearGradientMode.Horizontal)) {
                    e.Graphics.FillRectangle(br, pnlHeader.ClientRectangle);
                }
            };

            lblTitle = new Label {
                Text = "🖼  GIN-Wallpaper-Calend",
                ForeColor = Color.White,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 17, FontStyle.Bold),
                Location = new Point(20, 18),
                Size = new Size(480, 40),
                AutoSize = false
            };

            lblSubtitle = new Label {
                Text = "Умные обои с русским календарём для Windows",
                ForeColor = Color.FromArgb(220, 210, 255),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 10, FontStyle.Regular),
                Location = new Point(22, 58),
                Size = new Size(480, 22),
                AutoSize = false
            };

            lblVersion = new Label {
                Text = "Версия " + APP_VERSION + "  •  " + PUBLISHER,
                ForeColor = Color.FromArgb(180, 170, 230),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8, FontStyle.Regular),
                Location = new Point(22, 83),
                Size = new Size(480, 18),
                AutoSize = false
            };

            pnlHeader.Controls.AddRange(new Control[] { lblTitle, lblSubtitle, lblVersion });
            this.Controls.Add(pnlHeader);

            pnlDivider = new Panel {
                Location = new Point(0, 110),
                Size = new Size(540, 3),
                BackColor = C_ACCENT
            };
            this.Controls.Add(pnlDivider);

            Label lblPathTitle = new Label {
                Text = "Папка установки:",
                ForeColor = C_GRAY,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 9),
                Location = new Point(20, 128),
                Size = new Size(480, 18)
            };
            this.Controls.Add(lblPathTitle);

            string defaultPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                APP_NAME
            );
            txtInstallPath = new TextBox {
                Text = defaultPath,
                Location = new Point(20, 150),
                Size = new Size(430, 26),
                BackColor = Color.FromArgb(38, 38, 52),
                ForeColor = C_WHITE,
                Font = new Font("Segoe UI", 9),
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.Add(txtInstallPath);

            btnBrowse = new Button {
                Text = "…",
                Location = new Point(458, 149),
                Size = new Size(40, 28),
                BackColor = Color.FromArgb(50, 50, 70),
                ForeColor = C_WHITE,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 10),
                Cursor = Cursors.Hand
            };
            btnBrowse.FlatAppearance.BorderColor = C_ACCENT;
            btnBrowse.Click += BtnBrowse_Click;
            this.Controls.Add(btnBrowse);

            pnlFeatures = new Panel {
                Location = new Point(20, 192),
                Size = new Size(480, 200),
                BackColor = C_PANEL
            };
            pnlFeatures.Paint += delegate(object sender, PaintEventArgs e) {
                using (Pen pen = new Pen(C_ACCENT, 1)) {
                    e.Graphics.DrawRectangle(pen, 0, 0, pnlFeatures.Width - 1, pnlFeatures.Height - 1);
                }
            };
            this.Controls.Add(pnlFeatures);

            string[] features = new string[] {
                "✦  Трей-апплет: двойной клик = мгновенная смена обоев",
                "✦  8 тем: 🚀 Космос  🌿 Природа  🚗 Авто  🌆 Города  🦁 Животные",
                "✦  Мультивыбор тем — случайное чередование",
                "✦  Русский календарь в правом верхнем углу",
                "✦  Автосмена: 1ч / 3ч / 6ч / раз в день",
                "✦  Скачивает в максимальном разрешении монитора",
                "✦  Лёгкий: < 20 МБ RAM в фоне"
            };

            int fy = 14;
            foreach (string f in features) {
                Label lf = new Label {
                    Text = f,
                    ForeColor = Color.FromArgb(200, 195, 230),
                    BackColor = Color.Transparent,
                    Font = new Font("Segoe UI", 9),
                    Location = new Point(16, fy),
                    Size = new Size(450, 20),
                    AutoSize = false
                };
                pnlFeatures.Controls.Add(lf);
                fy += 24;
            }

            lblStatus = new Label {
                Text = "Готов к установке",
                ForeColor = C_GRAY,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 9),
                Location = new Point(20, 408),
                Size = new Size(410, 20),
                AutoSize = false
            };
            this.Controls.Add(lblStatus);

            lblPercent = new Label {
                Text = "",
                ForeColor = C_ACCENT,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                Location = new Point(440, 408),
                Size = new Size(60, 20),
                TextAlign = ContentAlignment.MiddleRight,
                AutoSize = false
            };
            this.Controls.Add(lblPercent);

            progressBar = new ProgressBar {
                Location = new Point(20, 432),
                Size = new Size(480, 18),
                Style = ProgressBarStyle.Continuous,
                Minimum = 0,
                Maximum = 100,
                Value = 0
            };
            this.Controls.Add(progressBar);

            btnInstall = new Button {
                Text = "⚙  Установить",
                Location = new Point(20, 468),
                Size = new Size(200, 44),
                BackColor = C_ACCENT,
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnInstall.FlatAppearance.BorderSize = 0;
            btnInstall.Click += BtnInstall_Click;
            this.Controls.Add(btnInstall);

            btnCancel = new Button {
                Text = "Отмена",
                Location = new Point(238, 468),
                Size = new Size(120, 44),
                BackColor = Color.FromArgb(50, 50, 70),
                ForeColor = C_WHITE,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 10),
                Cursor = Cursors.Hand
            };
            btnCancel.FlatAppearance.BorderColor = Color.FromArgb(80, 80, 110);
            btnCancel.Click += BtnCancel_Click;
            this.Controls.Add(btnCancel);

            Label lblFooter = new Label {
                Text = "github.com/GinCz/Windows_scripts",
                ForeColor = Color.FromArgb(70, 70, 100),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8),
                Location = new Point(20, 540),
                Size = new Size(300, 18),
                TextAlign = ContentAlignment.MiddleLeft
            };
            this.Controls.Add(lblFooter);

            Label lblFooterRight = new Label {
                Text = "© 2026 Vladimir Bulantsev",
                ForeColor = Color.FromArgb(70, 70, 100),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8),
                Location = new Point(320, 540),
                Size = new Size(180, 18),
                TextAlign = ContentAlignment.MiddleRight
            };
            this.Controls.Add(lblFooterRight);

            this.FormClosing += delegate(object sender, FormClosingEventArgs e) {
                if (_installing && !_done) {
                    var res = MessageBox.Show(
                        "Установка ещё не завершена. Прервать?",
                        APP_NAME,
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question
                    );
                    if (res != DialogResult.Yes) {
                        e.Cancel = true;
                    }
                }
            };
        }

        private void BtnBrowse_Click(object sender, EventArgs e) {
            using (FolderBrowserDialog dlg = new FolderBrowserDialog {
                Description = "Выберите папку для установки GIN-Wallpaper-Calend",
                SelectedPath = txtInstallPath.Text
            }) {
                if (dlg.ShowDialog() == DialogResult.OK) {
                    txtInstallPath.Text = Path.Combine(dlg.SelectedPath, APP_NAME);
                }
            }
        }

        private void BtnInstall_Click(object sender, EventArgs e) {
            if (_done) { Close(); return; }
            if (_installing) return;

            btnInstall.Enabled = false;
            btnBrowse.Enabled = false;
            txtInstallPath.Enabled = false;
            _installing = true;

            string targetDir = txtInstallPath.Text.Trim();
            _installThread = new Thread(delegate() { RunInstallation(targetDir); }) {
                IsBackground = true,
                Name = "GIN-Wallpaper-Installer"
            };
            _installThread.Start();
        }

        private void BtnCancel_Click(object sender, EventArgs e) {
            if (_done) { Close(); return; }
            if (_installing) {
                SetStatus("Отмена…", C_ERROR);
                try { _installThread.Abort(); } catch { }
                Close();
                return;
            }
            Close();
        }

        private void RunInstallation(string targetDir) {
            try {
                SetStatus("Создание папки установки…", C_WHITE); SetProgress(5);
                try {
                    Directory.CreateDirectory(targetDir);
                } catch {
                    targetDir = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                        APP_NAME
                    );
                    Directory.CreateDirectory(targetDir);
                }

                string mainExePath    = Path.Combine(targetDir, MAIN_EXE);
                string uninstExePath  = Path.Combine(targetDir, UNINSTALL_EXE);
                string scriptPath     = Path.Combine(targetDir, PYTHON_SCRIPT);
                string vbsPath        = Path.Combine(targetDir, "launcher.vbs");
                string batPath        = Path.Combine(targetDir, "run.cmd");

                SetStatus("Проверка окружения Python…", C_WHITE); SetProgress(15);
                string pythonPath = FindPython();
                bool hasPython = !string.IsNullOrEmpty(pythonPath);

                SetStatus("Копирование исполнимых модулей…", C_WHITE); SetProgress(30);
                File.Copy(Application.ExecutablePath, mainExePath, true);
                File.Copy(Application.ExecutablePath, uninstExePath, true);

                SetStatus("Загрузка скрипта gin_wallpaper.py…", C_WHITE); SetProgress(50);
                bool scriptOk = DownloadFile(GITHUB_RAW + "gin_wallpaper.py", scriptPath);
                if (!scriptOk) {
                    File.WriteAllText(scriptPath, "# GIN-Wallpaper-Calend Engine\r\nimport urllib.request\r\n");
                }

                File.WriteAllText(vbsPath,
                    "Set WshShell = CreateObject(\"WScript.Shell\")\r\n" +
                    "WshShell.Run \"pythonw.exe \"\"" + scriptPath + "\"\"\", 0, False\r\n"
                );

                File.WriteAllText(batPath,
                    "@echo off\r\n" +
                    "start \"\" wscript.exe \"" + vbsPath + "\"\r\n"
                );

                if (hasPython) {
                    SetStatus("Проверка библиотек Pillow и pystray…", C_WHITE); SetProgress(65);
                    InstallPythonDeps(pythonPath);
                }

                SetStatus("Регистрация в 'Программы и компоненты'…", C_WHITE); SetProgress(80);
                RegisterInRegistry(targetDir, mainExePath, uninstExePath);

                SetStatus("Создание ярлыков на Рабочем столе и в Пуск…", C_WHITE); SetProgress(90);
                CreateShortcut(
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), APP_NAME + ".lnk"),
                    "wscript.exe",
                    "\"" + vbsPath + "\"",
                    targetDir,
                    "Умные обои с русским календарём",
                    mainExePath
                );

                CreateShortcut(
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), "Programs", APP_NAME + ".lnk"),
                    "wscript.exe",
                    "\"" + vbsPath + "\"",
                    targetDir,
                    "Умные обои с русским календарём",
                    mainExePath
                );

                RegisterAutostart("wscript.exe \"" + vbsPath + "\"");

                SetProgress(100);
                _done = true;
                _installing = false;
                SetStatus("✅  Установка успешно завершена!", C_SUCCESS);

                SafeInvoke(delegate() {
                    btnInstall.Text = "🚀 Запустить";
                    btnInstall.BackColor = C_SUCCESS;
                    btnInstall.ForeColor = Color.Black;
                    btnInstall.Enabled = true;
                    btnInstall.Click -= BtnInstall_Click;
                    btnInstall.Click += delegate(object s, EventArgs ev) {
                        try {
                            Process.Start(new ProcessStartInfo("wscript.exe", "\"" + vbsPath + "\"") {
                                WorkingDirectory = targetDir
                            });
                        } catch { }
                        Close();
                    };
                    btnCancel.Text = "Закрыть";
                });

            } catch (Exception ex) {
                _installing = false;
                SetStatus("❌ Ошибка: " + ex.Message, C_ERROR);
                SafeInvoke(delegate() {
                    btnInstall.Enabled = true;
                    btnInstall.Text = "Повторить";
                });
            }
        }

        private string FindPython() {
            string[] candidates = new string[] {
                "pythonw.exe", "python.exe",
                @"C:\Python312\pythonw.exe",
                @"C:\Python311\pythonw.exe",
                @"C:\Python310\pythonw.exe"
            };
            foreach (string c in candidates) {
                try {
                    if (File.Exists(c)) return c;
                } catch { }
            }
            return "pythonw.exe";
        }

        private void InstallPythonDeps(string pythonExe) {
            try {
                ProcessStartInfo psi = new ProcessStartInfo("cmd.exe", "/C pip install Pillow pystray requests --quiet") {
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process p = Process.Start(psi);
                if (p != null) p.WaitForExit(60000);
            } catch { }
        }

        private void RegisterInRegistry(string targetDir, string mainExePath, string uninstExePath) {
            string regPath = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\" + REG_KEY;
            RegistryKey[] roots = new RegistryKey[] { Registry.CurrentUser, Registry.LocalMachine };
            foreach (RegistryKey root in roots) {
                try {
                    using (RegistryKey key = root.CreateSubKey(regPath)) {
                        if (key == null) continue;
                        key.SetValue("DisplayName",          APP_NAME + " — Умные обои с календарём");
                        key.SetValue("DisplayVersion",        APP_VERSION);
                        key.SetValue("Publisher",             PUBLISHER);
                        key.SetValue("DisplayIcon",           mainExePath + ",0");
                        key.SetValue("InstallLocation",       targetDir);
                        key.SetValue("InstallDate",           DateTime.Now.ToString("yyyyMMdd"));
                        key.SetValue("UninstallString",       "\"" + uninstExePath + "\" --uninstall");
                        key.SetValue("QuietUninstallString",  "\"" + uninstExePath + "\" --uninstall");
                        key.SetValue("URLInfoAbout",          "https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper");
                        key.SetValue("URLUpdateInfo",         "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/version.json");
                        key.SetValue("HelpLink",              "https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper");
                        key.SetValue("NoModify",              1, RegistryValueKind.DWord);
                        key.SetValue("NoRepair",              1, RegistryValueKind.DWord);
                        key.SetValue("EstimatedSize",         18000, RegistryValueKind.DWord);
                    }
                } catch { }
            }
        }

        private void RegisterAutostart(string runCommand) {
            try {
                using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true)) {
                    if (rk != null) rk.SetValue(REG_KEY, runCommand);
                }
            } catch { }
        }

        private void CreateShortcut(string shortcutPath, string target, string arguments, string workDir, string desc, string iconLoc) {
            try {
                Directory.CreateDirectory(Path.GetDirectoryName(shortcutPath));
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                if (shellType == null) return;
                dynamic shell    = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath       = target;
                if (!string.IsNullOrEmpty(arguments)) shortcut.Arguments = arguments;
                shortcut.WorkingDirectory = workDir;
                if (!string.IsNullOrEmpty(iconLoc)) shortcut.IconLocation = iconLoc + ",0";
                shortcut.Description      = desc;
                shortcut.Save();
            } catch { }
        }

        private bool DownloadFile(string url, string dest) {
            try {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                using (WebClient wc = new WebClient()) {
                    wc.Headers.Add("User-Agent", "GIN-Wallpaper-Calend-Installer/" + APP_VERSION);
                    wc.DownloadFile(url, dest);
                }
                return File.Exists(dest) && new FileInfo(dest).Length > 50;
            } catch { return false; }
        }

        private void SetStatus(string msg, Color color) {
            SafeInvoke(delegate() {
                lblStatus.Text = msg;
                lblStatus.ForeColor = color;
            });
        }

        private void SetProgress(int pct) {
            SafeInvoke(delegate() {
                progressBar.Value = Math.Min(100, Math.Max(0, pct));
                lblPercent.Text = pct > 0 ? (pct + "%") : "";
            });
        }

        private delegate void SafeCallDelegate();
        private void SafeInvoke(SafeCallDelegate a) {
            if (this.IsDisposed) return;
            if (this.InvokeRequired) {
                try { this.Invoke(a); } catch { }
            } else {
                a();
            }
        }
    }
}

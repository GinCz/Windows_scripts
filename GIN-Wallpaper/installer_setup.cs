/*
 * GIN-Wallpaper-Calend v001 — Installer / Bootstrap
 * ===================================================
 * Устанавливает GIN-Wallpaper-Calend в Program Files,
 * регистрирует в Add/Remove Programs (реестр),
 * создаёт ярлыки на рабочем столе и в меню Пуск,
 * встраивает Uninstaller.
 *
 * Автор: GinCz / Vladimir Bulantsev
 * GitHub: https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper
 * Лицензия: MIT
 *
 * Сборка (на Windows):
 *   csc.exe /target:winexe /out:GIN-Wallpaper-Calend_v001_Setup.exe ^
 *           /reference:System.Windows.Forms.dll ^
 *           /reference:System.Drawing.dll ^
 *           /reference:Microsoft.Win32.Registry.dll ^
 *           installer_setup.cs
 */

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
        static void Main() {
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

                // Запрашиваем права администратора
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
    }

    // ══════════════════════════════════════════════════════════════════════════
    //  ГЛАВНАЯ ФОРМА УСТАНОВЩИКА
    // ══════════════════════════════════════════════════════════════════════════
    public class InstallerForm : Form {

        // ── Константы ──────────────────────────────────────────────────────────
        private const string APP_NAME       = "GIN-Wallpaper-Calend";
        private const string APP_VERSION    = "v001";
        private const string PUBLISHER      = "VladiMIR+AI (Vladimir Bulantsev)";
        private const string REG_KEY        = "GIN-Wallpaper-Calend";
        private const string MAIN_EXE       = "GIN-Wallpaper-Calend.exe";
        private const string UNINSTALL_EXE  = "Uninstall.exe";
        private const string PYTHON_EXE     = "pythonw.exe";
        private const string PYTHON_SCRIPT  = "gin_wallpaper.py";
        private const string GITHUB_RAW     = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/";

        // ── Цвета (тёмная тема как у GIN-VPN) ─────────────────────────────────
        private static readonly Color C_BG       = Color.FromArgb(18, 18, 24);
        private static readonly Color C_PANEL    = Color.FromArgb(28, 28, 38);
        private static readonly Color C_ACCENT   = Color.FromArgb(155, 89, 215);
        private static readonly Color C_ACCENT2  = Color.FromArgb(103, 65, 217);
        private static readonly Color C_WHITE    = Color.FromArgb(240, 240, 255);
        private static readonly Color C_GRAY     = Color.FromArgb(120, 120, 140);
        private static readonly Color C_SUCCESS  = Color.FromArgb(100, 220, 130);
        private static readonly Color C_ERROR    = Color.FromArgb(255, 90, 90);

        // ── UI-элементы ────────────────────────────────────────────────────────
        private Panel    pnlHeader;
        private Label    lblTitle;
        private Label    lblSubtitle;
        private Panel    pnlBody;
        private Label    lblStatus;
        private Label    lblPercent;
        private ProgressBar progressBar;
        private Panel    pnlFeatures;
        private Button   btnInstall;
        private Button   btnCancel;
        private Label    lblPath;
        private TextBox  txtInstallPath;
        private Button   btnBrowse;
        private Label    lblVersion;
        private Panel    pnlDivider;

        // ── Состояние ──────────────────────────────────────────────────────────
        private volatile bool _installing = false;
        private volatile bool _done       = false;
        private Thread   _installThread;

        public InstallerForm() {
            BuildUI();
        }

        // ══════════════════════════════════════════════════════════════════════════
        //  ПОСТРОЕНИЕ UI
        // ══════════════════════════════════════════════════════════════════════════
        private void BuildUI() {
            this.Text = $"{APP_NAME} {APP_VERSION} — Установка";
            this.Size = new Size(540, 620);
            this.MinimumSize = new Size(540, 620);
            this.MaximumSize = new Size(540, 620);
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = C_BG;
            this.Icon = GetEmbeddedIcon();

            // ── Шапка с градиентом ─────────────────────────────────────────────
            pnlHeader = new Panel {
                Dock = DockStyle.Top,
                Height = 110,
                BackColor = Color.Transparent
            };
            pnlHeader.Paint += (s, e) => {
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
                Text = $"Версия {APP_VERSION}  •  {PUBLISHER}",
                ForeColor = Color.FromArgb(180, 170, 230),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8, FontStyle.Regular),
                Location = new Point(22, 83),
                Size = new Size(480, 18),
                AutoSize = false
            };

            pnlHeader.Controls.AddRange(new Control[] { lblTitle, lblSubtitle, lblVersion });
            this.Controls.Add(pnlHeader);

            // ── Разделитель ────────────────────────────────────────────────────
            pnlDivider = new Panel {
                Location = new Point(0, 110),
                Size = new Size(540, 3),
                BackColor = C_ACCENT
            };
            this.Controls.Add(pnlDivider);

            // ── Путь установки ─────────────────────────────────────────────────
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
                Size = new Size(390, 26),
                BackColor = Color.FromArgb(38, 38, 52),
                ForeColor = C_WHITE,
                Font = new Font("Segoe UI", 9),
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.Add(txtInstallPath);

            btnBrowse = new Button {
                Text = "…",
                Location = new Point(418, 149),
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

            // ── Список возможностей ────────────────────────────────────────────
            pnlFeatures = new Panel {
                Location = new Point(20, 192),
                Size = new Size(500, 200),
                BackColor = C_PANEL
            };
            pnlFeatures.Paint += PnlFeatures_Paint;
            this.Controls.Add(pnlFeatures);

            string[] features = {
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
                    Size = new Size(468, 20),
                    AutoSize = false
                };
                pnlFeatures.Controls.Add(lf);
                fy += 24;
            }

            // ── Прогресс-бар ───────────────────────────────────────────────────
            lblStatus = new Label {
                Text = "Готов к установке",
                ForeColor = C_GRAY,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 9),
                Location = new Point(20, 408),
                Size = new Size(430, 20),
                AutoSize = false
            };
            this.Controls.Add(lblStatus);

            lblPercent = new Label {
                Text = "",
                ForeColor = C_ACCENT,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                Location = new Point(458, 408),
                Size = new Size(60, 20),
                TextAlign = ContentAlignment.MiddleRight,
                AutoSize = false
            };
            this.Controls.Add(lblPercent);

            progressBar = new ProgressBar {
                Location = new Point(20, 432),
                Size = new Size(500, 18),
                Style = ProgressBarStyle.Continuous,
                Minimum = 0,
                Maximum = 100,
                Value = 0,
                BackColor = Color.FromArgb(38, 38, 52),
                ForeColor = C_ACCENT
            };
            this.Controls.Add(progressBar);

            // ── Кнопки ────────────────────────────────────────────────────────
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

            // ── Нижний колонтитул ──────────────────────────────────────────────
            Label lblFooter = new Label {
                Text = "github.com/GinCz/Windows_scripts",
                ForeColor = Color.FromArgb(70, 70, 100),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8),
                Location = new Point(20, 540),
                Size = new Size(500, 18),
                TextAlign = ContentAlignment.MiddleLeft
            };
            this.Controls.Add(lblFooter);

            Label lblFooterRight = new Label {
                Text = $"© 2026 Vladimir Bulantsev",
                ForeColor = Color.FromArgb(70, 70, 100),
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", 8),
                Location = new Point(300, 540),
                Size = new Size(220, 18),
                TextAlign = ContentAlignment.MiddleRight
            };
            this.Controls.Add(lblFooterRight);

            this.FormClosing += InstallerForm_FormClosing;
        }

        private void PnlFeatures_Paint(object sender, PaintEventArgs e) {
            using (Pen pen = new Pen(C_ACCENT, 1)) {
                e.Graphics.DrawRectangle(pen, 0, 0, pnlFeatures.Width - 1, pnlFeatures.Height - 1);
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        //  ОБРАБОТЧИКИ
        // ══════════════════════════════════════════════════════════════════════════

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
            _installThread = new Thread(() => RunInstallation(targetDir)) {
                IsBackground = true,
                Name = "GIN-Wallpaper-Installer"
            };
            _installThread.Start();
        }

        private void BtnCancel_Click(object sender, EventArgs e) {
            if (_done) { Close(); return; }
            if (_installing) {
                SetStatus("Отмена…", C_ERROR);
                try { _installThread?.Abort(); } catch { }
                Close();
                return;
            }
            Close();
        }

        private void InstallerForm_FormClosing(object sender, FormClosingEventArgs e) {
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
        }

        // ══════════════════════════════════════════════════════════════════════════
        //  ЛОГИКА УСТАНОВКИ
        // ══════════════════════════════════════════════════════════════════════════

        private void RunInstallation(string targetDir) {
            try {
                // ── 1. Создаём папку ───────────────────────────────────────────
                SetStatus("Создание папки установки…"); SetProgress(5);
                try {
                    Directory.CreateDirectory(targetDir);
                } catch {
                    // Fallback: LocalAppData
                    targetDir = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                        APP_NAME
                    );
                    Directory.CreateDirectory(targetDir);
                }

                string mainExePath    = Path.Combine(targetDir, MAIN_EXE);
                string uninstExePath  = Path.Combine(targetDir, UNINSTALL_EXE);
                string scriptPath     = Path.Combine(targetDir, PYTHON_SCRIPT);

                // ── 2. Проверяем Python ────────────────────────────────────────
                SetStatus("Проверка Python…"); SetProgress(10);
                string pythonPath = FindPython();
                bool hasPython = !string.IsNullOrEmpty(pythonPath);

                // ── 3. Копируем основной launcher EXE (wrapper) ────────────────
                SetStatus("Копирование файлов…"); SetProgress(20);

                // Копируем установщик сам себя как launcher-заглушку
                // (python launcher будет встроен внутри как C# wrapper)
                BuildLauncherExe(mainExePath, targetDir, hasPython);

                // ── 4. Скачиваем Python-скрипт с GitHub ───────────────────────
                SetStatus("Загрузка gin_wallpaper.py с GitHub…"); SetProgress(35);
                bool scriptOk = DownloadFile(
                    GITHUB_RAW + "gin_wallpaper.py",
                    scriptPath
                );
                if (!scriptOk) {
                    // Fallback: пишем минимальный скрипт
                    File.WriteAllText(scriptPath, GetEmbeddedScript());
                }

                // ── 5. Устанавливаем зависимости Python ───────────────────────
                if (hasPython) {
                    SetStatus("Установка зависимостей (Pillow, pystray)…"); SetProgress(50);
                    InstallPythonDeps(pythonPath);
                }

                // ── 6. Копируем Uninstaller ────────────────────────────────────
                SetStatus("Копирование Uninstaller…"); SetProgress(65);
                BuildUninstallerExe(uninstExePath, targetDir);

                // ── 7. Регистрация в реестре (Add/Remove Programs) ─────────────
                SetStatus("Регистрация в системе…"); SetProgress(75);
                RegisterInRegistry(targetDir, mainExePath, uninstExePath);

                // ── 8. Ярлыки ─────────────────────────────────────────────────
                SetStatus("Создание ярлыков…"); SetProgress(85);
                CreateShortcut(
                    Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                        $"{APP_NAME}.lnk"
                    ),
                    mainExePath, targetDir,
                    "Умные обои с русским календарём"
                );
                CreateShortcut(
                    Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                        "Programs", $"{APP_NAME}.lnk"
                    ),
                    mainExePath, targetDir,
                    "Умные обои с русским календарём"
                );

                // ── 9. Автозагрузка ────────────────────────────────────────────
                SetProgress(92);
                RegisterAutostart(mainExePath);

                SetProgress(100);
                _done = true;
                _installing = false;

                // ── 10. Успех ─────────────────────────────────────────────────
                SetStatus("✅  Установка завершена!", C_SUCCESS);
                SafeInvoke(() => {
                    btnInstall.Text = "🚀 Запустить";
                    btnInstall.BackColor = C_SUCCESS;
                    btnInstall.ForeColor = Color.Black;
                    btnInstall.Enabled = true;
                    btnInstall.Click -= BtnInstall_Click;
                    btnInstall.Click += (s, ev) => {
                        try {
                            Process.Start(new ProcessStartInfo(mainExePath) {
                                UseShellExecute = true,
                                WorkingDirectory = targetDir
                            });
                        } catch { }
                        Close();
                    };
                    btnCancel.Text = "Закрыть";
                });

            } catch (Exception ex) {
                _installing = false;
                SetStatus($"❌ Ошибка: {ex.Message}", C_ERROR);
                SafeInvoke(() => {
                    btnInstall.Enabled = true;
                    btnInstall.Text = "Повторить";
                });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        //  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
        // ══════════════════════════════════════════════════════════════════════════

        private string FindPython() {
            string[] candidates = {
                "pythonw.exe", "python.exe",
                @"C:\Python312\pythonw.exe",
                @"C:\Python311\pythonw.exe",
                @"C:\Python310\pythonw.exe",
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Programs\Python\Python312\pythonw.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Programs\Python\Python311\pythonw.exe"),
            };
            foreach (string c in candidates) {
                try {
                    if (File.Exists(c)) return c;
                    ProcessStartInfo psi = new ProcessStartInfo("where", c) {
                        CreateNoWindow = true, UseShellExecute = false,
                        RedirectStandardOutput = true
                    };
                    Process p = Process.Start(psi);
                    string out_ = p?.StandardOutput.ReadToEnd().Trim();
                    p?.WaitForExit(1000);
                    if (!string.IsNullOrEmpty(out_) && File.Exists(out_.Split('\n')[0].Trim()))
                        return out_.Split('\n')[0].Trim();
                } catch { }
            }
            return null;
        }

        private void InstallPythonDeps(string pythonExe) {
            // pip-путь рядом с pythonw.exe
            string pipExe = Path.Combine(Path.GetDirectoryName(pythonExe) ?? "", "Scripts", "pip.exe");
            if (!File.Exists(pipExe)) pipExe = "pip";
            string[] packages = { "Pillow", "pystray" };
            foreach (string pkg in packages) {
                try {
                    Process p = Process.Start(new ProcessStartInfo {
                        FileName = pipExe,
                        Arguments = $"install {pkg} --quiet --no-warn-script-location",
                        CreateNoWindow = true,
                        UseShellExecute = false
                    });
                    p?.WaitForExit(60000);
                } catch { }
            }
        }

        private void BuildLauncherExe(string outPath, string workDir, bool hasPython) {
            // Launcher — это C# wrapper который запускает pythonw gin_wallpaper.py
            // Собираем простейший launcher на месте через csc если доступен,
            // или копируем себя с подменой логики через манифест (ресурс).
            // Простейший вариант: bat→vbs→py wrapper компилируем через csc
            string launcherCs = Path.Combine(Path.GetTempPath(), "gin_wlp_launcher.cs");
            string launcherSrc = GetLauncherSource(workDir, hasPython);
            File.WriteAllText(launcherCs, launcherSrc, System.Text.Encoding.UTF8);

            // Пробуем скомпилировать через csc
            string cscPath = FindCsc();
            bool compiled = false;
            if (!string.IsNullOrEmpty(cscPath)) {
                try {
                    ProcessStartInfo psi = new ProcessStartInfo {
                        FileName = cscPath,
                        Arguments = $"/target:winexe /out:\"{outPath}\" /reference:System.Windows.Forms.dll " +
                                    $"/reference:System.dll \"{launcherCs}\"",
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    };
                    Process p = Process.Start(psi);
                    p?.WaitForExit(30000);
                    compiled = File.Exists(outPath) && new FileInfo(outPath).Length > 1024;
                } catch { }
            }

            if (!compiled) {
                // Fallback: VBS-wrapper (не требует компиляции)
                string vbsPath = Path.Combine(workDir, "GIN-Wallpaper-Calend.vbs");
                File.WriteAllText(vbsPath,
                    $"Set WshShell = CreateObject(\"WScript.Shell\")\r\n" +
                    $"WshShell.Run \"pythonw.exe \"\"\" & Chr(34) & \"{workDir}\\gin_wallpaper.py\" & Chr(34), 0, False\r\n"
                );
                // Создаём exe-обёртку через PowerShell
                BuildPsLauncher(outPath, workDir);
            }

            try { File.Delete(launcherCs); } catch { }
        }

        private void BuildPsLauncher(string outPath, string workDir) {
            // Компилируем простой PS1→exe через Add-Type
            string psScript = $@"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Reflection;
[assembly: AssemblyTitle(""{APP_NAME}"")]
[assembly: AssemblyVersion(""1.0.0.1"")]
class Program {{
    [STAThread]
    static void Main() {{
        try {{
            string dir = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string script = System.IO.Path.Combine(dir, ""gin_wallpaper.py"");
            ProcessStartInfo psi = new ProcessStartInfo(""pythonw.exe"", ""\"""" + script + ""\"""") {{
                WorkingDirectory = dir,
                UseShellExecute = true,
                WindowStyle = ProcessWindowStyle.Hidden
            }};
            Process.Start(psi);
        }} catch (Exception ex) {{
            System.Windows.Forms.MessageBox.Show(""Ошибка запуска: "" + ex.Message, ""{APP_NAME}"");
        }}
    }}
}}
'@ -ReferencedAssemblies 'System.Windows.Forms' -OutputAssembly '{outPath}' -OutputType WindowsApplication
";
            string tmpPs = Path.Combine(Path.GetTempPath(), "gin_launcher_build.ps1");
            File.WriteAllText(tmpPs, psScript, System.Text.Encoding.UTF8);
            try {
                Process p = Process.Start(new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{tmpPs}\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
                p?.WaitForExit(30000);
            } catch { }
            finally {
                try { File.Delete(tmpPs); } catch { }
            }

            // Если и это не сработало — bat-файл как последний fallback
            if (!File.Exists(outPath) || new FileInfo(outPath).Length < 100) {
                File.WriteAllText(
                    Path.Combine(workDir, "GIN-Wallpaper-Calend.bat"),
                    $"@echo off\r\nstart pythonw.exe \"{workDir}\\gin_wallpaper.py\"\r\n"
                );
            }
        }

        private void BuildUninstallerExe(string outPath, string installDir) {
            string uninstCs = Path.Combine(Path.GetTempPath(), "gin_wlp_uninstall.cs");
            File.WriteAllText(uninstCs, GetUninstallerSource(installDir), System.Text.Encoding.UTF8);

            string cscPath = FindCsc();
            if (!string.IsNullOrEmpty(cscPath)) {
                try {
                    ProcessStartInfo psi = new ProcessStartInfo {
                        FileName = cscPath,
                        Arguments = $"/target:winexe /out:\"{outPath}\" " +
                                    $"/reference:System.Windows.Forms.dll " +
                                    $"/reference:Microsoft.Win32.Registry.dll " +
                                    $"\"{uninstCs}\"",
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    Process p = Process.Start(psi);
                    p?.WaitForExit(30000);
                } catch { }
            }
            try { File.Delete(uninstCs); } catch { }

            // Fallback: PS1 uninstaller
            if (!File.Exists(outPath) || new FileInfo(outPath).Length < 100) {
                BuildPsUninstaller(outPath, installDir);
            }
        }

        private void BuildPsUninstaller(string outPath, string installDir) {
            string psScript = $@"
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using Microsoft.Win32;
[assembly: System.Reflection.AssemblyTitle(""GIN-Wallpaper-Calend Uninstaller"")]
class Program {{
    [STAThread]
    static void Main() {{
        Application.EnableVisualStyles();
        var r = MessageBox.Show(
            ""Удалить GIN-Wallpaper-Calend?\n\nБудут удалены:\n• Программа из Program Files\n• Ярлыки\n• Запись в Add/Remove Programs"",
            ""GIN-Wallpaper-Calend — Удаление"",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (r != DialogResult.Yes) return;

        // Kill processes
        try {{ foreach (var p in Process.GetProcessesByName(""GIN-Wallpaper-Calend"")) p.Kill(); }} catch {{ }}
        try {{ foreach (var p in Process.GetProcessesByName(""pythonw"")) p.Kill(); }} catch {{ }}
        System.Threading.Thread.Sleep(500);

        // Remove registry
        try {{ Registry.CurrentUser.DeleteSubKey(@""Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend"", false); }} catch {{ }}
        try {{ Registry.LocalMachine.DeleteSubKey(@""SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend"", false); }} catch {{ }}
        try {{ Registry.CurrentUser.DeleteSubKey(@""Software\Microsoft\Windows\CurrentVersion\Run\GIN-Wallpaper-Calend"", false); }} catch {{ }}
        try {{
            using (var rk = Registry.CurrentUser.OpenSubKey(@""Software\Microsoft\Windows\CurrentVersion\Run"", true))
                rk?.DeleteValue(""GIN-Wallpaper-Calend"", false);
        }} catch {{ }}

        // Remove shortcuts
        string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
        string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), ""Programs"");
        try {{ File.Delete(Path.Combine(desktop, ""GIN-Wallpaper-Calend.lnk"")); }} catch {{ }}
        try {{ File.Delete(Path.Combine(startMenu, ""GIN-Wallpaper-Calend.lnk"")); }} catch {{ }}

        // Remove files (deferred via cmd)
        string dir = ""{installDir.Replace("\"", "\\\"")}"";
        Process.Start(new ProcessStartInfo(""cmd.exe"",
            $""/C timeout /T 2 /NOBREAK & rmdir /S /Q \\""{dir}\\""\") {{
            CreateNoWindow = true, UseShellExecute = false }});

        MessageBox.Show(""GIN-Wallpaper-Calend успешно удалён."",
            ""Удаление завершено"", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }}
}}
'@ -ReferencedAssemblies 'System.Windows.Forms','Microsoft.Win32.Registry' -OutputAssembly '{outPath}' -OutputType WindowsApplication
";
            string tmpPs = Path.Combine(Path.GetTempPath(), "gin_uninstall_build.ps1");
            File.WriteAllText(tmpPs, psScript, System.Text.Encoding.UTF8);
            try {
                Process p = Process.Start(new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{tmpPs}\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
                p?.WaitForExit(30000);
            } catch { }
            finally {
                try { File.Delete(tmpPs); } catch { }
            }
        }

        private void RegisterInRegistry(string targetDir, string mainExePath, string uninstExePath) {
            const string REG_PATH = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\" + REG_KEY;
            RegistryKey[] roots = { Registry.CurrentUser, Registry.LocalMachine };
            foreach (RegistryKey root in roots) {
                try {
                    using (RegistryKey key = root.CreateSubKey(REG_PATH)) {
                        if (key == null) continue;
                        key.SetValue("DisplayName",          $"{APP_NAME} — Умные обои с календарём");
                        key.SetValue("DisplayVersion",        APP_VERSION);
                        key.SetValue("Publisher",             PUBLISHER);
                        key.SetValue("DisplayIcon",           mainExePath + ",0");
                        key.SetValue("InstallLocation",       targetDir);
                        key.SetValue("InstallDate",           DateTime.Now.ToString("yyyyMMdd"));
                        key.SetValue("UninstallString",       $"\"{uninstExePath}\"");
                        key.SetValue("QuietUninstallString",  $"\"{uninstExePath}\" --uninstall");
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

        private void RegisterAutostart(string mainExePath) {
            try {
                using (RegistryKey rk = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run", true)) {
                    rk?.SetValue(REG_KEY, $"\"{mainExePath}\"");
                }
            } catch { }
        }

        private void CreateShortcut(string shortcutPath, string target, string workDir, string desc) {
            try {
                Directory.CreateDirectory(Path.GetDirectoryName(shortcutPath) ?? ".");
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                if (shellType == null) return;
                dynamic shell    = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath     = target;
                shortcut.WorkingDirectory = workDir;
                shortcut.IconLocation   = target + ",0";
                shortcut.Description    = desc;
                shortcut.Save();
            } catch { }
        }

        private bool DownloadFile(string url, string dest) {
            try {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; // TLS 1.2
                ServicePointManager.ServerCertificateValidationCallback = (s, c, ch, e) => true;
                WebClient wc = new WebClient();
                wc.Headers.Add("User-Agent", $"GIN-Wallpaper-Calend-Installer/{APP_VERSION}");
                wc.DownloadFile(url, dest);
                return File.Exists(dest) && new FileInfo(dest).Length > 50;
            } catch { return false; }
        }

        private string FindCsc() {
            string[] dirs = {
                @"C:\Windows\Microsoft.NET\Framework64\v4.0.30319",
                @"C:\Windows\Microsoft.NET\Framework\v4.0.30319",
                @"C:\Windows\Microsoft.NET\Framework64\v3.5",
            };
            foreach (string d in dirs) {
                string p = Path.Combine(d, "csc.exe");
                if (File.Exists(p)) return p;
            }
            return null;
        }

        // ── Иконка из ресурсов ───────────────────────────────────────────────
        private Icon GetEmbeddedIcon() {
            try {
                // Пробуем загрузить из папки рядом с exe
                string ico = Path.Combine(
                    Path.GetDirectoryName(Application.ExecutablePath) ?? ".",
                    "assets", "icon.ico"
                );
                if (File.Exists(ico)) return new Icon(ico);
            } catch { }
            return SystemIcons.Application;
        }

        // ── Встроенный Python-скрипт (fallback) ─────────────────────────────
        private string GetEmbeddedScript() {
            return "# GIN-Wallpaper-Calend — загрузите gin_wallpaper.py с GitHub\n" +
                   "# https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper\n" +
                   "import webbrowser\n" +
                   "webbrowser.open('https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper')\n";
        }

        // ── Исходник launcher.cs ─────────────────────────────────────────────
        private string GetLauncherSource(string workDir, bool hasPython) {
            return $@"
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
[assembly: AssemblyTitle(""{APP_NAME}"")]
[assembly: AssemblyVersion(""1.0.0.1"")]
[assembly: AssemblyInformationalVersion(""{APP_VERSION}"")]
class Program {{
    [STAThread]
    static void Main() {{
        try {{
            string dir = ""{workDir.Replace("\\", "\\\\")}"";
            string script = Path.Combine(dir, ""{PYTHON_SCRIPT}"");
            if (!File.Exists(script)) {{
                MessageBox.Show(""Файл "" + script + "" не найден.\nПереустановите программу."",
                    ""{APP_NAME}"", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }}
            ProcessStartInfo psi = new ProcessStartInfo(""pythonw.exe"", ""\"""" + script + ""\"""") {{
                WorkingDirectory = dir,
                UseShellExecute = true,
                WindowStyle = ProcessWindowStyle.Hidden
            }};
            Process.Start(psi);
        }} catch (Exception ex) {{
            MessageBox.Show(""Ошибка запуска GIN-Wallpaper-Calend:\n"" + ex.Message +
                ""\n\nУбедитесь что Python установлен."", ""{APP_NAME}"");
        }}
    }}
}}
";
        }

        // ── Исходник uninstaller.cs ──────────────────────────────────────────
        private string GetUninstallerSource(string installDir) {
            return $@"
using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using Microsoft.Win32;
using System.Reflection;
[assembly: AssemblyTitle(""{APP_NAME} Uninstaller"")]
[assembly: AssemblyVersion(""1.0.0.1"")]
class Program {{
    [STAThread]
    static void Main() {{
        Application.EnableVisualStyles();
        var r = MessageBox.Show(
            ""Вы уверены, что хотите удалить {APP_NAME}?\n\nБудут удалены:\n• Файлы программы\n• Ярлыки на рабочем столе и в меню Пуск\n• Запись в 'Программы и компоненты'"",
            ""{APP_NAME} — Удаление"",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (r != DialogResult.Yes) return;

        try {{ foreach (var p in Process.GetProcessesByName(""GIN-Wallpaper-Calend"")) p.Kill(); }} catch {{ }}
        try {{ foreach (var p in Process.GetProcessesByName(""pythonw"")) p.Kill(); }} catch {{ }}
        System.Threading.Thread.Sleep(500);

        string[] regPaths = {{
            @""Software\Microsoft\Windows\CurrentVersion\Uninstall\{REG_KEY}"",
            @""SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{REG_KEY}""
        }};
        foreach (string rp in regPaths) {{
            try {{ Registry.CurrentUser.DeleteSubKey(rp, false); }} catch {{ }}
            try {{ Registry.LocalMachine.DeleteSubKey(rp, false); }} catch {{ }}
        }}
        try {{
            using (var rk = Registry.CurrentUser.OpenSubKey(
                @""Software\Microsoft\Windows\CurrentVersion\Run"", true))
                rk?.DeleteValue(""{REG_KEY}"", false);
        }} catch {{ }}

        string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
        string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), ""Programs"");
        try {{ File.Delete(Path.Combine(desktop,   ""{APP_NAME}.lnk"")); }} catch {{ }}
        try {{ File.Delete(Path.Combine(startMenu, ""{APP_NAME}.lnk"")); }} catch {{ }}

        string dir = @""{installDir.Replace("\\", "\\\\")}"";
        Process.Start(new ProcessStartInfo(""cmd.exe"",
            ""/C timeout /T 2 /NOBREAK & rmdir /S /Q \""{dir}\"""") {{
            CreateNoWindow = true, UseShellExecute = false }});

        MessageBox.Show(""{APP_NAME} успешно удалён с вашего компьютера."",
            ""Удаление завершено"", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }}
}}
";
        }

        // ── UI helpers ────────────────────────────────────────────────────────
        private void SetStatus(string msg, Color? color = null) {
            SafeInvoke(() => {
                lblStatus.Text = msg;
                lblStatus.ForeColor = color ?? C_WHITE;
            });
        }

        private void SetProgress(int pct) {
            SafeInvoke(() => {
                progressBar.Value = Math.Min(100, Math.Max(0, pct));
                lblPercent.Text = pct > 0 ? $"{pct}%" : "";
            });
        }

        private void SafeInvoke(Action a) {
            if (this.IsDisposed) return;
            if (this.InvokeRequired) {
                try { this.Invoke(a); } catch { }
            } else {
                a();
            }
        }
    }
}

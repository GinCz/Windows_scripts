using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("GIN Dock Wallpaper Uninstaller")]
[assembly: AssemblyDescription("Clean Uninstaller for GIN Dock Wallpaper")]
[assembly: AssemblyCompany("VladiMIR+AI")]
[assembly: AssemblyProduct("GIN Dock Wallpaper")]
[assembly: AssemblyCopyright("Copyright © 2026 Vladimir Bulantsev")]
[assembly: AssemblyVersion("0.36.0.0")]
[assembly: AssemblyFileVersion("0.36.0.0")]

namespace GINDockWallpaper {
    static class Uninstaller {
        [STAThread]
        static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            DialogResult res = MessageBox.Show(
                "Are you sure you want to completely remove GIN Dock Wallpaper from your computer?\n\nThis will remove application files, autostart entries, and desktop shortcuts.",
                "GIN Dock Wallpaper Uninstaller",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (res != DialogResult.Yes) return;

            try {
                // 1. Terminate running instances
                Process[] procs = Process.GetProcessesByName("GIN-Dock-Wallpaper");
                foreach (Process p in procs) {
                    try { p.Kill(); } catch { }
                }

                // Also check legacy names
                foreach (Process p in Process.GetProcessesByName("GIN-Dock")) {
                    try { p.Kill(); } catch { }
                }

                // 2. Remove autostart registry
                try {
                    RegistryKey rk = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                    if (rk != null) {
                        rk.DeleteValue("GIN-Dock-Wallpaper", false);
                        rk.DeleteValue("GIN-Dock", false);
                        rk.DeleteValue("GIN-Wallpaper", false);
                        rk.Close();
                    }
                } catch { }

                // 3. Remove Desktop & Start Menu shortcuts
                try {
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    foreach (string f in Directory.GetFiles(desktop, "*GIN*Dock*.lnk")) {
                        try { File.Delete(f); } catch { }
                    }

                    string pubDesktop = Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory);
                    if (Directory.Exists(pubDesktop)) {
                        foreach (string f in Directory.GetFiles(pubDesktop, "*GIN*Dock*.lnk")) {
                            try { File.Delete(f); } catch { }
                        }
                    }

                    string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "GIN Dock Wallpaper");
                    if (Directory.Exists(startMenu)) Directory.Delete(startMenu, true);
                } catch { }

                // 4. Remove Add/Remove Programs registry key
                try {
                    RegistryKey uninstKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall", true);
                    if (uninstKey != null) {
                        uninstKey.DeleteSubKeyTree("GIN-Dock-Wallpaper", false);
                        uninstKey.Close();
                    }
                } catch { }

                // 5. Spawn background self-cleanup script to delete install directory
                string installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
                string tempCmd = Path.Combine(Path.GetTempPath(), "gin_dock_cleanup.cmd");
                File.WriteAllText(tempCmd,
                    "@echo off\r\n" +
                    "timeout /t 2 /nobreak >nul\r\n" +
                    "rmdir /s /q \"" + installDir + "\" >nul 2>&1\r\n" +
                    "del \"%~f0\" >nul 2>&1\r\n"
                );

                ProcessStartInfo psi = new ProcessStartInfo {
                    FileName = "cmd.exe",
                    Arguments = "/c \"" + tempCmd + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process.Start(psi);

                MessageBox.Show(
                    "GIN Dock Wallpaper has been successfully uninstalled from your computer.",
                    "GIN Dock Wallpaper Uninstaller",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );

                Environment.Exit(0);
            } catch (Exception ex) {
                MessageBox.Show("Uninstallation failed:\n" + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}

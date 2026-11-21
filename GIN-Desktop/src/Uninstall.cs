using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("GIN-Desktop_v048")]
[assembly: AssemblyDescription("GIN-Desktop_v048")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("VladiMIR+AI")]
[assembly: AssemblyProduct("GIN-Desktop_v048")]
[assembly: AssemblyCopyright("VladiMIR+AI")]
[assembly: AssemblyTrademark("VladiMIR+AI")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("0.48.0.0")]
[assembly: AssemblyFileVersion("0.48.0.0")]

namespace GINDesktop {
    static class Uninstaller {
        [STAThread]
        static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            DialogResult res = MessageBox.Show(
                "Are you sure you want to completely remove GIN Desktop from your computer?\n\nThis will remove application files, autostart entries, and desktop shortcuts.",
                "GIN Desktop Uninstaller",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (res != DialogResult.Yes) return;

            DialogResult cleanData = MessageBox.Show(
                "Do you also want to delete all configuration settings and wallpaper cache?",
                "Remove Settings & Cache",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            try {
                // 1. Terminate running instances
                string[] pNames = new string[] { "GIN-Desktop", "GIN-Dock-Wallpaper", "GIN-Dock", "GIN-Wallpaper-Calend", "GIN-Wallpaper" };
                foreach (string name in pNames) {
                    try {
                        foreach (Process p in Process.GetProcessesByName(name)) {
                            try { p.Kill(); p.WaitForExit(1000); } catch { }
                        }
                    } catch { }
                }

                // 2. Remove autostart registry (both HKCU and HKLM)
                RegistryKey[] runRoots = new RegistryKey[] { Registry.CurrentUser, Registry.LocalMachine };
                foreach (RegistryKey root in runRoots) {
                    try {
                        using (RegistryKey rk = root.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true)) {
                            if (rk != null) {
                                rk.DeleteValue("GIN-Desktop", false);
                                rk.DeleteValue("GIN-Dock-Wallpaper", false);
                                rk.DeleteValue("GIN-Dock", false);
                                rk.DeleteValue("GIN-Wallpaper", false);
                            }
                        }
                    } catch { }
                }

                // 3. Remove Desktop & Start Menu shortcuts
                try {
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    if (Directory.Exists(desktop)) {
                        foreach (string f in Directory.GetFiles(desktop, "*GIN*Desktop*.lnk")) { try { File.Delete(f); } catch { } }
                        foreach (string f in Directory.GetFiles(desktop, "*GIN*Dock*.lnk")) { try { File.Delete(f); } catch { } }
                    }

                    string pubDesktop = Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory);
                    if (Directory.Exists(pubDesktop)) {
                        foreach (string f in Directory.GetFiles(pubDesktop, "*GIN*Desktop*.lnk")) { try { File.Delete(f); } catch { } }
                        foreach (string f in Directory.GetFiles(pubDesktop, "*GIN*Dock*.lnk")) { try { File.Delete(f); } catch { } }
                    }

                    string startMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "GIN Desktop");
                    if (Directory.Exists(startMenu)) Directory.Delete(startMenu, true);

                    string oldStartMenu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "GIN Dock Wallpaper");
                    if (Directory.Exists(oldStartMenu)) Directory.Delete(oldStartMenu, true);
                } catch { }

                // 4. Remove Add/Remove Programs registry key (both HKCU and HKLM)
                RegistryKey[] uninstRoots = new RegistryKey[] { Registry.CurrentUser, Registry.LocalMachine };
                foreach (RegistryKey root in uninstRoots) {
                    try {
                        using (RegistryKey uninstKey = root.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall", true)) {
                            if (uninstKey != null) {
                                uninstKey.DeleteSubKeyTree("GIN-Desktop", false);
                                uninstKey.DeleteSubKeyTree("GIN-Dock-Wallpaper", false);
                            }
                        }
                    } catch { }
                }

                // 5. Optional clean of AppData configuration and cache
                if (cleanData == DialogResult.Yes) {
                    try {
                        string appData = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "GIN-Desktop");
                        if (Directory.Exists(appData)) Directory.Delete(appData, true);
                        string oldAppData = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "GIN-Dock-Wallpaper");
                        if (Directory.Exists(oldAppData)) Directory.Delete(oldAppData, true);
                    } catch { }
                }

                // 6. Spawn background self-cleanup script to delete install directory
                string installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
                string tempCmd = Path.Combine(Path.GetTempPath(), "gin_desktop_cleanup.cmd");
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
                    "GIN Desktop has been successfully uninstalled from your computer.",
                    "GIN Desktop Uninstaller",
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

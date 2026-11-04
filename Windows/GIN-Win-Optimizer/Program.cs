using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("GIN-Win-Optimizer")]
[assembly: AssemblyProduct("GIN-Win-Optimizer_v039")]
[assembly: AssemblyDescription("GIN-Win-Optimizer_v039")]
[assembly: AssemblyCompany("VladiMIR+AI")]
[assembly: AssemblyCopyright("VladiMIR+AI")]
[assembly: AssemblyFileVersion("0.39.0.0")]
[assembly: AssemblyInformationalVersion("v039")]

static class Program
{
    private const string MutexName = @"Local\GIN_WIN_OPTIMIZER_MUTEX";
    private const string AppTitle = "GIN-Win-Optimizer v039 [VladiMIR + AI]";

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    private static bool IsAdministrator()
    {
        try
        {
            var identity = WindowsIdentity.GetCurrent();
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
        catch
        {
            return false;
        }
    }

    private static void ElevateToAdmin()
    {
        try
        {
            string exePath = Application.ExecutablePath;
            string workDir = Path.GetTempPath();
            try
            {
                // Stage executable to local %TEMP% if running from UNC share (\\Ulps1\util) or mapped drive
                string localCopy = Path.Combine(workDir, "GIN-Win-Optimizer.exe");
                if (!string.Equals(exePath, localCopy, StringComparison.OrdinalIgnoreCase))
                {
                    File.Copy(exePath, localCopy, true);
                    exePath = localCopy;
                }
            }
            catch { }

            var psi = new ProcessStartInfo
            {
                UseShellExecute = true,
                WorkingDirectory = workDir,
                FileName = exePath,
                Verb = "runas"
            };
            Process.Start(psi);
        }
        catch
        {
            MessageBox.Show("Administrator privileges are required to run GIN-Win-Optimizer.", AppTitle + " Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        Environment.Exit(0);
    }

    private static void BringExistingWindowToFront()
    {
        try
        {
            var current = Process.GetCurrentProcess();
            foreach (var p in Process.GetProcesses())
            {
                try
                {
                    if (p.Id != current.Id && p.MainWindowTitle.StartsWith("GIN-Win-Optimizer", StringComparison.OrdinalIgnoreCase))
                    {
                        ShowWindowAsync(p.MainWindowHandle, 9); // SW_RESTORE
                        SetForegroundWindow(p.MainWindowHandle);
                        return;
                    }
                }
                catch { }
            }
        }
        catch { }
    }

    [STAThread]
    static void Main()
    {
        bool createdNew;
        using (var mutex = new Mutex(true, MutexName, out createdNew))
        {
            if (!createdNew)
            {
                BringExistingWindowToFront();
                return;
            }

            if (!IsAdministrator())
            {
                ElevateToAdmin();
                return;
            }

            try
            {
                string targetDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GIN-Win-Optimizer");
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                string scriptPath = Path.Combine(targetDir, "engine_v039.ps1");
                var asm = Assembly.GetExecutingAssembly();

                using (var resStream = asm.GetManifestResourceStream("engine.ps1.gz"))
                {
                    if (resStream == null)
                    {
                        MessageBox.Show("Internal error: embedded engine resource missing.", AppTitle + " Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return;
                    }

                    using (var gz = new GZipStream(resStream, CompressionMode.Decompress))
                    using (var fs = new FileStream(scriptPath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        gz.CopyTo(fs);
                    }
                }

                using (var icoStream = asm.GetManifestResourceStream("app.ico"))
                {
                    if (icoStream != null)
                    {
                        string icoPath = Path.Combine(targetDir, "app.ico");
                        using (var fs = new FileStream(icoPath, FileMode.Create, FileAccess.Write, FileShare.None))
                        {
                            icoStream.CopyTo(fs);
                        }
                    }
                }

                // Dual-Path PowerShell Resolver:
                // If running on 64-bit Windows from a 32-bit process, Sysnative points to native 64-bit PowerShell.
                // If running on 32-bit Windows, Sysnative does not exist, so System32 is used.
                string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                if (string.IsNullOrEmpty(winDir)) winDir = @"C:\Windows";
                string sysnativePs = Path.Combine(winDir, @"Sysnative\WindowsPowerShell\v1.0\powershell.exe");
                string system32Ps = Path.Combine(winDir, @"System32\WindowsPowerShell\v1.0\powershell.exe");

                string psPath = File.Exists(sysnativePs) ? sysnativePs : (File.Exists(system32Ps) ? system32Ps : "powershell.exe");

                string loader = "try { $s = [System.IO.File]::ReadAllText('" + scriptPath.Replace("'", "''") + "', [System.Text.Encoding]::UTF8); Invoke-Expression $s } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'Optimizer Engine Error') }";
                string b64 = Convert.ToBase64String(Encoding.Unicode.GetBytes(loader));

                var psi = new ProcessStartInfo
                {
                    FileName = psPath,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -EncodedCommand " + b64,
                    WorkingDirectory = targetDir,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    WindowStyle = ProcessWindowStyle.Hidden
                };

                using (var proc = Process.Start(psi))
                {
                    proc.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Launch error:\n" + ex.Message, AppTitle + " Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}

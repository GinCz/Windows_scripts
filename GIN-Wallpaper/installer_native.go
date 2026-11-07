package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

var (
	shell32           = syscall.NewLazyDLL("shell32.dll")
	procShellExecuteW = shell32.NewProc("ShellExecuteW")
	procIsUserAnAdmin = shell32.NewProc("IsUserAnAdmin")
)

//go:embed GIN-Wallpaper-Calend.exe
var embeddedRunnerEXE []byte

//go:embed Uninstall.exe
var embeddedUninstEXE []byte

//go:embed app.ico
var embeddedAppICO []byte

func runQuiet(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Run()
}

func runSelfAsAdmin() {
	exe, _ := os.Executable()
	cwd, _ := os.Getwd()
	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)
	args := strings.Join(os.Args[1:], " ")
	aPtr, _ := syscall.UTF16PtrFromString(args)
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), uintptr(unsafe.Pointer(aPtr)), uintptr(unsafe.Pointer(dPtr)), 1)
}

func isAdmin() bool {
	r, _, _ := procIsUserAnAdmin.Call()
	return r != 0
}

func createShortcutsSafe(targetExe, workDir, icoPath string) {
	psScript := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$deskDirs = @('D:\MEGA\DOCS\desktop', 'D:\mega\docs\desktop', [Environment]::GetFolderPath('Desktop'), "$env:USERPROFILE\Desktop", "$env:PUBLIC\Desktop")
foreach ($d in $deskDirs) {
    if (Test-Path $d) {
        try {
            $s = $w.CreateShortcut("$d\GIN-Wallpaper-Calend.lnk")
            $s.TargetPath = '%s'
            $s.WorkingDirectory = '%s'
            $s.IconLocation = '%s,0'
            $s.Description = 'GIN-Wallpaper-Calend by VladiMIR+AI'
            $s.Save()
        } catch {}
    }
}
$sm = [Environment]::GetFolderPath('Programs')
if (Test-Path $sm) {
    try {
        $s = $w.CreateShortcut("$sm\GIN-Wallpaper-Calend.lnk")
        $s.TargetPath = '%s'
        $s.WorkingDirectory = '%s'
        $s.IconLocation = '%s,0'
        $s.Description = 'GIN-Wallpaper-Calend by VladiMIR+AI'
        $s.Save()
    } catch {}
}
`, targetExe, workDir, icoPath, targetExe, workDir, icoPath)

	runQuiet("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", psScript)
}

func writeFileWithRetry(dest string, data []byte, perm os.FileMode) error {
	var err error
	for i := 0; i < 15; i++ {
		err = os.WriteFile(dest, data, perm)
		if err == nil {
			return nil
		}
		time.Sleep(150 * time.Millisecond)
	}
	return err
}

func main() {
	if !isAdmin() {
		runSelfAsAdmin()
		return
	}

	// 1. Forcefully kill previous running instances quietly (no console window)
	runQuiet("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe")
	runQuiet("taskkill", "/F", "/IM", "GIN-Wallpaper*")
	time.Sleep(400 * time.Millisecond)

	// 2. Target installation directory
	targetDir := `C:\Program Files\GIN-Wallpaper-Calend`
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		targetDir = filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-Wallpaper-Calend")
		os.MkdirAll(targetDir, 0755)
	}

	// 3. Write embedded high-res icon
	icoDest := filepath.Join(targetDir, "app.ico")
	if len(embeddedAppICO) > 0 {
		writeFileWithRetry(icoDest, embeddedAppICO, 0644)
	}

	// 4. Write native runner EXE
	mainExe := filepath.Join(targetDir, "GIN-Wallpaper-Calend.exe")
	if len(embeddedRunnerEXE) > 0 {
		writeFileWithRetry(mainExe, embeddedRunnerEXE, 0755)
	}

	// 5. Write dedicated separate Uninstaller binary
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")
	if len(embeddedUninstEXE) > 0 {
		writeFileWithRetry(uninstExe, embeddedUninstEXE, 0755)
	}

	// 6. Register in Windows Programs & Features
	regPath := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`
	dispName := "GIN-Wallpaper-Calend v020 — Умные обои с календарём"
	runQuiet("reg", "add", regPath, "/v", "DisplayName", "/t", "REG_SZ", "/d", dispName, "/f")
	runQuiet("reg", "add", regPath, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", "v020", "/f")
	runQuiet("reg", "add", regPath, "/v", "Publisher", "/t", "REG_SZ", "/d", "VladiMIR+AI (Vladimir Bulantsev)", "/f")
	runQuiet("reg", "add", regPath, "/v", "DisplayIcon", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s",0`, icoDest), "/f")
	runQuiet("reg", "add", regPath, "/v", "InstallLocation", "/t", "REG_SZ", "/d", targetDir, "/f")
	runQuiet("reg", "add", regPath, "/v", "UninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f")
	runQuiet("reg", "add", regPath, "/v", "QuietUninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f")

	// 7. Autostart directly via native GIN-Wallpaper-Calend.exe
	runKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	runQuiet("reg", "add", runKey, "/v", "GIN-Wallpaper-Calend", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, mainExe), "/f")

	// 8. Desktop and Start Menu Shortcuts pointing directly to GIN-Wallpaper-Calend.exe with custom ICO
	createShortcutsSafe(mainExe, targetDir, icoDest)

	// 9. Launch immediately! (Standard direct execution, rock-solid, zero popups)
	cmd := exec.Command(mainExe, "--updated")
	cmd.Dir = targetDir
	cmd.Start()
}

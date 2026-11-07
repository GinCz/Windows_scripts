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
)

//go:embed GIN-Wallpaper-Calend.exe
var embeddedRunnerEXE []byte

//go:embed Uninstall.exe
var embeddedUninstEXE []byte

//go:embed app.ico
var embeddedAppICO []byte

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
	_, err := os.Open(`\\.\PHYSICALDRIVE0`)
	return err == nil
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

	cmd := exec.Command("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", psScript)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Run()
}

func main() {
	if !isAdmin() {
		runSelfAsAdmin()
		return
	}

	// 1. Terminate previous running instances
	cmdKill := exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe")
	cmdKill.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdKill.Run()
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
		os.WriteFile(icoDest, embeddedAppICO, 0644)
	}

	// 4. Write native runner EXE
	mainExe := filepath.Join(targetDir, "GIN-Wallpaper-Calend.exe")
	if len(embeddedRunnerEXE) > 0 {
		os.WriteFile(mainExe, embeddedRunnerEXE, 0755)
	}

	// 5. Write dedicated separate Uninstaller binary
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")
	if len(embeddedUninstEXE) > 0 {
		os.WriteFile(uninstExe, embeddedUninstEXE, 0755)
	}

	// 6. Register in Windows Programs & Features
	regPath := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`
	dispName := "GIN-Wallpaper-Calend v021 — Умные обои с календарём"
	cmdReg1 := exec.Command("reg", "add", regPath, "/v", "DisplayName", "/t", "REG_SZ", "/d", dispName, "/f")
	cmdReg1.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg1.Run()

	cmdReg2 := exec.Command("reg", "add", regPath, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", "v021", "/f")
	cmdReg2.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg2.Run()

	cmdReg3 := exec.Command("reg", "add", regPath, "/v", "Publisher", "/t", "REG_SZ", "/d", "VladiMIR+AI (Vladimir Bulantsev)", "/f")
	cmdReg3.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg3.Run()

	cmdReg4 := exec.Command("reg", "add", regPath, "/v", "DisplayIcon", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s",0`, icoDest), "/f")
	cmdReg4.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg4.Run()

	cmdReg5 := exec.Command("reg", "add", regPath, "/v", "InstallLocation", "/t", "REG_SZ", "/d", targetDir, "/f")
	cmdReg5.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg5.Run()

	cmdReg6 := exec.Command("reg", "add", regPath, "/v", "UninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f")
	cmdReg6.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg6.Run()

	cmdReg7 := exec.Command("reg", "add", regPath, "/v", "QuietUninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f")
	cmdReg7.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg7.Run()

	// 7. Autostart directly via native GIN-Wallpaper-Calend.exe
	runKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	cmdRun := exec.Command("reg", "add", runKey, "/v", "GIN-Wallpaper-Calend", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, mainExe), "/f")
	cmdRun.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdRun.Run()

	// 8. Desktop and Start Menu Shortcuts pointing directly to GIN-Wallpaper-Calend.exe with custom ICO
	createShortcutsSafe(mainExe, targetDir, icoDest)

	// 9. Launch immediately! (Zero popups, proven direct launch from v018)
	cmdLaunch := exec.Command(mainExe, "--updated")
	cmdLaunch.Dir = targetDir
	cmdLaunch.Start()
}

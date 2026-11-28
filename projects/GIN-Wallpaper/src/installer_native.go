package main

import (
	"bytes"
	"compress/gzip"
	_ "embed"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

var (
	kernel32          = syscall.NewLazyDLL("kernel32.dll")
	user32            = syscall.NewLazyDLL("user32.dll")
	shell32           = syscall.NewLazyDLL("shell32.dll")
	procCreateMutexW  = kernel32.NewProc("CreateMutexW")
	procMessageBoxW   = user32.NewProc("MessageBoxW")
	procShellExecuteW = shell32.NewProc("ShellExecuteW")
	installerMutex    uintptr
)

func checkInstallerSingleInstance() bool {
	mutexName := syscall.StringToUTF16Ptr("Local\\GIN_WALLPAPER_INSTALLER_MUTEX")
	hMutex, _, err := procCreateMutexW.Call(0, 0, uintptr(unsafe.Pointer(mutexName)))
	if hMutex == 0 {
		return false
	}
	errno, isErrno := err.(syscall.Errno)
	if isErrno && (errno == 183 || errno == 5) {
		return false
	}
	installerMutex = hMutex
	return true
}

const (
	MB_OKCANCEL     = 0x00000001
	MB_ICONQUESTION = 0x00000020
	IDOK            = 1
)

func msgBox(title, text string, style uint) int {
	tPtr, _ := syscall.UTF16PtrFromString(text)
	cPtr, _ := syscall.UTF16PtrFromString(title)
	r, _, _ := procMessageBoxW.Call(0, uintptr(unsafe.Pointer(tPtr)), uintptr(unsafe.Pointer(cPtr)), uintptr(style))
	return int(r)
}

//go:embed GIN-Wallpaper-Calend.exe.gz
var embeddedRunnerGZ []byte

//go:embed Uninstall.exe.gz
var embeddedUninstGZ []byte

//go:embed app.ico
var embeddedAppICO []byte

func unpackGz(gzData []byte, destPath string) error {
	gr, err := gzip.NewReader(bytes.NewReader(gzData))
	if err != nil {
		return err
	}
	defer gr.Close()

	outFile, err := os.OpenFile(destPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}
	defer outFile.Close()

	_, err = io.Copy(outFile, gr)
	return err
}

func runSelfAsAdmin(args ...string) {
	exe, _ := os.Executable()
	cwd, _ := os.Getwd()
	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)
	var argStr string
	if len(args) > 0 {
		argStr = strings.Join(args, " ")
	}
	aPtr, _ := syscall.UTF16PtrFromString(argStr)
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), uintptr(unsafe.Pointer(aPtr)), uintptr(unsafe.Pointer(dPtr)), 1)
}

func isAdmin() bool {
	_, err := os.Open(`\\.\PHYSICALDRIVE0`)
	return err == nil
}

func createShortcutsSafe(targetExe, workDir, icoPath string) {
	psScript := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell

# 1. Purge any duplicate shortcuts from Public Desktop
$pubDesks = @("$env:PUBLIC\Desktop", "C:\Users\Public\Desktop")
foreach ($p in $pubDesks) {
    if (Test-Path "$p\GIN-Wallpaper-Calend.lnk") {
        try { Remove-Item -Force "$p\GIN-Wallpaper-Calend.lnk" -ErrorAction SilentlyContinue } catch {}
    }
}

# 2. Identify the single primary user desktop directory
$userDesk = $null
$candidates = @('D:\DOCS\desktop', 'D:\docs\desktop', 'D:\MEGA\DOCS\desktop', 'D:\mega\docs\desktop')
foreach ($c in $candidates) {
    if (Test-Path $c) { $userDesk = $c; break }
}
if (-not $userDesk) {
    try {
        $regVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name 'Desktop' -ErrorAction SilentlyContinue).Desktop
        if ($regVal) {
            $expanded = [System.Environment]::ExpandEnvironmentVariables($regVal)
            if (Test-Path $expanded) { $userDesk = $expanded }
        }
    } catch {}
}
if (-not $userDesk) {
    $shDesk = [Environment]::GetFolderPath('Desktop')
    if ($shDesk -and (Test-Path $shDesk)) { $userDesk = $shDesk }
}
if (-not $userDesk) {
    $userDesk = "$env:USERPROFILE\Desktop"
}

# 3. Create strictly ONE shortcut on the user's desktop
if ($userDesk -and (Test-Path $userDesk)) {
    try {
        $s = $w.CreateShortcut("$userDesk\GIN-Wallpaper-Calend.lnk")
        $s.TargetPath = '%s'
        $s.WorkingDirectory = '%s'
        $s.IconLocation = '%s,0'
        $s.Description = 'GIN-Wallpaper-Calend by VladiMIR+AI'
        $s.Save()
    } catch {}
}

# 4. Start Menu shortcut
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
	if !checkInstallerSingleInstance() {
		return
	}

	isSilent := false
	isConfirmed := false

	for _, a := range os.Args[1:] {
		al := strings.ToLower(a)
		if al == "/silent" || al == "--silent" || al == "-silent" || al == "/s" || al == "--updated" || al == "/updated" {
			isSilent = true
		}
		if al == "--confirmed" || al == "-confirmed" {
			isConfirmed = true
		}
	}

	// English minimal prompt: "GIN-Wallpaper-Calend - Install?" [OK] [Cancel]
	if !isSilent && !isConfirmed {
		if msgBox("GIN-Wallpaper-Calend", "GIN-Wallpaper-Calend - Install?", MB_OKCANCEL|MB_ICONQUESTION) != IDOK {
			return
		}
		isConfirmed = true
	}

	if !isAdmin() {
		args := []string{"--confirmed"}
		if isSilent {
			args = append(args, "/SILENT")
		}
		runSelfAsAdmin(args...)
		return
	}

	// 1. Terminate previous running instances
	cmdKill := exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe")
	cmdKill.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdKill.Run()
	time.Sleep(400 * time.Millisecond)

	// 2. Target installation directory (Universal for 32-bit & 64-bit Windows)
	progFiles := os.Getenv("ProgramFiles")
	if progFiles == "" {
		progFiles = `C:\Program Files`
	}
	targetDir := filepath.Join(progFiles, "GIN-Wallpaper-Calend")
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		targetDir = filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-Wallpaper-Calend")
		os.MkdirAll(targetDir, 0755)
	}

	// Clean up any stray files in target directory
	if files, err := os.ReadDir(targetDir); err == nil {
		for _, f := range files {
			if strings.HasPrefix(f.Name(), "CGIN-Wallpaper_Uninstall") {
				os.Remove(filepath.Join(targetDir, f.Name()))
			}
		}
	}

	// 3. Write embedded high-res icon
	icoDest := filepath.Join(targetDir, "app.ico")
	if len(embeddedAppICO) > 0 {
		os.WriteFile(icoDest, embeddedAppICO, 0644)
	}

	// 4. Decompress native runner EXE
	mainExe := filepath.Join(targetDir, "GIN-Wallpaper-Calend.exe")
	if len(embeddedRunnerGZ) > 0 {
		unpackGz(embeddedRunnerGZ, mainExe)
	}

	// 5. Decompress separate Uninstaller binary
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")
	if len(embeddedUninstGZ) > 0 {
		unpackGz(embeddedUninstGZ, uninstExe)
	}

	// 6. Register in Windows Programs & Features
	regPath := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`
	dispName := "GIN-Wallpaper-Calend v031"
	cmdReg1 := exec.Command("reg", "add", regPath, "/v", "DisplayName", "/t", "REG_SZ", "/d", dispName, "/f")
	cmdReg1.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg1.Run()

	cmdReg2 := exec.Command("reg", "add", regPath, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", "v031", "/f")
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

	// 9. Launch immediately! (Zero popups, proven direct launch)
	cmdLaunch := exec.Command(mainExe, "--updated")
	cmdLaunch.Dir = targetDir
	cmdLaunch.Start()
}

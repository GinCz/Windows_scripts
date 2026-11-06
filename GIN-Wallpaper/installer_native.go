package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
	"unsafe"
)

var (
	user32             = syscall.NewLazyDLL("user32.dll")
	kernel32           = syscall.NewLazyDLL("kernel32.dll")
	shell32            = syscall.NewLazyDLL("shell32.dll")
	procMessageBoxW    = user32.NewProc("MessageBoxW")
	procGetLocaleInfoW = kernel32.NewProc("GetLocaleInfoW")
	procShellExecuteW  = shell32.NewProc("ShellExecuteW")
)

const (
	MB_OK                  = 0x00000000
	MB_YESNO               = 0x00000004
	MB_ICONINFO            = 0x00000040
	IDYES                  = 6
	LOCALE_USER_DEFAULT    = 0x0400
	LOCALE_SISO639LANGNAME = 0x0059
)

//go:embed GIN-Wallpaper-Calend.exe
var embeddedRunnerEXE []byte

//go:embed Uninstall.exe
var embeddedUninstEXE []byte

//go:embed app.ico
var embeddedAppICO []byte

func msgBox(title, text string, style uint) int {
	tPtr, _ := syscall.UTF16PtrFromString(text)
	cPtr, _ := syscall.UTF16PtrFromString(title)
	ret, _, _ := procMessageBoxW.Call(0, uintptr(unsafe.Pointer(tPtr)), uintptr(unsafe.Pointer(cPtr)), uintptr(style))
	return int(ret)
}

func isRussianLocale() bool {
	buf := make([]uint16, 16)
	ret, _, _ := procGetLocaleInfoW.Call(
		uintptr(LOCALE_USER_DEFAULT),
		uintptr(LOCALE_SISO639LANGNAME),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(len(buf)),
	)
	if ret > 0 {
		str := syscall.UTF16ToString(buf)
		if str == "ru" || str == "be" || str == "uk" {
			return true
		}
	}
	return false
}

func runSelfAsAdmin() {
	exe, _ := os.Executable()
	cwd, _ := os.Getwd()
	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), 0, uintptr(unsafe.Pointer(dPtr)), 1)
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

	ru := isRussianLocale()
	title := "GIN-Wallpaper-Calend v010 — Setup"
	qInstall := "Install GIN-Wallpaper-Calend v010 (Smart Wallpaper with Calendar)?\n\nTarget directory:\nC:\\Program Files\\GIN-Wallpaper-Calend"
	if ru {
		title = "GIN-Wallpaper-Calend v010 — Установка"
		qInstall = "Установить GIN-Wallpaper-Calend v010 (Умные обои с календарём)?\n\nПапка установки:\nC:\\Program Files\\GIN-Wallpaper-Calend"
	}

	if msgBox(title, qInstall, MB_YESNO|MB_ICONINFO) != IDYES {
		return
	}

	// Terminate previous running instances
	exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()
	time.Sleep(400 * time.Millisecond)

	targetDir := `C:\Program Files\GIN-Wallpaper-Calend`
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		targetDir = filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-Wallpaper-Calend")
		os.MkdirAll(targetDir, 0755)
	}

	// 1. Write embedded high-res icon
	icoDest := filepath.Join(targetDir, "app.ico")
	if len(embeddedAppICO) > 0 {
		os.WriteFile(icoDest, embeddedAppICO, 0644)
	}

	// 2. Write native runner EXE
	mainExe := filepath.Join(targetDir, "GIN-Wallpaper-Calend.exe")
	if len(embeddedRunnerEXE) > 0 {
		os.WriteFile(mainExe, embeddedRunnerEXE, 0755)
	}

	// 3. Write dedicated separate Uninstaller binary!
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")
	if len(embeddedUninstEXE) > 0 {
		os.WriteFile(uninstExe, embeddedUninstEXE, 0755)
	}

	// 4. Register in Windows Programs & Features
	regPath := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`
	dispName := "GIN-Wallpaper-Calend v010 — Smart Wallpaper with Calendar"
	if ru {
		dispName = "GIN-Wallpaper-Calend v010 — Умные обои с календарём"
	}
	exec.Command("reg", "add", regPath, "/v", "DisplayName", "/t", "REG_SZ", "/d", dispName, "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", "v010", "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "Publisher", "/t", "REG_SZ", "/d", "VladiMIR+AI (Vladimir Bulantsev)", "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "DisplayIcon", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s",0`, icoDest), "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "InstallLocation", "/t", "REG_SZ", "/d", targetDir, "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "UninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "QuietUninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, uninstExe), "/f").Run()

	// 5. Autostart directly via native GIN-Wallpaper-Calend.exe
	runKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	exec.Command("reg", "add", runKey, "/v", "GIN-Wallpaper-Calend", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, mainExe), "/f").Run()

	// 6. Desktop and Start Menu Shortcuts pointing directly to GIN-Wallpaper-Calend.exe with custom ICO!
	createShortcutsSafe(mainExe, targetDir, icoDest)

	// 7. Launch immediately!
	cmd := exec.Command(mainExe)
	cmd.Dir = targetDir
	cmd.Start()

	successMsg := "Installation completed successfully!\n\nGIN-Wallpaper-Calend v010 is now running in your system tray (bottom-right near clock).\nRight click the tray icon for Settings, fonts and wallpaper themes."
	if ru {
		successMsg = "Установка успешно завершена!\n\nGIN-Wallpaper-Calend v010 запущен в системном трее (в правом нижнем углу возле часов).\nКликните правой кнопкой мыши по иконке для открытия Настроек, выбора шрифтов и тематики обоев."
	}
	msgBox(title, successMsg, MB_OK|MB_ICONINFO)
}

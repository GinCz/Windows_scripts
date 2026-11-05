package main

import (
	_ "embed"
	"fmt"
	"io"
	"net/http"
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
	procMessageBoxW    = user32.NewProc("MessageBoxW")
	procGetLocaleInfoW = kernel32.NewProc("GetLocaleInfoW")
)

const (
	MB_OK                  = 0x00000000
	MB_YESNO               = 0x00000004
	MB_ICONINFO            = 0x00000040
	MB_ICONWARN            = 0x00000030
	MB_ICONERROR           = 0x00000010
	IDYES                  = 6
	LOCALE_USER_DEFAULT    = 0x0400
	LOCALE_SISO639LANGNAME = 0x0059
)

//go:embed GIN-Wallpaper-Calend.exe
var embeddedRunnerEXE []byte

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
	shell32 := syscall.NewLazyDLL("shell32.dll")
	procShellExecuteW := shell32.NewProc("ShellExecuteW")

	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)

	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), 0, uintptr(unsafe.Pointer(dPtr)), 1)
}

func isAdmin() bool {
	_, err := os.Open(`\\.\PHYSICALDRIVE0`)
	return err == nil
}

func downloadFile(url, dest string) error {
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %s", resp.Status)
	}

	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

func getDesktopDirectories() []string {
	res := []string{
		`D:\MEGA\DOCS\desktop`,
		`D:\mega\docs\desktop`,
		filepath.Join(os.Getenv("USERPROFILE"), "Desktop"),
		filepath.Join(os.Getenv("PUBLIC"), "Desktop"),
	}
	var existing []string
	for _, d := range res {
		if d == "" {
			continue
		}
		if fi, err := os.Stat(d); err == nil && fi.IsDir() {
			existing = append(existing, d)
		}
	}
	if len(existing) == 0 {
		ud := filepath.Join(os.Getenv("USERPROFILE"), "Desktop")
		os.MkdirAll(ud, 0755)
		existing = append(existing, ud)
	}
	return existing
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
	ru := isRussianLocale()

	if len(os.Args) > 1 && os.Args[1] == "--uninstall" {
		if !isAdmin() {
			runSelfAsAdmin()
			return
		}

		title := "GIN-Wallpaper-Calend v004 — Uninstall"
		q := "Are you sure you want to completely remove GIN-Wallpaper-Calend?"
		doneMsg := "GIN-Wallpaper-Calend has been successfully removed."
		if ru {
			title = "GIN-Wallpaper-Calend v004 — Удаление"
			q = "Вы действительно хотите полностью удалить GIN-Wallpaper-Calend?"
			doneMsg = "GIN-Wallpaper-Calend был успешно удалён."
		}

		if msgBox(title, q, MB_YESNO|MB_ICONWARN) != IDYES {
			return
		}

		// Kill processes
		exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()
		exec.Command("taskkill", "/F", "/IM", "pythonw.exe").Run()
		time.Sleep(500 * time.Millisecond)

		// Registry cleanup
		exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f").Run()
		exec.Command("reg", "delete", `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f").Run()
		exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "GIN-Wallpaper-Calend", "/f").Run()

		// Shortcuts
		for _, d := range getDesktopDirectories() {
			os.Remove(filepath.Join(d, "GIN-Wallpaper-Calend.lnk"))
		}
		startMenu := filepath.Join(os.Getenv("APPDATA"), `Microsoft\Windows\Start Menu\Programs\GIN-Wallpaper-Calend.lnk`)
		os.Remove(startMenu)

		// Self deletion via scheduled cmd batch in temp
		exe, _ := os.Executable()
		instDir := filepath.Dir(exe)
		batDel := filepath.Join(os.TempDir(), "gin_cleanup.bat")
		batContent := fmt.Sprintf(`@echo off
timeout /T 1 /NOBREAK >nul
taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1
taskkill /F /IM Uninstall.exe >nul 2>&1
rd /S /Q "%s" >nul 2>&1
del "%%~f0" >nul 2>&1
`, instDir)
		os.WriteFile(batDel, []byte(batContent), 0644)
		exec.Command("cmd.exe", "/C", "start", "/min", batDel).Start()

		msgBox(title, doneMsg, MB_OK|MB_ICONINFO)
		return
	}

	// Normal Installation
	if !isAdmin() {
		runSelfAsAdmin()
		return
	}

	title := "GIN-Wallpaper-Calend v004 — Setup"
	qInstall := "Install GIN-Wallpaper-Calend v004 (Smart Wallpaper with Calendar)?\n\nTarget directory:\nC:\\Program Files\\GIN-Wallpaper-Calend"
	if ru {
		title = "GIN-Wallpaper-Calend v004 — Установка"
		qInstall = "Установить GIN-Wallpaper-Calend v004 (Умные обои с календарём)?\n\nПапка установки:\nC:\\Program Files\\GIN-Wallpaper-Calend"
	}

	if msgBox(title, qInstall, MB_YESNO|MB_ICONINFO) != IDYES {
		return
	}

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


	// 4. Copy self as Uninstaller
	selfExe, _ := os.Executable()
	uninstExe := filepath.Join(targetDir, "Uninstall.exe")
	if selfBytes, err := os.ReadFile(selfExe); err == nil {
		os.WriteFile(uninstExe, selfBytes, 0755)
	}

	// 5. Install python dependencies silently

	// 6. Register in Windows Programs & Features
	regPath := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`
	dispName := "GIN-Wallpaper-Calend v004 — Smart Wallpaper with Calendar"
	if ru {
		dispName = "GIN-Wallpaper-Calend v004 — Умные обои с календарём"
	}
	exec.Command("reg", "add", regPath, "/v", "DisplayName", "/t", "REG_SZ", "/d", dispName, "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "DisplayVersion", "/t", "REG_SZ", "/d", "v004", "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "Publisher", "/t", "REG_SZ", "/d", "VladiMIR+AI (Vladimir Bulantsev)", "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "DisplayIcon", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s",0`, icoDest), "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "InstallLocation", "/t", "REG_SZ", "/d", targetDir, "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "UninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s" --uninstall`, uninstExe), "/f").Run()
	exec.Command("reg", "add", regPath, "/v", "QuietUninstallString", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s" --uninstall`, uninstExe), "/f").Run()

	// 7. Autostart directly via native GIN-Wallpaper-Calend.exe
	runKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	exec.Command("reg", "add", runKey, "/v", "GIN-Wallpaper-Calend", "/t", "REG_SZ", "/d", fmt.Sprintf(`"%s"`, mainExe), "/f").Run()

	// 8. Desktop and Start Menu Shortcuts pointing directly to GIN-Wallpaper-Calend.exe with custom ICO!
	createShortcutsSafe(mainExe, targetDir, icoDest)

	// 9. Launch immediately!
	exec.Command(mainExe).Start()

	successMsg := "Installation completed successfully!\n\nGIN-Wallpaper-Calend v004 is now running in your system tray (bottom-right near clock).\nDesktop shortcut created with custom icon."
	if ru {
		successMsg = "Установка успешно завершена!\n\nGIN-Wallpaper-Calend v004 запущен в системном трее (в правом нижнем углу возле часов).\nЯрлык с красивой иконкой создан на Рабочем столе."
	}
	msgBox(title, successMsg, MB_OK|MB_ICONINFO)
}

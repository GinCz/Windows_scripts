package main

import (
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
	MB_ICONWARN            = 0x00000030
	IDYES                  = 6
	LOCALE_USER_DEFAULT    = 0x0400
	LOCALE_SISO639LANGNAME = 0x0059
)

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

func main() {
	if !isAdmin() {
		runSelfAsAdmin()
		return
	}

	ru := isRussianLocale()
	title := "GIN-Wallpaper-Calend — Uninstall"
	q := "Are you sure you want to completely remove GIN-Wallpaper-Calend?\n\nThis will terminate the program and delete all installed files."
	doneMsg := "GIN-Wallpaper-Calend has been successfully removed."
	if ru {
		title = "GIN-Wallpaper-Calend — Удаление программы"
		q = "Вы действительно хотите полностью удалить GIN-Wallpaper-Calend?\n\nПрограмма будет закрыта, а все её файлы и ярлыки удалены."
		doneMsg = "GIN-Wallpaper-Calend был успешно удалён."
	}

	if msgBox(title, q, MB_YESNO|MB_ICONWARN) != IDYES {
		return
	}

	// 1. Force kill processes
	exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()
	exec.Command("taskkill", "/F", "/IM", "pythonw.exe").Run()
	time.Sleep(600 * time.Millisecond)

	// 2. Remove registry keys
	exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f").Run()
	exec.Command("reg", "delete", `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f").Run()
	exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "GIN-Wallpaper-Calend", "/f").Run()

	// 3. Remove shortcuts
	deskDirs := []string{
		`D:\MEGA\DOCS\desktop`,
		`D:\mega\docs\desktop`,
		filepath.Join(os.Getenv("USERPROFILE"), "Desktop"),
		filepath.Join(os.Getenv("PUBLIC"), "Desktop"),
	}
	for _, d := range deskDirs {
		os.Remove(filepath.Join(d, "GIN-Wallpaper-Calend.lnk"))
	}
	startMenu := filepath.Join(os.Getenv("APPDATA"), `Microsoft\Windows\Start Menu\Programs\GIN-Wallpaper-Calend.lnk`)
	os.Remove(startMenu)

	// 4. Deferred self-wiping batch script
	exe, _ := os.Executable()
	instDir := filepath.Dir(exe)
	batDel := filepath.Join(os.TempDir(), "gin_uninstall_cleaner.bat")
	batContent := fmt.Sprintf(`@echo off
timeout /T 1 /NOBREAK >nul
taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1
taskkill /F /IM Uninstall.exe >nul 2>&1
timeout /T 1 /NOBREAK >nul
rd /S /Q "%s" >nul 2>&1
del "%%~f0" >nul 2>&1
`, instDir)
	os.WriteFile(batDel, []byte(batContent), 0644)

	cmd := exec.Command("cmd.exe", "/C", "start", "/min", batDel)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Start()

	msgBox(title, doneMsg, MB_OK|MB_ICONINFO)
}

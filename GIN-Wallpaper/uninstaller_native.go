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

func runSelfAsAdmin(args ...string) {
	exe, _ := os.Executable()
	cwd := os.TempDir()
	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)
	var pPtr *uint16
	if len(args) > 0 {
		var argStr string
		for _, a := range args {
			argStr += fmt.Sprintf(`"%s" `, a)
		}
		pPtr, _ = syscall.UTF16PtrFromString(argStr)
	}
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), uintptr(unsafe.Pointer(pPtr)), uintptr(unsafe.Pointer(dPtr)), 1)
}

func isAdmin() bool {
	_, err := os.Open(`\\.\PHYSICALDRIVE0`)
	return err == nil
}

func main() {
	if !isAdmin() {
		runSelfAsAdmin(os.Args[1:]...)
		return
	}

	ru := isRussianLocale()
	title := "GIN-Wallpaper-Calend — Uninstall"
	doneMsg := "GIN-Wallpaper-Calend has been successfully removed."
	if ru {
		title = "GIN-Wallpaper-Calend — Удаление программы"
		doneMsg = "GIN-Wallpaper-Calend был успешно удалён."
	}

	// ── Phase 2: Running from %TEMP% as external cleanup agent ─────────────────
	if len(os.Args) >= 3 && os.Args[1] == "--cleanup" {
		targetDir := os.Args[2]

		// Wait for parent Uninstall.exe in targetDir to exit
		time.Sleep(1200 * time.Millisecond)

		// Terminate any lingering wallpaper processes
		exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()
		exec.Command("taskkill", "/F", "/IM", "pythonw.exe").Run()

		// Robust wipe loop: delete all files and directory with retries
		for i := 0; i < 15; i++ {
			// 1. Force delete all files inside targetDir individually
			if files, err := os.ReadDir(targetDir); err == nil {
				for _, f := range files {
					filePath := filepath.Join(targetDir, f.Name())
					os.Chmod(filePath, 0666)
					os.Remove(filePath)
				}
			}

			// 2. Remove directory
			if err := os.RemoveAll(targetDir); err == nil {
				if _, err := os.Stat(targetDir); os.IsNotExist(err) {
					break
				}
			}

			// 3. Command line forced deletion fallback
			cmdDel := exec.Command("cmd.exe", "/C", fmt.Sprintf(`del /F /Q /A "%s\*.*" & rd /S /Q "%s"`, targetDir, targetDir))
			cmdDel.Dir = os.TempDir()
			cmdDel.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
			cmdDel.Run()

			if _, err := os.Stat(targetDir); os.IsNotExist(err) {
				break
			}
			time.Sleep(400 * time.Millisecond)
		}

		// Also clean AppData cache
		appData := filepath.Join(os.Getenv("APPDATA"), "GIN-Wallpaper-Calend")
		os.RemoveAll(appData)

		// Schedule self-delete of this temp executable
		selfExe, _ := os.Executable()
		selfDelCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & del /F /Q "%s"`, selfExe)
		cDel := exec.Command("cmd.exe", "/C", selfDelCmd)
		cDel.Dir = os.TempDir()
		cDel.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		cDel.Start()

		msgBox(title, doneMsg, MB_OK|MB_ICONINFO)
		return
	}

	// ── Phase 1: User launched Uninstall.exe ────────────────────────────────────
	q := "Are you sure you want to completely remove GIN-Wallpaper-Calend?\n\nThis will terminate the program and delete all installed files."
	if ru {
		q = "Вы действительно хотите полностью удалить GIN-Wallpaper-Calend?\n\nПрограмма будет закрыта, а все её файлы и ярлыки удалены."
	}

	if msgBox(title, q, MB_YESNO|MB_ICONWARN) != IDYES {
		return
	}

	// 1. Force kill active wallpaper processes
	exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()
	exec.Command("taskkill", "/F", "/IM", "pythonw.exe").Run()
	time.Sleep(500 * time.Millisecond)

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

	// 4. Copy self to %TEMP% to unlock installation directory
	exe, _ := os.Executable()
	instDir := filepath.Dir(exe)
	tempUninst := filepath.Join(os.TempDir(), fmt.Sprintf("GIN-Wallpaper_Uninstall_%d.exe", time.Now().Unix()))

	data, err := os.ReadFile(exe)
	if err == nil {
		if err := os.WriteFile(tempUninst, data, 0755); err == nil {
			cmd := exec.Command(tempUninst, "--cleanup", instDir)
			cmd.Dir = os.TempDir()
			cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
			if err := cmd.Start(); err == nil {
				// Exit phase 1 immediately so targetDir's Uninstall.exe is unlocked!
				os.Exit(0)
			}
		}
	}

	// Fallback if copy to temp failed: deferred cmd cleanup
	cleanerCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1 & del /F /Q /A "%s\*.*" & rd /S /Q "%s"`, instDir, instDir)
	cmd := exec.Command("cmd.exe", "/C", cleanerCmd)
	cmd.Dir = os.TempDir()
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Start()

	msgBox(title, doneMsg, MB_OK|MB_ICONINFO)
}

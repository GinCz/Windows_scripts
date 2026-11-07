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
	shell32           = syscall.NewLazyDLL("shell32.dll")
	procShellExecuteW = shell32.NewProc("ShellExecuteW")
)

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

	// ── Phase 2: Running from %TEMP% as external cleanup agent ─────────────────
	if len(os.Args) >= 3 && os.Args[1] == "--cleanup" {
		targetDir := os.Args[2]

		time.Sleep(800 * time.Millisecond)

		// Terminate any lingering wallpaper processes
		exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe").Run()

		// Robust wipe loop: delete all files and directory with retries
		for i := 0; i < 15; i++ {
			if files, err := os.ReadDir(targetDir); err == nil {
				for _, f := range files {
					filePath := filepath.Join(targetDir, f.Name())
					os.Chmod(filePath, 0666)
					os.Remove(filePath)
				}
			}

			if err := os.RemoveAll(targetDir); err == nil {
				if _, err := os.Stat(targetDir); os.IsNotExist(err) {
					break
				}
			}

			cmdDel := exec.Command("cmd.exe", "/C", fmt.Sprintf(`del /F /Q /A "%s\*.*" & rd /S /Q "%s"`, targetDir, targetDir))
			cmdDel.Dir = os.TempDir()
			cmdDel.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
			cmdDel.Run()

			if _, err := os.Stat(targetDir); os.IsNotExist(err) {
				break
			}
			time.Sleep(300 * time.Millisecond)
		}

		// Clean AppData cache
		appData := filepath.Join(os.Getenv("APPDATA"), "GIN-Wallpaper-Calend")
		os.RemoveAll(appData)

		// Schedule self-delete of this temp executable
		selfExe, _ := os.Executable()
		selfDelCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & del /F /Q "%s"`, selfExe)
		cDel := exec.Command("cmd.exe", "/C", selfDelCmd)
		cDel.Dir = os.TempDir()
		cDel.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		cDel.Start()

		return
	}

	// ── Phase 1: User launched Uninstall.exe (Completely Silent, 0 Popups) ───────
	// 1. Force kill active wallpaper processes
	cmdKill := exec.Command("taskkill", "/F", "/IM", "GIN-Wallpaper-Calend.exe")
	cmdKill.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdKill.Run()
	time.Sleep(400 * time.Millisecond)

	// 2. Remove registry keys
	cmdReg1 := exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f")
	cmdReg1.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg1.Run()

	cmdReg2 := exec.Command("reg", "delete", `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Wallpaper-Calend`, "/f")
	cmdReg2.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg2.Run()

	cmdReg3 := exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "GIN-Wallpaper-Calend", "/f")
	cmdReg3.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg3.Run()

	// 3. Remove shortcuts from Desktop and Start Menu
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

	// 4. Copy self to %TEMP% to unlock installation directory and wipe it
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
				os.Exit(0)
			}
		}
	}

	// Fallback cleanup if temp copy failed
	cleanerCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1 & del /F /Q /A "%s\*.*" & rd /S /Q "%s"`, instDir, instDir)
	cmd := exec.Command("cmd.exe", "/C", cleanerCmd)
	cmd.Dir = os.TempDir()
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Start()
}

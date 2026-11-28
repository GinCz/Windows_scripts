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

		time.Sleep(500 * time.Millisecond)

		// Terminate any lingering GIN-DNS-Switch processes
		exec.Command("taskkill", "/F", "/IM", "GIN-DNS-Switch.exe").Run()

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
			time.Sleep(200 * time.Millisecond)
		}

		// Schedule self-delete of this temp executable
		selfExe, _ := os.Executable()
		selfDelCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & del /F /Q "%s"`, selfExe)
		cDel := exec.Command("cmd.exe", "/C", selfDelCmd)
		cDel.Dir = os.TempDir()
		cDel.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		cDel.Start()

		return
	}

	// ── Phase 1: User launched Uninstall.exe ────────────────────────────────────
	// 1. Remove registry keys
	cmdReg1 := exec.Command("reg", "delete", `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch`, "/f")
	cmdReg1.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg1.Run()

	cmdReg2 := exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch`, "/f")
	cmdReg2.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg2.Run()

	// 2. Remove shortcuts from Desktop and Start Menu
	deskDirs := []string{
		`D:\MEGA\DOCS\desktop`,
		`D:\mega\docs\desktop`,
		filepath.Join(os.Getenv("USERPROFILE"), "Desktop"),
		filepath.Join(os.Getenv("PUBLIC"), "Desktop"),
	}
	for _, d := range deskDirs {
		os.Remove(filepath.Join(d, "GIN-DNS-Switch.lnk"))
	}
	startMenus := []string{
		filepath.Join(os.Getenv("APPDATA"), `Microsoft\Windows\Start Menu\Programs\GIN-DNS-Switch.lnk`),
		filepath.Join(os.Getenv("ProgramData"), `Microsoft\Windows\Start Menu\Programs\GIN-DNS-Switch.lnk`),
	}
	for _, sm := range startMenus {
		os.Remove(sm)
	}

	// 3. Copy self to %TEMP% to unlock installation directory and wipe it
	exe, _ := os.Executable()
	instDir := filepath.Dir(exe)
	tempUninst := filepath.Join(os.TempDir(), fmt.Sprintf("GIN-DNS-Switch_Uninstall_%d.exe", time.Now().Unix()))

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
	cleanerCmd := fmt.Sprintf(`ping 127.0.0.1 -n 3 >nul & del /F /Q /A "%s\*.*" & rd /S /Q "%s"`, instDir, instDir)
	cmd := exec.Command("cmd.exe", "/C", cleanerCmd)
	cmd.Dir = os.TempDir()
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Start()
}

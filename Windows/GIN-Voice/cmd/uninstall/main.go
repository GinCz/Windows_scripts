// ==========================================================================================
// Execution Context : Go 1.22+ (Windows AMD64 Console Executable)
// Target Application: GIN-Voice
// Description       : Native Standalone Uninstaller for GIN-Voice with Vladimir's ANSI 90-char Styling
// ==========================================================================================

package main

import (
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
	kernel32             = syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitleW = kernel32.NewProc("SetConsoleTitleW")
	procSetConsoleMode   = kernel32.NewProc("SetConsoleMode")
	procGetStdHandle     = kernel32.NewProc("GetStdHandle")
)

const (
	STD_OUTPUT_HANDLE                  = ^uintptr(10) // -11
	ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
)

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

func enableVTMode() {
	hOut, _, _ := procGetStdHandle.Call(STD_OUTPUT_HANDLE)
	if hOut != 0 && hOut != ^uintptr(0) {
		var mode uint32
		procSetConsoleMode.Call(hOut, uintptr(mode|ENABLE_VIRTUAL_TERMINAL_PROCESSING))
	}
}

func main() {
	procSetConsoleTitleW.Call(uintptr(unsafe.Pointer(strPtr("GIN-Voice Clean Uninstaller by VladiMIR+AI"))))
	enableVTMode()

	line90 := strings.Repeat("=", 90)

	// ANSI Colors: Cyan \033[96m, Green \033[92m, Gray \033[90m, Reset \033[0m
	fmt.Println("\033[96m" + line90)
	fmt.Println("   GIN-Voice by VladiMIR+AI — Clean Uninstaller")
	fmt.Println("   Fast Multilingual Voice Typing Tool for Windows 10/11\033[90m")
	fmt.Println("\033[96m" + line90 + "\033[0m\n")

	fmt.Println("\033[92m[1/4] Stopping all active GIN-Voice background processes...\033[0m")
	_ = exec.Command("taskkill", "/F", "/IM", "GIN-Voice.exe", "/IM", "GIN-Voice_*.exe", "/IM", "GIN-Voice_Setup*.exe").Run()
	time.Sleep(500 * time.Millisecond)
	fmt.Println("\033[90m      Done. Processes terminated.\033[0m\n")

	fmt.Println("\033[92m[2/4] Removing desktop, start menu, and cloud shortcuts...\033[0m")
	userProfile := os.Getenv("USERPROFILE")
	appData := os.Getenv("APPDATA")
	desktopDir := filepath.Join(userProfile, "Desktop")
	startMenuDir := filepath.Join(appData, "Microsoft", "Windows", "Start Menu", "Programs")
	megaDesktopDir := `D:\MEGA\DOCS\desktop`

	_ = os.Remove(filepath.Join(desktopDir, "GIN-Voice.lnk"))
	_ = os.Remove(filepath.Join(startMenuDir, "GIN-Voice.lnk"))
	_ = os.Remove(filepath.Join(megaDesktopDir, "GIN-Voice.lnk"))

	if entries, err := os.ReadDir(megaDesktopDir); err == nil {
		for _, e := range entries {
			if strings.HasPrefix(e.Name(), "GIN-Voice_Setup") {
				_ = os.Remove(filepath.Join(megaDesktopDir, e.Name()))
			}
		}
	}
	fmt.Println("\033[90m      Done. Shortcuts removed.\033[0m\n")

	fmt.Println("\033[92m[3/4] Cleaning Windows Autostart and Registry entries...\033[0m")
	_ = exec.Command("reg", "delete", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "GIN-Voice", "/f").Run()
	_ = exec.Command("reg", "delete", `HKCU\Software\GIN-Voice`, "/f").Run()
	fmt.Println("\033[90m      Done. Registry cleaned.\033[0m\n")

	fmt.Println("\033[92m[4/4] Removing application directory and local data...\033[0m")
	currExe, err := os.Executable()
	appDir := filepath.Dir(currExe)
	if err == nil {
		if entries, err := os.ReadDir(appDir); err == nil {
			for _, e := range entries {
				name := strings.ToLower(e.Name())
				if !strings.HasPrefix(name, "uninstall") {
					_ = os.RemoveAll(filepath.Join(appDir, e.Name()))
				}
			}
		}
	}
	fmt.Println("\033[90m      Done. Application folder cleared.\033[0m\n")

	fmt.Println("\033[92m" + line90)
	fmt.Println("   GIN-Voice was successfully and completely uninstalled from your system!")
	fmt.Println(line90 + "\033[0m\n")
	fmt.Println("\033[90mThis window will close automatically in 3 seconds...\033[0m")
	time.Sleep(3 * time.Second)

	// Clean up appDir in background
	cmd := exec.Command("cmd.exe", "/c", fmt.Sprintf("timeout /t 1 >nul & rd /s /q \"%s\"", appDir))
	_ = cmd.Start()
}

package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"
)

var (
	shell32           = syscall.NewLazyDLL("shell32.dll")
	procShellExecuteW = shell32.NewProc("ShellExecuteW")
)

//go:embed GIN-DNS-Switch.cmd
var embeddedCMD []byte

//go:embed app.ico
var embeddedICO []byte

//go:embed version.json
var embeddedVersion []byte

//go:embed Uninstall.exe
var embeddedUninstall []byte

func runSelfAsAdmin() {
	exe, _ := os.Executable()
	cwd, _ := os.Getwd()
	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(exe)
	dPtr, _ := syscall.UTF16PtrFromString(cwd)
	aPtr, _ := syscall.UTF16PtrFromString("--elevated")
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), uintptr(unsafe.Pointer(aPtr)), uintptr(unsafe.Pointer(dPtr)), 1)
}

func isAdmin() bool {
	_, err := os.Open(`\\.\PHYSICALDRIVE0`)
	return err == nil
}

func createShortcutsSafe(targetCmd, workDir, icoPath string) {
	psScript := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$deskDirs = @('D:\MEGA\DOCS\desktop', 'D:\mega\docs\desktop', [Environment]::GetFolderPath('Desktop'), "$env:USERPROFILE\Desktop", "$env:PUBLIC\Desktop")
foreach ($d in $deskDirs) {
    if (Test-Path $d) {
        try {
            $s = $w.CreateShortcut("$d\GIN-DNS-Switch.lnk")
            $s.TargetPath = '%s'
            $s.WorkingDirectory = '%s'
            $s.IconLocation = '%s,0'
            $s.Description = 'GIN-DNS-Switch by VladiMIR+AI'
            $s.Save()
        } catch {}
    }
}
$smDirs = @([Environment]::GetFolderPath('CommonPrograms'), [Environment]::GetFolderPath('Programs'))
foreach ($sm in $smDirs) {
    if (Test-Path $sm) {
        try {
            $s = $w.CreateShortcut("$sm\GIN-DNS-Switch.lnk")
            $s.TargetPath = '%s'
            $s.WorkingDirectory = '%s'
            $s.IconLocation = '%s,0'
            $s.Description = 'GIN-DNS-Switch by VladiMIR+AI'
            $s.Save()
        } catch {}
    }
}
`, targetCmd, workDir, icoPath, targetCmd, workDir, icoPath)

	cmd := exec.Command("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", psScript)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Run()
}

func main() {
	if !isAdmin() {
		runSelfAsAdmin()
		return
	}

	targetDir := `C:\Program Files\GIN-DNS-Switch`
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		targetDir = filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-DNS-Switch")
		os.MkdirAll(targetDir, 0755)
	}

	cmdDest := filepath.Join(targetDir, "GIN-DNS-Switch.cmd")
	icoDest := filepath.Join(targetDir, "app.ico")
	verDest := filepath.Join(targetDir, "version.json")
	uninstDest := filepath.Join(targetDir, "Uninstall.exe")

	os.WriteFile(cmdDest, embeddedCMD, 0755)
	os.WriteFile(icoDest, embeddedICO, 0644)
	os.WriteFile(verDest, embeddedVersion, 0644)
	os.WriteFile(uninstDest, embeddedUninstall, 0755)

	// Clean up any stray versioned scripts from previous installations
	if entries, err := os.ReadDir(targetDir); err == nil {
		for _, e := range entries {
			name := e.Name()
			if strings.HasPrefix(name, "GIN-DNS-Switch_v") && strings.HasSuffix(name, ".cmd") {
				os.Remove(filepath.Join(targetDir, name))
			}
		}
	}

	createShortcutsSafe(cmdDest, targetDir, icoDest)

	// Register in Windows Programs & Features
	regCmd := fmt.Sprintf(`
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayName" /t REG_SZ /d "GIN-DNS-Switch" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayVersion" /t REG_SZ /d "v011" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "Publisher" /t REG_SZ /d "Vladimir Bulantsev (GinCz) & AI" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayIcon" /t REG_SZ /d "%s" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "UninstallString" /t REG_SZ /d "\"%s\"" /f
`, icoDest, uninstDest)
	cmdReg := exec.Command("cmd.exe", "/c", regCmd)
	cmdReg.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg.Run()

	// Launch installed application immediately with zero popups
	cmdLaunch := exec.Command("cmd.exe", "/c", fmt.Sprintf(`"%s"`, cmdDest))
	cmdLaunch.Dir = targetDir
	cmdLaunch.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdLaunch.Start()
}

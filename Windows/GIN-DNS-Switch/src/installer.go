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
	user32            = syscall.NewLazyDLL("user32.dll")
	shell32           = syscall.NewLazyDLL("shell32.dll")
	procMessageBoxW   = user32.NewProc("MessageBoxW")
	procShellExecuteW = shell32.NewProc("ShellExecuteW")
)

const (
	MB_OK       = 0x00000000
	MB_ICONINFO = 0x00000040
)

func msgBox(title, text string, style uint) int {
	tPtr, _ := syscall.UTF16PtrFromString(text)
	cPtr, _ := syscall.UTF16PtrFromString(title)
	r, _, _ := procMessageBoxW.Call(0, uintptr(unsafe.Pointer(tPtr)), uintptr(unsafe.Pointer(cPtr)), uintptr(style))
	return int(r)
}

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
	isSilent := false
	for _, arg := range os.Args[1:] {
		a := strings.ToLower(arg)
		if a == "/silent" || a == "-silent" || a == "--silent" || a == "/s" {
			isSilent = true
		}
	}

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
	cmdVDest := filepath.Join(targetDir, "GIN-DNS-Switch_v006.cmd")
	icoDest := filepath.Join(targetDir, "app.ico")
	verDest := filepath.Join(targetDir, "version.json")
	uninstDest := filepath.Join(targetDir, "Uninstall.exe")

	os.WriteFile(cmdDest, embeddedCMD, 0755)
	os.WriteFile(cmdVDest, embeddedCMD, 0755)
	os.WriteFile(icoDest, embeddedICO, 0644)
	os.WriteFile(verDest, embeddedVersion, 0644)
	os.WriteFile(uninstDest, embeddedUninstall, 0755)

	createShortcutsSafe(cmdDest, targetDir, icoDest)

	// Register in Windows Programs & Features
	regCmd := fmt.Sprintf(`
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayName" /t REG_SZ /d "GIN-DNS-Switch" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayVersion" /t REG_SZ /d "v006" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "Publisher" /t REG_SZ /d "Vladimir Bulantsev (GinCz) & AI" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayIcon" /t REG_SZ /d "%s" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "UninstallString" /t REG_SZ /d "\"%s\"" /f
`, icoDest, uninstDest)
	cmdReg := exec.Command("cmd.exe", "/c", regCmd)
	cmdReg.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmdReg.Run()

	if !isSilent {
		msgBox("GIN-DNS-Switch", "GIN-DNS-Switch v006 успешно установлен!\nЯрлык добавлен на Рабочий стол.", MB_OK|MB_ICONINFO)
	}
}

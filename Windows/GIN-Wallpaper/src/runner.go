package main

import (
	"unsafe"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
)

var (
	user32          = syscall.NewLazyDLL("user32.dll")
	procMessageBoxW = user32.NewProc("MessageBoxW")
)

func msgBox(title, text string, style uint) {
	tPtr, _ := syscall.UTF16PtrFromString(text)
	cPtr, _ := syscall.UTF16PtrFromString(title)
	procMessageBoxW.Call(0, uintptr(unsafe.Pointer(tPtr)), uintptr(unsafe.Pointer(cPtr)), uintptr(style))
}

func findPython() string {
	candidates := []string{
		"pythonw.exe",
		"python.exe",
		`C:\Python312\pythonw.exe`,
		`C:\Python311\pythonw.exe`,
		`C:\Python310\pythonw.exe`,
		`C:\Python312\python.exe`,
		`C:\Python311\python.exe`,
		`C:\Python310\python.exe`,
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python312\pythonw.exe`),
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python311\pythonw.exe`),
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python312\python.exe`),
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python311\python.exe`),
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
		if p, err := exec.LookPath(c); err == nil {
			return p
		}
	}
	return ""
}

func main() {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	script := filepath.Join(dir, "gin_wallpaper.py")

	logFile, _ := os.OpenFile(filepath.Join(dir, "launcher.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if logFile != nil {
		defer logFile.Close()
		fmt.Fprintf(logFile, "[%s] Starting GIN-Wallpaper-Calend launcher...\n", time.Now().Format("2006-01-02 15:04:05"))
	}

	py := findPython()
	if py == "" {
		if logFile != nil {
			fmt.Fprintf(logFile, "ERROR: Python is not found on this system!\n")
		}
		msgBox("GIN-Wallpaper-Calend", "Python is not found on your PC!\nPlease install Python 3.10+ from python.org", 0x10)
		return
	}

	if logFile != nil {
		fmt.Fprintf(logFile, "Using Python: %s\nScript: %s\n", py, script)
	}

	cmd := exec.Command(py, script)
	cmd.Dir = dir
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	err := cmd.Start()
	if err != nil && logFile != nil {
		fmt.Fprintf(logFile, "Launch error: %v\n", err)
	}
}

package main

import (
	_ "embed"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
)

func findPython() string {
	candidates := []string{
		"pythonw.exe",
		"python.exe",
		`C:\Python312\pythonw.exe`,
		`C:\Python311\pythonw.exe`,
		`C:\Python310\pythonw.exe`,
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python312\pythonw.exe`),
		filepath.Join(os.Getenv("LOCALAPPDATA"), `Programs\Python\Python311\pythonw.exe`),
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
		if p, err := exec.LookPath(c); err == nil {
			return p
		}
	}
	return "pythonw.exe"
}

func main() {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	script := filepath.Join(dir, "gin_wallpaper.py")

	// If script doesn't exist, try local appdata or current dir
	if _, err := os.Stat(script); os.IsNotExist(err) {
		time.Sleep(500 * time.Millisecond)
	}

	py := findPython()

	cmd := exec.Command(py, script)
	cmd.Dir = dir
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Start()
}

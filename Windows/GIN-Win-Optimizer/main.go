package main

import (
	"bytes"
	"compress/gzip"
	_ "embed"
	"encoding/base64"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"unicode/utf16"
	"unsafe"

	"golang.org/x/sys/windows"
)

//go:embed engine.ps1.gz
var embeddedEngineGz []byte

//go:embed app.ico
var embeddedAppIco []byte

const (
	AppName        = "GIN-Win-Optimizer"
	AppVersion     = "v035"
	AppTitle       = "GIN-Win-Optimizer v035 [VladiMIR + AI]"
	MutexName      = "Local\\GIN_WIN_OPTIMIZER_MUTEX"
	TelegramURL    = "https://t.me/GinCz"
	OfficialAuthor = "VladiMIR+AI (Vladimir Bulantsev)"
)

var (
	user32               = windows.NewLazySystemDLL("user32.dll")
	shell32              = windows.NewLazySystemDLL("shell32.dll")
	procMessageBoxW      = user32.NewProc("MessageBoxW")
	procShowWindowAsync  = user32.NewProc("ShowWindowAsync")
	procSetForeground    = user32.NewProc("SetForegroundWindow")
	procEnumWindows      = user32.NewProc("EnumWindows")
	procGetWindowTextW   = user32.NewProc("GetWindowTextW")
	procGetWindowTextLen = user32.NewProc("GetWindowTextLengthW")
	procIsUserAnAdmin    = shell32.NewProc("IsUserAnAdmin")
)

const (
	SW_RESTORE       = 9
	MB_OK            = 0x00000000
	MB_ICONERROR     = 0x00000010
	MB_ICONWARNING   = 0x00000030
	MB_ICONINFO      = 0x00000040
	CREATE_NO_WINDOW = 0x08000000
)

func showMessage(title, text string, flags uint32) {
	tPtr, _ := windows.UTF16PtrFromString(title)
	mPtr, _ := windows.UTF16PtrFromString(text)
	procMessageBoxW.Call(0, uintptr(unsafe.Pointer(mPtr)), uintptr(unsafe.Pointer(tPtr)), uintptr(flags))
}

func bringExistingWindowToFront() {
	cb := syscall.NewCallback(func(hwnd uintptr, lparam uintptr) uintptr {
		lenRet, _, _ := procGetWindowTextLen.Call(hwnd)
		if lenRet > 0 {
			buf := make([]uint16, lenRet+1)
			procGetWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(&buf[0])), uintptr(lenRet+1))
			title := windows.UTF16ToString(buf)
			if strings.HasPrefix(title, "GIN-Win-Optimizer") {
				procShowWindowAsync.Call(hwnd, uintptr(SW_RESTORE))
				procSetForeground.Call(hwnd)
				return 0 // stop enumeration
			}
		}
		return 1 // continue
	})
	procEnumWindows.Call(cb, 0)
}

func isUserAdmin() bool {
	if procIsUserAnAdmin.Find() == nil {
		ret, _, _ := procIsUserAnAdmin.Call()
		return ret != 0
	}
	return false
}

func relaunchAsAdmin() error {
	exe, err := os.Executable()
	if err != nil {
		return err
	}
	verbPtr, _ := windows.UTF16PtrFromString("runas")
	exePtr, _ := windows.UTF16PtrFromString(exe)

	var args string
	if len(os.Args) > 1 {
		args = strings.Join(os.Args[1:], " ")
	}
	var argsPtr *uint16
	if args != "" {
		argsPtr, _ = windows.UTF16PtrFromString(args)
	}

	err = windows.ShellExecute(0, verbPtr, exePtr, argsPtr, nil, windows.SW_SHOWNORMAL)
	if err != nil {
		return err
	}
	os.Exit(0)
	return nil
}

func decompressGzip(data []byte) ([]byte, error) {
	r, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer r.Close()
	return io.ReadAll(r)
}

func encodeUTF16LE(s string) []byte {
	u16 := utf16.Encode([]rune(s))
	buf := make([]byte, len(u16)*2)
	for i, v := range u16 {
		buf[i*2] = byte(v)
		buf[i*2+1] = byte(v >> 8)
	}
	return buf
}

func main() {
	// 1. Single Instance Mutex Protection
	mutexNamePtr, _ := windows.UTF16PtrFromString(MutexName)
	hMutex, err := windows.CreateMutex(nil, false, mutexNamePtr)
	if err != nil && err == windows.ERROR_ALREADY_EXISTS {
		bringExistingWindowToFront()
		if hMutex != 0 {
			windows.CloseHandle(hMutex)
		}
		return
	}
	if hMutex != 0 {
		defer windows.CloseHandle(hMutex)
	}

	// 2. Administrator check & elevation
	if !isUserAdmin() {
		if err := relaunchAsAdmin(); err != nil {
			showMessage(AppTitle+" Error", fmt.Sprintf("Failed to elevate to Administrator privileges:\n%v", err), MB_ICONERROR)
			return
		}
		return
	}

	// 3. Prepare target deployment directory
	targetDir := os.Getenv("LOCALAPPDATA")
	if targetDir == "" {
		targetDir = os.TempDir()
	}
	appDir := filepath.Join(targetDir, "GIN-Win-Optimizer")
	if err := os.MkdirAll(appDir, 0755); err != nil {
		appDir = filepath.Join(os.TempDir(), "GIN-Win-Optimizer")
		_ = os.MkdirAll(appDir, 0755)
	}

	// 4. Write app.ico for WPF window icon
	icoPath := filepath.Join(appDir, "app.ico")
	if len(embeddedAppIco) > 0 {
		_ = os.WriteFile(icoPath, embeddedAppIco, 0644)
	}

	// 5. Decompress and deploy engine_v035.ps1 with UTF-8 BOM
	engineBytes, err := decompressGzip(embeddedEngineGz)
	if err != nil {
		showMessage(AppTitle+" Error", fmt.Sprintf("Failed to decompress internal optimizer engine:\n%v", err), MB_ICONERROR)
		return
	}

	scriptPath := filepath.Join(appDir, "engine_v035.ps1")
	if err := os.WriteFile(scriptPath, engineBytes, 0644); err != nil {
		showMessage(AppTitle+" Error", fmt.Sprintf("Failed to write optimizer script:\n%v", err), MB_ICONERROR)
		return
	}

	// 6. Locate 64-bit PowerShell executable
	systemRoot := os.Getenv("SystemRoot")
	if systemRoot == "" {
		systemRoot = "C:\\Windows"
	}
	psPath := filepath.Join(systemRoot, "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
	if _, err := os.Stat(psPath); os.IsNotExist(err) {
		psPath = "powershell.exe"
	}

	// 7. Launch PowerShell via UTF-16LE Base64 -EncodedCommand
	// Reads the script using exact UTF-8 .NET API with zero command-line escaping issues
	loaderScript := fmt.Sprintf(`try { $s = [System.IO.File]::ReadAllText('%s', [System.Text.Encoding]::UTF8); Invoke-Expression $s } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), 'Optimizer Engine Error') }`, strings.ReplaceAll(scriptPath, "'", "''"))
	encodedCmd := base64.StdEncoding.EncodeToString(encodeUTF16LE(loaderScript))

	psArgs := []string{
		"-NoProfile",
		"-ExecutionPolicy", "Bypass",
		"-STA",
		"-WindowStyle", "Hidden",
		"-EncodedCommand", encodedCmd,
	}

	cmd := exec.Command(psPath, psArgs...)
	cmd.Dir = appDir
	cmd.SysProcAttr = &syscall.SysProcAttr{
		CreationFlags: CREATE_NO_WINDOW,
		HideWindow:    true,
	}

	// Run and wait for window to close
	if err := cmd.Run(); err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			if exitErr.ExitCode() != 0 {
				showMessage(AppTitle+" Error", fmt.Sprintf("Optimizer engine exited with code %d.\nPlease check your Windows PowerShell installation.", exitErr.ExitCode()), MB_ICONERROR)
				return
			}
		}
		showMessage(AppTitle+" Error", fmt.Sprintf("Optimizer launch error:\n%v", err), MB_ICONERROR)
	}
}

// Execution Context : Go 1.19+ (Windows AMD64)
// Target Server     : Local Windows Desktop PC
// Description       : GIN-Voice Native Windows Client & Installer with Whisper AI and Win32 GUI [v002]

package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

const (
	AppName       = "GIN-Voice"
	AppVersion    = "v002"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v002]"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice"
	GroqKeysURL   = "https://console.groq.com/keys"

	// Win32 Constants
	WM_USER          = 0x0400
	WM_TRAYICON      = WM_USER + 1
	WM_COMMAND       = 0x0111
	WM_HOTKEY        = 0x0312
	WM_DESTROY       = 0x0002
	WM_CLOSE         = 0x0010
	WM_SETFONT       = 0x0030
	WM_SETICON       = 0x0080
	WM_RBUTTONUP     = 0x0205
	WM_LBUTTONDBLCLK = 0x0203
	WM_KEYDOWN       = 0x0100
	WM_SYSKEYDOWN    = 0x0104

	WH_KEYBOARD_LL = 13

	NIM_ADD     = 0x00000000
	NIM_MODIFY  = 0x00000001
	NIM_DELETE  = 0x00000002
	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x00000800
	MF_CHECKED   = 0x00000008
	MF_UNCHECKED = 0x00000000
	MF_POPUP     = 0x00000010

	TPM_RIGHTBUTTON = 0x0002

	VK_F4           = 0x73
	VK_F8           = 0x77
	VK_F9           = 0x78
	VK_F10          = 0x79
	VK_F12          = 0x7B
	VK_CONTROL      = 0x11
	KEYEVENTF_KEYUP = 0x0002

	CF_UNICODETEXT = 13
	GMEM_MOVEABLE  = 0x0002

	SW_SHOWNORMAL = 1
	SW_HIDE       = 0

	DEFAULT_GUI_FONT = 17
	COLOR_WINDOW     = 5

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x0010
	LR_DEFAULTSIZE  = 0x0040
	ICON_SMALL      = 0
	ICON_BIG        = 1

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	ES_AUTOHSCROLL      = 0x0080
	BS_DEFPUSHBUTTON    = 0x0001
	BS_AUTOCHECKBOX     = 0x0003

	// Menu Command IDs
	IDM_TOGGLE_RECORD = 1001
	IDM_SETUP_KEY     = 1002
	IDM_OPEN_DICT     = 1003
	IDM_LINK_FOLDER   = 1004
	IDM_OPEN_CONFIG   = 1005
	IDM_AUTOSTART     = 1006
	IDM_OPEN_HELP     = 1007
	IDM_ICONS_PAGE    = 1008
	IDM_EXIT          = 1009

	IDM_LANG_BASE = 2000

	// Settings Dialog IDs
	IDC_BTN_SAVE       = 3001
	IDC_BTN_GROQ       = 3002
	IDC_EDIT_KEY       = 3003
	IDC_EDIT_FOLDER    = 3004
	IDC_BTN_BROWSE     = 3005
	IDC_EDIT_HOTKEY    = 3006
	IDC_CHK_EN         = 3007
	IDC_CHK_CS         = 3008
	IDC_CHK_RU         = 3009
	IDC_BTN_DICT       = 3010
)

//go:embed dictionary.json
var defaultDictionaryJSON []byte

//go:embed setup_guide.html
var defaultSetupGuideHTML []byte

//go:embed icons_showcase.html
var defaultIconsShowcaseHTML []byte

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procRegisterClassExW    = user32.NewProc("RegisterClassExW")
	procCreateWindowExW     = user32.NewProc("CreateWindowExW")
	procDefWindowProcW      = user32.NewProc("DefWindowProcW")
	procDestroyWindow       = user32.NewProc("DestroyWindow")
	procPostQuitMessage     = user32.NewProc("PostQuitMessage")
	procGetMessageW         = user32.NewProc("GetMessageW")
	procTranslateMessage    = user32.NewProc("TranslateMessage")
	procDispatchMessageW    = user32.NewProc("DispatchMessageW")
	procSetWindowsHookExW   = user32.NewProc("SetWindowsHookExW")
	procUnhookWindowsHookEx = user32.NewProc("UnhookWindowsHookEx")
	procCallNextHookEx      = user32.NewProc("CallNextHookEx")
	procCreatePopupMenu     = user32.NewProc("CreatePopupMenu")
	procAppendMenuW         = user32.NewProc("AppendMenuW")
	procTrackPopupMenu      = user32.NewProc("TrackPopupMenu")
	procDestroyMenu         = user32.NewProc("DestroyMenu")
	procSetForegroundWindow = user32.NewProc("SetForegroundWindow")
	procGetCursorPos        = user32.NewProc("GetCursorPos")
	procOpenClipboard       = user32.NewProc("OpenClipboard")
	procCloseClipboard      = user32.NewProc("CloseClipboard")
	procEmptyClipboard      = user32.NewProc("EmptyClipboard")
	procSetClipboardData    = user32.NewProc("SetClipboardData")
	procGetClipboardData    = user32.NewProc("GetClipboardData")
	procIsClipboardAvailable = user32.NewProc("IsClipboardFormatAvailable")
	procKeybdEvent          = user32.NewProc("keybd_event")
	procMessageBoxW         = user32.NewProc("MessageBoxW")
	procLoadIconW           = user32.NewProc("LoadIconW")
	procLoadImageW          = user32.NewProc("LoadImageW")
	procShowWindow          = user32.NewProc("ShowWindow")
	procSendMessageW        = user32.NewProc("SendMessageW")
	procGetWindowTextW      = user32.NewProc("GetWindowTextW")
	procSetWindowTextW      = user32.NewProc("SetWindowTextW")
	procGetSystemMetrics    = user32.NewProc("GetSystemMetrics")

	procShellNotifyIconW = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW    = shell32.NewProc("ShellExecuteW")

	procBeep             = kernel32.NewProc("Beep")
	procGlobalAlloc      = kernel32.NewProc("GlobalAlloc")
	procGlobalLock       = kernel32.NewProc("GlobalLock")
	procGlobalUnlock     = kernel32.NewProc("GlobalUnlock")
	procGlobalFree       = kernel32.NewProc("GlobalFree")
	procGetModuleHandleW = kernel32.NewProc("GetModuleHandleW")

	procGetStockObject     = gdi32.NewProc("GetStockObject")
	procMciSendStringW     = winmm.NewProc("mciSendStringW")
	procMciGetErrorStringW = winmm.NewProc("mciGetErrorStringW")
)

type POINT struct {
	X int32
	Y int32
}

type KBDLLHOOKSTRUCT struct {
	VkCode      uint32
	ScanCode    uint32
	Flags       uint32
	Time        uint32
	DwExtraInfo uintptr
}

type WNDCLASSEXW struct {
	CbSize        uint32
	Style         uint32
	LpfnWndProc   uintptr
	CbClsExtra    int32
	CbWndExtra    int32
	HInstance     uintptr
	HIcon         uintptr
	HCursor       uintptr
	HbrBackground uintptr
	LpszMenuName  *uint16
	LpszClassName *uint16
	HIconSm       uintptr
}

type NOTIFYICONDATAW struct {
	CbSize           uint32
	HWnd             uintptr
	UID              uint32
	UFlags           uint32
	UCallbackMessage uint32
	HIcon            uintptr
	SzTip            [128]uint16
}

type MSG struct {
	HWnd    uintptr
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      POINT
}

type LanguageItem struct {
	Code string `json:"code"`
	Name string `json:"name"`
}

type Config struct {
	Version               string         `json:"version"`
	FirstRun              bool           `json:"first_run"`
	Hotkey                string         `json:"hotkey"`
	HotkeyVK              uint32         `json:"hotkey_vk"`
	HotkeyMod             uint32         `json:"hotkey_mod"`
	ActiveLanguages       []string       `json:"active_languages"`
	AllLanguages          []LanguageItem `json:"all_languages"`
	GroqAPIKey            string         `json:"groq_api_key"`
	SoundFeedback         bool           `json:"sound_feedback"`
	AutoPaste             bool           `json:"auto_paste"`
	RestoreClipboard      bool           `json:"restore_clipboard"`
	Autostart             bool           `json:"autostart"`
	LinkedKnowledgeFolder string         `json:"linked_knowledge_folder"`
}

var (
	appDir          string
	configFile      string
	dictFile        string
	helpFile        string
	iconsFile       string
	logFile         string
	config          Config
	dictionary      map[string]string
	dictMutex       sync.RWMutex
	hwndMain        uintptr
	hwndSetup       uintptr
	hwndEditKey     uintptr
	hwndEditFolder  uintptr
	hwndEditHotkey  uintptr
	hwndChkEN       uintptr
	hwndChkCS       uintptr
	hwndChkRU       uintptr
	nid             NOTIFYICONDATAW
	isRecording     bool
	recordMutex     sync.Mutex
	trayCreated     bool
	hKeyboardHook   uintptr
	appIcon         uintptr
)

func writeLog(msg string) {
	if logFile == "" {
		return
	}
	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		defer f.Close()
		ts := time.Now().Format("2006-01-02 15:04:05")
		f.WriteString(fmt.Sprintf("[%s] %s\n", ts, msg))
	}
}

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

func loadAppIcon() uintptr {
	if appIcon != 0 {
		return appIcon
	}
	icoPath := filepath.Join(appDir, "app.ico")
	if _, err := os.Stat(icoPath); err == nil {
		h, _, _ := procLoadImageW.Call(
			0,
			uintptr(unsafe.Pointer(strPtr(icoPath))),
			IMAGE_ICON,
			0, 0,
			LR_LOADFROMFILE|LR_DEFAULTSIZE,
		)
		if h != 0 {
			appIcon = h
			return appIcon
		}
	}
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	h, _, _ := procLoadIconW.Call(hInstance, uintptr(1))
	if h != 0 {
		appIcon = h
		return appIcon
	}
	h, _, _ = procLoadIconW.Call(0, uintptr(32512)) // IDI_APPLICATION
	appIcon = h
	return appIcon
}

func playBeep(freq, duration uint32) {
	if config.SoundFeedback {
		go func() {
			procBeep.Call(uintptr(freq), uintptr(duration))
		}()
	}
}

func mciSend(cmd string) error {
	pCmd := strPtr(cmd)
	ret, _, _ := procMciSendStringW.Call(
		uintptr(unsafe.Pointer(pCmd)),
		0, 0, 0,
	)
	if ret != 0 {
		var buf [256]uint16
		procMciGetErrorStringW.Call(ret, uintptr(unsafe.Pointer(&buf[0])), 256)
		errStr := syscall.UTF16ToString(buf[:])
		writeLog(fmt.Sprintf("MCI Error for [%s]: %s (code %d)", cmd, errStr, ret))
		return fmt.Errorf("MCI error %d: %s", ret, errStr)
	}
	return nil
}

func updateTrayTip(text string) {
	if !trayCreated {
		return
	}
	var tip [128]uint16
	chars := []rune(text)
	for i := 0; i < len(chars) && i < 127; i++ {
		tip[i] = uint16(chars[i])
	}
	nid.SzTip = tip
	procShellNotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
}

func initTrayIcon() {
	if trayCreated {
		return
	}
	hIcon := loadAppIcon()

	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.HWnd = hwndMain
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIcon
	updateTrayTip(AppTitle + " | Ready (Press " + config.Hotkey + " to dictate)")
	procShellNotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))
	trayCreated = true
}

func loadConfig() {
	config = Config{
		Version:   AppVersion,
		FirstRun:  true,
		Hotkey:    "F4",
		HotkeyVK:  VK_F4,
		HotkeyMod: 0,
		ActiveLanguages: []string{"en"},
		AllLanguages: []LanguageItem{
			{Code: "en", Name: "English"},
			{Code: "cs", Name: "Czech"},
			{Code: "ru", Name: "Russian"},
			{Code: "de", Name: "German"},
			{Code: "fr", Name: "French"},
			{Code: "es", Name: "Spanish"},
			{Code: "uk", Name: "Ukrainian"},
		},
		SoundFeedback:    true,
		AutoPaste:        true,
		RestoreClipboard: true,
		Autostart:        false,
	}

	data, err := os.ReadFile(configFile)
	if err == nil {
		_ = json.Unmarshal(data, &config)
	} else {
		saveConfig()
	}
}

func saveConfig() {
	data, err := json.MarshalIndent(config, "", "  ")
	if err == nil {
		_ = os.WriteFile(configFile, data, 0644)
	}
}

func loadDictionary() {
	dictMutex.Lock()
	defer dictMutex.Unlock()

	dictionary = make(map[string]string)
	data, err := os.ReadFile(dictFile)
	if err == nil {
		_ = json.Unmarshal(data, &dictionary)
	} else {
		if len(defaultDictionaryJSON) > 0 {
			_ = json.Unmarshal(defaultDictionaryJSON, &dictionary)
		}
		data, _ := json.MarshalIndent(dictionary, "", "  ")
		_ = os.WriteFile(dictFile, data, 0644)
	}
}

func applyDictionary(input string) string {
	dictMutex.RLock()
	defer dictMutex.RUnlock()

	type dictEntry struct {
		key   string
		value string
	}
	var entries []dictEntry
	for k, v := range dictionary {
		entries = append(entries, dictEntry{key: k, value: v})
	}

	sort.Slice(entries, func(i, j int) bool {
		return len(entries[i].key) > len(entries[j].key)
	})

	result := input
	for _, entry := range entries {
		pattern := strings.ToLower(entry.key)
		lowerRes := strings.ToLower(result)

		idx := strings.Index(lowerRes, pattern)
		for idx != -1 {
			result = result[:idx] + entry.value + result[idx+len(pattern):]
			lowerRes = strings.ToLower(result)
			idx = strings.Index(lowerRes, pattern)
		}
	}
	return result
}

func getTempWavPath() string {
	return filepath.Join(os.TempDir(), "gin_voice_recording.wav")
}

func startRecording() {
	recordMutex.Lock()
	defer recordMutex.Unlock()

	if isRecording {
		return
	}

	_ = mciSend("close ginmic")
	err := mciSend("open new type waveaudio alias ginmic")
	if err != nil {
		writeLog("Failed to open waveaudio: " + err.Error())
		playBeep(250, 150)
		return
	}

	_ = mciSend("set ginmic time format ms")
	_ = mciSend("set ginmic bitspersample 16")
	_ = mciSend("set ginmic channels 1")
	// Try 44100 first, fallback to default
	_ = mciSend("set ginmic samplespersec 44100")

	err = mciSend("record ginmic")
	if err != nil {
		writeLog("Failed to record waveaudio: " + err.Error())
		playBeep(250, 150)
		return
	}

	isRecording = true
	playBeep(880, 100) // High chime = recording started
	updateTrayTip(AppTitle + " | 🎙️ RECORDING... (Press " + config.Hotkey + " to Stop)")
}

func stopRecordingAndTranscribe() {
	recordMutex.Lock()
	if !isRecording {
		recordMutex.Unlock()
		return
	}
	isRecording = false
	recordMutex.Unlock()

	playBeep(440, 100) // Low chime = recording stopped
	updateTrayTip(AppTitle + " | ⚡ Transcribing with Whisper...")

	wavPath := getTempWavPath()
	_ = mciSend("stop ginmic")
	_ = mciSend(fmt.Sprintf("save ginmic \"%s\"", wavPath))
	_ = mciSend("close ginmic")

	go func() {
		defer os.Remove(wavPath)
		defer updateTrayTip(AppTitle + " | Ready (Press " + config.Hotkey + " to dictate)")

		text, err := transcribeAudio(wavPath)
		if err != nil {
			writeLog("Transcription error: " + err.Error())
			playBeep(220, 300)
			return
		}

		text = strings.TrimSpace(text)
		if text == "" {
			return
		}

		text = applyDictionary(text)
		writeLog(fmt.Sprintf("Transcription inserted: [%s]", text))
		pasteText(text)
	}()
}

func toggleRecording() {
	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	if !rec {
		startRecording()
	} else {
		stopRecordingAndTranscribe()
	}
}

func transcribeAudio(wavPath string) (string, error) {
	apiKey := config.GroqAPIKey
	if apiKey == "" {
		apiKey = os.Getenv("GROQ_API_KEY")
	}
	if apiKey == "" {
		showSettingsDialog()
		return "", fmt.Errorf("missing api key")
	}

	audioData, err := os.ReadFile(wavPath)
	if err != nil || len(audioData) < 1000 {
		return "", fmt.Errorf("empty or invalid recording (bytes: %d)", len(audioData))
	}

	var reqBody bytes.Buffer
	writer := multipart.NewWriter(&reqBody)

	part, err := writer.CreateFormFile("file", "audio.wav")
	if err != nil {
		return "", err
	}
	_, _ = part.Write(audioData)

	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "text")

	// Context prompt biased with project entities
	dictMutex.RLock()
	var terms []string
	for _, v := range dictionary {
		terms = append(terms, v)
	}
	dictMutex.RUnlock()
	if len(terms) > 30 {
		terms = terms[:30]
	}
	prompt := strings.Join(terms, ", ")
	if prompt != "" {
		_ = writer.WriteField("prompt", prompt)
	}

	if len(config.ActiveLanguages) == 1 {
		_ = writer.WriteField("language", config.ActiveLanguages[0])
	}

	err = writer.Close()
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/audio/transcriptions", &reqBody)
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Groq API error (%d): %s", resp.StatusCode, string(respBytes))
	}

	return string(respBytes), nil
}

func getClipboardText() string {
	r, _, _ := procIsClipboardAvailable.Call(CF_UNICODETEXT)
	if r == 0 {
		return ""
	}
	r, _, _ = procOpenClipboard.Call(0)
	if r == 0 {
		return ""
	}
	defer procCloseClipboard.Call()

	hData, _, _ := procGetClipboardData.Call(CF_UNICODETEXT)
	if hData == 0 {
		return ""
	}

	pData, _, _ := procGlobalLock.Call(hData)
	if pData == 0 {
		return ""
	}
	defer procGlobalUnlock.Call(hData)

	return syscall.UTF16ToString((*[1 << 20]uint16)(unsafe.Pointer(pData))[:])
}

func setClipboardText(text string) bool {
	utf16Chars, err := syscall.UTF16FromString(text)
	if err != nil {
		return false
	}
	bytesSize := len(utf16Chars) * 2

	hMem, _, _ := procGlobalAlloc.Call(GMEM_MOVEABLE, uintptr(bytesSize))
	if hMem == 0 {
		return false
	}

	pMem, _, _ := procGlobalLock.Call(hMem)
	if pMem == 0 {
		procGlobalFree.Call(hMem)
		return false
	}

	dest := (*[1 << 20]byte)(unsafe.Pointer(pMem))
	src := (*[1 << 20]byte)(unsafe.Pointer(&utf16Chars[0]))
	copy(dest[:bytesSize], src[:bytesSize])
	procGlobalUnlock.Call(hMem)

	r, _, _ := procOpenClipboard.Call(0)
	if r == 0 {
		procGlobalFree.Call(hMem)
		return false
	}
	defer procCloseClipboard.Call()

	procEmptyClipboard.Call()
	procSetClipboardData.Call(CF_UNICODETEXT, hMem)
	return true
}

func pasteText(text string) {
	oldClip := ""
	if config.RestoreClipboard {
		oldClip = getClipboardText()
	}

	setClipboardText(text)
	time.Sleep(30 * time.Millisecond)

	// Simulate Ctrl + V
	procKeybdEvent.Call(VK_CONTROL, 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, 0, 0)
	procKeybdEvent.Call(uintptr('V'), 0, KEYEVENTF_KEYUP, 0)
	procKeybdEvent.Call(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)

	if config.RestoreClipboard && oldClip != "" {
		go func(prev string) {
			time.Sleep(250 * time.Millisecond)
			setClipboardText(prev)
		}(oldClip)
	}
}

func pickFolderDialog() string {
	psCmd := `Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Выберите общую папку с базами знаний и репозиториями для GIN-Voice'; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { [Console]::WriteLine($f.SelectedPath) }`
	out, err := exec.Command("powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", psCmd).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func linkKnowledgeFolder(folderPath string) int {
	if folderPath == "" {
		return 0
	}
	dictMutex.Lock()
	defer dictMutex.Unlock()

	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return 0
	}

	addedCount := 0
	for _, entry := range entries {
		name := entry.Name()
		if strings.HasPrefix(name, ".") {
			continue
		}
		cleanName := strings.TrimSuffix(name, filepath.Ext(name))
		cleanName = strings.ReplaceAll(cleanName, "_", " ")
		cleanName = strings.ReplaceAll(cleanName, "-", " ")
		key := strings.ToLower(cleanName)

		if _, exists := dictionary[key]; !exists {
			dictionary[key] = entry.Name()
			addedCount++
		}
	}

	if addedCount > 0 {
		data, _ := json.MarshalIndent(dictionary, "", "  ")
		_ = os.WriteFile(dictFile, data, 0644)
	}
	return addedCount
}

func toggleAutostart() {
	config.Autostart = !config.Autostart
	saveConfig()

	startupDir := filepath.Join(os.Getenv("APPDATA"), "Microsoft", "Windows", "Start Menu", "Programs", "Startup")
	shortcutPath := filepath.Join(startupDir, "GIN-Voice.bat")

	if config.Autostart {
		exePath, _ := os.Executable()
		batchContent := fmt.Sprintf("@echo off\r\nstart \"\" \"%s\"\r\n", exePath)
		_ = os.WriteFile(shortcutPath, []byte(batchContent), 0644)
	} else {
		_ = os.Remove(shortcutPath)
	}
}

func showContextMenu() {
	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))

	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	defer procDestroyMenu.Call(hMenu)

	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	statusLabel := fmt.Sprintf("🎙️ Start Dictation [%s]", config.Hotkey)
	if rec {
		statusLabel = fmt.Sprintf("⏹️ Stop Recording [%s]", config.Hotkey)
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_TOGGLE_RECORD, uintptr(unsafe.Pointer(strPtr(statusLabel))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	// Languages Submenu
	hLangMenu, _, _ := procCreatePopupMenu.Call()
	for idx, lang := range config.AllLanguages {
		flags := uintptr(MF_STRING)
		for _, active := range config.ActiveLanguages {
			if active == lang.Code {
				flags |= MF_CHECKED
				break
			}
		}
		menuID := uintptr(IDM_LANG_BASE + idx)
		procAppendMenuW.Call(hLangMenu, flags, menuID, uintptr(unsafe.Pointer(strPtr(lang.Name+" ("+strings.ToUpper(lang.Code)+")"))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hLangMenu, uintptr(unsafe.Pointer(strPtr("🌐 Languages (Active)"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	// API Key Status Indicator
	keyLabel := "🔑 Groq API Key [✓ Configured]"
	if config.GroqAPIKey == "" && os.Getenv("GROQ_API_KEY") == "" {
		keyLabel = "⚠️ Groq API Key [Not Configured]"
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETUP_KEY, uintptr(unsafe.Pointer(strPtr(keyLabel))))

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DICT, uintptr(unsafe.Pointer(strPtr("📖 Open Dictionary (Notepad)"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_LINK_FOLDER, uintptr(unsafe.Pointer(strPtr("📂 Link AI Knowledge Folder..."))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_CONFIG, uintptr(unsafe.Pointer(strPtr("⚙️ Open Settings (GUI)"))))

	autostartFlags := uintptr(MF_STRING)
	if config.Autostart {
		autostartFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autostartFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr("🚀 Autostart with Windows"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_ICONS_PAGE, uintptr(unsafe.Pointer(strPtr("🎨 Choose Icon (20 Options Showcase)"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr("❓ Setup Guide & Help"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr("❌ Exit GIN-Voice"))))

	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
}

func showSettingsDialog() {
	if hwndSetup != 0 {
		procShowWindow.Call(hwndSetup, SW_SHOWNORMAL)
		procSetForegroundWindow.Call(hwndSetup)
		return
	}

	hIcon := loadAppIcon()

	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	screenHeight, _, _ := procGetSystemMetrics.Call(1)
	dlgWidth := int32(560)
	dlgHeight := int32(430)
	dlgX := (int32(screenWidth) - dlgWidth) / 2
	dlgY := (int32(screenHeight) - dlgHeight) / 2

	className := strPtr("GIN_VOICE_SETTINGS_CLASS")
	hInstance, _, _ := procGetModuleHandleW.Call(0)

	hwndSetup, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("⚙️ GIN-Voice [v002] — Settings & Personalization"))),
		WS_OVERLAPPEDWINDOW&^0x00040000 | WS_VISIBLE,
		uintptr(dlgX), uintptr(dlgY), uintptr(dlgWidth), uintptr(dlgHeight),
		0, 0, hInstance, 0,
	)

	// Set custom icon on dialog window title and taskbar
	procSendMessageW.Call(hwndSetup, WM_SETICON, ICON_SMALL, hIcon)
	procSendMessageW.Call(hwndSetup, WM_SETICON, ICON_BIG, hIcon)

	hFont, _, _ := procGetStockObject.Call(DEFAULT_GUI_FONT)

	// Section 1: Groq API Key
	lbl1, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("1. Groq API Key (Free, 0.3s transcription): Create key named 'gin-voice':"))),
		WS_CHILD|WS_VISIBLE,
		20, 15, 500, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl1, WM_SETFONT, hFont, 1)

	currKey := config.GroqAPIKey
	if currKey == "" {
		currKey = os.Getenv("GROQ_API_KEY")
	}
	hwndEditKey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(currKey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		20, 38, 360, 26, hwndSetup, uintptr(IDC_EDIT_KEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditKey, WM_SETFONT, hFont, 1)

	btnGroq, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🌐 Get Key ↗"))),
		WS_CHILD|WS_VISIBLE,
		390, 37, 130, 28, hwndSetup, uintptr(IDC_BTN_GROQ), hInstance, 0,
	)
	procSendMessageW.Call(btnGroq, WM_SETFONT, hFont, 1)

	// Section 2: Hotkey
	lbl2, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("2. Hotkey for Voice Typing (Default: F4; or F8, F9, F10, F12):"))),
		WS_CHILD|WS_VISIBLE,
		20, 80, 500, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl2, WM_SETFONT, hFont, 1)

	hwndEditHotkey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.Hotkey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		20, 102, 120, 26, hwndSetup, uintptr(IDC_EDIT_HOTKEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditHotkey, WM_SETFONT, hFont, 1)

	// Section 3: AI Knowledge Folder Link
	lbl3, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("3. Common AI Knowledge Folder (D:\\AI, Secret_Privat, etc.):"))),
		WS_CHILD|WS_VISIBLE,
		20, 145, 500, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl3, WM_SETFONT, hFont, 1)

	hwndEditFolder, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.LinkedKnowledgeFolder))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		20, 168, 360, 26, hwndSetup, uintptr(IDC_EDIT_FOLDER), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditFolder, WM_SETFONT, hFont, 1)

	btnBrowse, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📁 Browse..."))),
		WS_CHILD|WS_VISIBLE,
		390, 167, 130, 28, hwndSetup, uintptr(IDC_BTN_BROWSE), hInstance, 0,
	)
	procSendMessageW.Call(btnBrowse, WM_SETFONT, hFont, 1)

	// Section 4: Active Languages
	lbl4, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("4. Active Languages (Code-Switching Support):"))),
		WS_CHILD|WS_VISIBLE,
		20, 212, 500, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl4, WM_SETFONT, hFont, 1)

	isEN := hasLang("en")
	isCS := hasLang("cs")
	isRU := hasLang("ru")

	hwndChkEN, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("English (EN)"))),
		WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
		20, 235, 140, 24, hwndSetup, uintptr(IDC_CHK_EN), hInstance, 0,
	)
	procSendMessageW.Call(hwndChkEN, WM_SETFONT, hFont, 1)
	if isEN {
		procSendMessageW.Call(hwndChkEN, 0x00F1, 1, 0) // BM_SETCHECK
	}

	hwndChkCS, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Czech (CS)"))),
		WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
		180, 235, 140, 24, hwndSetup, uintptr(IDC_CHK_CS), hInstance, 0,
	)
	procSendMessageW.Call(hwndChkCS, WM_SETFONT, hFont, 1)
	if isCS {
		procSendMessageW.Call(hwndChkCS, 0x00F1, 1, 0)
	}

	hwndChkRU, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Russian (RU)"))),
		WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
		340, 235, 140, 24, hwndSetup, uintptr(IDC_CHK_RU), hInstance, 0,
	)
	procSendMessageW.Call(hwndChkRU, WM_SETFONT, hFont, 1)
	if isRU {
		procSendMessageW.Call(hwndChkRU, 0x00F1, 1, 0)
	}

	// Action Buttons
	btnSave, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("💾 Save & Apply Settings"))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		20, 290, 240, 38, hwndSetup, uintptr(IDC_BTN_SAVE), hInstance, 0,
	)
	procSendMessageW.Call(btnSave, WM_SETFONT, hFont, 1)

	btnDict, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📖 Edit Dictionary (Notepad)"))),
		WS_CHILD|WS_VISIBLE,
		280, 290, 240, 38, hwndSetup, uintptr(IDC_BTN_DICT), hInstance, 0,
	)
	procSendMessageW.Call(btnDict, WM_SETFONT, hFont, 1)

	lblTip, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Tip: When done, click Save. GIN-Voice will run quietly in the tray near the clock."))),
		WS_CHILD|WS_VISIBLE,
		20, 345, 500, 30, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblTip, WM_SETFONT, hFont, 1)

	procSetForegroundWindow.Call(hwndSetup)
}

func hasLang(code string) bool {
	for _, l := range config.ActiveLanguages {
		if l == code {
			return true
		}
	}
	return false
}

func parseVK(keyStr string) uint32 {
	u := strings.ToUpper(strings.TrimSpace(keyStr))
	switch u {
	case "F4":
		return VK_F4
	case "F8":
		return VK_F8
	case "F9":
		return VK_F9
	case "F10":
		return VK_F10
	case "F12":
		return VK_F12
	default:
		return VK_F4
	}
}

func handleMenuCommand(cmdID uintptr) {
	switch {
	case cmdID == IDM_TOGGLE_RECORD:
		toggleRecording()
	case cmdID == IDM_SETUP_KEY || cmdID == IDM_OPEN_CONFIG:
		showSettingsDialog()
	case cmdID >= IDM_LANG_BASE && cmdID < IDM_LANG_BASE+uintptr(len(config.AllLanguages)):
		idx := int(cmdID - IDM_LANG_BASE)
		if idx >= 0 && idx < len(config.AllLanguages) {
			code := config.AllLanguages[idx].Code
			found := false
			var updated []string
			for _, c := range config.ActiveLanguages {
				if c == code {
					found = true
				} else {
					updated = append(updated, c)
				}
			}
			if !found {
				updated = append(updated, code)
			}
			if len(updated) == 0 {
				updated = []string{"en"}
			}
			config.ActiveLanguages = updated
			saveConfig()
		}
	case cmdID == IDM_OPEN_DICT:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
	case cmdID == IDM_LINK_FOLDER:
		go func() {
			folder := pickFolderDialog()
			if folder != "" {
				count := linkKnowledgeFolder(folder)
				config.LinkedKnowledgeFolder = folder
				saveConfig()
				msg := fmt.Sprintf("Успешно привязано!\nПапка: %s\nДобавлено новых проектов в словарь: %d", folder, count)
				procMessageBoxW.Call(
					0,
					uintptr(unsafe.Pointer(strPtr(msg))),
					uintptr(unsafe.Pointer(strPtr(AppTitle+" - Папка привязана"))),
					0x00000040,
				)
			}
		}()
	case cmdID == IDM_AUTOSTART:
		toggleAutostart()
	case cmdID == IDM_ICONS_PAGE:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(iconsFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_OPEN_HELP:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(helpFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_EXIT:
		if hKeyboardHook != 0 {
			procUnhookWindowsHookEx.Call(hKeyboardHook)
		}
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
	}
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_HOTKEY:
		toggleRecording()
		return 0
	case WM_TRAYICON:
		if lParam == WM_RBUTTONUP {
			showContextMenu()
		} else if lParam == WM_LBUTTONDBLCLK {
			toggleRecording()
		}
		return 0
	case WM_COMMAND:
		handleMenuCommand(wParam)
		return 0
	case WM_DESTROY:
		if hKeyboardHook != 0 {
			procUnhookWindowsHookEx.Call(hKeyboardHook)
		}
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
		return 0
	default:
		r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
		return r
	}
}

func setupWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		cmdID := wParam & 0xFFFF
		if cmdID == IDC_BTN_SAVE {
			// Read Key
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			config.GroqAPIKey = strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))

			// Read Hotkey
			var bufHotkey [64]uint16
			procGetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(&bufHotkey[0])), 64)
			newHotkey := strings.TrimSpace(syscall.UTF16ToString(bufHotkey[:]))
			if newHotkey != "" {
				config.Hotkey = newHotkey
				config.HotkeyVK = parseVK(newHotkey)
			}

			// Read Folder
			var bufFolder [1024]uint16
			procGetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(&bufFolder[0])), 1024)
			config.LinkedKnowledgeFolder = strings.TrimSpace(syscall.UTF16ToString(bufFolder[:]))

			// Read Languages
			var langs []string
			if r, _, _ := procSendMessageW.Call(hwndChkEN, 0x00F0, 0, 0); r == 1 { // BM_GETCHECK
				langs = append(langs, "en")
			}
			if r, _, _ := procSendMessageW.Call(hwndChkCS, 0x00F0, 0, 0); r == 1 {
				langs = append(langs, "cs")
			}
			if r, _, _ := procSendMessageW.Call(hwndChkRU, 0x00F0, 0, 0); r == 1 {
				langs = append(langs, "ru")
			}
			if len(langs) == 0 {
				langs = []string{"en"}
			}
			config.ActiveLanguages = langs

			saveConfig()
			playBeep(880, 150)
			procShowWindow.Call(hwnd, SW_HIDE)
			initTrayIcon()
			updateTrayTip(AppTitle + " | Ready (Press " + config.Hotkey + " to dictate)")

			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("GIN-Voice настройки успешно сохранены!\nГорячая клавиша: [%s]\nЯзыки: %s", config.Hotkey, strings.Join(config.ActiveLanguages, ", "))))),
				uintptr(unsafe.Pointer(strPtr(AppTitle+" - Готово"))),
				0x00000040,
			)
			return 0
		} else if cmdID == IDC_BTN_GROQ {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(GroqKeysURL))), 0, 0, SW_SHOWNORMAL)
			return 0
		} else if cmdID == IDC_BTN_BROWSE {
			go func() {
				folder := pickFolderDialog()
				if folder != "" {
					procSetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(strPtr(folder))))
				}
			}()
			return 0
		} else if cmdID == IDC_BTN_DICT {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
			return 0
		}
	case WM_CLOSE:
		procShowWindow.Call(hwnd, SW_HIDE)
		initTrayIcon()
		return 0
	}
	r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return r
}

func keyboardHookCallback(nCode int32, wParam uintptr, lParam uintptr) uintptr {
	if nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
		kbd := (*KBDLLHOOKSTRUCT)(unsafe.Pointer(lParam))
		if kbd.VkCode == config.HotkeyVK {
			go toggleRecording()
			return 1 // Suppress standard key action to avoid app conflicts
		}
	}
	r, _, _ := procCallNextHookEx.Call(hKeyboardHook, uintptr(nCode), wParam, lParam)
	return r
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}

func createShortcuts(exePath, targetDir string) {
	icoPath := filepath.Join(targetDir, "app.ico")
	psCmd := fmt.Sprintf(`
$w = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$s1 = $w.CreateShortcut("$desktop\GIN-Voice.lnk")
$s1.TargetPath = '%s'
$s1.WorkingDirectory = '%s'
$s1.IconLocation = '%s,0'
$s1.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s1.Save()

$startMenu = [Environment]::GetFolderPath('Programs')
$s2 = $w.CreateShortcut("$startMenu\GIN-Voice.lnk")
$s2.TargetPath = '%s'
$s2.WorkingDirectory = '%s'
$s2.IconLocation = '%s,0'
$s2.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s2.Save()

if (Test-Path 'D:\MEGA\DOCS\desktop') {
    $s3 = $w.CreateShortcut("D:\MEGA\DOCS\desktop\GIN-Voice.lnk")
    $s3.TargetPath = '%s'
    $s3.WorkingDirectory = '%s'
    $s3.IconLocation = '%s,0'
    $s3.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
    $s3.Save()
}
`, exePath, targetDir, icoPath, exePath, targetDir, icoPath, exePath, targetDir, icoPath)

	_ = exec.Command("powershell", "-NoProfile", "-WindowStyle", "Hidden", "-Command", psCmd).Run()
}

func checkAndSelfInstall() {
	currExe, err := os.Executable()
	if err != nil {
		return
	}

	localAppData := os.Getenv("LOCALAPPDATA")
	if localAppData == "" {
		localAppData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local")
	}
	targetDir := filepath.Join(localAppData, "GIN-Voice")
	targetExe := filepath.Join(targetDir, "GIN-Voice.exe")

	if strings.EqualFold(filepath.Dir(currExe), targetDir) {
		return
	}

	_ = os.MkdirAll(targetDir, 0755)

	_ = copyFile(currExe, targetExe)
	_ = copyFile(currExe, filepath.Join(targetDir, "GIN-Voice_v002.exe"))

	// Copy or deploy app.ico
	srcIco := filepath.Join(filepath.Dir(currExe), "app.ico")
	dstIco := filepath.Join(targetDir, "app.ico")
	if _, err := os.Stat(srcIco); err == nil {
		_ = copyFile(srcIco, dstIco)
	}

	dictDest := filepath.Join(targetDir, "dictionary.json")
	if _, err := os.Stat(dictDest); os.IsNotExist(err) && len(defaultDictionaryJSON) > 0 {
		_ = os.WriteFile(dictDest, defaultDictionaryJSON, 0644)
	}

	guideDest := filepath.Join(targetDir, "setup_guide.html")
	if len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(guideDest, defaultSetupGuideHTML, 0644)
	}

	iconsDest := filepath.Join(targetDir, "icons_showcase.html")
	if len(defaultIconsShowcaseHTML) > 0 {
		_ = os.WriteFile(iconsDest, defaultIconsShowcaseHTML, 0644)
	}

	createShortcuts(targetExe, targetDir)

	procShellExecuteW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("open"))),
		uintptr(unsafe.Pointer(strPtr(targetExe))),
		0,
		uintptr(unsafe.Pointer(strPtr(targetDir))),
		SW_SHOWNORMAL,
	)
	os.Exit(0)
}

func main() {
	flag.Parse()

	checkAndSelfInstall()

	exePath, _ := os.Executable()
	appDir = filepath.Dir(exePath)
	configFile = filepath.Join(appDir, "config.json")
	dictFile = filepath.Join(appDir, "dictionary.json")
	helpFile = filepath.Join(appDir, "setup_guide.html")
	iconsFile = filepath.Join(appDir, "icons_showcase.html")
	logFile = filepath.Join(appDir, "gin_voice.log")

	writeLog("=== GIN-Voice [v002] Starting ===")

	if _, err := os.Stat(helpFile); os.IsNotExist(err) && len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(helpFile, defaultSetupGuideHTML, 0644)
	}
	if _, err := os.Stat(iconsFile); os.IsNotExist(err) && len(defaultIconsShowcaseHTML) > 0 {
		_ = os.WriteFile(iconsFile, defaultIconsShowcaseHTML, 0644)
	}

	loadConfig()
	loadDictionary()

	hInstance, _, _ := procGetModuleHandleW.Call(0)
	hIcon := loadAppIcon()

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIcon
	wc.LpszClassName = strPtr("GIN_VOICE_WINDOW_CLASS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var sc WNDCLASSEXW
	sc.CbSize = uint32(unsafe.Sizeof(sc))
	sc.LpfnWndProc = syscall.NewCallback(setupWndProc)
	sc.HInstance = hInstance
	sc.HIcon = hIcon
	sc.HbrBackground = uintptr(COLOR_WINDOW + 1)
	sc.LpszClassName = strPtr("GIN_VOICE_SETTINGS_CLASS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&sc)))

	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_VOICE_WINDOW_CLASS"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		0, 0, 0, 0, 0,
		0, 0, hInstance, 0,
	)

	// Install Global Low-Level Keyboard Hook
	hookProc := syscall.NewCallback(keyboardHookCallback)
	r, _, _ := procSetWindowsHookExW.Call(
		WH_KEYBOARD_LL,
		hookProc,
		hInstance,
		0,
	)
	hKeyboardHook = r
	if hKeyboardHook == 0 {
		writeLog("Warning: Failed to install WH_KEYBOARD_LL hook!")
	} else {
		writeLog(fmt.Sprintf("Installed WH_KEYBOARD_LL hook for key [%s] (VK %d)", config.Hotkey, config.HotkeyVK))
	}

	apiKey := config.GroqAPIKey
	if apiKey == "" {
		apiKey = os.Getenv("GROQ_API_KEY")
	}

	if apiKey == "" || config.FirstRun {
		config.FirstRun = false
		saveConfig()
		showSettingsDialog()
	} else {
		initTrayIcon()
	}

	var msg MSG
	for {
		r, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if int32(r) <= 0 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}

	if hKeyboardHook != 0 {
		procUnhookWindowsHookEx.Call(hKeyboardHook)
	}
}

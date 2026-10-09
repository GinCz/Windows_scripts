// Execution Context : Go 1.19+ (Windows AMD64)
// Target Server     : Local Windows Desktop PC
// Description       : GIN-Voice Native Windows Tray Client with Whisper AI and Win32 MCI

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
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
	AppVersion    = "v001"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v001]"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice"

	// Win32 Constants
	WM_USER         = 0x0400
	WM_TRAYICON     = WM_USER + 1
	WM_COMMAND      = 0x0111
	WM_HOTKEY       = 0x0312
	WM_DESTROY      = 0x0002
	WM_RBUTTONUP    = 0x0205
	WM_LBUTTONDBLCLK = 0x0203

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
	MF_GRAYED    = 0x00000001

	TPM_RIGHTBUTTON = 0x0002

	VK_F4      = 0x73
	VK_CONTROL = 0x11
	KEYEVENTF_KEYUP = 0x0002

	CF_UNICODETEXT = 13
	GMEM_MOVEABLE  = 0x0002

	SW_SHOWNORMAL = 1
	HOTKEY_ID     = 101

	// Menu Command IDs
	IDM_TOGGLE_RECORD = 1001
	IDM_OPEN_DICT     = 1002
	IDM_LINK_FOLDER   = 1003
	IDM_OPEN_CONFIG   = 1004
	IDM_AUTOSTART     = 1005
	IDM_OPEN_HELP     = 1006
	IDM_EXIT          = 1007

	IDM_LANG_BASE = 2000
)

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procRegisterClassExW      = user32.NewProc("RegisterClassExW")
	procCreateWindowExW       = user32.NewProc("CreateWindowExW")
	procDefWindowProcW        = user32.NewProc("DefWindowProcW")
	procDestroyWindow         = user32.NewProc("DestroyWindow")
	procPostQuitMessage       = user32.NewProc("PostQuitMessage")
	procGetMessageW           = user32.NewProc("GetMessageW")
	procTranslateMessage      = user32.NewProc("TranslateMessage")
	procDispatchMessageW      = user32.NewProc("DispatchMessageW")
	procRegisterHotKey        = user32.NewProc("RegisterHotKey")
	procUnregisterHotKey      = user32.NewProc("UnregisterHotKey")
	procCreatePopupMenu       = user32.NewProc("CreatePopupMenu")
	procAppendMenuW           = user32.NewProc("AppendMenuW")
	procTrackPopupMenu        = user32.NewProc("TrackPopupMenu")
	procDestroyMenu           = user32.NewProc("DestroyMenu")
	procSetForegroundWindow   = user32.NewProc("SetForegroundWindow")
	procGetCursorPos          = user32.NewProc("GetCursorPos")
	procOpenClipboard         = user32.NewProc("OpenClipboard")
	procCloseClipboard        = user32.NewProc("CloseClipboard")
	procEmptyClipboard        = user32.NewProc("EmptyClipboard")
	procSetClipboardData      = user32.NewProc("SetClipboardData")
	procGetClipboardData      = user32.NewProc("GetClipboardData")
	procIsClipboardAvailable  = user32.NewProc("IsClipboardFormatAvailable")
	procKeybdEvent            = user32.NewProc("keybd_event")
	procMessageBoxW           = user32.NewProc("MessageBoxW")
	procLoadIconW             = user32.NewProc("LoadIconW")

	procShellNotifyIconW = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW    = shell32.NewProc("ShellExecuteW")

	procBeep         = kernel32.NewProc("Beep")
	procGlobalAlloc  = kernel32.NewProc("GlobalAlloc")
	procGlobalLock   = kernel32.NewProc("GlobalLock")
	procGlobalUnlock = kernel32.NewProc("GlobalUnlock")
	procGlobalFree   = kernel32.NewProc("GlobalFree")
	procGetModuleHandleW = kernel32.NewProc("GetModuleHandleW")

	procMciSendStringW = winmm.NewProc("mciSendStringW")
)

type POINT struct {
	X int32
	Y int32
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
	Version                string         `json:"version"`
	FirstRun               bool           `json:"first_run"`
	Hotkey                 string         `json:"hotkey"`
	HotkeyVK               uint32         `json:"hotkey_vk"`
	HotkeyMod              uint32         `json:"hotkey_mod"`
	ActiveLanguages        []string       `json:"active_languages"`
	AllLanguages           []LanguageItem `json:"all_languages"`
	GroqAPIKey             string         `json:"groq_api_key"`
	SoundFeedback          bool           `json:"sound_feedback"`
	AutoPaste              bool           `json:"auto_paste"`
	RestoreClipboard       bool           `json:"restore_clipboard"`
	Autostart              bool           `json:"autostart"`
	LinkedKnowledgeFolder  string         `json:"linked_knowledge_folder"`
}

var (
	appDir          string
	configFile      string
	dictFile        string
	helpFile        string
	config          Config
	dictionary      map[string]string
	dictMutex       sync.RWMutex
	hwndMain        uintptr
	nid             NOTIFYICONDATAW
	isRecording     bool
	recordMutex     sync.Mutex
	isTranscribing  bool
)

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
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
		return fmt.Errorf("MCI error code: %d", ret)
	}
	return nil
}

func updateTrayTip(text string) {
	var tip [128]uint16
	chars := []rune(text)
	for i := 0; i < len(chars) && i < 127; i++ {
		tip[i] = uint16(chars[i])
	}
	nid.SzTip = tip
	procShellNotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
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
		dictionary = map[string]string{
			"джин синема":             "GinCinema",
			"гин синема":              "GinCinema",
			"джин тв":                 "GinTV",
			"гин тв":                  "GinTV",
			"джин нетскан":            "GinNetScan",
			"гин нетскан":             "GinNetScan",
			"джин впн":                "GIN-VPN",
			"гин впн":                 "GIN-VPN",
			"джин чат":                "GIN-Chat",
			"гин чат":                 "GIN-Chat",
			"джин воис":               "GIN-Voice",
			"гин воис":                "GIN-Voice",
			"секрет приват":           "Secret_Privat",
			"оракл сто пятьдесят семь": "ORACLE_157",
			"оракл 157":               "ORACLE_157",
			"сервер 222":              "Server_222",
			"антигравити":             "Antigravity",
			"пунто свитчер":           "Punto Switcher",
			"пунто":                   "Punto Switcher",
			"гитхаб":                  "GitHub",
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
		playBeep(250, 200)
		return
	}

	_ = mciSend("set ginmic time format ms bitspersample 16 channels 1 samplespersec 16000")
	err = mciSend("record ginmic")
	if err != nil {
		playBeep(250, 200)
		return
	}

	isRecording = true
	playBeep(880, 100) // High beep
	updateTrayTip(AppTitle + " | 🎙️ Recording... (Press F4 to Stop)")
}

func stopRecordingAndTranscribe() {
	recordMutex.Lock()
	if !isRecording {
		recordMutex.Unlock()
		return
	}
	isRecording = false
	recordMutex.Unlock()

	playBeep(440, 100) // Low beep
	updateTrayTip(AppTitle + " | ⚡ Transcribing...")

	wavPath := getTempWavPath()
	_ = mciSend("stop ginmic")
	_ = mciSend(fmt.Sprintf("save ginmic \"%s\"", wavPath))
	_ = mciSend("close ginmic")

	go func() {
		defer os.Remove(wavPath)
		defer updateTrayTip(AppTitle + " | Ready (Press F4 to dictate)")

		text, err := transcribeAudio(wavPath)
		if err != nil {
			playBeep(220, 300)
			return
		}

		text = strings.TrimSpace(text)
		if text == "" {
			return
		}

		text = applyDictionary(text)
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
		procMessageBoxW.Call(
			0,
			uintptr(unsafe.Pointer(strPtr("Groq API Key is not set!\nPlease open config.json from tray menu and set groq_api_key.\nGet free key at: https://console.groq.com/keys"))),
			uintptr(unsafe.Pointer(strPtr(AppTitle+" - Configuration Required"))),
			0x00000030, // MB_ICONWARNING
		)
		return "", fmt.Errorf("missing api key")
	}

	audioData, err := os.ReadFile(wavPath)
	if err != nil || len(audioData) < 1000 {
		return "", fmt.Errorf("empty or invalid audio recording")
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

	// Language handling
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

	// Status / Action
	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	statusLabel := "🎙️ Start Dictation [F4]"
	if rec {
		statusLabel = "⏹️ Stop Recording [F4]"
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

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DICT, uintptr(unsafe.Pointer(strPtr("📖 Open Dictionary (dictionary.json)"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_LINK_FOLDER, uintptr(unsafe.Pointer(strPtr("📂 Link AI Knowledge Folder..."))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_CONFIG, uintptr(unsafe.Pointer(strPtr("⚙️ Open Settings (config.json)"))))

	autostartFlags := uintptr(MF_STRING)
	if config.Autostart {
		autostartFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autostartFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr("🚀 Autostart with Windows"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr("❓ Help & Guide (HELP.md)"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr("❌ Exit GIN-Voice"))))

	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
}

func handleMenuCommand(cmdID uintptr) {
	switch {
	case cmdID == IDM_TOGGLE_RECORD:
		toggleRecording()
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
				updated = []string{"en"} // Fallback to english
			}
			config.ActiveLanguages = updated
			saveConfig()
		}
	case cmdID == IDM_OPEN_DICT:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_LINK_FOLDER:
		go func() {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(configFile))), 0, SW_SHOWNORMAL)
		}()
	case cmdID == IDM_OPEN_CONFIG:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(configFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_AUTOSTART:
		toggleAutostart()
	case cmdID == IDM_OPEN_HELP:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(helpFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_EXIT:
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
	}
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_HOTKEY:
		if wParam == HOTKEY_ID {
			toggleRecording()
		}
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
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
		return 0
	default:
		r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
		return r
	}
}

func main() {
	linkFlag := flag.String("link-folder", "", "Link and scan AI knowledge folder for project names")
	flag.Parse()

	exePath, _ := os.Executable()
	appDir = filepath.Dir(exePath)
	configFile = filepath.Join(appDir, "config.json")
	dictFile = filepath.Join(appDir, "dictionary.json")
	helpFile = filepath.Join(appDir, "HELP.md")

	loadConfig()
	loadDictionary()

	if *linkFlag != "" {
		count := linkKnowledgeFolder(*linkFlag)
		fmt.Printf("Successfully linked folder and added %d project entities.\n", count)
		return
	}

	// First Run Handler: display help
	if config.FirstRun {
		config.FirstRun = false
		saveConfig()
		if _, err := os.Stat(helpFile); err == nil {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(helpFile))), 0, 0, SW_SHOWNORMAL)
		}
	}

	// Register Window Class
	className := strPtr("GIN_VOICE_WINDOW_CLASS")
	hInstance, _, _ := procGetModuleHandleW.Call(0)

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	// Create Message Window
	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		0, 0, 0, 0, 0,
		0, 0, hInstance, 0,
	)

	// Register Hotkey (VK_F4 default)
	procRegisterHotKey.Call(hwndMain, HOTKEY_ID, uintptr(config.HotkeyMod), uintptr(config.HotkeyVK))

	// Setup Tray Icon
	hIcon, _, _ := procLoadIconW.Call(hInstance, uintptr(1))
	if hIcon == 0 {
		hIcon, _, _ = procLoadIconW.Call(0, uintptr(32516)) // IDI_INFORMATION fallback
	}

	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.HWnd = hwndMain
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIcon
	updateTrayTip(AppTitle + " | Ready (Press F4 to dictate)")
	procShellNotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))

	// Message Loop
	var msg MSG
	for {
		r, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if int32(r) <= 0 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}

	procUnregisterHotKey.Call(hwndMain, HOTKEY_ID)
}

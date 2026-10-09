// Execution Context : Go 1.19+ (Windows AMD64)
// Target Server     : Local Windows Desktop PC
// Description       : GIN-Voice Native Windows Client & Installer with Whisper AI, WaveIn Engine, Cyber Dark GUI [v005]

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
	AppVersion    = "v005"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v005]"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice"
	GroqKeysURL   = "https://console.groq.com/keys"

	// Default key empty (loaded from api_key.txt or config.json)
	DefaultGroqKey = ""

	// Win32 Constants
	WM_USER          = 0x0400
	WM_TRAYICON      = WM_USER + 1
	WM_COMMAND       = 0x0111
	WM_DESTROY       = 0x0002
	WM_CLOSE         = 0x0010
	WM_SETFONT       = 0x0030
	WM_SETICON       = 0x0080
	WM_RBUTTONUP     = 0x0205
	WM_LBUTTONDBLCLK = 0x0203
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CTLCOLORBTN    = 0x0135

	// WaveIn Messages
	MM_WIM_OPEN  = 0x03BE
	MM_WIM_CLOSE = 0x03BF
	MM_WIM_DATA  = 0x03C0

	CALLBACK_WINDOW = 0x00010000
	WAVE_MAPPER     = 0xFFFFFFFF
	WAVE_FORMAT_PCM = 1
	WHDR_DONE       = 0x00000001

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

	BIF_RETURNONLYFSDIRS = 0x0001
	BIF_NEWDIALOGSTYLE   = 0x0040

	// Menu Command IDs
	IDM_TOGGLE_RECORD = 1001
	IDM_SETUP_KEY     = 1002
	IDM_OPEN_DICT     = 1003
	IDM_LINK_FOLDER   = 1004
	IDM_OPEN_CONFIG   = 1005
	IDM_OPEN_DIR      = 1006
	IDM_AUTOSTART     = 1007
	IDM_OPEN_HELP     = 1008
	IDM_UNINSTALL     = 1009
	IDM_EXIT          = 1010

	IDM_LANG_BASE = 2000

	// Settings Dialog IDs
	IDC_BTN_SAVE       = 3001
	IDC_BTN_GROQ       = 3002
	IDC_EDIT_KEY       = 3003
	IDC_EDIT_FOLDER    = 3004
	IDC_BTN_BROWSE     = 3005
	IDC_EDIT_HOTKEY    = 3006
	IDC_BTN_DICT       = 3007
	IDC_BTN_TEST       = 3008
	IDC_BTN_UNINST     = 3009
	IDC_BTN_COPY_KEY   = 3010
	IDC_BTN_OPEN_DIR   = 3011

	IDC_LANG_CHK_BASE  = 4000
)

//go:embed app.ico
var defaultAppIco []byte

//go:embed app_rec.ico
var defaultAppRecIco []byte

//go:embed dictionary.json
var defaultDictionaryJSON []byte

//go:embed setup_guide.html
var defaultSetupGuideHTML []byte

//go:embed uninstall.bat
var defaultUninstallBAT []byte

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")
	ole32    = syscall.NewLazyDLL("ole32.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procRegisterClassExW    = user32.NewProc("RegisterClassExW")
	procCreateWindowExW     = user32.NewProc("CreateWindowExW")
	procDefWindowProcW      = user32.NewProc("DefWindowProcW")
	procDestroyWindow       = user32.NewProc("DestroyWindow")
	procPostQuitMessage     = user32.NewProc("PostQuitMessage")
	procGetMessageW         = user32.NewProc("GetMessageW")
	procTranslateMessage    = user32.NewProc("TranslateMessage")
	procDispatchMessageW    = user32.NewProc("DispatchMessageW")
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
	procGetAsyncKeyState      = user32.NewProc("GetAsyncKeyState")

	procShellNotifyIconW     = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW        = shell32.NewProc("ShellExecuteW")
	procSHBrowseForFolderW   = shell32.NewProc("SHBrowseForFolderW")
	procSHGetPathFromIDListW = shell32.NewProc("SHGetPathFromIDListW")
	procCoTaskMemFree        = ole32.NewProc("CoTaskMemFree")

	procBeep             = kernel32.NewProc("Beep")
	procGlobalAlloc      = kernel32.NewProc("GlobalAlloc")
	procGlobalLock       = kernel32.NewProc("GlobalLock")
	procGlobalUnlock     = kernel32.NewProc("GlobalUnlock")
	procGlobalFree       = kernel32.NewProc("GlobalFree")
	procGetModuleHandleW = kernel32.NewProc("GetModuleHandleW")

	procGetStockObject   = gdi32.NewProc("GetStockObject")
	procCreateSolidBrush = gdi32.NewProc("CreateSolidBrush")
	procSetTextColor     = gdi32.NewProc("SetTextColor")
	procSetBkColor       = gdi32.NewProc("SetBkColor")

	// WaveIn Direct Audio Capture
	procWaveInOpen            = winmm.NewProc("waveInOpen")
	procWaveInPrepareHeader   = winmm.NewProc("waveInPrepareHeader")
	procWaveInUnprepareHeader = winmm.NewProc("waveInUnprepareHeader")
	procWaveInAddBuffer       = winmm.NewProc("waveInAddBuffer")
	procWaveInStart           = winmm.NewProc("waveInStart")
	procWaveInStop            = winmm.NewProc("waveInStop")
	procWaveInReset           = winmm.NewProc("waveInReset")
	procWaveInClose           = winmm.NewProc("waveInClose")
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

type BROWSEINFOW struct {
	HwndOwner      uintptr
	PidlRoot       uintptr
	PszDisplayName *uint16
	LpszTitle      *uint16
	UlFlags        uint32
	Lpfn           uintptr
	LParam         uintptr
	IIcon          int32
}

type WAVEFORMATEX struct {
	WFormatTag      uint16
	NChannels       uint16
	NSamplesPerSec  uint32
	NAvgBytesPerSec uint32
	NBlockAlign     uint16
	WBitsPerSample  uint16
	CbSize          uint16
}

type WAVEHDR struct {
	LpData          uintptr
	DwBufferLength  uint32
	DwBytesRecorded uint32
	DwUser          uintptr
	DwFlags         uint32
	DwLoops         uint32
	LpNext          uintptr
	Reserved        uintptr
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
	keyFile         string
	dictFile        string
	helpFile        string
	logFile         string
	config          Config
	dictionary      map[string]string
	dictMutex       sync.RWMutex
	hwndMain        uintptr
	hwndSetup       uintptr
	hwndEditKey     uintptr
	hwndEditFolder  uintptr
	hwndEditHotkey  uintptr
	langCheckHWnd   = make(map[string]uintptr)
	nid             NOTIFYICONDATAW
	isRecording     bool
	recordMutex     sync.Mutex
	trayCreated     bool
	hIconNormal     uintptr
	hIconRec        uintptr

	// Dark Theme Brushes
	hBrushDarkBg uintptr
	hBrushCardBg uintptr
	hBrushEditBg uintptr

	// Direct WaveIn Audio Engine
	hWaveIn       uintptr
	waveBuffers   [4][]byte
	waveHeaders   [4]WAVEHDR
	capturedAudio []byte
	audioMutex    sync.Mutex
)

// List of 40 languages in 4 columns
var MasterLanguages = []LanguageItem{
	// Column 1
	{Code: "EN", Name: "English"},
	{Code: "CS", Name: "Czech"},
	{Code: "RU", Name: "Russian"},
	{Code: "DE", Name: "German"},
	{Code: "FR", Name: "French"},
	{Code: "ES", Name: "Spanish"},
	{Code: "IT", Name: "Italian"},
	{Code: "PT", Name: "Portuguese"},
	{Code: "NL", Name: "Dutch"},
	{Code: "PL", Name: "Polish"},
	// Column 2
	{Code: "UK", Name: "Ukrainian"},
	{Code: "SV", Name: "Swedish"},
	{Code: "DA", Name: "Danish"},
	{Code: "FI", Name: "Finnish"},
	{Code: "NO", Name: "Norwegian"},
	{Code: "TR", Name: "Turkish"},
	{Code: "EL", Name: "Greek"},
	{Code: "RO", Name: "Romanian"},
	{Code: "HU", Name: "Hungarian"},
	{Code: "SK", Name: "Slovak"},
	// Column 3
	{Code: "BG", Name: "Bulgarian"},
	{Code: "HR", Name: "Croatian"},
	{Code: "SR", Name: "Serbian"},
	{Code: "SL", Name: "Slovenian"},
	{Code: "ET", Name: "Estonian"},
	{Code: "LV", Name: "Latvian"},
	{Code: "LT", Name: "Lithuanian"},
	{Code: "JA", Name: "Japanese"},
	{Code: "ZH", Name: "Chinese"},
	{Code: "KO", Name: "Korean"},
	// Column 4
	{Code: "AR", Name: "Arabic"},
	{Code: "HE", Name: "Hebrew"},
	{Code: "HI", Name: "Hindi"},
	{Code: "VI", Name: "Vietnamese"},
	{Code: "TH", Name: "Thai"},
	{Code: "ID", Name: "Indonesian"},
	{Code: "MS", Name: "Malay"},
	{Code: "CA", Name: "Catalan"},
	{Code: "KA", Name: "Georgian"},
	{Code: "HY", Name: "Armenian"},
}

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

func loadIconFromFile(fileName string, defaultBytes []byte) uintptr {
	targetPath := filepath.Join(appDir, fileName)
	if _, err := os.Stat(targetPath); os.IsNotExist(err) && len(defaultBytes) > 0 {
		_ = os.WriteFile(targetPath, defaultBytes, 0644)
	}

	if _, err := os.Stat(targetPath); err == nil {
		h, _, _ := procLoadImageW.Call(
			0,
			uintptr(unsafe.Pointer(strPtr(targetPath))),
			IMAGE_ICON,
			0, 0,
			LR_LOADFROMFILE|LR_DEFAULTSIZE,
		)
		if h != 0 {
			return h
		}
	}
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	h, _, _ := procLoadIconW.Call(hInstance, uintptr(1))
	if h != 0 {
		return h
	}
	h, _, _ = procLoadIconW.Call(0, uintptr(32512))
	return h
}

func loadIcons() {
	hIconNormal = loadIconFromFile("app.ico", defaultAppIco)
	hIconRec = loadIconFromFile("app_rec.ico", defaultAppRecIco)
}

func playBeep(freq, duration uint32) {
	if config.SoundFeedback {
		go func() {
			procBeep.Call(uintptr(freq), uintptr(duration))
		}()
	}
}

func updateTrayState(recording bool, tipText string) {
	if !trayCreated {
		return
	}
	if recording {
		nid.HIcon = hIconRec
	} else {
		nid.HIcon = hIconNormal
	}

	var tip [128]uint16
	chars := []rune(tipText)
	for i := 0; i < len(chars) && i < 127; i++ {
		tip[i] = uint16(chars[i])
	}
	nid.SzTip = tip
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	procShellNotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
}

func initTrayIcon() {
	if trayCreated {
		return
	}
	if hIconNormal == 0 {
		loadIcons()
	}

	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.HWnd = hwndMain
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconNormal

	var tip [128]uint16
	initTip := []rune(AppTitle + " | Ready (" + config.Hotkey + ")")
	for i := 0; i < len(initTip) && i < 127; i++ {
		tip[i] = uint16(initTip[i])
	}
	nid.SzTip = tip

	procShellNotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))
	trayCreated = true
}

func loadConfig() {
	config = Config{
		Version:          AppVersion,
		FirstRun:         false,
		Hotkey:           "F8",
		HotkeyVK:         VK_F8,
		HotkeyMod:        0,
		ActiveLanguages:  []string{"EN"},
		AllLanguages:     MasterLanguages,
		GroqAPIKey:       DefaultGroqKey,
		SoundFeedback:    true,
		AutoPaste:        true,
		RestoreClipboard: true,
		Autostart:        false,
	}

	data, err := os.ReadFile(configFile)
	if err == nil {
		_ = json.Unmarshal(data, &config)
	}

	if config.GroqAPIKey == "" {
		if kData, kErr := os.ReadFile(keyFile); kErr == nil {
			config.GroqAPIKey = strings.TrimSpace(string(kData))
		} else {
			config.GroqAPIKey = DefaultGroqKey
		}
	}

	// Always sync master languages
	config.AllLanguages = MasterLanguages
	saveConfig()
}

func saveConfig() {
	data, err := json.MarshalIndent(config, "", "  ")
	if err == nil {
		_ = os.WriteFile(configFile, data, 0644)
	}
	if config.GroqAPIKey != "" {
		_ = os.WriteFile(keyFile, []byte(config.GroqAPIKey), 0644)
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

// Build standard 44-byte WAV container from raw PCM
func createWAV(pcm []byte, sampleRate int, channels int, bits int) []byte {
	dataLen := len(pcm)
	totalLen := 36 + dataLen
	byteRate := sampleRate * channels * (bits / 8)
	blockAlign := channels * (bits / 8)

	buf := make([]byte, 44+dataLen)
	copy(buf[0:], []byte("RIFF"))
	buf[4] = byte(totalLen)
	buf[5] = byte(totalLen >> 8)
	buf[6] = byte(totalLen >> 16)
	buf[7] = byte(totalLen >> 24)
	copy(buf[8:], []byte("WAVE"))

	copy(buf[12:], []byte("fmt "))
	buf[16] = 16
	buf[20] = 1 // PCM
	buf[22] = byte(channels)
	buf[24] = byte(sampleRate)
	buf[25] = byte(sampleRate >> 8)
	buf[26] = byte(sampleRate >> 16)
	buf[27] = byte(sampleRate >> 24)
	buf[28] = byte(byteRate)
	buf[29] = byte(byteRate >> 8)
	buf[30] = byte(byteRate >> 16)
	buf[31] = byte(byteRate >> 24)
	buf[32] = byte(blockAlign)
	buf[33] = byte(blockAlign >> 8)
	buf[34] = byte(bits)
	buf[35] = byte(bits >> 8)

	copy(buf[36:], []byte("data"))
	buf[40] = byte(dataLen)
	buf[41] = byte(dataLen >> 8)
	buf[42] = byte(dataLen >> 16)
	buf[43] = byte(dataLen >> 24)
	copy(buf[44:], pcm)

	return buf
}

func startRecordingWaveIn() error {
	audioMutex.Lock()
	capturedAudio = nil
	audioMutex.Unlock()

	var wfx WAVEFORMATEX
	wfx.WFormatTag = WAVE_FORMAT_PCM
	wfx.NChannels = 1
	wfx.NSamplesPerSec = 16000
	wfx.WBitsPerSample = 16
	wfx.NBlockAlign = 2
	wfx.NAvgBytesPerSec = 32000
	wfx.CbSize = 0

	ret, _, _ := procWaveInOpen.Call(
		uintptr(unsafe.Pointer(&hWaveIn)),
		WAVE_MAPPER,
		uintptr(unsafe.Pointer(&wfx)),
		hwndMain,
		0,
		CALLBACK_WINDOW,
	)
	if ret != 0 {
		return fmt.Errorf("waveInOpen failed with error code %d", ret)
	}

	bufSize := 8000 // 0.25 sec buffer
	for i := 0; i < 4; i++ {
		waveBuffers[i] = make([]byte, bufSize)
		waveHeaders[i] = WAVEHDR{
			LpData:         uintptr(unsafe.Pointer(&waveBuffers[i][0])),
			DwBufferLength: uint32(bufSize),
		}
		procWaveInPrepareHeader.Call(hWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
		procWaveInAddBuffer.Call(hWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
	}

	ret, _, _ = procWaveInStart.Call(hWaveIn)
	if ret != 0 {
		procWaveInClose.Call(hWaveIn)
		hWaveIn = 0
		return fmt.Errorf("waveInStart failed with error code %d", ret)
	}

	return nil
}

func stopRecordingWaveIn() []byte {
	if hWaveIn == 0 {
		return nil
	}

	procWaveInStop.Call(hWaveIn)
	procWaveInReset.Call(hWaveIn)

	for i := 0; i < 4; i++ {
		procWaveInUnprepareHeader.Call(hWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
	}
	procWaveInClose.Call(hWaveIn)
	hWaveIn = 0

	audioMutex.Lock()
	pcm := make([]byte, len(capturedAudio))
	copy(pcm, capturedAudio)
	audioMutex.Unlock()

	return createWAV(pcm, 16000, 1, 16)
}

func startRecording() {
	recordMutex.Lock()
	defer recordMutex.Unlock()

	if isRecording {
		return
	}

	err := startRecordingWaveIn()
	if err != nil {
		writeLog("WaveIn start error: " + err.Error())
		playBeep(250, 150)
		return
	}

	isRecording = true
	playBeep(880, 100) // High chime = start
	updateTrayState(true, AppTitle+" | 🔴 RECORDING... ("+config.Hotkey+" to Stop)")
	writeLog("Direct WaveIn recording started.")
}

func stopRecordingAndTranscribe() {
	recordMutex.Lock()
	if !isRecording {
		recordMutex.Unlock()
		return
	}
	isRecording = false
	recordMutex.Unlock()

	playBeep(440, 100) // Low chime = stop
	updateTrayState(false, AppTitle+" | ⚡ Transcribing with Whisper...")

	wavBytes := stopRecordingWaveIn()

	go func() {
		defer updateTrayState(false, AppTitle+" | Ready ("+config.Hotkey+")")

		if len(wavBytes) < 2000 {
			writeLog(fmt.Sprintf("Audio recording too short: %d bytes", len(wavBytes)))
			playBeep(220, 200)
			return
		}

		text, err := transcribeAudioBytes(wavBytes)
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
		writeLog(fmt.Sprintf("Direct paste: [%s]", text))
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

func transcribeAudioBytes(wavBytes []byte) (string, error) {
	apiKey := config.GroqAPIKey
	if apiKey == "" {
		apiKey = os.Getenv("GROQ_API_KEY")
	}
	if apiKey == "" {
		return "", fmt.Errorf("missing Groq API key")
	}

	var reqBody bytes.Buffer
	writer := multipart.NewWriter(&reqBody)

	part, err := writer.CreateFormFile("file", "audio.wav")
	if err != nil {
		return "", err
	}
	_, _ = part.Write(wavBytes)

	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "text")

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
		_ = writer.WriteField("language", strings.ToLower(config.ActiveLanguages[0]))
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
		return "", fmt.Errorf("Groq error (%d): %s", resp.StatusCode, string(respBytes))
	}

	return string(respBytes), nil
}

func testGroqAPIKey(key string) (bool, string) {
	if key == "" {
		return false, "Ключ пуст."
	}
	req, err := http.NewRequest("GET", "https://api.groq.com/openai/v1/models", nil)
	if err != nil {
		return false, err.Error()
	}
	req.Header.Set("Authorization", "Bearer "+key)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return false, "Сетевая ошибка: " + err.Error()
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return true, "✅ Ключ Groq валиден и активен! Доступно 7000с/день."
	}
	return false, fmt.Sprintf("❌ Ошибка авторизации (HTTP %d). Проверьте ключ.", resp.StatusCode)
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

// Native Win32 SHBrowseForFolderW dialog
func pickFolderNative(owner uintptr) string {
	var bi BROWSEINFOW
	title := "Выберите общую папку с базами знаний для GIN-Voice:"
	bi.HwndOwner = owner
	bi.LpszTitle = strPtr(title)
	bi.UlFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE

	pidl, _, _ := procSHBrowseForFolderW.Call(uintptr(unsafe.Pointer(&bi)))
	if pidl == 0 {
		return ""
	}
	defer procCoTaskMemFree.Call(pidl)

	var pathBuf [1024]uint16
	procSHGetPathFromIDListW.Call(pidl, uintptr(unsafe.Pointer(&pathBuf[0])))
	return syscall.UTF16ToString(pathBuf[:])
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

func runUninstall() {
	r, _, _ := procMessageBoxW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("Вы уверены, что хотите полностью удалить GIN-Voice и все его файлы?"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle+" - Подтверждение удаления"))),
		0x00000024,
	)
	if r != 6 {
		return
	}

	uninstPath := filepath.Join(appDir, "uninstall.bat")
	if _, err := os.Stat(uninstPath); os.IsNotExist(err) && len(defaultUninstallBAT) > 0 {
		_ = os.WriteFile(uninstPath, defaultUninstallBAT, 0644)
	}

	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(uninstPath))), 0, 0, SW_SHOWNORMAL)
	os.Exit(0)
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
			if strings.EqualFold(active, lang.Code) {
				flags |= MF_CHECKED
				break
			}
		}
		menuID := uintptr(IDM_LANG_BASE + idx)
		procAppendMenuW.Call(hLangMenu, flags, menuID, uintptr(unsafe.Pointer(strPtr(lang.Name+" ("+strings.ToUpper(lang.Code)+")"))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hLangMenu, uintptr(unsafe.Pointer(strPtr("🌐 Languages (Active)"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	keyLabel := "🔑 Groq API Key [✓ Configured]"
	if config.GroqAPIKey == "" && os.Getenv("GROQ_API_KEY") == "" {
		keyLabel = "⚠️ Groq API Key [Not Configured]"
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETUP_KEY, uintptr(unsafe.Pointer(strPtr(keyLabel))))

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DICT, uintptr(unsafe.Pointer(strPtr("📖 Open Dictionary (Notepad)"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_LINK_FOLDER, uintptr(unsafe.Pointer(strPtr("📂 Link AI Knowledge Folder..."))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_CONFIG, uintptr(unsafe.Pointer(strPtr("⚙️ Open Settings (GUI)"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DIR, uintptr(unsafe.Pointer(strPtr("📁 Open App Data Folder"))))

	autostartFlags := uintptr(MF_STRING)
	if config.Autostart {
		autostartFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autostartFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr("🚀 Autostart with Windows"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr("❓ Setup Guide & Help"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_UNINSTALL, uintptr(unsafe.Pointer(strPtr("🗑️ Uninstall GIN-Voice..."))))
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

	if hIconNormal == 0 {
		loadIcons()
	}

	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	screenHeight, _, _ := procGetSystemMetrics.Call(1)
	dlgWidth := int32(760)
	dlgHeight := int32(620)
	dlgX := (int32(screenWidth) - dlgWidth) / 2
	dlgY := (int32(screenHeight) - dlgHeight) / 2

	className := strPtr("GIN_VOICE_CYBER_SETTINGS")
	hInstance, _, _ := procGetModuleHandleW.Call(0)

	hwndSetup, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("⚙️ GIN-Voice [v005] — Settings & Personalization"))),
		WS_OVERLAPPEDWINDOW&^0x00040000 | WS_VISIBLE,
		uintptr(dlgX), uintptr(dlgY), uintptr(dlgWidth), uintptr(dlgHeight),
		0, 0, hInstance, 0,
	)

	procSendMessageW.Call(hwndSetup, WM_SETICON, ICON_SMALL, hIconNormal)
	procSendMessageW.Call(hwndSetup, WM_SETICON, ICON_BIG, hIconNormal)

	hFont, _, _ := procGetStockObject.Call(DEFAULT_GUI_FONT)

	// Section 1: Groq API Key
	lbl1, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("🔑 1. Groq API Key (Free, 0.3s latency) — Stored in api_key.txt:"))),
		WS_CHILD|WS_VISIBLE,
		24, 16, 700, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl1, WM_SETFONT, hFont, 1)

	currKey := config.GroqAPIKey
	hwndEditKey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(currKey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 40, 420, 28, hwndSetup, uintptr(IDC_EDIT_KEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditKey, WM_SETFONT, hFont, 1)

	btnCopy, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📋 Copy"))),
		WS_CHILD|WS_VISIBLE,
		454, 39, 80, 30, hwndSetup, uintptr(IDC_BTN_COPY_KEY), hInstance, 0,
	)
	procSendMessageW.Call(btnCopy, WM_SETFONT, hFont, 1)

	btnTest, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🧪 Test Key"))),
		WS_CHILD|WS_VISIBLE,
		542, 39, 95, 30, hwndSetup, uintptr(IDC_BTN_TEST), hInstance, 0,
	)
	procSendMessageW.Call(btnTest, WM_SETFONT, hFont, 1)

	btnGroq, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🌐 Get Key ↗"))),
		WS_CHILD|WS_VISIBLE,
		645, 39, 90, 30, hwndSetup, uintptr(IDC_BTN_GROQ), hInstance, 0,
	)
	procSendMessageW.Call(btnGroq, WM_SETFONT, hFont, 1)

	// Section 2: Hotkey & AI Knowledge Folder
	lbl2, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("⌨️ 2. Hotkey:"))),
		WS_CHILD|WS_VISIBLE,
		24, 82, 120, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl2, WM_SETFONT, hFont, 1)

	hwndEditHotkey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.Hotkey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 104, 100, 28, hwndSetup, uintptr(IDC_EDIT_HOTKEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditHotkey, WM_SETFONT, hFont, 1)

	lbl3, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("📂 3. AI Knowledge Database Folder (e.g. D:\\AI\\Base):"))),
		WS_CHILD|WS_VISIBLE,
		144, 82, 590, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl3, WM_SETFONT, hFont, 1)

	hwndEditFolder, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.LinkedKnowledgeFolder))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		144, 104, 460, 28, hwndSetup, uintptr(IDC_EDIT_FOLDER), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditFolder, WM_SETFONT, hFont, 1)

	btnBrowse, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📁 Browse..."))),
		WS_CHILD|WS_VISIBLE,
		614, 103, 120, 30, hwndSetup, uintptr(IDC_BTN_BROWSE), hInstance, 0,
	)
	procSendMessageW.Call(btnBrowse, WM_SETFONT, hFont, 1)

	// Section 3: 40 Languages in 4 Columns
	lbl4, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("🌐 4. Active Languages (40 Languages in 4 Columns, Select Any):"))),
		WS_CHILD|WS_VISIBLE,
		24, 146, 700, 20, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lbl4, WM_SETFONT, hFont, 1)

	colWidth := int32(174)
	startY := int32(170)
	rowHeight := int32(24)

	for idx, lang := range MasterLanguages {
		col := int32(idx / 10)
		row := int32(idx % 10)
		x := 24 + col*colWidth
		y := startY + row*rowHeight

		label := fmt.Sprintf("[%s] %s", lang.Code, lang.Name)
		chkHWnd, _, _ := procCreateWindowExW.Call(
			0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
			uintptr(unsafe.Pointer(strPtr(label))),
			WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
			uintptr(x), uintptr(y), uintptr(colWidth-10), uintptr(rowHeight),
			hwndSetup, uintptr(IDC_LANG_CHK_BASE+idx), hInstance, 0,
		)
		procSendMessageW.Call(chkHWnd, WM_SETFONT, hFont, 1)
		langCheckHWnd[lang.Code] = chkHWnd

		if hasLang(lang.Code) {
			procSendMessageW.Call(chkHWnd, 0x00F1, 1, 0) // BM_SETCHECK = BST_CHECKED
		}
	}

	// Action Buttons
	btnSave, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("💾 Save, Apply & Run"))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		24, 430, 200, 42, hwndSetup, uintptr(IDC_BTN_SAVE), hInstance, 0,
	)
	procSendMessageW.Call(btnSave, WM_SETFONT, hFont, 1)

	btnDict, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📖 Edit Dictionary"))),
		WS_CHILD|WS_VISIBLE,
		236, 430, 160, 42, hwndSetup, uintptr(IDC_BTN_DICT), hInstance, 0,
	)
	procSendMessageW.Call(btnDict, WM_SETFONT, hFont, 1)

	btnOpenDir, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("📁 Open App Folder"))),
		WS_CHILD|WS_VISIBLE,
		408, 430, 160, 42, hwndSetup, uintptr(IDC_BTN_OPEN_DIR), hInstance, 0,
	)
	procSendMessageW.Call(btnOpenDir, WM_SETFONT, hFont, 1)

	btnUninst, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("🗑️ Uninstall GIN-Voice"))),
		WS_CHILD|WS_VISIBLE,
		580, 430, 155, 42, hwndSetup, uintptr(IDC_BTN_UNINST), hInstance, 0,
	)
	procSendMessageW.Call(btnUninst, WM_SETFONT, hFont, 1)

	lblTip, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("GIN-Voice [v005] • Direct WaveIn Audio Engine • Hardware Hotkey [F8]"))),
		WS_CHILD|WS_VISIBLE,
		24, 490, 700, 25, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblTip, WM_SETFONT, hFont, 1)

	procSetForegroundWindow.Call(hwndSetup)
}

func hasLang(code string) bool {
	for _, l := range config.ActiveLanguages {
		if strings.EqualFold(l, code) {
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
		return VK_F8
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
				if strings.EqualFold(c, code) {
					found = true
				} else {
					updated = append(updated, c)
				}
			}
			if !found {
				updated = append(updated, code)
			}
			if len(updated) == 0 {
				updated = []string{"EN"}
			}
			config.ActiveLanguages = updated
			saveConfig()
		}
	case cmdID == IDM_OPEN_DICT:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
	case cmdID == IDM_OPEN_DIR:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("explorer.exe"))), uintptr(unsafe.Pointer(strPtr(appDir))), 0, SW_SHOWNORMAL)
	case cmdID == IDM_LINK_FOLDER:
		folder := pickFolderNative(hwndMain)
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
	case cmdID == IDM_AUTOSTART:
		toggleAutostart()
	case cmdID == IDM_OPEN_HELP:
		procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(helpFile))), 0, 0, SW_SHOWNORMAL)
	case cmdID == IDM_UNINSTALL:
		runUninstall()
	case cmdID == IDM_EXIT:
		procShellNotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
		procPostQuitMessage.Call(0)
	}
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case MM_WIM_DATA:
		hdr := (*WAVEHDR)(unsafe.Pointer(lParam))
		if hdr != nil && hdr.DwBytesRecorded > 0 {
			audioMutex.Lock()
			chunk := (*[1 << 20]byte)(unsafe.Pointer(hdr.LpData))[:hdr.DwBytesRecorded]
			capturedAudio = append(capturedAudio, chunk...)
			audioMutex.Unlock()
		}
		if isRecording && hWaveIn != 0 {
			procWaveInAddBuffer.Call(hWaveIn, lParam, uintptr(unsafe.Sizeof(*hdr)))
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

func setupWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_CTLCOLORSTATIC:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00F8FAFC) // Bright White text
		procSetBkColor.Call(hdc, 0x0018110D)   // Dark Slate #0D1118
		return hBrushDarkBg
	case WM_CTLCOLOREDIT:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00F8E500) // Neon Cyan text
		procSetBkColor.Call(hdc, 0x00261D12)   // Dark Edit Bg #121D26
		return hBrushEditBg
	case WM_CTLCOLORBTN:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00F8FAFC)
		procSetBkColor.Call(hdc, 0x0018110D)
		return hBrushDarkBg
	case WM_COMMAND:
		cmdID := wParam & 0xFFFF
		if cmdID == IDC_BTN_SAVE {
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			config.GroqAPIKey = strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))

			var bufHotkey [64]uint16
			procGetWindowTextW.Call(hwndEditHotkey, uintptr(unsafe.Pointer(&bufHotkey[0])), 64)
			newHotkey := strings.TrimSpace(syscall.UTF16ToString(bufHotkey[:]))
			if newHotkey != "" {
				config.Hotkey = newHotkey
				config.HotkeyVK = parseVK(newHotkey)
			}

			var bufFolder [1024]uint16
			procGetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(&bufFolder[0])), 1024)
			config.LinkedKnowledgeFolder = strings.TrimSpace(syscall.UTF16ToString(bufFolder[:]))

			var langs []string
			for _, lang := range MasterLanguages {
				if chkHwnd, exists := langCheckHWnd[lang.Code]; exists {
					r, _, _ := procSendMessageW.Call(chkHwnd, 0x00F0, 0, 0) // BM_GETCHECK
					if r == 1 {
						langs = append(langs, strings.ToUpper(lang.Code))
					}
				}
			}
			if len(langs) == 0 {
				langs = []string{"EN"}
			}
			config.ActiveLanguages = langs

			saveConfig()
			playBeep(880, 150)
			procShowWindow.Call(hwnd, SW_HIDE)
			initTrayIcon()
			updateTrayState(false, AppTitle+" | Ready ("+config.Hotkey+")")

			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("GIN-Voice настройки сохранены!\nКлюч сохранен в api_key.txt\nГорячая клавиша: [%s]\nЯзыки: %s", config.Hotkey, strings.Join(config.ActiveLanguages, ", "))))),
				uintptr(unsafe.Pointer(strPtr(AppTitle+" - Готово"))),
				0x00000040,
			)
			return 0
		} else if cmdID == IDC_BTN_COPY_KEY {
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			k := strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))
			if k != "" {
				setClipboardText(k)
				playBeep(880, 80)
				procMessageBoxW.Call(
					hwndSetup,
					uintptr(unsafe.Pointer(strPtr("Ключ скопирован в буфер обмена!"))),
					uintptr(unsafe.Pointer(strPtr(AppTitle))),
					0x00000040,
				)
			}
			return 0
		} else if cmdID == IDC_BTN_TEST {
			var bufKey [512]uint16
			procGetWindowTextW.Call(hwndEditKey, uintptr(unsafe.Pointer(&bufKey[0])), 512)
			testKey := strings.TrimSpace(syscall.UTF16ToString(bufKey[:]))
			go func(k string) {
				ok, resMsg := testGroqAPIKey(k)
				iconType := uintptr(0x00000040)
				if !ok {
					iconType = 0x00000010
				}
				procMessageBoxW.Call(
					hwndSetup,
					uintptr(unsafe.Pointer(strPtr(resMsg))),
					uintptr(unsafe.Pointer(strPtr(AppTitle+" - Проверка API ключа"))),
					iconType,
				)
			}(testKey)
			return 0
		} else if cmdID == IDC_BTN_GROQ {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(GroqKeysURL))), 0, 0, SW_SHOWNORMAL)
			return 0
		} else if cmdID == IDC_BTN_BROWSE {
			folder := pickFolderNative(hwnd)
			if folder != "" {
				procSetWindowTextW.Call(hwndEditFolder, uintptr(unsafe.Pointer(strPtr(folder))))
			}
			return 0
		} else if cmdID == IDC_BTN_DICT {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("notepad.exe"))), uintptr(unsafe.Pointer(strPtr(dictFile))), 0, SW_SHOWNORMAL)
			return 0
		} else if cmdID == IDC_BTN_OPEN_DIR {
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("explorer.exe"))), uintptr(unsafe.Pointer(strPtr(appDir))), 0, SW_SHOWNORMAL)
			return 0
		} else if cmdID == IDC_BTN_UNINST {
			runUninstall()
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

func startHotkeyListener() {
	go func() {
		var wasPressed bool
		for {
			time.Sleep(20 * time.Millisecond)
			vk := config.HotkeyVK
			if vk == 0 {
				vk = VK_F8
			}

			state, _, _ := procGetAsyncKeyState.Call(uintptr(vk))
			isDown := (state & 0x8000) != 0

			if isDown && !wasPressed {
				wasPressed = true
				writeLog(fmt.Sprintf("Hardware hotkey press detected: [%s] (VK %d)", config.Hotkey, vk))
				toggleRecording()
			} else if !isDown && wasPressed {
				wasPressed = false
			}
		}
	}()
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
$s1.IconLocation = '%s'
$s1.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s1.Save()

$startMenu = [Environment]::GetFolderPath('Programs')
$s2 = $w.CreateShortcut("$startMenu\GIN-Voice.lnk")
$s2.TargetPath = '%s'
$s2.WorkingDirectory = '%s'
$s2.IconLocation = '%s'
$s2.Description = 'GIN-Voice by VladiMIR+AI - Instant Voice Typing'
$s2.Save()

if (Test-Path 'D:\MEGA\DOCS\desktop') {
    $s3 = $w.CreateShortcut("D:\MEGA\DOCS\desktop\GIN-Voice.lnk")
    $s3.TargetPath = '%s'
    $s3.WorkingDirectory = '%s'
    $s3.IconLocation = '%s'
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

	// Clean up all old version binaries and installers in targetDir
	if entries, err := os.ReadDir(targetDir); err == nil {
		for _, entry := range entries {
			name := entry.Name()
			if strings.HasPrefix(name, "GIN-Voice_v") || strings.HasPrefix(name, "GIN-Voice_Setup_v") {
				_ = os.Remove(filepath.Join(targetDir, name))
			}
		}
	}

	_ = copyFile(currExe, targetExe)
	_ = copyFile(currExe, filepath.Join(targetDir, "GIN-Voice_v005.exe"))

	dstIco := filepath.Join(targetDir, "app.ico")
	if len(defaultAppIco) > 0 {
		_ = os.WriteFile(dstIco, defaultAppIco, 0644)
	}

	dstRecIco := filepath.Join(targetDir, "app_rec.ico")
	if len(defaultAppRecIco) > 0 {
		_ = os.WriteFile(dstRecIco, defaultAppRecIco, 0644)
	}

	dstUninst := filepath.Join(targetDir, "uninstall.bat")
	if len(defaultUninstallBAT) > 0 {
		_ = os.WriteFile(dstUninst, defaultUninstallBAT, 0644)
	}

	dictDest := filepath.Join(targetDir, "dictionary.json")
	if _, err := os.Stat(dictDest); os.IsNotExist(err) && len(defaultDictionaryJSON) > 0 {
		_ = os.WriteFile(dictDest, defaultDictionaryJSON, 0644)
	}

	guideDest := filepath.Join(targetDir, "setup_guide.html")
	if len(defaultSetupGuideHTML) > 0 {
		_ = os.WriteFile(guideDest, defaultSetupGuideHTML, 0644)
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
	uninstFlag := flag.Bool("uninstall", false, "Uninstall GIN-Voice completely")
	flag.Parse()

	if *uninstFlag {
		runUninstall()
		return
	}

	checkAndSelfInstall()

	exePath, _ := os.Executable()
	appDir = filepath.Dir(exePath)
	configFile = filepath.Join(appDir, "config.json")
	keyFile = filepath.Join(appDir, "api_key.txt")
	dictFile = filepath.Join(appDir, "dictionary.json")
	helpFile = filepath.Join(appDir, "setup_guide.html")
	logFile = filepath.Join(appDir, "gin_voice.log")

	writeLog("=== GIN-Voice [v005] Starting with Direct WaveIn Engine ===")

	loadConfig()
	loadDictionary()
	loadIcons()

	// Initialize Dark Brushes (Slate-900 / Dark Navy)
	bDark, _, _ := procCreateSolidBrush.Call(0x0018110D)
	hBrushDarkBg = bDark
	bEdit, _, _ := procCreateSolidBrush.Call(0x00261D12)
	hBrushEditBg = bEdit

	hInstance, _, _ := procGetModuleHandleW.Call(0)

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconNormal
	wc.LpszClassName = strPtr("GIN_VOICE_WINDOW_CLASS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	var sc WNDCLASSEXW
	sc.CbSize = uint32(unsafe.Sizeof(sc))
	sc.LpfnWndProc = syscall.NewCallback(setupWndProc)
	sc.HInstance = hInstance
	sc.HIcon = hIconNormal
	sc.HbrBackground = hBrushDarkBg
	sc.LpszClassName = strPtr("GIN_VOICE_CYBER_SETTINGS")
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&sc)))

	hwndMain, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_VOICE_WINDOW_CLASS"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		0, 0, 0, 0, 0,
		0, 0, hInstance, 0,
	)

	startHotkeyListener()

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
}

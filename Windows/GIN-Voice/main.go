// =============================================================================
// Execution Context : Go 1.22+ (Windows AMD64)
// Target Server     : Local Windows Desktop PC
// Description       : GIN-Voice Native Windows Client & Installer with Whisper AI, WaveIn Event Engine, Multi-Language UI, Cyber Dark GUI, On-Screen HUD [v009]
// =============================================================================

package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
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
	AppVersion    = "v009"
	AppTitle      = "GIN-Voice by VladiMIR+AI [v009]"
	GitHubRepoURL = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice"
	GroqKeysURL   = "https://console.groq.com/keys"
)

const (
	WM_USER           = 0x0400
	WM_TRAYICON       = WM_USER + 1
	WM_UPDATE_HUD     = WM_USER + 2
	WM_COMMAND        = 0x0111
	WM_DESTROY        = 0x0002
	WM_CLOSE          = 0x0010
	WM_SETFONT        = 0x0030
	WM_SETICON        = 0x0080
	WM_RBUTTONUP      = 0x0205
	WM_LBUTTONDBLCLK  = 0x0203
	WM_CTLCOLORSTATIC = 0x0138
	WM_CTLCOLOREDIT   = 0x0133
	WM_CTLCOLORBTN    = 0x0135
	WM_PAINT          = 0x000F

	CALLBACK_EVENT  = 0x00050000
	WAVE_MAPPER     = 0xFFFFFFFF
	WAVE_FORMAT_PCM = 1

	WHDR_DONE     = 0x00000001
	WHDR_PREPARED = 0x00000002
	WHDR_INQUEUE  = 0x00000010

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

	SW_SHOWNORMAL     = 1
	SW_HIDE           = 0
	SW_SHOWNOACTIVATE = 4

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x0010
	LR_DEFAULTSIZE  = 0x0040
	ICON_SMALL      = 0
	ICON_BIG        = 1

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_POPUP            = 0x80000000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	ES_AUTOHSCROLL      = 0x0080
	BS_DEFPUSHBUTTON    = 0x0001
	BS_AUTOCHECKBOX     = 0x0003

	WS_EX_TOPMOST    = 0x00000008
	WS_EX_TOOLWINDOW = 0x00000080

	BIF_RETURNONLYFSDIRS = 0x0001
	BIF_NEWDIALOGSTYLE   = 0x0040

	// Menu Command IDs
	IDM_TOGGLE_RECORD = 1001
	IDM_SETUP_KEY     = 1002
	IDM_OPEN_DICT     = 1003
	IDM_LINK_FOLDER   = 1004
	IDM_OPEN_CONFIG   = 1005
	IDM_AUTOSTART     = 1006
	IDM_OPEN_HELP     = 1007
	IDM_EXIT          = 1008

	IDM_UI_LANG_BASE = 1500
	IDM_LANG_BASE    = 2000

	// Settings Dialog IDs
	IDC_BTN_SAVE    = 3001
	IDC_BTN_GROQ    = 3002
	IDC_EDIT_KEY    = 3003
	IDC_EDIT_FOLDER = 3004
	IDC_BTN_BROWSE  = 3005
	IDC_EDIT_HOTKEY = 3006
	IDC_BTN_DICT    = 3007
	IDC_BTN_TEST    = 3008

	IDC_LANG_CHK_BASE = 4000
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
	uxtheme  = syscall.NewLazyDLL("uxtheme.dll")
	winmm    = syscall.NewLazyDLL("winmm.dll")

	procRegisterClassExW     = user32.NewProc("RegisterClassExW")
	procCreateWindowExW      = user32.NewProc("CreateWindowExW")
	procDefWindowProcW       = user32.NewProc("DefWindowProcW")
	procDestroyWindow        = user32.NewProc("DestroyWindow")
	procPostQuitMessage      = user32.NewProc("PostQuitMessage")
	procGetMessageW          = user32.NewProc("GetMessageW")
	procTranslateMessage     = user32.NewProc("TranslateMessage")
	procDispatchMessageW     = user32.NewProc("DispatchMessageW")
	procCreatePopupMenu      = user32.NewProc("CreatePopupMenu")
	procAppendMenuW          = user32.NewProc("AppendMenuW")
	procTrackPopupMenu       = user32.NewProc("TrackPopupMenu")
	procDestroyMenu          = user32.NewProc("DestroyMenu")
	procSetForegroundWindow  = user32.NewProc("SetForegroundWindow")
	procGetCursorPos         = user32.NewProc("GetCursorPos")
	procOpenClipboard        = user32.NewProc("OpenClipboard")
	procCloseClipboard       = user32.NewProc("CloseClipboard")
	procEmptyClipboard       = user32.NewProc("EmptyClipboard")
	procSetClipboardData     = user32.NewProc("SetClipboardData")
	procGetClipboardData     = user32.NewProc("GetClipboardData")
	procIsClipboardAvailable = user32.NewProc("IsClipboardFormatAvailable")
	procKeybdEvent           = user32.NewProc("keybd_event")
	procMessageBoxW          = user32.NewProc("MessageBoxW")
	procLoadIconW            = user32.NewProc("LoadIconW")
	procLoadImageW           = user32.NewProc("LoadImageW")
	procShowWindow           = user32.NewProc("ShowWindow")
	procSendMessageW         = user32.NewProc("SendMessageW")
	procPostMessageW         = user32.NewProc("PostMessageW")
	procGetWindowTextW       = user32.NewProc("GetWindowTextW")
	procSetWindowTextW       = user32.NewProc("SetWindowTextW")
	procGetSystemMetrics     = user32.NewProc("GetSystemMetrics")
	procGetAsyncKeyState       = user32.NewProc("GetAsyncKeyState")
	procInvalidateRect       = user32.NewProc("InvalidateRect")

	procShellNotifyIconW     = shell32.NewProc("Shell_NotifyIconW")
	procShellExecuteW        = shell32.NewProc("ShellExecuteW")
	procSHBrowseForFolderW   = shell32.NewProc("SHBrowseForFolderW")
	procSHGetPathFromIDListW = shell32.NewProc("SHGetPathFromIDListW")
	procCoTaskMemFree        = ole32.NewProc("CoTaskMemFree")

	procSetWindowTheme = uxtheme.NewProc("SetWindowTheme")

	procBeep                = kernel32.NewProc("Beep")
	procGlobalAlloc         = kernel32.NewProc("GlobalAlloc")
	procGlobalLock          = kernel32.NewProc("GlobalLock")
	procGlobalUnlock        = kernel32.NewProc("GlobalUnlock")
	procGlobalFree          = kernel32.NewProc("GlobalFree")
	procGetModuleHandleW    = kernel32.NewProc("GetModuleHandleW")
	procCreateEventW        = kernel32.NewProc("CreateEventW")
	procSetEvent            = kernel32.NewProc("SetEvent")
	procResetEvent          = kernel32.NewProc("ResetEvent")
	procWaitForSingleObject = kernel32.NewProc("WaitForSingleObject")
	procCloseHandle         = kernel32.NewProc("CloseHandle")

	procCreateSolidBrush = gdi32.NewProc("CreateSolidBrush")
	procCreateFontW      = gdi32.NewProc("CreateFontW")
	procSetTextColor     = gdi32.NewProc("SetTextColor")
	procSetBkColor       = gdi32.NewProc("SetBkColor")

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

type UIStringBundle struct {
	MenuStartDictation string
	MenuStopDictation  string
	MenuSpeechLang     string
	MenuInterfaceLang  string
	MenuKeyConfigured  string
	MenuKeyNotSet      string
	MenuOpenDict       string
	MenuLinkFolder     string
	MenuAutostart      string
	MenuHelp           string
	MenuExit           string
	SettingsTitle      string
	SettingsHeader     string
	SettingsKeyLabel   string
	SettingsGetGroq    string
	SettingsTestBtn    string
	SettingsHotkey     string
	SettingsHotkeyTip  string
	SettingsFolder     string
	SettingsBrowse     string
	SettingsLangs      string
	SettingsSave       string
	SettingsDict       string
	HudRecording       string
	HudTranscribing    string
	HudPasted          string
	HudEmpty           string
	HudError           string
	Ready              string
}

type Config struct {
	Version               string         `json:"version"`
	UILanguage            string         `json:"ui_language"` // EN, RU, CS, IT, ES, FR
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
	appDir         string
	configFile     string
	dictFile       string
	helpFile       string
	logFile        string
	config         Config
	dictionary     map[string]string
	dictMutex      sync.RWMutex
	hwndMain       uintptr
	hwndSetup      uintptr
	hwndHUD        uintptr
	hwndHUDText    uintptr
	hwndEditKey    uintptr
	hwndEditFolder uintptr
	hwndEditHotkey uintptr
	langCheckHWnd  = make(map[string]uintptr)
	nid            NOTIFYICONDATAW
	isRecording    bool
	recordMutex    sync.Mutex
	trayCreated    bool
	hIconNormal    uintptr
	hIconRec       uintptr
	hBrushDarkBg   uintptr
	hBrushEditBg   uintptr
	hFontNormal    uintptr
	hFontBold      uintptr
	hFontHeader    uintptr
	hFontHUD       uintptr

	// WaveIn Event Audio Engine
	hWaveIn       uintptr
	hWaveEvent    uintptr
	waveBuffers   [8][]byte
	waveHeaders   [8]WAVEHDR
	capturedAudio []byte
	audioMutex    sync.Mutex

	// UI Languages supported
	UILanguages = []LanguageItem{
		{"EN", "English"},
		{"RU", "Русский"},
		{"CS", "Čeština"},
		{"IT", "Italiano"},
		{"ES", "Español"},
		{"FR", "Français"},
	}

	// Recognition languages: EN first (checked by default), CS second, RU third, followed by others
	MasterLanguages = []LanguageItem{
		{"EN", "English (Английский)"},
		{"CS", "Čeština (Czech)"},
		{"RU", "Русский (Russian)"},
		{"DE", "Deutsch (German)"},
		{"UK", "Українська (Ukrainian)"},
		{"ES", "Español (Spanish)"},
		{"FR", "Français (French)"},
		{"IT", "Italiano (Italian)"},
		{"PL", "Polski (Polish)"},
		{"ZH", "中文 (Chinese)"},
		{"JA", "日本語 (Japanese)"},
		{"TR", "Türkçe (Turkish)"},
		{"AR", "العربية (Arabic)"},
		{"HE", "עברית (Hebrew)"},
	}

	UIStrings = map[string]UIStringBundle{
		"EN": {
			MenuStartDictation: "🔴 Start Dictation [%s]",
			MenuStopDictation:  "⏹️ Stop Dictation [%s]",
			MenuSpeechLang:     "🌐 Speech Recognition (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Interface Language",
			MenuKeyConfigured:  "🔑 Groq API Key: Configured",
			MenuKeyNotSet:      "⚠️ Groq API Key: NOT configured (Click to set)",
			MenuOpenDict:       "📖 Open Dictionary (dictionary.json)",
			MenuLinkFolder:     "📁 Link Knowledge Folder...",
			MenuAutostart:      "⚡ Autostart on Windows Boot",
			MenuHelp:           "❓ Setup Guide & Help",
			MenuExit:           "❌ Exit GIN-Voice",
			SettingsTitle:      "GIN-Voice - Settings & Control Center",
			SettingsHeader:     "🎙️ GIN-Voice by VladiMIR+AI — Instant Voice Typing",
			SettingsKeyLabel:   "🔑 Groq Whisper API Key:",
			SettingsGetGroq:    "🌐 Get Free Key at Groq.com",
			SettingsTestBtn:    "🧪 Test Key",
			SettingsHotkey:     "⚡ Dictation Hotkey:",
			SettingsHotkeyTip:  "(Available: F8, F4, F9, F10, F12 — Toggle Start/Stop)",
			SettingsFolder:     "📁 Linked Knowledge / Project Folder (Auto-Dictionary):",
			SettingsBrowse:     "📂 Browse...",
			SettingsLangs:      "🌐 Active Recognition Languages (Whisper AI):",
			SettingsSave:       "💾 Save & Apply",
			SettingsDict:       "📖 Edit Dictionary",
			HudRecording:       "🔴 RECORDING... Speak now [%s to Finish]",
			HudTranscribing:    "⚡ Transcribing with Whisper AI...",
			HudPasted:          "✅ Pasted: %s",
			HudEmpty:           "⚠️ Audio recording was empty.",
			HudError:           "❌ Error: %s",
			Ready:              "Ready",
		},
		"RU": {
			MenuStartDictation: "🔴 Начать диктовку [%s]",
			MenuStopDictation:  "⏹️ Остановить диктовку [%s]",
			MenuSpeechLang:     "🌐 Языки распознавания (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Язык интерфейса",
			MenuKeyConfigured:  "🔑 Groq API Ключ: Настроен",
			MenuKeyNotSet:      "⚠️ Groq API Ключ: НЕ задан (Нажмите для ввода)",
			MenuOpenDict:       "📖 Открыть словарь автозамен (dictionary.json)",
			MenuLinkFolder:     "📁 Привязать общую папку с базами знаний...",
			MenuAutostart:      "⚡ Автозапуск при старте Windows",
			MenuHelp:           "❓ Инструкция и справка",
			MenuExit:           "❌ Выход из GIN-Voice",
			SettingsTitle:      "GIN-Voice - Центр Управления",
			SettingsHeader:     "🎙️ GIN-Voice by VladiMIR+AI — Мгновенный Голосовой Ввод",
			SettingsKeyLabel:   "🔑 Groq Whisper API Key:",
			SettingsGetGroq:    "🌐 Получить бесплатный ключ на Groq.com",
			SettingsTestBtn:    "🧪 Проверить",
			SettingsHotkey:     "⚡ Горячая клавиша диктовки:",
			SettingsHotkeyTip:  "(Доступны: F8, F4, F9, F10, F12 — переключение Старт/Стоп)",
			SettingsFolder:     "📁 Общая папка с базами знаний / проектами (Автословарь):",
			SettingsBrowse:     "📂 Обзор...",
			SettingsLangs:      "🌐 Активные языки распознавания (Whisper AI):",
			SettingsSave:       "💾 Сохранить и Применить",
			SettingsDict:       "📖 Редактировать словарь",
			HudRecording:       "🔴 ИДЁТ ЗАПИСЬ... Говорите [%s для Завершения]",
			HudTranscribing:    "⚡ Распознавание речи через Whisper AI...",
			HudPasted:          "✅ Вставлено: %s",
			HudEmpty:           "⚠️ Запись звука оказалась пустой.",
			HudError:           "❌ Ошибка: %s",
			Ready:              "Готов к работе",
		},
		"CS": {
			MenuStartDictation: "🔴 Spustit diktování [%s]",
			MenuStopDictation:  "⏹️ Zastavit diktování [%s]",
			MenuSpeechLang:     "🌐 Jazyky rozpoznávání (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Jazyk rozhraní",
			MenuKeyConfigured:  "🔑 Groq API Klíč: Nastaven",
			MenuKeyNotSet:      "⚠️ Groq API Klíč: NENÍ nastaven (Klikněte pro zadání)",
			MenuOpenDict:       "📖 Otevřít slovník (dictionary.json)",
			MenuLinkFolder:     "📁 Propojit složku znalostí...",
			MenuAutostart:      "⚡ Automatické spuštění při startu Windows",
			MenuHelp:           "❓ Nápověda a průvodce",
			MenuExit:           "❌ Ukončit GIN-Voice",
			SettingsTitle:      "GIN-Voice - Nastavení a Ovládací Centrum",
			SettingsHeader:     "🎙️ GIN-Voice od VladiMIR+AI — Okamžité Hlasové Psaní",
			SettingsKeyLabel:   "🔑 Groq Whisper API Klíč:",
			SettingsGetGroq:    "🌐 Získat klíč zdarma na Groq.com",
			SettingsTestBtn:    "🧪 Otestovat",
			SettingsHotkey:     "⚡ Klávesová zkratka diktování:",
			SettingsHotkeyTip:  "(Dostupné: F8, F4, F9, F10, F12 — Přepínač Start/Stop)",
			SettingsFolder:     "📁 Propojená složka projektů (Automatický slovník):",
			SettingsBrowse:     "📂 Procházet...",
			SettingsLangs:      "🌐 Aktivní jazyky rozpoznávání (Whisper AI):",
			SettingsSave:       "💾 Uložit a Použít",
			SettingsDict:       "📖 Upravit slovník",
			HudRecording:       "🔴 NAHRÁVÁNÍ... Mluvte [%s pro Dokončení]",
			HudTranscribing:    "⚡ Přepisuji řeč pomocí Whisper AI...",
			HudPasted:          "✅ Vloženo: %s",
			HudEmpty:           "⚠️ Záznam byl prázdný.",
			HudError:           "❌ Chyba: %s",
			Ready:              "Připraven",
		},
		"IT": {
			MenuStartDictation: "🔴 Avvia dettatura [%s]",
			MenuStopDictation:  "⏹️ Ferma dettatura [%s]",
			MenuSpeechLang:     "🌐 Lingue di riconoscimento (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Lingua dell'interfaccia",
			MenuKeyConfigured:  "🔑 Chiave Groq API: Configurato",
			MenuKeyNotSet:      "⚠️ Chiave Groq API: NON impostata (Clicca per inserire)",
			MenuOpenDict:       "📖 Apri dizionario (dictionary.json)",
			MenuLinkFolder:     "📁 Collega cartella progetti...",
			MenuAutostart:      "⚡ Avvio automatico con Windows",
			MenuHelp:           "❓ Guida e supporto",
			MenuExit:           "❌ Esci da GIN-Voice",
			SettingsTitle:      "GIN-Voice - Centro di controllo",
			SettingsHeader:     "🎙️ GIN-Voice by VladiMIR+AI — Digitazione vocale istantanea",
			SettingsKeyLabel:   "🔑 Chiave Groq Whisper API:",
			SettingsGetGroq:    "🌐 Ottieni chiave gratuita su Groq.com",
			SettingsTestBtn:    "🧪 Verifica",
			SettingsHotkey:     "⚡ Tasto rapido di dettatura:",
			SettingsHotkeyTip:  "(Disponibili: F8, F4, F9, F10, F12 — Avvia/Ferma)",
			SettingsFolder:     "📁 Cartella progetti collegata (Dizionario automatico):",
			SettingsBrowse:     "📂 Sfoglia...",
			SettingsLangs:      "🌐 Lingue di riconoscimento attive (Whisper AI):",
			SettingsSave:       "💾 Salva e applica",
			SettingsDict:       "📖 Modifica dizionario",
			HudRecording:       "🔴 REGISTRAZIONE... Parla [%s per Terminare]",
			HudTranscribing:    "⚡ Trascrizione vocale con Whisper AI...",
			HudPasted:          "✅ Incollato: %s",
			HudEmpty:           "⚠️ La registrazione audio era vuota.",
			HudError:           "❌ Errore: %s",
			Ready:              "Pronto",
		},
		"ES": {
			MenuStartDictation: "🔴 Iniciar dictado [%s]",
			MenuStopDictation:  "⏹️ Detener dictado [%s]",
			MenuSpeechLang:     "🌐 Idiomas de reconocimiento (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Idioma de la interfaz",
			MenuKeyConfigured:  "🔑 Clave Groq API: Configurada",
			MenuKeyNotSet:      "⚠️ Clave Groq API: NO configurada (Haga clic para ingresar)",
			MenuOpenDict:       "📖 Abrir diccionario (dictionary.json)",
			MenuLinkFolder:     "📁 Vincular carpeta de conocimientos...",
			MenuAutostart:      "⚡ Inicio automático con Windows",
			MenuHelp:           "❓ Guía y ayuda",
			MenuExit:           "❌ Salir de GIN-Voice",
			SettingsTitle:      "GIN-Voice - Centro de control",
			SettingsHeader:     "🎙️ GIN-Voice por VladiMIR+AI — Dictado por voz instantáneo",
			SettingsKeyLabel:   "🔑 Clave Groq Whisper API:",
			SettingsGetGroq:    "🌐 Obtener clave gratis en Groq.com",
			SettingsTestBtn:    "🧪 Probar clave",
			SettingsHotkey:     "⚡ Tecla de acceso rápido:",
			SettingsHotkeyTip:  "(Disponibles: F8, F4, F9, F10, F12 — Iniciar/Detener)",
			SettingsFolder:     "📁 Carpeta vinculada de proyectos (Diccionario automático):",
			SettingsBrowse:     "📂 Examinar...",
			SettingsLangs:      "🌐 Idiomas de reconocimiento activos (Whisper AI):",
			SettingsSave:       "💾 Guardar y aplicar",
			SettingsDict:       "📖 Editar diccionario",
			HudRecording:       "🔴 GRABANDO... Hable [%s para Terminar]",
			HudTranscribing:    "⚡ Transcribiendo voz con Whisper AI...",
			HudPasted:          "✅ Pegado: %s",
			HudEmpty:           "⚠️ La grabación de audio estaba vacía.",
			HudError:           "❌ Error: %s",
			Ready:              "Listo",
		},
		"FR": {
			MenuStartDictation: "🔴 Démarrer la dictée [%s]",
			MenuStopDictation:  "⏹️ Arrêter la dictée [%s]",
			MenuSpeechLang:     "🌐 Langues de reconnaissance (Whisper AI)",
			MenuInterfaceLang:  "🖥️ Langue de l'interface",
			MenuKeyConfigured:  "🔑 Clé Groq API : Configurée",
			MenuKeyNotSet:      "⚠️ Clé Groq API : NON configurée (Cliquez pour définir)",
			MenuOpenDict:       "📖 Ouvrir le dictionnaire (dictionary.json)",
			MenuLinkFolder:     "📁 Lier le dossier de connaissances...",
			MenuAutostart:      "⚡ Démarrage automatique avec Windows",
			MenuHelp:           "❓ Guide d'installation et aide",
			MenuExit:           "❌ Quitter GIN-Voice",
			SettingsTitle:      "GIN-Voice - Centre de configuration",
			SettingsHeader:     "🎙️ GIN-Voice par VladiMIR+AI — Saisie vocale instantanée",
			SettingsKeyLabel:   "🔑 Clé Groq Whisper API :",
			SettingsGetGroq:    "🌐 Obtenir une clé gratuite sur Groq.com",
			SettingsTestBtn:    "🧪 Tester",
			SettingsHotkey:     "⚡ Raccourci de dictée :",
			SettingsHotkeyTip:  "(Disponibles : F8, F4, F9, F10, F12 — Démarrer/Arrêter)",
			SettingsFolder:     "📁 Dossier de projets lié (Dictionnaire automatique) :",
			SettingsBrowse:     "📂 Parcourir...",
			SettingsLangs:      "🌐 Langues de reconnaissance actives (Whisper AI) :",
			SettingsSave:       "💾 Enregistrer et appliquer",
			SettingsDict:       "📖 Modifier le dictionnaire",
			HudRecording:       "🔴 ENREGISTREMENT... Parlez [%s pour Terminer]",
			HudTranscribing:    "⚡ Transcription vocale avec Whisper AI...",
			HudPasted:          "✅ Collé : %s",
			HudEmpty:           "⚠️ L'enregistrement audio était vide.",
			HudError:           "❌ Erreur : %s",
			Ready:              "Prêt",
		},
	}
)

func getUI() UIStringBundle {
	code := strings.ToUpper(config.UILanguage)
	if b, exists := UIStrings[code]; exists {
		return b
	}
	return UIStrings["EN"]
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
	iconPath := filepath.Join(appDir, fileName)
	if _, err := os.Stat(iconPath); os.IsNotExist(err) && len(defaultBytes) > 0 {
		_ = os.WriteFile(iconPath, defaultBytes, 0644)
	}

	h, _, _ := procLoadImageW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr(iconPath))),
		IMAGE_ICON,
		0, 0,
		LR_LOADFROMFILE|LR_DEFAULTSIZE,
	)
	if h != 0 {
		return h
	}

	hSys, _, _ := procLoadIconW.Call(0, 32512) // IDI_APPLICATION
	return hSys
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

func updateHUD(visible bool, text string) {
	if hwndHUD == 0 {
		return
	}
	if visible {
		procSetWindowTextW.Call(hwndHUDText, uintptr(unsafe.Pointer(strPtr(text))))
		procShowWindow.Call(hwndHUD, SW_SHOWNOACTIVATE)
	} else {
		procShowWindow.Call(hwndHUD, SW_HIDE)
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

	for i := range nid.SzTip {
		nid.SzTip[i] = 0
	}
	uTip, _ := syscall.UTF16FromString(tipText)
	copy(nid.SzTip[:], uTip)

	nid.UFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE
	procShellNotifyIconW.Call(NIM_MODIFY, uintptr(unsafe.Pointer(&nid)))
}

func initTrayIcon() {
	if trayCreated {
		return
	}
	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.HWnd = hwndMain
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconNormal

	ui := getUI()
	tip := fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey)
	uTip, _ := syscall.UTF16FromString(tip)
	copy(nid.SzTip[:], uTip)

	procShellNotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))
	trayCreated = true
}

func loadConfig() {
	config = Config{
		Version:          AppVersion,
		UILanguage:       "EN", // English by default
		FirstRun:         false,
		Hotkey:           "F8",
		HotkeyVK:         VK_F8,
		HotkeyMod:        0,
		ActiveLanguages:  []string{"EN"}, // English checked by default
		AllLanguages:     MasterLanguages,
		GroqAPIKey:       "", // Strictly empty by default - no hardcoded keys, no env fallback
		SoundFeedback:    true,
		AutoPaste:        true,
		RestoreClipboard: true,
		Autostart:        false,
	}

	data, err := os.ReadFile(configFile)
	if err == nil {
		_ = json.Unmarshal(data, &config)
	}

	if config.UILanguage == "" {
		config.UILanguage = "EN"
	}

	if len(config.ActiveLanguages) == 0 {
		config.ActiveLanguages = []string{"EN"}
	}

	config.AllLanguages = MasterLanguages
	saveConfig()
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

// WaveIn Event-Driven Engine: Direct low-latency asynchronous audio recording
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

	hEv, _, _ := procCreateEventW.Call(0, 0, 0, 0)
	if hEv == 0 {
		return fmt.Errorf("failed to create audio sync event")
	}

	var newWaveIn uintptr
	ret, _, _ := procWaveInOpen.Call(
		uintptr(unsafe.Pointer(&newWaveIn)),
		WAVE_MAPPER,
		uintptr(unsafe.Pointer(&wfx)),
		hEv,
		0,
		CALLBACK_EVENT,
	)
	if ret != 0 {
		procCloseHandle.Call(hEv)
		return fmt.Errorf("waveInOpen error: %d", ret)
	}

	audioMutex.Lock()
	hWaveIn = newWaveIn
	hWaveEvent = hEv
	audioMutex.Unlock()

	bufSize := 8000 // 250ms chunks
	for i := 0; i < 8; i++ {
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
		audioMutex.Lock()
		curWaveIn := hWaveIn
		curEvent := hWaveEvent
		hWaveIn = 0
		hWaveEvent = 0
		audioMutex.Unlock()

		procWaveInClose.Call(curWaveIn)
		procCloseHandle.Call(curEvent)
		return fmt.Errorf("waveInStart error: %d", ret)
	}

	// Dedicated background event capture goroutine (100% decoupled from Windows GUI message loop)
	go func(targetWaveIn, targetEvent uintptr) {
		for {
			r, _, _ := procWaitForSingleObject.Call(targetEvent, 60)
			if r != 0 && r != 258 {
				break
			}

			audioMutex.Lock()
			active := isRecording && hWaveIn == targetWaveIn
			if !active {
				audioMutex.Unlock()
				break
			}

			for i := 0; i < 8; i++ {
				if (waveHeaders[i].DwFlags & WHDR_DONE) != 0 {
					if waveHeaders[i].DwBytesRecorded > 0 {
						chunk := (*[1 << 20]byte)(unsafe.Pointer(waveHeaders[i].LpData))[:waveHeaders[i].DwBytesRecorded]
						capturedAudio = append(capturedAudio, chunk...)
					}
					waveHeaders[i].DwFlags &^= WHDR_DONE
					if isRecording && hWaveIn == targetWaveIn {
						procWaveInAddBuffer.Call(targetWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
					}
				}
			}
			audioMutex.Unlock()
		}
	}(hWaveIn, hWaveEvent)

	return nil
}

func stopRecordingWaveIn() []byte {
	audioMutex.Lock()
	curWaveIn := hWaveIn
	curEvent := hWaveEvent
	hWaveIn = 0
	hWaveEvent = 0
	audioMutex.Unlock()

	if curWaveIn == 0 {
		return nil
	}

	procWaveInStop.Call(curWaveIn)
	procWaveInReset.Call(curWaveIn)

	audioMutex.Lock()
	for i := 0; i < 8; i++ {
		if waveHeaders[i].DwBytesRecorded > 0 && (waveHeaders[i].DwFlags&WHDR_DONE) != 0 {
			chunk := (*[1 << 20]byte)(unsafe.Pointer(waveHeaders[i].LpData))[:waveHeaders[i].DwBytesRecorded]
			capturedAudio = append(capturedAudio, chunk...)
		}
		procWaveInUnprepareHeader.Call(curWaveIn, uintptr(unsafe.Pointer(&waveHeaders[i])), uintptr(unsafe.Sizeof(waveHeaders[i])))
	}

	pcm := make([]byte, len(capturedAudio))
	copy(pcm, capturedAudio)
	audioMutex.Unlock()

	procWaveInClose.Call(curWaveIn)
	if curEvent != 0 {
		procCloseHandle.Call(curEvent)
	}

	return createWAV(pcm, 16000, 1, 16)
}

func startRecording() {
	recordMutex.Lock()
	defer recordMutex.Unlock()

	if isRecording {
		return
	}

	cleanKey := strings.TrimSpace(config.GroqAPIKey)
	if cleanKey == "" {
		playBeep(250, 200)
		showSettingsDialog()
		return
	}

	err := startRecordingWaveIn()
	if err != nil {
		writeLog("WaveIn start error: " + err.Error())
		playBeep(250, 150)
		return
	}

	isRecording = true
	playBeep(880, 100)
	ui := getUI()
	updateTrayState(true, fmt.Sprintf("%s | %s", AppTitle, fmt.Sprintf(ui.HudRecording, config.Hotkey)))
	updateHUD(true, fmt.Sprintf(ui.HudRecording, config.Hotkey))
	writeLog("Direct WaveIn Event recording active.")
}

func stopRecordingAndTranscribe() {
	recordMutex.Lock()
	if !isRecording {
		recordMutex.Unlock()
		return
	}
	isRecording = false
	recordMutex.Unlock()

	ui := getUI()
	playBeep(440, 100)
	updateTrayState(false, AppTitle+" | "+ui.HudTranscribing)
	updateHUD(true, ui.HudTranscribing)

	wavBytes := stopRecordingWaveIn()

	go func() {
		defer updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))
		defer func() {
			time.Sleep(1400 * time.Millisecond)
			updateHUD(false, "")
		}()

		if len(wavBytes) < 2000 {
			writeLog(fmt.Sprintf("Audio recording too short: %d bytes", len(wavBytes)))
			playBeep(220, 200)
			updateHUD(true, ui.HudEmpty)
			return
		}

		text, err := transcribeAudioBytes(wavBytes)
		if err != nil {
			writeLog("Transcription error: " + err.Error())
			playBeep(220, 300)
			updateHUD(true, fmt.Sprintf(ui.HudError, err.Error()))
			return
		}

		text = strings.TrimSpace(text)
		if text == "" {
			return
		}

		text = applyDictionary(text)
		writeLog(fmt.Sprintf("Pasted text: [%s]", text))
		updateHUD(true, fmt.Sprintf(ui.HudPasted, text))
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

func getTranscriptionLanguage() string {
	hasEN := hasLang("EN")
	hasCS := hasLang("CS")
	hasRU := hasLang("RU")

	if hasEN && !hasCS && !hasRU {
		return "en"
	}
	if hasCS && !hasRU {
		return "cs"
	}
	if hasRU {
		return "ru"
	}
	if len(config.ActiveLanguages) == 1 {
		return strings.ToLower(config.ActiveLanguages[0])
	}
	return "en"
}

func transcribeAudioBytes(wavBytes []byte) (string, error) {
	apiKey := strings.TrimSpace(config.GroqAPIKey)
	if apiKey == "" {
		return "", fmt.Errorf("Groq API Key is not configured. Please open settings and enter your key.")
	}

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, err := writer.CreateFormFile("file", "speech.wav")
	if err != nil {
		return "", fmt.Errorf("failed to create form file: %w", err)
	}
	_, err = part.Write(wavBytes)
	if err != nil {
		return "", fmt.Errorf("failed to write wav bytes: %w", err)
	}

	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "json")
	_ = writer.WriteField("temperature", "0.0")

	langCode := getTranscriptionLanguage()
	_ = writer.WriteField("language", langCode)

	dictMutex.RLock()
	var dictTerms []string
	for _, v := range dictionary {
		dictTerms = append(dictTerms, v)
	}
	dictMutex.RUnlock()

	promptContext := "GIN-Voice, GIN-Cinema, GIN-TV, GIN-NetScan, GIN-Chat, GIN-VPN, Secret_Privat, ORACLE_157, Server_222, Antigravity, Gemini, Python, Windows 11"
	if len(dictTerms) > 0 {
		promptContext = strings.Join(dictTerms, ", ")
	}
	_ = writer.WriteField("prompt", promptContext)

	err = writer.Close()
	if err != nil {
		return "", fmt.Errorf("failed to close multipart writer: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/audio/transcriptions", body)
	if err != nil {
		return "", fmt.Errorf("failed to build HTTP request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Groq API request failed: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Groq API error (%d): %s", resp.StatusCode, string(respBytes))
	}

	var parsed struct {
		Text string `json:"text"`
	}
	if err := json.Unmarshal(respBytes, &parsed); err != nil {
		return "", fmt.Errorf("failed to parse json response: %w", err)
	}

	return parsed.Text, nil
}

func testGroqAPIKey(key string) (bool, string) {
	key = strings.TrimSpace(key)
	if key == "" {
		return false, "API Key cannot be empty."
	}

	dummyWAV := createWAV(make([]byte, 16000), 16000, 1, 16)
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, _ := writer.CreateFormFile("file", "test.wav")
	_, _ = part.Write(dummyWAV)
	_ = writer.WriteField("model", "whisper-large-v3")
	_ = writer.WriteField("response_format", "json")
	_ = writer.Close()

	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/audio/transcriptions", body)
	if err != nil {
		return false, "Error creating request: " + err.Error()
	}

	req.Header.Set("Authorization", "Bearer "+key)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 8 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return false, "Connection error with Groq: " + err.Error()
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusOK {
		return true, "✅ Success! Groq Whisper AI API key is valid and fully operational."
	}
	return false, fmt.Sprintf("❌ API Key Error (%d): %s", resp.StatusCode, string(respBytes))
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

func pickFolderNative(owner uintptr) string {
	var bi BROWSEINFOW
	title := "Select knowledge base / project folder for GIN-Voice:"
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

		baseName := name
		if !entry.IsDir() {
			baseName = strings.TrimSuffix(name, filepath.Ext(name))
		}

		if len(baseName) < 2 {
			continue
		}

		cleanKey := strings.ToLower(strings.ReplaceAll(baseName, "_", " "))
		cleanKey = strings.ReplaceAll(cleanKey, "-", " ")

		if _, exists := dictionary[cleanKey]; !exists {
			dictionary[cleanKey] = baseName
			addedCount++
		}
	}

	if addedCount > 0 {
		data, _ := json.MarshalIndent(dictionary, "", "  ")
		_ = os.WriteFile(dictFile, data, 0644)
	}

	return addedCount
}

func setAutostart(enabled bool) error {
	exePath, err := os.Executable()
	if err != nil {
		return err
	}

	keyCmd := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	if enabled {
		cmd := exec.Command("reg", "add", keyCmd, "/v", "GIN-Voice", "/t", "REG_SZ", "/d", fmt.Sprintf("\"%s\"", exePath), "/f")
		return cmd.Run()
	} else {
		cmd := exec.Command("reg", "delete", keyCmd, "/v", "GIN-Voice", "/f")
		return cmd.Run()
	}
}

func toggleAutostart() {
	config.Autostart = !config.Autostart
	_ = setAutostart(config.Autostart)
	saveConfig()
}

func showContextMenu() {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	defer procDestroyMenu.Call(hMenu)

	ui := getUI()
	var titleText string
	recordMutex.Lock()
	rec := isRecording
	recordMutex.Unlock()

	if rec {
		titleText = fmt.Sprintf(ui.MenuStopDictation, config.Hotkey)
	} else {
		titleText = fmt.Sprintf(ui.MenuStartDictation, config.Hotkey)
	}

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_TOGGLE_RECORD, uintptr(unsafe.Pointer(strPtr(titleText))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)

	// Speech Recognition Languages Submenu
	hLangSubMenu, _, _ := procCreatePopupMenu.Call()
	for i, lang := range config.AllLanguages {
		flags := uintptr(MF_STRING)
		if hasLang(lang.Code) {
			flags |= MF_CHECKED
		}
		itemText := fmt.Sprintf("[%s] %s", lang.Code, lang.Name)
		procAppendMenuW.Call(hLangSubMenu, flags, IDM_LANG_BASE+uintptr(i), uintptr(unsafe.Pointer(strPtr(itemText))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hLangSubMenu, uintptr(unsafe.Pointer(strPtr(ui.MenuSpeechLang))))

	// Interface Language Submenu (EN, RU, CS, IT, ES, FR)
	hUILangSubMenu, _, _ := procCreatePopupMenu.Call()
	for i, uiItem := range UILanguages {
		flags := uintptr(MF_STRING)
		if strings.EqualFold(config.UILanguage, uiItem.Code) {
			flags |= MF_CHECKED
		}
		procAppendMenuW.Call(hUILangSubMenu, flags, IDM_UI_LANG_BASE+uintptr(i), uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("[%s] %s", uiItem.Code, uiItem.Name)))))
	}
	procAppendMenuW.Call(hMenu, MF_POPUP, hUILangSubMenu, uintptr(unsafe.Pointer(strPtr(ui.MenuInterfaceLang))))

	cleanKey := strings.TrimSpace(config.GroqAPIKey)
	statusKey := ui.MenuKeyConfigured
	if cleanKey == "" {
		statusKey = ui.MenuKeyNotSet
	}
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETUP_KEY, uintptr(unsafe.Pointer(strPtr(statusKey))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DICT, uintptr(unsafe.Pointer(strPtr(ui.MenuOpenDict))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_LINK_FOLDER, uintptr(unsafe.Pointer(strPtr(ui.MenuLinkFolder))))

	autoFlags := uintptr(MF_STRING)
	if config.Autostart {
		autoFlags |= MF_CHECKED
	}
	procAppendMenuW.Call(hMenu, autoFlags, IDM_AUTOSTART, uintptr(unsafe.Pointer(strPtr(ui.MenuAutostart))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_HELP, uintptr(unsafe.Pointer(strPtr(ui.MenuHelp))))

	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr(ui.MenuExit))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(hwndMain)
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, hwndMain, 0)
}

func showSettingsDialog() {
	if hwndSetup != 0 {
		procShowWindow.Call(hwndSetup, SW_SHOWNORMAL)
		procSetForegroundWindow.Call(hwndSetup)
		return
	}

	ui := getUI()
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	screenHeight, _, _ := procGetSystemMetrics.Call(1)

	winW := int32(840)
	winH := int32(590)
	posX := (int32(screenWidth) - winW) / 2
	posY := (int32(screenHeight) - winH) / 2

	hwndSetup, _, _ = procCreateWindowExW.Call(
		WS_EX_TOPMOST,
		uintptr(unsafe.Pointer(strPtr("GIN_VOICE_CYBER_SETTINGS"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle+" - "+ui.SettingsTitle))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		uintptr(posX), uintptr(posY), uintptr(winW), uintptr(winH),
		0, 0, hInstance, 0,
	)

	// Header Banner
	lblHdr, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsHeader))),
		WS_CHILD|WS_VISIBLE,
		24, 20, 780, 32, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblHdr, WM_SETFONT, hFontHeader, 1)

	// 1. Groq API Key Row
	lblKey, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsKeyLabel))),
		WS_CHILD|WS_VISIBLE,
		24, 68, 260, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblKey, WM_SETFONT, hFontBold, 1)

	btnGroq, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsGetGroq))),
		WS_CHILD|WS_VISIBLE,
		470, 62, 334, 30, hwndSetup, uintptr(IDC_BTN_GROQ), hInstance, 0,
	)
	procSendMessageW.Call(btnGroq, WM_SETFONT, hFontNormal, 1)

	hwndEditKey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.GroqAPIKey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 98, 640, 34, hwndSetup, uintptr(IDC_EDIT_KEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditKey, WM_SETFONT, hFontNormal, 1)

	btnTest, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsTestBtn))),
		WS_CHILD|WS_VISIBLE,
		674, 98, 130, 34, hwndSetup, uintptr(IDC_BTN_TEST), hInstance, 0,
	)
	procSendMessageW.Call(btnTest, WM_SETFONT, hFontBold, 1)

	// 2. Hotkey Config Row
	lblHot, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsHotkey))),
		WS_CHILD|WS_VISIBLE,
		24, 146, 260, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblHot, WM_SETFONT, hFontBold, 1)

	hwndEditHotkey, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.Hotkey))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		290, 142, 120, 32, hwndSetup, uintptr(IDC_EDIT_HOTKEY), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditHotkey, WM_SETFONT, hFontBold, 1)

	lblHotTip, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsHotkeyTip))),
		WS_CHILD|WS_VISIBLE,
		424, 146, 380, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblHotTip, WM_SETFONT, hFontNormal, 1)

	// 3. Knowledge Base Linking
	lblFold, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsFolder))),
		WS_CHILD|WS_VISIBLE,
		24, 186, 520, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblFold, WM_SETFONT, hFontBold, 1)

	hwndEditFolder, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("EDIT"))),
		uintptr(unsafe.Pointer(strPtr(config.LinkedKnowledgeFolder))),
		WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL,
		24, 216, 640, 34, hwndSetup, uintptr(IDC_EDIT_FOLDER), hInstance, 0,
	)
	procSendMessageW.Call(hwndEditFolder, WM_SETFONT, hFontNormal, 1)

	btnBrowse, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsBrowse))),
		WS_CHILD|WS_VISIBLE,
		674, 216, 130, 34, hwndSetup, uintptr(IDC_BTN_BROWSE), hInstance, 0,
	)
	procSendMessageW.Call(btnBrowse, WM_SETFONT, hFontBold, 1)

	// 4. Recognition Language Checklist
	lblLangs, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsLangs))),
		WS_CHILD|WS_VISIBLE,
		24, 264, 780, 26, hwndSetup, 0, hInstance, 0,
	)
	procSendMessageW.Call(lblLangs, WM_SETFONT, hFontBold, 1)

	startX := int32(24)
	startY := int32(296)
	colW := int32(260)
	rowH := int32(32)

	for i, lang := range MasterLanguages {
		col := int32(i % 3)
		row := int32(i / 3)
		cX := startX + (col * colW)
		cY := startY + (row * rowH)

		chkHwnd, _, _ := procCreateWindowExW.Call(
			0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
			uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("[%s] %s", lang.Code, lang.Name)))),
			WS_CHILD|WS_VISIBLE|BS_AUTOCHECKBOX,
			uintptr(cX), uintptr(cY), uintptr(colW-12), uintptr(rowH-4),
			hwndSetup, uintptr(IDC_LANG_CHK_BASE+i), hInstance, 0,
		)
		procSendMessageW.Call(chkHwnd, WM_SETFONT, hFontNormal, 1)

		if hasLang(lang.Code) {
			procSendMessageW.Call(chkHwnd, 0x00F1, 1, 0)
		}
		langCheckHWnd[lang.Code] = chkHwnd
	}

	// 5. Action Buttons (Save, Dictionary)
	btnSave, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsSave))),
		WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON,
		24, 480, 380, 46, hwndSetup, uintptr(IDC_BTN_SAVE), hInstance, 0,
	)
	procSendMessageW.Call(btnSave, WM_SETFONT, hFontBold, 1)

	btnDict, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr(ui.SettingsDict))),
		WS_CHILD|WS_VISIBLE,
		424, 480, 380, 46, hwndSetup, uintptr(IDC_BTN_DICT), hInstance, 0,
	)
	procSendMessageW.Call(btnDict, WM_SETFONT, hFontNormal, 1)

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
		go toggleRecording()
	case cmdID == IDM_SETUP_KEY || cmdID == IDM_OPEN_CONFIG:
		showSettingsDialog()
	case cmdID >= IDM_UI_LANG_BASE && cmdID < IDM_UI_LANG_BASE+uintptr(len(UILanguages)):
		idx := int(cmdID - IDM_UI_LANG_BASE)
		if idx >= 0 && idx < len(UILanguages) {
			config.UILanguage = UILanguages[idx].Code
			saveConfig()
			ui := getUI()
			updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))
		}
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
	case cmdID == IDM_LINK_FOLDER:
		folder := pickFolderNative(hwndMain)
		if folder != "" {
			count := linkKnowledgeFolder(folder)
			config.LinkedKnowledgeFolder = folder
			saveConfig()
			msg := fmt.Sprintf("Successfully linked!\nFolder: %s\nNew terms added to dictionary: %d", folder, count)
			procMessageBoxW.Call(
				0,
				uintptr(unsafe.Pointer(strPtr(msg))),
				uintptr(unsafe.Pointer(strPtr(AppTitle+" - Folder Linked"))),
				0x00000040,
			)
		}
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
	case WM_TRAYICON:
		if lParam == WM_RBUTTONUP {
			showContextMenu()
		} else if lParam == WM_LBUTTONDBLCLK {
			go toggleRecording()
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
		procSetTextColor.Call(hdc, 0x00F8FAFC)
		procSetBkColor.Call(hdc, 0x0018110D)
		return hBrushDarkBg
	case WM_CTLCOLOREDIT:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x00F8E500)
		procSetBkColor.Call(hdc, 0x00261D12)
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
					r, _, _ := procSendMessageW.Call(chkHwnd, 0x00F0, 0, 0)
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
			ui := getUI()
			updateTrayState(false, fmt.Sprintf("%s | %s (%s)", AppTitle, ui.Ready, config.Hotkey))
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
					uintptr(unsafe.Pointer(strPtr(AppTitle+" - API Key Test"))),
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
		}
	case WM_CLOSE:
		procShowWindow.Call(hwnd, SW_HIDE)
		initTrayIcon()
		return 0
	}
	r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return r
}

func hudWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_CTLCOLORSTATIC:
		hdc := wParam
		procSetTextColor.Call(hdc, 0x0000E5FF) // Vibrant Cyan #00E5FF
		procSetBkColor.Call(hdc, 0x00111827)
		return hBrushDarkBg
	default:
		r, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
		return r
	}
}

func initHUD() {
	screenWidth, _, _ := procGetSystemMetrics.Call(0)
	hudWidth := int32(480)
	hudHeight := int32(50)
	hudX := (int32(screenWidth) - hudWidth) / 2
	hudY := int32(24)

	hInstance, _, _ := procGetModuleHandleW.Call(0)
	className := strPtr("GIN_VOICE_HUD_CLASS")

	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpfnWndProc = syscall.NewCallback(hudWndProc)
	wc.HInstance = hInstance
	wc.HbrBackground = hBrushDarkBg
	wc.LpszClassName = className
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hwndHUD, _, _ = procCreateWindowExW.Call(
		WS_EX_TOPMOST|WS_EX_TOOLWINDOW,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("GIN-Voice HUD"))),
		WS_POPUP,
		uintptr(hudX), uintptr(hudY), uintptr(hudWidth), uintptr(hudHeight),
		0, 0, hInstance, 0,
	)

	hwndHUDText, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Ready"))),
		WS_CHILD|WS_VISIBLE,
		16, 12, uintptr(hudWidth-32), 26,
		hwndHUD, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndHUDText, WM_SETFONT, hFontHUD, 1)
}

func startHotkeyListener() {
	go func() {
		var wasPressed bool
		var lastToggle time.Time
		for {
			time.Sleep(15 * time.Millisecond)
			vk := config.HotkeyVK
			if vk == 0 {
				vk = VK_F8
			}

			state, _, _ := procGetAsyncKeyState.Call(uintptr(vk))
			isDown := (state & 0x8000) != 0

			if isDown && !wasPressed {
				wasPressed = true
				if time.Since(lastToggle) > 300*time.Millisecond {
					lastToggle = time.Now()
					writeLog(fmt.Sprintf("Hardware hotkey press: [%s] (VK %d)", config.Hotkey, vk))
					go toggleRecording()
				}
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
    Copy-Item -Path '%s' -Destination 'D:\MEGA\DOCS\desktop\GIN-Voice_Setup_v009.exe' -Force -ErrorAction SilentlyContinue
}
`, exePath, targetDir, icoPath, exePath, targetDir, icoPath, exePath, targetDir, icoPath, exePath)

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
	_ = copyFile(currExe, filepath.Join(targetDir, "GIN-Voice_v009.exe"))

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
	checkAndSelfInstall()

	exePath, _ := os.Executable()
	appDir = filepath.Dir(exePath)
	configFile = filepath.Join(appDir, "config.json")
	dictFile = filepath.Join(appDir, "dictionary.json")
	helpFile = filepath.Join(appDir, "setup_guide.html")
	logFile = filepath.Join(appDir, "gin_voice.log")

	writeLog("=== GIN-Voice [v009] Starting ===")

	loadConfig()
	loadDictionary()
	loadIcons()

	bDark, _, _ := procCreateSolidBrush.Call(0x0018110D)
	hBrushDarkBg = bDark
	bEdit, _, _ := procCreateSolidBrush.Call(0x00261D12)
	hBrushEditBg = bEdit

	hFontNormal, _, _ = procCreateFontW.Call(
		19, 0, 0, 0, 400, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontBold, _, _ = procCreateFontW.Call(
		20, 0, 0, 0, 700, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontHeader, _, _ = procCreateFontW.Call(
		21, 0, 0, 0, 700, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)
	hFontHUD, _, _ = procCreateFontW.Call(
		21, 0, 0, 0, 700, 0, 0, 0,
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
	)

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

	initHUD()
	startHotkeyListener()

	apiKey := strings.TrimSpace(config.GroqAPIKey)
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

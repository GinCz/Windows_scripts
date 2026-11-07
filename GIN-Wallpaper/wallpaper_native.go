package main

import (
	_ "embed"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"math"
	_ "image/png"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"

	"github.com/golang/freetype/truetype"
	"golang.org/x/image/font"
	"golang.org/x/image/math/fixed"
	xdraw "golang.org/x/image/draw"
)

//go:embed font.ttf
var embeddedFontBytes []byte

//go:embed app.ico
var embeddedAppICO []byte

var (
	user32                    = syscall.NewLazyDLL("user32.dll")
	shell32                   = syscall.NewLazyDLL("shell32.dll")
	kernel32                  = syscall.NewLazyDLL("kernel32.dll")
	gdi32                     = syscall.NewLazyDLL("gdi32.dll")
	winmm                     = syscall.NewLazyDLL("winmm.dll")
	procPlaySoundW            = winmm.NewProc("PlaySoundW")
	procSystemParametersInfoW = user32.NewProc("SystemParametersInfoW")
	procGetSystemMetrics      = user32.NewProc("GetSystemMetrics")
	procShell_NotifyIconW     = shell32.NewProc("Shell_NotifyIconW")
	procCreateWindowExW       = user32.NewProc("CreateWindowExW")
	procDefWindowProcW        = user32.NewProc("DefWindowProcW")
	procRegisterClassExW      = user32.NewProc("RegisterClassExW")
	procGetMessageW           = user32.NewProc("GetMessageW")
	procTranslateMessage      = user32.NewProc("TranslateMessage")
	procDispatchMessageW      = user32.NewProc("DispatchMessageW")
	procCreatePopupMenu       = user32.NewProc("CreatePopupMenu")
	procAppendMenuW           = user32.NewProc("AppendMenuW")
	procTrackPopupMenu        = user32.NewProc("TrackPopupMenu")
	procDestroyMenu           = user32.NewProc("DestroyMenu")
	procGetCursorPos          = user32.NewProc("GetCursorPos")
	procSetForegroundWindow   = user32.NewProc("SetForegroundWindow")
	procPostQuitMessage       = user32.NewProc("PostQuitMessage")
	procShowWindow            = user32.NewProc("ShowWindow")
	procDestroyWindow         = user32.NewProc("DestroyWindow")
	procSendMessageW          = user32.NewProc("SendMessageW")
	procLoadImageW            = user32.NewProc("LoadImageW")
	procGetModuleHandleW      = kernel32.NewProc("GetModuleHandleW")
	procSetProcessWorkingSetSize = kernel32.NewProc("SetProcessWorkingSetSize")
	procGetCurrentProcess        = kernel32.NewProc("GetCurrentProcess")
	procShellExecuteW         = shell32.NewProc("ShellExecuteW")
	procSetWindowTextW        = user32.NewProc("SetWindowTextW")
	procGetClientRect         = user32.NewProc("GetClientRect")
	procInvalidateRect        = user32.NewProc("InvalidateRect")
	procDrawTextW             = user32.NewProc("DrawTextW")
	procMessageBoxW           = user32.NewProc("MessageBoxW")
	procEnableWindow          = user32.NewProc("EnableWindow")
	procIsWindowEnabled       = user32.NewProc("IsWindowEnabled")

	procCreateFontW           = gdi32.NewProc("CreateFontW")
	procCreateSolidBrush      = gdi32.NewProc("CreateSolidBrush")
	procDeleteObject          = gdi32.NewProc("DeleteObject")
	procSelectObject          = gdi32.NewProc("SelectObject")
	procSetBkMode             = gdi32.NewProc("SetBkMode")
	procSetTextColor          = gdi32.NewProc("SetTextColor")
	procFillRect              = user32.NewProc("FillRect")
	procCreatePen             = gdi32.NewProc("CreatePen")
	procRectangle             = gdi32.NewProc("Rectangle")
	procGetStockObject        = gdi32.NewProc("GetStockObject")
	procSetWindowLongPtrW     = user32.NewProc("SetWindowLongPtrW")
	procCallWindowProcW       = user32.NewProc("CallWindowProcW")
	procGetWindowTextW        = user32.NewProc("GetWindowTextW")
	procGetTextExtentPoint32W = gdi32.NewProc("GetTextExtentPoint32W")
	procMoveToEx              = gdi32.NewProc("MoveToEx")
	procLineTo                = gdi32.NewProc("LineTo")
	procGetDC                 = user32.NewProc("GetDC")
	procReleaseDC             = user32.NewProc("ReleaseDC")
)

type SIZE struct {
	CX int32
	CY int32
}

const (
	AppVersion = "v025"

	SS_CENTER = 0x00000001

	SPI_SETDESKWALLPAPER = 0x0014
	SPIF_UPDATEINIFILE   = 0x0001
	SPIF_SENDCHANGE      = 0x0002

	WM_USER          = 0x0400
	WM_TRAYICON      = 0x8001
	WM_COMMAND       = 0x0111
	WM_LBUTTONUP     = 0x0202
	WM_LBUTTONDBLCLK = 0x0203
	WM_RBUTTONUP     = 0x0205
	WM_CONTEXTMENU   = 0x007B
	WM_CLOSE         = 0x0010
	WM_SETFONT       = 0x0030
	WM_SETICON       = 0x0080
	WM_ERASEBKGND    = 0x0014
	WM_CTLCOLORSTATIC= 0x0138
	WM_CTLCOLORBTN   = 0x0135
	WM_DRAWITEM      = 0x002B

	NIM_ADD    = 0x00000000
	NIM_MODIFY = 0x00000001
	NIM_DELETE = 0x00000002

	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x0800
	TPM_RIGHTBUTTON = 0x0002

	IDM_CHANGE_NOW    = 1001
	IDM_SETTINGS      = 1002
	IDM_OPEN_DIR      = 1003
	IDM_VERSION_CHECK = 1004
	IDM_EXIT          = 1005

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_GROUP            = 0x00020000
	WS_TABSTOP          = 0x00010000
	BS_AUTORADIOBUTTON  = 0x00000009
	BS_AUTOCHECKBOX     = 0x00000003
	BS_OWNERDRAW        = 0x0000000B
	BM_SETCHECK         = 0x00F1
	BM_GETCHECK         = 0x00F0
	BST_CHECKED         = 0x0001
	BST_UNCHECKED       = 0x0000

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x00000010
	LR_DEFAULTSIZE  = 0x00000040
	LR_SHARED       = 0x00008000

	ThemeModeDay     = 0
	ThemeModeEvening = 1
	ThemeModeNight   = 2

	MB_OK          = 0x00000000
	MB_YESNO       = 0x00000004
	MB_ICONINFO    = 0x00000040
	MB_ICONWARN    = 0x00000030
	IDYES          = 6
)

type Config struct {
	Themes        []string `json:"themes"`
	Theme         string   `json:"theme,omitempty"`
	IntervalHours int      `json:"interval_hours"`
	FontSizeScale float64  `json:"font_size_scale"`
	FontStyle     string   `json:"font_style"`
	ThemeMode     int      `json:"theme_mode"`
	Lang          string   `json:"lang"`
	SoundMuted    bool     `json:"sound_muted"`
}

type RemoteVersionInfo struct {
	Version     string `json:"version"`
	Name        string `json:"name"`
	Installer   string `json:"installer"`
	DownloadURL string `json:"download_url"`
}

type NOTIFYICONDATAW struct {
	CbSize            uint32
	Hwnd              syscall.Handle
	UID               uint32
	UFlags            uint32
	UCallbackMessage  uint32
	HIcon             syscall.Handle
	SzTip             [128]uint16
	DwState           uint32
	DwStateMask       uint32
	SzInfo            [256]uint16
	UTimeoutOrVersion uint32
	SzInfoTitle       [64]uint16
	DwInfoFlags       uint32
	GuidItem          [16]byte
	HBalloonIcon      syscall.Handle
}

type WNDCLASSEXW struct {
	CbSize        uint32
	Style         uint32
	LpfnWndProc   uintptr
	CbClsExtra    int32
	CbWndExtra    int32
	HInstance     syscall.Handle
	HIcon         syscall.Handle
	HCursor       syscall.Handle
	HbrBackground syscall.Handle
	LpszMenuName  *uint16
	LpszClassName *uint16
	HIconSm       syscall.Handle
}

type MSG struct {
	Hwnd    syscall.Handle
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      POINT
}

type POINT struct {
	X int32
	Y int32
}

type RECT struct {
	Left   int32
	Top    int32
	Right  int32
	Bottom int32
}

type DRAWITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     uint32
	ItemAction uint32
	ItemState  uint32
	HwndItem   syscall.Handle
	HDC        syscall.Handle
	RcItem     RECT
	ItemData   uintptr
}

var (
	nid          NOTIFYICONDATAW
	hwndTray     syscall.Handle
	hwndSettings syscall.Handle
	hIconApp     syscall.Handle
	appDataDir   string
	cfg          Config
	parsedFont   *truetype.Font

	wallpaperMutex sync.Mutex
	lastWallFile   string

	// Brushes for window background
	hBrushDay     syscall.Handle
	hBrushEvening syscall.Handle
	hBrushNight   syscall.Handle

	// Brushes for neat horizontal dividers
	hBrushDayLine     syscall.Handle
	hBrushEveningLine syscall.Handle
	hBrushNightLine   syscall.Handle

	// Fonts for UI
	hUIFont     syscall.Handle
	hUIFontBold syscall.Handle
	hUIFontSm   syscall.Handle

	// 12 Distinct HFONTs for font samples
	hFontSegoe      syscall.Handle
	hFontBahn       syscall.Handle
	hFontArial      syscall.Handle
	hFontVerdana    syscall.Handle
	hFontGeorgia    syscall.Handle
	hFontCorbel     syscall.Handle
	hFontConsolas   syscall.Handle
	hFontTreb       syscall.Handle
	hFontCambria    syscall.Handle
	hFontGothic     syscall.Handle
	hFontCandara    syscall.Handle
	hFontConstantia syscall.Handle
	hFontBigPrev    syscall.Handle
	hUIFontStrike   syscall.Handle
	hFontScale1     syscall.Handle
	hFontScale2     syscall.Handle
	hFontScale3     syscall.Handle
	hFontScale4     syscall.Handle

	// Section Dividers (Thin neat horizontal lines)
	divThemes   syscall.Handle
	divInterval syscall.Handle
	divFonts    syscall.Handle
	divScale    syscall.Handle
	divBottom   syscall.Handle

	// Controls
	lblTitle       syscall.Handle
	lblSecThemes   syscall.Handle
	lblSecInt      syscall.Handle
	lblSecFonts    syscall.Handle
	lblSecScale    syscall.Handle
	lblStatusInfo  syscall.Handle
	hwndPreviewBox syscall.Handle

	// Top Bar Buttons & Separators
	btnModeDay, btnModeEvening, btnModeNight syscall.Handle
	lblSep1, lblSep2                         syscall.Handle
	btnLangRU, btnLangEN, btnLangCS          syscall.Handle
	btnSound                                 syscall.Handle

	// Checkboxes - Themes (14)
	cbAll, cb3DAbstract, cbFlowers, cbOcean, cbSpace, cbNature, cbAnimals syscall.Handle
	cbCars, cbTrucksOffroad, cbGirls, cbCity, cbCyberpunk, cbMinimal, cbAnime syscall.Handle

	// Buttons - Intervals (4 buttons matching bottom action buttons style)
	btnInt1h, btnInt3h, btnInt6h, btnInt24h syscall.Handle

	// Radio buttons - Font styles (12 fonts in 2 columns, single-line format)
	rbFontSegoe, rbFontBahn, rbFontArial, rbFontVerdana, rbFontGeorgia, rbFontCorbel, rbFontPalatino, rbFontFranklin syscall.Handle
	rbFontConsolas, rbFontTreb, rbFontCambria, rbFontGothic, rbFontCandara, rbFontConstantia, rbFontSegoePrint, rbFontCalibri syscall.Handle

	hFontPalatino   syscall.Handle
	hFontFranklin   syscall.Handle
	hFontSegoePrint syscall.Handle
	hFontCalibri   syscall.Handle

	// Buttons - Font scale (4 buttons: Compact, Moderate, Standard, Large with font size sample)
	btnScaleCompact, btnScaleModerate, btnScaleStandard, btnScaleLarge syscall.Handle

	// Action buttons (Bottom)
	btnApply, btnSave, btnRandom, btnClose syscall.Handle
	btnFooterAuthor, btnFooterUpdate      syscall.Handle

	origCheckboxProc uintptr
	footerUpdateText string

	ruMonths = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	enMonths = []string{"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
	csMonths = []string{"", "ledna", "února", "března", "dubna", "května", "června", "července", "srpna", "září", "října", "listopadu", "prosince"}
	ruDays   = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
	enDays   = []string{"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
	csDays   = []string{"Po", "Út", "St", "Čt", "Pá", "So", "Ne"}
	ruFullDays = []string{"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
	enFullDays = []string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
	csFullDays = []string{"Neděle", "Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota"}
)

func strPtr(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func rgb(r, g, b uint32) uint32 {
	return (r & 0xFF) | ((g & 0xFF) << 8) | ((b & 0xFF) << 16)
}

func isRu() bool {
	return cfg.Lang == "ru"
}

func isCs() bool {
	return cfg.Lang == "cs"
}

func loadConfig() {
	cfg = Config{
		Themes:        []string{"all"},
		Theme:         "all",
		IntervalHours: 3,
		FontSizeScale: 2.0,
		FontStyle:     "segoe",
		ThemeMode:     ThemeModeEvening,
		Lang:          "en",
	}
	cfgFile := filepath.Join(appDataDir, "config.json")
	data, err := os.ReadFile(cfgFile)
	if err == nil {
		json.Unmarshal(data, &cfg)
	}
	if cfg.IntervalHours <= 0 {
		cfg.IntervalHours = 3
	}
	if cfg.FontSizeScale <= 0 {
		cfg.FontSizeScale = 2.0
	}
	if cfg.FontStyle == "" {
		cfg.FontStyle = "segoe"
	}
	if len(cfg.Themes) == 0 {
		if cfg.Theme != "" && cfg.Theme != "all" {
			if cfg.Theme == "windows" || cfg.Theme == "linux" {
				cfg.Themes = []string{"all"}
			} else if cfg.Theme == "abstract" || cfg.Theme == "fractal" {
				cfg.Themes = []string{"3d_abstract"}
			} else {
				cfg.Themes = []string{cfg.Theme}
			}
		} else {
			cfg.Themes = []string{"all"}
		}
	}
	if cfg.Theme == "" {
		cfg.Theme = cfg.Themes[0]
	}
	if cfg.Lang == "" {
		cfg.Lang = "en"
	}
}

func saveConfig() {
	cfgFile := filepath.Join(appDataDir, "config.json")
	data, _ := json.MarshalIndent(cfg, "", "  ")
	os.WriteFile(cfgFile, data, 0644)
}

func setWallpaperWin(path string) error {
	pUTF16, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return err
	}
	r, _, err := procSystemParametersInfoW.Call(
		SPI_SETDESKWALLPAPER,
		0,
		uintptr(unsafe.Pointer(pUTF16)),
		SPIF_UPDATEINIFILE|SPIF_SENDCHANGE,
	)
	if r == 0 {
		return err
	}
	return nil
}

func getRealScreenResolution() (int, int) {
	w, _, _ := procGetSystemMetrics.Call(0) // SM_CXSCREEN
	h, _, _ := procGetSystemMetrics.Call(1) // SM_CYSCREEN
	if w <= 0 || h <= 0 {
		return 1920, 1080
	}
	return int(w), int(h)
}

func getScreenResolution() (int, int) {
	return getRealScreenResolution()
}

func fitAndScaleToScreen(src image.Image, targetW, targetH int) *image.RGBA {
	srcBounds := src.Bounds()
	sw := srcBounds.Dx()
	sh := srcBounds.Dy()

	targetRatio := float64(targetW) / float64(targetH)
	srcRatio := float64(sw) / float64(sh)

	var cropRect image.Rectangle
	if srcRatio > targetRatio {
		// Wider -> crop left and right
		cropW := int(float64(sh) * targetRatio)
		cropX0 := srcBounds.Min.X + (sw-cropW)/2
		cropRect = image.Rect(cropX0, srcBounds.Min.Y, cropX0+cropW, srcBounds.Max.Y)
	} else {
		// Taller -> crop top and bottom
		cropH := int(float64(sw) / targetRatio)
		cropY0 := srcBounds.Min.Y + (sh-cropH)/2
		cropRect = image.Rect(srcBounds.Min.X, cropY0, srcBounds.Max.X, cropY0+cropH)
	}

	dst := image.NewRGBA(image.Rect(0, 0, targetW, targetH))
	xdraw.BiLinear.Scale(dst, dst.Bounds(), src, cropRect, xdraw.Over, nil)
	return dst
}

func ensureWallpaperStyleRegistry() {
	exec.Command("reg", "add", `HKCU\Control Panel\Desktop`, "/v", "WallpaperStyle", "/t", "REG_SZ", "/d", "10", "/f").Run()
	exec.Command("reg", "add", `HKCU\Control Panel\Desktop`, "/v", "TileWallpaper", "/t", "REG_SZ", "/d", "0", "/f").Run()
}

type WallhavenResp struct {
	Data []struct {
		Path       string `json:"path"`
		Resolution string `json:"resolution"`
	} `json:"data"`
}

func getSingleThemeQuery(theme string) string {
	switch theme {
	case "3d_abstract", "abstract", "fractal":
		queries := []string{"3d render", "fractal", "abstract 3d", "texture 3d"}
		return queries[rand.Intn(len(queries))]
	case "flowers":
		queries := []string{"flowers", "roses", "blossom", "floral"}
		return queries[rand.Intn(len(queries))]
	case "ocean":
		queries := []string{"ocean", "sea waves", "beach sunset", "tropical coast"}
		return queries[rand.Intn(len(queries))]
	case "space":
		return "space"
	case "nature":
		return "nature"
	case "animals":
		return "wildlife"
	case "cars":
		queries := []string{"supercar", "sports car", "luxury supercar", "hypercar"}
		return queries[rand.Intn(len(queries))]
	case "trucks_offroad", "trucks", "offroad":
		queries := []string{"truck", "semi truck", "off-road 4x4", "suv off-road", "pickup truck", "overland vehicle"}
		return queries[rand.Intn(len(queries))]
	case "girls", "portraits", "women", "models", "fashion":
		queries := []string{"fashion model woman", "fashion photography woman", "high fashion portrait", "aesthetic model portrait", "beauty fashion editorial", "glamour portrait woman"}
		return queries[rand.Intn(len(queries))]
	case "city":
		return "city"
	case "cyberpunk":
		return "cyberpunk"
	case "minimalism":
		return "minimalism"
	case "anime":
		return "anime"
	default:
		all := []string{"3d render", "fractal", "abstract 3d", "flowers", "ocean", "space", "nature", "wildlife", "supercar", "motorcycle", "off-road 4x4", "portrait woman", "city", "cyberpunk", "minimalism", "anime"}
		return all[rand.Intn(len(all))]
	}
}

func getThemeQuery() string {
	selected := cfg.Themes
	if len(selected) == 0 || (len(selected) == 1 && selected[0] == "all") {
		all := []string{"3d_abstract", "flowers", "ocean", "space", "nature", "animals", "cars", "trucks_offroad", "girls", "city", "cyberpunk", "minimalism", "anime"}
		return getSingleThemeQuery(all[rand.Intn(len(all))])
	}
	choice := selected[rand.Intn(len(selected))]
	return getSingleThemeQuery(choice)
}

func downloadRandomWallpaper(w, h int) (image.Image, error) {
	client := &http.Client{Timeout: 15 * time.Second}
	themeQuery := getThemeQuery()

	// Stage 1: Wallhaven 4K UHD Query (3840x2160 minimum)
	wallhavenUrl := fmt.Sprintf("https://wallhaven.cc/api/v1/search?q=%s&atleast=3840x2160&sorting=random&purity=100",
		url.QueryEscape(themeQuery))
	resp, err := client.Get(wallhavenUrl)
	if err == nil && resp.StatusCode == http.StatusOK {
		var whResp WallhavenResp
		if json.NewDecoder(resp.Body).Decode(&whResp) == nil && len(whResp.Data) > 0 {
			resp.Body.Close()
			idx := rand.Intn(len(whResp.Data))
			imgUrl := whResp.Data[idx].Path
			imgResp, err := client.Get(imgUrl)
			if err == nil && imgResp.StatusCode == http.StatusOK {
				defer imgResp.Body.Close()
				if img, _, err := image.Decode(imgResp.Body); err == nil {
					return img, nil
				}
			}
		} else {
			resp.Body.Close()
		}
	}

	// Fallback to 2560x1440 if Wallhaven 4K search returns 0 results
	wallhavenUrl2 := fmt.Sprintf("https://wallhaven.cc/api/v1/search?q=%s&atleast=2560x1440&sorting=random&purity=100",
		url.QueryEscape(themeQuery))
	resp2, err := client.Get(wallhavenUrl2)
	if err == nil && resp2.StatusCode == http.StatusOK {
		var whResp WallhavenResp
		if json.NewDecoder(resp2.Body).Decode(&whResp) == nil && len(whResp.Data) > 0 {
			resp2.Body.Close()
			idx := rand.Intn(len(whResp.Data))
			imgUrl := whResp.Data[idx].Path
			imgResp, err := client.Get(imgUrl)
			if err == nil && imgResp.StatusCode == http.StatusOK {
				defer imgResp.Body.Close()
				if img, _, err := image.Decode(imgResp.Body); err == nil {
					return img, nil
				}
			}
		} else {
			resp2.Body.Close()
		}
	}

	// Stage 2: Picsum Fallback at Native 4K UHD (3840x2160)
	picsumUrl := "https://picsum.photos/3840/2160"
	respPic, err := client.Get(picsumUrl)
	if err == nil && respPic.StatusCode == http.StatusOK {
		defer respPic.Body.Close()
		if img, _, err := image.Decode(respPic.Body); err == nil {
			return img, nil
		}
	}

	// Stage 3: Emergency procedural wallpaper (Rich dark blue-violet gradient)
	fallbackImg := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		ratio := float64(y) / float64(h)
		r := uint8(15 + ratio*18)
		g := uint8(22 + ratio*28)
		b := uint8(45 + ratio*65)
		for x := 0; x < w; x++ {
			fallbackImg.Set(x, y, color.RGBA{r, g, b, 255})
		}
	}
	return fallbackImg, nil
}

func getFontForStyle(style string) *truetype.Font {
	winDir := os.Getenv("WINDIR")
	if winDir == "" {
		winDir = `C:\Windows`
	}
	fontsDir := filepath.Join(winDir, "Fonts")

	var fontFile string
	switch style {
	case "segoe":
		fontFile = filepath.Join(fontsDir, "segoeuib.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "segoeui.ttf")
		}
	case "bahn", "bahnschrift":
		fontFile = filepath.Join(fontsDir, "bahnschrift.ttf")
	case "arial":
		fontFile = filepath.Join(fontsDir, "arial.ttf")
	case "verdana":
		fontFile = filepath.Join(fontsDir, "verdana.ttf")
	case "consolas":
		fontFile = filepath.Join(fontsDir, "consolab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "consola.ttf")
		}
	case "trebuchet":
		fontFile = filepath.Join(fontsDir, "trebucbd.ttf")
	case "cambria", "impact":
		fontFile = filepath.Join(fontsDir, "cambriab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "cambria.ttc")
		}
	case "gothic":
		fontFile = filepath.Join(fontsDir, "gothicb.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "gothic.ttf")
		}
	case "georgia":
		fontFile = filepath.Join(fontsDir, "georgiab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "georgia.ttf")
		}
	case "corbel":
		fontFile = filepath.Join(fontsDir, "corbelb.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "corbel.ttf")
		}
	case "candara":
		fontFile = filepath.Join(fontsDir, "candarab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "candara.ttf")
		}
	case "constantia":
		fontFile = filepath.Join(fontsDir, "constanb.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "constan.ttf")
		}
	case "palatino":
		fontFile = filepath.Join(fontsDir, "palab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "pala.ttf")
		}
	case "franklin":
		fontFile = filepath.Join(fontsDir, "framd.ttf")
	case "segoeprint":
		fontFile = filepath.Join(fontsDir, "segoeprb.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "segoepr.ttf")
		}
	case "calibri":
		fontFile = filepath.Join(fontsDir, "calibrib.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "calibri.ttf")
		}
	default:
		fontFile = filepath.Join(fontsDir, "segoeuib.ttf")
	}

	if fontFile != "" {
		if data, err := os.ReadFile(fontFile); err == nil {
			if f, err := truetype.Parse(data); err == nil {
				return f
			}
		}
	}
	return parsedFont
}

func renderCalendarOverlay(bg image.Image) *image.RGBA {
	bounds := bg.Bounds()
	rgba := image.NewRGBA(bounds)
	draw.Draw(rgba, bounds, bg, bounds.Min, draw.Src)

	drawCalendar(rgba, time.Now(), cfg.FontSizeScale)
	return rgba
}

func drawCalendar(rgba *image.RGBA, now time.Time, userScale float64) {
	bounds := rgba.Bounds()
	if userScale <= 0 {
		userScale = 2.0
	}

	// Auto-scale with image resolution! On 4K (3840), resScale = 2.0
	imgW := float64(bounds.Dx())
	resScale := imgW / 1920.0
	if resScale < 1.0 {
		resScale = 1.0
	}
	scale := userScale * resScale

	calW := int(390.0 * (scale / 2.0))
	calH := int(246.0 * (scale / 2.0))
	margin := int(44.0 * (scale / 2.0))

	x0 := bounds.Dx() - calW - margin
	y0 := margin
	if x0 < 0 {
		x0 = 10
	}

	// 1. Semi-transparent backdrop (~85% opacity)
	for y := y0; y < y0+calH && y < bounds.Dy(); y++ {
		for x := x0; x < x0+calW && x < bounds.Dx(); x++ {
			orig := rgba.RGBAAt(x, y)
			bgR, bgG, bgB := 15, 18, 28
			alpha := 0.85
			newR := uint8(float64(bgR)*alpha + float64(orig.R)*(1.0-alpha))
			newG := uint8(float64(bgG)*alpha + float64(orig.G)*(1.0-alpha))
			newB := uint8(float64(bgB)*alpha + float64(orig.B)*(1.0-alpha))
			rgba.Set(x, y, color.RGBA{newR, newG, newB, 255})
		}
	}

	// Border
	borderColor := color.RGBA{130, 140, 180, 130}
	for x := x0; x < x0+calW && x < bounds.Dx(); x++ {
		rgba.Set(x, y0, borderColor)
		rgba.Set(x, y0+calH-1, borderColor)
	}
	for y := y0; y < y0+calH && y < bounds.Dy(); y++ {
		rgba.Set(x0, y, borderColor)
		rgba.Set(x0+calW-1, y, borderColor)
	}

	// Fonts
	fontToUse := getFontForStyle(cfg.FontStyle)
	if fontToUse == nil {
		fontToUse = parsedFont
	}

	titleSize := 24.0 * (scale / 2.0)
	titleFace := truetype.NewFace(fontToUse, &truetype.Options{
		Size:    titleSize,
		DPI:     72,
		Hinting: font.HintingFull,
	})

	daySize := 18.0 * (scale / 2.0)
	dayFace := truetype.NewFace(fontToUse, &truetype.Options{
		Size:    daySize,
		DPI:     72,
		Hinting: font.HintingFull,
	})

	// Title
	var title string
	if isCs() {
		title = fmt.Sprintf("%d. %s %d", now.Day(), csMonths[int(now.Month())], now.Year())
	} else if isRu() {
		title = fmt.Sprintf("%d %s %d г.", now.Day(), ruMonths[int(now.Month())], now.Year())
	} else {
		title = fmt.Sprintf("%d %s %d", now.Day(), enMonths[int(now.Month())], now.Year())
	}

	titleDrawer := &font.Drawer{
		Dst:  rgba,
		Src:  image.NewUniform(color.RGBA{255, 255, 255, 255}),
		Face: titleFace,
		Dot:  fixed.P(x0+int(20*(scale/2.0)), y0+int(36*(scale/2.0))),
	}
	titleDrawer.DrawString(title)

	// Days of week header
	colW := float64(calW-int(40*(scale/2.0))) / 7.0
	headerY := y0 + int(68*(scale/2.0))

	yellowWeekend := color.RGBA{255, 230, 0, 255}
	whiteWeekday := color.RGBA{220, 225, 235, 255}

	daysHeader := enDays
	if isCs() {
		daysHeader = csDays
	} else if isRu() {
		daysHeader = ruDays
	}

	for i, day := range daysHeader {
		dx := x0 + int(20*(scale/2.0)) + int(float64(i)*colW)
		c := whiteWeekday
		if i >= 5 {
			c = yellowWeekend
		}
		d := &font.Drawer{
			Dst:  rgba,
			Src:  image.NewUniform(c),
			Face: dayFace,
			Dot:  fixed.P(dx, headerY),
		}
		d.DrawString(day)
	}

	// Days grid
	year, month, _ := now.Date()
	firstDay := time.Date(year, month, 1, 0, 0, 0, 0, time.Local)
	startCol := (int(firstDay.Weekday()) + 6) % 7
	daysInMonth := time.Date(year, month+1, 0, 0, 0, 0, 0, time.Local).Day()

	curCol := startCol
	curRow := 0
	rowH := int(26 * (scale / 2.0))
	gridStartY := headerY + int(28*(scale/2.0))

	today := now.Day()
	for day := 1; day <= daysInMonth; day++ {
		dx := x0 + int(20*(scale/2.0)) + int(float64(curCol)*colW)
		dy := gridStartY + curRow*rowH

		if day == today {
			badgePad := int(4 * (scale / 2.0))
			badgeW := int(24 * (scale / 2.0))
			badgeH := int(20 * (scale / 2.0))
			bx0 := dx - badgePad
			by0 := dy - int(15*(scale/2.0))
			badgeColor := color.RGBA{61, 90, 254, 235}
			for by := by0; by < by0+badgeH && by < bounds.Dy(); by++ {
				for bx := bx0; bx < bx0+badgeW && bx < bounds.Dx(); bx++ {
					rgba.Set(bx, by, badgeColor)
				}
			}
		}

		dayColor := color.RGBA{255, 255, 255, 255}
		if curCol >= 5 && day != today {
			dayColor = yellowWeekend
		}

		str := fmt.Sprintf("%d", day)
		d := &font.Drawer{
			Dst:  rgba,
			Src:  image.NewUniform(dayColor),
			Face: dayFace,
			Dot:  fixed.P(dx, dy),
		}
		d.DrawString(str)

		curCol++
		if curCol > 6 {
			curCol = 0
			curRow++
		}
	}
}


const (
	SND_SYNC   = 0x00000000
	SND_ASYNC  = 0x00000001
	SND_NODEFAULT = 0x00000002
	SND_MEMORY = 0x00000004
)

var (
	chimeWAVBytes      []byte
	updateDropWAVBytes []byte
	suppressNextChime  bool
)

func initAudioBuffers() {
	if len(chimeWAVBytes) == 0 {
		chimeWAVBytes = generateChimeWAV()
	}
	if len(updateDropWAVBytes) == 0 {
		updateDropWAVBytes = generateUpdateDropWAV()
	}
}

// Generates an extra-soft, warm, quiet celestial shimmer (peaceful velvet bells)
func generateChimeWAV() []byte {
	sampleRate := 22050
	duration := 1.2
	totalSamples := int(float64(sampleRate) * duration)
	notes := []struct {
		freq, start, decay, vol float64
	}{
		{369.99, 0.00, 1.1, 0.20}, // F#4
		{466.16, 0.06, 1.2, 0.18}, // A#4
		{554.37, 0.12, 1.3, 0.16}, // C#5
		{698.46, 0.18, 1.4, 0.14}, // F5
	}
	samples := make([]float64, totalSamples)
	for _, n := range notes {
		sIdx := int(n.start * float64(sampleRate))
		for i := sIdx; i < totalSamples; i++ {
			t := float64(i-sIdx) / float64(sampleRate)
			attack := t / 0.040
			if attack > 1.0 {
				attack = 1.0
			}
			env := attack * math.Exp(-t*(3.2/n.decay))
			val := math.Sin(2.0*math.Pi*n.freq*t)
			samples[i] += val * env * n.vol
		}
	}
	maxVal := 0.0
	for _, s := range samples {
		if math.Abs(s) > maxVal {
			maxVal = math.Abs(s)
		}
	}
	if maxVal == 0.0 {
		maxVal = 1.0
	}
	// Gentle, quiet scale amplitude (6000 instead of 22000)
	return buildWAV16Mono(sampleRate, samples, maxVal, 6000)
}

// Generates an extra-soft, warm, quiet double water-bubble / drop ("буль-буль" / "бум-бум")
func generateUpdateDropWAV() []byte {
	sampleRate := 22050
	duration := 0.60
	totalSamples := int(float64(sampleRate) * duration)
	samples := make([]float64, totalSamples)

	// Two gentle, low-mid acoustic water bloops:
	// Bloop 1: 0.00s, starts at ~220Hz (A3) gently rising to ~270Hz (soft round bubble)
	// Bloop 2: 0.16s, starts at ~293Hz (D4) gently rising to ~360Hz (warm second bubble)
	drops := []struct {
		startFreq, endFreq float64
		startSec, durSec   float64
		vol                float64
	}{
		{220.0, 275.0, 0.00, 0.24, 0.45},
		{293.66, 360.0, 0.15, 0.32, 0.50},
	}

	for _, d := range drops {
		sIdx := int(d.startSec * float64(sampleRate))
		eIdx := int((d.startSec + d.durSec) * float64(sampleRate))
		if eIdx > totalSamples {
			eIdx = totalSamples
		}
		numS := eIdx - sIdx
		phase := 0.0
		for i := 0; i < numS; i++ {
			t := float64(i) / float64(sampleRate)
			progress := t / d.durSec

			// Organic bubble pitch curve: smooth sine ease-in
			currentFreq := d.startFreq + (d.endFreq-d.startFreq)*math.Sin(progress*math.Pi*0.5)
			phase += 2.0 * math.Pi * currentFreq / float64(sampleRate)

			// Velvet smooth attack: 28ms without any sharp clicks
			attack := t / 0.028
			if attack > 1.0 {
				attack = 1.0
			}
			// Warm exponential decay
			decay := math.Exp(-progress * 5.5)

			// Sine wave with subtle 15% second harmonic for warm organic resonance
			waveform := math.Sin(phase) + 0.15*math.Sin(2.0*phase)
			samples[sIdx+i] += waveform * attack * decay * d.vol
		}
	}

	maxVal := 0.0
	for _, s := range samples {
		if math.Abs(s) > maxVal {
			maxVal = math.Abs(s)
		}
	}
	if maxVal == 0.0 {
		maxVal = 1.0
	}
	// Identical soft, quiet volume level to the chime (6000 instead of 24000)
	return buildWAV16Mono(sampleRate, samples, maxVal, 6000)
}

func buildWAV16Mono(sampleRate int, samples []float64, maxVal float64, scaleAmp float64) []byte {
	totalSamples := len(samples)
	dataSize := totalSamples * 2
	buf := make([]byte, 44+dataSize)
	copy(buf[0:], "RIFF")
	binary.LittleEndian.PutUint32(buf[4:], uint32(36+dataSize))
	copy(buf[8:], "WAVE")
	copy(buf[12:], "fmt ")
	binary.LittleEndian.PutUint32(buf[16:], 16)
	binary.LittleEndian.PutUint16(buf[20:], 1) // PCM
	binary.LittleEndian.PutUint16(buf[22:], 1) // Mono
	binary.LittleEndian.PutUint32(buf[24:], uint32(sampleRate))
	binary.LittleEndian.PutUint32(buf[28:], uint32(sampleRate*2))
	binary.LittleEndian.PutUint16(buf[32:], 2) // block align
	binary.LittleEndian.PutUint16(buf[34:], 16) // bits
	copy(buf[36:], "data")
	binary.LittleEndian.PutUint32(buf[40:], uint32(dataSize))
	for i, s := range samples {
		val := int16((s / maxVal) * scaleAmp)
		binary.LittleEndian.PutUint16(buf[44+i*2:], uint16(val))
	}
	return buf
}

func playSoftChime() {
	if cfg.SoundMuted {
		return
	}
	go func() {
		initAudioBuffers()
		if len(chimeWAVBytes) > 0 {
			procPlaySoundW.Call(uintptr(unsafe.Pointer(&chimeWAVBytes[0])), 0, uintptr(SND_MEMORY|SND_SYNC|SND_NODEFAULT))
		}
	}()
}

func playUpdateSoftDrop() {
	if cfg.SoundMuted {
		return
	}
	go func() {
		initAudioBuffers()
		if len(updateDropWAVBytes) > 0 {
			procPlaySoundW.Call(uintptr(unsafe.Pointer(&updateDropWAVBytes[0])), 0, uintptr(SND_MEMORY|SND_SYNC|SND_NODEFAULT))
		}
	}()
}

func cycleWallpaper() {
	wallpaperMutex.Lock()
	defer wallpaperMutex.Unlock()

	w, h := getRealScreenResolution()
	rawImg, err := downloadRandomWallpaper(w, h)
	if err != nil {
		return
	}

	// 1. Scale/crop UHD image exactly to user's screen resolution
	screenImg := fitAndScaleToScreen(rawImg, w, h)

	// 2. Render calendar onto the top-right corner of the scaled screen image
	finalImg := renderCalendarOverlay(screenImg)

	// 3. Alternate between wallpaper_A.jpg and wallpaper_B.jpg to bypass Windows Desktop path caching!
	fileName := "wallpaper_A.jpg"
	if lastWallFile == "wallpaper_A.jpg" {
		fileName = "wallpaper_B.jpg"
	}
	lastWallFile = fileName

	outPath := filepath.Join(appDataDir, fileName)
	f, err := os.Create(outPath)
	if err == nil {
		jpeg.Encode(f, finalImg, &jpeg.Options{Quality: 98})
		f.Close()
		ensureWallpaperStyleRegistry()
		setWallpaperWin(outPath)
		if !suppressNextChime {
			playSoftChime()
		} else {
			suppressNextChime = false
		}
	}
	rawImg = nil
	screenImg = nil
	finalImg = nil
	trimMemory()
}

func trimMemory() {
	runtime.GC()
	debug.FreeOSMemory()
	h, _, _ := procGetCurrentProcess.Call()
	if h != 0 {
		procSetProcessWorkingSetSize.Call(h, ^uintptr(0), ^uintptr(0))
	}
}

func showContextMenu(hwnd syscall.Handle) {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	// 1. Change Wallpaper (Top)
	mChange := "🔄 Change Wallpaper"
	// 2. Settings (Second)
	mSettings := "⚙️ Settings"
	// 3. Open Program Folder
	mOpen := "📁 Open Program Folder"
	// 4. Version & Check Update
	mVer := fmt.Sprintf("ℹ️ %s (Check for Updates)", AppVersion)
	// 5. Exit
	mExit := "❌ Exit"

	if isCs() {
		mChange = "🔄 Změnit tapetu"
		mSettings = "⚙️ Nastavení"
		mOpen = "📁 Otevřít složku programu"
		mVer = fmt.Sprintf("ℹ️ %s (Zkontrolovat aktualizace)", AppVersion)
		mExit = "❌ Konec"
	} else if isRu() {
		mChange = "🔄 Сменить обои"
		mSettings = "⚙️ Настройки"
		mOpen = "📁 Открыть папку программы"
		mVer = fmt.Sprintf("ℹ️ %s (Проверить обновление)", AppVersion)
		mExit = "❌ Выход"
	}

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHANGE_NOW, uintptr(unsafe.Pointer(strPtr(mChange))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETTINGS, uintptr(unsafe.Pointer(strPtr(mSettings))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DIR, uintptr(unsafe.Pointer(strPtr(mOpen))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_VERSION_CHECK, uintptr(unsafe.Pointer(strPtr(mVer))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr(mExit))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(uintptr(hwnd))
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, uintptr(hwnd), 0)
	procDestroyMenu.Call(hMenu)
}

func triggerCheckForUpdates(manual bool) {
	go func() {
		if manual && btnFooterUpdate != 0 {
			chkMsg := "⏳ Checking..."
			if isCs() {
				chkMsg = "⏳ Kontrola..."
			} else if isRu() {
				chkMsg = "⏳ Проверка..."
			}
			footerUpdateText = chkMsg
			procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
		}

		url := fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/version.json?t=%d", time.Now().UnixNano())
		client := &http.Client{Timeout: 8 * time.Second}
		resp, err := client.Get(url)
		if err != nil {
			if manual && btnFooterUpdate != 0 {
				errMsg := "❌ Connection Error"
				if isCs() {
					errMsg = "❌ Chyba sítě"
				} else if isRu() {
					errMsg = "❌ Ошибка сети"
				}
				footerUpdateText = errMsg
				procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
				time.Sleep(3 * time.Second)
				footerUpdateText = ""
				procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
			}
			return
		}
		defer resp.Body.Close()

		var info RemoteVersionInfo
		if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
			return
		}

		remoteVer := strings.TrimSpace(info.Version)
		if remoteVer != "" && remoteVer != AppVersion {
			// Update available -> Instant silent background install without ANY popups!
			if manual && btnFooterUpdate != 0 {
				updMsg := fmt.Sprintf("🚀 Updating to %s...", remoteVer)
				if isCs() {
					updMsg = fmt.Sprintf("🚀 Aktualizace na %s...", remoteVer)
				} else if isRu() {
					updMsg = fmt.Sprintf("🚀 Загрузка %s...", remoteVer)
				}
				footerUpdateText = updMsg
				procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
			}
			downloadAndApplyUpdate(info.DownloadURL, info.Installer)
		} else if manual {
			// Up to date -> Display directly inside the button without popups!
			okMsg := fmt.Sprintf("✔️ Up to date (%s)", AppVersion)
			if isCs() {
				okMsg = fmt.Sprintf("✔️ Aktuální verze (%s)", AppVersion)
			} else if isRu() {
				okMsg = fmt.Sprintf("✔️ Актуальная версия (%s)", AppVersion)
			}
			footerUpdateText = okMsg
			procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
			playSoftChime()
			time.Sleep(4 * time.Second)
			footerUpdateText = ""
			if btnFooterUpdate != 0 {
				procInvalidateRect.Call(uintptr(btnFooterUpdate), 0, 1)
			}
		}
		trimMemory()
	}()
}

func downloadAndApplyUpdate(downUrl, installerName string) {
	if downUrl == "" {
		downUrl = fmt.Sprintf("https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/%s", installerName)
	}
	tmpExe := filepath.Join(os.TempDir(), installerName)
	resp, err := http.Get(downUrl)
	if err != nil {
		return
	}
	defer resp.Body.Close()

	out, err := os.Create(tmpExe)
	if err != nil {
		return
	}
	io.Copy(out, resp.Body)
	out.Close()

	// Cleanly hide settings window and remove tray icon before starting installer
	if hwndSettings != 0 {
		procDestroyWindow.Call(uintptr(hwndSettings))
		hwndSettings = 0
	}
	procShell_NotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))

	vPtr, _ := syscall.UTF16PtrFromString("runas")
	fPtr, _ := syscall.UTF16PtrFromString(tmpExe)
	aPtr, _ := syscall.UTF16PtrFromString("/SILENT")
	dPtr, _ := syscall.UTF16PtrFromString(os.TempDir())
	procShellExecuteW.Call(0, uintptr(unsafe.Pointer(vPtr)), uintptr(unsafe.Pointer(fPtr)), uintptr(unsafe.Pointer(aPtr)), uintptr(unsafe.Pointer(dPtr)), 1)
	os.Exit(0)
}

func initThemeBrushes() {
	if hBrushDay == 0 {
		bDay, _, _ := procCreateSolidBrush.Call(uintptr(rgb(244, 245, 248)))
		hBrushDay = syscall.Handle(bDay)
	}
	if hBrushEvening == 0 {
		bEve, _, _ := procCreateSolidBrush.Call(uintptr(rgb(45, 50, 62)))
		hBrushEvening = syscall.Handle(bEve)
	}
	if hBrushNight == 0 {
		bNight, _, _ := procCreateSolidBrush.Call(uintptr(rgb(18, 20, 26)))
		hBrushNight = syscall.Handle(bNight)
	}

	if hBrushDayLine == 0 {
		bDayL, _, _ := procCreateSolidBrush.Call(uintptr(rgb(214, 218, 226)))
		hBrushDayLine = syscall.Handle(bDayL)
	}
	if hBrushEveningLine == 0 {
		bEveL, _, _ := procCreateSolidBrush.Call(uintptr(rgb(72, 80, 98)))
		hBrushEveningLine = syscall.Handle(bEveL)
	}
	if hBrushNightLine == 0 {
		bNightL, _, _ := procCreateSolidBrush.Call(uintptr(rgb(46, 52, 68)))
		hBrushNightLine = syscall.Handle(bNightL)
	}
}

func initFonts() {
	if hUIFont == 0 {
		hF, _, _ := procCreateFontW.Call(uintptr(17), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hUIFont = syscall.Handle(hF)
	}
	if hUIFontBold == 0 {
		hFB, _, _ := procCreateFontW.Call(uintptr(18), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hUIFontBold = syscall.Handle(hFB)
	}
	if hUIFontSm == 0 {
		hFS, _, _ := procCreateFontW.Call(uintptr(14), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hUIFontSm = syscall.Handle(hFS)
	}

	// 12 Distinct Fonts for single-line radio previews
	makeFont := func(name string, weight int) syscall.Handle {
		h, _, _ := procCreateFontW.Call(uintptr(18), 0, 0, 0, uintptr(weight), 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr(name))))
		return syscall.Handle(h)
	}

	if hFontSegoe == 0 {
		hFontSegoe = makeFont("Segoe UI", 700)
	}
	if hFontBahn == 0 {
		hFontBahn = makeFont("Bahnschrift", 600)
	}
	if hFontArial == 0 {
		hFontArial = makeFont("Arial", 400) // Regular Arial
	}
	if hFontVerdana == 0 {
		hFontVerdana = makeFont("Verdana", 400) // Regular Verdana
	}
	if hFontGeorgia == 0 {
		hFontGeorgia = makeFont("Georgia", 700)
	}
	if hFontCorbel == 0 {
		hFontCorbel = makeFont("Corbel", 700)
	}
	if hFontConsolas == 0 {
		hFontConsolas = makeFont("Consolas", 700)
	}
	if hFontTreb == 0 {
		hFontTreb = makeFont("Trebuchet MS", 700)
	}
	if hFontCambria == 0 {
		hFontCambria = makeFont("Cambria", 700) // Elegant Cambria (replaces Impact)
	}
	if hFontGothic == 0 {
		hFontGothic = makeFont("Century Gothic", 700)
	}
	if hFontCandara == 0 {
		hFontCandara = makeFont("Candara", 700)
	}
	if hFontConstantia == 0 {
		hFontConstantia = makeFont("Constantia", 700)
	}
	if hFontPalatino == 0 {
		hFontPalatino = makeFont("Palatino Linotype", 700)
	}
	if hFontFranklin == 0 {
		hFontFranklin = makeFont("Franklin Gothic Medium", 600)
	}
	if hFontSegoePrint == 0 {
		hFontSegoePrint = makeFont("Segoe Print", 700)
	}
	if hFontCalibri == 0 {
		hFontCalibri = makeFont("Calibri", 700)
	}

	// Big Live Preview Font (22pt Bold)
	if hFontBigPrev == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(24), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontBigPrev = syscall.Handle(h)
	}

	// Strikethrough Font for disabled/inactive themes (Segoe UI 17px with StrikeOut=1)
	if hUIFontStrike == 0 {
		hFS, _, _ := procCreateFontW.Call(uintptr(17), 0, 0, 0, 400, 0, 0, 1, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hUIFontStrike = syscall.Handle(hFS)
	}

	// Scale Button Sample Fonts (4 distinct sizes)
	if hFontScale1 == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(14), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontScale1 = syscall.Handle(h)
	}
	if hFontScale2 == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(17), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontScale2 = syscall.Handle(h)
	}
	if hFontScale3 == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(20), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontScale3 = syscall.Handle(h)
	}
	if hFontScale4 == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(24), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontScale4 = syscall.Handle(h)
	}
}

func createSettingsWindow() {
	if hwndSettings != 0 {
		procShowWindow.Call(uintptr(hwndSettings), 1)
		procSetForegroundWindow.Call(uintptr(hwndSettings))
		return
	}

	initThemeBrushes()
	initFonts()

	screenW, screenH := getRealScreenResolution()
	winW, winH := 820, 790
	posX := 50
	posY := 20
	if posX+winW > screenW {
		posX = 10
	}
	if posY+winH > screenH {
		posY = 5
	}

	wTitle := fmt.Sprintf("GIN-Wallpaper-Calend %s — Settings & Themes", AppVersion)
	if isRu() {
		wTitle = fmt.Sprintf("GIN-Wallpaper-Calend %s — Настройки и Темы", AppVersion)
	}

	wcSettings := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(settingsWndProc),
		LpszClassName: strPtr("GIN_Wallpaper_SettingsClass"),
		HIcon:         hIconApp,
		HIconSm:       hIconApp,
		HbrBackground: syscall.Handle(16),
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcSettings)))

	wnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_Wallpaper_SettingsClass"))),
		uintptr(unsafe.Pointer(strPtr(wTitle))),
		WS_OVERLAPPEDWINDOW&^0x00040000,
		uintptr(posX), uintptr(posY), uintptr(winW), uintptr(winH),
		0, 0, 0, 0,
	)
	hwndSettings = syscall.Handle(wnd)

	// Set Window Icons (Top-Left Titlebar)
	procSendMessageW.Call(uintptr(hwndSettings), WM_SETICON, 0, uintptr(hIconApp))
	procSendMessageW.Call(uintptr(hwndSettings), WM_SETICON, 1, uintptr(hIconApp))

	createControls(hwndSettings)
	updateTexts()
	updatePreviewCard()

	procShowWindow.Call(uintptr(hwndSettings), 1)
	procSetForegroundWindow.Call(uintptr(hwndSettings))
}

func createControls(parent syscall.Handle) {
	btnClass := strPtr("BUTTON")
	staticClass := strPtr("STATIC")

	// 1. Top Header bar: Title on Left, Themes & Languages & Sound on Right
	titleText := fmt.Sprintf("GIN-Wallpaper-Calend от VladiMIR+AI [%s]", AppVersion)
	lblTitle = syscall.Handle(createCtrl(staticClass, titleText, WS_CHILD|WS_VISIBLE, 20, 12, 310, 26, parent, 10))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblTitle), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Header Mode Buttons: Day, Evening, Night
	btnModeDay = syscall.Handle(createCtrl(btnClass, "☀️", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 330, 10, 36, 28, parent, 101))
	btnModeEvening = syscall.Handle(createCtrl(btnClass, "⛅", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 368, 10, 36, 28, parent, 102))
	btnModeNight = syscall.Handle(createCtrl(btnClass, "🌙", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 406, 10, 36, 28, parent, 103))

	// Separator 1: Dash with 1mm (~4px) space
	lblSep1 = syscall.Handle(createCtrl(staticClass, "—", WS_CHILD|WS_VISIBLE|SS_CENTER, 446, 14, 14, 20, parent, 15))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSep1), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Language Buttons in order RU, EN, CS:
	btnLangRU = syscall.Handle(createCtrl(btnClass, "RU", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 464, 10, 38, 28, parent, 105))
	btnLangEN = syscall.Handle(createCtrl(btnClass, "EN", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 506, 10, 38, 28, parent, 104))
	btnLangCS = syscall.Handle(createCtrl(btnClass, "CS", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 548, 10, 38, 28, parent, 107))

	// Separator 2: Dash with 1mm (~4px) space
	lblSep2 = syscall.Handle(createCtrl(staticClass, "—", WS_CHILD|WS_VISIBLE|SS_CENTER, 590, 14, 14, 20, parent, 16))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSep2), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Sound Toggle Button (reduced width: 140px)
	btnSound = syscall.Handle(createCtrl(btnClass, "🔊 Sound ON", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 608, 10, 140, 28, parent, 106))

	// Divider 1: Above Themes (Full Width)
	divThemes = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 0, 46, 820, 1, parent, 51))

	// Section 1: Themes (12 Checkboxes in 2 columns: All Random + 11 Categories)
	lblSecThemes = syscall.Handle(createCtrl(staticClass, "🎨 Wallpaper Themes / Тематика обоев:", WS_CHILD|WS_VISIBLE, 20, 54, 780, 20, parent, 11))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecThemes), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Column 1
	cbAll = createCheckbox("🎲 All Random (Mix)", 30, 74, 340, 20, parent, 201)
	cb3DAbstract = createCheckbox("🔮 3D Renders, Textures & Abstract", 30, 94, 340, 20, parent, 202)
	cbFlowers = createCheckbox("🌸 Flowers & Blossom", 30, 114, 340, 20, parent, 203)
	cbOcean = createCheckbox("🌊 Ocean, Sea & Waves", 30, 134, 340, 20, parent, 204)
	cbSpace = createCheckbox("🚀 Space & Galaxies (Nebula)", 30, 154, 340, 20, parent, 205)
	cbNature = createCheckbox("🌿 Nature & Landscapes", 30, 174, 340, 20, parent, 206)
	cbAnimals = createCheckbox("🐾 Wildlife & Animals", 30, 194, 340, 20, parent, 211)

	// Column 2
	cbCars = createCheckbox("🏎️ Cars & Supercars", 380, 74, 380, 20, parent, 207)
	cbTrucksOffroad = createCheckbox("🚛 Trucks & 4x4 Off-Road", 380, 94, 380, 20, parent, 213)
	cbGirls = createCheckbox("👗 Girls: Models & Fashion", 380, 114, 380, 20, parent, 214)
	cbCity = createCheckbox("🌆 City & Architecture", 380, 134, 380, 20, parent, 208)
	cbCyberpunk = createCheckbox("⚡ Cyberpunk & Neon", 380, 154, 380, 20, parent, 209)
	cbMinimal = createCheckbox("🖤 Minimalism & Dark AMOLED", 380, 174, 380, 20, parent, 210)
	cbAnime = createCheckbox("⛩️ Anime & Digital Scenery", 380, 194, 380, 20, parent, 212)

	selectCurrentThemeCheckboxes()

	// Divider 2: Between Themes and Intervals (Full Width)
	divInterval = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 0, 218, 820, 1, parent, 52))

	// Section 2: Intervals (4 Buttons: 1 hour, 3 hours, 6 hours, Once a day - exactly matching action buttons style)
	lblSecInt = syscall.Handle(createCtrl(staticClass, "⏱ Auto-Change Interval / Интервал смены:", WS_CHILD|WS_VISIBLE, 20, 222, 780, 20, parent, 12))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecInt), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	btnInt1h = syscall.Handle(createCtrl(btnClass, "1 hour", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_GROUP|WS_TABSTOP, 25, 246, 182, 40, parent, 301))
	btnInt3h = syscall.Handle(createCtrl(btnClass, "3 hours", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 217, 246, 182, 40, parent, 302))
	btnInt6h = syscall.Handle(createCtrl(btnClass, "6 hours", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 409, 246, 182, 40, parent, 303))
	btnInt24h = syscall.Handle(createCtrl(btnClass, "Once a day", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 601, 246, 182, 40, parent, 304))

	// Divider 3: Between Intervals and Fonts (Full Width)
	divFonts = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 0, 296, 820, 1, parent, 53))

	// Section 3: Fonts (16 Distinct Choices in 2 Columns of 8, Single-Line with Date Sample)
	lblSecFonts = syscall.Handle(createCtrl(staticClass, "🔤 Calendar Font Choices (16 Options):", WS_CHILD|WS_VISIBLE, 20, 304, 780, 20, parent, 13))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecFonts), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Column 1 (Left): Fonts 1 to 8 (X = 20, W = 355)
	rbFontSegoe = createRadio("1. Segoe UI Bold", 20, 328, 355, 24, parent, 401, true) // WS_GROUP start
	procSendMessageW.Call(uintptr(rbFontSegoe), WM_SETFONT, uintptr(hFontSegoe), 1)

	rbFontBahn = createRadio("2. Bahnschrift", 20, 353, 355, 24, parent, 402, false)
	procSendMessageW.Call(uintptr(rbFontBahn), WM_SETFONT, uintptr(hFontBahn), 1)

	rbFontArial = createRadio("3. Arial", 20, 378, 355, 24, parent, 403, false)
	procSendMessageW.Call(uintptr(rbFontArial), WM_SETFONT, uintptr(hFontArial), 1)

	rbFontVerdana = createRadio("4. Verdana", 20, 403, 355, 24, parent, 404, false)
	procSendMessageW.Call(uintptr(rbFontVerdana), WM_SETFONT, uintptr(hFontVerdana), 1)

	rbFontGeorgia = createRadio("5. Georgia Bold", 20, 428, 355, 24, parent, 405, false)
	procSendMessageW.Call(uintptr(rbFontGeorgia), WM_SETFONT, uintptr(hFontGeorgia), 1)

	rbFontCorbel = createRadio("6. Corbel Bold", 20, 453, 355, 24, parent, 406, false)
	procSendMessageW.Call(uintptr(rbFontCorbel), WM_SETFONT, uintptr(hFontCorbel), 1)

	rbFontPalatino = createRadio("7. Palatino Linotype Bold", 20, 478, 355, 24, parent, 407, false)
	procSendMessageW.Call(uintptr(rbFontPalatino), WM_SETFONT, uintptr(hFontPalatino), 1)

	rbFontFranklin = createRadio("8. Franklin Gothic Medium", 20, 503, 355, 24, parent, 408, false)
	procSendMessageW.Call(uintptr(rbFontFranklin), WM_SETFONT, uintptr(hFontFranklin), 1)

	// Column 2 (Right): Fonts 9 to 16 (X = 385, W = 420 - shifted left by ~25px and widened to 420px for zero clipping)
	rbFontConsolas = createRadio("9. Consolas Bold", 385, 328, 420, 24, parent, 409, false)
	procSendMessageW.Call(uintptr(rbFontConsolas), WM_SETFONT, uintptr(hFontConsolas), 1)

	rbFontTreb = createRadio("10. Trebuchet MS Bold", 385, 353, 420, 24, parent, 410, false)
	procSendMessageW.Call(uintptr(rbFontTreb), WM_SETFONT, uintptr(hFontTreb), 1)

	rbFontCambria = createRadio("11. Cambria Bold", 385, 378, 420, 24, parent, 411, false)
	procSendMessageW.Call(uintptr(rbFontCambria), WM_SETFONT, uintptr(hFontCambria), 1)

	rbFontGothic = createRadio("12. Century Gothic Bold", 385, 403, 420, 24, parent, 412, false)
	procSendMessageW.Call(uintptr(rbFontGothic), WM_SETFONT, uintptr(hFontGothic), 1)

	rbFontCandara = createRadio("13. Candara Bold", 385, 428, 420, 24, parent, 413, false)
	procSendMessageW.Call(uintptr(rbFontCandara), WM_SETFONT, uintptr(hFontCandara), 1)

	rbFontConstantia = createRadio("14. Constantia Bold", 385, 453, 420, 24, parent, 414, false)
	procSendMessageW.Call(uintptr(rbFontConstantia), WM_SETFONT, uintptr(hFontConstantia), 1)

	rbFontSegoePrint = createRadio("15. Segoe Print Bold", 385, 478, 420, 24, parent, 415, false)
	procSendMessageW.Call(uintptr(rbFontSegoePrint), WM_SETFONT, uintptr(hFontSegoePrint), 1)

	rbFontCalibri = createRadio("16. Calibri Bold", 385, 503, 420, 24, parent, 416, false)
	procSendMessageW.Call(uintptr(rbFontCalibri), WM_SETFONT, uintptr(hFontCalibri), 1)
	procSendMessageW.Call(uintptr(rbFontCalibri), WM_SETFONT, uintptr(hFontCalibri), 1)

	selectCurrentFontRadio()

	// Divider 4: Between Fonts and Scale (Full Width)
	divScale = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 0, 537, 820, 1, parent, 54))

	// Section 4: Scale (4 buttons: Compact, Moderate, Standard, Large with font size samples)
	lblSecScale = syscall.Handle(createCtrl(staticClass, "🔍 Calendar Scale / Размер календаря:", WS_CHILD|WS_VISIBLE, 20, 545, 780, 20, parent, 14))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecScale), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	btnScaleCompact = syscall.Handle(createCtrl(btnClass, "Compact", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_GROUP|WS_TABSTOP, 25, 569, 182, 42, parent, 451))
	btnScaleModerate = syscall.Handle(createCtrl(btnClass, "Moderate", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 217, 569, 182, 42, parent, 452))
	btnScaleStandard = syscall.Handle(createCtrl(btnClass, "Standard", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 409, 569, 182, 42, parent, 453))
	btnScaleLarge = syscall.Handle(createCtrl(btnClass, "Large", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 601, 569, 182, 42, parent, 454))

	// Divider 5: Between Scale and Status / Buttons (Full Width)
	divBottom = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 0, 621, 820, 1, parent, 55))

	// Status Info Label
	lblStatusInfo = syscall.Handle(createCtrl(staticClass, "Ready. Click 'Apply Now' to change desktop wallpaper immediately.", WS_CHILD|WS_VISIBLE, 25, 629, 780, 20, parent, 505))
	if hUIFontSm != 0 {
		procSendMessageW.Call(uintptr(lblStatusInfo), WM_SETFONT, uintptr(hUIFontSm), 1)
	}

	// Bottom Action Buttons (Y = 654, Height = 42)
	btnApply = syscall.Handle(createCtrl(btnClass, "⚡ Apply Now", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_GROUP|WS_TABSTOP, 25, 654, 182, 42, parent, 601))
	btnSave = syscall.Handle(createCtrl(btnClass, "💾 Save & Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 217, 654, 182, 42, parent, 602))
	btnRandom = syscall.Handle(createCtrl(btnClass, "🎲 Random Theme", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 409, 654, 182, 42, parent, 603))
	btnClose = syscall.Handle(createCtrl(btnClass, "Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 601, 654, 182, 42, parent, 604))

	// Bottom Footer: Separated Author & Update Buttons (Y = 706, Height = 36)
	btnFooterAuthor = syscall.Handle(createCtrl(btnClass, "⭐ VladiMIR + AI", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, 25, 706, 374, 36, parent, 606))
	btnFooterUpdate = syscall.Handle(createCtrl(btnClass, fmt.Sprintf("%s (update)", AppVersion), WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, 409, 706, 374, 36, parent, 605))

	// Subclass individual checkboxes for crisp 100% GDI strikethrough lines
	if origCheckboxProc == 0 {
		cbProc := syscall.NewCallback(themeCheckboxWndProc)
		for _, it := range getIndividualThemeCheckboxes() {
			p, _, _ := procSetWindowLongPtrW.Call(uintptr(it.h), uintptr(uint64(0xFFFFFFFFFFFFFFFC)), cbProc) // GWLP_WNDPROC = -4
			if p != 0 && origCheckboxProc == 0 {
				origCheckboxProc = p
			}
		}
	}
}

func getTodaySampleString() string {
	now := time.Now()
	wDay := int(now.Weekday())
	mDay := now.Day()
	mIdx := int(now.Month())
	yr := now.Year()

	if isCs() {
		return fmt.Sprintf("%s, %d. %s %d", csFullDays[wDay], mDay, csMonths[mIdx], yr)
	} else if isRu() {
		return fmt.Sprintf("%s, %d %s %d", ruFullDays[wDay], mDay, ruMonths[mIdx], yr)
	}
	return fmt.Sprintf("%s, %s %d, %d", enFullDays[wDay], enMonths[mIdx], mDay, yr)
}

func createCtrl(className *uint16, text string, style uint32, x, y, w, h int, parent syscall.Handle, id uintptr) uintptr {
	r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(className)), uintptr(unsafe.Pointer(strPtr(text))), uintptr(style), uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), id, 0, 0)
	return r
}

func createRadio(caption string, x, y, w, h int, parent syscall.Handle, id uintptr, isGroupStart bool) syscall.Handle {
	btnClass := strPtr("BUTTON")
	style := uint32(WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON)
	if isGroupStart {
		style |= WS_GROUP | WS_TABSTOP
	}
	r := createCtrl(btnClass, caption, style, x, y, w, h, parent, id)
	hCtrl := syscall.Handle(r)
	if hUIFont != 0 {
		procSendMessageW.Call(uintptr(hCtrl), WM_SETFONT, uintptr(hUIFont), 1)
	}
	return hCtrl
}

func createCheckbox(caption string, x, y, w, h int, parent syscall.Handle, id uintptr) syscall.Handle {
	btnClass := strPtr("BUTTON")
	style := uint32(WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX | WS_TABSTOP)
	r := createCtrl(btnClass, caption, style, x, y, w, h, parent, id)
	hCtrl := syscall.Handle(r)
	if hUIFont != 0 {
		procSendMessageW.Call(uintptr(hCtrl), WM_SETFONT, uintptr(hUIFont), 1)
	}
	return hCtrl
}

func enableCtrl(h syscall.Handle, enable bool) {
	val := uintptr(0)
	if enable {
		val = 1
	}
	procEnableWindow.Call(uintptr(h), val)
}

func isEnabled(h syscall.Handle) bool {
	r, _, _ := procIsWindowEnabled.Call(uintptr(h))
	return r != 0
}

type ThemeCheckboxInfo struct {
	id uintptr
	h  syscall.Handle
	th string
}

func getIndividualThemeCheckboxes() []ThemeCheckboxInfo {
	return []ThemeCheckboxInfo{
		{202, cb3DAbstract, "3d_abstract"},
		{203, cbFlowers, "flowers"},
		{204, cbOcean, "ocean"},
		{205, cbSpace, "space"},
		{206, cbNature, "nature"},
		{211, cbAnimals, "animals"},
		{207, cbCars, "cars"},
		{213, cbTrucksOffroad, "trucks_offroad"},
		{214, cbGirls, "girls"},
		{208, cbCity, "city"},
		{209, cbCyberpunk, "cyberpunk"},
		{210, cbMinimal, "minimalism"},
		{212, cbAnime, "anime"},
	}
}

func isThemeCheckbox(h syscall.Handle) bool {
	return h == cb3DAbstract || h == cbFlowers || h == cbOcean || h == cbSpace ||
		h == cbNature || h == cbAnimals || h == cbCars || h == cbTrucksOffroad ||
		h == cbGirls || h == cbCity || h == cbCyberpunk || h == cbMinimal || h == cbAnime
}

func themeCheckboxWndProc(hwnd syscall.Handle, msg uint32, wParam, lParam uintptr) uintptr {
	ret, _, _ := procCallWindowProcW.Call(origCheckboxProc, uintptr(hwnd), uintptr(msg), wParam, lParam)

	if msg == 0x000F && isChecked(cbAll) { // WM_PAINT = 0x000F
		hDC, _, _ := procGetDC.Call(uintptr(hwnd))
		if hDC != 0 {
			var rc RECT
			procGetClientRect.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&rc)))

			buf := make([]uint16, 256)
			tLen, _, _ := procGetWindowTextW.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&buf[0])), 256)
			textWidth := int32(0)
			if tLen > 0 {
				var sz SIZE
				oldFont, _, _ := procSelectObject.Call(hDC, uintptr(hUIFont))
				procGetTextExtentPoint32W.Call(hDC, uintptr(unsafe.Pointer(&buf[0])), tLen, uintptr(unsafe.Pointer(&sz)))
				procSelectObject.Call(hDC, oldFont)
				textWidth = sz.CX
			}
			if textWidth <= 0 || textWidth > rc.Right-24 {
				textWidth = rc.Right - 26
			}

			midY := (rc.Top + rc.Bottom) / 2
			lineCol := rgb(140, 150, 165)
			if cfg.ThemeMode == ThemeModeDay {
				lineCol = rgb(150, 155, 165)
			} else if cfg.ThemeMode == ThemeModeNight {
				lineCol = rgb(115, 125, 140)
			}

			hPen, _, _ := procCreatePen.Call(0, 1, uintptr(lineCol))
			oldPen, _, _ := procSelectObject.Call(hDC, hPen)
			procMoveToEx.Call(hDC, 20, uintptr(midY), 0)
			procLineTo.Call(hDC, uintptr(22+textWidth), uintptr(midY))
			procSelectObject.Call(hDC, oldPen)
			procDeleteObject.Call(hPen)
			procReleaseDC.Call(uintptr(hwnd), hDC)
		}
	}
	return ret
}

func updateThemeCheckboxesState() {
	allChecked := isChecked(cbAll)
	items := getIndividualThemeCheckboxes()
	for _, it := range items {
		if allChecked {
			procSendMessageW.Call(uintptr(it.h), BM_SETCHECK, BST_UNCHECKED, 0)
			procSendMessageW.Call(uintptr(it.h), WM_SETFONT, uintptr(hUIFontStrike), 1)
		} else {
			procSendMessageW.Call(uintptr(it.h), WM_SETFONT, uintptr(hUIFont), 1)
		}
		procInvalidateRect.Call(uintptr(it.h), 0, 1)
	}
}

func selectCurrentThemeCheckboxes() {
	items := getIndividualThemeCheckboxes()
	isAll := false
	if len(cfg.Themes) == 0 {
		isAll = true
	} else {
		for _, t := range cfg.Themes {
			if t == "all" {
				isAll = true
				break
			}
		}
	}

	if isAll {
		procSendMessageW.Call(uintptr(cbAll), BM_SETCHECK, BST_CHECKED, 0)
		for _, it := range items {
			procSendMessageW.Call(uintptr(it.h), BM_SETCHECK, BST_UNCHECKED, 0)
			procSendMessageW.Call(uintptr(it.h), WM_SETFONT, uintptr(hUIFontStrike), 1)
			procInvalidateRect.Call(uintptr(it.h), 0, 1)
		}
	} else {
		procSendMessageW.Call(uintptr(cbAll), BM_SETCHECK, BST_UNCHECKED, 0)
		activeMap := make(map[string]bool)
		for _, t := range cfg.Themes {
			activeMap[t] = true
			if t == "abstract" || t == "fractal" || t == "windows" {
				activeMap["3d_abstract"] = true
			}
		}
		anyChecked := false
		for _, it := range items {
			procSendMessageW.Call(uintptr(it.h), WM_SETFONT, uintptr(hUIFont), 1)
			if activeMap[it.th] {
				procSendMessageW.Call(uintptr(it.h), BM_SETCHECK, BST_CHECKED, 0)
				anyChecked = true
			} else {
				procSendMessageW.Call(uintptr(it.h), BM_SETCHECK, BST_UNCHECKED, 0)
			}
			procInvalidateRect.Call(uintptr(it.h), 0, 1)
		}
		if !anyChecked {
			procSendMessageW.Call(uintptr(cbAll), BM_SETCHECK, BST_CHECKED, 0)
			for _, it := range items {
				procSendMessageW.Call(uintptr(it.h), BM_SETCHECK, BST_UNCHECKED, 0)
				procSendMessageW.Call(uintptr(it.h), WM_SETFONT, uintptr(hUIFontStrike), 1)
				procInvalidateRect.Call(uintptr(it.h), 0, 1)
			}
		}
	}
}

func selectCurrentIntervalRadio() {
	if btnInt1h != 0 {
		procInvalidateRect.Call(uintptr(btnInt1h), 0, 1)
		procInvalidateRect.Call(uintptr(btnInt3h), 0, 1)
		procInvalidateRect.Call(uintptr(btnInt6h), 0, 1)
		procInvalidateRect.Call(uintptr(btnInt24h), 0, 1)
	}
}

func selectCurrentFontRadio() {
	switch cfg.FontStyle {
	case "bahn", "bahnschrift":
		procSendMessageW.Call(uintptr(rbFontBahn), BM_SETCHECK, BST_CHECKED, 0)
	case "arial":
		procSendMessageW.Call(uintptr(rbFontArial), BM_SETCHECK, BST_CHECKED, 0)
	case "verdana":
		procSendMessageW.Call(uintptr(rbFontVerdana), BM_SETCHECK, BST_CHECKED, 0)
	case "georgia":
		procSendMessageW.Call(uintptr(rbFontGeorgia), BM_SETCHECK, BST_CHECKED, 0)
	case "corbel":
		procSendMessageW.Call(uintptr(rbFontCorbel), BM_SETCHECK, BST_CHECKED, 0)
	case "palatino":
		procSendMessageW.Call(uintptr(rbFontPalatino), BM_SETCHECK, BST_CHECKED, 0)
	case "franklin":
		procSendMessageW.Call(uintptr(rbFontFranklin), BM_SETCHECK, BST_CHECKED, 0)
	case "consolas":
		procSendMessageW.Call(uintptr(rbFontConsolas), BM_SETCHECK, BST_CHECKED, 0)
	case "trebuchet":
		procSendMessageW.Call(uintptr(rbFontTreb), BM_SETCHECK, BST_CHECKED, 0)
	case "cambria", "impact":
		procSendMessageW.Call(uintptr(rbFontCambria), BM_SETCHECK, BST_CHECKED, 0)
	case "gothic":
		procSendMessageW.Call(uintptr(rbFontGothic), BM_SETCHECK, BST_CHECKED, 0)
	case "candara":
		procSendMessageW.Call(uintptr(rbFontCandara), BM_SETCHECK, BST_CHECKED, 0)
	case "constantia":
		procSendMessageW.Call(uintptr(rbFontConstantia), BM_SETCHECK, BST_CHECKED, 0)
	case "segoeprint":
		procSendMessageW.Call(uintptr(rbFontSegoePrint), BM_SETCHECK, BST_CHECKED, 0)
	case "calibri":
		procSendMessageW.Call(uintptr(rbFontCalibri), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rbFontSegoe), BM_SETCHECK, BST_CHECKED, 0)
	}
}

func selectCurrentScaleRadio() {
	if btnScaleCompact != 0 {
		procInvalidateRect.Call(uintptr(btnScaleCompact), 0, 1)
		procInvalidateRect.Call(uintptr(btnScaleModerate), 0, 1)
		procInvalidateRect.Call(uintptr(btnScaleStandard), 0, 1)
		procInvalidateRect.Call(uintptr(btnScaleLarge), 0, 1)
	}
}

func updateTexts() {
	ru := isRu()
	cs := isCs()
	setTxt := func(h syscall.Handle, txt string) {
		procSetWindowTextW.Call(uintptr(h), uintptr(unsafe.Pointer(strPtr(txt))))
	}

	wTitle := fmt.Sprintf("GIN-Wallpaper-Calend %s — Settings & Themes", AppVersion)
	if cs {
		wTitle = fmt.Sprintf("GIN-Wallpaper-Calend %s — Nastavení a Témata", AppVersion)
	} else if ru {
		wTitle = fmt.Sprintf("GIN-Wallpaper-Calend %s — Настройки и Темы", AppVersion)
	}
	procSetWindowTextW.Call(uintptr(hwndSettings), uintptr(unsafe.Pointer(strPtr(wTitle))))

	titleText := fmt.Sprintf("GIN-Wallpaper-Calend by VladiMIR+AI [%s]", AppVersion)
	if cs {
		titleText = fmt.Sprintf("GIN-Wallpaper-Calend od VladiMIR+AI [%s]", AppVersion)
	} else if ru {
		titleText = fmt.Sprintf("GIN-Wallpaper-Calend от VladiMIR+AI [%s]", AppVersion)
	}
	setTxt(lblTitle, titleText)

	sampDate := getTodaySampleString()

	if cs {
		setTxt(lblSecThemes, "🎨 Témata tapet (vyberte několik nebo „Vše náhodně“):")
		setTxt(cbAll, "🎲 Vše náhodně (Mix všech témat)")
		setTxt(cb3DAbstract, "🔮 3D Rendery, Textury a Abstrakce")
		setTxt(cbFlowers, "🌸 Květiny a flóra")
		setTxt(cbOcean, "🌊 Oceán, moře a vlny")
		setTxt(cbSpace, "🚀 Vesmír a galaxie (Mlhoviny)")
		setTxt(cbNature, "🌿 Příroda a krajiny")
		setTxt(cbAnimals, "🐾 Zvířata a divoká příroda")
		setTxt(cbCars, "🏎️ Auta a Supersporty")
		setTxt(cbTrucksOffroad, "🚛 Nákladní auta a Off-Road")
		setTxt(cbGirls, "👗 Dívky: Modelky a Móda")
		setTxt(cbCity, "🌆 Města a architektura (Panorama)")
		setTxt(cbCyberpunk, "⚡ Cyberpunk a neon (Synthwave)")
		setTxt(cbMinimal, "🖤 Minimalismus a Dark AMOLED")
		setTxt(cbAnime, "⛩️ Anime a digitální scenérie")

		setTxt(lblSecInt, "⏱ Interval automatické změny tapety:")
		setTxt(lblSecFonts, "🔤 Výběr písma kalendáře (16 možností ve 2 sloupcích):")
		setTxt(rbFontSegoe, fmt.Sprintf("1. Segoe UI Bold - %s", sampDate))
		setTxt(rbFontBahn, fmt.Sprintf("2. Bahnschrift - %s", sampDate))
		setTxt(rbFontArial, fmt.Sprintf("3. Arial - %s", sampDate))
		setTxt(rbFontVerdana, fmt.Sprintf("4. Verdana - %s", sampDate))
		setTxt(rbFontGeorgia, fmt.Sprintf("5. Georgia Bold - %s", sampDate))
		setTxt(rbFontCorbel, fmt.Sprintf("6. Corbel Bold - %s", sampDate))
		setTxt(rbFontPalatino, fmt.Sprintf("7. Palatino Linotype - %s", sampDate))
		setTxt(rbFontFranklin, fmt.Sprintf("8. Franklin Gothic - %s", sampDate))
		setTxt(rbFontConsolas, fmt.Sprintf("9. Consolas Bold - %s", sampDate))
		setTxt(rbFontTreb, fmt.Sprintf("10. Trebuchet MS Bold - %s", sampDate))
		setTxt(rbFontCambria, fmt.Sprintf("11. Cambria Bold - %s", sampDate))
		setTxt(rbFontGothic, fmt.Sprintf("12. Century Gothic Bold - %s", sampDate))
		setTxt(rbFontCandara, fmt.Sprintf("13. Candara Bold - %s", sampDate))
		setTxt(rbFontConstantia, fmt.Sprintf("14. Constantia Bold - %s", sampDate))
		setTxt(rbFontSegoePrint, fmt.Sprintf("15. Segoe Print - %s", sampDate))
		setTxt(rbFontCalibri, fmt.Sprintf("16. Calibri Bold - %s", sampDate))

		setTxt(lblSecScale, "🔍 Měřítko a velikost kalendáře:")
		setTxt(lblStatusInfo, "Připraveno. Klikněte na „Použít nyní“ pro okamžitou změnu tapety a kalendáře.")
	} else if ru {
		setTxt(lblSecThemes, "🎨 Тематика обоев (выберите несколько или «Все подряд»):")
		setTxt(cbAll, "🎲 Все подряд (Случайный микс)")
		setTxt(cb3DAbstract, "🔮 3D Рендеры, Фактуры и Абстракция")
		setTxt(cbFlowers, "🌸 Цветы и ботаника")
		setTxt(cbOcean, "🌊 Океан, море и побережье")
		setTxt(cbSpace, "🚀 Космос и Галактики (Nebula)")
		setTxt(cbNature, "🌿 Природа и пейзажи")
		setTxt(cbAnimals, "🐾 Животные и Дикая природа")
		setTxt(cbCars, "🏎️ Автомобили и Суперкары")
		setTxt(cbTrucksOffroad, "🚛 Грузовики и Внедорожники")
		setTxt(cbGirls, "👗 Девушки: Модели и Мода")
		setTxt(cbCity, "🌆 Города и Архитектура (Skylines)")
		setTxt(cbCyberpunk, "⚡ Киберпанк и Неон (Synthwave)")
		setTxt(cbMinimal, "🖤 Минимализм и Dark AMOLED")
		setTxt(cbAnime, "⛩️ Аниме и Цифровой Арт")

		setTxt(lblSecInt, "⏱ Интервал автоматической смены обоев:")
		setTxt(lblSecFonts, "🔤 Выбор шрифта календаря (16 вариантов в 2 столбика):")
		setTxt(rbFontSegoe, fmt.Sprintf("1. Segoe UI Bold - %s", sampDate))
		setTxt(rbFontBahn, fmt.Sprintf("2. Bahnschrift - %s", sampDate))
		setTxt(rbFontArial, fmt.Sprintf("3. Arial - %s", sampDate))
		setTxt(rbFontVerdana, fmt.Sprintf("4. Verdana - %s", sampDate))
		setTxt(rbFontGeorgia, fmt.Sprintf("5. Georgia Bold - %s", sampDate))
		setTxt(rbFontCorbel, fmt.Sprintf("6. Corbel Bold - %s", sampDate))
		setTxt(rbFontPalatino, fmt.Sprintf("7. Palatino Linotype - %s", sampDate))
		setTxt(rbFontFranklin, fmt.Sprintf("8. Franklin Gothic - %s", sampDate))
		setTxt(rbFontConsolas, fmt.Sprintf("9. Consolas Bold - %s", sampDate))
		setTxt(rbFontTreb, fmt.Sprintf("10. Trebuchet MS Bold - %s", sampDate))
		setTxt(rbFontCambria, fmt.Sprintf("11. Cambria Bold - %s", sampDate))
		setTxt(rbFontGothic, fmt.Sprintf("12. Century Gothic Bold - %s", sampDate))
		setTxt(rbFontCandara, fmt.Sprintf("13. Candara Bold - %s", sampDate))
		setTxt(rbFontConstantia, fmt.Sprintf("14. Constantia Bold - %s", sampDate))
		setTxt(rbFontSegoePrint, fmt.Sprintf("15. Segoe Print - %s", sampDate))
		setTxt(rbFontCalibri, fmt.Sprintf("16. Calibri Bold - %s", sampDate))

		setTxt(lblSecScale, "🔍 Масштаб и размер календаря:")
		setTxt(lblStatusInfo, "Готово. Нажмите «Применить сейчас», чтобы сразу сменить обои и календарь.")
	} else {
		setTxt(lblSecThemes, "🎨 Wallpaper Themes (Check multiple or 'All Random'):")
		setTxt(cbAll, "🎲 All Random (Mix of all themes)")
		setTxt(cb3DAbstract, "🔮 3D Renders, Textures & Abstract")
		setTxt(cbFlowers, "🌸 Flowers & Blossom")
		setTxt(cbOcean, "🌊 Ocean, Sea & Waves")
		setTxt(cbSpace, "🚀 Space & Galaxies (Nebula)")
		setTxt(cbNature, "🌿 Nature & Landscapes")
		setTxt(cbAnimals, "🐾 Wildlife & Animals")
		setTxt(cbCars, "🏎️ Cars & Supercars")
		setTxt(cbTrucksOffroad, "🚛 Trucks & 4x4 Off-Road")
		setTxt(cbGirls, "👗 Girls: Models & Fashion")
		setTxt(cbCity, "🌆 City & Architecture (Skylines)")
		setTxt(cbCyberpunk, "⚡ Cyberpunk & Neon (Synthwave)")
		setTxt(cbMinimal, "🖤 Minimalism & Dark AMOLED")
		setTxt(cbAnime, "⛩️ Anime & Digital Scenery")

		setTxt(lblSecInt, "⏱ Auto-Change Interval:")
		setTxt(lblSecFonts, "🔤 Calendar Font Choices (16 Options in 2 Columns):")
		setTxt(rbFontSegoe, fmt.Sprintf("1. Segoe UI Bold - %s", sampDate))
		setTxt(rbFontBahn, fmt.Sprintf("2. Bahnschrift - %s", sampDate))
		setTxt(rbFontArial, fmt.Sprintf("3. Arial - %s", sampDate))
		setTxt(rbFontVerdana, fmt.Sprintf("4. Verdana - %s", sampDate))
		setTxt(rbFontGeorgia, fmt.Sprintf("5. Georgia Bold - %s", sampDate))
		setTxt(rbFontCorbel, fmt.Sprintf("6. Corbel Bold - %s", sampDate))
		setTxt(rbFontPalatino, fmt.Sprintf("7. Palatino Linotype - %s", sampDate))
		setTxt(rbFontFranklin, fmt.Sprintf("8. Franklin Gothic - %s", sampDate))
		setTxt(rbFontConsolas, fmt.Sprintf("9. Consolas Bold - %s", sampDate))
		setTxt(rbFontTreb, fmt.Sprintf("10. Trebuchet MS Bold - %s", sampDate))
		setTxt(rbFontCambria, fmt.Sprintf("11. Cambria Bold - %s", sampDate))
		setTxt(rbFontGothic, fmt.Sprintf("12. Century Gothic Bold - %s", sampDate))
		setTxt(rbFontCandara, fmt.Sprintf("13. Candara Bold - %s", sampDate))
		setTxt(rbFontConstantia, fmt.Sprintf("14. Constantia Bold - %s", sampDate))
		setTxt(rbFontSegoePrint, fmt.Sprintf("15. Segoe Print - %s", sampDate))
		setTxt(rbFontCalibri, fmt.Sprintf("16. Calibri Bold - %s", sampDate))

		setTxt(lblSecScale, "🔍 Calendar Scale and Size:")

		setTxt(lblStatusInfo, "Ready. Click 'Apply Now' to change wallpaper and calendar immediately.")
	}

	procInvalidateRect.Call(uintptr(hwndSettings), 0, 1)
}

func updatePreviewCard() {
	// Replaced by 2-column live font preview
}

func isChecked(h syscall.Handle) bool {
	r, _, _ := procSendMessageW.Call(uintptr(h), BM_GETCHECK, 0, 0)
	return r == BST_CHECKED
}

func readCurrentUISelections() {
	if isChecked(cbAll) {
		cfg.Themes = []string{"all"}
		cfg.Theme = "all"
	} else {
		var selected []string
		items := getIndividualThemeCheckboxes()
		for _, it := range items {
			if isChecked(it.h) {
				selected = append(selected, it.th)
			}
		}
		if len(selected) == 0 {
			cfg.Themes = []string{"all"}
			cfg.Theme = "all"
			procSendMessageW.Call(uintptr(cbAll), BM_SETCHECK, BST_CHECKED, 0)
			updateThemeCheckboxesState()
		} else {
			cfg.Themes = selected
			cfg.Theme = selected[0]
		}
	}

	if isChecked(rbFontBahn) {
		cfg.FontStyle = "bahnschrift"
	} else if isChecked(rbFontArial) {
		cfg.FontStyle = "arial"
	} else if isChecked(rbFontVerdana) {
		cfg.FontStyle = "verdana"
	} else if isChecked(rbFontGeorgia) {
		cfg.FontStyle = "georgia"
	} else if isChecked(rbFontCorbel) {
		cfg.FontStyle = "corbel"
	} else if isChecked(rbFontPalatino) {
		cfg.FontStyle = "palatino"
	} else if isChecked(rbFontFranklin) {
		cfg.FontStyle = "franklin"
	} else if isChecked(rbFontConsolas) {
		cfg.FontStyle = "consolas"
	} else if isChecked(rbFontTreb) {
		cfg.FontStyle = "trebuchet"
	} else if isChecked(rbFontCambria) {
		cfg.FontStyle = "cambria"
	} else if isChecked(rbFontGothic) {
		cfg.FontStyle = "gothic"
	} else if isChecked(rbFontCandara) {
		cfg.FontStyle = "candara"
	} else if isChecked(rbFontConstantia) {
		cfg.FontStyle = "constantia"
	} else if isChecked(rbFontSegoePrint) {
		cfg.FontStyle = "segoeprint"
	} else if isChecked(rbFontCalibri) {
		cfg.FontStyle = "calibri"
	} else {
		cfg.FontStyle = "segoe"
	}
}

func drawCustomButton(dis *DRAWITEMSTRUCT) uintptr {
	hDC := uintptr(dis.HDC)
	rc := dis.RcItem
	isPressed := (dis.ItemState & 0x0001) != 0

	var btnText string
	var bgCol, borderCol, textCol uint32
	var hFont uintptr = uintptr(hUIFontBold)

	switch dis.CtlID {
	// Mode buttons
	case 101:
		btnText = "☀️"
		bgCol = rgb(230, 235, 245)
		borderCol = rgb(180, 190, 210)
		if cfg.ThemeMode == ThemeModeDay {
			borderCol = rgb(255, 179, 0)
			bgCol = rgb(255, 248, 225)
		}
		textCol = rgb(30, 30, 30)
	case 102:
		btnText = "⛅"
		bgCol = rgb(60, 68, 84)
		borderCol = rgb(90, 100, 120)
		if cfg.ThemeMode == ThemeModeEvening {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(75, 85, 105)
		}
		textCol = rgb(255, 255, 255)
	case 103:
		btnText = "🌙"
		bgCol = rgb(28, 30, 38)
		borderCol = rgb(50, 55, 70)
		if cfg.ThemeMode == ThemeModeNight {
			borderCol = rgb(61, 90, 254)
			bgCol = rgb(38, 42, 56)
		}
		textCol = rgb(255, 255, 255)

	case 104:
		btnText = "EN"
		bgCol = rgb(45, 52, 68)
		borderCol = rgb(80, 90, 110)
		if cfg.Lang == "en" {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(55, 68, 90)
		}
		textCol = rgb(255, 255, 255)
	case 105:
		btnText = "RU"
		bgCol = rgb(45, 52, 68)
		borderCol = rgb(80, 90, 110)
		if cfg.Lang == "ru" {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(55, 68, 90)
		}
		textCol = rgb(255, 255, 255)
	case 107:
		btnText = "CS"
		bgCol = rgb(45, 52, 68)
		borderCol = rgb(80, 90, 110)
		if cfg.Lang == "cs" {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(55, 68, 90)
		}
		textCol = rgb(255, 255, 255)

	case 106: // Sound Toggle
		if !cfg.SoundMuted {
			btnText = "🔊 Sound ON"
			if isCs() {
				btnText = "🔊 Se zvukem"
			} else if isRu() {
				btnText = "🔊 Со звуком"
			}
			bgCol = rgb(45, 52, 68)
			borderCol = rgb(0, 230, 118)
			textCol = rgb(255, 255, 255)
		} else {
			btnText = "🔇 Sound OFF"
			if isCs() {
				btnText = "🔇 Bez zvuku"
			} else if isRu() {
				btnText = "🔇 Без звука"
			}
			bgCol = rgb(38, 42, 52)
			borderCol = rgb(120, 130, 145)
			textCol = rgb(175, 185, 200)
		}
		hFont = uintptr(hUIFontBold)

	// Section 2: Intervals (Selected button glows rich green matching Apply button!)
	case 301, 302, 303, 304:
		var targetHours int
		switch dis.CtlID {
		case 301:
			targetHours = 1
			btnText = "1 hour"
			if isCs() {
				btnText = "1 hodina"
			} else if isRu() {
				btnText = "1 час"
			}
		case 302:
			targetHours = 3
			btnText = "3 hours"
			if isCs() {
				btnText = "3 hodiny"
			} else if isRu() {
				btnText = "3 часа"
			}
		case 303:
			targetHours = 6
			btnText = "6 hours"
			if isCs() {
				btnText = "6 hodin"
			} else if isRu() {
				btnText = "6 часов"
			}
		case 304:
			targetHours = 24
			btnText = "Once a day"
			if isCs() {
				btnText = "Jednou denně"
			} else if isRu() {
				btnText = "Раз в сутки"
			}
		}

		if cfg.IntervalHours == targetHours {
			// Rich green background like Apply button!
			bgCol = rgb(46, 125, 50)
			borderCol = rgb(0, 230, 118)
			textCol = rgb(255, 255, 255)
		} else {
			bgCol = rgb(69, 90, 100)
			borderCol = rgb(120, 144, 156)
			textCol = rgb(240, 240, 240)
		}
		hFont = uintptr(hUIFontBold)

	// Section 4: Scale (Selected button glows rich green matching Apply button!)
	case 451, 452, 453, 454:
		var isSelected bool
		switch dis.CtlID {
		case 451:
			btnText = "Compact"
			if isCs() {
				btnText = "Kompaktní"
			} else if isRu() {
				btnText = "Компактный"
			}
			hFont = uintptr(hFontScale1)
			isSelected = (cfg.FontSizeScale <= 1.5)
		case 452:
			btnText = "Moderate"
			if isCs() {
				btnText = "Střední"
			} else if isRu() {
				btnText = "Умеренный"
			}
			hFont = uintptr(hFontScale2)
			isSelected = (cfg.FontSizeScale > 1.5 && cfg.FontSizeScale <= 1.85)
		case 453:
			btnText = "Standard"
			if isCs() {
				btnText = "Standardní"
			} else if isRu() {
				btnText = "Стандартный"
			}
			hFont = uintptr(hFontScale3)
			isSelected = (cfg.FontSizeScale > 1.85 && cfg.FontSizeScale <= 2.1)
		case 454:
			btnText = "Large"
			if isCs() {
				btnText = "Velký"
			} else if isRu() {
				btnText = "Крупный"
			}
			hFont = uintptr(hFontScale4)
			isSelected = (cfg.FontSizeScale > 2.1)
		}

		if isSelected {
			// Rich green background like Apply button!
			bgCol = rgb(46, 125, 50)
			borderCol = rgb(0, 230, 118)
			textCol = rgb(255, 255, 255)
		} else {
			bgCol = rgb(69, 90, 100)
			borderCol = rgb(120, 144, 156)
			textCol = rgb(240, 240, 240)
		}

	// Bottom action buttons
	case 601:
		btnText = "⚡ Apply Now"
		if isCs() {
			btnText = "⚡ Použít nyní"
		} else if isRu() {
			btnText = "⚡ Применить"
		}
		bgCol = rgb(46, 125, 50)
		borderCol = rgb(0, 230, 118)
		textCol = rgb(255, 255, 255)

	case 602:
		btnText = "💾 Save & Close"
		if isCs() {
			btnText = "💾 Uložit a zavřít"
		} else if isRu() {
			btnText = "💾 Сохранить"
		}
		bgCol = rgb(211, 84, 0)
		borderCol = rgb(243, 156, 18)
		textCol = rgb(255, 255, 255)

	case 603:
		btnText = "🎲 Random"
		if isCs() {
			btnText = "🎲 Náhodně"
		} else if isRu() {
			btnText = "🎲 Случайно"
		}
		bgCol = rgb(123, 31, 162)
		borderCol = rgb(186, 104, 200)
		textCol = rgb(255, 255, 255)

	case 604:
		btnText = "Close"
		if isCs() {
			btnText = "Zavřít"
		} else if isRu() {
			btnText = "Закрыть"
		}
		bgCol = rgb(69, 90, 100)
		borderCol = rgb(120, 144, 156)
		textCol = rgb(240, 240, 240)

	case 605: // Footer Update Button
		if footerUpdateText != "" {
			btnText = footerUpdateText
		} else {
			btnText = fmt.Sprintf("%s (update)", AppVersion)
			if isCs() {
				btnText = fmt.Sprintf("%s (aktualizovat)", AppVersion)
			} else if isRu() {
				btnText = fmt.Sprintf("%s (обновить)", AppVersion)
			}
		}
		if cfg.ThemeMode == ThemeModeDay {
			bgCol = rgb(235, 240, 250)
			borderCol = rgb(180, 195, 215)
			textCol = rgb(30, 80, 160)
		} else if cfg.ThemeMode == ThemeModeNight {
			bgCol = rgb(28, 32, 44)
			borderCol = rgb(60, 75, 100)
			textCol = rgb(100, 180, 246)
		} else {
			bgCol = rgb(45, 52, 68)
			borderCol = rgb(80, 95, 120)
			textCol = rgb(129, 212, 250)
		}
		hFont = uintptr(hUIFontBold)

	case 606: // Footer Author GitHub Button
		btnText = "⭐ VladiMIR + AI"
		if cfg.ThemeMode == ThemeModeDay {
			bgCol = rgb(240, 244, 252)
			borderCol = rgb(185, 200, 225)
			textCol = rgb(25, 95, 195)
		} else if cfg.ThemeMode == ThemeModeNight {
			bgCol = rgb(32, 38, 52)
			borderCol = rgb(70, 90, 125)
			textCol = rgb(135, 195, 255)
		} else {
			bgCol = rgb(50, 60, 78)
			borderCol = rgb(90, 110, 140)
			textCol = rgb(145, 205, 255)
		}
		hFont = uintptr(hUIFontBold)
	}

	if isPressed {
		rc.Left += 1
		rc.Top += 1
	}

	hBrush, _, _ := procCreateSolidBrush.Call(uintptr(bgCol))
	procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), hBrush)
	procDeleteObject.Call(hBrush)

	// Outer border
	hPen, _, _ := procCreatePen.Call(0, 2, uintptr(borderCol))
	oldPen, _, _ := procSelectObject.Call(hDC, hPen)
	hNullBrush, _, _ := procGetStockObject.Call(5)
	oldBrush, _, _ := procSelectObject.Call(hDC, hNullBrush)
	procRectangle.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom))
	procSelectObject.Call(hDC, oldPen)
	procSelectObject.Call(hDC, oldBrush)
	procDeleteObject.Call(hPen)

	// Volumetric 3D Bevel (Inner Highlight on top/left, Shadow on bottom/right)
	clampCol := func(v int) int {
		if v < 0 { return 0 }
		if v > 255 { return 255 }
		return v
	}
	shiftColor := func(c uint32, amt int) uint32 {
		r := clampCol(int(c&0xFF) + amt)
		g := clampCol(int((c>>8)&0xFF) + amt)
		b := clampCol(int((c>>16)&0xFF) + amt)
		return uint32(r | (g << 8) | (b << 16))
	}

	hiColor := shiftColor(bgCol, 36)
	shColor := shiftColor(bgCol, -36)
	if isPressed {
		hiColor, shColor = shColor, hiColor
	}

	hPenHi, _, _ := procCreatePen.Call(0, 1, uintptr(hiColor))
	oldPenHi, _, _ := procSelectObject.Call(hDC, hPenHi)
	procMoveToEx.Call(hDC, uintptr(rc.Left+2), uintptr(rc.Top+2), 0)
	procLineTo.Call(hDC, uintptr(rc.Right-2), uintptr(rc.Top+2))
	procMoveToEx.Call(hDC, uintptr(rc.Left+2), uintptr(rc.Top+2), 0)
	procLineTo.Call(hDC, uintptr(rc.Left+2), uintptr(rc.Bottom-2))
	procSelectObject.Call(hDC, oldPenHi)
	procDeleteObject.Call(hPenHi)

	hPenSh, _, _ := procCreatePen.Call(0, 1, uintptr(shColor))
	oldPenSh, _, _ := procSelectObject.Call(hDC, hPenSh)
	procMoveToEx.Call(hDC, uintptr(rc.Left+2), uintptr(rc.Bottom-3), 0)
	procLineTo.Call(hDC, uintptr(rc.Right-2), uintptr(rc.Bottom-3))
	procMoveToEx.Call(hDC, uintptr(rc.Right-3), uintptr(rc.Top+2), 0)
	procLineTo.Call(hDC, uintptr(rc.Right-3), uintptr(rc.Bottom-2))
	procSelectObject.Call(hDC, oldPenSh)
	procDeleteObject.Call(hPenSh)

	procSetBkMode.Call(hDC, 1)
	procSetTextColor.Call(hDC, uintptr(textCol))
	oldFont, _, _ := procSelectObject.Call(hDC, hFont)

	pText := strPtr(btnText)
	procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(pText)), uintptr(len(syscall.StringToUTF16(btnText))-1), uintptr(unsafe.Pointer(&rc)), 0x0001|0x0004|0x0020)
	procSelectObject.Call(hDC, oldFont)

	return 1
}

func settingsWndProc(hwnd syscall.Handle, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_ERASEBKGND:
		hDC := wParam
		var rc RECT
		procGetClientRect.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&rc)))
		brush := hBrushEvening
		lineBrush := hBrushEveningLine
		if cfg.ThemeMode == ThemeModeDay {
			brush = hBrushDay
			lineBrush = hBrushDayLine
		} else if cfg.ThemeMode == ThemeModeNight {
			brush = hBrushNight
			lineBrush = hBrushNightLine
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), uintptr(brush))

		// Draw thin neat horizontal divider lines across full width
		rLine := RECT{Left: 0, Right: rc.Right}
		drawHLine := func(y int32) {
			rLine.Top = y
			rLine.Bottom = y + 1
			procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rLine)), uintptr(lineBrush))
		}
		drawHLine(46)  // 1. Above Themes
		drawHLine(214) // 2. Between Themes and Intervals
		drawHLine(296) // 3. Between Intervals and Fonts
		drawHLine(537) // 4. Between Fonts and Scale
		drawHLine(621) // 5. Between Scale and Status / Buttons
		return 1

	case WM_CTLCOLORSTATIC, WM_CTLCOLORBTN:
		hDC := wParam
		ctrl := syscall.Handle(lParam)
		if ctrl == divThemes || ctrl == divInterval || ctrl == divFonts || ctrl == divScale || ctrl == divBottom {
			lineBrush := hBrushEveningLine
			if cfg.ThemeMode == ThemeModeDay {
				lineBrush = hBrushDayLine
			} else if cfg.ThemeMode == ThemeModeNight {
				lineBrush = hBrushNightLine
			}
			return uintptr(lineBrush)
		}

		procSetBkMode.Call(hDC, 1)

		if ctrl == lblSep1 || ctrl == lblSep2 {
			procSetTextColor.Call(hDC, uintptr(rgb(120, 140, 165)))
			if cfg.ThemeMode == ThemeModeDay {
				procSetTextColor.Call(hDC, uintptr(rgb(160, 170, 185)))
				return uintptr(hBrushDay)
			} else if cfg.ThemeMode == ThemeModeNight {
				procSetTextColor.Call(hDC, uintptr(rgb(90, 100, 115)))
				return uintptr(hBrushNight)
			}
			return uintptr(hBrushEvening)
		}

		if isChecked(cbAll) && isThemeCheckbox(ctrl) {
			if cfg.ThemeMode == ThemeModeDay {
				procSetTextColor.Call(hDC, uintptr(rgb(145, 150, 160)))
				return uintptr(hBrushDay)
			} else if cfg.ThemeMode == ThemeModeNight {
				procSetTextColor.Call(hDC, uintptr(rgb(105, 115, 130)))
				return uintptr(hBrushNight)
			}
			procSetTextColor.Call(hDC, uintptr(rgb(135, 145, 160)))
			return uintptr(hBrushEvening)
		}

		if !isEnabled(ctrl) {
			if cfg.ThemeMode == ThemeModeDay {
				procSetTextColor.Call(hDC, uintptr(rgb(155, 160, 170)))
				return uintptr(hBrushDay)
			} else if cfg.ThemeMode == ThemeModeNight {
				procSetTextColor.Call(hDC, uintptr(rgb(100, 110, 125)))
				return uintptr(hBrushNight)
			}
			procSetTextColor.Call(hDC, uintptr(rgb(130, 140, 155)))
			return uintptr(hBrushEvening)
		}

		if cfg.ThemeMode == ThemeModeDay {
			procSetTextColor.Call(hDC, uintptr(rgb(30, 35, 45)))
			return uintptr(hBrushDay)
		} else if cfg.ThemeMode == ThemeModeNight {
			procSetTextColor.Call(hDC, uintptr(rgb(225, 230, 240)))
			return uintptr(hBrushNight)
		}
		procSetTextColor.Call(hDC, uintptr(rgb(240, 242, 245)))
		return uintptr(hBrushEvening)

	case WM_DRAWITEM:
		dis := (*DRAWITEMSTRUCT)(unsafe.Pointer(lParam))
		if dis != nil {
			return drawCustomButton(dis)
		}
		return 0

	case WM_COMMAND:
		id := int(wParam & 0xFFFF)
		switch id {
		case 101: // Day Theme
			cfg.ThemeMode = ThemeModeDay
			saveConfig()
			procInvalidateRect.Call(uintptr(hwnd), 0, 1)
			return 0
		case 102: // Evening Theme
			cfg.ThemeMode = ThemeModeEvening
			saveConfig()
			procInvalidateRect.Call(uintptr(hwnd), 0, 1)
			return 0
		case 103: // Night Theme
			cfg.ThemeMode = ThemeModeNight
			saveConfig()
			procInvalidateRect.Call(uintptr(hwnd), 0, 1)
			return 0

		case 104: // Language EN
			cfg.Lang = "en"
			saveConfig()
			updateTexts()
			updatePreviewCard()
			return 0
		case 105: // Language RU
			cfg.Lang = "ru"
			saveConfig()
			updateTexts()
			updatePreviewCard()
			return 0
		case 107: // Language CS
			cfg.Lang = "cs"
			saveConfig()
			updateTexts()
			updatePreviewCard()
			return 0

		case 106: // Toggle Sound
			cfg.SoundMuted = !cfg.SoundMuted
			saveConfig()
			procInvalidateRect.Call(uintptr(btnSound), 0, 1)
			if !cfg.SoundMuted {
				playSoftChime()
			}
			return 0

		case 201: // cbAll clicked
			if isChecked(cbAll) {
				cfg.Themes = []string{"all"}
				cfg.Theme = "all"
			}
			updateThemeCheckboxesState()
			saveConfig()
			return 0

		case 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214: // Individual theme checkbox clicked
			if isChecked(cbAll) {
				// While "All Random" is selected, individual categories cannot be checked
				procSendMessageW.Call(uintptr(lParam), BM_SETCHECK, BST_UNCHECKED, 0)
				return 0
			}
			var selected []string
			items := getIndividualThemeCheckboxes()
			for _, it := range items {
				if isChecked(it.h) {
					selected = append(selected, it.th)
				}
			}
			if len(selected) == 0 {
				procSendMessageW.Call(uintptr(cbAll), BM_SETCHECK, BST_CHECKED, 0)
				cfg.Themes = []string{"all"}
				cfg.Theme = "all"
				updateThemeCheckboxesState()
			} else {
				cfg.Themes = selected
				cfg.Theme = selected[0]
			}
			saveConfig()
			return 0

		case 301, 302, 303, 304:
			switch id {
			case 301:
				cfg.IntervalHours = 1
			case 302:
				cfg.IntervalHours = 3
			case 303:
				cfg.IntervalHours = 6
			case 304:
				cfg.IntervalHours = 24
			}
			saveConfig()
			procInvalidateRect.Call(uintptr(btnInt1h), 0, 1)
			procInvalidateRect.Call(uintptr(btnInt3h), 0, 1)
			procInvalidateRect.Call(uintptr(btnInt6h), 0, 1)
			procInvalidateRect.Call(uintptr(btnInt24h), 0, 1)
			return 0

		case 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416:
			fontRadios := []struct {
				id    uintptr
				h     syscall.Handle
				style string
			}{
				{401, rbFontSegoe, "segoe"},
				{402, rbFontBahn, "bahnschrift"},
				{403, rbFontArial, "arial"},
				{404, rbFontVerdana, "verdana"},
				{405, rbFontGeorgia, "georgia"},
				{406, rbFontCorbel, "corbel"},
				{407, rbFontPalatino, "palatino"},
				{408, rbFontFranklin, "franklin"},
				{409, rbFontConsolas, "consolas"},
				{410, rbFontTreb, "trebuchet"},
				{411, rbFontCambria, "cambria"},
				{412, rbFontGothic, "gothic"},
				{413, rbFontCandara, "candara"},
				{414, rbFontConstantia, "constantia"},
				{415, rbFontSegoePrint, "segoeprint"},
				{416, rbFontCalibri, "calibri"},
			}
			for _, fr := range fontRadios {
				if fr.id == uintptr(id) {
					procSendMessageW.Call(uintptr(fr.h), BM_SETCHECK, BST_CHECKED, 0)
					cfg.FontStyle = fr.style
				} else {
					procSendMessageW.Call(uintptr(fr.h), BM_SETCHECK, BST_UNCHECKED, 0)
				}
			}
			saveConfig()
			return 0

		case 451, 452, 453, 454:
			switch id {
			case 451:
				cfg.FontSizeScale = 1.4
			case 452:
				cfg.FontSizeScale = 1.7
			case 453:
				cfg.FontSizeScale = 2.0
			case 454:
				cfg.FontSizeScale = 2.25
			}
			saveConfig()
			procInvalidateRect.Call(uintptr(btnScaleCompact), 0, 1)
			procInvalidateRect.Call(uintptr(btnScaleModerate), 0, 1)
			procInvalidateRect.Call(uintptr(btnScaleStandard), 0, 1)
			procInvalidateRect.Call(uintptr(btnScaleLarge), 0, 1)
			return 0

		case 601: // ⚡ Apply Now (Instant Desktop Update without closing!)
			readCurrentUISelections()
			saveConfig()
			stTxt := "✓ Downloading 4K wallpaper and rendering calendar..."
			if isCs() {
				stTxt = "✓ Stahování 4K tapety a vykreslování kalendáře..."
			} else if isRu() {
				stTxt = "✓ Загрузка 4K UHD обоев и отрисовка календаря..."
			}
			procSetWindowTextW.Call(uintptr(lblStatusInfo), uintptr(unsafe.Pointer(strPtr(stTxt))))
			go func() {
				cycleWallpaper()
				doneTxt := "✓ Successfully applied to desktop!"
				if isCs() {
					doneTxt = "✓ 4K Tapeta a kalendář byly úspěšně nastaveny!"
				} else if isRu() {
					doneTxt = "✓ 4K Обои и календарь успешно установлены!"
				}
				procSetWindowTextW.Call(uintptr(lblStatusInfo), uintptr(unsafe.Pointer(strPtr(doneTxt))))
			}()
			return 0

		case 602: // 💾 Save & Close
			readCurrentUISelections()
			saveConfig()
			procDestroyWindow.Call(uintptr(hwndSettings))
			hwndSettings = 0
			go cycleWallpaper()
			return 0

		case 603: // 🎲 Random Theme
			allThemes := []string{"3d_abstract", "flowers", "ocean", "space", "nature", "animals", "cars", "trucks_offroad", "girls", "city", "cyberpunk", "minimalism", "anime"}
			rnd := allThemes[rand.Intn(len(allThemes))]
			cfg.Themes = []string{rnd}
			cfg.Theme = rnd
			selectCurrentThemeCheckboxes()
			saveConfig()
			updatePreviewCard()
			go cycleWallpaper()
			return 0

		case 604: // Close
			procDestroyWindow.Call(uintptr(hwndSettings))
			hwndSettings = 0
			go trimMemory()
			return 0

		case 605: // Footer Update Button
			triggerCheckForUpdates(true)
			return 0

		case 606: // Footer Author GitHub Button
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr("https://github.com/GinCz"))), 0, 0, 1)
			return 0
		}

	case WM_CLOSE:
		procDestroyWindow.Call(uintptr(hwndSettings))
		hwndSettings = 0
		go trimMemory()
		return 0
	}
	ret, _, _ := procDefWindowProcW.Call(uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

func wndProc(hwnd syscall.Handle, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_TRAYICON:
		msgType := uint32(lParam & 0xFFFF)
		switch msgType {
		case WM_LBUTTONDBLCLK:
			go cycleWallpaper()
			return 0
		case WM_RBUTTONUP, WM_CONTEXTMENU:
			showContextMenu(hwnd)
			return 0
		}
		return 0

	case WM_COMMAND:
		switch wParam {
		case IDM_CHANGE_NOW:
			go cycleWallpaper()
		case IDM_SETTINGS:
			createSettingsWindow()
		case IDM_OPEN_DIR:
			exePath, _ := os.Executable()
			dir := filepath.Dir(exePath)
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(dir))), 0, 0, 1)
		case IDM_VERSION_CHECK:
			triggerCheckForUpdates(true)
		case IDM_EXIT:
			procShell_NotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
			procPostQuitMessage.Call(0)
		}
		return 0
	}
	ret, _, _ := procDefWindowProcW.Call(uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

func loadAppIcon() syscall.Handle {
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	hIco, _, _ := procLoadImageW.Call(hInstance, 1, uintptr(IMAGE_ICON), 16, 16, uintptr(LR_DEFAULTSIZE|LR_SHARED))
	if hIco != 0 {
		return syscall.Handle(hIco)
	}

	exePath, _ := os.Executable()
	diskIco := filepath.Join(filepath.Dir(exePath), "app.ico")
	if _, err := os.Stat(diskIco); err == nil {
		hIcoDisk, _, _ := procLoadImageW.Call(0, uintptr(unsafe.Pointer(strPtr(diskIco))), uintptr(IMAGE_ICON), 16, 16, uintptr(LR_LOADFROMFILE))
		if hIcoDisk != 0 {
			return syscall.Handle(hIcoDisk)
		}
	}

	if len(embeddedAppICO) > 0 {
		tmpIco := filepath.Join(os.TempDir(), "gin_wallpaper_tray.ico")
		os.WriteFile(tmpIco, embeddedAppICO, 0644)
		hTmp, _, _ := procLoadImageW.Call(0, uintptr(unsafe.Pointer(strPtr(tmpIco))), uintptr(IMAGE_ICON), 16, 16, uintptr(LR_LOADFROMFILE))
		if hTmp != 0 {
			return syscall.Handle(hTmp)
		}
	}

	return 0
}

func main() {
	runtime.LockOSThread()

	appDataDir = filepath.Join(os.Getenv("APPDATA"), "GIN-Wallpaper-Calend")
	os.MkdirAll(appDataDir, 0755)

	rand.Seed(time.Now().UnixNano())
	loadConfig()

	isPostUpdate := false
	for _, arg := range os.Args[1:] {
		if strings.ToLower(arg) == "--updated" || strings.ToLower(arg) == "/updated" {
			isPostUpdate = true
			break
		}
	}
	if isPostUpdate {
		suppressNextChime = true
		playUpdateSoftDrop()
	}

	var err error
	parsedFont, err = truetype.Parse(embeddedFontBytes)
	if err != nil {
		fmt.Printf("Font error: %v\n", err)
	}

	hIconApp = loadAppIcon()

	wc := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(wndProc),
		LpszClassName: strPtr("GIN_Wallpaper_TrayClass"),
		HIcon:         hIconApp,
		HIconSm:       hIconApp,
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_Wallpaper_TrayClass"))),
		uintptr(unsafe.Pointer(strPtr("GIN_Wallpaper_TrayClass"))),
		0, 0, 0, 0, 0, 0, 0, 0, 0,
	)
	hwndTray = syscall.Handle(hwnd)

	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.Hwnd = hwndTray
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconApp

	tip, _ := syscall.UTF16FromString(fmt.Sprintf("GIN-Wallpaper-Calend %s", AppVersion))
	for i := 0; i < len(tip) && i < 127; i++ {
		nid.SzTip[i] = tip[i]
	}

	procShell_NotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))

	go cycleWallpaper()

	go func() {
		for {
			hrs := cfg.IntervalHours
			if hrs <= 0 {
				hrs = 3
			}
			time.Sleep(time.Duration(hrs) * time.Hour)
			cycleWallpaper()
		}
	}()

	// Automated silent background update check every 2 hours
	go func() {
		// Initial background check 2 minutes after launch
		time.Sleep(2 * time.Minute)
		triggerCheckForUpdates(false)
		for {
			time.Sleep(2 * time.Hour)
			triggerCheckForUpdates(false)
		}
	}()

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

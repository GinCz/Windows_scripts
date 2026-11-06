package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	_ "image/png"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
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
	procShellExecuteW         = shell32.NewProc("ShellExecuteW")
	procSetWindowTextW        = user32.NewProc("SetWindowTextW")
	procGetClientRect         = user32.NewProc("GetClientRect")
	procInvalidateRect        = user32.NewProc("InvalidateRect")
	procDrawTextW             = user32.NewProc("DrawTextW")
	procMessageBoxW           = user32.NewProc("MessageBoxW")

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
)

const (
	AppVersion = "v011"

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
	Theme         string  `json:"theme"`
	IntervalHours int     `json:"interval_hours"`
	FontSizeScale float64 `json:"font_size_scale"`
	FontStyle     string  `json:"font_style"`
	ThemeMode     int     `json:"theme_mode"`
	Lang          string  `json:"lang"`
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
	hFontImpact     syscall.Handle
	hFontGothic     syscall.Handle
	hFontCandara    syscall.Handle
	hFontConstantia syscall.Handle
	hFontBigPrev    syscall.Handle

	// Controls
	lblTitle       syscall.Handle
	lblSecThemes   syscall.Handle
	lblSecInt      syscall.Handle
	lblSecFonts    syscall.Handle
	lblSecScale    syscall.Handle
	lblStatusInfo  syscall.Handle
	hwndPreviewBox syscall.Handle

	// Top Bar Buttons
	btnModeDay, btnModeEvening, btnModeNight syscall.Handle
	btnLangEN, btnLangRU                     syscall.Handle

	// Radio buttons - Themes (12)
	rbAll, rbAbstract, rbWindows, rbLinux, rbSpace, rbNature syscall.Handle
	rbCars, rbCity, rbCyberpunk, rbMinimal, rbAnimals, rbAnime syscall.Handle

	// Radio buttons - Intervals (4)
	rb1h, rb3h, rb6h, rb24h syscall.Handle

	// Radio buttons - Font styles (12 fonts in 2 columns)
	rbFontSegoe, rbFontBahn, rbFontArial, rbFontVerdana, rbFontGeorgia, rbFontCorbel syscall.Handle
	rbFontConsolas, rbFontTreb, rbFontImpact, rbFontGothic, rbFontCandara, rbFontConstantia syscall.Handle

	lblSampSegoe, lblSampBahn, lblSampArial, lblSampVerdana, lblSampGeorgia, lblSampCorbel syscall.Handle
	lblSampConsolas, lblSampTreb, lblSampImpact, lblSampGothic, lblSampCandara, lblSampConstantia syscall.Handle

	// Radio buttons - Font scale (3)
	rbFontNormal, rbFontLarge, rbFontHuge syscall.Handle

	// Action buttons (Bottom)
	btnApply, btnSave, btnRandom, btnClose syscall.Handle

	ruMonths = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	enMonths = []string{"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
	ruDays   = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
	enDays   = []string{"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
	ruFullDays = []string{"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
	enFullDays = []string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
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

func loadConfig() {
	cfg = Config{
		Theme:         "all",
		IntervalHours: 3,
		FontSizeScale: 0.8,
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
		cfg.FontSizeScale = 0.8
	}
	if cfg.FontStyle == "" {
		cfg.FontStyle = "segoe"
	}
	if cfg.Theme == "" {
		cfg.Theme = "all"
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

func getThemeQuery(theme string) string {
	switch theme {
	case "abstract":
		return "abstract"
	case "windows":
		return "windows"
	case "linux":
		return "linux"
	case "space":
		return "space"
	case "nature":
		return "nature"
	case "cars":
		return "supercar"
	case "city":
		return "city"
	case "cyberpunk":
		return "cyberpunk"
	case "minimalism":
		return "minimalism"
	case "animals":
		return "wildlife"
	case "anime":
		return "anime"
	default:
		all := []string{"abstract", "windows", "linux", "space", "nature", "supercar", "city", "cyberpunk", "minimalism", "wildlife", "anime"}
		return all[rand.Intn(len(all))]
	}
}

func downloadRandomWallpaper(w, h int) (image.Image, error) {
	client := &http.Client{Timeout: 15 * time.Second}
	themeQuery := getThemeQuery(cfg.Theme)

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
		fontFile = filepath.Join(fontsDir, "ariblk.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "arialbd.ttf")
		}
	case "verdana":
		fontFile = filepath.Join(fontsDir, "verdanab.ttf")
	case "consolas":
		fontFile = filepath.Join(fontsDir, "consolab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "consola.ttf")
		}
	case "trebuchet":
		fontFile = filepath.Join(fontsDir, "trebucbd.ttf")
	case "impact":
		fontFile = filepath.Join(fontsDir, "impact.ttf")
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
	if isRu() {
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
	if isRu() {
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
	mOpen := "📁 Open Program"
	// 4. Version & Check Update
	mVer := fmt.Sprintf("ℹ️ %s (Check for Updates)", AppVersion)
	// 5. Exit
	mExit := "❌ Exit"

	if isRu() {
		mChange = "🔄 Сменить обои"
		mSettings = "⚙️ Настройки"
		mOpen = "📁 Открыть программу"
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
		url := "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Wallpaper/version.json"
		client := &http.Client{Timeout: 8 * time.Second}
		resp, err := client.Get(url)
		if err != nil {
			if manual {
				t := "Update Check"
				m := "Unable to connect to update server. Please check your internet connection."
				if isRu() {
					t = "Проверка обновлений"
					m = "Не удалось подключиться к серверу обновлений. Проверьте интернет-соединение."
				}
				procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(m))), uintptr(unsafe.Pointer(strPtr(t))), MB_OK|MB_ICONWARN)
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
			t := "GIN-Wallpaper-Calend — Update Available"
			m := fmt.Sprintf("A new version is available: %s (current: %s).\n\nDo you want to download and install it now?", remoteVer, AppVersion)
			if isRu() {
				t = "GIN-Wallpaper-Calend — Доступно обновление"
				m = fmt.Sprintf("Доступна новая версия: %s (текущая: %s).\n\nСкачать и установить обновление прямо сейчас?", remoteVer, AppVersion)
			}
			r, _, _ := procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(m))), uintptr(unsafe.Pointer(strPtr(t))), MB_YESNO|MB_ICONINFO)
			if int(r) == IDYES {
				downloadAndApplyUpdate(info.DownloadURL, info.Installer)
			}
		} else if manual {
			t := "GIN-Wallpaper-Calend — Up to Date"
			m := fmt.Sprintf("✅ You have the latest version installed (%s).", AppVersion)
			if isRu() {
				t = "GIN-Wallpaper-Calend — Обновление"
				m = fmt.Sprintf("✅ У вас установлена самая актуальная версия (%s).", AppVersion)
			}
			procMessageBoxW.Call(0, uintptr(unsafe.Pointer(strPtr(m))), uintptr(unsafe.Pointer(strPtr(t))), MB_OK|MB_ICONINFO)
		}
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

	cmd := exec.Command(tmpExe)
	cmd.Start()
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

	// 12 Distinct Fonts for Samples (20pt Bold for crisp clarity without clipping)
	makeFont := func(name string) syscall.Handle {
		h, _, _ := procCreateFontW.Call(uintptr(20), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr(name))))
		return syscall.Handle(h)
	}

	if hFontSegoe == 0 {
		hFontSegoe = makeFont("Segoe UI")
	}
	if hFontBahn == 0 {
		hFontBahn = makeFont("Bahnschrift")
	}
	if hFontArial == 0 {
		hFontArial = makeFont("Arial")
	}
	if hFontVerdana == 0 {
		hFontVerdana = makeFont("Verdana")
	}
	if hFontGeorgia == 0 {
		hFontGeorgia = makeFont("Georgia")
	}
	if hFontCorbel == 0 {
		hFontCorbel = makeFont("Corbel")
	}
	if hFontConsolas == 0 {
		hFontConsolas = makeFont("Consolas")
	}
	if hFontTreb == 0 {
		hFontTreb = makeFont("Trebuchet MS")
	}
	if hFontImpact == 0 {
		hFontImpact = makeFont("Impact")
	}
	if hFontGothic == 0 {
		hFontGothic = makeFont("Century Gothic")
	}
	if hFontCandara == 0 {
		hFontCandara = makeFont("Candara")
	}
	if hFontConstantia == 0 {
		hFontConstantia = makeFont("Constantia")
	}

	// Big Live Preview Font (22pt Bold)
	if hFontBigPrev == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(24), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontBigPrev = syscall.Handle(h)
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
	winW, winH := 760, 750
	posX := 60
	posY := 30
	if posX+winW > screenW {
		posX = 20
	}
	if posY+winH > screenH {
		posY = 10
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

	// 1. Top Header bar: Title on Left, Themes & Languages on Right
	titleText := fmt.Sprintf("GIN-Wallpaper-Calend от VladiMIR+AI [%s]", AppVersion)
	lblTitle = syscall.Handle(createCtrl(staticClass, titleText, WS_CHILD|WS_VISIBLE, 20, 14, 350, 26, parent, 10))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblTitle), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Header Mode Buttons: Day, Evening, Night, EN, RU
	btnModeDay = syscall.Handle(createCtrl(btnClass, "☀️", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 410, 10, 42, 30, parent, 101))
	btnModeEvening = syscall.Handle(createCtrl(btnClass, "⛅", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 456, 10, 42, 30, parent, 102))
	btnModeNight = syscall.Handle(createCtrl(btnClass, "🌙", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 502, 10, 42, 30, parent, 103))

	btnLangEN = syscall.Handle(createCtrl(btnClass, "EN", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 565, 10, 52, 30, parent, 104))
	btnLangRU = syscall.Handle(createCtrl(btnClass, "RU", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 622, 10, 52, 30, parent, 105))

	// Section 1: Themes (12 in 2 columns)
	lblSecThemes = syscall.Handle(createCtrl(staticClass, "🎨 Wallpaper Theme / Тематика обоев:", WS_CHILD|WS_VISIBLE, 20, 48, 680, 20, parent, 11))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecThemes), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Column 1
	rbAll = createRadio("🎲 All Random (Mix)", 30, 70, 320, 20, parent, 201, true) // WS_GROUP start
	rbAbstract = createRadio("🌀 Abstract & 3D Art", 30, 92, 320, 20, parent, 202, false)
	rbWindows = createRadio("🪟 Windows Style (Fluent/11)", 30, 114, 320, 20, parent, 203, false)
	rbLinux = createRadio("🐧 Linux Style (Arch / Minimal OS)", 30, 136, 320, 20, parent, 204, false)
	rbSpace = createRadio("🚀 Space & Galaxies (Nebula)", 30, 158, 320, 20, parent, 205, false)
	rbNature = createRadio("🌿 Nature & Landscapes", 30, 180, 320, 20, parent, 206, false)

	// Column 2
	rbCars = createRadio("🏎️ Cars & Supercars", 370, 70, 320, 20, parent, 207, false)
	rbCity = createRadio("🌆 City & Architecture", 370, 92, 320, 20, parent, 208, false)
	rbCyberpunk = createRadio("⚡ Cyberpunk & Neon", 370, 114, 320, 20, parent, 209, false)
	rbMinimal = createRadio("🖤 Minimalism & Dark AMOLED", 370, 136, 320, 20, parent, 210, false)
	rbAnimals = createRadio("🐾 Wildlife & Animals", 370, 158, 320, 20, parent, 211, false)
	rbAnime = createRadio("⛩️ Anime & Digital Scenery", 370, 180, 320, 20, parent, 212, false)

	selectCurrentThemeRadio()

	// Section 2: Intervals
	lblSecInt = syscall.Handle(createCtrl(staticClass, "⏱ Auto-Change Interval / Интервал смены:", WS_CHILD|WS_VISIBLE, 20, 206, 680, 20, parent, 12))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecInt), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	rb1h = createRadio("1 hour", 30, 226, 120, 20, parent, 301, true) // WS_GROUP start
	rb3h = createRadio("3 hours (Recommended)", 160, 226, 200, 20, parent, 302, false)
	rb6h = createRadio("6 hours", 370, 226, 120, 20, parent, 303, false)
	rb24h = createRadio("24 hours (Daily)", 510, 226, 150, 20, parent, 304, false)

	selectCurrentIntervalRadio()

	// Section 3: Fonts (12 Distinct Choices in 2 Columns with 20pt Bold Sample, NO digits)
	lblSecFonts = syscall.Handle(createCtrl(staticClass, "🔤 Calendar Font Choices (12 Options in 2 Columns):", WS_CHILD|WS_VISIBLE, 20, 236, 700, 18, parent, 13))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecFonts), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	sampDate := getTodaySampleString()

	// Column 1 (Left): Fonts 1 to 6 (X = 25, W = 345)
	// Row 0: Font 1 - Segoe UI Bold
	rbFontSegoe = createRadio("1. 🔠 Segoe UI Bold", 25, 258, 345, 18, parent, 401, true) // WS_GROUP start
	lblSampSegoe = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 278, 325, 26, parent, 431))
	procSendMessageW.Call(uintptr(lblSampSegoe), WM_SETFONT, uintptr(hFontSegoe), 1)

	// Row 1: Font 2 - Bahnschrift
	rbFontBahn = createRadio("2. 📐 Bahnschrift", 25, 308, 345, 18, parent, 402, false)
	lblSampBahn = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 328, 325, 26, parent, 432))
	procSendMessageW.Call(uintptr(lblSampBahn), WM_SETFONT, uintptr(hFontBahn), 1)

	// Row 2: Font 3 - Arial Bold
	rbFontArial = createRadio("3. 🛡️ Arial Bold", 25, 358, 345, 18, parent, 403, false)
	lblSampArial = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 378, 325, 26, parent, 433))
	procSendMessageW.Call(uintptr(lblSampArial), WM_SETFONT, uintptr(hFontArial), 1)

	// Row 3: Font 4 - Verdana Bold
	rbFontVerdana = createRadio("4. 👓 Verdana Bold", 25, 408, 345, 18, parent, 404, false)
	lblSampVerdana = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 428, 325, 26, parent, 434))
	procSendMessageW.Call(uintptr(lblSampVerdana), WM_SETFONT, uintptr(hFontVerdana), 1)

	// Row 4: Font 5 - Georgia Bold
	rbFontGeorgia = createRadio("5. 📜 Georgia Bold", 25, 458, 345, 18, parent, 405, false)
	lblSampGeorgia = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 478, 325, 26, parent, 435))
	procSendMessageW.Call(uintptr(lblSampGeorgia), WM_SETFONT, uintptr(hFontGeorgia), 1)

	// Row 5: Font 6 - Corbel Bold
	rbFontCorbel = createRadio("6. 💎 Corbel Bold", 25, 508, 345, 18, parent, 406, false)
	lblSampCorbel = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 45, 528, 325, 26, parent, 436))
	procSendMessageW.Call(uintptr(lblSampCorbel), WM_SETFONT, uintptr(hFontCorbel), 1)

	// Column 2 (Right): Fonts 7 to 12 (X = 385, W = 345)
	// Row 0: Font 7 - Consolas Bold
	rbFontConsolas = createRadio("7. 💻 Consolas Bold", 385, 258, 345, 18, parent, 407, false)
	lblSampConsolas = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 278, 325, 26, parent, 437))
	procSendMessageW.Call(uintptr(lblSampConsolas), WM_SETFONT, uintptr(hFontConsolas), 1)

	// Row 1: Font 8 - Trebuchet MS Bold
	rbFontTreb = createRadio("8. ✒️ Trebuchet MS Bold", 385, 308, 345, 18, parent, 408, false)
	lblSampTreb = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 328, 325, 26, parent, 438))
	procSendMessageW.Call(uintptr(lblSampTreb), WM_SETFONT, uintptr(hFontTreb), 1)

	// Row 2: Font 9 - Impact
	rbFontImpact = createRadio("9. 💥 Impact", 385, 358, 345, 18, parent, 409, false)
	lblSampImpact = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 378, 325, 26, parent, 439))
	procSendMessageW.Call(uintptr(lblSampImpact), WM_SETFONT, uintptr(hFontImpact), 1)

	// Row 3: Font 10 - Century Gothic Bold
	rbFontGothic = createRadio("10. ⭕ Century Gothic Bold", 385, 408, 345, 18, parent, 410, false)
	lblSampGothic = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 428, 325, 26, parent, 440))
	procSendMessageW.Call(uintptr(lblSampGothic), WM_SETFONT, uintptr(hFontGothic), 1)

	// Row 4: Font 11 - Candara Bold
	rbFontCandara = createRadio("11. 🎨 Candara Bold", 385, 458, 345, 18, parent, 411, false)
	lblSampCandara = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 478, 325, 26, parent, 441))
	procSendMessageW.Call(uintptr(lblSampCandara), WM_SETFONT, uintptr(hFontCandara), 1)

	// Row 5: Font 12 - Constantia Bold
	rbFontConstantia = createRadio("12. 🏛️ Constantia Bold", 385, 508, 345, 18, parent, 412, false)
	lblSampConstantia = syscall.Handle(createCtrl(staticClass, sampDate, WS_CHILD|WS_VISIBLE, 405, 528, 325, 26, parent, 442))
	procSendMessageW.Call(uintptr(lblSampConstantia), WM_SETFONT, uintptr(hFontConstantia), 1)

	selectCurrentFontRadio()

	// Section 4: Scale
	lblSecScale = syscall.Handle(createCtrl(staticClass, "🔍 Calendar Scale / Размер календаря:", WS_CHILD|WS_VISIBLE, 20, 560, 700, 18, parent, 14))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecScale), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	rbFontNormal = createRadio("Standard (0.8x)", 30, 582, 190, 20, parent, 451, true) // WS_GROUP start
	rbFontLarge = createRadio("Large (1.5x, Recommended)", 230, 582, 260, 20, parent, 452, false)
	rbFontHuge = createRadio("Extra Large (2.2x)", 500, 582, 210, 20, parent, 453, false)

	if cfg.FontSizeScale <= 1.0 {
		procSendMessageW.Call(uintptr(rbFontNormal), BM_SETCHECK, BST_CHECKED, 0)
	} else if cfg.FontSizeScale >= 2.0 {
		procSendMessageW.Call(uintptr(rbFontHuge), BM_SETCHECK, BST_CHECKED, 0)
	} else {
		procSendMessageW.Call(uintptr(rbFontLarge), BM_SETCHECK, BST_CHECKED, 0)
	}

	// Status Info Label
	lblStatusInfo = syscall.Handle(createCtrl(staticClass, "Ready. Click 'Apply Now' to change desktop wallpaper immediately.", WS_CHILD|WS_VISIBLE, 25, 608, 700, 20, parent, 505))
	if hUIFontSm != 0 {
		procSendMessageW.Call(uintptr(lblStatusInfo), WM_SETFONT, uintptr(hUIFontSm), 1)
	}

	// Bottom Action Buttons (Y = 634, Height = 42)
	btnApply = syscall.Handle(createCtrl(btnClass, "⚡ Apply Now", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_GROUP|WS_TABSTOP, 25, 634, 168, 42, parent, 601))
	btnSave = syscall.Handle(createCtrl(btnClass, "💾 Save & Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 203, 634, 168, 42, parent, 602))
	btnRandom = syscall.Handle(createCtrl(btnClass, "🎲 Random Theme", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 381, 634, 168, 42, parent, 603))
	btnClose = syscall.Handle(createCtrl(btnClass, "Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 559, 634, 168, 42, parent, 604))
}

func getTodaySampleString() string {
	now := time.Now()
	wDay := int(now.Weekday())
	mDay := now.Day()
	mIdx := int(now.Month())
	yr := now.Year()

	if isRu() {
		return fmt.Sprintf("%s, %d %s %d года", ruFullDays[wDay], mDay, ruMonths[mIdx], yr)
	}
	return fmt.Sprintf("%s, %d %s %d", enFullDays[wDay], mDay, enMonths[mIdx], yr)
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

func selectCurrentThemeRadio() {
	switch cfg.Theme {
	case "abstract":
		procSendMessageW.Call(uintptr(rbAbstract), BM_SETCHECK, BST_CHECKED, 0)
	case "windows":
		procSendMessageW.Call(uintptr(rbWindows), BM_SETCHECK, BST_CHECKED, 0)
	case "linux":
		procSendMessageW.Call(uintptr(rbLinux), BM_SETCHECK, BST_CHECKED, 0)
	case "space":
		procSendMessageW.Call(uintptr(rbSpace), BM_SETCHECK, BST_CHECKED, 0)
	case "nature":
		procSendMessageW.Call(uintptr(rbNature), BM_SETCHECK, BST_CHECKED, 0)
	case "cars":
		procSendMessageW.Call(uintptr(rbCars), BM_SETCHECK, BST_CHECKED, 0)
	case "city":
		procSendMessageW.Call(uintptr(rbCity), BM_SETCHECK, BST_CHECKED, 0)
	case "cyberpunk":
		procSendMessageW.Call(uintptr(rbCyberpunk), BM_SETCHECK, BST_CHECKED, 0)
	case "minimalism":
		procSendMessageW.Call(uintptr(rbMinimal), BM_SETCHECK, BST_CHECKED, 0)
	case "animals":
		procSendMessageW.Call(uintptr(rbAnimals), BM_SETCHECK, BST_CHECKED, 0)
	case "anime":
		procSendMessageW.Call(uintptr(rbAnime), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rbAll), BM_SETCHECK, BST_CHECKED, 0)
	}
}

func selectCurrentIntervalRadio() {
	switch cfg.IntervalHours {
	case 1:
		procSendMessageW.Call(uintptr(rb1h), BM_SETCHECK, BST_CHECKED, 0)
	case 6:
		procSendMessageW.Call(uintptr(rb6h), BM_SETCHECK, BST_CHECKED, 0)
	case 24:
		procSendMessageW.Call(uintptr(rb24h), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rb3h), BM_SETCHECK, BST_CHECKED, 0)
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
	case "consolas":
		procSendMessageW.Call(uintptr(rbFontConsolas), BM_SETCHECK, BST_CHECKED, 0)
	case "trebuchet":
		procSendMessageW.Call(uintptr(rbFontTreb), BM_SETCHECK, BST_CHECKED, 0)
	case "impact":
		procSendMessageW.Call(uintptr(rbFontImpact), BM_SETCHECK, BST_CHECKED, 0)
	case "gothic":
		procSendMessageW.Call(uintptr(rbFontGothic), BM_SETCHECK, BST_CHECKED, 0)
	case "candara":
		procSendMessageW.Call(uintptr(rbFontCandara), BM_SETCHECK, BST_CHECKED, 0)
	case "constantia":
		procSendMessageW.Call(uintptr(rbFontConstantia), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rbFontSegoe), BM_SETCHECK, BST_CHECKED, 0)
	}
}

func updateTexts() {
	ru := isRu()
	setTxt := func(h syscall.Handle, txt string) {
		procSetWindowTextW.Call(uintptr(h), uintptr(unsafe.Pointer(strPtr(txt))))
	}

	wTitle := fmt.Sprintf("GIN-Wallpaper-Calend %s — Settings & Themes", AppVersion)
	if ru {
		wTitle = fmt.Sprintf("GIN-Wallpaper-Calend %s — Настройки и Темы", AppVersion)
	}
	procSetWindowTextW.Call(uintptr(hwndSettings), uintptr(unsafe.Pointer(strPtr(wTitle))))

	sampDate := getTodaySampleString()

	setTxt(lblSampSegoe, sampDate)
	setTxt(lblSampBahn, sampDate)
	setTxt(lblSampArial, sampDate)
	setTxt(lblSampVerdana, sampDate)
	setTxt(lblSampGeorgia, sampDate)
	setTxt(lblSampCorbel, sampDate)
	setTxt(lblSampConsolas, sampDate)
	setTxt(lblSampTreb, sampDate)
	setTxt(lblSampImpact, sampDate)
	setTxt(lblSampGothic, sampDate)
	setTxt(lblSampCandara, sampDate)
	setTxt(lblSampConstantia, sampDate)

	if ru {
		setTxt(lblSecThemes, "🎨 Тематика обоев (выберите желаемый стиль):")
		setTxt(rbAll, "🎲 Все подряд (Случайный микс)")
		setTxt(rbAbstract, "🌀 Абстракция и 3D рендеры")
		setTxt(rbWindows, "🪟 В стиле Windows (11 / Fluent)")
		setTxt(rbLinux, "🐧 В стиле Linux (Arch / Minimal OS)")
		setTxt(rbSpace, "🚀 Космос и Галактики (Nebula)")
		setTxt(rbNature, "🌿 Природа и пейзажи (Горы, Океан)")
		setTxt(rbCars, "🏎️ Автомобили и Суперкары")
		setTxt(rbCity, "🌆 Города и Архитектура (Skylines)")
		setTxt(rbCyberpunk, "⚡ Киберпанк и Неон (Synthwave)")
		setTxt(rbMinimal, "🖤 Минимализм и Dark AMOLED")
		setTxt(rbAnimals, "🐾 Животные и Дикая природа")
		setTxt(rbAnime, "⛩️ Аниме и Цифровой Арт")

		setTxt(lblSecInt, "⏱ Интервал автоматической смены обоев:")
		setTxt(rb1h, "1 час")
		setTxt(rb3h, "3 часа (Оптимально)")
		setTxt(rb6h, "6 часов")
		setTxt(rb24h, "1 раз в сутки")

		setTxt(lblSecFonts, "🔤 Выбор шрифта календаря (12 вариантов в 2 столбика):")
		setTxt(rbFontSegoe, "1. 🔠 Segoe UI Bold")
		setTxt(rbFontBahn, "2. 📐 Bahnschrift")
		setTxt(rbFontArial, "3. 🛡️ Arial Bold")
		setTxt(rbFontVerdana, "4. 👓 Verdana Bold")
		setTxt(rbFontGeorgia, "5. 📜 Georgia Bold")
		setTxt(rbFontCorbel, "6. 💎 Corbel Bold")
		setTxt(rbFontConsolas, "7. 💻 Consolas Bold")
		setTxt(rbFontTreb, "8. ✒️ Trebuchet MS Bold")
		setTxt(rbFontImpact, "9. 💥 Impact")
		setTxt(rbFontGothic, "10. ⭕ Century Gothic Bold")
		setTxt(rbFontCandara, "11. 🎨 Candara Bold")
		setTxt(rbFontConstantia, "12. 🏛️ Constantia Bold")

		setTxt(lblSecScale, "🔍 Масштаб и размер календаря:")
		setTxt(rbFontNormal, "Стандартный (0.8x)")
		setTxt(rbFontLarge, "Крупный (1.5x, Рекомендуется)")
		setTxt(rbFontHuge, "Очень крупный (2.2x)")

		setTxt(lblStatusInfo, "Готово. Нажмите «Применить сейчас», чтобы сразу сменить обои и календарь.")
	} else {
		setTxt(lblSecThemes, "🎨 Wallpaper Theme (Select desired photo style):")
		setTxt(rbAll, "🎲 All Random (Mix of all themes)")
		setTxt(rbAbstract, "🌀 Abstract & 3D Renders")
		setTxt(rbWindows, "🪟 Windows Style (Fluent / 11)")
		setTxt(rbLinux, "🐧 Linux Style (Arch / Minimal OS)")
		setTxt(rbSpace, "🚀 Space & Galaxies (Nebula)")
		setTxt(rbNature, "🌿 Nature & Landscapes")
		setTxt(rbCars, "🏎️ Cars & Supercars")
		setTxt(rbCity, "🌆 City & Architecture (Skylines)")
		setTxt(rbCyberpunk, "⚡ Cyberpunk & Neon (Synthwave)")
		setTxt(rbMinimal, "🖤 Minimalism & Dark AMOLED")
		setTxt(rbAnimals, "🐾 Wildlife & Animals")
		setTxt(rbAnime, "⛩️ Anime & Digital Scenery")

		setTxt(lblSecInt, "⏱ Auto-Change Interval:")
		setTxt(rb1h, "1 hour")
		setTxt(rb3h, "3 hours (Recommended)")
		setTxt(rb6h, "6 hours")
		setTxt(rb24h, "24 hours (Daily)")

		setTxt(lblSecFonts, "🔤 Calendar Font Choices (12 Options in 2 Columns):")
		setTxt(rbFontSegoe, "1. 🔠 Segoe UI Bold")
		setTxt(rbFontBahn, "2. 📐 Bahnschrift")
		setTxt(rbFontArial, "3. 🛡️ Arial Bold")
		setTxt(rbFontVerdana, "4. 👓 Verdana Bold")
		setTxt(rbFontGeorgia, "5. 📜 Georgia Bold")
		setTxt(rbFontCorbel, "6. 💎 Corbel Bold")
		setTxt(rbFontConsolas, "7. 💻 Consolas Bold")
		setTxt(rbFontTreb, "8. ✒️ Trebuchet MS Bold")
		setTxt(rbFontImpact, "9. 💥 Impact")
		setTxt(rbFontGothic, "10. ⭕ Century Gothic Bold")
		setTxt(rbFontCandara, "11. 🎨 Candara Bold")
		setTxt(rbFontConstantia, "12. 🏛️ Constantia Bold")

		setTxt(lblSecScale, "🔍 Calendar Scale and Size:")
		setTxt(rbFontNormal, "Standard (0.8x)")
		setTxt(rbFontLarge, "Large (1.5x, Recommended)")
		setTxt(rbFontHuge, "Extra Large (2.2x)")

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
	if isChecked(rbAbstract) {
		cfg.Theme = "abstract"
	} else if isChecked(rbWindows) {
		cfg.Theme = "windows"
	} else if isChecked(rbLinux) {
		cfg.Theme = "linux"
	} else if isChecked(rbSpace) {
		cfg.Theme = "space"
	} else if isChecked(rbNature) {
		cfg.Theme = "nature"
	} else if isChecked(rbCars) {
		cfg.Theme = "cars"
	} else if isChecked(rbCity) {
		cfg.Theme = "city"
	} else if isChecked(rbCyberpunk) {
		cfg.Theme = "cyberpunk"
	} else if isChecked(rbMinimal) {
		cfg.Theme = "minimalism"
	} else if isChecked(rbAnimals) {
		cfg.Theme = "animals"
	} else if isChecked(rbAnime) {
		cfg.Theme = "anime"
	} else {
		cfg.Theme = "all"
	}

	if isChecked(rb1h) {
		cfg.IntervalHours = 1
	} else if isChecked(rb6h) {
		cfg.IntervalHours = 6
	} else if isChecked(rb24h) {
		cfg.IntervalHours = 24
	} else {
		cfg.IntervalHours = 3
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
	} else if isChecked(rbFontConsolas) {
		cfg.FontStyle = "consolas"
	} else if isChecked(rbFontTreb) {
		cfg.FontStyle = "trebuchet"
	} else if isChecked(rbFontImpact) {
		cfg.FontStyle = "impact"
	} else if isChecked(rbFontGothic) {
		cfg.FontStyle = "gothic"
	} else if isChecked(rbFontCandara) {
		cfg.FontStyle = "candara"
	} else if isChecked(rbFontConstantia) {
		cfg.FontStyle = "constantia"
	} else {
		cfg.FontStyle = "segoe"
	}

	if isChecked(rbFontNormal) {
		cfg.FontSizeScale = 0.8
	} else if isChecked(rbFontHuge) {
		cfg.FontSizeScale = 2.2
	} else {
		cfg.FontSizeScale = 1.5
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

	// Bottom action buttons
	case 601:
		btnText = "⚡ Apply Now"
		if isRu() {
			btnText = "⚡ Применить"
		}
		bgCol = rgb(46, 125, 50)
		borderCol = rgb(0, 230, 118)
		textCol = rgb(255, 255, 255)

	case 602:
		btnText = "💾 Save & Close"
		if isRu() {
			btnText = "💾 Сохранить"
		}
		bgCol = rgb(211, 84, 0)
		borderCol = rgb(243, 156, 18)
		textCol = rgb(255, 255, 255)

	case 603:
		btnText = "🎲 Random"
		if isRu() {
			btnText = "🎲 Случайно"
		}
		bgCol = rgb(123, 31, 162)
		borderCol = rgb(186, 104, 200)
		textCol = rgb(255, 255, 255)

	case 604:
		btnText = "Close"
		if isRu() {
			btnText = "Закрыть"
		}
		bgCol = rgb(69, 90, 100)
		borderCol = rgb(120, 144, 156)
		textCol = rgb(240, 240, 240)
	}

	if isPressed {
		rc.Left += 1
		rc.Top += 1
	}

	hBrush, _, _ := procCreateSolidBrush.Call(uintptr(bgCol))
	procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), hBrush)
	procDeleteObject.Call(hBrush)

	hPen, _, _ := procCreatePen.Call(0, 2, uintptr(borderCol))
	oldPen, _, _ := procSelectObject.Call(hDC, hPen)
	hNullBrush, _, _ := procGetStockObject.Call(5)
	oldBrush, _, _ := procSelectObject.Call(hDC, hNullBrush)
	procRectangle.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom))
	procSelectObject.Call(hDC, oldPen)
	procSelectObject.Call(hDC, oldBrush)
	procDeleteObject.Call(hPen)

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
		if cfg.ThemeMode == ThemeModeDay {
			brush = hBrushDay
		} else if cfg.ThemeMode == ThemeModeNight {
			brush = hBrushNight
		}
		procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), uintptr(brush))
		return 1

	case WM_CTLCOLORSTATIC:
		hDC := wParam
		procSetBkMode.Call(hDC, 1)

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

		case 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212:
			themeRadios := []struct {
				id uintptr
				h  syscall.Handle
				th string
			}{
				{201, rbAll, "all"},
				{202, rbAbstract, "abstract"},
				{203, rbWindows, "windows"},
				{204, rbLinux, "linux"},
				{205, rbSpace, "space"},
				{206, rbNature, "nature"},
				{207, rbCars, "cars"},
				{208, rbCity, "city"},
				{209, rbCyberpunk, "cyberpunk"},
				{210, rbMinimal, "minimalism"},
				{211, rbAnimals, "animals"},
				{212, rbAnime, "anime"},
			}
			for _, tr := range themeRadios {
				if tr.id == uintptr(id) {
					procSendMessageW.Call(uintptr(tr.h), BM_SETCHECK, BST_CHECKED, 0)
					cfg.Theme = tr.th
				} else {
					procSendMessageW.Call(uintptr(tr.h), BM_SETCHECK, BST_UNCHECKED, 0)
				}
			}
			saveConfig()
			return 0

		case 301, 302, 303, 304:
			intRadios := []struct {
				id  uintptr
				h   syscall.Handle
				val int
			}{
				{301, rb1h, 1},
				{302, rb3h, 3},
				{303, rb6h, 6},
				{304, rb24h, 24},
			}
			for _, ir := range intRadios {
				if ir.id == uintptr(id) {
					procSendMessageW.Call(uintptr(ir.h), BM_SETCHECK, BST_CHECKED, 0)
					cfg.IntervalHours = ir.val
				} else {
					procSendMessageW.Call(uintptr(ir.h), BM_SETCHECK, BST_UNCHECKED, 0)
				}
			}
			saveConfig()
			return 0

		case 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412:
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
				{407, rbFontConsolas, "consolas"},
				{408, rbFontTreb, "trebuchet"},
				{409, rbFontImpact, "impact"},
				{410, rbFontGothic, "gothic"},
				{411, rbFontCandara, "candara"},
				{412, rbFontConstantia, "constantia"},
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

		case 451, 452, 453:
			scaleRadios := []struct {
				id  uintptr
				h   syscall.Handle
				val float64
			}{
				{451, rbFontNormal, 0.8},
				{452, rbFontLarge, 1.5},
				{453, rbFontHuge, 2.2},
			}
			for _, sr := range scaleRadios {
				if sr.id == uintptr(id) {
					procSendMessageW.Call(uintptr(sr.h), BM_SETCHECK, BST_CHECKED, 0)
					cfg.FontSizeScale = sr.val
				} else {
					procSendMessageW.Call(uintptr(sr.h), BM_SETCHECK, BST_UNCHECKED, 0)
				}
			}
			saveConfig()
			return 0

		case 601: // ⚡ Apply Now (Instant Desktop Update without closing!)
			readCurrentUISelections()
			saveConfig()
			stTxt := "✓ Downloading 4K wallpaper and rendering calendar..."
			if isRu() {
				stTxt = "✓ Загрузка 4K UHD обоев и отрисовка календаря..."
			}
			procSetWindowTextW.Call(uintptr(lblStatusInfo), uintptr(unsafe.Pointer(strPtr(stTxt))))
			go func() {
				cycleWallpaper()
				doneTxt := "✓ Successfully applied to desktop!"
				if isRu() {
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
			allThemes := []string{"abstract", "windows", "linux", "space", "nature", "cars", "city", "cyberpunk", "minimalism", "animals", "anime"}
			cfg.Theme = allThemes[rand.Intn(len(allThemes))]
			selectCurrentThemeRadio()
			saveConfig()
			updatePreviewCard()
			go cycleWallpaper()
			return 0

		case 604: // Close
			procDestroyWindow.Call(uintptr(hwndSettings))
			hwndSettings = 0
			return 0
		}

	case WM_CLOSE:
		procDestroyWindow.Call(uintptr(hwndSettings))
		hwndSettings = 0
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

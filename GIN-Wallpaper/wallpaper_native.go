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
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"syscall"
	"time"
	"unsafe"

	"github.com/golang/freetype/truetype"
	"golang.org/x/image/font"
	"golang.org/x/image/math/fixed"
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
	MF_SEPARATOR = 0x00000800
	TPM_RIGHTBUTTON = 0x0002

	IDM_VERSION_CHECK = 1000
	IDM_CHANGE_NOW    = 1001
	IDM_SETTINGS      = 1002
	IDM_OPEN_DIR      = 1003
	IDM_EXIT          = 1004

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
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

	// UI Theme modes (GIN-VPN Standard)
	ThemeModeDay     = 0 // ☀️ Day (Light)
	ThemeModeEvening = 1 // ⛅ Evening (Graphite / Slate)
	ThemeModeNight   = 2 // 🌙 Night (Dark OLED)
)

type Config struct {
	Theme         string  `json:"theme"`
	IntervalHours int     `json:"interval_hours"`
	FontSizeScale float64 `json:"font_size_scale"`
	FontStyle     string  `json:"font_style"`
	ThemeMode     int     `json:"theme_mode"` // 0: Day, 1: Evening, 2: Night
	Lang          string  `json:"lang"`       // "en" (default) or "ru"
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

	// Brushes for window background
	hBrushDay     syscall.Handle
	hBrushEvening syscall.Handle
	hBrushNight   syscall.Handle

	// Fonts for UI
	hUIFont     syscall.Handle
	hUIFontBold syscall.Handle
	hUIFontSm   syscall.Handle

	// Specific HFONTs for font preview labels
	hFontSegoe    syscall.Handle
	hFontBahn     syscall.Handle
	hFontDejavu   syscall.Handle
	hFontConsolas syscall.Handle
	hFontTreb     syscall.Handle

	// Controls
	lblTitle      syscall.Handle
	lblSecThemes  syscall.Handle
	lblSecInt     syscall.Handle
	lblSecFonts   syscall.Handle
	lblSecScale   syscall.Handle
	lblStatusInfo syscall.Handle
	hwndPreviewBox syscall.Handle

	// Top Bar Buttons
	btnModeDay, btnModeEvening, btnModeNight syscall.Handle
	btnLangEN, btnLangRU                     syscall.Handle

	// Radio buttons - Themes (12)
	rbAll, rbAbstract, rbWindows, rbLinux, rbSpace, rbNature syscall.Handle
	rbCars, rbCity, rbCyberpunk, rbMinimal, rbAnimals, rbAnime syscall.Handle

	// Radio buttons - Intervals (4)
	rb1h, rb3h, rb6h, rb24h syscall.Handle

	// Radio buttons - Font styles (5)
	rbFontSegoe, rbFontBahn, rbFontDejavu, rbFontConsolas, rbFontTreb syscall.Handle
	lblSampSegoe, lblSampBahn, lblSampDejavu, lblSampConsolas, lblSampTreb syscall.Handle

	// Radio buttons - Font scale (3)
	rbFontNormal, rbFontLarge, rbFontHuge syscall.Handle

	// Action buttons (Bottom)
	btnApply, btnSave, btnRandom, btnClose syscall.Handle

	ruMonths = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	enMonths = []string{"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
	ruDays   = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
	enDays   = []string{"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
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
		FontSizeScale: 2.0,
		FontStyle:     "segoe",
		ThemeMode:     ThemeModeEvening, // Default GIN-VPN Evening (Graphite)
		Lang:          "en",             // Default English as requested
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

func getScreenResolution() (int, int) {
	w, _, _ := procGetSystemMetrics.Call(0)
	h, _, _ := procGetSystemMetrics.Call(1)
	if w == 0 || h == 0 {
		return 1920, 1080
	}
	return int(w), int(h)
}

// Wallhaven API structures
type WallhavenResp struct {
	Data []struct {
		Path string `json:"path"`
	} `json:"data"`
}

// Bing API structures
type BingResp struct {
	Images []struct {
		URL string `json:"url"`
	} `json:"images"`
}

func getThemeQuery(theme string) string {
	switch theme {
	case "abstract":
		return "abstract 3d wallpaper"
	case "windows":
		return "windows 11 wallpaper fluent"
	case "linux":
		return "linux minimal wallpaper arch unix"
	case "space":
		return "space galaxy nebula stars 4k"
	case "nature":
		return "nature landscape mountains 4k"
	case "cars":
		return "supercar sports car automotive 4k"
	case "city":
		return "city skyline night lights architecture"
	case "cyberpunk":
		return "cyberpunk neon synthwave future"
	case "minimalism":
		return "minimalism dark amoled clean"
	case "animals":
		return "wildlife animals nature predator"
	case "anime":
		return "anime scenery digital art landscape"
	default:
		all := []string{
			"abstract 3d wallpaper",
			"windows 11 wallpaper fluent",
			"linux minimal wallpaper arch unix",
			"space galaxy nebula stars 4k",
			"nature landscape mountains 4k",
			"supercar sports car automotive 4k",
			"city skyline night lights architecture",
			"cyberpunk neon synthwave future",
			"minimalism dark amoled clean",
			"wildlife animals nature predator",
			"anime scenery digital art landscape",
		}
		return all[rand.Intn(len(all))]
	}
}

func downloadRandomWallpaper(w, h int) (image.Image, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	themeQuery := getThemeQuery(cfg.Theme)

	// Stage 1: Wallhaven High-Res Query (works globally, 4K/UHD, categorized)
	wallhavenUrl := fmt.Sprintf("https://wallhaven.cc/api/v1/search?q=%s&atleast=%dx%d&purity=100&sorting=random",
		url.QueryEscape(themeQuery), w, h)
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

	// Stage 2: Microsoft Bing Curated Daily Wallpapers (100% Russia accessible, zero blockages)
	bingApiUrl := "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=ru-RU"
	respBing, err := client.Get(bingApiUrl)
	if err == nil && respBing.StatusCode == http.StatusOK {
		var bResp BingResp
		if json.NewDecoder(respBing.Body).Decode(&bResp) == nil && len(bResp.Images) > 0 {
			respBing.Body.Close()
			idx := rand.Intn(len(bResp.Images))
			fullBingUrl := "https://www.bing.com" + bResp.Images[idx].URL
			imgResp, err := client.Get(fullBingUrl)
			if err == nil && imgResp.StatusCode == http.StatusOK {
				defer imgResp.Body.Close()
				if img, _, err := image.Decode(imgResp.Body); err == nil {
					return img, nil
				}
			}
		} else {
			respBing.Body.Close()
		}
	}

	// Stage 3: Lorem Picsum Fallback
	picsumUrl := fmt.Sprintf("https://picsum.photos/%d/%d", w, h)
	respPic, err := client.Get(picsumUrl)
	if err == nil && respPic.StatusCode == http.StatusOK {
		defer respPic.Body.Close()
		if img, _, err := image.Decode(respPic.Body); err == nil {
			return img, nil
		}
	}

	// Stage 4: Emergency offline procedural wallpaper
	fallbackImg := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		ratio := float64(y) / float64(h)
		r := uint8(18 + ratio*20)
		g := uint8(24 + ratio*30)
		b := uint8(45 + ratio*60)
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
	case "consolas":
		fontFile = filepath.Join(fontsDir, "consolab.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "consola.ttf")
		}
	case "trebuchet":
		fontFile = filepath.Join(fontsDir, "trebucbd.ttf")
		if _, err := os.Stat(fontFile); err != nil {
			fontFile = filepath.Join(fontsDir, "trebuc.ttf")
		}
	case "dejavu":
		return parsedFont
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

func drawCalendar(rgba *image.RGBA, now time.Time, scale float64) {
	bounds := rgba.Bounds()
	if scale <= 0 {
		scale = 2.0
	}

	calW := int(380.0 * (scale / 2.0))
	calH := int(240.0 * (scale / 2.0))
	margin := int(40.0 * (scale / 2.0))

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
	borderColor := color.RGBA{130, 140, 180, 120}
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
	w, h := getScreenResolution()
	img, err := downloadRandomWallpaper(w, h)
	if err != nil {
		return
	}

	finalImg := renderCalendarOverlay(img)

	outPath := filepath.Join(appDataDir, "current_wallpaper.jpg")
	f, err := os.Create(outPath)
	if err == nil {
		jpeg.Encode(f, finalImg, &jpeg.Options{Quality: 94})
		f.Close()
		setWallpaperWin(outPath)
	}
}

func showContextMenu(hwnd syscall.Handle) {
	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}

	verTitle := "🖼 GIN-Wallpaper-Calend v008 (Check for Updates)"
	mChange := "🔄 Change Wallpaper Now"
	mSettings := "⚙️ Settings & Themes..."
	mOpen := "📁 Open Program Folder"
	mExit := "❌ Exit"

	if isRu() {
		verTitle = "🖼 GIN-Wallpaper-Calend v008 (Проверить обновление)"
		mChange = "🔄 Сменить обои сейчас"
		mSettings = "⚙️ Настройки и темы..."
		mOpen = "📁 Открыть папку программы"
		mExit = "❌ Выход"
	}

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_VERSION_CHECK, uintptr(unsafe.Pointer(strPtr(verTitle))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHANGE_NOW, uintptr(unsafe.Pointer(strPtr(mChange))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETTINGS, uintptr(unsafe.Pointer(strPtr(mSettings))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DIR, uintptr(unsafe.Pointer(strPtr(mOpen))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr(mExit))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(uintptr(hwnd))
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, uintptr(hwnd), 0)
	procDestroyMenu.Call(hMenu)
}

func initThemeBrushes() {
	if hBrushDay == 0 {
		bDay, _, _ := procCreateSolidBrush.Call(uintptr(rgb(244, 245, 248)))
		hBrushDay = syscall.Handle(bDay)
	}
	if hBrushEvening == 0 {
		bEve, _, _ := procCreateSolidBrush.Call(uintptr(rgb(45, 50, 62))) // GIN-VPN Graphite Slate
		hBrushEvening = syscall.Handle(bEve)
	}
	if hBrushNight == 0 {
		bNight, _, _ := procCreateSolidBrush.Call(uintptr(rgb(18, 20, 26))) // Dark OLED
		hBrushNight = syscall.Handle(bNight)
	}
}

func initFonts() {
	if hUIFont == 0 {
		hF, _, _ := procCreateFontW.Call(
			uintptr(17), 0, 0, 0,
			400, // FW_NORMAL
			0, 0, 0, 1, 0, 0, 0, 0,
			uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
		)
		hUIFont = syscall.Handle(hF)
	}
	if hUIFontBold == 0 {
		hFB, _, _ := procCreateFontW.Call(
			uintptr(18), 0, 0, 0,
			700, // FW_BOLD
			0, 0, 0, 1, 0, 0, 0, 0,
			uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
		)
		hUIFontBold = syscall.Handle(hFB)
	}
	if hUIFontSm == 0 {
		hFS, _, _ := procCreateFontW.Call(
			uintptr(14), 0, 0, 0,
			400,
			0, 0, 0, 1, 0, 0, 0, 0,
			uintptr(unsafe.Pointer(strPtr("Segoe UI"))),
		)
		hUIFontSm = syscall.Handle(hFS)
	}

	// Distinct fonts for each preview line
	if hFontSegoe == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(15), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
		hFontSegoe = syscall.Handle(h)
	}
	if hFontBahn == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(15), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Bahnschrift"))))
		hFontBahn = syscall.Handle(h)
	}
	if hFontDejavu == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(15), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Arial"))))
		hFontDejavu = syscall.Handle(h)
	}
	if hFontConsolas == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(15), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Consolas"))))
		hFontConsolas = syscall.Handle(h)
	}
	if hFontTreb == 0 {
		h, _, _ := procCreateFontW.Call(uintptr(15), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 0, 0, uintptr(unsafe.Pointer(strPtr("Trebuchet MS"))))
		hFontTreb = syscall.Handle(h)
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

	screenW, screenH := getScreenResolution()
	winW, winH := 700, 785
	posX := (screenW - winW) / 2
	posY := (screenH - winH) / 2
	if posX < 0 {
		posX = 50
	}
	if posY < 0 {
		posY = 40
	}

	wTitle := "GIN-Wallpaper-Calend v008 — Settings & Themes"
	if isRu() {
		wTitle = "GIN-Wallpaper-Calend v008 — Настройки и Темы"
	}

	wnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_Wallpaper_SettingsClass"))),
		uintptr(unsafe.Pointer(strPtr(wTitle))),
		WS_OVERLAPPEDWINDOW&^0x00040000,
		uintptr(posX), uintptr(posY), uintptr(winW), uintptr(winH),
		0, 0, 0, 0,
	)
	hwndSettings = syscall.Handle(wnd)

	createControls(hwndSettings)
	updateTexts()
	updatePreviewCard()

	procShowWindow.Call(uintptr(hwndSettings), 1)
	procSetForegroundWindow.Call(uintptr(hwndSettings))
}

func createControls(parent syscall.Handle) {
	btnClass := strPtr("BUTTON")
	staticClass := strPtr("STATIC")

	// 1. Top Header bar: Title on Left, Themes & Languages on Right (GIN-VPN Header Standard)
	lblTitle = syscall.Handle(createCtrl(staticClass, "GIN-Wallpaper-Calend от VladiMIR+AI [v008]", WS_CHILD|WS_VISIBLE, 20, 14, 340, 26, parent, 10))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblTitle), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Header Mode Buttons (Ownerdrawn): Day, Evening, Night, EN, RU
	btnModeDay = syscall.Handle(createCtrl(btnClass, "☀️", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 380, 10, 42, 30, parent, 101))
	btnModeEvening = syscall.Handle(createCtrl(btnClass, "⛅", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 426, 10, 42, 30, parent, 102))
	btnModeNight = syscall.Handle(createCtrl(btnClass, "🌙", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 472, 10, 42, 30, parent, 103))

	btnLangEN = syscall.Handle(createCtrl(btnClass, "EN", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 530, 10, 52, 30, parent, 104))
	btnLangRU = syscall.Handle(createCtrl(btnClass, "RU", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 586, 10, 52, 30, parent, 105))

	// Section 1: Themes (12 in 2 columns)
	lblSecThemes = syscall.Handle(createCtrl(staticClass, "🎨 Wallpaper Theme / Тематика обоев:", WS_CHILD|WS_VISIBLE, 20, 52, 640, 20, parent, 11))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecThemes), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	// Column 1
	rbAll = createRadio("🎲 All Random (Mix)", 30, 76, 300, 20, parent, 201)
	rbAbstract = createRadio("🌀 Abstract & 3D Art", 30, 98, 300, 20, parent, 202)
	rbWindows = createRadio("🪟 Windows Style (Fluent/11)", 30, 120, 300, 20, parent, 203)
	rbLinux = createRadio("🐧 Linux Style (Minimal OS)", 30, 142, 300, 20, parent, 204)
	rbSpace = createRadio("🚀 Space & Galaxies (Nebula)", 30, 164, 300, 20, parent, 205)
	rbNature = createRadio("🌿 Nature & Landscapes", 30, 186, 300, 20, parent, 206)

	// Column 2
	rbCars = createRadio("🏎️ Cars & Supercars", 350, 76, 300, 20, parent, 207)
	rbCity = createRadio("🌆 City & Architecture", 350, 98, 300, 20, parent, 208)
	rbCyberpunk = createRadio("⚡ Cyberpunk & Neon", 350, 120, 300, 20, parent, 209)
	rbMinimal = createRadio("🖤 Minimalism & Dark AMOLED", 350, 142, 300, 20, parent, 210)
	rbAnimals = createRadio("🐾 Wildlife & Animals", 350, 164, 300, 20, parent, 211)
	rbAnime = createRadio("⛩️ Anime & Digital Scenery", 350, 186, 300, 20, parent, 212)

	selectCurrentThemeRadio()

	// Section 2: Intervals
	lblSecInt = syscall.Handle(createCtrl(staticClass, "⏱ Auto-Change Interval / Интервал смены:", WS_CHILD|WS_VISIBLE, 20, 216, 640, 20, parent, 12))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecInt), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	rb1h = createRadio("1 hour", 30, 238, 120, 20, parent, 301)
	rb3h = createRadio("3 hours (Recommended)", 160, 238, 190, 20, parent, 302)
	rb6h = createRadio("6 hours", 360, 238, 120, 20, parent, 303)
	rb24h = createRadio("24 hours (Daily)", 490, 238, 160, 20, parent, 304)

	selectCurrentIntervalRadio()

	// Section 3: Fonts (Each with its distinct actual HFONT!)
	lblSecFonts = syscall.Handle(createCtrl(staticClass, "🔤 Calendar Font & Live Sample / Шрифт календаря:", WS_CHILD|WS_VISIBLE, 20, 270, 640, 20, parent, 13))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecFonts), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	rbFontSegoe = createRadio("🔠 Segoe UI Bold (Windows Fluent)", 30, 292, 600, 20, parent, 401)
	lblSampSegoe = syscall.Handle(createCtrl(staticClass, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026", WS_CHILD|WS_VISIBLE, 50, 312, 600, 18, parent, 411))
	procSendMessageW.Call(uintptr(lblSampSegoe), WM_SETFONT, uintptr(hFontSegoe), 1)

	rbFontBahn = createRadio("📐 Bahnschrift (Geometric Tech / DIN)", 30, 334, 600, 20, parent, 402)
	lblSampBahn = syscall.Handle(createCtrl(staticClass, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026", WS_CHILD|WS_VISIBLE, 50, 354, 600, 18, parent, 412))
	procSendMessageW.Call(uintptr(lblSampBahn), WM_SETFONT, uintptr(hFontBahn), 1)

	rbFontDejavu = createRadio("🛡️ DejaVu Sans / Arial Bold (Universal)", 30, 376, 600, 20, parent, 403)
	lblSampDejavu = syscall.Handle(createCtrl(staticClass, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026", WS_CHILD|WS_VISIBLE, 50, 396, 600, 18, parent, 413))
	procSendMessageW.Call(uintptr(lblSampDejavu), WM_SETFONT, uintptr(hFontDejavu), 1)

	rbFontConsolas = createRadio("💻 Consolas Bold (Cyber / Monospace)", 30, 418, 600, 20, parent, 404)
	lblSampConsolas = syscall.Handle(createCtrl(staticClass, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026", WS_CHILD|WS_VISIBLE, 50, 438, 600, 18, parent, 414))
	procSendMessageW.Call(uintptr(lblSampConsolas), WM_SETFONT, uintptr(hFontConsolas), 1)

	rbFontTreb = createRadio("✒️ Trebuchet MS Bold (Design Elegance)", 30, 460, 600, 20, parent, 405)
	lblSampTreb = syscall.Handle(createCtrl(staticClass, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026", WS_CHILD|WS_VISIBLE, 50, 480, 600, 18, parent, 415))
	procSendMessageW.Call(uintptr(lblSampTreb), WM_SETFONT, uintptr(hFontTreb), 1)

	selectCurrentFontRadio()

	// Section 4: Scale
	lblSecScale = syscall.Handle(createCtrl(staticClass, "🔍 Calendar Scale / Размер календаря:", WS_CHILD|WS_VISIBLE, 20, 508, 640, 20, parent, 14))
	if hUIFontBold != 0 {
		procSendMessageW.Call(uintptr(lblSecScale), WM_SETFONT, uintptr(hUIFontBold), 1)
	}

	rbFontNormal = createRadio("Standard (1.0x)", 30, 530, 180, 20, parent, 421)
	rbFontLarge = createRadio("Large (2.0x, Recommended)", 220, 530, 240, 20, parent, 422)
	rbFontHuge = createRadio("Extra Large (2.5x)", 470, 530, 180, 20, parent, 423)

	if cfg.FontSizeScale <= 1.2 {
		procSendMessageW.Call(uintptr(rbFontNormal), BM_SETCHECK, BST_CHECKED, 0)
	} else if cfg.FontSizeScale >= 2.3 {
		procSendMessageW.Call(uintptr(rbFontHuge), BM_SETCHECK, BST_CHECKED, 0)
	} else {
		procSendMessageW.Call(uintptr(rbFontLarge), BM_SETCHECK, BST_CHECKED, 0)
	}

	// Interactive Live Preview Box (Preview Card)
	hwndPreviewBox = syscall.Handle(createCtrl(staticClass, "", WS_CHILD|WS_VISIBLE, 25, 560, 640, 64, parent, 500))

	// Status Info Label
	lblStatusInfo = syscall.Handle(createCtrl(staticClass, "Ready. Click Apply to update desktop wallpaper immediately.", WS_CHILD|WS_VISIBLE, 25, 634, 640, 20, parent, 505))
	if hUIFontSm != 0 {
		procSendMessageW.Call(uintptr(lblStatusInfo), WM_SETFONT, uintptr(hUIFontSm), 1)
	}

	// Bottom Action Buttons (Ownerdrawn with GIN-VPN Color Palette)
	btnApply = syscall.Handle(createCtrl(btnClass, "⚡ Apply Now", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 25, 664, 160, 38, parent, 601))
	btnSave = syscall.Handle(createCtrl(btnClass, "💾 Save & Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 195, 664, 160, 38, parent, 602))
	btnRandom = syscall.Handle(createCtrl(btnClass, "🎲 Random Theme", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 365, 664, 160, 38, parent, 603))
	btnClose = syscall.Handle(createCtrl(btnClass, "Close", WS_CHILD|WS_VISIBLE|BS_OWNERDRAW, 535, 664, 130, 38, parent, 604))
}

func createCtrl(className *uint16, text string, style uint32, x, y, w, h int, parent syscall.Handle, id uintptr) uintptr {
	r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(className)), uintptr(unsafe.Pointer(strPtr(text))), uintptr(style), uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), id, 0, 0)
	return r
}

func createRadio(caption string, x, y, w, h int, parent syscall.Handle, id uintptr) syscall.Handle {
	btnClass := strPtr("BUTTON")
	r := createCtrl(btnClass, caption, WS_CHILD|WS_VISIBLE|BS_AUTORADIOBUTTON, x, y, w, h, parent, id)
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
	case "dejavu":
		procSendMessageW.Call(uintptr(rbFontDejavu), BM_SETCHECK, BST_CHECKED, 0)
	case "consolas":
		procSendMessageW.Call(uintptr(rbFontConsolas), BM_SETCHECK, BST_CHECKED, 0)
	case "trebuchet":
		procSendMessageW.Call(uintptr(rbFontTreb), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rbFontSegoe), BM_SETCHECK, BST_CHECKED, 0)
	}
}

func updateTexts() {
	ru := isRu()

	setTxt := func(h syscall.Handle, txt string) {
		procSetWindowTextW.Call(uintptr(h), uintptr(unsafe.Pointer(strPtr(txt))))
	}

	wTitle := "GIN-Wallpaper-Calend v008 — Settings & Themes"
	if ru {
		wTitle = "GIN-Wallpaper-Calend v008 — Настройки и Темы"
	}
	procSetWindowTextW.Call(uintptr(hwndSettings), uintptr(unsafe.Pointer(strPtr(wTitle))))

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

		setTxt(lblSecFonts, "🔤 Стиль шрифта календаря (с реальными системными шрифтами):")
		setTxt(rbFontSegoe, "🔠 Segoe UI Bold (Windows Fluent)")
		setTxt(lblSampSegoe, "   1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт Сб Вс  •  Ноябрь 2026")

		setTxt(rbFontBahn, "📐 Bahnschrift (Geometric Tech / DIN)")
		setTxt(lblSampBahn, "   1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт Сб Вс  •  Ноябрь 2026")

		setTxt(rbFontDejavu, "🛡️ DejaVu Sans / Arial Bold (Универсальный)")
		setTxt(lblSampDejavu, "   1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт Сб Вс  •  Ноябрь 2026")

		setTxt(rbFontConsolas, "💻 Consolas Bold (Cyber / Monospace)")
		setTxt(lblSampConsolas, "   1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт Сб Вс  •  Ноябрь 2026")

		setTxt(rbFontTreb, "✒️ Trebuchet MS Bold (Design Elegance)")
		setTxt(lblSampTreb, "   1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт Сб Вс  •  Ноябрь 2026")

		setTxt(lblSecScale, "🔍 Масштаб и размер календаря:")
		setTxt(rbFontNormal, "Стандартный (1.0x)")
		setTxt(rbFontLarge, "Крупный (2.0x, Рекомендуется)")
		setTxt(rbFontHuge, "Очень крупный (2.5x)")

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

		setTxt(lblSecFonts, "🔤 Calendar Font (With actual live font samples):")
		setTxt(rbFontSegoe, "🔠 Segoe UI Bold (Windows Fluent)")
		setTxt(lblSampSegoe, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026")

		setTxt(rbFontBahn, "📐 Bahnschrift (Geometric Tech / DIN)")
		setTxt(lblSampBahn, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026")

		setTxt(rbFontDejavu, "🛡️ DejaVu Sans / Arial Bold (Universal)")
		setTxt(lblSampDejavu, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026")

		setTxt(rbFontConsolas, "💻 Consolas Bold (Cyber / Monospace)")
		setTxt(lblSampConsolas, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026")

		setTxt(rbFontTreb, "✒️ Trebuchet MS Bold (Design Elegance)")
		setTxt(lblSampTreb, "   1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr Sa Su  •  Nov 2026")

		setTxt(lblSecScale, "🔍 Calendar Scale and Size:")
		setTxt(rbFontNormal, "Standard (1.0x)")
		setTxt(rbFontLarge, "Large (2.0x, Recommended)")
		setTxt(rbFontHuge, "Extra Large (2.5x)")

		setTxt(lblStatusInfo, "Ready. Click 'Apply Now' to change wallpaper and calendar immediately.")
	}

	procInvalidateRect.Call(uintptr(hwndSettings), 0, 1)
}

func updatePreviewCard() {
	if hwndPreviewBox == 0 {
		return
	}
	fontName := "Segoe UI"
	hFontToUse := hFontSegoe

	readCurrentUISelections()

	switch cfg.FontStyle {
	case "bahn", "bahnschrift":
		fontName = "Bahnschrift"
		hFontToUse = hFontBahn
	case "dejavu":
		fontName = "DejaVu Sans"
		hFontToUse = hFontDejavu
	case "consolas":
		fontName = "Consolas"
		hFontToUse = hFontConsolas
	case "trebuchet":
		fontName = "Trebuchet MS"
		hFontToUse = hFontTreb
	default:
		fontName = "Segoe UI"
		hFontToUse = hFontSegoe
	}

	txt := fmt.Sprintf("  [ PREVIEW: %s ]  •  1 2 3 4 5 6 7 8 9 10  •  Mo Tu We Th Fr [Sa] [Su]\n  5 November 2026  •  Scale: %.1fx", fontName, cfg.FontSizeScale)
	if isRu() {
		txt = fmt.Sprintf("  [ ПРЕВЬЮ: %s ]  •  1 2 3 4 5 6 7 8 9 10  •  Пн Вт Ср Чт Пт [Сб] [Вс]\n  5 ноября 2026 г.  •  Масштаб: %.1fx", fontName, cfg.FontSizeScale)
	}

	procSetWindowTextW.Call(uintptr(hwndPreviewBox), uintptr(unsafe.Pointer(strPtr(txt))))
	if hFontToUse != 0 {
		procSendMessageW.Call(uintptr(hwndPreviewBox), WM_SETFONT, uintptr(hFontToUse), 1)
	}
	procInvalidateRect.Call(uintptr(hwndPreviewBox), 0, 1)
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
	} else if isChecked(rbFontDejavu) {
		cfg.FontStyle = "dejavu"
	} else if isChecked(rbFontConsolas) {
		cfg.FontStyle = "consolas"
	} else if isChecked(rbFontTreb) {
		cfg.FontStyle = "trebuchet"
	} else {
		cfg.FontStyle = "segoe"
	}

	if isChecked(rbFontNormal) {
		cfg.FontSizeScale = 1.0
	} else if isChecked(rbFontHuge) {
		cfg.FontSizeScale = 2.5
	} else {
		cfg.FontSizeScale = 2.0
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
	case 101: // Day
		btnText = "☀️"
		bgCol = rgb(230, 235, 245)
		borderCol = rgb(180, 190, 210)
		if cfg.ThemeMode == ThemeModeDay {
			borderCol = rgb(255, 179, 0)
			bgCol = rgb(255, 248, 225)
		}
		textCol = rgb(30, 30, 30)
	case 102: // Evening (Graphite)
		btnText = "⛅"
		bgCol = rgb(60, 68, 84)
		borderCol = rgb(90, 100, 120)
		if cfg.ThemeMode == ThemeModeEvening {
			borderCol = rgb(0, 230, 118) // Active green border
			bgCol = rgb(75, 85, 105)
		}
		textCol = rgb(255, 255, 255)
	case 103: // Night
		btnText = "🌙"
		bgCol = rgb(28, 30, 38)
		borderCol = rgb(50, 55, 70)
		if cfg.ThemeMode == ThemeModeNight {
			borderCol = rgb(61, 90, 254)
			bgCol = rgb(38, 42, 56)
		}
		textCol = rgb(255, 255, 255)

	case 104: // EN
		btnText = "EN"
		bgCol = rgb(45, 52, 68)
		borderCol = rgb(80, 90, 110)
		if cfg.Lang == "en" {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(55, 68, 90)
		}
		textCol = rgb(255, 255, 255)
	case 105: // RU
		btnText = "RU"
		bgCol = rgb(45, 52, 68)
		borderCol = rgb(80, 90, 110)
		if cfg.Lang == "ru" {
			borderCol = rgb(0, 230, 118)
			bgCol = rgb(55, 68, 90)
		}
		textCol = rgb(255, 255, 255)

	// Bottom action buttons
	case 601: // Apply Now (Emerald Green)
		btnText = "⚡ Apply Now"
		if isRu() {
			btnText = "⚡ Применить"
		}
		bgCol = rgb(46, 125, 50)
		borderCol = rgb(0, 230, 118)
		textCol = rgb(255, 255, 255)

	case 602: // Save & Close (GIN-VPN Amber Orange)
		btnText = "💾 Save & Close"
		if isRu() {
			btnText = "💾 Сохранить"
		}
		bgCol = rgb(211, 84, 0)
		borderCol = rgb(243, 156, 18)
		textCol = rgb(255, 255, 255)

	case 603: // Random Theme (Royal Purple)
		btnText = "🎲 Random"
		if isRu() {
			btnText = "🎲 Случайно"
		}
		bgCol = rgb(123, 31, 162)
		borderCol = rgb(186, 104, 200)
		textCol = rgb(255, 255, 255)

	case 604: // Close (Slate Gray)
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

	// 1. Background
	hBrush, _, _ := procCreateSolidBrush.Call(uintptr(bgCol))
	procFillRect.Call(hDC, uintptr(unsafe.Pointer(&rc)), hBrush)
	procDeleteObject.Call(hBrush)

	// 2. Border
	hPen, _, _ := procCreatePen.Call(0, 2, uintptr(borderCol))
	oldPen, _, _ := procSelectObject.Call(hDC, hPen)
	hNullBrush, _, _ := procGetStockObject.Call(5) // NULL_BRUSH
	oldBrush, _, _ := procSelectObject.Call(hDC, hNullBrush)
	procRectangle.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom))
	procSelectObject.Call(hDC, oldPen)
	procSelectObject.Call(hDC, oldBrush)
	procDeleteObject.Call(hPen)

	// 3. Text
	procSetBkMode.Call(hDC, 1) // TRANSPARENT
	procSetTextColor.Call(hDC, uintptr(textCol))
	oldFont, _, _ := procSelectObject.Call(hDC, hFont)

	pText := strPtr(btnText)
	procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(pText)), uintptr(len(syscall.StringToUTF16(btnText))-1), uintptr(unsafe.Pointer(&rc)), 0x0001|0x0004|0x0020) // DT_CENTER | DT_VCENTER | DT_SINGLELINE
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
		procSetBkMode.Call(hDC, 1) // TRANSPARENT
		hwndCtrl := syscall.Handle(lParam)

		if hwndCtrl == hwndPreviewBox {
			// Card style preview box
			if cfg.ThemeMode == ThemeModeDay {
				procSetTextColor.Call(hDC, uintptr(rgb(20, 24, 32)))
				return uintptr(hBrushDay)
			}
			procSetTextColor.Call(hDC, uintptr(rgb(255, 230, 0))) // Vibrant preview text
			return uintptr(hBrushNight)
		}

		if cfg.ThemeMode == ThemeModeDay {
			procSetTextColor.Call(hDC, uintptr(rgb(30, 35, 45)))
			return uintptr(hBrushDay)
		} else if cfg.ThemeMode == ThemeModeNight {
			procSetTextColor.Call(hDC, uintptr(rgb(225, 230, 240)))
			return uintptr(hBrushNight)
		}
		// Evening
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
			readCurrentUISelections()
			updatePreviewCard()
			return 0

		case 401, 402, 403, 404, 405: // Font Selection
			readCurrentUISelections()
			updatePreviewCard()
			return 0

		case 421, 422, 423: // Scale Selection
			readCurrentUISelections()
			updatePreviewCard()
			return 0

		case 601: // ⚡ Apply Now (Instant Desktop Update without closing!)
			readCurrentUISelections()
			saveConfig()
			updatePreviewCard()
			stTxt := "✓ Applying wallpaper and calendar..."
			if isRu() {
				stTxt = "✓ Применение обоев и календаря на рабочем столе..."
			}
			procSetWindowTextW.Call(uintptr(lblStatusInfo), uintptr(unsafe.Pointer(strPtr(stTxt))))
			go func() {
				cycleWallpaper()
				time.Sleep(500 * time.Millisecond)
				doneTxt := "✓ Successfully applied to desktop!"
				if isRu() {
					doneTxt = "✓ Обои и календарь успешно обновлены на рабочем столе!"
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
		case IDM_VERSION_CHECK:
			pUrl := strPtr("https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper")
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(pUrl)), 0, 0, 1)
		case IDM_CHANGE_NOW:
			go cycleWallpaper()
		case IDM_SETTINGS:
			createSettingsWindow()
		case IDM_OPEN_DIR:
			exePath, _ := os.Executable()
			dir := filepath.Dir(exePath)
			procShellExecuteW.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(dir))), 0, 0, 1)
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
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	wcSettings := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(settingsWndProc),
		LpszClassName: strPtr("GIN_Wallpaper_SettingsClass"),
		HbrBackground: syscall.Handle(16), // COLOR_BTNFACE + 1
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcSettings)))

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

	tip, _ := syscall.UTF16FromString("GIN-Wallpaper-Calend v008")
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

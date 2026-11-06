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
	procCreateFontW           = gdi32.NewProc("CreateFontW")
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

	NIM_ADD    = 0x00000000
	NIM_MODIFY = 0x00000001
	NIM_DELETE = 0x00000002

	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x00000800
	TPM_RIGHTBUTTON = 0x0002

	IDM_CHANGE_NOW = 1001
	IDM_SETTINGS   = 1002
	IDM_OPEN_DIR   = 1003
	IDM_EXIT       = 1004

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	BS_AUTORADIOBUTTON  = 0x00000009
	BS_DEFPUSHBUTTON    = 0x00000001
	BM_SETCHECK         = 0x00F1
	BM_GETCHECK         = 0x00F0
	BST_CHECKED         = 0x0001
	BST_UNCHECKED       = 0x0000

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x00000010
	LR_DEFAULTSIZE  = 0x00000040
	LR_SHARED       = 0x00008000
)

type Config struct {
	Theme         string  `json:"theme"`
	IntervalHours int     `json:"interval_hours"`
	FontSizeScale float64 `json:"font_size_scale"`
	FontStyle     string  `json:"font_style"`
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

var (
	nid          NOTIFYICONDATAW
	hwndTray     syscall.Handle
	hwndSettings syscall.Handle
	hIconApp     syscall.Handle
	hUIFont      syscall.Handle
	hUIFontBold  syscall.Handle
	hUIFontSm    syscall.Handle
	appDataDir   string
	cfg          Config
	parsedFont   *truetype.Font

	// Radio buttons - Themes (12)
	rbAll, rbAbstract, rbWindows, rbLinux, rbSpace, rbNature syscall.Handle
	rbCars, rbCity, rbCyberpunk, rbMinimal, rbAnimals, rbAnime syscall.Handle

	// Radio buttons - Intervals (4)
	rb1h, rb3h, rb6h, rb24h syscall.Handle

	// Radio buttons - Font styles (5)
	rbFontSegoe, rbFontBahn, rbFontDejavu, rbFontConsolas, rbFontTreb syscall.Handle

	// Radio buttons - Font scale (3)
	rbFontNormal, rbFontLarge, rbFontHuge syscall.Handle

	ruMonths = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	ruDays   = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
)

func strPtr(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func loadConfig() {
	cfg = Config{
		Theme:         "all",
		IntervalHours: 3,
		FontSizeScale: 2.0,
		FontStyle:     "segoe",
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

	// Stage 4: Emergency offline procedural wallpaper (ensures zero crash even offline)
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

	// 1. Semi-transparent backdrop (~85% opacity) for outstanding contrast
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
	title := fmt.Sprintf("%d %s %d г.", now.Day(), ruMonths[int(now.Month())], now.Year())
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

	for i, day := range ruDays {
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

	procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHANGE_NOW, uintptr(unsafe.Pointer(strPtr("🔄 Сменить обои сейчас"))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETTINGS, uintptr(unsafe.Pointer(strPtr("⚙️ Настройки и темы..."))))
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_OPEN_DIR, uintptr(unsafe.Pointer(strPtr("📁 Открыть папку программы"))))
	procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
	procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(strPtr("❌ Выход"))))

	var pt POINT
	procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
	procSetForegroundWindow.Call(uintptr(hwnd))
	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(pt.X), uintptr(pt.Y), 0, uintptr(hwnd), 0)
	procDestroyMenu.Call(hMenu)
}

func createSettingsWindow() {
	if hwndSettings != 0 {
		procShowWindow.Call(uintptr(hwndSettings), 1)
		procSetForegroundWindow.Call(uintptr(hwndSettings))
		return
	}

	// Calculate center position
	screenW, screenH := getScreenResolution()
	winW, winH := 680, 740
	posX := (screenW - winW) / 2
	posY := (screenH - winH) / 2
	if posX < 0 {
		posX = 50
	}
	if posY < 0 {
		posY = 50
	}

	wnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(strPtr("GIN_Wallpaper_SettingsClass"))),
		uintptr(unsafe.Pointer(strPtr("GIN-Wallpaper-Calend v007 — Настройки и Темы"))),
		WS_OVERLAPPEDWINDOW&^0x00040000,
		uintptr(posX), uintptr(posY), uintptr(winW), uintptr(winH),
		0, 0, 0, 0,
	)
	hwndSettings = syscall.Handle(wnd)

	createControls(hwndSettings)
	procShowWindow.Call(uintptr(hwndSettings), 1)
	procSetForegroundWindow.Call(uintptr(hwndSettings))
}

func createControls(parent syscall.Handle) {
	btnClass := strPtr("BUTTON")
	staticClass := strPtr("STATIC")

	initFonts()

	addSectionLabel := func(text string, x, y, w, h int) syscall.Handle {
		r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(staticClass)), uintptr(unsafe.Pointer(strPtr(text))), WS_CHILD|WS_VISIBLE, uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), 0, 0, 0)
		hCtrl := syscall.Handle(r)
		if hUIFontBold != 0 {
			procSendMessageW.Call(uintptr(hCtrl), WM_SETFONT, uintptr(hUIFontBold), 1)
		}
		return hCtrl
	}

	addSampleLabel := func(text string, x, y, w, h int) syscall.Handle {
		r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(staticClass)), uintptr(unsafe.Pointer(strPtr(text))), WS_CHILD|WS_VISIBLE, uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), 0, 0, 0)
		hCtrl := syscall.Handle(r)
		if hUIFontSm != 0 {
			procSendMessageW.Call(uintptr(hCtrl), WM_SETFONT, uintptr(hUIFontSm), 1)
		}
		return hCtrl
	}

	createBtn := func(caption string, x, y, w, h int, id uintptr) syscall.Handle {
		r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(strPtr(caption))), WS_CHILD|WS_VISIBLE|BS_AUTORADIOBUTTON, uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), id, 0, 0)
		hCtrl := syscall.Handle(r)
		if hUIFont != 0 {
			procSendMessageW.Call(uintptr(hCtrl), WM_SETFONT, uintptr(hUIFont), 1)
		}
		return hCtrl
	}

	// 1. Theme Selection (12 themes in 2 columns)
	addSectionLabel("🎨 Тематика обоев (выберите желаемый стиль):", 25, 12, 600, 22)

	// Column 1
	rbAll = createBtn("🎲 Все подряд (Случайный микс)", 35, 38, 280, 22, 201)
	rbAbstract = createBtn("🌀 Абстракция и 3D рендеры", 35, 62, 280, 22, 202)
	rbWindows = createBtn("🪟 В стиле Windows (11 / Fluent)", 35, 86, 280, 22, 203)
	rbLinux = createBtn("🐧 В стиле Linux (Arch / Minimal OS)", 35, 110, 280, 22, 204)
	rbSpace = createBtn("🚀 Космос и Галактики (Nebula)", 35, 134, 280, 22, 205)
	rbNature = createBtn("🌿 Природа и пейзажи (Горы, Океан)", 35, 158, 280, 22, 206)

	// Column 2
	rbCars = createBtn("🏎️ Автомобили и Суперкары", 340, 38, 280, 22, 207)
	rbCity = createBtn("🌆 Города и Архитектура (Skylines)", 340, 62, 280, 22, 208)
	rbCyberpunk = createBtn("⚡ Киберпанк и Неон (Synthwave)", 340, 86, 280, 22, 209)
	rbMinimal = createBtn("🖤 Минимализм и Dark AMOLED", 340, 110, 280, 22, 210)
	rbAnimals = createBtn("🐾 Животные и Дикая природа", 340, 134, 280, 22, 211)
	rbAnime = createBtn("⛩️ Аниме и Цифровой Арт", 340, 158, 280, 22, 212)

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

	// 2. Interval Selection
	addSectionLabel("⏱ Интервал автоматической смены обоев:", 25, 192, 600, 22)
	rb1h = createBtn("1 час", 35, 216, 120, 22, 301)
	rb3h = createBtn("3 часа (Оптимально)", 165, 216, 180, 22, 302)
	rb6h = createBtn("6 часов", 360, 216, 120, 22, 303)
	rb24h = createBtn("1 раз в день", 500, 216, 130, 22, 304)

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

	// 3. Font Selection with Samples (Digits 1-10 + Cyrillic Days)
	addSectionLabel("🔤 Стиль шрифта календаря (с образцами цифр и букв):", 25, 252, 600, 22)

	rbFontSegoe = createBtn("🔠 Segoe UI Bold (Windows Fluent)", 35, 276, 580, 22, 401)
	addSampleLabel("   Образец:  1 2 3 4 5 6 7 8 9 10   •   Пн Вт Ср Чт Пт Сб Вс   •   Ноябрь 2026", 55, 298, 560, 18)

	rbFontBahn = createBtn("📐 Bahnschrift (Geometric Tech / DIN)", 35, 320, 580, 22, 402)
	addSampleLabel("   Образец:  1 2 3 4 5 6 7 8 9 10   •   Пн Вт Ср Чт Пт Сб Вс   •   Ноябрь 2026", 55, 342, 560, 18)

	rbFontDejavu = createBtn("🛡️ DejaVu Sans Bold (Universal Clean)", 35, 364, 580, 22, 403)
	addSampleLabel("   Образец:  1 2 3 4 5 6 7 8 9 10   •   Пн Вт Ср Чт Пт Сб Вс   •   Ноябрь 2026", 55, 386, 560, 18)

	rbFontConsolas = createBtn("💻 Consolas Bold (Cyber / Monospace)", 35, 408, 580, 22, 404)
	addSampleLabel("   Образец:  1 2 3 4 5 6 7 8 9 10   •   Пн Вт Ср Чт Пт Сб Вс   •   Ноябрь 2026", 55, 430, 560, 18)

	rbFontTreb = createBtn("✒️ Trebuchet MS Bold (Design Elegance)", 35, 452, 580, 22, 405)
	addSampleLabel("   Образец:  1 2 3 4 5 6 7 8 9 10   •   Пн Вт Ср Чт Пт Сб Вс   •   Ноябрь 2026", 55, 474, 560, 18)

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

	// 4. Scale Selection
	addSectionLabel("🔍 Масштаб и размер календаря:", 25, 502, 600, 22)
	rbFontNormal = createBtn("Стандартный (1.0x)", 35, 526, 180, 22, 411)
	rbFontLarge = createBtn("Крупный (2.0x, Рекомендуется)", 225, 526, 250, 22, 412)
	rbFontHuge = createBtn("Очень крупный (2.5x)", 485, 526, 180, 22, 413)

	if cfg.FontSizeScale <= 1.2 {
		procSendMessageW.Call(uintptr(rbFontNormal), BM_SETCHECK, BST_CHECKED, 0)
	} else if cfg.FontSizeScale >= 2.3 {
		procSendMessageW.Call(uintptr(rbFontHuge), BM_SETCHECK, BST_CHECKED, 0)
	} else {
		procSendMessageW.Call(uintptr(rbFontLarge), BM_SETCHECK, BST_CHECKED, 0)
	}

	// Bottom action buttons
	btnSave, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(strPtr("💾 Сохранить и применить"))), WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON, 35, 575, 230, 36, uintptr(parent), 501, 0, 0)
	btnClose, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(strPtr("Закрыть"))), WS_CHILD|WS_VISIBLE, 280, 575, 120, 36, uintptr(parent), 502, 0, 0)

	if hUIFontBold != 0 {
		procSendMessageW.Call(btnSave, WM_SETFONT, uintptr(hUIFontBold), 1)
	}
	if hUIFont != 0 {
		procSendMessageW.Call(btnClose, WM_SETFONT, uintptr(hUIFont), 1)
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
}

func isChecked(h syscall.Handle) bool {
	r, _, _ := procSendMessageW.Call(uintptr(h), BM_GETCHECK, 0, 0)
	return r == BST_CHECKED
}

func saveSettingsFromUI() {
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

	saveConfig()
	procDestroyWindow.Call(uintptr(hwndSettings))
	hwndSettings = 0

	go cycleWallpaper()
}

func settingsWndProc(hwnd syscall.Handle, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		switch wParam {
		case 501:
			saveSettingsFromUI()
			return 0
		case 502:
			procDestroyWindow.Call(uintptr(hwnd))
			hwndSettings = 0
			return 0
		}
	case WM_CLOSE:
		procDestroyWindow.Call(uintptr(hwnd))
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
			procShellExecute := shell32.NewProc("ShellExecuteW")
			procShellExecute.Call(0, uintptr(unsafe.Pointer(strPtr("open"))), uintptr(unsafe.Pointer(strPtr(dir))), 0, 0, 1)
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

	tip, _ := syscall.UTF16FromString("GIN-Wallpaper-Calend v007")
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

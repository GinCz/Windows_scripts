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
	procGetCursorPos          = user32.NewProc("GetCursorPos")
	procSetForegroundWindow   = user32.NewProc("SetForegroundWindow")
	procPostQuitMessage       = user32.NewProc("PostQuitMessage")
	procShowWindow            = user32.NewProc("ShowWindow")
	procDestroyWindow         = user32.NewProc("DestroyWindow")
	procSendMessageW          = user32.NewProc("SendMessageW")
	procLoadImageW            = user32.NewProc("LoadImageW")
	procGetModuleHandleW      = kernel32.NewProc("GetModuleHandleW")
)

const (
	SPI_SETDESKWALLPAPER = 0x0014
	SPIF_UPDATEINIFILE   = 0x0001
	SPIF_SENDCHANGE      = 0x0002

	WM_USER          = 0x0400
	WM_TRAYICON      = WM_USER + 1
	WM_COMMAND       = 0x0111
	WM_LBUTTONDBLCLK = 0x0203
	WM_RBUTTONUP     = 0x0205
	WM_CLOSE         = 0x0010

	NIM_ADD    = 0x00000000
	NIM_MODIFY = 0x00000001
	NIM_DELETE = 0x00000002

	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x00000800

	IDM_CHANGE_NOW = 1001
	IDM_SETTINGS   = 1002
	IDM_EXIT       = 1003

	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	BS_AUTORADIOBUTTON  = 0x00000009
	BS_DEFPUSHBUTTON    = 0x00000001
	BM_SETCHECK         = 0x00F1
	BM_GETCHECK         = 0x00F0
	BST_CHECKED         = 0x0001
	BST_UNCHECKED       = 0x0000

	IMAGE_ICON     = 1
	LR_LOADFROMFILE = 0x00000010
	LR_DEFAULTSIZE = 0x00000040
	LR_SHARED      = 0x00008000
)

type Config struct {
	Theme         string  `json:"theme"`
	IntervalHours int     `json:"interval_hours"`
	FontSizeScale float64 `json:"font_size_scale"`
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

var (
	nid          NOTIFYICONDATAW
	hwndTray     syscall.Handle
	hwndSettings syscall.Handle
	hIconApp     syscall.Handle
	appDataDir   string
	cfg          Config
	parsedFont   *truetype.Font

	rbSpace, rbNature, rbCars, rbCity, rbAll syscall.Handle
	rb1h, rb3h, rb6h, rb24h                  syscall.Handle
	rbFontNormal, rbFontLarge, rbFontHuge    syscall.Handle

	ruMonths = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	ruDays   = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
)

func loadConfig() {
	cfg = Config{
		Theme:         "all",
		IntervalHours: 3,
		FontSizeScale: 2.0,
	}
	cfgPath := filepath.Join(appDataDir, "config.json")
	if data, err := os.ReadFile(cfgPath); err == nil {
		json.Unmarshal(data, &cfg)
	}
}

func saveConfig() {
	cfgPath := filepath.Join(appDataDir, "config.json")
	if data, err := json.MarshalIndent(cfg, "", "  "); err == nil {
		os.WriteFile(cfgPath, data, 0644)
	}
}

func setWallpaperWin(path string) {
	pPtr, _ := syscall.UTF16PtrFromString(path)
	procSystemParametersInfoW.Call(
		SPI_SETDESKWALLPAPER,
		0,
		uintptr(unsafe.Pointer(pPtr)),
		SPIF_UPDATEINIFILE|SPIF_SENDCHANGE,
	)
}

func getScreenSize() (int, int) {
	w, _, _ := procGetSystemMetrics.Call(0)
	h, _, _ := procGetSystemMetrics.Call(1)
	if w == 0 || h == 0 {
		return 1920, 1080
	}
	return int(w), int(h)
}

func downloadRandomWallpaper(w, h int) (image.Image, error) {
	themeQuery := "nature,wallpaper"
	switch cfg.Theme {
	case "space":
		themeQuery = "space,galaxy,stars"
	case "nature":
		themeQuery = "nature,landscape,forest"
	case "cars":
		themeQuery = "car,supercar,auto"
	case "city":
		themeQuery = "city,skyline,architecture"
	default:
		allThemes := []string{"space", "nature", "car", "city", "mountains", "ocean"}
		themeQuery = allThemes[rand.Intn(len(allThemes))]
	}

	picsumUrl := fmt.Sprintf("https://picsum.photos/%d/%d", w, h)
	if cfg.Theme != "all" {
		unsplashUrl := fmt.Sprintf("https://source.unsplash.com/random/%dx%d/?%s", w, h, url.QueryEscape(themeQuery))
		resp, err := http.Get(unsplashUrl)
		if err == nil && resp.StatusCode == http.StatusOK {
			defer resp.Body.Close()
			if img, _, err := image.Decode(resp.Body); err == nil {
				return img, nil
			}
		}
	}

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(picsumUrl)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	img, _, err := image.Decode(resp.Body)
	return img, err
}

func renderCalendarOverlay(bg image.Image) *image.RGBA {
	bounds := bg.Bounds()
	rgba := image.NewRGBA(bounds)
	draw.Draw(rgba, bounds, bg, bounds.Min, draw.Src)

	now := time.Now()

	scale := cfg.FontSizeScale
	if scale < 1.0 {
		scale = 2.0
	}

	calW := int(480 * (scale / 2.0))
	calH := int(310 * (scale / 2.0))
	margin := 28
	x0 := bounds.Dx() - calW - margin
	y0 := margin

	// Darker background with excellent contrast (alpha = 145 / 255 (~57% opacity))
	boxCol := color.RGBA{12, 12, 20, 145}
	for y := y0; y < y0+calH && y < bounds.Dy(); y++ {
		for x := x0; x < x0+calW && x < bounds.Dx(); x++ {
			orig := rgba.At(x, y)
			r1, g1, b1, _ := orig.RGBA()
			r2 := (uint32(boxCol.R)*uint32(boxCol.A) + r1*(255-uint32(boxCol.A))) / 255
			g2 := (uint32(boxCol.G)*uint32(boxCol.A) + g1*(255-uint32(boxCol.A))) / 255
			b2 := (uint32(boxCol.B)*uint32(boxCol.A) + b1*(255-uint32(boxCol.A))) / 255
			rgba.Set(x, y, color.RGBA{R: uint8(r2 >> 8), G: uint8(g2 >> 8), B: uint8(b2 >> 8), A: 255})
		}
	}

	// Border
	borderColor := color.RGBA{180, 130, 240, 210}
	for x := x0; x < x0+calW && x < bounds.Dx(); x++ {
		rgba.Set(x, y0, borderColor)
		rgba.Set(x, y0+calH-1, borderColor)
	}
	for y := y0; y < y0+calH && y < bounds.Dy(); y++ {
		rgba.Set(x0, y, borderColor)
		rgba.Set(x0+calW-1, y, borderColor)
	}

	// Title font setup
	titleSize := 24.0 * (scale / 2.0)
	titleFace := truetype.NewFace(parsedFont, &truetype.Options{
		Size:    titleSize,
		DPI:     72,
		Hinting: font.HintingFull,
	})

	// Days font setup
	daySize := 18.0 * (scale / 2.0)
	dayFace := truetype.NewFace(parsedFont, &truetype.Options{
		Size:    daySize,
		DPI:     72,
		Hinting: font.HintingFull,
	})

	// Draw Title: e.g. "5 ноября 2026 г."
	title := fmt.Sprintf("%d %s %d г.", now.Day(), ruMonths[int(now.Month())], now.Year())
	titleDrawer := &font.Drawer{
		Dst:  rgba,
		Src:  image.NewUniform(color.RGBA{255, 255, 255, 255}),
		Face: titleFace,
		Dot:  fixed.Point26_6{X: fixed.I(x0 + int(24*(scale/2.0))), Y: fixed.I(y0 + int(42*(scale/2.0)))},
	}
	titleDrawer.DrawString(title)

	// Weekdays: Monday-Friday = Pure White, Saturday-Sunday = Bright Neon Yellow!
	colStep := int(62 * (scale / 2.0))
	hdrY := y0 + int(82*(scale/2.0))
	for i, d := range ruDays {
		col := color.RGBA{255, 255, 255, 255} // Pure bright white
		if i >= 5 {
			col = color.RGBA{255, 230, 0, 255} // Bright vibrant Yellow for Sat and Sun!
		}
		dDrawer := &font.Drawer{
			Dst:  rgba,
			Src:  image.NewUniform(col),
			Face: dayFace,
			Dot:  fixed.Point26_6{X: fixed.I(x0 + int(24*(scale/2.0)) + i*colStep), Y: fixed.I(hdrY)},
		}
		dDrawer.DrawString(d)
	}

	// Days grid calculation
	firstDay := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	startWeekday := (int(firstDay.Weekday()) + 6) % 7
	daysInMonth := time.Date(now.Year(), now.Month()+1, 0, 0, 0, 0, 0, time.Local).Day()

	curX := startWeekday
	curY := 0
	rowStep := int(34 * (scale / 2.0))
	gridStartY := hdrY + int(38*(scale/2.0))

	for d := 1; d <= daysInMonth; d++ {
		posX := x0 + int(24*(scale/2.0)) + curX*colStep
		posY := gridStartY + curY*rowStep

		dayCol := color.RGBA{255, 255, 255, 255} // Bright White for weekdays
		if curX >= 5 {
			dayCol = color.RGBA{255, 230, 0, 255} // Bright Vibrant Yellow for Weekend dates!
		}

		if d == now.Day() {
			dayCol = color.RGBA{255, 255, 255, 255}
			// Distinct bright purple/blue box for Today
			bw := int(34 * (scale / 2.0))
			bh := int(24 * (scale / 2.0))
			bx := posX - int(6*(scale/2.0))
			by := posY - int(18*(scale/2.0))
			for gy := by; gy < by+bh; gy++ {
				for gx := bx; gx < bx+bw; gx++ {
					if gx >= 0 && gx < bounds.Dx() && gy >= 0 && gy < bounds.Dy() {
						rgba.Set(gx, gy, color.RGBA{65, 80, 240, 240}) // Bright saturated Royal Blue
					}
				}
			}
		}

		dayDrawer := &font.Drawer{
			Dst:  rgba,
			Src:  image.NewUniform(dayCol),
			Face: dayFace,
			Dot:  fixed.Point26_6{X: fixed.I(posX), Y: fixed.I(posY)},
		}
		dayDrawer.DrawString(fmt.Sprintf("%2d", d))

		curX++
		if curX > 6 {
			curX = 0
			curY++
		}
	}

	return rgba
}

func cycleWallpaper() {
	w, h := getScreenSize()
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

func createSettingsWindow() {
	if hwndSettings != 0 {
		procShowWindow.Call(uintptr(hwndSettings), 1)
		procSetForegroundWindow.Call(uintptr(hwndSettings))
		return
	}

	className, _ := syscall.UTF16PtrFromString("GIN_Wallpaper_SettingsClass")
	title, _ := syscall.UTF16PtrFromString("GIN-Wallpaper-Calend v005 — Настройки")

	wnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(title)),
		WS_OVERLAPPEDWINDOW&^0x00040000,
		100, 100, 480, 560,
		0, 0, 0, 0,
	)
	hwndSettings = syscall.Handle(wnd)

	createControls(hwndSettings)
	procShowWindow.Call(uintptr(hwndSettings), 1)
	procSetForegroundWindow.Call(uintptr(hwndSettings))
}

func createControls(parent syscall.Handle) {
	btnClass, _ := syscall.UTF16PtrFromString("BUTTON")
	staticClass, _ := syscall.UTF16PtrFromString("STATIC")

	addLabel := func(text string, x, y, w, h int) {
		tPtr, _ := syscall.UTF16PtrFromString(text)
		procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(staticClass)), uintptr(unsafe.Pointer(tPtr)), WS_CHILD|WS_VISIBLE, uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), 0, 0, 0)
	}

	createBtn := func(caption string, x, y, w, h int, id uintptr) syscall.Handle {
		cPtr, _ := syscall.UTF16PtrFromString(caption)
		r, _, _ := procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(cPtr)), WS_CHILD|WS_VISIBLE|BS_AUTORADIOBUTTON, uintptr(x), uintptr(y), uintptr(w), uintptr(h), uintptr(parent), id, 0, 0)
		return syscall.Handle(r)
	}

	// 1. Theme Section
	addLabel("🎨 Тематика обоев:", 20, 15, 400, 20)
	rbAll = createBtn("🎲 Все подряд (Случайно)", 30, 40, 300, 24, 201)
	rbSpace = createBtn("🚀 Космос (Space & Galaxies)", 30, 68, 300, 24, 202)
	rbNature = createBtn("🌿 Природа и пейзажи", 30, 96, 300, 24, 203)
	rbCars = createBtn("🚗 Автомобили и спорткары", 30, 124, 300, 24, 204)
	rbCity = createBtn("🌆 Города и архитектура", 30, 152, 300, 24, 205)

	switch cfg.Theme {
	case "space":
		procSendMessageW.Call(uintptr(rbSpace), BM_SETCHECK, BST_CHECKED, 0)
	case "nature":
		procSendMessageW.Call(uintptr(rbNature), BM_SETCHECK, BST_CHECKED, 0)
	case "cars":
		procSendMessageW.Call(uintptr(rbCars), BM_SETCHECK, BST_CHECKED, 0)
	case "city":
		procSendMessageW.Call(uintptr(rbCity), BM_SETCHECK, BST_CHECKED, 0)
	default:
		procSendMessageW.Call(uintptr(rbAll), BM_SETCHECK, BST_CHECKED, 0)
	}

	// 2. Interval Section
	addLabel("⏱ Интервал автосмены:", 20, 195, 400, 20)
	rb1h = createBtn("Каждый 1 час", 30, 220, 180, 24, 301)
	rb3h = createBtn("Каждые 3 часа (По умолчанию)", 30, 248, 250, 24, 302)
	rb6h = createBtn("Каждые 6 часов", 30, 276, 180, 24, 303)
	rb24h = createBtn("1 раз в день", 30, 304, 180, 24, 304)

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

	// 3. Font Size Section
	addLabel("🔤 Размер шрифта календаря:", 20, 345, 400, 20)
	rbFontNormal = createBtn("Стандартный (1.0x)", 30, 370, 180, 24, 401)
	rbFontLarge = createBtn("Крупный (2.0x, Рекомендуется)", 30, 398, 260, 24, 402)
	rbFontHuge = createBtn("Очень крупный (2.5x)", 30, 426, 220, 24, 403)

	if cfg.FontSizeScale <= 1.2 {
		procSendMessageW.Call(uintptr(rbFontNormal), BM_SETCHECK, BST_CHECKED, 0)
	} else if cfg.FontSizeScale >= 2.3 {
		procSendMessageW.Call(uintptr(rbFontHuge), BM_SETCHECK, BST_CHECKED, 0)
	} else {
		procSendMessageW.Call(uintptr(rbFontLarge), BM_SETCHECK, BST_CHECKED, 0)
	}

	saveTxt, _ := syscall.UTF16PtrFromString("Сохранить и применить")
	closeTxt, _ := syscall.UTF16PtrFromString("Закрыть")
	procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(saveTxt)), WS_CHILD|WS_VISIBLE|BS_DEFPUSHBUTTON, 30, 465, 200, 34, uintptr(parent), 501, 0, 0)
	procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(btnClass)), uintptr(unsafe.Pointer(closeTxt)), WS_CHILD|WS_VISIBLE, 245, 465, 120, 34, uintptr(parent), 502, 0, 0)
}

func isChecked(h syscall.Handle) bool {
	r, _, _ := procSendMessageW.Call(uintptr(h), BM_GETCHECK, 0, 0)
	return r == BST_CHECKED
}

func saveSettingsFromUI() {
	if isChecked(rbSpace) {
		cfg.Theme = "space"
	} else if isChecked(rbNature) {
		cfg.Theme = "nature"
	} else if isChecked(rbCars) {
		cfg.Theme = "cars"
	} else if isChecked(rbCity) {
		cfg.Theme = "city"
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
		if lParam == WM_LBUTTONDBLCLK {
			go cycleWallpaper()
			return 0
		} else if lParam == WM_RBUTTONUP {
			hMenu, _, _ := procCreatePopupMenu.Call()
			pChange, _ := syscall.UTF16PtrFromString("🔄 Сменить обои сейчас")
			pSettings, _ := syscall.UTF16PtrFromString("⚙️ Настройки...")
			pExit, _ := syscall.UTF16PtrFromString("❌ Выход")

			procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHANGE_NOW, uintptr(unsafe.Pointer(pChange)))
			procAppendMenuW.Call(hMenu, MF_STRING, IDM_SETTINGS, uintptr(unsafe.Pointer(pSettings)))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(pExit)))

			var pt POINT
			procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
			procSetForegroundWindow.Call(uintptr(hwnd))
			procTrackPopupMenu.Call(hMenu, 0x0002, uintptr(pt.X), uintptr(pt.Y), 0, uintptr(hwnd), 0)
			return 0
		}
	case WM_COMMAND:
		switch wParam {
		case IDM_CHANGE_NOW:
			go cycleWallpaper()
		case IDM_SETTINGS:
			createSettingsWindow()
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
	// Try loading from embedded resource ID 1
	hInstance, _, _ := procGetModuleHandleW.Call(0)
	hIco, _, _ := procLoadImageW.Call(hInstance, 1, uintptr(IMAGE_ICON), 16, 16, uintptr(LR_DEFAULTSIZE|LR_SHARED))
	if hIco != 0 {
		return syscall.Handle(hIco)
	}

	// Fallback to app.ico from disk
	exePath, _ := os.Executable()
	diskIco := filepath.Join(filepath.Dir(exePath), "app.ico")
	if _, err := os.Stat(diskIco); err == nil {
		pIco, _ := syscall.UTF16PtrFromString(diskIco)
		hIcoDisk, _, _ := procLoadImageW.Call(0, uintptr(unsafe.Pointer(pIco)), uintptr(IMAGE_ICON), 16, 16, uintptr(LR_LOADFROMFILE))
		if hIcoDisk != 0 {
			return syscall.Handle(hIcoDisk)
		}
	}

	// Fallback: write embeddedAppICO to temp and load
	if len(embeddedAppICO) > 0 {
		tmpIco := filepath.Join(os.TempDir(), "gin_wallpaper_tray.ico")
		os.WriteFile(tmpIco, embeddedAppICO, 0644)
		pTmp, _ := syscall.UTF16PtrFromString(tmpIco)
		hTmp, _, _ := procLoadImageW.Call(0, uintptr(unsafe.Pointer(pTmp)), uintptr(IMAGE_ICON), 16, 16, uintptr(LR_LOADFROMFILE))
		if hTmp != 0 {
			return syscall.Handle(hTmp)
		}
	}

	return 0
}

func main() {
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

	className, _ := syscall.UTF16PtrFromString("GIN_Wallpaper_TrayClass")
	wc := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(wndProc),
		LpszClassName: className,
		HIcon:         hIconApp,
		HIconSm:       hIconApp,
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	settingsClass, _ := syscall.UTF16PtrFromString("GIN_Wallpaper_SettingsClass")
	wcSettings := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(settingsWndProc),
		LpszClassName: settingsClass,
		HIcon:         hIconApp,
		HIconSm:       hIconApp,
		HbrBackground: syscall.Handle(15 + 1),
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcSettings)))

	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(className)),
		0, 0, 0, 0, 0, 0, 0, 0, 0,
	)
	hwndTray = syscall.Handle(hwnd)

	// Explicitly assign HIcon and NIF_ICON!
	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.Hwnd = hwndTray
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconApp

	tip, _ := syscall.UTF16FromString("GIN-Wallpaper-Calend v005")
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

	var m MSG
	for {
		r, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&m)), 0, 0, 0)
		if int32(r) <= 0 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&m)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&m)))
	}
}

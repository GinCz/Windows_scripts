package main

import (
	_ "embed"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	_ "image/png"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"syscall"
	"time"
	"unsafe"

	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
)

var (
	user32                     = syscall.NewLazyDLL("user32.dll")
	shell32                    = syscall.NewLazyDLL("shell32.dll")
	procSystemParametersInfoW  = user32.NewProc("SystemParametersInfoW")
	procGetSystemMetrics       = user32.NewProc("GetSystemMetrics")
	procShell_NotifyIconW      = shell32.NewProc("Shell_NotifyIconW")
	procCreateWindowExW        = user32.NewProc("CreateWindowExW")
	procDefWindowProcW         = user32.NewProc("DefWindowProcW")
	procRegisterClassExW       = user32.NewProc("RegisterClassExW")
	procGetMessageW            = user32.NewProc("GetMessageW")
	procTranslateMessage       = user32.NewProc("TranslateMessage")
	procDispatchMessageW       = user32.NewProc("DispatchMessageW")
	procCreatePopupMenu        = user32.NewProc("CreatePopupMenu")
	procAppendMenuW            = user32.NewProc("AppendMenuW")
	procTrackPopupMenu         = user32.NewProc("TrackPopupMenu")
	procGetCursorPos           = user32.NewProc("GetCursorPos")
	procSetForegroundWindow    = user32.NewProc("SetForegroundWindow")
	procPostQuitMessage        = user32.NewProc("PostQuitMessage")
	procLoadImageW             = user32.NewProc("LoadImageW")
)

const (
	SPI_SETDESKWALLPAPER = 0x0014
	SPIF_UPDATEINIFILE   = 0x0001
	SPIF_SENDCHANGE      = 0x0002

	WM_USER         = 0x0400
	WM_TRAYICON     = WM_USER + 1
	WM_COMMAND      = 0x0111
	WM_LBUTTONDBLCLK = 0x0203
	WM_RBUTTONUP    = 0x0205

	NIM_ADD    = 0x00000000
	NIM_MODIFY = 0x00000001
	NIM_DELETE = 0x00000002

	NIF_MESSAGE = 0x00000001
	NIF_ICON    = 0x00000002
	NIF_TIP     = 0x00000004

	MF_STRING    = 0x00000000
	MF_SEPARATOR = 0x00000800

	IDM_CHANGE_NOW = 1001
	IDM_EXIT       = 1002
)

type NOTIFYICONDATAW struct {
	CbSize           uint32
	Hwnd             syscall.Handle
	UID              uint32
	UFlags           uint32
	UCallbackMessage uint32
	HIcon            syscall.Handle
	SzTip            [128]uint16
	DwState          uint32
	DwStateMask      uint32
	SzInfo           [256]uint16
	UTimeoutOrVersion uint32
	SzInfoTitle      [64]uint16
	DwInfoFlags      uint32
	GuidItem         [16]byte
	HBalloonIcon     syscall.Handle
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
	nid         NOTIFYICONDATAW
	hwndTray    syscall.Handle
	hIconApp    syscall.Handle
	appDataDir  string
	ruMonths    = []string{"", "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"}
	ruDays      = []string{"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"}
)

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
	url := fmt.Sprintf("https://picsum.photos/%d/%d", w, h)
	client := &http.Client{Timeout: 25 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	img, _, err := image.Decode(resp.Body)
	return img, err
}

func drawString(dst *image.RGBA, x, y int, label string, col color.Color) {
	point := fixed.Point26_6{X: fixed.I(x), Y: fixed.I(y)}
	d := &font.Drawer{
		Dst:  dst,
		Src:  image.NewUniform(col),
		Face: basicfont.Face7x13,
		Dot:  point,
	}
	d.DrawString(label)
}

func renderCalendarOverlay(bg image.Image) *image.RGBA {
	bounds := bg.Bounds()
	rgba := image.NewRGBA(bounds)
	draw.Draw(rgba, bounds, bg, bounds.Min, draw.Src)

	now := time.Now()
	calW := 260
	calH := 160
	margin := 24
	x0 := bounds.Dx() - calW - margin
	y0 := margin

	// Semi-transparent dark background
	boxCol := color.RGBA{15, 15, 25, 210}
	for y := y0; y < y0+calH; y++ {
		for x := x0; x < x0+calW; x++ {
			orig := rgba.At(x, y)
			r1, g1, b1, _ := orig.RGBA()
			r2 := (uint32(boxCol.R)*uint32(boxCol.A) + r1*(255-uint32(boxCol.A))) / 255
			g2 := (uint32(boxCol.G)*uint32(boxCol.A) + g1*(255-uint32(boxCol.A))) / 255
			b2 := (uint32(boxCol.B)*uint32(boxCol.A) + b1*(255-uint32(boxCol.A))) / 255
			rgba.Set(x, y, color.RGBA{R: uint8(r2 >> 8), G: uint8(g2 >> 8), B: uint8(b2 >> 8), A: 255})
		}
	}

	// Border
	borderColor := color.RGBA{155, 89, 215, 230}
	for x := x0; x < x0+calW; x++ {
		rgba.Set(x, y0, borderColor)
		rgba.Set(x, y0+calH-1, borderColor)
	}
	for y := y0; y < y0+calH; y++ {
		rgba.Set(x0, y, borderColor)
		rgba.Set(x0+calW-1, y, borderColor)
	}

	// Title
	title := fmt.Sprintf("%d %s %d", now.Day(), ruMonths[int(now.Month())], now.Year())
	drawString(rgba, x0+20, y0+24, title, color.RGBA{255, 255, 255, 255})

	// Days of week header
	for i, d := range ruDays {
		col := color.RGBA{190, 190, 220, 255}
		if i >= 5 {
			col = color.RGBA{255, 100, 100, 255}
		}
		drawString(rgba, x0+16+i*34, y0+48, d, col)
	}

	// Simple month days calculation
	firstDay := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	startWeekday := (int(firstDay.Weekday()) + 6) % 7 // Monday = 0
	daysInMonth := time.Date(now.Year(), now.Month()+1, 0, 0, 0, 0, 0, time.Local).Day()

	curX := startWeekday
	curY := 0
	for d := 1; d <= daysInMonth; d++ {
		posX := x0 + 16 + curX*34
		posY := y0 + 72 + curY*18

		dayCol := color.RGBA{230, 230, 240, 255}
		if d == now.Day() {
			dayCol = color.RGBA{0, 240, 255, 255} // Highlight today
			// Draw circle / marker behind today
			for dy := -9; dy <= 4; dy++ {
				for dx := -3; dx <= 16; dx++ {
					rgba.Set(posX+dx, posY+dy, color.RGBA{80, 40, 120, 200})
				}
			}
		} else if curX >= 5 {
			dayCol = color.RGBA{255, 120, 120, 240}
		}

		drawString(rgba, posX, posY, fmt.Sprintf("%2d", d), dayCol)

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
		jpeg.Encode(f, finalImg, &jpeg.Options{Quality: 92})
		f.Close()
		setWallpaperWin(outPath)
	}
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
			pExit, _ := syscall.UTF16PtrFromString("❌ Выход")

			procAppendMenuW.Call(hMenu, MF_STRING, IDM_CHANGE_NOW, uintptr(unsafe.Pointer(pChange)))
			procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
			procAppendMenuW.Call(hMenu, MF_STRING, IDM_EXIT, uintptr(unsafe.Pointer(pExit)))

			var pt POINT
			procGetCursorPos.Call(uintptr(unsafe.Pointer(&pt)))
			procSetForegroundWindow.Call(uintptr(hwnd))
			procTrackPopupMenu.Call(hMenu, 0x0002 /* TPM_RIGHTBUTTON */, uintptr(pt.X), uintptr(pt.Y), 0, uintptr(hwnd), 0)
			return 0
		}
	case WM_COMMAND:
		switch wParam {
		case IDM_CHANGE_NOW:
			go cycleWallpaper()
		case IDM_EXIT:
			procShell_NotifyIconW.Call(NIM_DELETE, uintptr(unsafe.Pointer(&nid)))
			procPostQuitMessage.Call(0)
		}
		return 0
	}
	ret, _, _ := procDefWindowProcW.Call(uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

func main() {
	appDataDir = filepath.Join(os.Getenv("APPDATA"), "GIN-Wallpaper-Calend")
	os.MkdirAll(appDataDir, 0755)

	rand.Seed(time.Now().UnixNano())

	// Initial wallpaper cycle on startup
	go cycleWallpaper()

	// 3-hour automatic timer
	go func() {
		ticker := time.NewTicker(3 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			cycleWallpaper()
		}
	}()

	// Register Window class
	className, _ := syscall.UTF16PtrFromString("GIN_Wallpaper_TrayClass")
	wc := WNDCLASSEXW{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEXW{})),
		LpfnWndProc:   syscall.NewCallback(wndProc),
		LpszClassName: className,
	}
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	hwnd, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(className)),
		0, 0, 0, 0, 0, 0, 0, 0, 0,
	)
	hwndTray = syscall.Handle(hwnd)

	// Load custom icon from installed directory
	exePath, _ := os.Executable()
	icoPath := filepath.Join(filepath.Dir(exePath), "app.ico")
	pIco, _ := syscall.UTF16PtrFromString(icoPath)
	hIco, _, _ := procLoadImageW.Call(0, uintptr(unsafe.Pointer(pIco)), 1 /* IMAGE_ICON */, 32, 32, 0x00000010 /* LR_LOADFROMFILE */)
	hIconApp = syscall.Handle(hIco)

	// Setup tray notification icon
	nid.CbSize = uint32(unsafe.Sizeof(nid))
	nid.Hwnd = hwndTray
	nid.UID = 1
	nid.UFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP
	nid.UCallbackMessage = WM_TRAYICON
	nid.HIcon = hIconApp

	tip, _ := syscall.UTF16FromString("GIN-Wallpaper-Calend v003")
	for i := 0; i < len(tip) && i < 127; i++ {
		nid.SzTip[i] = tip[i]
	}

	procShell_NotifyIconW.Call(NIM_ADD, uintptr(unsafe.Pointer(&nid)))

	// Message pump
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

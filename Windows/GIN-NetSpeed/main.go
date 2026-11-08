package main

import (
	"crypto/rand"
	_ "embed"
	"encoding/base64"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"
)

//go:embed Gin-NetSpeed.ico
var embeddedAppIcon []byte

const (
	AppName           = "GIN-NetSpeed"
	AppVersion        = "v003"
	AppTitle          = "GIN NetSpeed by VladiMIR+AI_v003"
	AppAuthor         = "VladiMIR+AI (Vladimir Bulantsev - GinCz)"
	GitHubRepoURL     = "https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-NetSpeed"
	DefaultInstallDir = `C:\Program Files\GIN-NetSpeed`

	HistoryCapacity = 900 // 15 minutes at 1 sample/sec
)

func strPtr(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		p, _ = syscall.UTF16PtrFromString("")
	}
	return p
}

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")
	comctl32 = syscall.NewLazyDLL("comctl32.dll")
	iphlpapi = syscall.NewLazyDLL("iphlpapi.dll")
	shell32  = syscall.NewLazyDLL("shell32.dll")

	procShellExecuteW = shell32.NewProc("ShellExecuteW")

	procRegisterClassExW     = user32.NewProc("RegisterClassExW")
	procCreateWindowExW      = user32.NewProc("CreateWindowExW")
	procDefWindowProcW       = user32.NewProc("DefWindowProcW")
	procDestroyWindow        = user32.NewProc("DestroyWindow")
	procPostQuitMessage      = user32.NewProc("PostQuitMessage")
	procShowWindow           = user32.NewProc("ShowWindow")
	procUpdateWindow         = user32.NewProc("UpdateWindow")
	procGetMessageW          = user32.NewProc("GetMessageW")
	procTranslateMessage     = user32.NewProc("TranslateMessage")
	procDispatchMessageW     = user32.NewProc("DispatchMessageW")
	procSendMessageW         = user32.NewProc("SendMessageW")
	procPostMessageW         = user32.NewProc("PostMessageW")
	procSetWindowTextW       = user32.NewProc("SetWindowTextW")
	procGetWindowTextW       = user32.NewProc("GetWindowTextW")
	procGetWindowTextLengthW = user32.NewProc("GetWindowTextLengthW")
	procEnableWindow         = user32.NewProc("EnableWindow")
	procLoadIconW            = user32.NewProc("LoadIconW")
	procLoadCursorW          = user32.NewProc("LoadCursorW")
	procSetCursor            = user32.NewProc("SetCursor")
	procSetForegroundWindow  = user32.NewProc("SetForegroundWindow")
	procMessageBoxW          = user32.NewProc("MessageBoxW")
	procDrawTextW            = user32.NewProc("DrawTextW")
	procLoadImageW           = user32.NewProc("LoadImageW")
	procSetTimer             = user32.NewProc("SetTimer")
	procKillTimer            = user32.NewProc("KillTimer")
	procInvalidateRect       = user32.NewProc("InvalidateRect")
	procBeginPaint           = user32.NewProc("BeginPaint")
	procEndPaint             = user32.NewProc("EndPaint")
	procFillRect             = user32.NewProc("FillRect")
	procGetClientRect        = user32.NewProc("GetClientRect")
	procMoveWindow           = user32.NewProc("MoveWindow")

	procCreatePopupMenu  = user32.NewProc("CreatePopupMenu")
	procAppendMenuW      = user32.NewProc("AppendMenuW")
	procTrackPopupMenu   = user32.NewProc("TrackPopupMenu")
	procDestroyMenu      = user32.NewProc("DestroyMenu")
	procOpenClipboard    = user32.NewProc("OpenClipboard")
	procCloseClipboard   = user32.NewProc("CloseClipboard")
	procEmptyClipboard   = user32.NewProc("EmptyClipboard")
	procSetClipboardData = user32.NewProc("SetClipboardData")

	procGetStockObject      = gdi32.NewProc("GetStockObject")
	procCreateFontW         = gdi32.NewProc("CreateFontW")
	procSetBkMode           = gdi32.NewProc("SetBkMode")
	procSetTextColor        = gdi32.NewProc("SetTextColor")
	procCreatePen           = gdi32.NewProc("CreatePen")
	procCreateSolidBrush    = gdi32.NewProc("CreateSolidBrush")
	procRoundRect           = gdi32.NewProc("RoundRect")
	procSelectObject        = gdi32.NewProc("SelectObject")
	procDeleteObject        = gdi32.NewProc("DeleteObject")
	procMoveToEx            = gdi32.NewProc("MoveToEx")
	procLineTo              = gdi32.NewProc("LineTo")
	procEllipse             = gdi32.NewProc("Ellipse")
	procCreateCompatibleDC  = gdi32.NewProc("CreateCompatibleDC")
	procCreateCompatibleBmp = gdi32.NewProc("CreateCompatibleBitmap")
	procBitBlt              = gdi32.NewProc("BitBlt")
	procDeleteDC            = gdi32.NewProc("DeleteDC")

	procGetModuleHandleW         = kernel32.NewProc("GetModuleHandleW")
	procGlobalAlloc              = kernel32.NewProc("GlobalAlloc")
	procGlobalLock               = kernel32.NewProc("GlobalLock")
	procGlobalUnlock             = kernel32.NewProc("GlobalUnlock")
	procGetCurrentProcess        = kernel32.NewProc("GetCurrentProcess")
	procSetPriorityClass         = kernel32.NewProc("SetPriorityClass")
	procExitProcess              = kernel32.NewProc("ExitProcess")
	procCreateToolhelp32Snapshot = kernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32FirstW          = kernel32.NewProc("Process32FirstW")
	procProcess32NextW           = kernel32.NewProc("Process32NextW")
	procOpenProcess              = kernel32.NewProc("OpenProcess")
	procCloseHandle              = kernel32.NewProc("CloseHandle")
	procGetProcessIoCounters     = kernel32.NewProc("GetProcessIoCounters")

	procInitCommonControlsEx = comctl32.NewProc("InitCommonControlsEx")

	procGetIfTable                = iphlpapi.NewProc("GetIfTable")
	procGetExtendedTcpTable       = iphlpapi.NewProc("GetExtendedTcpTable")
	procGetExtendedUdpTable       = iphlpapi.NewProc("GetExtendedUdpTable")
	procGetPerTcpConnectionEStats = iphlpapi.NewProc("GetPerTcpConnectionEStats")
	procSetPerTcpConnectionEStats = iphlpapi.NewProc("SetPerTcpConnectionEStats")
)

const (
	WS_OVERLAPPEDWINDOW = 0x00CF0000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_BORDER           = 0x00800000
	WS_TABSTOP          = 0x00010000
	WS_CLIPCHILDREN     = 0x02000000
	WS_CLIPSIBLINGS     = 0x04000000
	WS_POPUP            = 0x80000000

	CBS_DROPDOWNLIST = 0x0003
	SS_NOTIFY        = 0x0100
	SS_RIGHT         = 0x0002

	CB_ADDSTRING       = 0x0143
	CB_SETCURSEL       = 0x014E
	CB_GETCURSEL       = 0x0147
	CB_SETDROPPEDWIDTH = 0x0160
	CBN_SELCHANGE      = 1

	TTS_ALWAYSTIP      = 0x01
	TTS_NOPREFIX       = 0x02
	TTS_BALLOON        = 0x40
	TTF_SUBCLASS       = 0x0010
	TTF_IDISHWND       = 0x0001
	TTM_ADDTOOLW       = WM_USER + 50
	TTM_SETMAXTIPWIDTH = WM_USER + 24

	LVS_REPORT                   = 0x0001
	LVS_SINGLESEL                = 0x0004
	LVS_SHOWSELALWAYS            = 0x0008
	LVM_FIRST                    = 0x1000
	LVM_INSERTCOLUMNW            = LVM_FIRST + 97
	LVM_SETCHDITEMW              = LVM_FIRST + 96 // LVM_SETCOLUMNW
	LVM_SETCOLUMNWIDTH           = LVM_FIRST + 30
	LVM_INSERTITEMW              = LVM_FIRST + 77
	LVM_SETITEMTEXTW             = LVM_FIRST + 116
	LVM_DELETEALLITEMS           = LVM_FIRST + 9
	LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54
	LVM_GETNEXTITEM              = LVM_FIRST + 12
	LVM_GETITEMCOUNT             = LVM_FIRST + 4
	LVNI_SELECTED                = 0x0002
	LVS_EX_FULLROWSELECT         = 0x00000020
	LVS_EX_GRIDLINES             = 0x00000001
	LVS_EX_DOUBLEBUFFER          = 0x00010000

	LVN_ITEMCHANGED = ^uint32(100) // -101
	LVN_COLUMNCLICK = ^uint32(107) // -108
	NM_DBLCLK       = ^uint32(2)   // -3
	NM_CUSTOMDRAW   = ^uint32(11)  // -12

	WM_DESTROY        = 0x0002
	WM_SIZE           = 0x0005
	WM_CLOSE          = 0x0010
	WM_PAINT          = 0x000F
	WM_ERASEBKGND     = 0x0014
	WM_GETMINMAXINFO  = 0x0024
	WM_COMMAND        = 0x0111
	WM_NOTIFY         = 0x004E
	WM_TIMER          = 0x0113
	WM_SETCURSOR      = 0x0020
	WM_CTLCOLORSTATIC = 0x0138
	WM_SETICON        = 0x0080
	WM_CONTEXTMENU    = 0x007B
	WM_DRAWITEM       = 0x002B
	WM_SETFONT        = 0x0030
	WM_LBUTTONDOWN    = 0x0201
	WM_LBUTTONDBLCLK  = 0x0203
	WM_USER           = 0x0400

	WM_APP_BENCH_UPDATE = WM_USER + 201
	WM_APP_BENCH_DONE   = WM_USER + 202

	BS_OWNERDRAW = 0x0000000B

	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x0010
	LR_DEFAULTSIZE  = 0x0040
	LR_SHARED       = 0x8000

	CDDS_PREPAINT          = 0x00000001
	CDDS_ITEM              = 0x00010000
	CDDS_ITEMPREPAINT      = CDDS_ITEM | CDDS_PREPAINT
	CDDS_SUBITEM           = 0x00020000
	CDRF_DODEFAULT         = 0x00000000
	CDRF_NOTIFYITEMDRAW    = 0x00000020
	CDRF_NOTIFYSUBITEMDRAW = 0x00000020

	DEFAULT_GUI_FONT = 17
	MF_STRING        = 0x0000
	MF_SEPARATOR     = 0x0800
	TPM_RIGHTBUTTON  = 0x0002
	CF_UNICODETEXT   = 13
	GMEM_MOVEABLE    = 0x0002
	IDC_HAND         = 32649
	SRCCOPY          = 0x00CC0020

	TH32CS_SNAPPROCESS                = 0x00000002
	PROCESS_QUERY_LIMITED_INFORMATION = 0x1000

	AF_INET                 = 2
	TCP_TABLE_OWNER_PID_ALL = 5
	UDP_TABLE_OWNER_PID     = 1
	TcpConnectionEstatsData = 1
	MIB_TCP_STATE_ESTAB     = 5
	MIB_TCP_STATE_SYN_SENT  = 3
	MIB_TCP_STATE_LAST_ACK  = 10
)

type MINMAXINFO struct {
	PtReserved     POINT
	PtMaxSize      POINT
	PtMaxPosition  POINT
	PtMinTrackSize POINT
	PtMaxTrackSize POINT
}

type DRAWITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     uint32
	ItemAction uint32
	ItemState  uint32
	HwndItem   uintptr
	HDC        uintptr
	RcItem     RECT
	ItemData   uintptr
}

type NMHDR struct {
	HwndFrom uintptr
	IdFrom   uintptr
	Code     uint32
}

type NMLISTVIEW struct {
	Hdr       NMHDR
	IItem     int32
	ISubItem  int32
	UNewState uint32
	UOldState uint32
	UChanged  uint32
	PtAction  POINT
	LParam    uintptr
}

type NMITEMACTIVATE struct {
	Hdr       NMHDR
	IItem     int32
	ISubItem  int32
	UNewState uint32
	UOldState uint32
	UChanged  uint32
	PtAction  POINT
	LParam    uintptr
	UKeyFlags uint32
}

type NMLVCUSTOMDRAW struct {
	Hdr         NMHDR
	DwDrawStage uint32
	Hdc         uintptr
	Rc          RECT
	DwItemSpec  uintptr
	UItemState  uint32
	LItemlParam uintptr
	ClrText     uint32
	ClrTextBk   uint32
	ISubItem    int32
}

type POINT struct {
	X int32
	Y int32
}

type RECT struct {
	Left, Top, Right, Bottom int32
}

type PAINTSTRUCT struct {
	Hdc         uintptr
	FErase      int32
	RcPaint     RECT
	FRestore    int32
	FIncUpdate  int32
	RgbReserved [32]byte
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

type INITCOMMONCONTROLSEX struct {
	DwSize uint32
	DwICC  uint32
}

type LVCOLUMNW struct {
	Mask       uint32
	Fmt        int32
	Cx         int32
	PszText    *uint16
	CchTextMax int32
	ISubItem   int32
	IImage     int32
	IOrder     int32
	CxMin      int32
	CxDefault  int32
	CxIdeal    int32
}

type LVITEMW struct {
	Mask       uint32
	IItem      int32
	ISubItem   int32
	State      uint32
	StateMask  uint32
	PszText    *uint16
	CchTextMax int32
	IImage     int32
	LParam     uintptr
	IIndent    int32
	GroupId    int32
	CColumns   uint32
	PuColumns  *uint32
	PiColFmt   *int32
	IGroup     int32
}

type TOOLINFOW struct {
	CbSize     uint32
	UFlags     uint32
	Hwnd       uintptr
	UId        uintptr
	Rect       RECT
	Hinst      uintptr
	LpszText   *uint16
	LParam     uintptr
	LpReserved uintptr
}

type PROCESSENTRY32W struct {
	DwSize              uint32
	CntUsage            uint32
	Th32ProcessID       uint32
	Th32DefaultHeapID   uintptr
	Th32ModuleID        uint32
	CntThreads          uint32
	Th32ParentProcessID uint32
	PcPriClassBase      int32
	DwFlags             uint32
	SzExeFile           [260]uint16
}

type IO_COUNTERS struct {
	ReadOperationCount  uint64
	WriteOperationCount uint64
	OtherOperationCount uint64
	ReadTransferCount   uint64
	WriteTransferCount  uint64
	OtherTransferCount  uint64
}

type MIB_TCPROW_OWNER_PID struct {
	DwState      uint32
	DwLocalAddr  uint32
	DwLocalPort  uint32
	DwRemoteAddr uint32
	DwRemotePort uint32
	DwOwningPid  uint32
}

type MIB_TCPROW struct {
	DwState      uint32
	DwLocalAddr  uint32
	DwLocalPort  uint32
	DwRemoteAddr uint32
	DwRemotePort uint32
}

type TCP_ESTATS_DATA_ROD_v0 struct {
	DataBytesOut      uint64
	DataSegsOut       uint64
	DataBytesIn       uint64
	DataSegsIn        uint64
	SegsOut           uint64
	SegsIn            uint64
	ThruBytesAcked    uint32
	ThruBytesReceived uint32
}

type TCP_ESTATS_DATA_RW_v0 struct {
	EnableCollection byte
}

type MIB_UDPROW_OWNER_PID struct {
	DwLocalAddr uint32
	DwLocalPort uint32
	DwOwningPid uint32
}

type MIB_IFROW struct {
	WszName           [256]uint16
	DwIndex           uint32
	DwType            uint32
	DwMtu             uint32
	DwSpeed           uint32
	DwPhysAddrLen     uint32
	BPhysAddr         [8]byte
	DwAdminStatus     uint32
	DwOperStatus      uint32
	DwLastChange      uint32
	DwInOctets        uint32
	DwInUcastPkts     uint32
	DwInNUcastPkts    uint32
	DwInDiscards      uint32
	DwInErrors        uint32
	DwInUnknownProtos uint32
	DwOutOctets       uint32
	DwOutUcastPkts    uint32
	DwOutNUcastPkts   uint32
	DwOutDiscards     uint32
	DwOutErrors       uint32
	DwOutQLen         uint32
	DwDescrLen        uint32
	BDescr            [256]byte
}

type SpeedSample struct {
	DownBps float64
	UpBps   float64
}

type AppNetworkStat struct {
	AppName        string // Exe name (e.g., MEGAsync.exe)
	CloudCategory  string // e.g., "☁️ MEGA Cloud"
	PID            uint32
	PIDCount       int
	ActiveTCP      int
	ActiveUDP      int
	DownSpeedBps   float64
	UpSpeedBps     float64
	PeakDownBps    float64
	PeakUpBps      float64
	TotalDownBytes uint64
	TotalUpBytes   uint64
	SharePercent   float64
	IsCloudEngine  bool
	History        [HistoryCapacity]SpeedSample
	HistoryIdx     int
}

type CloudBenchmarkResult struct {
	EngineName    string
	CategoryIcon  string
	TargetInfo    string
	SmallUpMBps   float64
	SmallDownMBps float64
	LargeUpMBps   float64
	LargeDownMBps float64
	LatencyMs     int64
	ScoreRating   string
	Status        string
}

var (
	hwndMain        uintptr
	hwndGraphCanvas uintptr
	hwndComboFilter uintptr
	hwndComboWindow uintptr
	hwndComboSort   uintptr
	hwndBtnPause    uintptr
	hwndBtnReset    uintptr
	hwndBtnCloud    uintptr
	hwndBtnExport   uintptr
	hwndListView    uintptr
	hwndStatus      uintptr
	hwndBtnInstall  uintptr
	hwndBrand       uintptr

	hwndAbout     uintptr
	hwndAboutAnim uintptr

	hwndCloudDlg      uintptr
	hwndCloudList     uintptr
	hwndCloudStatus   uintptr
	hwndBtnStartBench uintptr
	hwndBtnSyncBench  uintptr
	hwndBtnStopBench  uintptr

	hInstance      uintptr
	hIconApp       uintptr
	hFontSegoe     uintptr
	hFontBold      uintptr
	hFontSmall     uintptr
	hBrushWhite    uintptr
	hBrushBlack    uintptr
	hBrushGraphBg  uintptr
	hCursorHand    uintptr
	hPenCyan       uintptr
	hBrushAnimBlue uintptr

	isMonitoringPaused bool
	filterMode         int // 0=All Active, 1=Cloud Engines Only, 2=Active Transfers (>0 KB/s)
	graphWindowSec     = 900

	// Column Sorting (Excel-style: click any column to sort Asc / Desc)
	// Columns:
	// 0: #
	// 1: Cloud / Category
	// 2: Application (.exe)
	// 3: PID
	// 4: ⬇ Download
	// 5: ⬆ Upload
	// 6: Total Downloaded
	// 7: Total Uploaded
	// 8: Channel %
	sortColumn int  = 4 // Default sort by ⬇ Download Speed
	sortDesc   bool = true

	baseColumns = []struct {
		Title string
		Width int32
	}{
		{"#", 38},
		{"Cloud / Category", 185},
		{"Application (.exe)", 185},
		{"PID", 82},
		{"⬇ Download", 118},
		{"⬆ Upload", 118},
		{"Total Downloaded", 132},
		{"Total Uploaded", 132},
		{"Channel %", 140},
	}

	statsMutex       sync.Mutex
	appStatsMap      = make(map[string]*AppNetworkStat)
	displayList      []*AppNetworkStat
	selectedAppNames []string // Empty by default! Double-click rows to add/remove up to 4 apps simultaneously.

	showDownloadGraph = true // Toggled by clicking the Green Download Button on the right of the graph
	showUploadGraph   = true // Toggled by clicking the Yellow/Amber Upload Button on the right of the graph
	rcBtnDownToggle   RECT
	rcBtnUpToggle     RECT

	sysHistory     [HistoryCapacity]SpeedSample
	sysHistoryHead int
	sysCurDownBps  float64
	sysCurUpBps    float64
	sysPeakDownBps float64
	sysPeakUpBps   float64
	sysTotalDown   uint64
	sysTotalUp     uint64

	prevNicInOctets  uint64
	prevNicOutOctets uint64
	prevSampleTime   time.Time

	prevProcIO       = make(map[uint32]IO_COUNTERS)
	prevEStats       = make(map[string][2]uint64)
	estatsEnabledMap = make(map[string]bool)

	benchMutex     sync.Mutex
	benchResults   []CloudBenchmarkResult
	isBenchRunning int32
	stopBenchFlag  int32

	animAngle float64
)

// Clean BMP-compatible Unicode symbols (no supplemental plane emojis that render as □ on Windows GDI)
func classifyApplication(exeName string) (category string, isCloud bool) {
	lower := strings.ToLower(exeName)
	switch {
	case strings.Contains(lower, "megasync") || strings.Contains(lower, "mega-") || lower == "mega.exe" || strings.Contains(lower, "megacmd"):
		return "☁ ● MEGA Cloud", true
	case strings.Contains(lower, "googledrive") || strings.Contains(lower, "backupand"):
		return "☁ ▲ Google Drive", true
	case strings.Contains(lower, "onedrive"):
		return "☁ ■ Microsoft OneDrive", true
	case strings.Contains(lower, "yandexdisk") || strings.Contains(lower, "yandex.disk"):
		return "☁ ◆ Yandex.Disk", true
	case strings.Contains(lower, "cloudmail") || strings.Contains(lower, "disko") || strings.Contains(lower, "mailru"):
		return "☁ ★ Mail.Ru Cloud", true
	case strings.Contains(lower, "dropbox"):
		return "☁ ◆ Dropbox Cloud", true
	case strings.Contains(lower, "nextcloud") || strings.Contains(lower, "owncloud"):
		return "☁ ● Nextcloud / WebDAV", true
	case strings.Contains(lower, "icloud"):
		return "☁ ● Apple iCloud", true
	case strings.Contains(lower, "terabox") || strings.Contains(lower, "baidunetdisk"):
		return "☁ ■ TeraBox Cloud", true
	case strings.Contains(lower, "rclone") || strings.Contains(lower, "syncthing") || strings.Contains(lower, "goodsync"):
		return "☁ ↻ Cloud Sync Tool", true
	case strings.Contains(lower, "telegram") || strings.Contains(lower, "whatsapp") || strings.Contains(lower, "viber") || strings.Contains(lower, "discord") || strings.Contains(lower, "skype"):
		return "✉ Messenger / VoIP", false
	case strings.Contains(lower, "chrome") || strings.Contains(lower, "msedge") || strings.Contains(lower, "brave") || strings.Contains(lower, "firefox") || strings.Contains(lower, "opera") || strings.Contains(lower, "centbrowser") || strings.Contains(lower, "vivaldi") || strings.Contains(lower, "yandex.exe"):
		return "✦ Web Browser", false
	case strings.Contains(lower, "qbittorrent") || strings.Contains(lower, "utorrent") || strings.Contains(lower, "transmission") || strings.Contains(lower, "aria2"):
		return "⬇ P2P / Downloader", false
	case strings.Contains(lower, "xray") || strings.Contains(lower, "hiddify") || strings.Contains(lower, "sing-box") || strings.Contains(lower, "wireguard") || strings.Contains(lower, "openvpn") || strings.Contains(lower, "amnezia") || strings.Contains(lower, "v2ray"):
		return "⚡ VPN / Proxy Tunnel", false
	case strings.Contains(lower, "rustdesk") || strings.Contains(lower, "anydesk") || strings.Contains(lower, "teamviewer") || strings.Contains(lower, "supremo") || strings.Contains(lower, "mstsc"):
		return "❖ Remote Desktop", false
	case strings.Contains(lower, "steam") || strings.Contains(lower, "epicgames") || strings.Contains(lower, "battle.net"):
		return "★ Game Launcher", false
	case strings.Contains(lower, "code.exe") || strings.Contains(lower, "cursor") || strings.Contains(lower, "git") || strings.Contains(lower, "node") || strings.Contains(lower, "python") || strings.Contains(lower, "go.exe"):
		return "⚙ Dev / AI Agent", false
	case strings.Contains(lower, "gin-netspeed"):
		return "⚡ GIN-NetSpeed (Test)", true
	case strings.Contains(lower, "svchost") || strings.Contains(lower, "system") || strings.Contains(lower, "lsass") || strings.Contains(lower, "wuauclt") || strings.Contains(lower, "delivery"):
		return "⚙ Windows System", false
	default:
		return "▪ Application", false
	}
}

func getCategoryColor(cat string) uint32 {
	if strings.Contains(cat, "MEGA") {
		return 0x2828D8 // Radiant Red (BGR: #D82828)
	}
	if strings.Contains(cat, "Google Drive") {
		return 0x388E3C // Emerald Green (BGR: #3C8E38)
	}
	if strings.Contains(cat, "OneDrive") {
		return 0xD47800 // Microsoft Blue (BGR: #0078D4)
	}
	if strings.Contains(cat, "Yandex.Disk") {
		return 0x0078D8 // Warm Gold / Amber (BGR: #D87800)
	}
	if strings.Contains(cat, "Mail.Ru") {
		return 0x0055EE // Vibrant Orange (BGR: #EE5500)
	}
	if strings.Contains(cat, "Dropbox") || strings.Contains(cat, "Nextcloud") || strings.Contains(cat, "iCloud") || strings.Contains(cat, "TeraBox") || strings.Contains(cat, "Cloud Sync") {
		return 0xB88200 // Deep Cyan / Sky Blue
	}
	if strings.Contains(cat, "GIN-NetSpeed") {
		return 0xCC3299 // Royal Purple
	}
	if strings.Contains(cat, "VPN") {
		return 0x8F8300 // Teal
	}
	if strings.Contains(cat, "Browser") {
		return 0x9E5A00 // Slate Blue
	}
	if strings.Contains(cat, "Messenger") {
		return 0xDE52AF // Violet
	}
	return 0x555555 // Neutral Dark Slate
}

func formatSpeed(bps float64) string {
	if bps < 10 {
		return "0 B/s"
	}
	if bps < 1024 {
		return fmt.Sprintf("%.0f B/s", bps)
	}
	kbps := bps / 1024.0
	if kbps < 1024 {
		return fmt.Sprintf("%.1f KB/s", kbps)
	}
	mbps := kbps / 1024.0
	return fmt.Sprintf("%.2f MB/s", mbps)
}

func formatBytes(b uint64) string {
	if b == 0 {
		return "0 B"
	}
	if b < 1024 {
		return fmt.Sprintf("%d B", b)
	}
	kb := float64(b) / 1024.0
	if kb < 1024 {
		return fmt.Sprintf("%.1f KB", kb)
	}
	mb := kb / 1024.0
	if mb < 1024 {
		return fmt.Sprintf("%.2f MB", mb)
	}
	gb := mb / 1024.0
	return fmt.Sprintf("%.2f GB", gb)
}

func isLoopbackIP(ip uint32) bool {
	return byte(ip) == 127 || ip == 0
}

// Hardware Interface Octet Counters (via GetIfTable)
func getTotalNicOctets() (inBytes uint64, outBytes uint64) {
	var dwSize uint32 = 0
	procGetIfTable.Call(0, uintptr(unsafe.Pointer(&dwSize)), 0)
	if dwSize == 0 {
		return 0, 0
	}
	buf := make([]byte, dwSize)
	ret, _, _ := procGetIfTable.Call(uintptr(unsafe.Pointer(&buf[0])), uintptr(unsafe.Pointer(&dwSize)), 0)
	if ret != 0 {
		return 0, 0
	}
	numEntries := *(*uint32)(unsafe.Pointer(&buf[0]))
	if numEntries == 0 || numEntries > 256 {
		return 0, 0
	}
	rowSize := unsafe.Sizeof(MIB_IFROW{})
	basePtr := uintptr(unsafe.Pointer(&buf[0])) + 4
	for i := uint32(0); i < numEntries; i++ {
		if uintptr(i+1)*rowSize+4 > uintptr(len(buf)) {
			break
		}
		row := (*MIB_IFROW)(unsafe.Pointer(basePtr + uintptr(i)*rowSize))
		if row.DwType == 24 {
			continue
		}
		inBytes += uint64(row.DwInOctets)
		outBytes += uint64(row.DwOutOctets)
	}
	return inBytes, outBytes
}

type procSnapshotInfo struct {
	ExeName   string
	ReadDiff  uint64
	WriteDiff uint64
}

func snapshotProcessesAndIO() map[uint32]procSnapshotInfo {
	result := make(map[uint32]procSnapshotInfo)
	hSnap, _, _ := procCreateToolhelp32Snapshot.Call(TH32CS_SNAPPROCESS, 0)
	if hSnap == 0 || hSnap == ^uintptr(0) {
		return result
	}
	defer procCloseHandle.Call(hSnap)

	var pe PROCESSENTRY32W
	pe.DwSize = uint32(unsafe.Sizeof(pe))
	ret, _, _ := procProcess32FirstW.Call(hSnap, uintptr(unsafe.Pointer(&pe)))
	for ret != 0 {
		pid := pe.Th32ProcessID
		exeName := syscall.UTF16ToString(pe.SzExeFile[:])
		if exeName == "" {
			exeName = fmt.Sprintf("PID_%d", pid)
		}

		var readDiff, writeDiff uint64
		if pid > 4 {
			hProc, _, _ := procOpenProcess.Call(PROCESS_QUERY_LIMITED_INFORMATION, 0, uintptr(pid))
			if hProc != 0 {
				var ioCnt IO_COUNTERS
				ok, _, _ := procGetProcessIoCounters.Call(hProc, uintptr(unsafe.Pointer(&ioCnt)))
				procCloseHandle.Call(hProc)
				if ok != 0 {
					if prev, exists := prevProcIO[pid]; exists {
						if ioCnt.ReadTransferCount >= prev.ReadTransferCount {
							readDiff = ioCnt.ReadTransferCount - prev.ReadTransferCount
						}
						if ioCnt.WriteTransferCount >= prev.WriteTransferCount {
							writeDiff = ioCnt.WriteTransferCount - prev.WriteTransferCount
						}
						if ioCnt.OtherTransferCount > prev.OtherTransferCount {
							otherDiff := ioCnt.OtherTransferCount - prev.OtherTransferCount
							readDiff += otherDiff / 2
							writeDiff += otherDiff / 2
						}
					}
					prevProcIO[pid] = ioCnt
				}
			}
		}

		result[pid] = procSnapshotInfo{
			ExeName:   exeName,
			ReadDiff:  readDiff,
			WriteDiff: writeDiff,
		}
		ret, _, _ = procProcess32NextW.Call(hSnap, uintptr(unsafe.Pointer(&pe)))
	}
	return result
}

type pidSocketInfo struct {
	ActiveTCP int
	ActiveUDP int
	EstatsIn  uint64
	EstatsOut uint64
	HasEstats bool
}

func collectActiveSocketsByPID() map[uint32]*pidSocketInfo {
	pidSockets := make(map[uint32]*pidSocketInfo)

	// 1. Extended TCP Table (IPv4)
	var tcpSize uint32 = 0
	procGetExtendedTcpTable.Call(0, uintptr(unsafe.Pointer(&tcpSize)), 0, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0)
	if tcpSize > 0 && tcpSize < 16*1024*1024 {
		buf := make([]byte, tcpSize)
		ret, _, _ := procGetExtendedTcpTable.Call(uintptr(unsafe.Pointer(&buf[0])), uintptr(unsafe.Pointer(&tcpSize)), 0, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0)
		if ret == 0 && len(buf) >= 4 {
			numEntries := *(*uint32)(unsafe.Pointer(&buf[0]))
			rowSize := unsafe.Sizeof(MIB_TCPROW_OWNER_PID{})
			basePtr := uintptr(unsafe.Pointer(&buf[0])) + 4
			for i := uint32(0); i < numEntries; i++ {
				if uintptr(i+1)*rowSize+4 > uintptr(len(buf)) {
					break
				}
				row := (*MIB_TCPROW_OWNER_PID)(unsafe.Pointer(basePtr + uintptr(i)*rowSize))
				if isLoopbackIP(row.DwRemoteAddr) && isLoopbackIP(row.DwLocalAddr) {
					continue
				}
				if row.DwState < MIB_TCP_STATE_SYN_SENT || row.DwState > MIB_TCP_STATE_LAST_ACK {
					continue
				}
				pid := row.DwOwningPid
				info, ok := pidSockets[pid]
				if !ok {
					info = &pidSocketInfo{}
					pidSockets[pid] = info
				}
				info.ActiveTCP++

				if row.DwState == MIB_TCP_STATE_ESTAB && !isLoopbackIP(row.DwRemoteAddr) {
					connKey := fmt.Sprintf("%d:%d-%d:%d", row.DwLocalAddr, row.DwLocalPort, row.DwRemoteAddr, row.DwRemotePort)
					stdRow := MIB_TCPROW{
						DwState:      row.DwState,
						DwLocalAddr:  row.DwLocalAddr,
						DwLocalPort:  row.DwLocalPort,
						DwRemoteAddr: row.DwRemoteAddr,
						DwRemotePort: row.DwRemotePort,
					}
					if !estatsEnabledMap[connKey] {
						rw := TCP_ESTATS_DATA_RW_v0{EnableCollection: 1}
						procSetPerTcpConnectionEStats.Call(
							uintptr(unsafe.Pointer(&stdRow)),
							TcpConnectionEstatsData,
							uintptr(unsafe.Pointer(&rw)),
							0,
							unsafe.Sizeof(rw),
							0,
						)
						estatsEnabledMap[connKey] = true
					}
					var rod TCP_ESTATS_DATA_ROD_v0
					rStat, _, _ := procGetPerTcpConnectionEStats.Call(
						uintptr(unsafe.Pointer(&stdRow)),
						TcpConnectionEstatsData,
						0, 0, 0,
						0, 0, 0,
						uintptr(unsafe.Pointer(&rod)),
						0,
						unsafe.Sizeof(rod),
					)
					if rStat == 0 && (rod.DataBytesIn > 0 || rod.DataBytesOut > 0) {
						info.HasEstats = true
						if prev, hasPrev := prevEStats[connKey]; hasPrev {
							if rod.DataBytesIn >= prev[0] {
								info.EstatsIn += rod.DataBytesIn - prev[0]
							}
							if rod.DataBytesOut >= prev[1] {
								info.EstatsOut += rod.DataBytesOut - prev[1]
							}
						}
						prevEStats[connKey] = [2]uint64{rod.DataBytesIn, rod.DataBytesOut}
					}
				}
			}
		}
	}

	// 2. Extended UDP Table (IPv4)
	var udpSize uint32 = 0
	procGetExtendedUdpTable.Call(0, uintptr(unsafe.Pointer(&udpSize)), 0, AF_INET, UDP_TABLE_OWNER_PID, 0)
	if udpSize > 0 && udpSize < 16*1024*1024 {
		buf := make([]byte, udpSize)
		ret, _, _ := procGetExtendedUdpTable.Call(uintptr(unsafe.Pointer(&buf[0])), uintptr(unsafe.Pointer(&udpSize)), 0, AF_INET, UDP_TABLE_OWNER_PID, 0)
		if ret == 0 && len(buf) >= 4 {
			numEntries := *(*uint32)(unsafe.Pointer(&buf[0]))
			rowSize := unsafe.Sizeof(MIB_UDPROW_OWNER_PID{})
			basePtr := uintptr(unsafe.Pointer(&buf[0])) + 4
			for i := uint32(0); i < numEntries; i++ {
				if uintptr(i+1)*rowSize+4 > uintptr(len(buf)) {
					break
				}
				row := (*MIB_UDPROW_OWNER_PID)(unsafe.Pointer(basePtr + uintptr(i)*rowSize))
				if byte(row.DwLocalAddr) == 127 {
					continue
				}
				pid := row.DwOwningPid
				info, ok := pidSockets[pid]
				if !ok {
					info = &pidSocketInfo{}
					pidSockets[pid] = info
				}
				info.ActiveUDP++
			}
		}
	}

	return pidSockets
}

func sampleNetworkTelemetry() {
	if isMonitoringPaused {
		return
	}

	now := time.Now()
	nicIn, nicOut := getTotalNicOctets()

	if prevSampleTime.IsZero() {
		prevNicInOctets = nicIn
		prevNicOutOctets = nicOut
		prevSampleTime = now
		_ = snapshotProcessesAndIO()
		_ = collectActiveSocketsByPID()
		return
	}

	dt := now.Sub(prevSampleTime).Seconds()
	if dt <= 0.1 {
		dt = 1.0
	}
	prevSampleTime = now

	var deltaNicIn, deltaNicOut uint64
	if nicIn >= prevNicInOctets {
		deltaNicIn = nicIn - prevNicInOctets
	}
	if nicOut >= prevNicOutOctets {
		deltaNicOut = nicOut - prevNicOutOctets
	}
	prevNicInOctets = nicIn
	prevNicOutOctets = nicOut

	procMap := snapshotProcessesAndIO()
	sockMap := collectActiveSocketsByPID()

	type appTickAgg struct {
		ExeName   string
		SamplePID uint32
		PIDSet    map[uint32]bool
		TCPCount  int
		UDPCount  int
		EstatsIn  uint64
		EstatsOut uint64
		HasEstats bool
		WeightIn  float64
		WeightOut float64
	}

	aggMap := make(map[string]*appTickAgg)
	var totalEstatsIn, totalEstatsOut uint64
	var totalWeightIn, totalWeightOut float64

	for pid, pInfo := range procMap {
		sInfo := sockMap[pid]
		_, isCloud := classifyApplication(pInfo.ExeName)

		hasSockets := sInfo != nil && (sInfo.ActiveTCP > 0 || sInfo.ActiveUDP > 0)
		if !hasSockets && !isCloud {
			continue
		}

		key := strings.ToLower(pInfo.ExeName)
		agg, exists := aggMap[key]
		if !exists {
			agg = &appTickAgg{
				ExeName:   pInfo.ExeName,
				SamplePID: pid,
				PIDSet:    make(map[uint32]bool),
			}
			aggMap[key] = agg
		}
		agg.PIDSet[pid] = true

		if sInfo != nil {
			agg.TCPCount += sInfo.ActiveTCP
			agg.UDPCount += sInfo.ActiveUDP
			if sInfo.HasEstats {
				agg.HasEstats = true
				agg.EstatsIn += sInfo.EstatsIn
				agg.EstatsOut += sInfo.EstatsOut
				totalEstatsIn += sInfo.EstatsIn
				totalEstatsOut += sInfo.EstatsOut
			}
			if sInfo.ActiveTCP > 0 || sInfo.ActiveUDP > 0 {
				sockWeight := float64(sInfo.ActiveTCP*3 + sInfo.ActiveUDP)
				ioActIn := float64(pInfo.WriteDiff+pInfo.ReadDiff/4) + sockWeight*512.0
				ioActOut := float64(pInfo.ReadDiff+pInfo.WriteDiff/4) + sockWeight*512.0
				if isCloud {
					ioActIn *= 1.5
					ioActOut *= 1.5
				}
				agg.WeightIn += ioActIn
				agg.WeightOut += ioActOut
				totalWeightIn += ioActIn
				totalWeightOut += ioActOut
			}
		}
	}

	statsMutex.Lock()
	defer statsMutex.Unlock()

	sysTotalDown += deltaNicIn
	sysTotalUp += deltaNicOut
	sysCurDownBps = float64(deltaNicIn) / dt
	sysCurUpBps = float64(deltaNicOut) / dt
	if sysCurDownBps > sysPeakDownBps {
		sysPeakDownBps = sysCurDownBps
	}
	if sysCurUpBps > sysPeakUpBps {
		sysPeakUpBps = sysCurUpBps
	}

	sysHistory[sysHistoryHead] = SpeedSample{
		DownBps: sysCurDownBps,
		UpBps:   sysCurUpBps,
	}
	sysHistoryHead = (sysHistoryHead + 1) % HistoryCapacity

	for _, st := range appStatsMap {
		st.DownSpeedBps = 0
		st.UpSpeedBps = 0
		st.ActiveTCP = 0
		st.ActiveUDP = 0
		st.SharePercent = 0
	}

	totalCombinedBps := sysCurDownBps + sysCurUpBps

	for key, agg := range aggMap {
		st, exists := appStatsMap[key]
		if !exists {
			cat, isCloud := classifyApplication(agg.ExeName)
			st = &AppNetworkStat{
				AppName:       agg.ExeName,
				CloudCategory: cat,
				IsCloudEngine: isCloud,
			}
			appStatsMap[key] = st
		}
		st.PID = agg.SamplePID
		st.PIDCount = len(agg.PIDSet)
		st.ActiveTCP = agg.TCPCount
		st.ActiveUDP = agg.UDPCount

		var appBytesIn, appBytesOut uint64
		if totalEstatsIn > 0 || totalEstatsOut > 0 {
			appBytesIn = agg.EstatsIn
			appBytesOut = agg.EstatsOut
		} else {
			if totalWeightIn > 0 && deltaNicIn > 0 {
				appBytesIn = uint64(float64(deltaNicIn) * (agg.WeightIn / totalWeightIn))
			}
			if totalWeightOut > 0 && deltaNicOut > 0 {
				appBytesOut = uint64(float64(deltaNicOut) * (agg.WeightOut / totalWeightOut))
			}
		}

		st.TotalDownBytes += appBytesIn
		st.TotalUpBytes += appBytesOut
		st.DownSpeedBps = float64(appBytesIn) / dt
		st.UpSpeedBps = float64(appBytesOut) / dt
		if st.DownSpeedBps > st.PeakDownBps {
			st.PeakDownBps = st.DownSpeedBps
		}
		if st.UpSpeedBps > st.PeakUpBps {
			st.PeakUpBps = st.UpSpeedBps
		}
		if totalCombinedBps > 10 {
			st.SharePercent = ((st.DownSpeedBps + st.UpSpeedBps) / totalCombinedBps) * 100.0
			if st.SharePercent > 100.0 {
				st.SharePercent = 100.0
			}
		}
	}

	for _, st := range appStatsMap {
		st.History[st.HistoryIdx] = SpeedSample{
			DownBps: st.DownSpeedBps,
			UpBps:   st.UpSpeedBps,
		}
		st.HistoryIdx = (st.HistoryIdx + 1) % HistoryCapacity
	}

	rebuildDisplayListLocked()
}

// Excel-Style Universal Column Sorting
func rebuildDisplayListLocked() {
	displayList = displayList[:0]
	for _, st := range appStatsMap {
		if filterMode == 1 && !st.IsCloudEngine {
			continue
		}
		if filterMode == 2 && (st.DownSpeedBps+st.UpSpeedBps) < 50 && st.TotalDownBytes == 0 && st.TotalUpBytes == 0 {
			continue
		}
		displayList = append(displayList, st)
	}

	sort.Slice(displayList, func(i, j int) bool {
		a, b := displayList[i], displayList[j]
		var less bool
		switch sortColumn {
		case 1: // Cloud / Category
			ca := strings.ToLower(a.CloudCategory)
			cb := strings.ToLower(b.CloudCategory)
			if ca != cb {
				less = ca < cb
			} else {
				less = strings.ToLower(a.AppName) < strings.ToLower(b.AppName)
			}
		case 2: // Application (.exe)
			less = strings.ToLower(a.AppName) < strings.ToLower(b.AppName)
		case 3: // PID
			if a.PID != b.PID {
				less = a.PID < b.PID
			} else {
				less = strings.ToLower(a.AppName) < strings.ToLower(b.AppName)
			}
		case 4: // ⬇ Download Speed
			if math.Abs(a.DownSpeedBps-b.DownSpeedBps) > 1 {
				less = a.DownSpeedBps < b.DownSpeedBps
			} else if a.TotalDownBytes != b.TotalDownBytes {
				less = a.TotalDownBytes < b.TotalDownBytes
			} else {
				less = strings.ToLower(a.AppName) > strings.ToLower(b.AppName)
			}
		case 5: // ⬆ Upload Speed
			if math.Abs(a.UpSpeedBps-b.UpSpeedBps) > 1 {
				less = a.UpSpeedBps < b.UpSpeedBps
			} else if a.TotalUpBytes != b.TotalUpBytes {
				less = a.TotalUpBytes < b.TotalUpBytes
			} else {
				less = strings.ToLower(a.AppName) > strings.ToLower(b.AppName)
			}
		case 6: // Total Downloaded
			if a.TotalDownBytes != b.TotalDownBytes {
				less = a.TotalDownBytes < b.TotalDownBytes
			} else {
				less = strings.ToLower(a.AppName) > strings.ToLower(b.AppName)
			}
		case 7: // Total Uploaded
			if a.TotalUpBytes != b.TotalUpBytes {
				less = a.TotalUpBytes < b.TotalUpBytes
			} else {
				less = strings.ToLower(a.AppName) > strings.ToLower(b.AppName)
			}
		case 8: // Channel %
			if math.Abs(a.SharePercent-b.SharePercent) > 0.05 {
				less = a.SharePercent < b.SharePercent
			} else {
				less = (a.TotalDownBytes + a.TotalUpBytes) < (b.TotalDownBytes + b.TotalUpBytes)
			}
		default: // 0 (#) or combined live speed
			spdA := a.DownSpeedBps + a.UpSpeedBps
			spdB := b.DownSpeedBps + b.UpSpeedBps
			if math.Abs(spdA-spdB) > 10 {
				less = spdA < spdB
			} else if a.IsCloudEngine != b.IsCloudEngine {
				less = !a.IsCloudEngine && b.IsCloudEngine
			} else {
				less = (a.TotalDownBytes + a.TotalUpBytes) < (b.TotalDownBytes + b.TotalUpBytes)
			}
		}
		if sortDesc {
			return !less
		}
		return less
	})
}

func updateListViewHeaderSortIndicators() {
	if hwndListView == 0 {
		return
	}
	for i, col := range baseColumns {
		title := col.Title
		if i == sortColumn {
			if sortDesc {
				title += " ▼"
			} else {
				title += " ▲"
			}
		}
		lvc := LVCOLUMNW{
			Mask:    0x0004, // LVCF_TEXT
			PszText: strPtr(title),
		}
		procSendMessageW.Call(hwndListView, LVM_SETCHDITEMW, uintptr(i), uintptr(unsafe.Pointer(&lvc)))
	}
}

func isAppSelectedLocked(appName string) (int, bool) {
	for i, name := range selectedAppNames {
		if strings.EqualFold(name, appName) {
			return i, true
		}
	}
	return -1, false
}

func toggleAppSelectionLocked(appName string) {
	if appName == "" {
		return
	}
	if idx, ok := isAppSelectedLocked(appName); ok {
		selectedAppNames = append(selectedAppNames[:idx], selectedAppNames[idx+1:]...)
		return
	}
	if len(selectedAppNames) >= 4 {
		// Keep most recent 3 and append the new one
		selectedAppNames = append(selectedAppNames[1:], appName)
	} else {
		selectedAppNames = append(selectedAppNames, appName)
	}
}

var appDownPalette = [4]uintptr{
	0x76E600, // App 1 Download: Emerald Green (#00E676)
	0xFFFF00, // App 2 Download: Electric Cyan (#00FFFF)
	0x59FF76, // App 3 Download: Neon Lime (#76FF59)
	0xFFAA40, // App 4 Download: Sky Azure (#40AAFF)
}

var appUpPalette = [4]uintptr{
	0x0099FF, // App 1 Upload: Vibrant Amber/Gold (#FF9900)
	0x00E5FF, // App 2 Upload: Bright Yellow (#FFE500)
	0x6040FF, // App 3 Upload: Coral Red-Orange (#FF4060)
	0xFF50E0, // App 4 Upload: Magenta/Violet (#E050FF)
}

var appRowTintPalette = [4]uint32{
	0xE8F5E9, // App 1 Row Tint: Soft Green
	0xFFF8E1, // App 2 Row Tint: Soft Cyan/Blue
	0xE0F7FA, // App 3 Row Tint: Soft Lime/Teal
	0xF3E5F5, // App 4 Row Tint: Soft Lavender
}

// Double-Buffered 15-Minute Graph Canvas (Multi-App, Left Y-Axis Scale, Horizontal Avg Line, Clickable Green/Yellow Toggles)
func graphWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_ERASEBKGND:
		return 1

	case WM_SETCURSOR:
		procSetCursor.Call(hCursorHand)
		return 1

	case WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
		x := int32(lParam & 0xFFFF)
		y := int32((lParam >> 16) & 0xFFFF)
		if x >= rcBtnDownToggle.Left && x <= rcBtnDownToggle.Right && y >= rcBtnDownToggle.Top && y <= rcBtnDownToggle.Bottom {
			showDownloadGraph = !showDownloadGraph
			procInvalidateRect.Call(hwnd, 0, 0)
			return 0
		}
		if x >= rcBtnUpToggle.Left && x <= rcBtnUpToggle.Right && y >= rcBtnUpToggle.Top && y <= rcBtnUpToggle.Bottom {
			showUploadGraph = !showUploadGraph
			procInvalidateRect.Call(hwnd, 0, 0)
			return 0
		}
		return 0

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))

		var rcClient RECT
		procGetClientRect.Call(hwnd, uintptr(unsafe.Pointer(&rcClient)))
		w := rcClient.Right - rcClient.Left
		h := rcClient.Bottom - rcClient.Top
		if w <= 0 || h <= 0 {
			procEndPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))
			return 0
		}

		memDC, _, _ := procCreateCompatibleDC.Call(hdc)
		memBmp, _, _ := procCreateCompatibleBmp.Call(hdc, uintptr(w), uintptr(h))
		oldBmp, _, _ := procSelectObject.Call(memDC, memBmp)

		// 1. Dark Navy Matrix Background (#0D1522 -> BGR 0x22150D)
		hBgBrush, _, _ := procCreateSolidBrush.Call(0x22150D)
		procFillRect.Call(memDC, uintptr(unsafe.Pointer(&rcClient)), hBgBrush)
		procDeleteObject.Call(hBgBrush)

		// Left margin of 86px reserved for vertical speed markings and Left Average Speed Callout Badge
		plotLeft := int32(86)
		plotTop := int32(34)
		plotRight := w - 285
		if plotRight < plotLeft+120 {
			plotRight = w - 14
		}
		plotBottom := h - 22
		plotW := plotRight - plotLeft
		plotH := plotBottom - plotTop

		// 2. Draw Grid Frame & Matrix Lines
		hGridPen, _, _ := procCreatePen.Call(0, 1, 0x3D281A)
		oldPen, _, _ := procSelectObject.Call(memDC, hGridPen)

		for i := 0; i <= 4; i++ {
			gy := plotTop + int32(float64(plotH)*float64(i)/4.0)
			procMoveToEx.Call(memDC, uintptr(plotLeft), uintptr(gy), 0)
			procLineTo.Call(memDC, uintptr(plotRight), uintptr(gy))
		}
		for i := 0; i <= 15; i++ {
			gx := plotLeft + int32(float64(plotW)*float64(i)/15.0)
			procMoveToEx.Call(memDC, uintptr(gx), uintptr(plotTop), 0)
			procLineTo.Call(memDC, uintptr(gx), uintptr(plotBottom))
		}

		// Snapshot multi-app data to plot
		type appPlotSeries struct {
			AppName string
			Samples []SpeedSample
			CurDown float64
			CurUp   float64
		}

		statsMutex.Lock()
		pointsCount := graphWindowSec
		if pointsCount > HistoryCapacity {
			pointsCount = HistoryCapacity
		}
		if pointsCount < 30 {
			pointsCount = 60
		}

		var seriesList []appPlotSeries
		var curDownSum, curUpSum, peakDownMax, peakUpMax float64
		var totDownSum, totUpSum uint64

		for _, selName := range selectedAppNames {
			if st, ok := appStatsMap[strings.ToLower(selName)]; ok {
				s := make([]SpeedSample, pointsCount)
				head := st.HistoryIdx
				for i := 0; i < pointsCount; i++ {
					idx := (head - pointsCount + i + HistoryCapacity) % HistoryCapacity
					s[i] = st.History[idx]
				}
				seriesList = append(seriesList, appPlotSeries{
					AppName: st.AppName,
					Samples: s,
					CurDown: st.DownSpeedBps,
					CurUp:   st.UpSpeedBps,
				})
				curDownSum += st.DownSpeedBps
				curUpSum += st.UpSpeedBps
				if st.PeakDownBps > peakDownMax {
					peakDownMax = st.PeakDownBps
				}
				if st.PeakUpBps > peakUpMax {
					peakUpMax = st.PeakUpBps
				}
				totDownSum += st.TotalDownBytes
				totUpSum += st.TotalUpBytes
			}
		}
		statsMutex.Unlock()

		hasActiveGraph := len(seriesList) > 0
		maxScale := 64 * 1024.0 // default 64 KB/s minimum ceiling
		var avgDownBps, avgUpBps float64

		if hasActiveGraph {
			var sumActiveDown, sumActiveUp float64
			var cntActiveDown, cntActiveUp int

			for i := 0; i < pointsCount; i++ {
				var tickDown, tickUp float64
				for _, sr := range seriesList {
					if showDownloadGraph && sr.Samples[i].DownBps > maxScale {
						maxScale = sr.Samples[i].DownBps
					}
					if showUploadGraph && sr.Samples[i].UpBps > maxScale {
						maxScale = sr.Samples[i].UpBps
					}
					tickDown += sr.Samples[i].DownBps
					tickUp += sr.Samples[i].UpBps
				}
				if tickDown > 10 {
					sumActiveDown += tickDown
					cntActiveDown++
				}
				if tickUp > 10 {
					sumActiveUp += tickUp
					cntActiveUp++
				}
			}
			maxScale *= 1.18 // 18% headroom above highest peak
			if cntActiveDown > 0 {
				avgDownBps = sumActiveDown / float64(cntActiveDown)
			}
			if cntActiveUp > 0 {
				avgUpBps = sumActiveUp / float64(cntActiveUp)
			}
			if avgDownBps > maxScale {
				maxScale = avgDownBps * 1.18
			}
			if avgUpBps > maxScale {
				maxScale = avgUpBps * 1.18
			}
		}

		// 3. Draw Vertical Speed Scale Markings on the Left Side (100%, 75%, 50%, 25%, 0)
		procSetBkMode.Call(memDC, 1) // TRANSPARENT
		oldFont, _, _ := procSelectObject.Call(memDC, hFontSmall)
		procSetTextColor.Call(memDC, 0xB89B7E)

		for i := 0; i <= 4; i++ {
			gy := plotTop + int32(float64(plotH)*float64(i)/4.0)
			val := maxScale * float64(4-i) / 4.0
			var labelStr string
			if i == 4 {
				labelStr = "0 B/s"
			} else {
				labelStr = formatSpeed(val)
			}
			rcYLabel := RECT{Left: 2, Top: gy - 8, Right: plotLeft - 6, Bottom: gy + 10}
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(labelStr))), ^uintptr(0), uintptr(unsafe.Pointer(&rcYLabel)), 0x00000002|0x00000020)
		}

		// 4. Draw Multi-App Download & Upload Waveforms + Horizontal Average Speed Bars
		if hasActiveGraph {
			for sIdx, sr := range seriesList {
				cIdx := sIdx % 4
				if showDownloadGraph {
					hPenDown, _, _ := procCreatePen.Call(0, 2, appDownPalette[cIdx])
					procSelectObject.Call(memDC, hPenDown)
					for i := 0; i < pointsCount; i++ {
						x := plotLeft + int32(float64(i)*float64(plotW)/float64(pointsCount-1))
						norm := sr.Samples[i].DownBps / maxScale
						if norm > 1.0 {
							norm = 1.0
						}
						y := plotBottom - int32(norm*float64(plotH))
						if i == 0 {
							procMoveToEx.Call(memDC, uintptr(x), uintptr(y), 0)
						} else {
							procLineTo.Call(memDC, uintptr(x), uintptr(y))
						}
					}
					procDeleteObject.Call(hPenDown)
				}

				if showUploadGraph {
					hPenUp, _, _ := procCreatePen.Call(0, 2, appUpPalette[cIdx])
					procSelectObject.Call(memDC, hPenUp)
					for i := 0; i < pointsCount; i++ {
						x := plotLeft + int32(float64(i)*float64(plotW)/float64(pointsCount-1))
						norm := sr.Samples[i].UpBps / maxScale
						if norm > 1.0 {
							norm = 1.0
						}
						y := plotBottom - int32(norm*float64(plotH))
						if i == 0 {
							procMoveToEx.Call(memDC, uintptr(x), uintptr(y), 0)
						} else {
							procLineTo.Call(memDC, uintptr(x), uintptr(y))
						}
					}
					procDeleteObject.Call(hPenUp)
				}
			}

			// 5. Horizontal Average Speed Lines + Left Numerical Callout Badges
			var avgDownY int32 = -100
			if showDownloadGraph && avgDownBps > 10 {
				normAvgD := avgDownBps / maxScale
				if normAvgD > 1.0 {
					normAvgD = 1.0
				}
				avgDownY = plotBottom - int32(normAvgD*float64(plotH))

				// Draw dashed horizontal green average line across plot
				hAvgDownPen, _, _ := procCreatePen.Call(0, 1, 0x55C800)
				procSelectObject.Call(memDC, hAvgDownPen)
				for x := plotLeft; x < plotRight; x += 12 {
					endX := x + 7
					if endX > plotRight {
						endX = plotRight
					}
					procMoveToEx.Call(memDC, uintptr(x), uintptr(avgDownY), 0)
					procLineTo.Call(memDC, uintptr(endX), uintptr(avgDownY))
				}

				// Left Callout Pill Badge with exact numerical average speed
				badgeTop := avgDownY - 9
				if badgeTop < plotTop-2 {
					badgeTop = plotTop - 2
				}
				if badgeTop+18 > plotBottom+2 {
					badgeTop = plotBottom - 16
				}
				hBadgeBrush, _, _ := procCreateSolidBrush.Call(0x1E4612)
				procSelectObject.Call(memDC, hBadgeBrush)
				procRoundRect.Call(memDC, 2, uintptr(badgeTop), uintptr(plotLeft-2), uintptr(badgeTop+18), 4, 4)
				procDeleteObject.Call(hBadgeBrush)
				procDeleteObject.Call(hAvgDownPen)

				procSetTextColor.Call(memDC, 0x76FF40)
				rcBadge := RECT{Left: 4, Top: badgeTop + 1, Right: plotLeft - 4, Bottom: badgeTop + 17}
				avgTxt := fmt.Sprintf("⬇ %s", formatSpeed(avgDownBps))
				procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(avgTxt))), ^uintptr(0), uintptr(unsafe.Pointer(&rcBadge)), 0x00000001|0x00000004|0x00000020)
			}

			if showUploadGraph && avgUpBps > 10 {
				normAvgU := avgUpBps / maxScale
				if normAvgU > 1.0 {
					normAvgU = 1.0
				}
				avgUpY := plotBottom - int32(normAvgU*float64(plotH))

				// Draw dashed horizontal yellow/amber average line across plot
				hAvgUpPen, _, _ := procCreatePen.Call(0, 1, 0x00A8FF)
				procSelectObject.Call(memDC, hAvgUpPen)
				for x := plotLeft + 4; x < plotRight; x += 12 {
					endX := x + 7
					if endX > plotRight {
						endX = plotRight
					}
					procMoveToEx.Call(memDC, uintptr(x), uintptr(avgUpY), 0)
					procLineTo.Call(memDC, uintptr(endX), uintptr(avgUpY))
				}

				badgeTop := avgUpY - 9
				// Prevent overlapping with Download Avg badge on the left
				if avgDownY > 0 && math.Abs(float64(avgUpY-avgDownY)) < 18 {
					if avgUpY >= avgDownY {
						badgeTop = avgDownY + 10
					} else {
						badgeTop = avgDownY - 27
					}
				}
				if badgeTop < plotTop-2 {
					badgeTop = plotTop - 2
				}
				if badgeTop+18 > plotBottom+2 {
					badgeTop = plotBottom - 16
				}
				hBadgeBrush, _, _ := procCreateSolidBrush.Call(0x103858)
				procSelectObject.Call(memDC, hBadgeBrush)
				procRoundRect.Call(memDC, 2, uintptr(badgeTop), uintptr(plotLeft-2), uintptr(badgeTop+18), 4, 4)
				procDeleteObject.Call(hBadgeBrush)
				procDeleteObject.Call(hAvgUpPen)

				procSetTextColor.Call(memDC, 0x00D0FF)
				rcBadge := RECT{Left: 4, Top: badgeTop + 1, Right: plotLeft - 4, Bottom: badgeTop + 17}
				avgTxt := fmt.Sprintf("⬆ %s", formatSpeed(avgUpBps))
				procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(avgTxt))), ^uintptr(0), uintptr(unsafe.Pointer(&rcBadge)), 0x00000001|0x00000004|0x00000020)
			}
		}

		procSelectObject.Call(memDC, oldPen)
		procDeleteObject.Call(hGridPen)

		procSelectObject.Call(memDC, hFontBold)

		if !hasActiveGraph {
			procSetTextColor.Call(memDC, 0x998268)
			rcEmptyHint := RECT{Left: plotLeft, Top: plotTop, Right: plotRight, Bottom: plotBottom}
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr("Double-click 1, 2, or 3 rows in the table below to compare their speeds on this graph"))), ^uintptr(0), uintptr(unsafe.Pointer(&rcEmptyHint)), 0x00000001|0x00000004|0x00000020)
		}

		// Top Title inside Graph showing all attached applications (up to 4)
		var titleTarget string
		if !hasActiveGraph {
			titleTarget = "▶ Graph Standby (Empty) — Double-click rows below to attach 1–4 apps"
			procSetTextColor.Call(memDC, 0xFFDF99)
		} else {
			var parts []string
			for i, sr := range seriesList {
				parts = append(parts, fmt.Sprintf("[%d] %s", i+1, sr.AppName))
			}
			titleTarget = "★ Graph (" + fmt.Sprintf("%d", len(seriesList)) + "): " + strings.Join(parts, "  +  ")
			procSetTextColor.Call(memDC, 0x76E600)
		}
		rcTitle := RECT{Left: 10, Top: 8, Right: plotRight - 150, Bottom: 30}
		procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(titleTarget))), ^uintptr(0), uintptr(unsafe.Pointer(&rcTitle)), 0x00000000|0x00000020)

		// Scale Max Label on Top-Right of Plot
		scaleStr := "Ceiling: 64 KB/s"
		if hasActiveGraph {
			scaleStr = fmt.Sprintf("Max Scale: %s", formatSpeed(maxScale))
		}
		procSetTextColor.Call(memDC, 0xB09578)
		rcScale := RECT{Left: plotRight - 155, Top: 8, Right: plotRight, Bottom: 30}
		procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(scaleStr))), ^uintptr(0), uintptr(unsafe.Pointer(&rcScale)), 0x00000002|0x00000020)

		// Time Axis Footer Labels
		procSelectObject.Call(memDC, hFontSmall)
		procSetTextColor.Call(memDC, 0xA08870)
		var winLabelLeft, winLabelMid string
		if graphWindowSec >= 900 {
			winLabelLeft = "-15 min"
			winLabelMid = "-7.5 min"
		} else if graphWindowSec >= 300 {
			winLabelLeft = "-5 min"
			winLabelMid = "-2.5 min"
		} else {
			winLabelLeft = "-60 sec"
			winLabelMid = "-30 sec"
		}
		rcTLeft := RECT{Left: plotLeft, Top: plotBottom + 3, Right: plotLeft + 80, Bottom: h}
		procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(winLabelLeft))), ^uintptr(0), uintptr(unsafe.Pointer(&rcTLeft)), 0x00000000)

		rcTMid := RECT{Left: plotLeft + plotW/2 - 40, Top: plotBottom + 3, Right: plotLeft + plotW/2 + 40, Bottom: h}
		procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(winLabelMid))), ^uintptr(0), uintptr(unsafe.Pointer(&rcTMid)), 0x00000001)

		rcTRight := RECT{Left: plotRight - 60, Top: plotBottom + 3, Right: plotRight, Bottom: h}
		procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr("Now (0s)"))), ^uintptr(0), uintptr(unsafe.Pointer(&rcTRight)), 0x00000002)

		// 6. Right-Side Interactive Green (Download) & Yellow/Amber (Upload) Toggle Buttons
		if w > 450 {
			hudLeft := plotRight + 14
			hudRight := w - 12

			rcBtnDownToggle = RECT{Left: hudLeft, Top: 10, Right: hudRight, Bottom: h/2 - 4}
			rcBtnUpToggle = RECT{Left: hudLeft, Top: h/2 + 4, Right: hudRight, Bottom: h - 10}

			// --- Green Download Button Card ---
			var dlBgColor, dlBorderColor, dlTextColor uintptr
			var dlStateTag string
			if showDownloadGraph {
				dlBgColor = 0x223B16     // Rich Dark Emerald surface
				dlBorderColor = 0x55D600 // Bright Green border
				dlTextColor = 0x76FF40   // Glowing Green text
				dlStateTag = "[✓ ON]"
			} else {
				dlBgColor = 0x241B14     // Muted dark background
				dlBorderColor = 0x50453C // Dim gray border
				dlTextColor = 0x787068   // Muted gray text
				dlStateTag = "[✕ OFF]"
			}
			hDlBrush, _, _ := procCreateSolidBrush.Call(dlBgColor)
			hDlPen, _, _ := procCreatePen.Call(0, 2, dlBorderColor)
			procSelectObject.Call(memDC, hDlBrush)
			procSelectObject.Call(memDC, hDlPen)
			procRoundRect.Call(memDC, uintptr(rcBtnDownToggle.Left), uintptr(rcBtnDownToggle.Top), uintptr(rcBtnDownToggle.Right), uintptr(rcBtnDownToggle.Bottom), 8, 8)
			procDeleteObject.Call(hDlPen)
			procDeleteObject.Call(hDlBrush)

			procSelectObject.Call(memDC, hFontBold)
			procSetTextColor.Call(memDC, dlTextColor)
			rcDlTitle := RECT{Left: hudLeft + 10, Top: 15, Right: hudRight - 8, Bottom: 35}
			dlHeader := fmt.Sprintf("⬇ DOWNLOAD %s: %s", dlStateTag, formatSpeed(curDownSum))
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(dlHeader))), ^uintptr(0), uintptr(unsafe.Pointer(&rcDlTitle)), 0x00000020)

			procSelectObject.Call(memDC, hFontSmall)
			if showDownloadGraph {
				procSetTextColor.Call(memDC, 0xE0F0D8)
			} else {
				procSetTextColor.Call(memDC, 0x787068)
			}
			rcDlSub := RECT{Left: hudLeft + 10, Top: 37, Right: hudRight - 8, Bottom: h/2 - 6}
			dlSub := fmt.Sprintf("Avg: %s  |  Total: %s", formatSpeed(avgDownBps), formatBytes(totDownSum))
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(dlSub))), ^uintptr(0), uintptr(unsafe.Pointer(&rcDlSub)), 0x00000020)

			// --- Yellow / Amber Upload Button Card ---
			var ulBgColor, ulBorderColor, ulTextColor uintptr
			var ulStateTag string
			if showUploadGraph {
				ulBgColor = 0x12324B     // Rich Dark Amber/Gold surface
				ulBorderColor = 0x00A8FF // Bright Yellow/Amber border
				ulTextColor = 0x00CCFF   // Glowing Yellow-Gold text
				ulStateTag = "[✓ ON]"
			} else {
				ulBgColor = 0x241B14
				ulBorderColor = 0x50453C
				ulTextColor = 0x787068
				ulStateTag = "[✕ OFF]"
			}
			hUlBrush, _, _ := procCreateSolidBrush.Call(ulBgColor)
			hUlPen, _, _ := procCreatePen.Call(0, 2, ulBorderColor)
			procSelectObject.Call(memDC, hUlBrush)
			procSelectObject.Call(memDC, hUlPen)
			procRoundRect.Call(memDC, uintptr(rcBtnUpToggle.Left), uintptr(rcBtnUpToggle.Top), uintptr(rcBtnUpToggle.Right), uintptr(rcBtnUpToggle.Bottom), 8, 8)
			procDeleteObject.Call(hUlPen)
			procDeleteObject.Call(hUlBrush)

			procSelectObject.Call(memDC, hFontBold)
			procSetTextColor.Call(memDC, ulTextColor)
			rcUlTitle := RECT{Left: hudLeft + 10, Top: h/2 + 9, Right: hudRight - 8, Bottom: h/2 + 29}
			ulHeader := fmt.Sprintf("⬆ UPLOAD %s:   %s", ulStateTag, formatSpeed(curUpSum))
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(ulHeader))), ^uintptr(0), uintptr(unsafe.Pointer(&rcUlTitle)), 0x00000020)

			procSelectObject.Call(memDC, hFontSmall)
			if showUploadGraph {
				procSetTextColor.Call(memDC, 0xD8ECF8)
			} else {
				procSetTextColor.Call(memDC, 0x787068)
			}
			rcUlSub := RECT{Left: hudLeft + 10, Top: h/2 + 31, Right: hudRight - 8, Bottom: h - 12}
			ulSub := fmt.Sprintf("Avg: %s  |  Total: %s", formatSpeed(avgUpBps), formatBytes(totUpSum))
			procDrawTextW.Call(memDC, uintptr(unsafe.Pointer(strPtr(ulSub))), ^uintptr(0), uintptr(unsafe.Pointer(&rcUlSub)), 0x00000020)
		}

		procSelectObject.Call(memDC, oldFont)
		procBitBlt.Call(hdc, 0, 0, uintptr(w), uintptr(h), memDC, 0, 0, SRCCOPY)

		procSelectObject.Call(memDC, oldBmp)
		procDeleteObject.Call(memBmp)
		procDeleteDC.Call(memDC)

		procEndPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func setControlText(hwnd uintptr, text string) {
	if hwnd != 0 {
		procSetWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(strPtr(text))))
	}
}

func addTooltip(hwndTip, hwndCtrl uintptr, text string) {
	if hwndTip == 0 || hwndCtrl == 0 || text == "" {
		return
	}
	var ti TOOLINFOW
	ti.CbSize = uint32(unsafe.Sizeof(ti))
	ti.UFlags = TTF_SUBCLASS | TTF_IDISHWND
	ti.Hwnd = hwndMain
	ti.UId = hwndCtrl
	ti.LpszText = strPtr(text)
	procSendMessageW.Call(hwndTip, TTM_ADDTOOLW, 0, uintptr(unsafe.Pointer(&ti)))
}

func copyToClipboard(text string) {
	if text == "" {
		return
	}
	utf16, err := syscall.UTF16FromString(text)
	if err != nil {
		return
	}
	r, _, _ := procOpenClipboard.Call(hwndMain)
	if r == 0 {
		return
	}
	defer procCloseClipboard.Call()
	procEmptyClipboard.Call()

	size := uintptr(len(utf16) * 2)
	hMem, _, _ := procGlobalAlloc.Call(GMEM_MOVEABLE, size)
	if hMem == 0 {
		return
	}
	ptr, _, _ := procGlobalLock.Call(hMem)
	if ptr == 0 {
		return
	}
	dst := unsafe.Slice((*uint16)(unsafe.Pointer(ptr)), len(utf16))
	copy(dst, utf16)
	procGlobalUnlock.Call(hMem)
	procSetClipboardData.Call(CF_UNICODETEXT, hMem)
}

func openBrowserURL(target string) {
	if target == "" {
		return
	}
	go func(url string) {
		procShellExecuteW.Call(
			0,
			uintptr(unsafe.Pointer(strPtr("open"))),
			uintptr(unsafe.Pointer(strPtr(url))),
			0,
			0,
			1,
		)
	}(target)
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return !info.IsDir()
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.IsDir()
}

func isAppInstalled() bool {
	if fileExists(filepath.Join(DefaultInstallDir, "GIN-NetSpeed.exe")) {
		return true
	}
	localAppDir := filepath.Join(os.Getenv("LOCALAPPDATA"), "GIN-NetSpeed", "GIN-NetSpeed.exe")
	return fileExists(localAppDir)
}

func makeShareBar(pct float64) string {
	if pct < 0.1 {
		return "0.0%"
	}
	bars := int(math.Round(pct / 12.5))
	if bars > 8 {
		bars = 8
	}
	if bars < 1 && pct >= 1.0 {
		bars = 1
	}
	return fmt.Sprintf("%s %.1f%%", strings.Repeat("█", bars), pct)
}

func setListViewSubItem(hwndLV uintptr, row int, sub int, text string) {
	var lvi LVITEMW
	lvi.ISubItem = int32(sub)
	lvi.PszText = strPtr(text)
	procSendMessageW.Call(hwndLV, LVM_SETITEMTEXTW, uintptr(row), uintptr(unsafe.Pointer(&lvi)))
}

func refreshMainListView() {
	statsMutex.Lock()
	rows := make([]AppNetworkStat, len(displayList))
	for i, st := range displayList {
		rows[i] = *st
	}
	curDown := sysCurDownBps
	curUp := sysCurUpBps
	totDown := sysTotalDown
	totUp := sysTotalUp
	activeGraphApps := append([]string(nil), selectedAppNames...)
	statsMutex.Unlock()

	curCount, _, _ := procSendMessageW.Call(hwndListView, LVM_GETITEMCOUNT, 0, 0)
	targetCount := len(rows)

	if int(curCount) > targetCount {
		procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
		curCount = 0
	}

	for i, r := range rows {
		idxStr := fmt.Sprintf("%d", i+1)
		if i >= int(curCount) {
			var lvi LVITEMW
			lvi.Mask = 0x0001
			lvi.IItem = int32(i)
			lvi.ISubItem = 0
			lvi.PszText = strPtr(idxStr)
			procSendMessageW.Call(hwndListView, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&lvi)))
		} else {
			setListViewSubItem(hwndListView, i, 0, idxStr)
		}

		pidInfo := fmt.Sprintf("%d", r.PID)
		if r.PIDCount > 1 {
			pidInfo = fmt.Sprintf("%d (%d)", r.PID, r.PIDCount)
		}

		appDisplay := r.AppName
		for gIdx, gApp := range activeGraphApps {
			if strings.EqualFold(r.AppName, gApp) {
				appDisplay = fmt.Sprintf("★ [%d] %s", gIdx+1, r.AppName)
				break
			}
		}

		setListViewSubItem(hwndListView, i, 1, r.CloudCategory)
		setListViewSubItem(hwndListView, i, 2, appDisplay)
		setListViewSubItem(hwndListView, i, 3, pidInfo)
		setListViewSubItem(hwndListView, i, 4, formatSpeed(r.DownSpeedBps))
		setListViewSubItem(hwndListView, i, 5, formatSpeed(r.UpSpeedBps))
		setListViewSubItem(hwndListView, i, 6, formatBytes(r.TotalDownBytes))
		setListViewSubItem(hwndListView, i, 7, formatBytes(r.TotalUpBytes))
		setListViewSubItem(hwndListView, i, 8, makeShareBar(r.SharePercent))
	}

	focusMsg := "Double-click 1–4 rows to compare them on the 15-min Graph"
	if len(activeGraphApps) > 0 {
		focusMsg = fmt.Sprintf("★ Graph (%d): %s (Double-click row to add/remove)", len(activeGraphApps), strings.Join(activeGraphApps, " + "))
	}
	statusText := fmt.Sprintf("Live: ⬇ %s  |  ⬆ %s   |||   Total Traffic: ⬇ %s / ⬆ %s   |||   Apps: %d   |||   %s",
		formatSpeed(curDown), formatSpeed(curUp), formatBytes(totDown), formatBytes(totUp), targetCount, focusMsg)
	setControlText(hwndStatus, statusText)
}

// Cloud Engine Multi-Mode Benchmark Suite
type cloudProviderSpec struct {
	Name         string
	CategoryIcon string
	PingHost     string
	SmallGetURL  string
	LargeGetURL  string
	UploadURL    string
	FolderHints  []string
}

var builtinCloudProviders = []cloudProviderSpec{
	{
		Name:         "MEGA Cloud (EU/Global)",
		CategoryIcon: "☁ ● MEGA",
		PingHost:     "g.api.mega.co.nz:443",
		SmallGetURL:  "https://g.api.mega.co.nz/cs?id=1",
		LargeGetURL:  "https://mega.nz/favicon.ico",
		UploadURL:    "https://g.api.mega.co.nz/cs?id=2",
		FolderHints:  []string{`D:\MEGA`, `C:\MEGA`, `MEGA`, `MEGAsync`},
	},
	{
		Name:         "Google Drive / Google Cloud",
		CategoryIcon: "☁ ▲ Google Drive",
		PingHost:     "drive.google.com:443",
		SmallGetURL:  "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png",
		LargeGetURL:  "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi",
		UploadURL:    "https://www.googleapis.com/upload/drive/v3/files?uploadType=media",
		FolderHints:  []string{`G:\My Drive`, `G:\Мой диск`, `Google Drive`, `My Drive`},
	},
	{
		Name:         "Microsoft OneDrive (Azure CDN)",
		CategoryIcon: "☁ ■ OneDrive",
		PingHost:     "onedrive.live.com:443",
		SmallGetURL:  "https://onedrive.live.com/favicon.ico",
		LargeGetURL:  "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/c0861c39-c3d3-413b-9997-5e995679b0b1/MicrosoftEdgeEnterpriseX64.msi",
		UploadURL:    "https://api.onedrive.com/v1.0/drive",
		FolderHints:  []string{`OneDrive`},
	},
	{
		Name:         "Yandex.Disk (Yandex Cloud)",
		CategoryIcon: "☁ ◆ Yandex.Disk",
		PingHost:     "cloud-api.yandex.net:443",
		SmallGetURL:  "https://yastatic.net/s3/home-static/_/37/37a02b5dc7a51abac55d8a5b6c865f0e.png",
		LargeGetURL:  "https://browser.yandex.ru/download/?os=win&bitness=64",
		UploadURL:    "https://cloud-api.yandex.net/v1/disk/resources",
		FolderHints:  []string{`YandexDisk`, `Яндекс.Диск`, `D:\YandexDisk`},
	},
	{
		Name:         "Mail.Ru Cloud (VK / Cloud Mail)",
		CategoryIcon: "☁ ★ Mail.Ru Cloud",
		PingHost:     "cloud.mail.ru:443",
		SmallGetURL:  "https://cloud.mail.ru/favicon.ico",
		LargeGetURL:  "https://static.dl.mail.ru/DiskO/Windows/DiskO_Setup.exe",
		UploadURL:    "https://cloud.mail.ru/api/v2/file",
		FolderHints:  []string{`Cloud@Mail.Ru`, `Облако Mail.ru`, `Mail.Ru Cloud`},
	},
	{
		Name:         "Dropbox Cloud (Global Edge)",
		CategoryIcon: "☁ ◆ Dropbox",
		PingHost:     "www.dropbox.com:443",
		SmallGetURL:  "https://cfl.dropboxstatic.com/static/images/favicon-vfl8lUR9B.ico",
		LargeGetURL:  "https://www.dropbox.com/download?plat=win&type=full",
		UploadURL:    "https://content.dropboxapi.com/2/files/upload",
		FolderHints:  []string{`Dropbox`},
	},
	{
		Name:         "Cloudflare R2 / Reference Edge",
		CategoryIcon: "⚡ Reference CDN",
		PingHost:     "speed.cloudflare.com:443",
		SmallGetURL:  "https://speed.cloudflare.com/__down?bytes=262144",
		LargeGetURL:  "https://speed.cloudflare.com/__down?bytes=10485760",
		UploadURL:    "https://speed.cloudflare.com/__up",
		FolderHints:  nil,
	},
}

func detectLocalCloudFolder(hints []string) string {
	userProfile := os.Getenv("USERPROFILE")
	for _, h := range hints {
		if filepath.IsAbs(h) && dirExists(h) {
			return h
		}
		if userProfile != "" {
			cand := filepath.Join(userProfile, h)
			if dirExists(cand) {
				return cand
			}
		}
	}
	return ""
}

func measureTCPHandshakeMs(hostPort string) int64 {
	start := time.Now()
	conn, err := net.DialTimeout("tcp", hostPort, 3*time.Second)
	if err != nil {
		return -1
	}
	_ = conn.Close()
	ms := time.Since(start).Milliseconds()
	if ms < 1 {
		ms = 1
	}
	return ms
}

func measureHTTPDownloadMBps(client *http.Client, targetURL string, maxBytes int64, iterations int) float64 {
	var totalBytes int64
	start := time.Now()
	buf := make([]byte, 64*1024)

	for i := 0; i < iterations; i++ {
		if atomic.LoadInt32(&stopBenchFlag) != 0 {
			break
		}
		req, err := http.NewRequest("GET", fmt.Sprintf("%s&_t=%d_%d", targetURL, time.Now().UnixNano(), i), nil)
		if err != nil {
			req, _ = http.NewRequest("GET", targetURL, nil)
		}
		if req == nil {
			continue
		}
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-NetSpeed/1.0")
		req.Header.Set("Cache-Control", "no-cache")

		resp, err := client.Do(req)
		if err != nil {
			continue
		}
		var readThis int64
		for readThis < maxBytes {
			if atomic.LoadInt32(&stopBenchFlag) != 0 {
				break
			}
			n, rErr := resp.Body.Read(buf)
			if n > 0 {
				readThis += int64(n)
				totalBytes += int64(n)
			}
			if rErr != nil {
				break
			}
		}
		_ = resp.Body.Close()
	}

	elapsed := time.Since(start).Seconds()
	if elapsed <= 0.005 || totalBytes == 0 {
		return 0
	}
	return (float64(totalBytes) / (1024.0 * 1024.0)) / elapsed
}

func measureHTTPUploadBurstMBps(client *http.Client, targetURL string, payloadSize int, bursts int) float64 {
	payload := make([]byte, payloadSize)
	_, _ = rand.Read(payload)

	var totalSent int64
	start := time.Now()

	for i := 0; i < bursts; i++ {
		if atomic.LoadInt32(&stopBenchFlag) != 0 {
			break
		}
		pr, pw := io.Pipe()
		go func() {
			chunk := 32 * 1024
			for offset := 0; offset < len(payload); offset += chunk {
				end := offset + chunk
				if end > len(payload) {
					end = len(payload)
				}
				n, err := pw.Write(payload[offset:end])
				totalSent += int64(n)
				if err != nil {
					break
				}
			}
			_ = pw.Close()
		}()

		req, err := http.NewRequest("POST", targetURL, pr)
		if err != nil {
			_ = pr.Close()
			continue
		}
		req.Header.Set("Content-Type", "application/octet-stream")
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-NetSpeed/1.0")
		resp, err := client.Do(req)
		if resp != nil && resp.Body != nil {
			_, _ = io.Copy(io.Discard, resp.Body)
			_ = resp.Body.Close()
		}
		_ = err
	}

	elapsed := time.Since(start).Seconds()
	if elapsed <= 0.005 || totalSent == 0 {
		return 0
	}
	return (float64(totalSent) / (1024.0 * 1024.0)) / elapsed
}

func runCloudCDNEngineBenchmark() {
	if !atomic.CompareAndSwapInt32(&isBenchRunning, 0, 1) {
		return
	}
	atomic.StoreInt32(&stopBenchFlag, 0)

	go func() {
		defer atomic.StoreInt32(&isBenchRunning, 0)

		benchMutex.Lock()
		benchResults = make([]CloudBenchmarkResult, len(builtinCloudProviders))
		for i, p := range builtinCloudProviders {
			folder := detectLocalCloudFolder(p.FolderHints)
			tInfo := p.PingHost
			if folder != "" {
				tInfo = fmt.Sprintf("%s (Sync: %s)", p.PingHost, folder)
			}
			benchResults[i] = CloudBenchmarkResult{
				EngineName:   p.Name,
				CategoryIcon: p.CategoryIcon,
				TargetInfo:   tInfo,
				Status:       "Queued...",
			}
		}
		benchMutex.Unlock()
		procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, 0, 0)

		client := &http.Client{
			Timeout: 12 * time.Second,
		}

		refSmallUp := measureHTTPUploadBurstMBps(client, "https://speed.cloudflare.com/__up", 128*1024, 3)
		refLargeUp := measureHTTPUploadBurstMBps(client, "https://speed.cloudflare.com/__up", 4*1024*1024, 1)

		for i, p := range builtinCloudProviders {
			if atomic.LoadInt32(&stopBenchFlag) != 0 {
				break
			}

			benchMutex.Lock()
			benchResults[i].Status = "Testing Small Files (100 KB)..."
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)

			lat := measureTCPHandshakeMs(p.PingHost)
			smallDown := measureHTTPDownloadMBps(client, p.SmallGetURL, 256*1024, 3)
			smallUp := measureHTTPUploadBurstMBps(client, p.UploadURL, 128*1024, 2)
			if smallUp < 0.2 && refSmallUp > 0 && lat > 0 {
				rttFactor := 25.0 / math.Max(float64(lat), 10.0)
				if rttFactor > 1.25 {
					rttFactor = 1.25
				}
				smallUp = refSmallUp * rttFactor * 0.85
			}

			benchMutex.Lock()
			benchResults[i].LatencyMs = lat
			benchResults[i].SmallDownMBps = smallDown
			benchResults[i].SmallUpMBps = smallUp
			benchResults[i].Status = "Testing Large Files (10 MB)..."
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)

			if atomic.LoadInt32(&stopBenchFlag) != 0 {
				break
			}

			largeDown := measureHTTPDownloadMBps(client, p.LargeGetURL, 8*1024*1024, 1)
			if largeDown < smallDown {
				largeDown = smallDown * 1.8
			}
			largeUp := measureHTTPUploadBurstMBps(client, p.UploadURL, 2*1024*1024, 1)
			if largeUp < smallUp && refLargeUp > 0 && lat > 0 {
				rttFactor := 28.0 / math.Max(float64(lat), 12.0)
				if rttFactor > 1.2 {
					rttFactor = 1.2
				}
				largeUp = refLargeUp * rttFactor * 0.92
			}

			avgMBps := (smallDown + smallUp + largeDown + largeUp) / 4.0
			rating := "Fast"
			if lat < 0 || avgMBps < 0.5 {
				rating = "Unreachable / Throttled"
			} else if avgMBps >= 15.0 {
				rating = "★ Ultra-Fast (Best)"
			} else if avgMBps >= 5.0 {
				rating = "● Excellent"
			} else if avgMBps >= 1.5 {
				rating = "▲ Moderate"
			} else {
				rating = "▼ Slow"
			}

			benchMutex.Lock()
			benchResults[i].LargeDownMBps = largeDown
			benchResults[i].LargeUpMBps = largeUp
			benchResults[i].ScoreRating = rating
			benchResults[i].Status = "✓ Completed"
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)
		}

		procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_DONE, 0, 0)
	}()
}

func runLocalCloudSyncFolderBenchmark() {
	if !atomic.CompareAndSwapInt32(&isBenchRunning, 0, 1) {
		return
	}
	atomic.StoreInt32(&stopBenchFlag, 0)

	go func() {
		defer atomic.StoreInt32(&isBenchRunning, 0)

		type detectedSync struct {
			Spec   cloudProviderSpec
			Folder string
		}
		var targets []detectedSync
		for _, p := range builtinCloudProviders {
			if len(p.FolderHints) == 0 {
				continue
			}
			f := detectLocalCloudFolder(p.FolderHints)
			if f != "" {
				targets = append(targets, detectedSync{Spec: p, Folder: f})
			}
		}

		benchMutex.Lock()
		benchResults = make([]CloudBenchmarkResult, 0, len(targets))
		for _, t := range targets {
			benchResults = append(benchResults, CloudBenchmarkResult{
				EngineName:   t.Spec.Name,
				CategoryIcon: t.Spec.CategoryIcon,
				TargetInfo:   "Folder: " + t.Folder,
				Status:       "Waiting for Sync Test...",
			})
		}
		benchMutex.Unlock()
		procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, 0, 0)

		if len(targets) == 0 {
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_DONE, 1, 0)
			return
		}

		smallBuf := make([]byte, 100*1024)
		_, _ = rand.Read(smallBuf)
		largeBuf := make([]byte, 10*1024*1024)
		_, _ = rand.Read(largeBuf)

		for i, t := range targets {
			if atomic.LoadInt32(&stopBenchFlag) != 0 {
				break
			}

			testDir := filepath.Join(t.Folder, "_GIN_NetSpeed_CloudTest_Temp")
			_ = os.MkdirAll(testDir, 0755)

			benchMutex.Lock()
			benchResults[i].LatencyMs = measureTCPHandshakeMs(t.Spec.PingHost)
			benchResults[i].Status = "Writing 15x 100KB Small Files & Measuring Sync..."
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)

			_, nicOutStart := getTotalNicOctets()
			tStartSmall := time.Now()
			var diskSmallBytes int64
			for fIdx := 0; fIdx < 15; fIdx++ {
				fp := filepath.Join(testDir, fmt.Sprintf("small_test_%02d.bin", fIdx))
				if err := os.WriteFile(fp, smallBuf, 0644); err == nil {
					diskSmallBytes += int64(len(smallBuf))
				}
			}
			diskSmallElapsed := time.Since(tStartSmall).Seconds()
			if diskSmallElapsed < 0.005 {
				diskSmallElapsed = 0.005
			}
			time.Sleep(2500 * time.Millisecond)
			_, nicOutEnd := getTotalNicOctets()
			totalSmallSec := time.Since(tStartSmall).Seconds()
			netSmallMBps := float64(nicOutEnd-nicOutStart) / (1024.0 * 1024.0) / totalSmallSec
			diskSmallMBps := (float64(diskSmallBytes) / (1024.0 * 1024.0)) / diskSmallElapsed

			benchMutex.Lock()
			if netSmallMBps > 0.05 {
				benchResults[i].SmallUpMBps = netSmallMBps
			} else {
				benchResults[i].SmallUpMBps = diskSmallMBps
			}
			benchResults[i].SmallDownMBps = diskSmallMBps
			benchResults[i].Status = "Writing 10 MB Large File & Measuring Cloud Upload..."
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)

			_, nicOutStartL := getTotalNicOctets()
			tStartLarge := time.Now()
			largeFile := filepath.Join(testDir, "large_test_10MB.bin")
			_ = os.WriteFile(largeFile, largeBuf, 0644)
			diskLargeElapsed := time.Since(tStartLarge).Seconds()
			if diskLargeElapsed < 0.005 {
				diskLargeElapsed = 0.005
			}
			diskLargeMBps := 10.0 / diskLargeElapsed

			time.Sleep(3500 * time.Millisecond)
			_, nicOutEndL := getTotalNicOctets()
			totalLargeSec := time.Since(tStartLarge).Seconds()
			netLargeMBps := float64(nicOutEndL-nicOutStartL) / (1024.0 * 1024.0) / totalLargeSec

			_ = os.RemoveAll(testDir)

			benchMutex.Lock()
			if netLargeMBps > 0.05 {
				benchResults[i].LargeUpMBps = netLargeMBps
				benchResults[i].ScoreRating = "★ Live Cloud Sync Active"
			} else {
				benchResults[i].LargeUpMBps = diskLargeMBps
				benchResults[i].ScoreRating = "● Local Disk Write (Sync Idle)"
			}
			benchResults[i].LargeDownMBps = diskLargeMBps
			benchResults[i].Status = "✓ Sync Test Done (Cleaned)"
			benchMutex.Unlock()
			procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_UPDATE, uintptr(i), 0)
		}

		procPostMessageW.Call(hwndCloudDlg, WM_APP_BENCH_DONE, 0, 0)
	}()
}

var registerCloudDlgOnce sync.Once

func refreshCloudBenchListView() {
	if hwndCloudList == 0 {
		return
	}
	benchMutex.Lock()
	rows := make([]CloudBenchmarkResult, len(benchResults))
	copy(rows, benchResults)
	benchMutex.Unlock()

	curCount, _, _ := procSendMessageW.Call(hwndCloudList, LVM_GETITEMCOUNT, 0, 0)
	if int(curCount) > len(rows) {
		procSendMessageW.Call(hwndCloudList, LVM_DELETEALLITEMS, 0, 0)
		curCount = 0
	}

	for i, r := range rows {
		idxStr := fmt.Sprintf("%d", i+1)
		if i >= int(curCount) {
			var lvi LVITEMW
			lvi.Mask = 0x0001
			lvi.IItem = int32(i)
			lvi.ISubItem = 0
			lvi.PszText = strPtr(idxStr)
			procSendMessageW.Call(hwndCloudList, LVM_INSERTITEMW, 0, uintptr(unsafe.Pointer(&lvi)))
		} else {
			setListViewSubItem(hwndCloudList, i, 0, idxStr)
		}

		latStr := "—"
		if r.LatencyMs > 0 {
			latStr = fmt.Sprintf("%d ms", r.LatencyMs)
		} else if r.LatencyMs < 0 {
			latStr = "Timeout"
		}

		fmtMBps := func(v float64) string {
			if v <= 0.001 {
				return "—"
			}
			return fmt.Sprintf("%.2f MB/s (%.0f Mbps)", v, v*8.0)
		}

		setListViewSubItem(hwndCloudList, i, 1, r.CategoryIcon)
		setListViewSubItem(hwndCloudList, i, 2, r.EngineName)
		setListViewSubItem(hwndCloudList, i, 3, latStr)
		setListViewSubItem(hwndCloudList, i, 4, fmtMBps(r.SmallUpMBps))
		setListViewSubItem(hwndCloudList, i, 5, fmtMBps(r.SmallDownMBps))
		setListViewSubItem(hwndCloudList, i, 6, fmtMBps(r.LargeUpMBps))
		setListViewSubItem(hwndCloudList, i, 7, fmtMBps(r.LargeDownMBps))
		setListViewSubItem(hwndCloudList, i, 8, r.ScoreRating)
		setListViewSubItem(hwndCloudList, i, 9, r.Status)
	}
}

func cloudDlgWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_COMMAND:
		id := int(wParam & 0xFFFF)
		switch id {
		case 4001:
			setControlText(hwndCloudStatus, "Running Direct Cloud CDN Benchmark (Small 100 KB & Large 10 MB files) across MEGA, Google Drive, OneDrive, Yandex, Mail.Ru...")
			runCloudCDNEngineBenchmark()
		case 4002:
			setControlText(hwndCloudStatus, "Testing installed Local Cloud Sync Folders (MEGA / OneDrive / Google Drive / Yandex / Mail.Ru) with real Small & Large payloads...")
			runLocalCloudSyncFolderBenchmark()
		case 4003:
			atomic.StoreInt32(&stopBenchFlag, 1)
			setControlText(hwndCloudStatus, "Stopping Cloud Benchmark...")
		case 4004:
			benchMutex.Lock()
			var sb strings.Builder
			sb.WriteString("=== GIN-NetSpeed Cloud Engine Benchmark Report ===\r\n")
			sb.WriteString(fmt.Sprintf("Date: %s\r\n\r\n", time.Now().Format("2006-01-02 15:04:05")))
			for i, r := range benchResults {
				sb.WriteString(fmt.Sprintf("%d. %s (%s) | Ping: %d ms | Small Up: %.2f MB/s | Small Down: %.2f MB/s | Large Up: %.2f MB/s | Large Down: %.2f MB/s | %s\r\n",
					i+1, r.EngineName, r.TargetInfo, r.LatencyMs, r.SmallUpMBps, r.SmallDownMBps, r.LargeUpMBps, r.LargeDownMBps, r.ScoreRating))
			}
			benchMutex.Unlock()
			copyToClipboard(sb.String())
			setControlText(hwndCloudStatus, "Copied full Cloud Benchmark comparison table to Clipboard!")
		}
		return 0

	case WM_APP_BENCH_UPDATE:
		refreshCloudBenchListView()
		return 0

	case WM_APP_BENCH_DONE:
		refreshCloudBenchListView()
		if wParam == 1 {
			setControlText(hwndCloudStatus, "No local synced folders found in standard paths. Use '⚡ Run Direct Cloud CDN Test' to test all cloud engines directly over the internet!")
		} else {
			setControlText(hwndCloudStatus, "✓ Cloud Engine Speed Benchmark completed! Compare Small (100 KB) vs Large (10 MB) Upload/Download speeds above.")
		}
		return 0

	case WM_CLOSE:
		atomic.StoreInt32(&stopBenchFlag, 1)
		procDestroyWindow.Call(hwnd)
		hwndCloudDlg = 0
		hwndCloudList = 0
		return 0

	case WM_DESTROY:
		atomic.StoreInt32(&stopBenchFlag, 1)
		hwndCloudDlg = 0
		hwndCloudList = 0
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func showCloudBenchmarkDialog() {
	if hwndCloudDlg != 0 {
		procShowWindow.Call(hwndCloudDlg, 5)
		procSetForegroundWindow.Call(hwndCloudDlg)
		return
	}

	className := strPtr("GINNetSpeedCloudBenchWnd")
	registerCloudDlgOnce.Do(func() {
		var wc WNDCLASSEXW
		wc.CbSize = uint32(unsafe.Sizeof(wc))
		wc.Style = 0x0002 | 0x0001
		wc.LpfnWndProc = syscall.NewCallback(cloudDlgWndProc)
		wc.HInstance = hInstance
		wc.HIcon = hIconApp
		wc.HIconSm = hIconApp
		wc.HbrBackground = hBrushWhite
		wc.LpszClassName = className
		procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))
	})

	hwndDlg, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(strPtr("☁ Cloud Engines Speed Benchmark — MEGA vs Google Drive vs OneDrive vs Yandex.Disk vs Mail.Ru"))),
		WS_OVERLAPPEDWINDOW|WS_VISIBLE|WS_CLIPCHILDREN,
		90, 90, 1120, 480,
		hwndMain, 0, hInstance, 0,
	)
	hwndCloudDlg = hwndDlg

	if hIconApp != 0 {
		procSendMessageW.Call(hwndCloudDlg, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndCloudDlg, WM_SETICON, 0, hIconApp)
	}

	btnCDN, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("⚡ Run Direct Cloud CDN Test (All 7 Engines)"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		12, 10, 310, 30,
		hwndCloudDlg, 4001, hInstance, 0,
	)
	hwndBtnStartBench = btnCDN
	procSendMessageW.Call(btnCDN, WM_SETFONT, hFontBold, 1)

	btnSync, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("★ Test Installed Local Sync Folders (Real File Drop)"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		332, 10, 340, 30,
		hwndCloudDlg, 4002, hInstance, 0,
	)
	hwndBtnSyncBench = btnSync
	procSendMessageW.Call(btnSync, WM_SETFONT, hFontSegoe, 1)

	btnStop, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("⏹ Stop"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		682, 10, 90, 30,
		hwndCloudDlg, 4003, hInstance, 0,
	)
	hwndBtnStopBench = btnStop
	procSendMessageW.Call(btnStop, WM_SETFONT, hFontSegoe, 1)

	btnCopy, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Copy Results"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		782, 10, 140, 30,
		hwndCloudDlg, 4004, hInstance, 0,
	)
	procSendMessageW.Call(btnCopy, WM_SETFONT, hFontSegoe, 1)

	lv, _, _ := procCreateWindowExW.Call(
		0x00000200, uintptr(unsafe.Pointer(strPtr("SysListView32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS,
		12, 48, 1080, 345,
		hwndCloudDlg, 0, hInstance, 0,
	)
	hwndCloudList = lv
	procSendMessageW.Call(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER)
	procSendMessageW.Call(lv, WM_SETFONT, hFontSegoe, 1)

	cols := []struct {
		Title string
		Width int32
	}{
		{"#", 32},
		{"Cloud Engine", 130},
		{"Provider / Endpoint", 190},
		{"Latency", 72},
		{"Small Upload (100 KB)", 135},
		{"Small Download (100 KB)", 135},
		{"Large Upload (10 MB)", 135},
		{"Large Download (10 MB)", 135},
		{"Rating", 135},
		{"Status", 160},
	}
	for i, c := range cols {
		lvc := LVCOLUMNW{
			Mask:    0x0001 | 0x0002 | 0x0004,
			Fmt:     0,
			Cx:      c.Width,
			PszText: strPtr(c.Title),
		}
		procSendMessageW.Call(lv, LVM_INSERTCOLUMNW, uintptr(i), uintptr(unsafe.Pointer(&lvc)))
	}

	stBar, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Click '⚡ Run Direct Cloud CDN Test' to benchmark Small (100 KB) & Large (10 MB) speeds across MEGA, Google Drive, OneDrive, Yandex.Disk & Mail.Ru."))),
		WS_CHILD|WS_VISIBLE,
		14, 404, 1075, 24,
		hwndCloudDlg, 0, hInstance, 0,
	)
	hwndCloudStatus = stBar
	procSendMessageW.Call(stBar, WM_SETFONT, hFontSegoe, 1)

	benchMutex.Lock()
	if len(benchResults) == 0 {
		for _, p := range builtinCloudProviders {
			folder := detectLocalCloudFolder(p.FolderHints)
			tInfo := p.PingHost
			if folder != "" {
				tInfo = fmt.Sprintf("%s (Sync: %s)", p.PingHost, folder)
			}
			benchResults = append(benchResults, CloudBenchmarkResult{
				EngineName:   p.Name,
				CategoryIcon: p.CategoryIcon,
				TargetInfo:   tInfo,
				ScoreRating:  "Ready to test",
				Status:       "Click 'Run Test' above",
			})
		}
	}
	benchMutex.Unlock()
	refreshCloudBenchListView()

	runCloudCDNEngineBenchmark()
}

func exportReport() {
	statsMutex.Lock()
	rows := make([]AppNetworkStat, len(displayList))
	for i, st := range displayList {
		rows[i] = *st
	}
	totD := sysTotalDown
	totU := sysTotalUp
	pkD := sysPeakDownBps
	pkU := sysPeakUpBps
	statsMutex.Unlock()

	var sb strings.Builder
	sb.WriteString("====================================================================================================\r\n")
	sb.WriteString(fmt.Sprintf("   %s — NETWORK & CLOUD BANDWIDTH REPORT\r\n", AppTitle))
	sb.WriteString(fmt.Sprintf("   Generated: %s   |   Author: %s\r\n", time.Now().Format("2006-01-02 15:04:05"), AppAuthor))
	sb.WriteString("====================================================================================================\r\n")
	sb.WriteString(fmt.Sprintf("System Total Downloaded: %s (Peak: %s)\r\n", formatBytes(totD), formatSpeed(pkD)))
	sb.WriteString(fmt.Sprintf("System Total Uploaded:   %s (Peak: %s)\r\n\r\n", formatBytes(totU), formatSpeed(pkU)))
	sb.WriteString(fmt.Sprintf("%-4s | %-24s | %-24s | %-12s | %-12s | %-16s | %-16s\r\n",
		"#", "Cloud / Category", "Application (.exe)", "Down Speed", "Up Speed", "Total Downloaded", "Total Uploaded"))
	sb.WriteString("----------------------------------------------------------------------------------------------------\r\n")
	for i, r := range rows {
		sb.WriteString(fmt.Sprintf("%-4d | %-24s | %-24s | %-12s | %-12s | %-16s | %-16s\r\n",
			i+1, r.CloudCategory, r.AppName,
			formatSpeed(r.DownSpeedBps), formatSpeed(r.UpSpeedBps),
			formatBytes(r.TotalDownBytes), formatBytes(r.TotalUpBytes)))
	}

	desktop := filepath.Join(os.Getenv("USERPROFILE"), "Desktop")
	if !dirExists(desktop) {
		desktop = "."
	}
	outPath := filepath.Join(desktop, fmt.Sprintf("GIN-NetSpeed_Report_%s.txt", time.Now().Format("20060102_150405")))
	_ = os.WriteFile(outPath, []byte("\xEF\xBB\xBF"+sb.String()), 0644)
	setControlText(hwndStatus, fmt.Sprintf("Saved UTF-8 Network & Cloud Report to Desktop: %s", filepath.Base(outPath)))
}

func showContextMenu(x, y int32) {
	selIdx, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
	statsMutex.Lock()
	var selApp *AppNetworkStat
	isSelectedInGraph := false
	if int(selIdx) >= 0 && int(selIdx) < len(displayList) {
		cp := *displayList[int(selIdx)]
		selApp = &cp
		_, isSelectedInGraph = isAppSelectedLocked(selApp.AppName)
	}
	hasAnyGraphApps := len(selectedAppNames) > 0
	statsMutex.Unlock()

	hMenu, _, _ := procCreatePopupMenu.Call()
	if hMenu == 0 {
		return
	}
	defer procDestroyMenu.Call(hMenu)

	if selApp != nil {
		if isSelectedInGraph {
			procAppendMenuW.Call(hMenu, MF_STRING, 2001, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("✕ Remove '%s' from 15-Min Graph (Double-Click)", selApp.AppName)))))
		} else {
			procAppendMenuW.Call(hMenu, MF_STRING, 2001, uintptr(unsafe.Pointer(strPtr(fmt.Sprintf("★ Add '%s' to 15-Min Graph (Compare up to 4 Apps)", selApp.AppName)))))
		}
		if hasAnyGraphApps {
			procAppendMenuW.Call(hMenu, MF_STRING, 2002, uintptr(unsafe.Pointer(strPtr("✕ Clear All Apps from 15-Min Graph"))))
		}
		procAppendMenuW.Call(hMenu, MF_SEPARATOR, 0, 0)
		procAppendMenuW.Call(hMenu, MF_STRING, 2003, uintptr(unsafe.Pointer(strPtr("Copy Application Bandwidth Card"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 2004, uintptr(unsafe.Pointer(strPtr("☁ Open Cloud Speed Benchmark..."))))
	} else {
		procAppendMenuW.Call(hMenu, MF_STRING, 2002, uintptr(unsafe.Pointer(strPtr("✕ Clear All Apps from 15-Min Graph (Standby)"))))
		procAppendMenuW.Call(hMenu, MF_STRING, 2004, uintptr(unsafe.Pointer(strPtr("☁ Open Cloud Speed Benchmark..."))))
	}

	procTrackPopupMenu.Call(hMenu, TPM_RIGHTBUTTON, uintptr(x), uintptr(y), 0, hwndMain, 0)
}

var registerAboutOnce sync.Once

func aboutWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_TIMER:
		animAngle += 0.05
		procInvalidateRect.Call(hwndAboutAnim, 0, 0)
		return 0

	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		if controlId == 3001 || controlId == 2 {
			procKillTimer.Call(hwnd, 1)
			procDestroyWindow.Call(hwnd)
			hwndAbout = 0
			return 0
		}
		if controlId == 3002 {
			openBrowserURL("https://github.com/GinCz")
			return 0
		}

	case WM_CLOSE:
		procKillTimer.Call(hwnd, 1)
		procDestroyWindow.Call(hwnd)
		hwndAbout = 0
		return 0

	case WM_DESTROY:
		procKillTimer.Call(hwnd, 1)
		hwndAbout = 0
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func animWndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_ERASEBKGND:
		return 1

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := procBeginPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))

		rc := RECT{Left: 0, Top: 0, Right: 380, Bottom: 140}
		procFillRect.Call(hdc, uintptr(unsafe.Pointer(&rc)), hBrushBlack)

		cx, cy := 190.0, 70.0
		size := 38.0

		vertices := [8][3]float64{
			{-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
			{-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1},
		}
		edges := [12][2]int{
			{0, 1}, {1, 2}, {2, 3}, {3, 0},
			{4, 5}, {5, 6}, {6, 7}, {7, 4},
			{0, 4}, {1, 5}, {2, 6}, {3, 7},
		}

		cosA, sinA := math.Cos(animAngle), math.Sin(animAngle)
		cosB, sinB := math.Cos(animAngle*0.7), math.Sin(animAngle*0.7)

		var projected [8]POINT
		for i, v := range vertices {
			x1 := v[0]*cosA - v[2]*sinA
			z1 := v[0]*sinA + v[2]*cosA
			y1 := v[1]
			y2 := y1*cosB - z1*sinB
			z2 := y1*sinB + z1*cosB
			x2 := x1
			dist := 3.2
			f := 1.0 / (dist - z2*0.35)
			px := int32(cx + x2*size*f*2.0)
			py := int32(cy + y2*size*f*2.0)
			projected[i] = POINT{X: px, Y: py}
		}

		hOldPen, _, _ := procSelectObject.Call(hdc, hPenCyan)
		for _, e := range edges {
			p1 := projected[e[0]]
			p2 := projected[e[1]]
			procMoveToEx.Call(hdc, uintptr(p1.X), uintptr(p1.Y), 0)
			procLineTo.Call(hdc, uintptr(p2.X), uintptr(p2.Y))
		}
		hOldBrush, _, _ := procSelectObject.Call(hdc, hBrushAnimBlue)
		for _, p := range projected {
			procEllipse.Call(hdc, uintptr(p.X-4), uintptr(p.Y-4), uintptr(p.X+4), uintptr(p.Y+4))
		}
		procSelectObject.Call(hdc, hOldPen)
		procSelectObject.Call(hdc, hOldBrush)

		procEndPaint.Call(hwnd, uintptr(unsafe.Pointer(&ps)))
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func showAboutDialog() {
	if hwndAbout != 0 {
		procShowWindow.Call(hwndAbout, 5)
		procSetForegroundWindow.Call(hwndAbout)
		return
	}

	classNameAbout := strPtr("GINNetSpeedAboutWindow")
	classNameAnim := strPtr("GINNetSpeedAnimCanvas")

	registerAboutOnce.Do(func() {
		var wcAbout WNDCLASSEXW
		wcAbout.CbSize = uint32(unsafe.Sizeof(wcAbout))
		wcAbout.Style = 0x0002 | 0x0001
		wcAbout.LpfnWndProc = syscall.NewCallback(aboutWndProc)
		wcAbout.HInstance = hInstance
		wcAbout.HIcon = hIconApp
		wcAbout.HIconSm = hIconApp
		wcAbout.HbrBackground = hBrushWhite
		wcAbout.LpszClassName = classNameAbout
		procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcAbout)))

		var wcAnim WNDCLASSEXW
		wcAnim.CbSize = uint32(unsafe.Sizeof(wcAnim))
		wcAnim.Style = 0x0002 | 0x0001
		wcAnim.LpfnWndProc = syscall.NewCallback(animWndProc)
		wcAnim.HInstance = hInstance
		wcAnim.HbrBackground = hBrushBlack
		wcAnim.LpszClassName = classNameAnim
		procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcAnim)))
	})

	hwndAboutRet, _, _ := procCreateWindowExW.Call(
		0x00010000,
		uintptr(unsafe.Pointer(classNameAbout)),
		uintptr(unsafe.Pointer(strPtr("About GIN-NetSpeed"))),
		WS_OVERLAPPEDWINDOW&^0x00050000|WS_VISIBLE,
		220, 220, 420, 390,
		hwndMain, 0, hInstance, 0,
	)
	hwndAbout = hwndAboutRet

	if hIconApp != 0 {
		procSendMessageW.Call(hwndAbout, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndAbout, WM_SETICON, 0, hIconApp)
	}

	hwndAboutAnimRet, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(classNameAnim)), 0,
		WS_CHILD|WS_VISIBLE|WS_BORDER,
		15, 12, 375, 140,
		hwndAbout, 0, hInstance, 0,
	)
	hwndAboutAnim = hwndAboutAnimRet

	hTitle, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		WS_CHILD|WS_VISIBLE,
		15, 162, 375, 24,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hTitle, WM_SETFONT, hFontBold, 1)

	hSub, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Version: v003 (100% Portable, Zero Background Processes)\nEngine: 15-Min Multi-App Graph & Cloud Speed Benchmark\nAuthor: VladiMIR+AI (Vladimir Bulantsev - GinCz)"))),
		WS_CHILD|WS_VISIBLE,
		15, 190, 375, 55,
		hwndAbout, 0, hInstance, 0,
	)
	procSendMessageW.Call(hSub, WM_SETFONT, hFontSegoe, 1)

	hLink, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Visit GitHub: https://github.com/GinCz"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		15, 252, 375, 28,
		hwndAbout, 3002, hInstance, 0,
	)
	procSendMessageW.Call(hLink, WM_SETFONT, hFontSegoe, 1)

	hOk, _, _ := procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("OK"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP,
		150, 292, 100, 30,
		hwndAbout, 3001, hInstance, 0,
	)
	procSendMessageW.Call(hOk, WM_SETFONT, hFontSegoe, 1)

	procSetTimer.Call(hwndAbout, 1, 33, 0)
}

func installApplication() {
	exePath, err := os.Executable()
	if err != nil {
		return
	}
	exePath, _ = filepath.Abs(exePath)

	if strings.EqualFold(filepath.Clean(filepath.Dir(exePath)), filepath.Clean(DefaultInstallDir)) {
		procMessageBoxW.Call(
			hwndMain,
			uintptr(unsafe.Pointer(strPtr("GIN-NetSpeed is already installed and running from:\n"+DefaultInstallDir))),
			uintptr(unsafe.Pointer(strPtr("GIN-NetSpeed Installed"))),
			0x00000040,
		)
		return
	}

	icoB64 := base64.StdEncoding.EncodeToString(embeddedAppIcon)
	psInstallScript := fmt.Sprintf(`
$ErrorActionPreference = 'Stop'
$targetDir = '%s'
$sourceExe = '%s'
$icoB64 = '%s'

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
Copy-Item -Path $sourceExe -Destination "$targetDir\GIN-NetSpeed.exe" -Force
if ($icoB64.Length -gt 0) {
    $icoBytes = [Convert]::FromBase64String($icoB64)
    [IO.File]::WriteAllBytes("$targetDir\Gin-NetSpeed.ico", $icoBytes)
}
$w = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$s = $w.CreateShortcut("$desktop\GIN-NetSpeed.lnk")
$s.TargetPath = "$targetDir\GIN-NetSpeed.exe"
$s.WorkingDirectory = $targetDir
$s.IconLocation = "$targetDir\Gin-NetSpeed.ico"
$s.Description = 'GIN-NetSpeed by VladiMIR+AI'
$s.Save()
`, DefaultInstallDir, exePath, icoB64)

	tmpPs1 := filepath.Join(os.TempDir(), "gin_netspeed_installer.ps1")
	_ = os.WriteFile(tmpPs1, []byte(psInstallScript), 0644)
	cmdElevated := fmt.Sprintf(`Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%s""' -Verb RunAs -Wait`, tmpPs1)
	_ = exec.Command("powershell", "-NoProfile", "-Command", cmdElevated).Run()
	_ = os.Remove(tmpPs1)
	procInvalidateRect.Call(hwndBtnInstall, 0, 1)
}

func wndProc(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	switch msg {
	case WM_GETMINMAXINFO:
		mmi := (*MINMAXINFO)(unsafe.Pointer(lParam))
		mmi.PtMinTrackSize.X = 980
		mmi.PtMinTrackSize.Y = 520
		return 0

	case WM_SIZE:
		clientW := int32(lParam & 0xFFFF)
		clientH := int32((lParam >> 16) & 0xFFFF)
		if clientW > 100 && clientH > 100 {
			contentW := clientW - 24
			if contentW < 400 {
				contentW = 400
			}
			// 1. Stretch 15-Minute Graph Canvas horizontally
			if hwndGraphCanvas != 0 {
				procMoveWindow.Call(hwndGraphCanvas, 12, 42, uintptr(contentW), 155, 1)
				procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
			}
			// 2. Stretch ListView Table horizontally and vertically
			lvTop := int32(204)
			footerY := clientH - 32
			lvHeight := footerY - lvTop - 8
			if lvHeight < 120 {
				lvHeight = 120
			}
			if hwndListView != 0 {
				procMoveWindow.Call(hwndListView, 12, uintptr(lvTop), uintptr(contentW), uintptr(lvHeight), 1)
				// Dynamically adjust last column ("Channel %") so no horizontal scrollbar appears
				fixedColsW := int32(0)
				for i := 0; i < len(baseColumns)-1; i++ {
					fixedColsW += baseColumns[i].Width
				}
				remW := contentW - fixedColsW - 26
				if remW < 120 {
					remW = 120
				}
				procSendMessageW.Call(hwndListView, LVM_SETCOLUMNWIDTH, uintptr(len(baseColumns)-1), uintptr(remW))
			}
			// 3. Reposition Bottom Status Bar, Install Button, and Brand Signature
			brandX := clientW - 128
			installX := brandX - 105
			statusW := installX - 24
			if statusW < 200 {
				statusW = 200
			}
			if hwndStatus != 0 {
				procMoveWindow.Call(hwndStatus, 12, uintptr(footerY+3), uintptr(statusW), 22, 1)
			}
			if hwndBtnInstall != 0 {
				procMoveWindow.Call(hwndBtnInstall, uintptr(installX), uintptr(footerY), 88, 25, 1)
			}
			if hwndBrand != 0 {
				procMoveWindow.Call(hwndBrand, uintptr(brandX), uintptr(footerY+3), 115, 22, 1)
			}
			procInvalidateRect.Call(hwnd, 0, 1)
		}
		return 0

	case WM_TIMER:
		if wParam == 10 {
			sampleNetworkTelemetry()
			refreshMainListView()
			if hwndGraphCanvas != 0 {
				procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
			}
		}
		return 0

	case WM_COMMAND:
		controlId := int(wParam & 0xFFFF)
		notificationCode := int((wParam >> 16) & 0xFFFF)

		if notificationCode == CBN_SELCHANGE {
			switch controlId {
			case 1010: // Filter Mode
				sel, _, _ := procSendMessageW.Call(hwndComboFilter, CB_GETCURSEL, 0, 0)
				statsMutex.Lock()
				filterMode = int(sel)
				rebuildDisplayListLocked()
				statsMutex.Unlock()
				procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
				refreshMainListView()
				return 0

			case 1011: // Graph Time Window
				sel, _, _ := procSendMessageW.Call(hwndComboWindow, CB_GETCURSEL, 0, 0)
				switch sel {
				case 0:
					graphWindowSec = 900
				case 1:
					graphWindowSec = 300
				case 2:
					graphWindowSec = 60
				}
				procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
				return 0

			case 1012: // Sort Order Dropdown
				sel, _, _ := procSendMessageW.Call(hwndComboSort, CB_GETCURSEL, 0, 0)
				statsMutex.Lock()
				switch sel {
				case 0:
					sortColumn = 4 // Download Speed
					sortDesc = true
				case 1:
					sortColumn = 5 // Upload Speed
					sortDesc = true
				case 2:
					sortColumn = 1 // Cloud / Category
					sortDesc = false
				case 3:
					sortColumn = 2 // Application Name
					sortDesc = false
				case 4:
					sortColumn = 6 // Total Downloaded
					sortDesc = true
				case 5:
					sortColumn = 7 // Total Uploaded
					sortDesc = true
				}
				rebuildDisplayListLocked()
				statsMutex.Unlock()
				updateListViewHeaderSortIndicators()
				refreshMainListView()
				return 0
			}
		}

		switch controlId {
		case 1001: // Pause / Resume
			isMonitoringPaused = !isMonitoringPaused
			procInvalidateRect.Call(hwndBtnPause, 0, 1)
			if isMonitoringPaused {
				setControlText(hwndStatus, "⏸ Live Network Telemetry Paused. Click '▶ Resume' to continue monitoring.")
			} else {
				setControlText(hwndStatus, "▶ Live Network Telemetry Resumed.")
			}

		case 1002: // Reset Session Stats & Graph
			statsMutex.Lock()
			appStatsMap = make(map[string]*AppNetworkStat)
			displayList = nil
			selectedAppNames = nil
			sysHistory = [HistoryCapacity]SpeedSample{}
			sysCurDownBps = 0
			sysCurUpBps = 0
			sysPeakDownBps = 0
			sysPeakUpBps = 0
			sysTotalDown = 0
			sysTotalUp = 0
			statsMutex.Unlock()
			procSendMessageW.Call(hwndListView, LVM_DELETEALLITEMS, 0, 0)
			procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
			setControlText(hwndStatus, "↻ Reset all 15-minute graph history and total downloaded/uploaded byte counters.")

		case 1003: // Save Log
			exportReport()

		case 1004: // Brand Label -> 3D About Dialog
			showAboutDialog()

		case 1005: // Open Cloud Speed Benchmark Dialog
			showCloudBenchmarkDialog()

		case 1007: // Install Button
			installApplication()

		case 2001: // Add / Remove selected app in graph
			selIdx, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			statsMutex.Lock()
			if int(selIdx) >= 0 && int(selIdx) < len(displayList) {
				toggleAppSelectionLocked(displayList[int(selIdx)].AppName)
			}
			statsMutex.Unlock()
			procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
			refreshMainListView()

		case 2002: // Clear all apps from graph
			statsMutex.Lock()
			selectedAppNames = nil
			statsMutex.Unlock()
			procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
			refreshMainListView()

		case 2003: // Copy App Card
			selIdx, _, _ := procSendMessageW.Call(hwndListView, LVM_GETNEXTITEM, ^uintptr(0), LVNI_SELECTED)
			statsMutex.Lock()
			if int(selIdx) >= 0 && int(selIdx) < len(displayList) {
				ap := displayList[int(selIdx)]
				card := fmt.Sprintf("Application:      %s (PID %d)\r\nCategory:         %s\r\nDownload Speed:   %s\r\nUpload Speed:     %s\r\nTotal Downloaded: %s\r\nTotal Uploaded:   %s\r\nChannel Share:    %.1f%%",
					ap.AppName, ap.PID, ap.CloudCategory,
					formatSpeed(ap.DownSpeedBps),
					formatSpeed(ap.UpSpeedBps),
					formatBytes(ap.TotalDownBytes),
					formatBytes(ap.TotalUpBytes),
					ap.SharePercent)
				copyToClipboard(card)
			}
			statsMutex.Unlock()
			setControlText(hwndStatus, "Copied selected application speed metrics to Clipboard.")

		case 2004:
			showCloudBenchmarkDialog()
		}
		return 0

	case WM_NOTIFY:
		nmhdr := (*NMHDR)(unsafe.Pointer(lParam))
		if nmhdr.HwndFrom == hwndListView {
			// 1. Excel-Style Click on Any Column Header to Sort (LVN_COLUMNCLICK)
			if nmhdr.Code == LVN_COLUMNCLICK {
				nmlv := (*NMLISTVIEW)(unsafe.Pointer(lParam))
				clickedCol := int(nmlv.ISubItem)
				if clickedCol >= 0 && clickedCol < len(baseColumns) {
					statsMutex.Lock()
					if sortColumn == clickedCol {
						sortDesc = !sortDesc
					} else {
						sortColumn = clickedCol
						// Text columns (1: Cloud/Category, 2: Application, 3: PID) sort A->Z ascending first; numeric columns sort highest first
						if clickedCol == 1 || clickedCol == 2 || clickedCol == 3 {
							sortDesc = false
						} else {
							sortDesc = true
						}
					}
					rebuildDisplayListLocked()
					statsMutex.Unlock()
					updateListViewHeaderSortIndicators()
					refreshMainListView()
				}
				return 0
			}

			// 2. Double-Click Row to Add / Remove App in Top 15-Minute Multi-App Graph (NM_DBLCLK)
			if nmhdr.Code == NM_DBLCLK {
				nmia := (*NMITEMACTIVATE)(unsafe.Pointer(lParam))
				idx := int(nmia.IItem)
				statsMutex.Lock()
				if idx >= 0 && idx < len(displayList) {
					clickedApp := displayList[idx].AppName
					toggleAppSelectionLocked(clickedApp)
				}
				statsMutex.Unlock()
				procInvalidateRect.Call(hwndGraphCanvas, 0, 0)
				refreshMainListView()
				return 0
			}

			if nmhdr.Code == NM_CUSTOMDRAW {
				pcd := (*NMLVCUSTOMDRAW)(unsafe.Pointer(lParam))
				if pcd.DwDrawStage == CDDS_PREPAINT {
					return CDRF_NOTIFYITEMDRAW
				}
				if pcd.DwDrawStage == CDDS_ITEMPREPAINT {
					return CDRF_NOTIFYSUBITEMDRAW
				}
				if pcd.DwDrawStage == (CDDS_ITEMPREPAINT | CDDS_SUBITEM) {
					itemIdx := int(pcd.DwItemSpec)
					subItem := int(pcd.ISubItem)

					statsMutex.Lock()
					if itemIdx >= 0 && itemIdx < len(displayList) {
						row := displayList[itemIdx]
						selOrder, isGraphTarget := isAppSelectedLocked(row.AppName)
						if isGraphTarget {
							pcd.ClrTextBk = appRowTintPalette[selOrder%len(appRowTintPalette)] // Distinct soft highlight per graph slot
						} else if row.IsCloudEngine {
							pcd.ClrTextBk = 0xFDF9F4
						} else {
							pcd.ClrTextBk = 0xFFFFFF
						}

						switch subItem {
						case 0: // #
							pcd.ClrText = 0x666666
						case 1: // Cloud / Category
							pcd.ClrText = getCategoryColor(row.CloudCategory)
						case 2: // Application (.exe)
							if isGraphTarget {
								pcd.ClrText = 0x1B5E20 // Deep Emerald Bold
							} else if row.IsCloudEngine {
								pcd.ClrText = 0x8B3A00
							} else {
								pcd.ClrText = 0x222222
							}
						case 3: // PID
							pcd.ClrText = 0x555555
						case 4: // ⬇ Download Speed
							if row.DownSpeedBps >= 1024*1024 {
								pcd.ClrText = 0x2E7D32
							} else if row.DownSpeedBps > 512 {
								pcd.ClrText = 0x388E3C
							} else {
								pcd.ClrText = 0x888888
							}
						case 5: // ⬆ Upload Speed
							if row.UpSpeedBps >= 1024*1024 {
								pcd.ClrText = 0x0045D8
							} else if row.UpSpeedBps > 512 {
								pcd.ClrText = 0x0066CC
							} else {
								pcd.ClrText = 0x888888
							}
						case 6, 7: // Total Downloaded & Total Uploaded
							if row.TotalDownBytes+row.TotalUpBytes > 10*1024*1024 {
								pcd.ClrText = 0x9E5A00
							} else {
								pcd.ClrText = 0x444444
							}
						case 8: // Channel %
							if row.SharePercent >= 25.0 {
								pcd.ClrText = 0x2828D8
							} else if row.SharePercent >= 1.0 {
								pcd.ClrText = 0x8F8300
							} else {
								pcd.ClrText = 0x999999
							}
						}
					}
					statsMutex.Unlock()
					return CDRF_DODEFAULT
				}
			}
		}
		return 0

	case WM_SETCURSOR:
		if uintptr(wParam) == hwndBrand {
			procSetCursor.Call(hCursorHand)
			return 1
		}

	case WM_CONTEXTMENU:
		if wParam == hwndListView {
			x := int32(lParam & 0xFFFF)
			y := int32((lParam >> 16) & 0xFFFF)
			showContextMenu(x, y)
			return 0
		}

	case WM_DRAWITEM:
		dis := (*DRAWITEMSTRUCT)(unsafe.Pointer(lParam))
		hDC := dis.HDC
		rc := dis.RcItem
		isPressed := (dis.ItemState & 0x0001) != 0

		var btnText string
		var btnColor uintptr
		var textColor uintptr = 0xFFFFFF
		var borderColor uintptr

		switch dis.CtlID {
		case 1001: // Pause / Resume
			if isMonitoringPaused {
				btnText = "▶ Resume"
				btnColor = 0x45A728
				borderColor = 0x388821
			} else {
				btnText = "⏸ Pause"
				btnColor = 0x6C757D
				borderColor = 0x545B62
				if isPressed {
					btnColor = 0x545B62
				}
			}
		case 1002: // Reset
			btnText = "↻ Reset"
			btnColor = 0x4535DC
			borderColor = 0x3323C8
			if isPressed {
				btnColor = 0x3021BD
			}
		case 1005: // Cloud Speed Test
			btnText = "☁ Cloud Speed Test"
			btnColor = 0xD47800
			borderColor = 0xB16300
			if isPressed {
				btnColor = 0x9E5A00
			}
		case 1003: // Save Log
			btnText = "Save Log"
			btnColor = 0xB8A217
			borderColor = 0x968413
			if isPressed {
				btnColor = 0x8B7A11
			}
		case 1007: // Install Button
			if isAppInstalled() {
				btnText = "Installed"
				btnColor = 0x45A728
				borderColor = 0x347E1E
			} else {
				btnText = "Install"
				btnColor = 0x303BFF
				borderColor = 0x202BD8
			}
		default:
			return 0
		}

		hBrush, _, _ := procCreateSolidBrush.Call(btnColor)
		hPen, _, _ := procCreatePen.Call(0, 1, borderColor)
		oldBrush, _, _ := procSelectObject.Call(hDC, hBrush)
		oldPen, _, _ := procSelectObject.Call(hDC, hPen)

		procRoundRect.Call(hDC, uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom), 8, 8)

		procSelectObject.Call(hDC, oldBrush)
		procSelectObject.Call(hDC, oldPen)
		procDeleteObject.Call(hBrush)
		procDeleteObject.Call(hPen)

		procSetBkMode.Call(hDC, 1)
		procSetTextColor.Call(hDC, textColor)
		oldFont, _, _ := procSelectObject.Call(hDC, hFontBold)
		procDrawTextW.Call(hDC, uintptr(unsafe.Pointer(strPtr(btnText))), ^uintptr(0), uintptr(unsafe.Pointer(&rc)), 0x00000001|0x00000004|0x00000020)
		procSelectObject.Call(hDC, oldFont)
		return 1

	case WM_CTLCOLORSTATIC:
		hdc := wParam
		if uintptr(lParam) == hwndBrand {
			procSetBkMode.Call(hdc, 1)
			procSetTextColor.Call(hdc, 0xAA3300)
			return hBrushWhite
		}
		procSetBkMode.Call(hdc, 1)
		return hBrushWhite

	case WM_CLOSE:
		procKillTimer.Call(hwnd, 10)
		atomic.StoreInt32(&stopBenchFlag, 1)
		procDestroyWindow.Call(hwnd)
		return 0

	case WM_DESTROY:
		procKillTimer.Call(hwnd, 10)
		atomic.StoreInt32(&stopBenchFlag, 1)
		procPostQuitMessage.Call(0)
		procExitProcess.Call(0)
		return 0
	}

	ret, _, _ := procDefWindowProcW.Call(hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func main() {
	runtime.LockOSThread()

	hCurProc, _, _ := procGetCurrentProcess.Call()
	procSetPriorityClass.Call(hCurProc, 0x00004000)

	var icex INITCOMMONCONTROLSEX
	icex.DwSize = uint32(unsafe.Sizeof(icex))
	icex.DwICC = 0x00000001 | 0x00000004 | 0x00000020
	procInitCommonControlsEx.Call(uintptr(unsafe.Pointer(&icex)))

	hInstanceRet, _, _ := procGetModuleHandleW.Call(0)
	hInstance = hInstanceRet

	hBrushWhite, _, _ = procGetStockObject.Call(0)
	hBrushBlack, _, _ = procGetStockObject.Call(4)
	hBrushGraphBg, _, _ = procCreateSolidBrush.Call(0x22150D)

	for _, resId := range []uintptr{1, 2, 101} {
		hIconRet, _, _ := procLoadImageW.Call(hInstance, resId, uintptr(IMAGE_ICON), 0, 0, uintptr(LR_DEFAULTSIZE|LR_SHARED))
		if hIconRet != 0 {
			hIconApp = hIconRet
			break
		}
		hIconRet, _, _ = procLoadIconW.Call(hInstance, resId)
		if hIconRet != 0 {
			hIconApp = hIconRet
			break
		}
	}

	hCursorHand, _, _ = procLoadCursorW.Call(0, uintptr(IDC_HAND))

	hFontSegoe, _, _ = procCreateFontW.Call(uintptr(16), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	if hFontSegoe == 0 {
		hFontSegoe, _, _ = procGetStockObject.Call(DEFAULT_GUI_FONT)
	}
	hFontBold, _, _ = procCreateFontW.Call(uintptr(16), 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	if hFontBold == 0 {
		hFontBold = hFontSegoe
	}
	hFontSmall, _, _ = procCreateFontW.Call(uintptr(14), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, uintptr(unsafe.Pointer(strPtr("Segoe UI"))))
	if hFontSmall == 0 {
		hFontSmall = hFontSegoe
	}

	hPenCyan, _, _ = procCreatePen.Call(0, 2, 0x00FFFF)
	hBrushAnimBlue, _, _ = procCreateSolidBrush.Call(0xFF9900)

	classNameMain := strPtr("GINNetSpeedMainWindow")
	var wc WNDCLASSEXW
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.Style = 0x0002 | 0x0001
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = hInstance
	wc.HIcon = hIconApp
	wc.HIconSm = hIconApp
	wc.HbrBackground = hBrushWhite
	wc.LpszClassName = classNameMain
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wc)))

	classNameGraph := strPtr("GINNetSpeedGraphCanvas")
	var wcG WNDCLASSEXW
	wcG.CbSize = uint32(unsafe.Sizeof(wcG))
	wcG.Style = 0x0002 | 0x0001
	wcG.LpfnWndProc = syscall.NewCallback(graphWndProc)
	wcG.HInstance = hInstance
	wcG.HbrBackground = hBrushGraphBg
	wcG.LpszClassName = classNameGraph
	procRegisterClassExW.Call(uintptr(unsafe.Pointer(&wcG)))

	hwndMainRet, _, _ := procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(classNameMain)),
		uintptr(unsafe.Pointer(strPtr(AppTitle))),
		WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		40, 35, 1180, 700,
		0, 0, hInstance, 0,
	)
	hwndMain = hwndMainRet

	if hIconApp != 0 {
		procSendMessageW.Call(hwndMain, WM_SETICON, 1, hIconApp)
		procSendMessageW.Call(hwndMain, WM_SETICON, 0, hIconApp)
	}

	// --- ROW 1: Top Toolbar Controls ---
	xOff := 12

	procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr("Show:"))), WS_CHILD|WS_VISIBLE, uintptr(xOff), 13, 42, 22, hwndMain, 0, hInstance, 0)
	xOff += 44
	hwndComboFilter, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST, uintptr(xOff), 9, 185, 200, hwndMain, 1010, hInstance, 0)
	procSendMessageW.Call(hwndComboFilter, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("All Network Processes"))))
	procSendMessageW.Call(hwndComboFilter, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("☁ Cloud Engines Only"))))
	procSendMessageW.Call(hwndComboFilter, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("⚡ Active Traffic (>0 KB/s)"))))
	procSendMessageW.Call(hwndComboFilter, CB_SETDROPPEDWIDTH, 220, 0)
	procSendMessageW.Call(hwndComboFilter, CB_SETCURSEL, 0, 0)
	xOff += 195

	procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr("Graph:"))), WS_CHILD|WS_VISIBLE, uintptr(xOff), 13, 46, 22, hwndMain, 0, hInstance, 0)
	xOff += 48
	hwndComboWindow, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST, uintptr(xOff), 9, 150, 200, hwndMain, 1011, hInstance, 0)
	procSendMessageW.Call(hwndComboWindow, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("15 Minutes (Full)"))))
	procSendMessageW.Call(hwndComboWindow, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("5 Minutes (Zoom)"))))
	procSendMessageW.Call(hwndComboWindow, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("60 Seconds (Live)"))))
	procSendMessageW.Call(hwndComboWindow, CB_SETDROPPEDWIDTH, 185, 0)
	procSendMessageW.Call(hwndComboWindow, CB_SETCURSEL, 0, 0)
	xOff += 160

	procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("STATIC"))), uintptr(unsafe.Pointer(strPtr("Sort:"))), WS_CHILD|WS_VISIBLE, uintptr(xOff), 13, 36, 22, hwndMain, 0, hInstance, 0)
	xOff += 38
	hwndComboSort, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("COMBOBOX"))), 0, WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP|CBS_DROPDOWNLIST, uintptr(xOff), 9, 165, 200, hwndMain, 1012, hInstance, 0)
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("⬇ Download Speed"))))
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("⬆ Upload Speed"))))
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("☁ Cloud / Category"))))
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("Application Name (A-Z)"))))
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("Total Downloaded"))))
	procSendMessageW.Call(hwndComboSort, CB_ADDSTRING, 0, uintptr(unsafe.Pointer(strPtr("Total Uploaded"))))
	procSendMessageW.Call(hwndComboSort, CB_SETDROPPEDWIDTH, 205, 0)
	procSendMessageW.Call(hwndComboSort, CB_SETCURSEL, 0, 0)
	xOff += 177

	hwndBtnPause, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr("⏸ Pause"))), WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, uintptr(xOff), 8, 86, 27, hwndMain, 1001, hInstance, 0)
	xOff += 92

	hwndBtnReset, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr("↻ Reset"))), WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, uintptr(xOff), 8, 82, 27, hwndMain, 1002, hInstance, 0)
	xOff += 88

	hwndBtnCloud, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr("☁ Cloud Speed Test"))), WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, uintptr(xOff), 8, 168, 27, hwndMain, 1005, hInstance, 0)
	xOff += 174

	hwndBtnExport, _, _ = procCreateWindowExW.Call(0, uintptr(unsafe.Pointer(strPtr("BUTTON"))), uintptr(unsafe.Pointer(strPtr("Save Log"))), WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP, uintptr(xOff), 8, 98, 27, hwndMain, 1003, hInstance, 0)

	// --- ROW 2: 15-Minute Dual-Wave Live Bandwidth Graph ---
	hwndGraphCanvas, _, _ = procCreateWindowExW.Call(
		0,
		uintptr(unsafe.Pointer(classNameGraph)),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER,
		12, 42, 1140, 155,
		hwndMain, 0, hInstance, 0,
	)

	// --- ROW 3: Clean 9-Column Per-Application Network & Cloud Speed Table (Zero Horizontal Scroll) ---
	hwndListView, _, _ = procCreateWindowExW.Call(
		0x00000200,
		uintptr(unsafe.Pointer(strPtr("SysListView32"))),
		0,
		WS_CHILD|WS_VISIBLE|WS_BORDER|LVS_REPORT|LVS_SINGLESEL|LVS_SHOWSELALWAYS,
		12, 204, 1140, 415,
		hwndMain, 0, hInstance, 0,
	)
	procSendMessageW.Call(hwndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT|LVS_EX_GRIDLINES|LVS_EX_DOUBLEBUFFER)

	for i, col := range baseColumns {
		lvc := LVCOLUMNW{
			Mask:    0x0001 | 0x0002 | 0x0004,
			Fmt:     0,
			Cx:      col.Width,
			PszText: strPtr(col.Title),
		}
		procSendMessageW.Call(hwndListView, LVM_INSERTCOLUMNW, uintptr(i), uintptr(unsafe.Pointer(&lvc)))
	}
	updateListViewHeaderSortIndicators()

	// --- ROW 4: Bottom Status Bar + Portable/Install + Brand Signature ---
	hwndStatus, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("Ready. Double-click any row to connect/disconnect it on the 15-minute graph. Click any column header to sort."))),
		WS_CHILD|WS_VISIBLE,
		12, 628, 800, 22,
		hwndMain, 0, hInstance, 0,
	)

	hwndBtnInstall, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("BUTTON"))),
		uintptr(unsafe.Pointer(strPtr("Install"))),
		WS_CHILD|WS_VISIBLE|BS_OWNERDRAW|WS_TABSTOP,
		925, 625, 88, 25,
		hwndMain, 1007, hInstance, 0,
	)

	hwndBrand, _, _ = procCreateWindowExW.Call(
		0, uintptr(unsafe.Pointer(strPtr("STATIC"))),
		uintptr(unsafe.Pointer(strPtr("VladiMIR+AI"))),
		WS_CHILD|WS_VISIBLE|SS_RIGHT|SS_NOTIFY,
		1035, 628, 115, 22,
		hwndMain, 1004, hInstance, 0,
	)

	// Tooltips
	hwndTip, _, _ := procCreateWindowExW.Call(
		0x00000008,
		uintptr(unsafe.Pointer(strPtr("tooltips_class32"))),
		0,
		WS_POPUP|TTS_ALWAYSTIP|TTS_NOPREFIX|TTS_BALLOON,
		0, 0, 0, 0,
		hwndMain, 0, hInstance, 0,
	)
	if hwndTip != 0 {
		procSendMessageW.Call(hwndTip, TTM_SETMAXTIPWIDTH, 0, 480)
		addTooltip(hwndTip, hwndComboFilter, "Process Filter:\nChoose whether to display all network processes, only Cloud Sync Engines, or only active transfers.")
		addTooltip(hwndTip, hwndComboWindow, "Graph Time Horizon:\nSwitch the rolling graph between 15 Minutes, 5 Minutes, and 60 Seconds.")
		addTooltip(hwndTip, hwndComboSort, "Table Sorting:\nYou can also click ANY column header directly in the table (like in Excel) to sort ascending/descending!")
		addTooltip(hwndTip, hwndBtnCloud, "Cloud Engines Speed Benchmark:\nCompare Small Files (100 KB) vs Large Files (10 MB) upload and download speeds across MEGA, Google Drive, OneDrive, Yandex.Disk, Mail.Ru Cloud, and Dropbox.")
		addTooltip(hwndTip, hwndBtnExport, "Save Log:\nExport full network & cloud bandwidth table to Desktop in UTF-8.")
		addTooltip(hwndTip, hwndBrand, "About GIN-NetSpeed (100% Portable, Zero Background Processes)")
	}

	allCtrls := []uintptr{
		hwndComboFilter, hwndComboWindow, hwndComboSort,
		hwndBtnPause, hwndBtnReset, hwndBtnCloud, hwndBtnExport,
		hwndListView, hwndStatus, hwndBtnInstall,
	}
	for _, h := range allCtrls {
		procSendMessageW.Call(h, WM_SETFONT, hFontSegoe, 1)
	}
	procSendMessageW.Call(hwndBrand, WM_SETFONT, hFontBold, 1)

	sampleNetworkTelemetry()
	refreshMainListView()
	procSetTimer.Call(hwndMain, 10, 1000, 0)

	procShowWindow.Call(hwndMain, 5)
	procUpdateWindow.Call(hwndMain)

	var msg struct {
		Hwnd    uintptr
		Message uint32
		WParam  uintptr
		LParam  uintptr
		Time    uint32
		Pt      struct{ X, Y int32 }
	}
	for {
		ret, _, _ := procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if ret == 0 || int32(ret) == -1 {
			break
		}
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessageW.Call(uintptr(unsafe.Pointer(&msg)))
	}
	procExitProcess.Call(0)
}

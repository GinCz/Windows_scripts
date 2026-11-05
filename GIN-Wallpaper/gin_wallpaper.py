"""
GIN-Wallpaper v001
==================
Лёгкий трей-апплет для Windows: скачивает обои с Unsplash/Pexels,
рисует поверх них календарь (как на скриншоте) и устанавливает
как wallpaper рабочего стола. Автосмена по расписанию.

Автор: GinCz / Vladimir Bulantsev
GitHub: https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper
Лицензия: MIT
"""

import os
import sys
import json
import ctypes
import locale
import logging
import threading
import calendar
import datetime
import urllib.request
import urllib.parse
import urllib.error
import tkinter as tk
import tkinter.ttk as ttk
import tkinter.messagebox as mb
import tkinter.font as tkfont
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ─── Опциональный pystray (трей). Если не установлен — работает без трея ───
try:
    import pystray
    from pystray import MenuItem as item
    HAS_TRAY = True
except ImportError:
    HAS_TRAY = False

# ─── Версия ───────────────────────────────────────────────────────────────────
VERSION = "v001"
APP_NAME = "GIN-Wallpaper"

# ─── Пути ─────────────────────────────────────────────────────────────────────
APP_DIR = Path(os.environ.get("APPDATA", "")) / "GIN-Wallpaper"
CACHE_DIR = APP_DIR / "cache"
SETTINGS_FILE = APP_DIR / "settings.json"
LOG_FILE = APP_DIR / "gin_wallpaper.log"

APP_DIR.mkdir(parents=True, exist_ok=True)
CACHE_DIR.mkdir(parents=True, exist_ok=True)

# ─── Логирование ──────────────────────────────────────────────────────────────
logging.basicConfig(
    filename=str(LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(APP_NAME)

# ─── Темы картинок ────────────────────────────────────────────────────────────
THEMES = {
    "space":       {"name": "🚀 Космос",    "query": "space galaxy nebula stars"},
    "nature":      {"name": "🌿 Природа",   "query": "nature landscape mountains forest"},
    "cars":        {"name": "🚗 Автомобили","query": "supercar sports car automotive"},
    "city":        {"name": "🌆 Города",    "query": "city skyline urban architecture"},
    "animals":     {"name": "🦁 Животные",  "query": "wildlife animals nature"},
    "abstract":    {"name": "🎨 Абстракция","query": "abstract art colorful digital"},
    "ocean":       {"name": "🌊 Океан",     "query": "ocean sea waves beach"},
    "winter":      {"name": "❄️ Зима",      "query": "winter snow ice forest"},
}

INTERVALS = {
    "1h":    {"name": "Каждый час",        "seconds": 3600},
    "3h":    {"name": "Каждые 3 часа",     "seconds": 10800},
    "6h":    {"name": "Каждые 6 часов",    "seconds": 21600},
    "daily": {"name": "Раз в день",        "seconds": 86400},
}

# ─── Настройки по умолчанию ───────────────────────────────────────────────────
DEFAULT_SETTINGS = {
    "themes": ["space"],         # список активных тем
    "interval": "3h",           # ключ из INTERVALS
    "unsplash_key": "",         # Unsplash Client-ID (опционально)
    "pexels_key": "",           # Pexels API key (опционально)
    "calendar_locale": "ru_RU", # локаль для подписей календаря
    "calendar_opacity": 180,    # прозрачность фона под календарём 0-255
    "show_calendar": True,      # показывать ли календарь
    "last_changed": "",         # ISO-время последней смены
}

# ─── Русские названия месяцев и дней (fallback без locale) ────────────────────
RU_MONTHS = [
    "", "января","февраля","марта","апреля","мая","июня",
    "июля","августа","сентября","октября","ноября","декабря",
]
RU_MONTHS_NOM = [
    "", "Январь","Февраль","Март","Апрель","Май","Июнь",
    "Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь",
]
RU_WEEKDAYS_SHORT = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]


# ════════════════════════════════════════════════════════════════════════════════
#  УТИЛИТЫ
# ════════════════════════════════════════════════════════════════════════════════

def load_settings() -> dict:
    if SETTINGS_FILE.exists():
        try:
            with open(SETTINGS_FILE, encoding="utf-8") as f:
                data = json.load(f)
            # Дополняем дефолтами если появились новые ключи
            for k, v in DEFAULT_SETTINGS.items():
                data.setdefault(k, v)
            return data
        except Exception as e:
            log.warning(f"Ошибка чтения настроек: {e}")
    return DEFAULT_SETTINGS.copy()


def save_settings(settings: dict):
    with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
        json.dump(settings, f, ensure_ascii=False, indent=2)


def get_screen_resolution() -> tuple[int, int]:
    """Возвращает разрешение основного монитора."""
    user32 = ctypes.windll.user32
    user32.SetProcessDPIAware()
    w = user32.GetSystemMetrics(0)
    h = user32.GetSystemMetrics(1)
    return w, h


def set_wallpaper_win(path: str):
    """Устанавливает обои средствами Windows API (SystemParametersInfo)."""
    SPI_SETDESKWALLPAPER = 0x0014
    SPIF_UPDATEINIFILE   = 0x0001
    SPIF_SENDCHANGE      = 0x0002
    ctypes.windll.user32.SystemParametersInfoW(
        SPI_SETDESKWALLPAPER, 0, path,
        SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
    )


def pick_theme(settings: dict) -> str:
    """Возвращает случайный запрос из выбранных тем."""
    import random
    active = [t for t in settings["themes"] if t in THEMES]
    if not active:
        active = ["nature"]
    theme_key = random.choice(active)
    return THEMES[theme_key]["query"]


# ════════════════════════════════════════════════════════════════════════════════
#  ЗАГРУЗКА КАРТИНОК
# ════════════════════════════════════════════════════════════════════════════════

def download_unsplash(query: str, w: int, h: int, api_key: str) -> bytes | None:
    """Загружает фото с Unsplash API (требует ключ)."""
    url = (
        f"https://api.unsplash.com/photos/random"
        f"?query={urllib.parse.quote(query)}"
        f"&orientation=landscape&content_filter=high"
    )
    req = urllib.request.Request(url, headers={"Authorization": f"Client-ID {api_key}"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read())
        # Запрашиваем максимальное разрешение под экран
        raw_url = data["urls"]["raw"]
        img_url = f"{raw_url}&w={w}&h={h}&fit=crop&auto=format&q=85"
        with urllib.request.urlopen(img_url, timeout=30) as r:
            return r.read()
    except Exception as e:
        log.error(f"Unsplash download error: {e}")
        return None


def download_pexels(query: str, w: int, h: int, api_key: str) -> bytes | None:
    """Загружает фото с Pexels API (требует ключ)."""
    url = (
        f"https://api.pexels.com/v1/search"
        f"?query={urllib.parse.quote(query)}&per_page=15&orientation=landscape"
    )
    req = urllib.request.Request(url, headers={"Authorization": api_key})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read())
        import random
        photos = data.get("photos", [])
        if not photos:
            return None
        photo = random.choice(photos)
        # Выбираем наиболее подходящее разрешение
        src = photo["src"]
        img_url = src.get("original", src.get("large2x", src["large"]))
        with urllib.request.urlopen(img_url, timeout=30) as r:
            return r.read()
    except Exception as e:
        log.error(f"Pexels download error: {e}")
        return None


def download_picsum(w: int, h: int) -> bytes | None:
    """Fallback: Lorem Picsum (случайное фото, без ключа)."""
    import random
    seed = random.randint(1, 1000)
    url = f"https://picsum.photos/seed/{seed}/{w}/{h}"
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return r.read()
    except Exception as e:
        log.error(f"Picsum download error: {e}")
        return None


def fetch_wallpaper_image(settings: dict) -> bytes | None:
    """Пробует загрузить картинку: Unsplash → Pexels → Picsum."""
    w, h = get_screen_resolution()
    query = pick_theme(settings)
    log.info(f"Загрузка обоев: query='{query}' {w}x{h}")

    if settings.get("unsplash_key"):
        data = download_unsplash(query, w, h, settings["unsplash_key"])
        if data:
            log.info("Источник: Unsplash ✓")
            return data

    if settings.get("pexels_key"):
        data = download_pexels(query, w, h, settings["pexels_key"])
        if data:
            log.info("Источник: Pexels ✓")
            return data

    # Бесплатный fallback без ключа
    data = download_picsum(w, h)
    if data:
        log.info("Источник: Picsum (fallback) ✓")
    return data


# ════════════════════════════════════════════════════════════════════════════════
#  РИСОВАНИЕ КАЛЕНДАРЯ (как на скриншоте: правый верхний угол)
# ════════════════════════════════════════════════════════════════════════════════

def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | None:
    """Пробует загрузить системный шрифт с поддержкой кириллицы."""
    candidates = [
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibri.ttf",
        "C:/Windows/Fonts/tahoma.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def draw_calendar(img: Image.Image, opacity: int = 180) -> Image.Image:
    """
    Рисует календарь текущего месяца в правом верхнем углу изображения.
    Стиль: полупрозрачный тёмный фон, белый текст, текущий день выделен.
    """
    img = img.copy()
    now = datetime.date.today()
    year, month, day = now.year, now.month, now.day

    # Шрифты
    font_title  = _load_font(22, bold=True)   # «5 ноября 2026 г.»
    font_header = _load_font(16, bold=True)   # «Пн Вт Ср ...»
    font_day    = _load_font(16)              # числа
    font_today  = _load_font(16, bold=True)   # текущий день (bold)

    # Параметры сетки
    col_w  = 36   # ширина ячейки
    row_h  = 24   # высота строки
    pad_x  = 16   # внутренний отступ по x
    pad_y  = 14   # внутренний отступ по y
    cols   = 7    # Пн–Вс

    cal_w = col_w * cols + pad_x * 2
    rows_needed = len(calendar.monthcalendar(year, month)) + 2  # +title+header
    cal_h = row_h * rows_needed + pad_y * 2 + 10

    # Создаём слой для календаря
    overlay = Image.new("RGBA", (cal_w, cal_h), (0, 0, 0, 0))
    bg = Image.new("RGBA", (cal_w, cal_h), (10, 10, 10, opacity))
    # Скруглённые углы через маску
    mask = Image.new("L", (cal_w, cal_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    radius = 14
    mask_draw.rounded_rectangle([0, 0, cal_w - 1, cal_h - 1], radius=radius, fill=255)
    overlay.paste(bg, mask=mask)

    draw = ImageDraw.Draw(overlay)

    # ── Заголовок: «5 ноября 2026 г.» ──
    title_text = f"{day} {RU_MONTHS[month]} {year} г."
    tw = draw.textlength(title_text, font=font_title)
    tx = (cal_w - tw) / 2
    draw.text((tx, pad_y), title_text, font=font_title, fill=(255, 255, 255, 255))

    y = pad_y + row_h + 6

    # ── Строка заголовков дней Пн–Вс ──
    for i, name in enumerate(RU_WEEKDAYS_SHORT):
        x = pad_x + i * col_w + (col_w - draw.textlength(name, font=font_header)) / 2
        color = (200, 200, 200, 230) if i < 5 else (255, 100, 100, 230)
        draw.text((x, y), name, font=font_header, fill=color)

    y += row_h

    # ── Числа месяца ──
    for week in calendar.monthcalendar(year, month):
        for col_idx, d in enumerate(week):
            if d == 0:
                continue
            is_today = (d == day)
            is_weekend = (col_idx >= 5)
            x = pad_x + col_idx * col_w
            cell_cx = x + col_w / 2
            cell_cy = y + row_h / 2

            if is_today:
                # Выделение текущего дня: белый круг
                r = row_h // 2 - 1
                draw.ellipse(
                    [cell_cx - r, cell_cy - r, cell_cx + r, cell_cy + r],
                    fill=(255, 255, 255, 230)
                )
                txt_color = (0, 0, 0, 255)
                fnt = font_today
            else:
                txt_color = (255, 80, 80, 230) if is_weekend else (255, 255, 255, 220)
                fnt = font_day

            tw = draw.textlength(str(d), font=fnt)
            draw.text((cell_cx - tw / 2, y + 3), str(d), font=fnt, fill=txt_color)
        y += row_h

    # ── Вставляем оверлей на основное изображение (правый верхний угол) ──
    img_w, img_h = img.size
    margin_right = 24
    margin_top   = 24
    paste_x = img_w - cal_w - margin_right
    paste_y = margin_top

    img_rgba = img.convert("RGBA")
    img_rgba.paste(overlay, (paste_x, paste_y), mask=overlay.split()[3])
    return img_rgba.convert("RGB")


# ════════════════════════════════════════════════════════════════════════════════
#  ОСНОВНАЯ ФУНКЦИЯ: скачать → нарисовать → установить
# ════════════════════════════════════════════════════════════════════════════════

def apply_wallpaper(settings: dict | None = None, status_cb=None) -> bool:
    """
    Полный цикл: загрузка → рисование → сохранение → установка.
    status_cb(text) вызывается для обновления UI (опционально).
    """
    if settings is None:
        settings = load_settings()

    def _status(msg: str):
        log.info(msg)
        if status_cb:
            status_cb(msg)

    _status("Загрузка изображения…")
    img_bytes = fetch_wallpaper_image(settings)
    if not img_bytes:
        _status("❌ Ошибка загрузки изображения")
        return False

    _status("Обработка изображения…")
    try:
        import io
        img = Image.open(io.BytesIO(img_bytes))
        # Масштабируем точно под экран
        sw, sh = get_screen_resolution()
        img = img.resize((sw, sh), Image.LANCZOS)

        if settings.get("show_calendar", True):
            img = draw_calendar(img, opacity=settings.get("calendar_opacity", 180))

        # Сохраняем
        out_path = str(APP_DIR / "current_wallpaper.jpg")
        img.save(out_path, "JPEG", quality=92, optimize=True)

        # Очищаем кэш в памяти
        del img
        del img_bytes

        _status("Установка обоев…")
        set_wallpaper_win(out_path)

        # Запоминаем время
        settings["last_changed"] = datetime.datetime.now().isoformat()
        save_settings(settings)

        _status("✅ Обои обновлены!")
        log.info(f"Wallpaper set: {out_path}")
        return True

    except Exception as e:
        log.error(f"apply_wallpaper error: {e}", exc_info=True)
        _status(f"❌ Ошибка: {e}")
        return False


# ════════════════════════════════════════════════════════════════════════════════
#  ПЛАНИРОВЩИК (фоновый поток)
# ════════════════════════════════════════════════════════════════════════════════

class WallpaperScheduler:
    """Лёгкий планировщик смены обоев на фоновом потоке."""

    def __init__(self):
        self._timer: threading.Timer | None = None
        self._lock = threading.Lock()

    def start(self):
        self._schedule_next()

    def stop(self):
        with self._lock:
            if self._timer:
                self._timer.cancel()
                self._timer = None

    def _schedule_next(self):
        settings = load_settings()
        interval_key = settings.get("interval", "3h")
        seconds = INTERVALS.get(interval_key, INTERVALS["3h"])["seconds"]

        with self._lock:
            self._timer = threading.Timer(seconds, self._tick)
            self._timer.daemon = True
            self._timer.start()
        log.info(f"Следующая смена через {seconds}с ({interval_key})")

    def _tick(self):
        apply_wallpaper()
        self._schedule_next()

    def reset(self):
        """Перезапустить таймер (после изменения настроек)."""
        self.stop()
        self.start()


# ════════════════════════════════════════════════════════════════════════════════
#  ОКНО НАСТРОЕК (Tkinter)
# ════════════════════════════════════════════════════════════════════════════════

class SettingsWindow:

    def __init__(self, scheduler: WallpaperScheduler, root: tk.Tk | None = None):
        self.scheduler = scheduler
        self._win: tk.Toplevel | None = None
        self._root = root

    def show(self):
        if self._win and self._win.winfo_exists():
            self._win.lift()
            self._win.focus_force()
            return
        self._build()

    def _build(self):
        settings = load_settings()

        win = tk.Toplevel(self._root) if self._root else tk.Tk()
        win.title(f"{APP_NAME} {VERSION} — Настройки")
        win.resizable(False, False)
        win.configure(bg="#1e1e2e")

        # Иконка (если есть)
        ico = Path(__file__).parent / "assets" / "icon.ico"
        if ico.exists():
            try:
                win.iconbitmap(str(ico))
            except Exception:
                pass

        self._win = win

        style = ttk.Style(win)
        style.theme_use("clam")
        style.configure("TCheckbutton", background="#1e1e2e", foreground="#cdd6f4",
                        font=("Segoe UI", 10))
        style.configure("TRadiobutton", background="#1e1e2e", foreground="#cdd6f4",
                        font=("Segoe UI", 10))
        style.configure("TLabel",       background="#1e1e2e", foreground="#cdd6f4",
                        font=("Segoe UI", 10))
        style.configure("TFrame",       background="#1e1e2e")

        def lbl(parent, text, **kw):
            return tk.Label(parent, text=text, bg="#1e1e2e", fg="#cdd6f4",
                            font=("Segoe UI", kw.pop("size", 10), kw.pop("weight", "normal")),
                            **kw)

        pad = {"padx": 16, "pady": 6}

        # ── Заголовок ──────────────────────────────────────────────────────────
        lbl(win, f"🖼  {APP_NAME}", size=15, weight="bold",
            fg="#cba6f7").pack(anchor="w", padx=16, pady=(14, 2))
        lbl(win, "Умные обои с календарём для Windows", size=9,
            fg="#6c7086").pack(anchor="w", padx=16, pady=(0, 10))

        ttk.Separator(win, orient="horizontal").pack(fill="x", padx=16, pady=4)

        # ── Темы ───────────────────────────────────────────────────────────────
        lbl(win, "🎨 Тематика изображений", size=11, weight="bold").pack(anchor="w", **pad)

        self._theme_vars: dict[str, tk.BooleanVar] = {}
        themes_fr = tk.Frame(win, bg="#181825", relief="flat", bd=0)
        themes_fr.pack(fill="x", padx=16, pady=(0, 8))

        for key, info in THEMES.items():
            var = tk.BooleanVar(value=(key in settings["themes"]))
            self._theme_vars[key] = var
            cb = tk.Checkbutton(
                themes_fr, text=info["name"],
                variable=var, bg="#181825", fg="#cdd6f4",
                selectcolor="#313244", activebackground="#181825",
                activeforeground="#cba6f7",
                font=("Segoe UI", 10), cursor="hand2"
            )
            cb.pack(anchor="w", padx=12, pady=2)

        ttk.Separator(win, orient="horizontal").pack(fill="x", padx=16, pady=4)

        # ── Интервал ───────────────────────────────────────────────────────────
        lbl(win, "⏱  Интервал смены обоев", size=11, weight="bold").pack(anchor="w", **pad)

        self._interval_var = tk.StringVar(value=settings["interval"])
        int_fr = tk.Frame(win, bg="#181825")
        int_fr.pack(fill="x", padx=16, pady=(0, 8))

        for key, info in INTERVALS.items():
            rb = tk.Radiobutton(
                int_fr, text=info["name"], variable=self._interval_var, value=key,
                bg="#181825", fg="#cdd6f4", selectcolor="#313244",
                activebackground="#181825", activeforeground="#cba6f7",
                font=("Segoe UI", 10), cursor="hand2"
            )
            rb.pack(anchor="w", padx=12, pady=2)

        ttk.Separator(win, orient="horizontal").pack(fill="x", padx=16, pady=4)

        # ── Календарь ──────────────────────────────────────────────────────────
        lbl(win, "📅 Календарь", size=11, weight="bold").pack(anchor="w", **pad)

        cal_fr = tk.Frame(win, bg="#181825")
        cal_fr.pack(fill="x", padx=16, pady=(0, 8))

        self._show_cal_var = tk.BooleanVar(value=settings.get("show_calendar", True))
        tk.Checkbutton(
            cal_fr, text="Показывать календарь на обоях",
            variable=self._show_cal_var,
            bg="#181825", fg="#cdd6f4", selectcolor="#313244",
            activebackground="#181825", activeforeground="#cba6f7",
            font=("Segoe UI", 10), cursor="hand2"
        ).pack(anchor="w", padx=12, pady=2)

        # Прозрачность
        opc_fr = tk.Frame(cal_fr, bg="#181825")
        opc_fr.pack(anchor="w", padx=12, pady=4, fill="x")
        lbl(opc_fr, "Прозрачность фона:", bg="#181825").pack(side="left")
        self._opacity_var = tk.IntVar(value=settings.get("calendar_opacity", 180))
        tk.Scale(
            opc_fr, from_=50, to=240, orient="horizontal",
            variable=self._opacity_var, length=160,
            bg="#181825", fg="#cdd6f4", troughcolor="#313244",
            highlightthickness=0, bd=0
        ).pack(side="left", padx=8)

        ttk.Separator(win, orient="horizontal").pack(fill="x", padx=16, pady=4)

        # ── API ключи ──────────────────────────────────────────────────────────
        lbl(win, "🔑 API-ключи (опционально, для лучшего качества)",
            size=11, weight="bold").pack(anchor="w", **pad)

        api_fr = tk.Frame(win, bg="#181825")
        api_fr.pack(fill="x", padx=16, pady=(0, 8))

        for label, attr, hint in [
            ("Unsplash Client-ID:", "_unsplash_var",
             "Получить на unsplash.com/developers"),
            ("Pexels API Key:",    "_pexels_var",
             "Получить на pexels.com/api"),
        ]:
            row = tk.Frame(api_fr, bg="#181825")
            row.pack(fill="x", padx=12, pady=3)
            tk.Label(row, text=label, bg="#181825", fg="#cdd6f4",
                     font=("Segoe UI", 9), width=20, anchor="w").pack(side="left")
            var = tk.StringVar(value=settings.get(
                "unsplash_key" if "Unsplash" in label else "pexels_key", ""
            ))
            setattr(self, attr, var)
            entry = tk.Entry(row, textvariable=var, width=34,
                             bg="#313244", fg="#cdd6f4", insertbackground="#cdd6f4",
                             relief="flat", font=("Segoe UI", 9))
            entry.pack(side="left", padx=4)
            tk.Label(row, text=hint, bg="#181825", fg="#6c7086",
                     font=("Segoe UI", 8)).pack(side="left", padx=4)

        ttk.Separator(win, orient="horizontal").pack(fill="x", padx=16, pady=4)

        # ── Статус и кнопки ────────────────────────────────────────────────────
        last_ch = settings.get("last_changed", "")
        if last_ch:
            try:
                dt = datetime.datetime.fromisoformat(last_ch)
                last_text = "Последняя смена: " + dt.strftime("%d.%m.%Y %H:%M")
            except Exception:
                last_text = ""
        else:
            last_text = "Обои ещё не менялись"

        self._status_lbl = tk.Label(
            win, text=last_text, bg="#1e1e2e", fg="#6c7086",
            font=("Segoe UI", 9)
        )
        self._status_lbl.pack(anchor="w", padx=16, pady=(4, 2))

        btn_fr = tk.Frame(win, bg="#1e1e2e")
        btn_fr.pack(fill="x", padx=16, pady=12)

        def _btn(parent, text, cmd, accent=False):
            bg = "#cba6f7" if accent else "#313244"
            fg = "#1e1e2e" if accent else "#cdd6f4"
            return tk.Button(
                parent, text=text, command=cmd,
                bg=bg, fg=fg, activebackground="#b4befe", activeforeground="#1e1e2e",
                relief="flat", bd=0, padx=14, pady=7, cursor="hand2",
                font=("Segoe UI", 10, "bold" if accent else "normal")
            )

        _btn(btn_fr, "🔄 Сменить сейчас", self._change_now, accent=True).pack(side="left")
        _btn(btn_fr, "💾 Сохранить", self._save).pack(side="left", padx=8)
        _btn(btn_fr, "✖ Закрыть", win.destroy).pack(side="right")

        win.update_idletasks()

    def _collect_settings(self) -> dict:
        settings = load_settings()
        # Темы
        settings["themes"] = [k for k, v in self._theme_vars.items() if v.get()]
        if not settings["themes"]:
            settings["themes"] = ["nature"]
        settings["interval"] = self._interval_var.get()
        settings["show_calendar"] = self._show_cal_var.get()
        settings["calendar_opacity"] = self._opacity_var.get()
        settings["unsplash_key"] = self._unsplash_var.get().strip()
        settings["pexels_key"] = self._pexels_var.get().strip()
        return settings

    def _save(self):
        settings = self._collect_settings()
        save_settings(settings)
        self.scheduler.reset()
        self._status_lbl.config(text="✅ Настройки сохранены!", fg="#a6e3a1")
        self._win.after(2000, lambda: self._status_lbl.config(text="", fg="#6c7086"))

    def _change_now(self):
        settings = self._collect_settings()
        save_settings(settings)
        self._status_lbl.config(text="⏳ Загрузка…", fg="#f9e2af")
        self._win.update()

        def _worker():
            apply_wallpaper(settings, status_cb=lambda t: self._win.after(
                0, lambda: self._status_lbl.config(text=t, fg="#a6e3a1")
            ))

        threading.Thread(target=_worker, daemon=True).start()
        self.scheduler.reset()


# ════════════════════════════════════════════════════════════════════════════════
#  ТРЕЙ (pystray)
# ════════════════════════════════════════════════════════════════════════════════

def _make_tray_icon() -> Image.Image:
    """Генерирует простую иконку для трея (если нет .ico файла)."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Фиолетовый круг с буквой G
    draw.ellipse([2, 2, size - 2, size - 2], fill="#cba6f7")
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 36)
    except Exception:
        font = ImageFont.load_default()
    draw.text((16, 10), "G", font=font, fill="#1e1e2e")
    return img


def run_tray(scheduler: WallpaperScheduler, root: tk.Tk):
    """Запускает трей-иконку (блокирующий вызов в своём потоке)."""
    settings_win = SettingsWindow(scheduler, root)

    def on_double_click(icon, item):
        """Двойной клик — сменить обои сейчас."""
        threading.Thread(target=apply_wallpaper, daemon=True).start()
        scheduler.reset()

    def on_settings(icon, item):
        root.after(0, settings_win.show)

    def on_quit(icon, item):
        scheduler.stop()
        icon.stop()
        root.after(0, root.quit)

    # Загружаем иконку
    ico_path = Path(__file__).parent / "assets" / "icon.ico"
    if ico_path.exists():
        try:
            tray_img = Image.open(str(ico_path)).resize((64, 64))
        except Exception:
            tray_img = _make_tray_icon()
    else:
        tray_img = _make_tray_icon()

    menu = pystray.Menu(
        item("🔄 Сменить обои сейчас", on_double_click, default=True),
        item("⚙ Настройки…",           on_settings),
        pystray.Menu.SEPARATOR,
        item(f"GIN-Wallpaper {VERSION}", None, enabled=False),
        item("❌ Выход",                on_quit),
    )

    icon = pystray.Icon(APP_NAME, tray_img, f"{APP_NAME} {VERSION}", menu)
    icon.run()


# ════════════════════════════════════════════════════════════════════════════════
#  ТОЧКА ВХОДА
# ════════════════════════════════════════════════════════════════════════════════

def main():
    # Скрытое окно Tk как message pump (нужно для потокобезопасного UI)
    root = tk.Tk()
    root.withdraw()
    root.title(APP_NAME)

    settings = load_settings()
    scheduler = WallpaperScheduler()
    scheduler.start()

    if HAS_TRAY:
        # Трей в отдельном потоке
        t = threading.Thread(target=run_tray, args=(scheduler, root), daemon=True)
        t.start()
        root.mainloop()
    else:
        # Нет pystray — открываем окно настроек сразу
        log.warning("pystray не установлен — открываем настройки напрямую")
        win_settings = SettingsWindow(scheduler)
        win_settings.show()
        root.mainloop()


if __name__ == "__main__":
    main()

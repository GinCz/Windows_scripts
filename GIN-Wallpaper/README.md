# 🖼 GIN-Wallpaper-Calend v002

> **Умные обои с русским календарём для Windows** — лёгкий трей-апплет с установщиком  
> **Автор:** [GinCz / Vladimir Bulantsev ↗](https://github.com/GinCz)  
> **Репозиторий:** [Windows_scripts/GIN-Wallpaper ↗](https://github.com/GinCz/Windows_scripts/tree/main/GIN-Wallpaper)  
> **Лицензия:** MIT

---

## 🚀 Быстрый старт — Установка

**Скачать установщик:**  
[`GIN-Wallpaper-Calend_v002_Setup.exe`](https://github.com/GinCz/Windows_scripts/raw/main/GIN-Wallpaper/GIN-Wallpaper-Calend_v002_Setup.exe)

> **Запустить от имени Администратора** → следовать инструкциям → ✅ Готово!

Программа автоматически:
- Установится в `C:\Program Files\GIN-Wallpaper-Calend\`  
- Появится в **«Программы и компоненты»** (Settings → Apps)  
- Создаст ярлык на **рабочем столе** и в **меню Пуск**  
- Добавится в **автозагрузку** Windows  
- Скачает первые обои сразу после запуска

---

## ✨ Возможности

| Функция | Описание |
|---|---|
| 🖥 Трей-апплет | Висит в системном трее (справа снизу), не мешает работе |
| 🖱 Двойной клик | Мгновенно скачивает и устанавливает новые обои |
| 🗓 Календарь | Русский календарь в правом верхнем углу с выделением текущего дня |
| 🎨 8 тем | Космос, Природа, Авто, Города, Животные, Абстракция, Океан, Зима |
| ✅ Мультивыбор | Несколько тем сразу — картинки чередуются случайно |
| ⏱ Автосмена | Каждый час / 3ч / 6ч / раз в день |
| 📐 Нативное разрешение | Скачивает под точное разрешение вашего монитора |
| 🪶 Лёгкость | < 20 МБ RAM в фоновом режиме |
| 🗑 Uninstaller | Полное удаление через «Программы и компоненты» |

---

## 📐 Как работает календарь

Программа рисует поверх обоев (как на скриншоте):
- Полупрозрачный тёмный фон со скруглёнными углами
- **«5 ноября 2026 г.»** — заголовок
- Строка дней недели Пн–Вс (сб/вс — красные)
- Числа месяца в сетке — **текущий день выделен белым кружком**
- Позиция: **правый верхний угол**, отступ 24 px

---

## ⚙️ Настройки (ПКМ по иконке в трее → Настройки…)

### 🎨 Темы картинок
| Тема | Запрос |
|---|---|
| 🚀 Космос | space galaxy nebula stars |
| 🌿 Природа | nature landscape mountains forest |
| 🚗 Автомобили | supercar sports car automotive |
| 🌆 Города | city skyline urban architecture |
| 🦁 Животные | wildlife animals nature |
| 🎨 Абстракция | abstract art colorful digital |
| 🌊 Океан | ocean sea waves beach |
| ❄️ Зима | winter snow ice forest |

> Выберите **несколько тем** — программа случайно чередует их при каждой смене.

### 🔑 API-ключи (для высочайшего качества без лимитов)
- **Unsplash Client-ID** → [unsplash.com/developers ↗](https://unsplash.com/developers) — бесплатно
- **Pexels API Key** → [pexels.com/api ↗](https://www.pexels.com/api) — бесплатно  
- Без ключей: **Picsum Photos** (случайные фото HD, без регистрации)

---

## 🏗️ Сборка из исходников

### Шаг 1: Собрать Setup EXE (на Windows)
```bat
build_setup.bat
```
Результат: `GIN-Wallpaper-Calend_v002_Setup.exe`

> Требует: .NET Framework 4.x (для `csc.exe`) или PowerShell 5+

### Шаг 2: Запуск без установки (Python)
```bat
pip install Pillow pystray
pythonw gin_wallpaper.py
```

---

## 🗂 Структура проекта

```
GIN-Wallpaper/
├── GIN-Wallpaper-Calend_v002_Setup.exe  # ← Скачать и запустить!
├── installer_setup.cs                    # C# WinForms установщик
├── build_setup.bat                       # Сборка Setup EXE
├── gin_wallpaper.py                      # Python движок (обои + календарь)
├── requirements.txt                      # Pillow, pystray
├── version.json                          # Версия и метаданные
├── README.md                             # Документация
└── assets/
    ├── icon.ico                          # Иконка (256x256)
    └── icon.png                          # PNG версия
```

---

## 📋 Таблица версий

| Версия | Дата | Изменения |
|---|---|---|
| v002 | 2026-11-05 | Первый релиз: трей + календарь + 8 тем + автосмена + полноценный установщик |

---

## ❌ Удаление

**Способ 1:** Параметры Windows → Приложения → `GIN-Wallpaper-Calend` → Удалить  
**Способ 2:** `C:\Program Files\GIN-Wallpaper-Calend\Uninstall.exe`

Удаляет полностью: файлы, ярлыки, реестр, автозагрузку.

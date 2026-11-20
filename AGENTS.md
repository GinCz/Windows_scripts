# 🤖 Windows Projects Master Standards & Directives (`AGENTS.md`)
> Universal standard for AI agents working in `GinCz/Windows_scripts`: maximum autonomy, strict versioning, and deterministic delivery.
> Repository: GinCz/Windows_scripts | Author: Vladimir Bulantsev (@GinCz)

---

## ⭐️ ЖЕЛЕЗНОЕ ПРАВИЛО: ОБЯЗАТЕЛЬНЫЙ ИНКРЕМЕНТ ВЕРСИИ И ДОСТАВКА В MEGA DESKTOP

1. **Обязательный инкремент версии на каждое изменение:**
   - При любом изменении исходного кода, исправлении багов или добавлении функционала версия приложения **ОБЯЗАТЕЛЬНО повышается** (`v043` ➔ `v044`).
   - Перезапись релизного бинарника с сохранением прежнего номера версии категорически запрещена.

2. **Имя установщика строго с версией:**
   - Формат имени файла установщика: `<AppName>_vXXX_Setup.exe` (например: `GIN-Desktop_v043_Setup.exe`, `GIN-DNS-Switch_v041_Setup.exe`).

3. **Обязательное копирование на Рабочий стол через Облако MEGA:**
   - Каждый скомпилированный `.exe` файл установщика при сборке **ОБЯЗАТЕЛЬНО копируется в `D:\MEGA\DOCS\desktop\`** через облако MEGA (`/MEGA/DOCS/desktop/`).
   - Это Рабочий стол Владимира на домашнем ПК. Доставка выполняется автоматически через скрипт `scripts/sync_mega_desktop.sh` (используя `mega-put -c "<App>_vXXX_Setup.exe" "/MEGA/DOCS/desktop/"`).

4. **Ротация версий (строго 2 последние):**
   - В облаке MEGA (`/MEGA/DOCS/desktop/`) и в релизных каталогах репозитория сохраняются **строго 2 последние версии** приложения, более старые удаляются (`mega-rm`).

---

## 🪟 ТЕХНИЧЕСКИЕ СТАНДАРТЫ WINDOWS
* **Win32 PE Свойства:** В свойствах компилируемого `.exe` (`VERSIONINFO`) обязательно указывать:
  - `LegalCopyright`: `VladiMIR+AI`
  - `CompanyName`: `VladiMIR+AI`
  - `FileDescription`: `<AppName>_vXXX`
  - `ProductName`: `<AppName>_vXXX`
  - `ProductVersion`: `vXXX`
  - `FileVersion`: `0.XXX.0.0`
* **Кодировка и переводы строк:** Windows batch файлы (`.bat`, `.cmd`) **СТРОГО в Windows CRLF (`\r\n`)**. Исходники C#, Go, Python — UTF-8 без BOM.
* **Категорический запрет сетевых папок Server_222:** В сетевые папки `/storage/soft/` Windows-установщики больше не пишутся! Доставка — только MEGA Desktop.

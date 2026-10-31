# 🔒 GIN-Win-Optimizer — Private Master Source Repository

> **Private Repository:** [Secret_Privat / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-Win-Optimizer)  
> **Public Mirror:** [Windows_scripts / Windows / GIN-Win-Optimizer ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Win-Optimizer)  
> **Author / Architect:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Target OS:** Windows 10 / 11 (x86_64, all editions: Home, Pro, Enterprise, LTSC)  
> **Current Version:** `v030` (Active)  
> **Retention Policy:** Strictly **2 latest production versions** (`v030` and `v028`).

---

## 🏛️ Двухрепозиторная Архитектура и Правила Хранения Исходников

По прямому архитектурному регламенту владельца проекта (Владимира Буланцева):

1. **Исходники — ТОЛЬКО в приватном репозитории:**
   - Все исполняемые исходные скрипты (`GIN-Win-Optimizer_v*.cmd`) и внутренняя конфигурация хранятся **исключительно в приватном репозитории `Secret_Privat`**.
   - В публичном репозитории `Windows_scripts` публикуется **только подробная англоязычная документация (`README.md`), история изменений (`CHANGELOG.md`) и метаданные версий (`version.json`)**. Исполняемые файлы в публичный репозиторий НЕ выкладываются.

2. **Точные пути хранения исполняемых файлов (Две последние версии):**
   - На всех рабочих носителях скрипт хранится строго в каталоге `\WIN-FLASH\Util-WINDOWS\`:
     - **Физическая USB-флешка Ventoy:** `V:\WIN-FLASH\Util-WINDOWS\`
     - **Локальное облачное зеркало MEGA:** `D:\MEGA\WIN-FLASH\Util-WINDOWS\`
     - **Облачный удалённый каталог MEGA:** `/MEGA/WIN-FLASH/Util-WINDOWS/`
     - **Серверный постоянный кэш DE-222:** `/root/AI_222/cache/win_opt/`
   - **Правило ротации (Strict 2 Latest Versions):**
     - Хранятся **строго 2 последние версии** скрипта:
       1. Актуальная (Current): `GIN-Win-Optimizer_v027.cmd`
       2. Предыдущая (Backup): `GIN-Win-Optimizer_v025.cmd`
     - Все более старые версии (`v016`, `v015` и т.д.) автоматически удаляются с носителей при релизе нового билда.

3. **Категорический запрет на копирование на Рабочий стол:**
   - На Рабочий стол (`D:\MEGA\DOCS\desktop\`) скрипт **НЕ копируется**. Рабочий стол остаётся чистым.

---

## 🖥️ Сводная Таблица Целевых Путей Развёртывания

| Среда / Носитель | Полный путь к файлу | Назначение | Политика хранения |
| :--- | :--- | :--- | :---: |
| 💾 **USB Flash Drive (Ventoy)** | `V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v028.cmd`<br>`V:\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v027.cmd` | Физическая рабочая загрузочная флешка сисадмина | Ровно 2 последние версии |
| ☁️ **MEGA Win-Flash Mirror** | `D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v028.cmd`<br>`D:\MEGA\WIN-FLASH\Util-WINDOWS\GIN-Win-Optimizer_v027.cmd` | Локальная папка облака MEGA для синхронизации | Ровно 2 последние версии |
| ☁️ **MEGA Cloud Remote** | `/MEGA/WIN-FLASH/Util-WINDOWS/GIN-Win-Optimizer_v028.cmd` | Центральное облачное хранилище утилит | Ровно 2 последние версии |
| 🗄️ **Server Permanent Cache** | `/root/AI_222/cache/win_opt/GIN-Win-Optimizer_v028.cmd` | Постоянный резервный кэш на ноде DE-222 | Долговременный архив |
| 🔒 **Private Git Repository** | `Secret_Privat/Windows/GIN-Win-Optimizer/` | **Основное хранилище исходного кода проекта** | Полная история Git |
| 🌐 **Public Git Repository** | `Windows_scripts/Windows/GIN-Win-Optimizer/` | Публичное зеркало документации (English) | Только документация |
| 🚫 **Рабочий стол пользователя** | `D:\MEGA\DOCS\desktop\` | — | **Копирование запрещено** |

---

## ⚡ Автономный Конвейер Деплоя Новой Версии (vXXX)

При выпуске новой версии `vXXX` агент выполняет:

```bash
# 1. Сборка нового скрипта GIN-Win-Optimizer_vXXX.cmd с повышением версии (v028)
# 2. ОБЯЗАТЕЛЬНАЯ доставка в облако MEGA (откуда синхронизируется D:\MEGA\WIN-FLASH\Util-WINDOWS\):
mega-put /root/github_templates/Windows/GIN-Win-Optimizer/GIN-Win-Optimizer_vXXX.cmd "MEGA/WIN-FLASH/Util-WINDOWS/"

# 3. Очистка старых версий в MEGA (хранятся строго 2 последние версии):
mega-rm "MEGA/WIN-FLASH/Util-WINDOWS/GIN-Win-Optimizer_v<XXX-2>.cmd"

# 4. Копирование на локальные носители при запуске с флешки:
# Copy-Item "GIN-Win-Optimizer_vXXX.cmd" "V:\WIN-FLASH\Util-WINDOWS\" -Force

# 5. Обновление документации:
#    - В Secret_Privat: README.md, version.json, CHANGELOG.md + коммит с исходниками
#    - В Windows_scripts: README.md (English), version.json, CHANGELOG.md (БЕЗ исходников .cmd)
```

---

## 🛡️ Ключевые Технические Характеристики (v024)

- **106 системных твиков Dism++:** Телеметрия, безопасность UAC, очистка проводника, службы.
- **Глобальный вид папок «Список» и сортировка по типу:** Автоматически через `Bags\AllFolders\Shell` и `FolderTypes`.
- **Все значки трея открыты:** `EnableAutoTray = 0`, политика `NoAutoTray = 1`, `IsPromoted = 1` для Win11.
- **Открепление IE и Edge:** Полная очистка User Pinned TaskBar и блокировка через GPO.
- **Скрытие кнопки People:** `PeopleBand = 0` и `HidePeopleBar = 1` через реестр и GPO.
- **Гарантированный значок «Этот компьютер»:** 4 ветки `HideDesktopIcons` + системный shell-ярлык.
- **Последовательная очистка Cleanmgr:** Сначала C: с ожиданием завершения, затем D:.
- **Красные пункты для долгих настроек:** `chk_deep_dism_repair` и `chk_deep_dism_resetbase` наверху списка, отключены по умолчанию, с пометкой `(slow - медленно)`.

# 🪐 Железные Правила и Архитектурные Инварианты: GIN-Voice

> **Проект:** GIN-Voice by VladiMIR+AI  
> **Репозиторий:** [Windows_scripts / GIN-Voice ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice)  
> **Владелец:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz))  
> **Статус:** Обязательно к неукоснительному соблюдению при каждом изменении  

---

## ⚡ 1. Железное Правило Версионирования и Метаданных Windows PE (Strict Version & PE Metadata Increment)
1. **Любое малейшее изменение повышает версию:**
   - Каждое, даже самое минимальное изменение исходного кода, исправление бага, улучшение интерфейса, добавление параметра, оптимизация или обновление документации **ОБЯЗАТЕЛЬНО увеличивает номер версии проекта**.
2. **Формат номера версии — строго три цифры:**
   - Номер версии всегда записывается буквой `v` и тремя цифрами: например, `v003`, `v041`, `v105`.
3. **Обязательное указание версии в названии файла установщика:**
   - **В названии файла установщика ОБЯЗАТЕЛЬНО должна быть версия:** `GIN-Voice_Setup_vXXX.exe` (например, `GIN-Voice_Setup_v044.exe`).
   - Для совместимости также собирается файл `GIN-Voice_Setup.exe`.
   - При сборке каждого релиза установщик с версией (`GIN-Voice_Setup_vXXX.exe`) и файл `GIN-Voice_Setup.exe` синхронно копируются строго в **ОБА целевых места**:
     1. **Рабочий стол Владимира:** `D:\MEGA\DOCS\desktop` (`/MEGA/DOCS/desktop/`)
     2. **Папка на флешке:** `D:\MEGA\WIN-FLASH\Util-WINDOWS\MUSIC` (`/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/`)
   - **Правило ротации версий:** сохраняются строго **2 последние версии** установщика (`vXXX`), устаревшие версии автоматически удаляются.
4. **Обязательное заполнение свойств .exe файла (Windows PE VERSIONINFO):**
   - В свойствах `.exe` файла (ресурс `VERSIONINFO`, компилируемый через `app.rc` и `windres`) данные прописываются полностью:
     - `LegalCopyright`: строго `VladiMIR+AI` (запрещено писать «Буланцев», «GinCz», «Гот» и т.п.);
     - `CompanyName`: `VladiMIR+AI`;
     - `FileDescription`: `<AppName>_vXXX` (например `GIN-Voice_v044`);
     - `ProductName`: `<AppName>_vXXX` (например `GIN-Voice_v044`);
     - `ProductVersion`: `vXXX` (например `v044`);
     - `FileVersion` (StringFileInfo): `vXXX` (например `v044`);
     - `FileVersion` (бинарная структура `VS_FIXEDFILEINFO`): `0.XXX.0.0` (например `0.44.0.0`);
     - `Language`: English (`0x0409, 0x04b0` / 1200 Unicode);
     - `Дата изменения`: сохраняется системная дата сборки / файла.
   - При подведении курсора мыши в Проводнике Windows во всплывающей подсказке и во вкладке «Подробно» свойств файла номер версии, описание `<AppName>_vXXX` и автор `VladiMIR+AI` отображаются на 100%.
5. **Синхронное обновление всех файлов версии:**
   - При повышении версии синхронно обновляются:
     - `app.rc` и пересобирается `rsrc_windows_amd64.syso`;
     - Константы `AppVersion` и `AppTitle` в `main.go`;
     - `version.json` и `version.txt`;
     - `CHANGELOG.md`, `README.md`, `HELP.md` и `setup_guide.html`.

---

## 🖥️ 2. Доставка Бинарников — Строго на Рабочий Стол Владимира и на Флешку в MUSIC (`D:\MEGA\DOCS\desktop` и `D:\MEGA\WIN-FLASH\Util-WINDOWS\MUSIC`)
1. **Тотальный запрет записи на Server_222:**
   - **В сетевую папку на диск на Server_222 мы больше НЕ записываем!** Категорически запрещено записывать скомпилированные файлы на серверные шары DE-222 (`/storage/soft/...`, `S:\soft\...`, `\\DE-222\...`).
2. **Обязательная доставка в ДВА целевых места в облаке MEGA:**
   - При каждом релизе или обновлении версии агент **ОБЯЗАН копировать последнюю скомпилированную версию установщика с версией в названии (`GIN-Voice_Setup_vXXX.exe`) и файл `GIN-Voice_Setup.exe` строго в ОБА места:**
     - **1. Рабочий стол Владимира:**  
       - Локальный путь у Владимира: `D:\MEGA\DOCS\desktop`  
       - Облачный путь в MEGA: `/MEGA/DOCS/desktop/` (команда: `mega-put -c "GIN-Voice_Setup_vXXX.exe" "/MEGA/DOCS/desktop/"`)
     - **2. Папка на флешке:**  
       - Локальный путь у Владимира: `D:\MEGA\WIN-FLASH\Util-WINDOWS\MUSIC`  
       - Облачный путь в MEGA: `/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/` (команда: `mega-put -c "GIN-Voice_Setup_vXXX.exe" "/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/"`)
3. **Обязательное присутствие номера версии в названии:**
   - Файл установщика обязан иметь в названии суффикс версии: `GIN-Voice_Setup_vXXX.exe` (например, `GIN-Voice_Setup_v044.exe`).
4. **Правило ротации версий (Strict 2 Latest Versions):**
   - И на Рабочем столе (`/MEGA/DOCS/desktop/`), и в папке флешки (`/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/`) удерживаются строго **2 последние версии** установщика (`GIN-Voice_Setup_v*.exe`). Устаревшие релизы автоматически удаляются.

---

## 🔒 3. Разделение Приватных и Публичных Репозиториев
1. **Исходный код — ТОЛЬКО в приватных репозиториях:**
   - Все исходные файлы (`main.go`, `build.sh`, `app.rc`, `rsrc_*.syso`, внутренние конфиги) хранятся **ТОЛЬКО В ПРИВАТНОМ РЕПОЗИТОРИИ** (`Secret_Privat`).
2. **Публичные репозитории:**
   - В публичных репозиториях (`Windows_scripts`, `Linux_Server_Public`) в папке `Windows/GIN-Voice/` размещаются **ТОЛЬКО описание на английском языке (`README.md` strictly in English)** и **сам скомпилированный релизный бинарник/установщик (`GIN-Voice.exe`, `GIN-Voice_Setup.exe`)**. Исходный код в публичные репозитории не выкладывается.

---

## 🔄 2. Железный Регламент Автообновления, Синхронизации с GitHub и Доставки на Рабочий Стол (Zero-Desync & MEGA Pipeline)
1. **Архитектура обновления:**
   - Пункт контекстного меню в трее **«Проверить обновление»** опрашивает GitHub raw URL:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json`
   - И загружает бинарник:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/GIN-Voice.exe`
2. **Обязательная доставка на Рабочий Стол Владимира (`D:\MEGA\DOCS\desktop`) и на Флешку (`D:\MEGA\WIN-FLASH\Util-WINDOWS\MUSIC`):**
   - Для всех Windows-приложений: все новые скомпилированные установщики с версией (`GIN-Voice_Setup_vXXX.exe`) и файл `GIN-Voice_Setup.exe` копируются строго в два целевых места:
     1. **Рабочий стол Владимира:** `D:\MEGA\DOCS\desktop` (`/MEGA/DOCS/desktop/` в MEGA)
     2. **Папка на флешке:** `D:\MEGA\WIN-FLASH\Util-WINDOWS\MUSIC` (`/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/` в MEGA)
   - Скрипт `build.sh` автоматически выгружает обе версии (`GIN-Voice_Setup_vXXX.exe` и `GIN-Voice_Setup.exe`) в обе целевые папки MEGA.
3. **Строгая последовательность релиза:**
   1. Компиляция бинарников с полными свойствами PE (`rsrc_windows_amd64.syso`, `GIN-Voice.exe`, `GIN-Voice_Setup_vXXX.exe`, `GIN-Voice_Setup.exe`).
   2. Синхронное обновление всех файлов версии (`version.txt`, `version.json`, `app.rc`, `CHANGELOG.md`, `README.md`, `HELP.md`).
   3. `git add`, `git commit` и `git push origin main` на GitHub в репозитории `Secret_Privat` и `Windows_scripts`.
   4. Проверка доступности через curl:  
      `curl -s https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json` возвращает актуальную версию.
   5. Выгрузка в `/MEGA/DOCS/desktop/` и `/MEGA/WIN-FLASH/Util-WINDOWS/MUSIC/` с сохранением строго 2 последних версий установщика (`vXXX`).
   6. Контроль чистоты: на Рабочем столе и на флешке хранятся strictly 2 актуальные версии с номерами версий в названии для быстрого отката при необходимости.

---

## 🛑 3. Неприкосновенность Инсталлятора на Рабочем столе (Installer Preservation)
1. При запуске деинсталлятора (`Uninstall.exe` или скриптов удаления) **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО** удалять установщик `GIN-Voice_Setup.exe` с Рабочего стола или из папок пользователя.
2. Деинсталлятор удаляет **ТОЛЬКО ярлыки** (`GIN-Voice.lnk`), чтобы пользователь в любой момент мог снова запустить инсталлятор с Рабочего стола.

---

## 🧹 4. Гарантированное Завершение Процессов и Чистая Деинсталляция (Complete Purge)
1. Завершение работы перед деинсталляцией или обновлением выполняется по 4-уровневой схеме:
   - `taskkill /F /IM GIN-Voice.exe /T`
   - `taskkill /F /FI "IMAGENAME eq GIN-Voice*"`
   - PowerShell `Get-Process | Stop-Process -Force`
   - Fallback `wmic process where name like 'GIN-Voice%' call terminate`.
2. Удаление рабочей папки `%LOCALAPPDATA%\GIN-Voice` выполняется через отложенный процесс (`del_after.bat`), ожидающий завершения родительского процесса во избежание блокировки Windows `ERROR_ACCESS_DENIED`.

---

## 🎙️ 5. Сохранение Хвоста Речи (Trailing Speech Buffer Protection)
1. Запрещено использовать агрессивную обрезку тишины, отрезающую окончание слов.
2. Перед остановкой потока записи `waveIn` всегда удерживается 200 мс буферный флаш, гарантируя, что последнее сказанное слово полностью попадет в аудиофайл для транскрипции.

---

## 🧠 6. Защита от Зацикливания Whisper и Санитария Промпта (Loop Guard)
1. Промпт подсказки для Whisper Large v3 формируется динамически и **строго ограничивается максимум 12 терминами**. Перегрузка промпта вызывает галлюцинации и зацикливание декодера.
2. Функция `cleanHallucinations()` обязана содержать фильтр `removeRepetitiveLoops()`, который автоматически срезает повторяющиеся цепочки брендов и зацикленные фразы в конце транскрипции.

---

## 💾 7. Сохранение Ключей и Настроек при Обновлении (Zero-Data-Loss)
1. При любом обновлении (как через трей-апдейтер, так и повторным запуском `Setup_vXXX.exe`) файл `config.json` и `dictionary.json` сохраняются на 100%.
2. Пользовательский Groq API-ключ, путь к базе, выбранный шрифт HUD и персональные словарные замены никогда не затираются.

---

## 🏷️ 8. ПРАВИЛО НАИМЕНОВАНИЯ ЧАТОВ И ТЕМ (Chat Title Naming Convention)
- Тема чата всегда строго в формате: `GIN-Voice - <Краткое описание задачи>`.

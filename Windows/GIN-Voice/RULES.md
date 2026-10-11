# 🪐 Правила Проекта: GIN-Voice

> **Проект:** GIN-Voice by VladiMIR+AI  
> **Репозиторий:** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice)  
> **Владелец:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz))  

---

## ⚡ 1. Железное Правило Версионирования (Strict Version Increment)
1. **Любое малейшее изменение повышает версию:**
   - Каждое, даже самое минимальное изменение исходного кода, исправление бага, улучшение интерфейса, добавление параметра, оптимизация или обновление документации **ОБЯЗАТЕЛЬНО увеличивает номер версии проекта** (например, `v017` -> `v018` -> `v019`).
2. **Синхронное обновление всех файлов версии:**
   - При повышении версии синхронно обновляются:
     - Константы `AppVersion` и `AppTitle` в `main.go`;
     - `version.json` и `version.txt`;
     - `README.md`, `HELP.md` и `setup_guide.html`.
3. **Единственный установщик на Рабочем столе (MEGA Sync):**
   - На Рабочем столе Владимира в Облаке MEGA (`/MEGA/DOCS/desktop/`) должен находиться **СТРОГО ОДИН файл** — установщик последней актуальной версии с номером версии в имени (например: `GIN-Voice_Setup_v018.exe`).
   - Категорически запрещено оставлять дубликаты без версии (`GIN-Voice.exe`) или старые версии.

---

## 🔄 2. Железный Регламент Автообновления и Синхронизации с GitHub (Zero-Desync Rule)
1. **Архитектура встроенного обновления:**
   - Пункт контекстного меню в трее **«Проверить обновление»** и фоновый автоапдейтер проверяют эндпоинт:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json`
   - При наличии более новой версии скачивается бинарник:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/GIN-Voice.exe`
2. **Категорический запрет рассинхрона (MEGA без GitHub):**
   - Запрещено выкладывать новый установщик в MEGA (`/MEGA/DOCS/desktop/`) без **одновременного коммита и пуша на GitHub (`git push origin main`)**.
   - Если установщик на Рабочем столе уже обновлен, а в GitHub осталась старая версия `version.json` — запущенная программа при проверке обновлений ложно утверждает: *«У вас последняя версия»* и блокирует автоматический переход.
3. **Строгий чеклист любого релиза (Release Pipeline):**
   1. Компиляция бинарников (`GIN-Voice.exe`, `GIN-Voice_Setup_vXXX.exe`, `GIN-Voice_vXXX.exe`).
   2. Синхронное обновление `AppVersion` в `main.go`, `version.json`, `version.txt`, `README.md`, `HELP.md`, `setup_guide.html`.
   3. `git add`, `git commit` и `git push origin main` на GitHub.
   4. Проверка доступности:  
      `curl -s https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json` возвращает новую версию `vXXX`.
   5. Очистка старой версии и выгрузка нового инсталлятора в `/MEGA/DOCS/desktop/`.
   6. Контроль: ровно один актуальный файл установщика на Рабочем столе.

---

## 🏷️ ПРАВИЛО НАИМЕНОВАНИЯ ЧАТОВ И ТЕМ (Chat Title Naming Convention)
- Тема чата всегда строго в формате: `GIN-Voice - <Краткое описание задачи>`.

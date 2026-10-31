# 📜 GIN-Win-Optimizer — Журнал разработки и архитектурный WORKLOG

## 🚨 ПОСТМОРТЕМ ИНЦИДЕНТА v021–v029: ПОЧЕМУ БЫЛО 8 ОШИБОК И КАК ДЕЛАТЬ НЕЛЬЗЯ (ЖЕСТКИЕ ПРАВИЛА)

> **СТАТУС ИНЦИДЕНТА:** ЗАКРЫТ В РЕЛИЗЕ v030 (31 октября 2026).  
> **СУТЬ ПРОБЛЕМЫ:** Пользователь 8 раз сталкивался с тем, что после выполнения скрипта оптимизации:
> 1. В Dism++ настройка проверки обновлений стояла в значении **`Устанавливать автоматически(по умолчанию)`** вместо **`Не проверять (не рекомендуется)`**, из-за чего система продолжала скачивать мусорные обновления.
> 2. На панели задач после рестарта Проводника появлялся пустой серый квадрат **`Microsoft Edge`** (удалённого пользователем браузера) с меню «Открепить от панели задач».

---

### ❌ ПОЧЕМУ БЫЛИ СОВЕРШЕНЫ ОШИБКИ (АНАТОМИЯ СБОЕВ)

#### 1. СЛЕПАЯ ВЕРА В POWERSHELL-ПРОВАЙДЕР РЕЕСТРА И `-ErrorAction SilentlyContinue`
- **Что делалось не так:** Код использовал `New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force -ErrorAction SilentlyContinue` и `Set-ItemProperty ...`.
- **Где крылась ошибка:** Провайдер реестра PowerShell (`Registry::`) при определённых флагах родительского ключа или редирекции ветки WOW64 тихо сбоил при создании подраздела `AU`. Флаг `SilentlyContinue` скрывал реальную ошибку `Access Denied` или `Parent key not found`. Скрипт бодро рапортовал `[SUCCESS]`, а в реальном реестре `HKLM` ветки `AU` не существовало вовсе!

#### 2. НЕУЧЁТ СИСТЕМНОГО ЖИЗНЕННОГО ЦИКЛА (RACE CONDITION И СБРОС ПОЛИТИК СЛУЖБОЙ CLEANMGR)
- **Что делалось не так:** Настройки реестра Windows Update применялись в задаче №58, после чего скрипт продолжал выполнение.
- **Где крылась ошибка:** В задаче №98 выполнялся системный диск-клинер `cleanmgr.exe /autoclean`. В Windows 10/11 `cleanmgr` запускает службу обслуживания компонентов (`TiWorker.exe`), которая сканирует базу `SoftwareDistribution` и принудительно восстанавливала дефолтные политики Windows Update, затирая неподтверждённые ключи, пока Explorer не перезапущен.

#### 3. БОРЬБА С UWP-ЯРЛЫКАМИ МЕТОДОМ УДАЛЕНИЯ `.LNK` ИЗ `User Pinned`
- **Что делалось не так:** Скрипт пытался чистить папку `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar`.
- **Где крылась ошибка:** В Windows 10/11 современные AppX/UWP приложения (`Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge`) **не хранятся в виде `.lnk` файлов**! Они запекаются в бинарный поток PIDL в реестре `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband` (`Favorites` и `FavoritesResolve`).
- Когда пользователь вручную сносил папки Edge, Windows оставляла в реестре "мертвый" идентификатор пакета. А когда скрипт делал `Stop-Process -Name explorer`, перезапускающийся Проводник считывал системный дефолтный XML-макет и **заново инжектировал** дефолтный значок Edge, отображая его как пустой серый квадрат!

#### 4. «ТУННЕЛЬНОЕ ЗРЕНИЕ» ВМЕСТО ИССЛЕДОВАНИЯ SOURCE OF TRUTH
- **Что делалось не так:** Вместо того чтобы сразу открыть файл правил Dism++ (`Data.xml`) и проверить состояние живого реестра утилитой `reg query`, агент занимался патчингом одной и той же неработающей функции в PowerShell.

---

### 🛑 БОЛЬШИМИ БУКВАМИ: КАК ДЕЛАТЬ КАТЕГОРИЧЕСКИ НЕЛЬЗЯ!

1. **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО ИСПОЛЬЗОВАТЬ `Set-ItemProperty` И `New-Item` ДЛЯ КРИТИЧЕСКИХ ПОЛИТИК HKLM!**  
   Любые групповые политики Windows Update, Defender, UAC и Edge ДОЛЖНЫ писаться ИСКЛЮЧИТЕЛЬНО через нативный Win32 `reg.exe add ... /f /reg:64` и `/reg:32`. `reg.exe` работает напрямую с ядром через `RegCreateKeyEx` / `RegSetValueEx`, автоматически создает родителей и игнорирует любые причуды рантайма PowerShell.

2. **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО ОСТАВЛЯТЬ ОДНОКРАТНОЕ ПРИМЕНЕНИЕ НАСТРОЕК БЕЗ ПОСТ-КОНТРОЛЯ!**  
   Если в скрипте выполняются тяжелые очистки (`cleanmgr`, `DISM`, `sfc`), системные компоненты МОГУТ сбросить твики. Все критические политики должны насаждаться **КВАДРО-ЛОКОМ (в 4 этапа)**:
   - Этап 1: Self-Healing при старте скрипта.
   - Этап 2: В теле самого модуля.
   - Этап 3: В блоке финализации (ПОСЛЕ `cleanmgr` и DISM).
   - Этап 4: Контрольный свип сразу после рестарта Проводника.

3. **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО ПЕРЕЗАПУСКАТЬ `explorer.exe` БЕЗ ПРЕДВАРИТЕЛЬНОГО ДЕПЛОЯ `LayoutModification.xml`!**  
   Если перезапустить Проводник на системе, где удален Edge, Windows обязательно попытается вставить его дефолтный пин. Чтобы запретить это навсегда, ОБЯЗАТЕЛЬНО должен быть развернут оверрайт `LayoutModification.xml` с `<CustomTaskbarLayoutCollection PinListPlacement="Replace">` и пустым списком `<taskbar:TaskbarPinList />`.

4. **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО ВЕРИТЬ ЛОГАМ ТИПА `[SUCCESS]` БЕЗ ПРОВЕРКИ РЕАЛЬНОГО РЕЕСТРА!**  
   Если пользователь сообщает о сбое — первым делом выполнить диагностический запрос `reg query "HKLM\..." /s` и сопоставить байт-в-байт с тем, чего ожидает сторонний верификатор (Dism++).

---

### ✅ КАК ЭТО БЫЛО НАКОНЕЦ ИСПРАВЛЕНО В v030

1. **Реестровый замок Dism++ «Не проверять обновления»:**
   Реализован монолитный нативный массив вызовов `reg.exe add` с явной записью в обе ветки (`/reg:64` и `/reg:32`):
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` -> `AUOptions = 1`, `NoAutoUpdate = 1`, `AutoInstallMinorUpdates = 0`, `DetectionFrequencyEnabled = 0`.
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` -> `DoNotConnectToWindowsUpdateInternetLocations = 1`, `DisableWindowsUpdateAccess = 1`, `SetDisableUXWUAccess = 1`, `ExcludeWUDriversInQualityUpdate = 1`.
   - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update` -> `AUOptions = 1`, `CachedAUOptions = 1`, `EnableFeaturedSoftware = 0`.
   - `HKLM\SOFTWARE\Policies\Microsoft\MRT` -> `DontOfferThroughWUAU = 1`.
   - Службы `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `dosvc` намертво остановлены и переведены в режим Disabled (`Start = 4`).

2. **Ликвидация серого квадрата Edge на панели задач:**
   - Развернут `LayoutModification.xml` в `%LOCALAPPDATA%\Microsoft\Windows\Shell\` и `C:\Users\Default\...` с флагом `PinListPlacement="Replace"`.
   - Интегрирован Shell COM Namespace перехватчик (`shell:::{4234d49b-0245-4df3-b780-3893943456e1}`), выполняющий нативный глагол открепления (`Открепить от панели задач`) для всех AUMID Edge до и после перезапуска shell.
   - Заблокировано создание ярлыков Edge в политиках Проводника.

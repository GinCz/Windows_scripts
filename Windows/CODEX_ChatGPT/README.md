# 🤖 OpenAI Codex & ChatGPT Desktop — Universal Windows Installer

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-0078D4?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Architecture](https://img.shields.io/badge/Architecture-x64-blue)](https://openai.com)
[![Package](https://img.shields.io/badge/Package-OpenAI.Codex-10a37f?logo=openai&logoColor=white)](https://openai.com/codex/)
[![Store Bypass](https://img.shields.io/badge/Microsoft%20Store-Bypass%20Direct-success)](https://store.rg-adguard.net)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%20Bulantsev%20(GinCz)-orange)](https://github.com/GinCz)

> **Автономный монолитный CMD-установщик приложения ChatGPT Desktop с встроенным AI-агентом Codex для Windows 10 и 11 без необходимости открывать или восстанавливать Microsoft Store.**

---

## 📌 Описание (Overview)

Официальное настольное приложение ChatGPT для Windows (`OpenAI.Codex`) включает полнофункционального агентского помощника **Codex** для планирования, анализа и написания кода.

Обычно установка приложения требует перехода в Microsoft Store, что часто вызывает сбои при повреждении служб магазина (`wsreset`, ошибки авторизации, сбои AppX Delivery Optimization или корпоративные ограничения).

**`Install_ChatGPT_Codex_Universal.cmd`** решает эту проблему раз и навсегда:
* 🚀 **100% Zero-Dependency (Всё в одном файле):** Никаких внешних скриптов, архивов или Python рядом. Только один чистый `.cmd` файл.
* 🛡️ **Автоматический UAC-Elevation:** При запуске скрипт автоматически запрашивает права Администратора и перезапускается в привилегированном контексте.
* ⚡ **Прямой опрос Store CDN (Product ID `9PLM9XGG6VKS`):** Напрямую обращается к официальным серверам доставки Microsoft/OpenAI, находит самую свежую версию `.msixbundle` / `x64.msix` и скачивает её.
* 📦 **Нативная установка через Windows AppX API:** Разворачивает пакет командой `Add-AppxPackage` в обход графического интерфейса магазина.
* 🔄 **Автоматический Fallback:** Если прямой запрос к CDN недоступен, автоматически пытается установить пакет через CLI `winget install --id 9PLM9XGG6VKS -s msstore`.
* 🔔 **Звуковое оповещение:** Проигрывает системный колокольчик `chimes.wav` по завершении установки.

---

## 🚀 Быстрый запуск (Quick Start)

### Вариант 1: Запуск готового CMD-файла
1. Скачайте файл [`Install_ChatGPT_Codex_Universal.cmd ↗`](Install_ChatGPT_Codex_Universal.cmd).
2. Запустите его двойным кликом мыши на любом компьютере с Windows 10/11 (x64).
3. Подтвердите запрос UAC (Контроль учетных записей).
4. Дождитесь завершения скачивания и установки. Приложение появится в меню **«Пуск»**.

### Вариант 2: Запуск одной строкой в PowerShell (от Администратора)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/CODEX_ChatGPT/Install_ChatGPT_Codex_Universal.cmd'; $dest = \"$env:TEMP\Install_ChatGPT_Codex_Universal.cmd\"; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Start-Process cmd.exe -ArgumentList \"/c `\"$dest`\"\" -Verb RunAs }"
```

---

## 🛠️ Технические подробности (Technical Details)

| Параметр | Значение |
| :--- | :--- |
| **Product ID (Microsoft Store)** | `9PLM9XGG6VKS` |
| **Официальное имя пакета** | `OpenAI.Codex` (`OpenAI.Codex_26.901.4073.0_x64__2p2nqsd0c76g0`) |
| **Разработчик** | OpenAI (`CN=50BDFD77-8903-4850-9FFE-6E8522F64D5B`) |
| **Формат пакета** | Store-Signed `MSIXBundle` / `MSIX` |
| **Поддерживаемые ОС** | Windows 10 Pro / Home (x64, билд 19041+), Windows 11 (x64) |
| **Требования к лицензии** | Учетная запись OpenAI (Free / Plus / Pro / Team для использования агента Codex) |

---

## 📁 Структура директории

```text
Windows/CODEX_ChatGPT/
├── Install_ChatGPT_Codex_Universal.cmd   # Универсальный автономный установщик
└── README.md                             # Документация и руководство
```

---

## 👤 Автор и поддержка (Author & Support)

* **Автор:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz))
* **Репозиторий:** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)
* **Email:** `gin@volny.cz` / `gin.vladimir@gmail.com`

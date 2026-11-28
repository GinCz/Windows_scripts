# 📋 План обновлений GIN-Desktop v053: Устранение моргания и режим «Только иконки»

## 1. Диагностика и устранение моргания (Flicker / Loop Show-Hide)

### Причина бага:
В версии `v052` докер был отцентрирован по горизонтали экрана:
`posX = screen.Bounds.Left + (screen.Bounds.Width - width) / 2`.
При этом сторожевой таймер (`WatchdogTimer_Tick`, интервал 50 мс) проверял наведение курсора в верхний левый угол (`inHotCorner`):
1. Курсор попадает в левый верхний угол (`inHotCorner == true`) ➔ вызывается `ShowDock()`.
2. Докер появляется в **центре** экрана, а флаг `_isDockVisible` становится `true`.
3. На следующем тике таймера (через 50 мс) курсор всё ещё в левом верхнем углу, но проверка `this.Bounds.Contains(cursor)` возвращает `false`, так как докер находится в центре!
4. Сторожевой таймер считает, что курсор вне докера, наращивает счетчик `_outOfBoundsTicks` и через ~200 мс вызывает `HideDock()`.
5. После скрытия докера на следующем тике курсор снова детектируется в левом углу ➔ снова `ShowDock()`.
6. Цикл бесконечно повторяется (Show ➔ Hide ➔ Show), вызывая видимое моргание.

### Решение:
В `WatchdogTimer_Tick` условие удержания видимости докера должно учитывать активную зону горячего угла:
```csharp
bool keepVisible = overDock || overDropDown || inHotCorner;
if (keepVisible) {
    _outOfBoundsTicks = 0;
    // ...
}
```
Если курсор находится в зоне активации (`inHotCorner`), докер **не скрывается** и не сбрасывается, исключая цикл моргания. Дополнительно можно расширить триггер наведения на всю верхнюю кромку в зоне самого отцентрированного докера.

---

## 2. Галочка «Отображать только иконки / Скрыть названия»

### Требование:
В настройках докера (вкладка «Докер» / `TabDock`) добавить чекбокс (галочку), при снятии которой названия папок и ярлыков полностью скрываются (`Text = ""`), отображаются только компактные квадратные плавающие иконки (как в RocketDock). При наведении мыши название папки/приложения всплывает в Tooltip.

### Архитектурные изменения:

1. **Модель конфигурации (`DockConfig`)**:
   - Добавить булево свойство:
     ```csharp
     public bool ShowItemLabels = true;
     ```
   - Добавить сериализацию и десериализацию в JSON (`Save()` / `Load()`).

2. **Интерфейс настроек (`SettingsForm`)**:
   - На вкладке `TabDock` заменить/дополнить комбобокс удобным чекбоксом:
     ```csharp
     _chkShowLabels = new CheckBox {
         Text = I18n.T("ShowItemLabels"),
         Checked = _config.ShowItemLabels,
         Location = new Point(370, 88),
         AutoSize = true
     };
     ```
   - Добавить ключи локализации в словари (`ShowItemLabels`):
     - RU: `"Отображать названия (только иконки при выключении)"`
     - EN: `"Show item labels (icons only when disabled)"`
     - CS: `"Zobrazovat popisky (pouze ikony při vypnutí)"`

3. **Отрисовка элементов докера (`LoadItems()`)**:
   - Для папок:
     ```csharp
     if (_config.ShowItemLabels) {
         btn.Text = " " + folder.Name + " ▾";
         SizeF size = g.MeasureString(btn.Text, btn.Font);
         btn.Width = (int)size.Width + iconSz + 24;
     } else {
         btn.Text = "";
         btn.Width = iconSz + 16; // компактный квадратный вид
     }
     _toolTip.SetToolTip(btn, folder.Name);
     ```
   - Для ярлыков:
     ```csharp
     if (_config.ShowItemLabels) {
         btn.Text = " " + item.Name;
         SizeF size = g.MeasureString(btn.Text, btn.Font);
         btn.Width = (int)size.Width + iconSz + 24;
     } else {
         btn.Text = "";
         btn.Width = iconSz + 16;
     }
     _toolTip.SetToolTip(btn, item.Name);
     ```

---

## 3. План релиз-конвейера v053

1. **Патч исходного кода**: внесение изменений в `GIN-Desktop.cs`, `SettingsForm` и словари локализации `I18n`.
2. **Сборка через .NET 4.0 `csc.exe`**: сборка `GIN-Desktop.exe`, `Uninstall.exe`, инъекция Base64 в `installer_setup.cs` и компиляция `GIN-Desktop_v053_Setup.exe`.
3. **Развертывание**:
   - `D:\MEGA\WIN-FLASH\Util-WINDOWS\Graphics\GIN-Desktop_v053_Setup.exe`
   - `D:\MEGA\DOCS\desktop\GIN-Desktop_v053_Setup.exe`
   - Ротация: сохранение строго 2 последних версий (`v052` и `v053`), удаление `v051`.
4. **Синхронизация с GitHub**: коммит и пуш в `Windows_scripts` и `Secret_Privat`.

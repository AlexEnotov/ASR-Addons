local A=ASRSuite;
local EN={
 ["Отпусти — стыковка"]="Release to dock",
 ["Магнитная стыковка панелей"]="Magnetic panel docking",
 ["Разъединить панели"]="Undock panels",
 ["В режиме изменения интерфейса подведи панель к краю другой. Главная двигает всю цепочку; дочерняя отделяется вместе со своей цепочкой. Shift — без стыковки."]="In Edit interface, drag a panel near another edge. The parent moves its whole chain; a child detaches with its own chain. Hold Shift to skip docking.",
 ["Галочка включает элемент аддона. Стандартный вариант игры — рядом. Наведи курсор для пояснения."]="Check to enable an addon element. Its game alternative is beside it. Hover for details.",
 ["Текст урона сейчас: "]="Current combat text: ", ["Текст игры"]="Game text",
 ["Показывать числа ASR"]="Show ASR numbers", ["Показывать числа SurvivorUI"]="Show SurvivorUI numbers",
 ["Включение заменяет другие числа урона. Выключение возвращает прежний режим."]="Enabling replaces other combat numbers. Disabling restores the previous display.",
 ["Использовать стандартный текст игры вместо текста аддона."]="Use the game's default combat text instead of the addon's numbers.",
 ["Показывать панель характеристик"]="Show character stats panel",
 ["Текущие характеристики персонажа отдельной панелью. Выключено — панель скрыта."]="Current character statistics in a separate panel. Off: the panel is hidden.",
 ["Включить билдер и подсказки"]="Enable build planner and recommendations",
 ["Выключено — трекер и подсказки выбора не работают. Сохранённые билды остаются."]="Off: the tracker and card recommendations stop. Saved builds are kept.",
 ["Stats"]="Stats", ["ASR Stats"]="ASR Stats",
 ["Выбери аддон слева и отметь элементы, которыми он будет управлять."]="Choose an addon on the left and check the elements it should manage.",
 ["Панель характеристик"]="Character stats panel", ["Билдер и подсказки"]="Build planner and recommendations", ["Игра"]="Game",
 ["Восстановить прежний текст"]="Restore previous combat text",
 ["Один элемент может заменять только один аддон. Другие его панели не меняются."]="Only one addon can replace each element. Its other panels stay unchanged.",
 ["Как было до ASR"]="Restore previous display",
 ["Изменить интерфейс"]="Edit interface", ["Закрепить все панели"]="Lock all panels", ["Модуль включён"]="Module enabled",
 ["Стандартный текст игры"]="Default game text", ["Текст ASR"]="ASR text", ["Текст SurvivorUI"]="SurvivorUI text",
 ["Источник текста урона"]="Combat text source",
 ["Не установлен. Установи и включи этот аддон, чтобы открыть его настройки."]="Not installed. Install and enable this addon to configure it.",
 ["Выбранный источник заменяет остальные только для этого элемента интерфейса."]="The selected source replaces the others only for this interface element.",
 ["Источники для группы и других элементов появятся после установки соответствующих модулей."]="Party frames and other display sources will appear when their modules are installed.",
 ["Фон настроек"]="Settings background", ["Фон трекеров"]="Tracker backgrounds", ["Своя прозрачность настроек"]="Use own settings opacity", ["Своя прозрачность трекера"]="Use own tracker opacity", ["Своя прозрачность чисел"]="Use own number opacity",
 ["Общие"]="General",
 ["Настройки комплекса"]="Suite settings",
 ["Общая прозрачность"]="Shared opacity",
 ["Своя прозрачность"]="Use module opacity",
 ["Мин. отступ между числами"]="Minimum number gap",
 ["Прозрачность чисел"]="Number opacity",
 ["Общие настройки текста"]="Shared text settings",
 ["Текст урона"]="Combat text",
 ["Показывать этот тип"]="Show this type",
 ["Использовать свои настройки"]="Use custom settings",
 ["Используются индивидуальные значения этого типа."]="This type uses its own values.",
 ["Используются общие значения. Включи галочку, чтобы изменить их только для этого типа."]="Uses shared values. Enable the checkbox to customize this type.",
 ["Модули используют общую прозрачность, пока не включена своя. Индивидуальные значения сохраняются."]="Modules inherit shared opacity until their own opacity is enabled. Local values are preserved.",
 ["Выбери модуль слева. Его настройки появятся справа."]="Choose a module on the left to view its settings.",
 ["Настройки панели характеристик. Расположение меняется в общем режиме редактирования."]="Character stats panel settings. Move it using the shared edit mode.",
 ["Билдер"]="Build planner",
 ["Открыть редактор билдов"]="Open build planner",
 ["Показывать трекер"]="Show tracker",
 ["Трекер: подробный"]="Tracker: detailed",
 ["Трекер: компактный"]="Tracker: compact",
 ["Масштаб редактора"]="Editor scale",
 ["Масштаб трекера"]="Tracker scale",
 ["Фон редактора"]="Editor background",
 ["Фон трекера"]="Tracker background",
 ["Билды, требования и импорт/экспорт доступны в редакторе билдов."]="Builds, goals and import/export are available in the build planner.",
 ["Совместимость"]="Compatibility",
 ["657 ×3 — суммарный урон трёх попаданий, а не урон каждого."]="657 ×3 is the total damage of three hits, not damage per hit.",
 ["ASR / КОМПЛЕКС"]="ASR / SUITE", ["ТЕКСТ УРОНА"]="COMBAT TEXT",
 ["Текст урона: "]="Combat text: ", ["Расположение: "]="Placement: ", ["Вкл."]="On", ["Выкл."]="Off",
 ["Колонки"]="Columns", ["Над врагами"]="Above enemies", ["Завершить перемещение"]="Finish editing", ["Переместить колонки и Stats"]="Move columns and Stats",
 ["Скорость прокрутки"]="Scroll speed", ["%.0f ед/с"]="%.0f units/s", ["Размер текста"]="Text size", ["Время показа"]="Display time", ["Высота движения"]="Scroll distance", ["Объединять за"]="Merge window", ["%.2f с"]="%.2f s",
 ["Иконки"]="Icons", ["Периодический урон"]="Periodic damage", ["Исцеление"]="Healing", ["Полученный урон"]="Incoming damage", ["Короткие числа"]="Short numbers",
 ["Язык"]="Language", ["Язык комплекса"]="Suite language", ["Масштаб"]="Scale", ["Непрозрачность"]="Opacity", ["Скрывать нули"]="Hide zeros", ["Закрепить"]="Lock position", ["Нет Stats"]="Stats unavailable",
 ["Настройки билдера"]="Open build planner", ["Тест чисел"]="Preview numbers", ["Сбросить области текста"]="Reset text positions",
 ["Обычный урон"]="Normal damage", ["Критические удары"]="Critical hits", ["Перетащи область"]="Drag this area", ["Тест"]="Preview", ["Готово"]="Done", ["Настройки"]="Settings",
 ["SurvivorUI: вернуть его числа"]="SurvivorUI: restore its numbers", ["SurvivorUI: убрать его числа"]="SurvivorUI: hide its numbers",
 ["Расположение чисел"]="Number placement",
 ["Колонки перемещаются в режиме редактирования. Над врагами числа следуют игровым координатам; лечение и полученный урон остаются в своих колонках."]="Drag columns in edit mode. Above-enemy numbers follow world positions; healing and incoming damage use their own columns.",
 ["Только текст SurvivorUI"]="SurvivorUI combat text only",
 ["Остальные панели SurvivorUI не меняются. Повторное нажатие возвращает прежний режим текста."]="Other SurvivorUI panels stay unchanged. Click again to restore its previous combat text mode.",
 ["В SurvivorUI включён свой текст урона. Его можно отключить кнопкой SurvivorUI внизу."]="SurvivorUI combat text is also enabled. Use the SurvivorUI button below to hide its numbers.",
 ["Настрой расположение сейчас; боевые числа появятся в забеге."]="Arrange the panels now; live combat numbers appear during a run.",
 ["ЛКМ — настройки комплекса\nПКМ — режим редактирования\nПеретащи кнопку вокруг миникарты"]="Left click: suite settings\nRight click: edit layout\nDrag the button around the minimap",
 ["ASR Advisor не установлен."]="ASR Advisor is not installed.", ["Собственный текст SurvivorUI не обнаружен."]="SurvivorUI combat text was not found.",
};
ASRLocale.RegisterTranslations("suite","en",EN);
ASRLocale.RegisterTranslations("suite","ru",{["Stats"]="Статы",["ASR Stats"]="ASR Статы"});
function A.T(value) return ASRLocale.Text("suite",ASRSuiteDB and ASRSuiteDB.language or "en",value); end
function A.SetLanguage(language)
 language=ASRLocale.Normalize(language); ASRSuiteDB.language=language; if ASRCombatTextDB then ASRCombatTextDB.language=language; end
 if ASRStatsDB then ASRStatsDB.language=language; if ASRStats and ASRStats.Refresh then ASRStats.Refresh(); end end
 if ASAdvisorDB and ASAdvisorDB.options and ASAdvisor and ASAdvisor.SetLanguage and ASAdvisorDB.options.language~=language then ASAdvisor.SetLanguage(language); end
 if GameTooltip then GameTooltip:Hide(); end
 if A.DrawSettings then A.DrawSettings(); end
end
function A.InitLanguage()
 local language=ASRSuiteDB.language;
 if not ASRLocale.languages[language] then language=ASRStatsDB and ASRStatsDB.language or ASAdvisorDB and ASAdvisorDB.options and ASAdvisorDB.options.language or "en"; end
 A.SetLanguage(language);
end

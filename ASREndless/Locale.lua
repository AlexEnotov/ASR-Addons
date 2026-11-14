local A=ASREndless; local EN={["Закрепить"]="Lock panel"};
EN["Бесконечный режим"]="Endless mode";
EN["Зазор между панелями"]="Gap between panels";
EN["Обычный"]="Normal"; EN["Героический"]="Heroic";
EN["Убито врагов %d"]="Enemies slain  %d";
EN["%s убит %d / 1"]="%s slain  %d / 1";
EN["Круг %d · Боссы: %d"]="Round %d · Bosses: %d";
EN["Показывать трекер Endless"]="Show Endless tracker";
EN["Автоматически заменяет штатный трекер только в бесконечном режиме. Выключение возвращает штатный интерфейс."]="Automatically replaces the native tracker in endless mode. Disable to restore the native interface.";
EN["Враги — за весь забег. Боссы — только в бесконечном режиме."]="Enemies count the entire run. Bosses count endless mode only.";
EN["Боссы повторяются в порядке карты."]="Bosses repeat in the map's order.";
EN["Сбросить положение Endless"]="Reset Endless position";
EN["Круг %d"]="Round %d"; EN["Уровень %d"]="Level %d";
EN["Враги: %d  ·  Боссы: %d"]="Enemies: %d  ·  Bosses: %d";
EN["Круг %d · %s"]="Round %d · %s";
EN["В бою"]="Alive"; EN["Убит"]="Defeated"; EN["Следующий"]="Next"; EN["Далее"]="Later";
EN["Живых боссов: %d"]="Bosses alive: %d";
EN["Следующий: круг %d"]="Next: round %d";

ASRLocale.RegisterTranslations("endless","en",EN);
function A.T(value) return ASRLocale.Text("endless",ASREndlessDB and ASREndlessDB.language or "en",value); end
function A.SetLanguage(value) ASREndlessDB.language=ASRLocale.Normalize(value); if A.ready then A.UpdateEndless(0,true); end; if A.DrawSettings then A.DrawSettings(); end end

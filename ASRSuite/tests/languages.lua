local A=ASRSuite; local n=0; local function check(value,label) assert(value,label); n=n+1; end
ASRLocale.RegisterTranslations("suite","test-locale",{["Совместимость"]="Test compatibility"},"Test language");
A.SetLanguage("test-locale");
check(ASRSuiteDB.language=="test-locale" and ASRStatsDB.language=="test-locale" and ASRCombatTextDB.language=="test-locale","registered languages propagate without a two-language restriction");
check(A.T("Совместимость")=="Test compatibility" and A.T("Настройки")=="Settings","partial locale dictionaries fall back to English");
local control=A.controls.language; A.settings:Show(); A.SelectSettingsPage("general"); control.scripts.OnClick(control);
check(not control.localePopup.backdrop and control.localePopup:GetWidth()==control:GetWidth(),"picker contains only full-width language tiles without an outer frame");
check(control.localePopup.options.ru.point[4]==0 and control.localePopup.options.ru.point[5]==0,"language tiles have no leftover outer padding");
check(control.localePopup.options["test-locale"]~=nil and ASRSuiteDB.language=="test-locale","opening a picker lists registered locales without changing the selection");
control.localePopup.options.en.scripts.OnClick(control.localePopup.options.en); check(ASRSuiteDB.language=="en" and not control.localePopup:IsShown(),"choosing an item applies it and closes the list");
for i=1,15 do ASRLocale.Register("test-language-"..i,"Test language "..i); end
control.scripts.OnClick(control); local popup=control.localePopup;
check(popup:GetHeight()<=224,"large locale lists stay bounded");
popup.scripts.OnMouseWheel(popup,-100); check(popup.options["test-language-15"]:IsShown() and not popup.options.ru:IsShown(),"language list scrolls to its final entries");
popup.options["test-language-15"].scripts.OnClick(popup.options["test-language-15"]); check(ASRSuiteDB.language=="test-language-15","any registered locale is selectable");
popup:Hide(); MouseDown=true; local oldOver=MouseIsOver; MouseIsOver=function() return false; end;
control.scripts.OnClick(control); popup.scripts.OnUpdate(popup); check(popup:IsShown(),"the opening click cannot immediately dismiss its own menu");
MouseDown=false; popup.scripts.OnUpdate(popup); check(popup:IsShown(),"releasing the opening click keeps the picker open");
MouseDown=true; popup.scripts.OnUpdate(popup); check(not popup:IsShown(),"a subsequent outside click closes the picker");
MouseDown=false; MouseIsOver=oldOver; A.SetLanguage("ru"); A.settings:Hide();
print("Passed "..n.." extensible language picker checks");

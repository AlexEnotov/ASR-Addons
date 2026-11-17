local A,S=ASREndless,ASRStyle;
function A.DrawSettings()
 ASRLocale.UseFont(ASREndlessDB and ASREndlessDB.language); ASRLocale.ApplyFonts(A.settings,ASREndlessDB and ASREndlessDB.language);
 if not A.settings then return; end; local f=A.settings;
 f.enabled:SetChecked(ASREndlessDB.endlessEnabled); f.enabled.label:SetText(A.T("Показывать трекер Endless"));
 f.locked:SetChecked(ASREndlessDB.locked); f.locked.label:SetText(A.T("Закрепить"));
 f.language.text:SetText(ASRLocale.Name(ASREndlessDB.language)); f.reset.text:SetText(A.T("Сбросить положение Endless"));
end
function A.CreateSettings()
 local f=CreateFrame("Frame","ASREndlessSettings",UIParent); A.settings=f; f:SetSize(310,206); f:SetPoint("CENTER",UIParent,"CENTER",0,0); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(420); S.Panel(f,0.98); f:Hide();
 f:SetScript("OnShow",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASREndlessSettings",true); end; S.SyncChildren(f); end);
 f:SetScript("OnHide",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASREndlessSettings",false); end; if f.language.localePopup then f.language.localePopup:Hide(); end end);
 S.Label(f,"|cff8cd123ASR|r Endless",15,16,12,260);
 S.Button(f,"×",24,24,272,8,function() f:Hide(); end);
 local function Check(y,click)
  local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); c:SetSize(24,24); c:SetPoint("TOPLEFT",f,"TOPLEFT",14,-y); c.label=S.Label(f,"",11,44,y+3,252); c:SetScript("OnClick",function() click(); A.DrawSettings(); end); return c;
 end
 f.enabled=Check(46,function() A.SetEnabled(not ASREndlessDB.endlessEnabled); end);
 f.locked=Check(78,function() ASREndlessDB.locked=not ASREndlessDB.locked; end);
 f.language=S.Button(f,"",278,28,16,116,function() end); ASRLocale.Bind(f.language,function() return ASREndlessDB.language; end,A.SetLanguage);
 f.reset=S.Button(f,"",278,28,16,158,A.ResetPosition); A.DrawSettings();
end

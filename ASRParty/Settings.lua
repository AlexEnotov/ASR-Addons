local A,S=ASRParty,ASRStyle;
function A.BuildOptions(page,width,suite)
 local c={labels={}}; page.partyControls=c; local left=suite and 8 or 20; local right=suite and 8 or 20; local top=suite and 0 or 26; local usable=width-left-right;
 local function Label(key,x,y,w) local f=S.Label(page,A.T(key),11,x,y,w); c.labels[#c.labels+1]={f,key}; return f; end
 local function Check(key,y,get,set)
  local f=CreateFrame("CheckButton",nil,page,"UICheckButtonTemplate"); f:SetSize(24,24); f:SetPoint("TOPLEFT",page,"TOPLEFT",left,-y); Label(key,left+30,y+3,usable-30);
  f:SetScript("OnClick",function() set(not get()); A.Refresh(); A.DrawSettings(); if suite then suite.DrawSettings(); end end); return f;
 end
 c.title=Label("Группа",left,top,usable-36); c.title:SetFont(S.font,16,""); c.title:SetHeight(21);
 c.enabled=Check("Модуль включён",top+32,function() return ASRPartyDB.enabled; end,A.SetEnabled);
 c.mode=S.Button(page,"",usable,27,left,top+68,function() A.SetMode(ASRPartyDB.mode=="classic" and "compact" or "classic"); if suite then suite.DrawSettings(); end end);
 c.locked=Check("Закрепить",top+108,function() return ASRPartyDB.locked; end,function(v) ASRPartyDB.locked=v; end);
 c.showHeader=Check("Всегда показывать заголовок группы",top+140,function() return ASRPartyDB.showHeader; end,function(v) ASRPartyDB.showHeader=v; end);
 c.healthFormat=S.Button(page,"",usable,27,left,top+178,function()
  local i=1; for index,mode in ipairs(A.healthFormats) do if mode==ASRPartyDB.healthFormat then i=index; end end
  ASRPartyDB.healthFormat=A.healthFormats[i%#A.healthFormats+1]; A.Refresh(); A.DrawSettings(); if suite then suite.DrawSettings(); end
 end);
 c.healthPreview=S.Label(page,"",11,left,top+213,usable); c.healthPreview:SetJustifyH("CENTER");
 local plus=width-right-26; local value=plus-76; local minus=value-36;
 Label("Масштаб",left,top+246,minus-left-10); c.scale=S.Label(page,"",11,value,top+246,66); c.scale:SetJustifyH("CENTER");
 local function Scale(delta) ASRPartyDB.scale=math.max(0.5,math.min(1.5,ASRPartyDB.scale+delta)); A.Refresh(); A.DrawSettings(); if suite then suite.DrawSettings(); end end
 c.minus=S.Button(page,"−",26,25,minus,top+242,function() Scale(-0.01); end); c.plus=S.Button(page,"+",26,25,plus,top+242,function() Scale(0.01); end);
 c.language=S.Button(page,"",usable,27,left,top+282,function() end); ASRLocale.Bind(c.language,function() return ASRPartyDB.language; end,function(value) if suite then suite.SetLanguage(value); else A.SetLanguage(value); end end);
 c.reset=S.Button(page,"",usable,27,left,top+322,A.ResetPosition);
 c.note=Label("Перетащи заголовок, чтобы переместить группу.",left,top+362,usable); c.note:SetHeight(44);
 if suite then c.edit=S.Button(page,A.T("Изменить интерфейс"),usable,27,left,top+414,function() suite.ToggleEdit(); end); end
 return c;
end
function A.DrawOptions(c)
 ASRLocale.UseFont(ASRPartyDB.language); ASRLocale.ApplyFonts(c.title:GetParent(),ASRPartyDB.language);
 c.showHeader:SetChecked(ASRPartyDB.showHeader); c.enabled:SetChecked(ASRPartyDB.enabled); c.locked:SetChecked(ASRPartyDB.locked); c.scale:SetText(math.floor(ASRPartyDB.scale*100+0.5).."%");
 c.healthFormat.text:SetText(A.T("Формат ХП")..": "..A.T(A.HealthFormatName(ASRPartyDB.healthFormat))); c.healthPreview:SetText(A.HealthText(1200,2400));
 c.mode.text:SetText(A.T("Вид панели")..": "..A.T(ASRPartyDB.mode=="classic" and "Классический" or "Компактный"));
 c.language.text:SetText(ASRLocale.Name(ASRPartyDB.language)); c.reset.text:SetText(A.T("Сбросить положение"));
 for _,v in ipairs(c.labels) do v[1]:SetText(A.T(v[2])); end; if c.edit then c.edit.text:SetText(A.T("Изменить интерфейс")); end
 c.title:SetText("|cff8cd123ASR|r Party");
 local shared=ASRSuite and ASRSuite.ready; c.locked:SetAlpha(shared and 0.45 or 1); c.note:SetText(A.T(shared and "С Suite перемещение — через «Изменить интерфейс»." or "Перетащи заголовок, чтобы переместить группу."));
 ASRLocale.ApplyFonts(c.title:GetParent(),ASRPartyDB.language);
end
function A.DrawSettings() if A.settings and A.settings.partyControls then A.DrawOptions(A.settings.partyControls); end end
function A.CreateSettings()
 local f=CreateFrame("Frame","ASRPartySettings",UIParent); A.settings=f; f:SetSize(330,454); f:SetPoint("CENTER",UIParent,"CENTER",0,0); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(420); S.Panel(f,0.98);
 f.close=S.Button(f,"×",24,24,282,26,function() f:Hide(); end); A.BuildOptions(f,330);
 f:SetScript("OnShow",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRPartySettings",true); end; A.preview=true; A.Refresh(); A.DrawSettings(); S.SyncChildren(f); end);
 f:SetScript("OnHide",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRPartySettings",false); end; A.preview=false; if f.partyControls.language.localePopup then f.partyControls.language.localePopup:Hide(); end; A.Refresh(); end); f:Hide(); A.DrawSettings();
end
function A.BindSuite()
 local suite=ASRSuite; if not suite or not suite.ready then return; end
 if ASRPartyDB.language~=ASRSuiteDB.language then A.SetLanguage(ASRSuiteDB.language); end
 if A.suiteBound then return; end; A.suiteBound=true;
 suite.RegisterSettingsPage("party","ASR Party",function(page) A.BuildOptions(page,484,suite); end,function(page) if page.partyControls then A.DrawOptions(page.partyControls); end end);
 suite.RegisterPanel("party",{frame=A.frame,available=function() return A.frame:IsShown(); end,setEnabled=A.SetEnabled,
  setEditing=function(on) A.editing=on; A.Refresh(); end,
  savePosition=function(r) ASRPartyDB.positions[ASRPartyDB.mode]={point="TOPLEFT",relative="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; end});
 suite.RegisterCompatibilityAddon("party","ASR Party",function() return true; end,{{id="panel",title="ASR Party",get=function() return ASRPartyDB.enabled; end,set=A.SetEnabled}});
end

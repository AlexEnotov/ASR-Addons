local A,S=ASRChat,ASRStyle;
function A.BuildOptions(page,width,suite)
 local c={labels={},checks={},steps={}}; page.chatControls=c; local left=8; local usable=width-16; c.section="view"; c.suite=suite;
 c.title=S.Label(page,"|cff8cd123ASR|r Chat",16,left,0,usable);
 local function Changed() A.Apply(); A.DrawSettings(); A.DrawOptions(c); if suite then suite.DrawSettings(); end end
 local function Check(parent,key,field,y)
  local f=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); f:SetSize(24,24); f:SetPoint("TOPLEFT",parent,"TOPLEFT",left,-y);
  f.label=S.Label(parent,"",11,left+30,y+3,usable-30); c.labels[#c.labels+1]={frame=f.label,key=key}; c.checks[field]=f;
  f:SetScript("OnClick",function() if field=="enabled" then A.SetEnabled(not ASRChatDB.enabled); else ASRChatDB[field]=not ASRChatDB[field]; end; Changed(); end); return f;
 end
 Check(page,"Модуль включён","enabled",28);
 c.view=S.Button(page,"",(usable-8)/2,26,left,62,function() c.section="view"; A.DrawOptions(c); end);
 c.behavior=S.Button(page,"",(usable-8)/2,26,left+(usable+8)/2,62,function() c.section="behavior"; A.DrawOptions(c); end);
 c.preview=CreateFrame("Frame",nil,page); c.preview:SetSize(usable,80); c.preview:SetPoint("TOPLEFT",page,"TOPLEFT",left,-100);
 c.sample=S.Label(c.preview,"",12,16,16,usable-32); c.sample:SetHeight(52);
 c.viewPage=CreateFrame("Frame",nil,page); c.viewPage:SetSize(width,270); c.viewPage:SetPoint("TOPLEFT",page,"TOPLEFT",0,-194);
 c.behaviorPage=CreateFrame("Frame",nil,page); c.behaviorPage:SetSize(width,270); c.behaviorPage:SetPoint("TOPLEFT",page,"TOPLEFT",0,-194);
 local function Step(parent,key,field,y,lo,hi,delta,format)
  local label=S.Label(parent,"",11,left,y+5,usable-150); c.labels[#c.labels+1]={frame=label,key=key};
  local r={}; c.steps[field]=r; r.value=S.Label(parent,"",11,width-112,y+5,66); r.value:SetJustifyH("CENTER");
  local function Move(sign) ASRChatDB[field]=math.max(lo,math.min(hi,ASRChatDB[field]+sign*delta)); if field=="opacity" then ASRChatDB.ownOpacity=true; end; Changed(); end
  r.minus=S.Button(parent,"−",26,25,width-148,y,function() Move(-1); end); r.plus=S.Button(parent,"+",26,25,width-34,y,function() Move(1); end);
  r.format=format or function(v) return tostring(math.floor(v+0.5)); end;
 end
 local percent=function(v) return math.floor(v*100+0.5).."%"; end
 Step(c.viewPage,"Ширина","width",0,196,900,10); Step(c.viewPage,"Высота","height",32,180,600,10);
 Step(c.viewPage,"Масштаб","scale",64,0.5,1.5,0.01,percent); Step(c.viewPage,"Размер текста","fontSize",96,10,22,1);
 Step(c.viewPage,"Фон","opacity",128,0,1,0.05,percent); Step(c.viewPage,"Интервал строк","spacing",160,0,8,1);
 c.stone=S.Button(c.viewPage,"",suite and (usable-8)/2 or usable,26,left,198,function() local nextStyle={stone="simple",simple="none",none="stone"}; ASRChatDB.frameStyle=nextStyle[ASRChatDB.frameStyle] or "stone"; Changed(); end);
 if suite then c.ownOpacity=S.Button(c.viewPage,"",(usable-8)/2,26,left+(usable+8)/2,198,function() ASRChatDB.ownOpacity=not ASRChatDB.ownOpacity; Changed(); end); end
 Check(c.behaviorPage,"Закрепить","locked",0); Check(c.behaviorPage,"Затухание сообщений","fading",26);
 Step(c.behaviorPage,"Показывать сообщения, сек.","timeVisible",52,5,300,5);
 Check(c.behaviorPage,"Ввод сверху","inputTop",80); Check(c.behaviorPage,"Показывать кнопки","showTools",106); Check(c.behaviorPage,"Показывать заголовок","showHeader",132);
 Check(c.behaviorPage,"Всегда показывать чат","alwaysShowChat",158);
 Check(c.behaviorPage,"Всегда показывать поле ввода","alwaysShowInput",184);
 c.copy=S.Button(c.behaviorPage,"",(usable-8)/2,26,left,214,A.OpenCopy); c.reset=S.Button(c.behaviorPage,"",(usable-8)/2,26,left+(usable+8)/2,214,A.ResetPosition);
 c.edit=S.Button(page,"",usable,26,left,440,function() if suite then suite.ToggleEdit(); else ASRChatDB.locked=false; A.settings:Hide(); A.Apply(); end end);
 c.note=S.Label(page,"",10,left,478,usable); c.note:SetHeight(32); if suite then c.note:Hide(); end
 return c;
end
function A.DrawOptions(c)
 if not c then return; end
 for _,v in ipairs(c.labels) do v.frame:SetText(A.T(v.key)); end
 for key,f in pairs(c.checks) do f:SetChecked(ASRChatDB[key]); end
 for key,r in pairs(c.steps) do r.value:SetText(r.format(ASRChatDB[key])); end
 c.view.text:SetText(A.T("Вид")); c.behavior.text:SetText(A.T("Поведение")); c.copy.text:SetText(A.T("Копировать чат")); c.reset.text:SetText(A.T("Сбросить положение")); c.edit.text:SetText(A.T("Изменить интерфейс"));
 c.stone.text:SetText(A.T(({stone="Рамка: камень",simple="Рамка: простая",none="Рамка: нет"})[ASRChatDB.frameStyle]));
 if c.section=="view" then c.viewPage:Show(); c.behaviorPage:Hide(); else c.viewPage:Hide(); c.behaviorPage:Show(); end
 c.view:SetBackdropColor(c.section=="view" and 0.22 or 0.12,0.15,0.18,1); c.behavior:SetBackdropColor(c.section=="behavior" and 0.22 or 0.12,0.15,0.18,1);
 if c.ownOpacity then c.ownOpacity.text:SetText(A.T(ASRChatDB.ownOpacity and "Фон: свой" or "Фон: общий")); end
 local opacity=not ASRChatDB.ownOpacity and c.suite and c.suite.GetPanelOpacity("chat",ASRChatDB.opacity) or ASRChatDB.opacity;
 A.PanelStyle(c.preview,ASRChatDB.frameStyle,opacity);
 c.sample:SetFont(S.font,ASRChatDB.fontSize,""); c.sample:SetText("|cff8cd123Alex:|r "..A.T("Пример сообщения группы").."\n|cffffd100"..A.T("Получена новая вещь").."|r");
 c.note:SetText(A.T("Перетащи заголовок. Угол справа снизу меняет размер."));
end
function A.DrawSettings() if A.settings then A.DrawOptions(A.settings.chatControls); end end
function A.CreateSettings()
 local f=CreateFrame("Frame","ASRChatSettings",UIParent); A.settings=f; f:SetSize(530,566); f:SetPoint("CENTER",UIParent,"CENTER",0,0); f:SetScale(math.min(1,(UIParent:GetHeight()-24)/566)); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(600); S.Panel(f,0.98);
 local body=CreateFrame("Frame",nil,f); body:SetSize(490,512); body:SetPoint("TOPLEFT",f,"TOPLEFT",20,-26); f.chatControls=A.BuildOptions(body,490);
 f.close=S.Button(f,"×",24,24,480,24,function() f:Hide(); end);
 f:SetScript("OnShow",function() if A.copy then A.copy:Hide(); end; if A.popup then A.popup:Hide(); end; A.Apply(); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatSettings",true); end; A.DrawSettings(); S.SyncChildren(f); end);
 f:SetScript("OnHide",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatSettings",false); end; A.Apply(); end); f:Hide(); A.DrawSettings();
end
function A.BindSuite()
 local suite=ASRSuite; if not suite or not suite.ready then return; end
 if A.boundSuite then if ASRChatDB.language~=ASRSuiteDB.language then A.SetLanguage(ASRSuiteDB.language); end; return; end
 A.boundSuite=true;
 suite.RegisterSettingsPage("chat","ASR Chat",function(page) A.BuildOptions(page,484,suite); end,function(page) A.DrawOptions(page.chatControls); end);
 suite.RegisterPanel("chat",{frame=A.frame,available=function() return A.frame:IsShown(); end,setEnabled=A.SetEnabled,setEditing=A.SetEditMode,
  savePosition=function(r) ASRChatDB.position={point="TOPLEFT",relative="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; end});
 suite.RegisterCompatibilityAddon("chat","ASR Chat",function() return true; end,{{id="panel",title="ASR Chat",get=function() return ASRChatDB.enabled; end,set=A.SetEnabled}});
 if suite.settings and suite.settings.HookScript then suite.settings:HookScript("OnShow",function() if A.copy then A.copy:Hide(); end; if A.settings then A.settings:Hide(); end; if A.popup then A.popup:Hide(); end; A.Apply(); end); suite.settings:HookScript("OnHide",function() A.Apply(); end); end
 A.SetLanguage(ASRSuiteDB.language); A.SetEditMode(suite.editing);
end

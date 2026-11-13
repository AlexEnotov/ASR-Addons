local A=ASRStats; local S=ASRStyle; local panel,menu,grip,ready,config; local raw,received=false,false;
local function L(ru,en) return ASRLocale.Text("stats",ASRStatsDB.language,ru,en); end
local defaults={language="en",opacity=0.9,menuOpacity=0.95,scale=0.7,hideZeros=true,locked=false,hidden=false,enabled=true};
local function InRun()
 local phase=AZS_RUN and AZS_RUN.ph;
 return phase=="playing" or phase=="choosing" or phase=="ready" or phase=="dead";
end
local function Stop()
 if panel and panel.moving then
  panel:StopMovingOrSizing(); panel.moving=false;
  local point,_,relative,x,y=panel:GetPoint(); ASRStatsDB.position={point=point,relative=relative,x=x,y=y};
 end
end
local function Place()
 panel:ClearAllPoints(); local p=ASRStatsDB.position;
 if type(p)=="table" and type(p.point)=="string" and type(p.relative)=="string" and A.Number(p.x) and A.Number(p.y) then panel:SetPoint(p.point,UIParent,p.relative,p.x,p.y);
 else panel:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-210); end
end
local function Layers()
 local overlay=config or A.editing;
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRStatsPanel",overlay and true or false); end
 panel:SetFrameStrata(overlay and "FULLSCREEN_DIALOG" or "HIGH");
 panel:SetFrameLevel(config and 600 or A.editing and 450 or 10);
 if S.SyncChildren then S.SyncChildren(panel); end
end
local function Tip(frame,title,body)
 GameTooltip:SetOwner(frame,"ANCHOR_RIGHT"); GameTooltip:SetText(title,0.96,0.96,0.97);
 if body then GameTooltip:AddLine(body,0.75,0.77,0.8,true); end; GameTooltip:Show();
end
function A.Refresh()
 if not ready then return; end
 Layers();
 if not config and (ASRStatsDB.enabled==false or ASRSuite and ASRSuite.IsModuleEnabled and not ASRSuite.IsModuleEnabled("stats")) then Stop(); panel:Hide(); return; end
 if not config and not A.editing and (ASRStatsDB.hidden or not InRun()) then Stop(); panel:Hide(); return; end
 panel:Show(); panel:SetWidth(config and 280 or 196); local ownOpacity=config and ASRStatsDB.menuOpacity or ASRStatsDB.opacity; S.Panel(panel,ASRSuite and ASRSuite.GetPanelOpacity and ASRSuite.GetPanelOpacity("stats",ownOpacity,config and "menu" or "tracker") or ownOpacity);
 panel.title:SetWidth(config and 198 or 129); panel.title:SetFont(S.font,config and 10 or 9,""); panel.title:ClearAllPoints(); panel.title:SetPoint("TOPLEFT",panel,"TOPLEFT",config and 24 or 20,config and -24 or -23); panel.title:SetHeight(config and 20 or 16);
 panel.menu:ClearAllPoints(); panel.menu:SetPoint("TOPLEFT",panel,"TOPLEFT",config and 232 or 156,config and -24 or -23); panel.menu:SetSize(config and 24 or 20,config and 20 or 16);
 grip:SetWidth(config and 200 or 136); grip:SetHeight(config and 24 or 18); grip:ClearAllPoints(); grip:SetPoint("TOPLEFT",panel,"TOPLEFT",config and 22 or 18,config and -22 or -22); panel.title:SetText(config and L("ASR / НАСТРОЙКИ","ASR / SETTINGS") or (A.editing and L("СТАТЫ · ПЕРЕТАЩИ","STATS · DRAG") or L("ASR / СТАТЫ","ASR / STATS")));
 panel.menu.text:SetText(config and "‹" or "≡");
 for _,row in ipairs(panel.rows) do row:Hide(); end; for _,head in ipairs(panel.headings) do head:Hide(); end
 panel.empty:Hide(); if config then menu:Show(); else menu:Hide(); end
 local height=0;
 if config then
  for _,setting in ipairs(menu.settings) do
   setting.label:SetText(L(setting.ru,setting.en));
   if setting.key=="opacity" or setting.key=="menuOpacity" or setting.key=="scale" then setting.value:SetText(math.floor(ASRStatsDB[setting.key]*100+0.5).."%");
   elseif setting.key=="language" then setting.button.text:SetText(ASRLocale.Name(ASRStatsDB.language));
   else setting.button.text:SetText(ASRStatsDB[setting.key] and L("Вкл.","On") or L("Выкл.","Off")); end
  end
  menu.reset.text:SetText(L("Сбросить положение","Reset position")); menu.close.text:SetText(L("Готово","Done")); height=375;
 else
  local primary=received and raw or AZS_STATS; local fallback=AZS_RUNSTATS; if not InRun() then primary=nil; fallback=nil; end; local y=45; local shown=0;
  for gi,group in ipairs(A.sections) do
   local start=y; local groupShown=0;
   for _,row in ipairs(panel.groupRows[gi]) do
    local v=A.Value(row.definition,primary,fallback,InRun() and AZS_RUN or nil);
    if (v~=nil and (not ASRStatsDB.hideZeros or math.abs(v)>0.00001)) or (not ASRStatsDB.hideZeros and (primary or fallback)) then
     if groupShown==0 then y=y+14; end
     row:ClearAllPoints(); row:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-y);
     row.name:SetText(L(row.definition[1],row.definition[2])); row.value:SetText(A.Format(row.definition,v,ASRStatsDB.language~="ru")); row:Show();
     y=y+11; shown=shown+1; groupShown=groupShown+1;
    end
   end
   if groupShown>0 then local head=panel.headings[gi]; head:ClearAllPoints(); head:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-start); head:SetText(L(group[1],group[2])); head:Show(); y=y+3; end
  end
  if shown==0 then panel.empty:SetText(L("Ожидание характеристик от игры…","Waiting for current game stats…")); panel.empty:Show(); y=79; end
  height=y+20;
 end
 panel:SetHeight(height); panel:SetScale(math.min(config and math.max(0.85,ASRStatsDB.scale) or ASRStatsDB.scale,(UIParent:GetHeight()-24)/height,(UIParent:GetWidth()-24)/panel:GetWidth()));
end
function A.SetEditMode(on)
 Stop(); config=false; A.editing=on and true or false;
 if panel then
  if A.editing then panel:SetFrameStrata("FULLSCREEN_DIALOG"); panel:SetFrameLevel(450); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRStatsPanel",true); end
  else if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRStatsPanel",false); end; panel:SetFrameStrata("HIGH"); panel:SetFrameLevel(10); end
 end
 A.Refresh(); if ASRStyle.SyncChildren then ASRStyle.SyncChildren(panel); end
end
local function Build()
 panel=CreateFrame("Frame","ASRStatsPanel",UIParent); panel:SetSize(280,100); panel:SetFrameStrata("HIGH"); panel:SetMovable(true); panel:SetClampedToScreen(true); panel:EnableMouse(true);
 panel.title=S.Label(panel,"ASR / STATS",10,24,24,198); panel.title:SetHeight(20);
 grip=CreateFrame("Frame",nil,panel); grip:SetSize(200,24); grip:SetPoint("TOPLEFT",panel,"TOPLEFT",22,-22); grip:EnableMouse(true); grip:RegisterForDrag("LeftButton");
 grip:SetScript("OnDragStart",function() if (config or A.editing or not ASRStatsDB.locked) and (config or not ASRSuite or not ASRSuite.CanMovePanel or ASRSuite.CanMovePanel("stats")) then panel.moving=true; panel:StartMoving(); end end); grip:SetScript("OnDragStop",Stop);
 grip:SetScript("OnEnter",function(self) Tip(self,"ASR Stats · by AlexEnotov",L("Тяни за заголовок. Настройки — кнопка ≡ или /asrstats config.","Drag the header. Settings: ≡ or /asrstats config.")); end); grip:SetScript("OnLeave",function() GameTooltip:Hide(); end);
 panel.menu=S.Button(panel,"≡",24,20,232,24,function() Stop(); config=not config; A.Refresh(); end); panel.menu:SetFrameLevel(grip:GetFrameLevel()+1);
 panel.empty=S.Label(panel,"",9,20,42,156,S.muted); panel.empty:SetHeight(35);
 panel.rows={}; panel.headings={}; panel.groupRows={};
 for gi,group in ipairs(A.sections) do
  panel.headings[gi]=S.Label(panel,"",8,20,40,156,group[3]); panel.headings[gi]:SetHeight(12); panel.groupRows[gi]={};
  for _,definition in ipairs(group[4]) do
   local row=CreateFrame("Frame",nil,panel); row:SetSize(156,11); row:EnableMouse(true); row.definition=definition;
   row.name=S.Label(row,"",8,0,0,103); row.name:SetHeight(11); row.value=S.Label(row,"",8,105,0,51); row.value:SetHeight(11); row.value:SetJustifyH("RIGHT");
   row:SetScript("OnEnter",function(self) Tip(self,L(self.definition[1],self.definition[2]),L(self.definition[7],self.definition[8])); end); row:SetScript("OnLeave",function() GameTooltip:Hide(); end);
   panel.rows[#panel.rows+1]=row; panel.groupRows[gi][#panel.groupRows[gi]+1]=row;
  end
 end
 menu=CreateFrame("Frame",nil,panel); menu:SetAllPoints(panel); menu.settings={}; panel.settings=menu;
 local definitions={{"language","Язык","Language"},{"enabled","Модуль включён","Module enabled"},{"opacity","Фон трекера","Tracker background"},{"menuOpacity","Фон настроек","Settings background"},{"scale","Масштаб","Scale"},{"hideZeros","Скрывать нули","Hide zeros"},{"locked","Закрепить","Lock position"}};
 for i,d in ipairs(definitions) do
  local y=57+(i-1)*33; local key=d[1]; local setting={key=key,ru=d[2],en=d[3]}; setting.label=S.Label(menu,"",10,24,y+2,131);
  if key=="opacity" or key=="menuOpacity" or key=="scale" then
   setting.value=S.Label(menu,"",10,179,y+2,45); setting.value:SetJustifyH("CENTER");
   local function step(delta) ASRStatsDB[key]=math.max(key~="scale" and 0 or 0.5,math.min(key~="scale" and 1 or 1.5,ASRStatsDB[key]+delta)); A.Refresh(); end
   setting.minus=S.Button(menu,"−",23,23,154,y,function() step(-0.05); end); setting.plus=S.Button(menu,"+",23,23,233,y,function() step(0.05); end);
  else setting.button=S.Button(menu,"",102,23,154,y,function() if key~="language" then ASRStatsDB[key]=not ASRStatsDB[key]; if key=="enabled" and ASRSuite and ASRSuite.SetModuleEnabled then ASRSuite.SetModuleEnabled("stats",ASRStatsDB.enabled); end; end; A.Refresh(); end); end
  if key=="language" then ASRLocale.Bind(setting.button,function() return ASRStatsDB.language; end,function(code) if ASRSuite and ASRSuite.SetLanguage then ASRSuite.SetLanguage(code); else ASRStatsDB.language=ASRLocale.Normalize(code); end end,A.Refresh); end
  menu.settings[#menu.settings+1]=setting;
 end
 menu.reset=S.Button(menu,"",232,24,24,298,function() Stop(); ASRStatsDB.position=nil; Place(); end);
 menu.close=S.Button(menu,"",232,24,24,329,function() config=false; A.Refresh(); end);
 panel:SetScript("OnHide",function() Stop(); GameTooltip:Hide(); end); Place();
end
local clock=CreateFrame("Frame","ASRStatsRuntime"); clock:RegisterEvent("ADDON_LOADED"); clock:RegisterEvent("PLAYER_ENTERING_WORLD"); local elapsed=0;
clock:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" and name=="ASRStats" then
  if type(ASRStatsDB)~="table" then ASRStatsDB={}; end
  for key,value in pairs(defaults) do if type(ASRStatsDB[key])~=type(value) then ASRStatsDB[key]=value; end end
  ASRStatsDB.language=ASRLocale.Normalize(ASRStatsDB.language);
  if not ASRStatsDB.compactLayout then if ASRStatsDB.scale==0.9 then ASRStatsDB.scale=0.7; end; ASRStatsDB.compactLayout=true; end
  ASRStatsDB.scale=math.max(0.5,math.min(1.5,A.Number(ASRStatsDB.scale) or 0.9)); ASRStatsDB.opacity=math.max(0,math.min(1,A.Number(ASRStatsDB.opacity) or 0.9)); ASRStatsDB.menuOpacity=math.max(0,math.min(1,A.Number(ASRStatsDB.menuOpacity) or 0.95));
  ASRStatsDB.onlyRun=nil;
  Build(); ready=true;
  AZS.On("AZS",function(msg) raw={}; for key,value in string.gmatch(msg or "","(%w+)=([^;]*)") do raw[key]=A.Number(value); end; received=true; A.Refresh(); end);
  for _,prefix in ipairs({"AZSSTATS","AZSRUN","AZSEND","AZSZONE"}) do AZS.On(prefix,function() A.Refresh(); end); end
  A.Refresh();
 elseif ready then A.Refresh(); end
end);
clock:SetScript("OnUpdate",function(self,dt)
 if not ready then return; end
 if panel.moving and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then Stop(); end
 elapsed=elapsed+dt; if elapsed<0.25 then return; end; elapsed=0; A.Refresh();
end);
SLASH_ASRSTATS1="/asrstats";
SlashCmdList.ASRSTATS=function(msg)
 if not ready then return; end
 msg=string.lower(msg or ""); Stop();
 if msg=="config" or msg=="settings" then config=true; ASRStatsDB.hidden=false;
 elseif msg=="reset" then ASRStatsDB.position=nil; Place(); config=true; ASRStatsDB.hidden=false;
 else ASRStatsDB.hidden=not ASRStatsDB.hidden; config=false; end
 A.Refresh();
end;

local A=ASRSuite; local S=ASRStyle; local window,content,status; local pages,nav={},{}; local selected="general"; local records={}; local MountPage; local navCount=0; local subnav={};
A.settingsPages={};
local function L(parent,key,size,x,y,w,color) local f=S.Label(parent,A.T(key),size,x,y+(parent.contentOffset or 0),w,color); if parent.contentOffset and size==16 and y==0 then f:Hide(); end; records[#records+1]=function() f:SetText(A.T(key)); end; return f; end
local function B(parent,key,w,h,x,y,fn) local f=S.Button(parent,A.T(key),w,h,x,y+(parent.contentOffset or 0),fn); records[#records+1]=function() f.text:SetText(A.T(key)); end; return f; end
local function Note(page,key,y) local f=L(page,key,10,8,y,468,S.muted); f:SetHeight(36); return f; end
local function Changed() A.RefreshModules(); end
local function Check(page,key,get,set,y,available)
 local f=CreateFrame("CheckButton",nil,page,"UICheckButtonTemplate"); f:SetSize(24,24); f:SetPoint("TOPLEFT",page,"TOPLEFT",6,-y-(page.contentOffset or 0)); f:SetFrameLevel(page:GetFrameLevel()+2);
 f.label=L(page,key,11,36,y+3,452);
 f:SetScript("OnClick",function() if not available or available() then set(not get()); Changed(); end end);
 records[#records+1]=function() f:SetChecked(get() and true or false); f:SetAlpha((not available or available()) and 1 or 0.45); end; return f;
end
local function Step(page,key,get,set,y,lo,hi,delta,format,available)
 local row={}; row.label=L(page,key,11,8,y+4,280); row.value=S.Label(page,"",11,338,y+4+(page.contentOffset or 0),100); row.value:SetJustifyH("CENTER");
 local function update(sign) if not available or available() then set(math.max(lo,math.min(hi,get()+sign*delta))); Changed(); end end
 row.minus=B(page,"−",26,25,304,y,function() update(-1); end); row.plus=B(page,"+",26,25,450,y,function() update(1); end);
 records[#records+1]=function() local value=get(); assert(value~=nil,"Missing setting: "..key); row.value:SetText(format and format(value) or tostring(value)); local alpha=(not available or available()) and 1 or 0.45; row.minus:SetAlpha(alpha); row.plus:SetAlpha(alpha); row.value:SetAlpha(alpha); end; return row;
end
local function Percent(v) return math.floor(v*100+0.5).."%"; end
local specs={{"fontSize","Размер текста",10,36,2},{"scrollSpeed","Скорость прокрутки",0,300,10},{"lifetime","Время показа",0.6,4,0.2},{"rise","Высота движения",20,200,10},{"merge","Объединять за",0,1,0.05},{"spacing","Мин. отступ между числами",0,80,1}};
local function StyleRows(page,get,y,available)
 local out={}; for i,s in ipairs(specs) do local key=s[1]; out[key]=Step(page,s[2],function() return get()[key]; end,function(v) get()[key]=v; end,y+(i-1)*29,s[3],s[4],s[5],function(v)
  if key=="scrollSpeed" then return string.format(A.T("%.0f ед/с"),v); elseif key=="lifetime" or key=="merge" then return string.format(A.T("%.2f с"),v); end; return tostring(math.floor(v*100+0.5)/100);
 end,available); end
 if out.merge then out.merge.minus:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(A.T("Объединять за")); GameTooltip:AddLine(A.T("657 ×3 — суммарный урон трёх попаданий, а не урон каждого."),0.8,0.8,0.82,true); GameTooltip:Show(); end); out.merge.minus:SetScript("OnLeave",function() GameTooltip:Hide(); end); end
 return out;
end
local function OverrideOpacity(page,module,y,category)
 local key=category=="menu" and "menuOpacity" or "opacity"; local caption=category=="menu" and "Своя прозрачность настроек" or category=="text" and "Своя прозрачность чисел" or "Своя прозрачность трекера";
 return Check(page,caption,function() return ASRSuiteDB.moduleOverrides[module][key]; end,function(v) ASRSuiteDB.moduleOverrides[module][key]=v; end,y);
end
local function OwnOpacity(module,category) return ASRSuiteDB.moduleOverrides[module][category=="menu" and "menuOpacity" or "opacity"]; end
function A.RegisterSettingsPage(id,title,build,draw,parent)
 for _,kind in ipairs(A.typeKeys) do if id==kind then parent="combat"; end end
 local spec={id=id,title=title,build=build,draw=draw,parent=parent}; A.settingsPages[#A.settingsPages+1]=spec;
 if A.settings==window and MountPage then MountPage(spec,#A.settingsPages); A.DrawSettings(); end
end
function A.SelectSettingsPage(id)
 if not pages[id] then return; end; selected=id; A.DrawSettings();
end
function A.RefreshStatus()
 if A.editBar and A.editBar:IsShown() then S.SyncChildren(A.editBar); end
 if ASRStatsPanel and ASRStats and ASRStats.editing then S.SyncChildren(ASRStatsPanel); end
 if ASAdvisorTracker and ASAdvisor and ASAdvisor.suiteEditing then S.SyncChildren(ASAdvisorTracker); end
 if window and window:IsShown() then S.SyncChildren(window); end
 if not status then return; end
 status:SetText(A.T(not A.InRun() and "Настрой расположение сейчас; боевые числа появятся в забеге." or ""));
end
function A.DrawSettings()
 if not window then return; end
 S.Panel(window,ASRSuiteDB.opacity);
 for _,draw in ipairs(records) do draw(); end
 if A.TranslateLayout then A.TranslateLayout(); end
 for _,tab in ipairs(subnav) do local active=tab.target==selected; tab.button:SetBackdropColor(active and 0.22 or 0.12,active and 0.25 or 0.13,active and 0.29 or 0.15,1); tab.button:SetBackdropBorderColor(active and 0.85 or 0.5,active and 0.88 or 0.52,active and 0.93 or 0.56,1); end
 for _,p in ipairs(A.settingsPages) do
  if pages[p.id] then if p.id==selected then pages[p.id]:Show(); else pages[p.id]:Hide(); end end
  local active=p.id==selected; for _,child in ipairs(A.settingsPages) do if child.id==selected and child.parent==p.id then active=true; end end
  local b=nav[p.id]; if b then b:SetBackdropColor(active and 0.22 or 0.12,active and 0.25 or 0.13,active and 0.29 or 0.15,1); b:SetBackdropBorderColor(active and 0.85 or 0.5, active and 0.88 or 0.52,active and 0.93 or 0.56,1); end
  if p.draw then p.draw(pages[p.id]); end
 end
 A.RefreshStatus();
end
function A.ToggleSettings() if window:IsShown() then window:Hide(); else window:Show(); A.DrawSettings(); end end
local function RegisterBuiltins()
 A.RegisterSettingsPage("general","Общие",function(page)
  L(page,"Настройки комплекса",16,8,0,480);
  local lang=B(page,"",210,27,266,48,function() end); A.controls.language=lang; ASRLocale.Bind(lang,function() return ASRSuiteDB.language; end,A.SetLanguage); L(page,"Язык комплекса",11,8,52,250); records[#records+1]=function() lang.text:SetText(ASRLocale.Name(ASRSuiteDB.language)); end
  Step(page,"Фон настроек",function() return ASRSuiteDB.opacity; end,function(v) ASRSuiteDB.opacity=v; end,90,0.2,1,0.05,Percent);
  Step(page,"Фон трекеров",function() return ASRSuiteDB.trackerOpacity; end,function(v) ASRSuiteDB.trackerOpacity=v; end,126,0,1,0.05,Percent);
  Step(page,"Прозрачность чисел",function() return ASRSuiteDB.textOpacity; end,function(v) ASRSuiteDB.textOpacity=v; end,162,0,1,0.05,Percent);
  Note(page,"Модули используют общую прозрачность, пока не включена своя. Индивидуальные значения сохраняются.",204);
  Check(page,"Закрепить все панели",function() return ASRSuiteDB.lockPanels; end,function(v) ASRSuiteDB.lockPanels=v; end,253);
  B(page,"Изменить интерфейс",468,29,8,293,function() A.ToggleEdit(); end);
  Check(page,"Магнитная стыковка панелей",function() return ASRSuiteDB.dockingEnabled~=false; end,function(v) ASRSuiteDB.dockingEnabled=v; end,331);
  Note(page,"В режиме изменения интерфейса подведи панель к краю другой. Главная двигает всю цепочку; дочерняя отделяется вместе со своей цепочкой. Shift — без стыковки.",365):SetHeight(54);
  B(page,"Разъединить панели",468,27,8,428,function() if A.ClearDocking then A.ClearDocking(); end end);
 end);
 A.RegisterSettingsPage("combat","Текст урона",function(page)
  L(page,"Общие настройки текста",16,8,0,480);
  A.controls.enabled=Check(page,"Текст урона",function() return A.IsModuleEnabled("combat"); end,function(v) A.SetModuleEnabled("combat",v); end,38);
  local mode=B(page,"",468,25,8,69,function() A.CombatConfig().mode=A.CombatConfig().mode=="columns" and "enemies" or "columns"; A.ClearCombat(); Changed(); end);
  records[#records+1]=function() mode.text:SetText(A.T("Расположение: ")..A.T(A.CombatConfig().mode=="columns" and "Колонки" or "Над врагами")); end
  A.controls.mode=mode; A.controls.steps=StyleRows(page,function() return A.CombatConfig(); end,106);
  Check(page,"Иконки",function() return A.CombatConfig().icons; end,function(v) A.CombatConfig().icons=v; end,289);
  Check(page,"Короткие числа",function() return A.CombatConfig().short; end,function(v) A.CombatConfig().short=v; end,319);
  OverrideOpacity(page,"combat",349,"text");
  Step(page,"Прозрачность чисел",function() return A.CombatConfig().combatOpacity; end,function(v) A.CombatConfig().combatOpacity=v; end,382,0,1,0.05,Percent,function() return OwnOpacity("combat"); end);
 end);
 local titles={normal="Обычный урон",critical="Критические удары",heal="Исцеление",taken="Полученный урон",periodic="Периодический урон"};
 for _,k in ipairs(A.typeKeys) do local kind=k;
  A.RegisterSettingsPage(kind,titles[kind],function(page)
   L(page,titles[kind],16,8,0,480);
   A.controls.types=A.controls.types or {}; local c={}; A.controls.types[kind]=c;
   c.shown=Check(page,"Показывать этот тип",function() return A.TypeShown(kind); end,function(v) A.SetTypeShown(kind,v); end,37);
   c.custom=Check(page,"Использовать свои настройки",function() return A.CombatConfig().types[kind].custom; end,function(v) A.SetCustom(kind,v); end,68);
   local help=S.Label(page,"",10,8,103+(page.contentOffset or 0),468,S.muted); help:SetHeight(32);
   records[#records+1]=function() help:SetText(A.T(A.CombatConfig().types[kind].custom and "Используются индивидуальные значения этого типа." or "Используются общие значения. Включи галочку, чтобы изменить их только для этого типа.")); end
   c.steps=StyleRows(page,function() return A.CombatConfig().types[kind].custom and A.CombatConfig().types[kind].values or A.CombatConfig(); end,142,function() return A.CombatConfig().types[kind].custom; end);
   Check(page,"Иконки",function() return A.EffectiveOptions(kind).icons; end,function(v) A.CombatConfig().types[kind].values.icons=v; end,324,function() return A.CombatConfig().types[kind].custom; end);
   Check(page,"Короткие числа",function() return A.EffectiveOptions(kind).short; end,function(v) A.CombatConfig().types[kind].values.short=v; end,354,function() return A.CombatConfig().types[kind].custom; end);
  end);
 end
 A.RegisterSettingsPage("stats","Stats",function(page)
  L(page,"Stats",16,8,0,480);
  Check(page,"Модуль включён",function() return A.IsModuleEnabled("stats"); end,function(v) A.SetModuleEnabled("stats",v); end,36);
  local function Have() return ASRStatsDB and ASRStats; end
  Note(page,"Настройки панели характеристик. Расположение меняется в общем режиме редактирования.",64);
  Step(page,"Масштаб",function() return ASRStatsDB and ASRStatsDB.scale or 0.7; end,function(v) ASRStatsDB.scale=v; end,108,0.5,1.5,0.05,Percent,Have);
  Check(page,"Скрывать нули",function() return ASRStatsDB and ASRStatsDB.hideZeros; end,function(v) ASRStatsDB.hideZeros=v; end,145,Have);
  Check(page,"Закрепить",function() return ASRStatsDB and ASRStatsDB.locked; end,function(v) ASRStatsDB.locked=v; end,181,Have);
  OverrideOpacity(page,"stats",207);
  Step(page,"Непрозрачность",function() return ASRStatsDB and ASRStatsDB.opacity or 0.9; end,function(v) ASRStatsDB.opacity=v; end,243,0,1,0.05,Percent,function() return Have() and OwnOpacity("stats"); end);
  OverrideOpacity(page,"stats",285,"menu");
  Step(page,"Фон настроек",function() return ASRStatsDB and ASRStatsDB.menuOpacity or 0.95; end,function(v) ASRStatsDB.menuOpacity=v; end,321,0,1,0.05,Percent,function() return Have() and OwnOpacity("stats","menu"); end);
  B(page,"Изменить интерфейс",468,28,8,378,function() A.ToggleEdit(); end);
 end);
 A.RegisterSettingsPage("builder","Билдер",function(page)
  L(page,"Билдер",16,8,0,480);
  local function Have() return ASAdvisor and ASAdvisorDB and ASAdvisorDB.options; end
  Check(page,"Модуль включён",function() return A.IsModuleEnabled("builder"); end,function(v) A.SetModuleEnabled("builder",v); end,36);
  local function Opt() return Have() or {}; end
  B(page,"Открыть редактор билдов",468,28,8,73,function() if ASAdvisor and ASAdvisor.ToggleUI then ASAdvisor.ToggleUI(); window:Hide(); end end);
  Check(page,"Показывать трекер",function() return Have() and not Opt().trackerHidden; end,function(v) Opt().trackerHidden=not v; end,109,Have);
  local mode=B(page,"",468,25,8,143,function() if Have() then Opt().trackerMode=Opt().trackerMode=="compact" and "detailed" or "compact"; Changed(); end end);
  records[#records+1]=function() mode.text:SetText(A.T(Opt().trackerMode=="detailed" and "Трекер: подробный" or "Трекер: компактный")); end
  Step(page,"Масштаб редактора",function() return Opt().scale or 0.85; end,function(v) Opt().scale=v; end,181,0.55,1.3,0.05,Percent,Have);
  Step(page,"Масштаб трекера",function() return Opt().trackerScale or 0.85; end,function(v) Opt().trackerScale=v; end,215,0.5,1.3,0.05,Percent,Have);
  OverrideOpacity(page,"builder",251,"menu");
  local function Own() return Have() and OwnOpacity("builder","menu"); end
  Step(page,"Фон редактора",function() return Opt().opacity or 0.84; end,function(v) Opt().opacity=v; end,284,0.15,1,0.05,Percent,Own);
  OverrideOpacity(page,"builder",318);
  Step(page,"Фон трекера",function() return Opt().trackerOpacity or 0.42; end,function(v) Opt().trackerOpacity=v; end,351,0.1,1,0.05,Percent,function() return Have() and OwnOpacity("builder"); end);
  Note(page,"Билды, требования и импорт/экспорт доступны в редакторе билдов.",388);
 end);
 A.RegisterSettingsPage("compat","Совместимость",function(page)
  L(page,"Совместимость",16,8,0,480);
  Note(page,"Галочка включает элемент аддона. Стандартный вариант игры — рядом. Наведи курсор для пояснения.",35);
  local current=S.Label(page,"",10,8,77,468,S.muted); current:SetHeight(22);
  local scroll=CreateFrame("ScrollFrame",nil,page); scroll:SetSize(448,344); scroll:SetPoint("TOPLEFT",page,"TOPLEFT",8,-106); scroll:EnableMouseWheel(true);
  local list=CreateFrame("Frame",nil,scroll); list:SetSize(448,344); scroll:SetScrollChild(list);
  local groups={}; local maximum=0;
  local bar=CreateFrame("Frame",nil,page); bar:SetSize(20,344); bar:SetPoint("TOPLEFT",page,"TOPLEFT",476,-106);
  local slider=CreateFrame("Slider",nil,bar); slider:SetSize(14,292); slider:SetPoint("TOPLEFT",bar,"TOPLEFT",3,-26); slider:SetOrientation("VERTICAL"); slider:SetValueStep(1); slider:SetMinMaxValues(0,0);
  slider:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); slider:SetBackdropColor(0.12,0.13,0.15,1); slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob"); slider:GetThumbTexture():SetSize(14,28);
  local syncing=false;
  local function SetScroll(value)
   value=math.max(0,math.min(maximum,value)); scroll:SetVerticalScroll(value);
   if not syncing then syncing=true; slider:SetValue(value); syncing=false; end
  end
  slider:SetScript("OnValueChanged",function(self,value) if not syncing then syncing=true; SetScroll(value or self:GetValue()); syncing=false; end end);
  S.Button(bar,"↑",20,20,0,0,function() SetScroll(scroll:GetVerticalScroll()-40); end);
  S.Button(bar,"↓",20,20,0,324,function() SetScroll(scroll:GetVerticalScroll()+40); end);
  local function Wheel(self,delta) SetScroll(scroll:GetVerticalScroll()-delta*40); end
  local function WheelOn(frame) frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel",Wheel); end
  WheelOn(page); WheelOn(scroll); WheelOn(list); WheelOn(slider);
  A.compatibilityScroll={frame=scroll,bar=bar,slider=slider,set=SetScroll,maximum=function() return maximum; end};
  A.controls.compatibility={}; A.compatibilityGroups=groups;
  local function Explain(control,getText)
   control:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(A.T("Совместимость"),1,1,1); GameTooltip:AddLine(A.T(getText()),0.85,0.85,0.87,true); GameTooltip:Show(); end);
   control:SetScript("OnLeave",function() GameTooltip:Hide(); end);
  end
  A.RefreshCompatibility=function()
   local y=0;
   for _,spec in ipairs(A.compatibilityAddons) do
    local group=groups[spec.id];
    if not group then
     group={controls={},rows={},features={}}; groups[spec.id]=group; A.controls.compatibility[spec.id]=group.controls;
     group.frame=CreateFrame("Frame",nil,list); group.frame:SetWidth(448); WheelOn(group.frame);
     group.title=S.Label(group.frame,"",12,0,0,448);
    end
    group.title:SetText(A.T(spec.title));
    local rowY=20;
    for _,feature in ipairs(spec.features) do
     group.features[feature.id]=feature;
     local row=group.rows[feature.id];
     if not row then
      local featureId=feature.id;
      row=CreateFrame("Frame",nil,group.frame); row:SetWidth(448); WheelOn(row); group.rows[featureId]=row;
      local function Feature() return group.features[featureId]; end
      local control=Check(row,feature.title,function() return Feature().get(); end,function(on) Feature().set(on); end,0,function() return not Feature().available or Feature().available(); end);
      control.label:SetWidth(feature.fallback and 265 or 410); group.controls[featureId]=control; WheelOn(control);
      local hit=CreateFrame("Button",nil,row); WheelOn(hit); hit:SetSize(feature.fallback and 300 or 448,24); hit:SetPoint("TOPLEFT",row,"TOPLEFT",0,0); hit:SetScript("OnClick",function() control:GetScript("OnClick")(control); end);
      Explain(control,function() return Feature().description or Feature().title; end);
      Explain(hit,function() return Feature().description or Feature().title; end);
      if feature.fallback then
       local fallback=Check(row,feature.fallback.title,function() return Feature().fallback.get(); end,function(on) Feature().fallback.set(on); end,0);
       fallback:ClearAllPoints(); fallback:SetPoint("TOPLEFT",row,"TOPLEFT",310,0); fallback.label:ClearAllPoints(); fallback.label:SetPoint("TOPLEFT",row,"TOPLEFT",340,-3); fallback.label:SetWidth(108);
       row.fallback=fallback; WheelOn(fallback); group.controls[featureId.."Default"]=fallback;
       Explain(fallback,function() return "Использовать стандартный текст игры вместо текста аддона."; end);
      end
     end
     row:ClearAllPoints(); row:SetPoint("TOPLEFT",group.frame,"TOPLEFT",0,-rowY); row:SetHeight(28); rowY=rowY+30;
    end
    group.frame:SetHeight(rowY+8);
    if not spec.available or spec.available() then group.frame:Show(); group.frame:ClearAllPoints(); group.frame:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y); y=y+group.frame:GetHeight(); else group.frame:Hide(); end
   end
   local source=ASRSuiteDB.sources.combat; local names={asr="Текст ASR",game="Стандартный текст игры",survivor="Текст SurvivorUI",previous="Как было до ASR"};
   current:SetText(A.T("Текст урона сейчас: ")..A.T(names[source] or names.previous));
   list:SetHeight(math.max(344,y)); maximum=math.max(0,y-344); syncing=true; slider:SetMinMaxValues(0,maximum); syncing=false; SetScroll(scroll:GetVerticalScroll()); if maximum>0 then bar:Show(); else bar:Hide(); end
   if S.SyncChildren then S.SyncChildren(page); end
  end;
  A.RefreshCompatibility();
 end,function() if A.RefreshCompatibility then A.RefreshCompatibility(); end end);
end
function A.CreateSettings()
 window=CreateFrame("Frame","ASRSuiteSettings",UIParent); window:SetSize(740,610); window:SetPoint("CENTER",UIParent,"CENTER",0,0); window:SetFrameStrata("FULLSCREEN_DIALOG"); window:SetFrameLevel(400); window:SetClampedToScreen(true); window:EnableMouse(true); window:SetMovable(true); window:RegisterForDrag("LeftButton");
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRSuiteSettings",true); end
 window:SetScript("OnShow",function(self) self:SetFrameStrata("FULLSCREEN_DIALOG"); self:SetFrameLevel(400); if self.Raise then self:Raise(); end; S.SyncChildren(self); end);
 window:SetScript("OnDragStart",function(self) self:StartMoving(); end); window:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); end);
 window:SetScale(math.min(1,(UIParent:GetWidth()-24)/740,(UIParent:GetHeight()-24)/610)); S.Panel(window,ASRSuiteDB.opacity);
 L(window,"ASR / КОМПЛЕКС",17,24,24,420); L(window,"by AlexEnotov",9,25,47,250,S.muted);
 A.controls={}; A.controls.edit=B(window,"Изменить интерфейс",230,26,456,24,function() A.ToggleEdit(); end);
 B(window,"×",24,22,692,26,function() window:Hide(); end);
 RegisterBuiltins();
 MountPage=function(p,i)
  local id=p.id;
  local installed=not (id=="stats" and not ASRStats or id=="builder" and not ASAdvisor or (id=="combat" or p.parent=="combat") and not A.HasCombat());
  if not p.parent then navCount=navCount+1; nav[id]=B(window,p.title,170,28,24,87+(navCount-1)*34,function() A.SelectSettingsPage(id); end); if not installed then nav[id]:SetAlpha(0.5); end end
  local page=CreateFrame("Frame",nil,window); page:SetSize(500,465); page:SetPoint("TOPLEFT",window,"TOPLEFT",212,-88); pages[id]=page;
  if installed then
   if p.parent or id=="combat" then page.contentOffset=40; end
   if p.build then p.build(page); end
  else L(page,p.title,16,8,0,480); Note(page,"Не установлен. Установи и включи этот аддон, чтобы открыть его настройки.",48); page.unavailable=true; end
  if page.contentOffset then
   local tabs=CreateFrame("Frame",nil,page); tabs:SetSize(500,58); tabs:SetPoint("TOPLEFT",page,"TOPLEFT",0,0);
   for j,entry in ipairs({{"combat","Общие"},{"normal","Обычный урон"},{"critical","Критические удары"},{"heal","Исцеление"},{"taken","Полученный урон"},{"periodic","Периодический урон"}}) do local target=entry[1]; local button=B(tabs,entry[2],156,25,8+((j-1)%3)*160,math.floor((j-1)/3)*30,function() A.SelectSettingsPage(target); end); subnav[#subnav+1]={button=button,target=target}; end
  end
 end
 for i,p in ipairs(A.settingsPages) do MountPage(p,i); end
 status=S.Label(window,"",10,214,563,500,S.muted); status:SetHeight(28);
 A.settings=window; A.pages=pages; A.navigation=nav; window:Hide(); A.DrawSettings();
end

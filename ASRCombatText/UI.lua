local A=ASRCombatText; local S=ASRStyle; local panel,kindButton,custom,shown; local index=1; local targets={"all","normal","critical","heal","taken","periodic"}; local handles={}; local rows={};
local names={all={"Общие","Shared"},normal={"Обычный урон","Normal damage"},critical={"Криты","Critical hits"},heal={"Лечение","Healing"},taken={"Входящий урон","Incoming damage"},periodic={"Периодический","Periodic damage"}};
local function T(ru,en) return ASRLocale.Text("combat",ASRCombatTextDB.language,ru,en); end
local function Config() local k=targets[index]; return k=="all" and ASRCombatTextDB or A.EffectiveOptions(k); end
local function Editable() return index==1 or ASRCombatTextDB.types[targets[index]].custom; end
local function Refresh()
 if not panel then return; end
 for key,h in pairs(handles) do h.label:SetText(T(names[key][1],names[key][2])); end
 if A.testButton then A.testButton.text:SetText(T("Тест","Test")); A.doneButton.text:SetText(T("Готово","Done")); end
 panel.title:SetText(T("ASR / ТЕКСТ УРОНА","ASR / COMBAT TEXT")); panel.enabled.text:SetText(T("Модуль: ","Module: ")..(ASRCombatTextDB.enabled and T("Вкл.","On") or T("Выкл.","Off")));
 panel.mode.text:SetText(T("Расположение: ","Placement: ")..(ASRCombatTextDB.mode=="columns" and T("Колонки","Columns") or T("Над врагами","Above enemies")));
 kindButton.text:SetText(T("Тип: ","Type: ")..T(names[targets[index]][1],names[targets[index]][2]));
 custom.text:SetText(index==1 and T("Общие настройки","Shared settings") or (Editable() and "[x] " or "[ ] ")..T("Свои настройки","Custom settings"));
 shown.text:SetText(index==1 and T("Все типы","All types") or (A.TypeShown(targets[index]) and "[x] " or "[ ] ")..T("Показывать","Show"));
 for _,r in ipairs(rows) do r.label:SetText(T(r.ru,r.en)); r.value:SetText(string.format("%.2f",Config()[r.key])); r.minus:SetAlpha(Editable() and 1 or 0.4); r.plus:SetAlpha(Editable() and 1 or 0.4); end
 panel.icons.text:SetText((Config().icons and "[x] " or "[ ] ")..T("Иконки","Icons")); panel.short.text:SetText((Config().short and "[x] " or "[ ] ")..T("Короткие числа","Short numbers")); panel.edit.text:SetText(T("Изменить интерфейс","Edit interface")); panel.lang.text:SetText(ASRLocale.Name(ASRCombatTextDB.language)); S.SyncChildren(panel);
end
function A.SetEditing(on)
 A.editing=on; if A.suiteAttached then on=false; A.editing=false; end
 for key,h in pairs(handles) do h:ClearAllPoints(); local p=ASRCombatTextDB.positions[key]; h:SetPoint("CENTER",UIParent,"CENTER",p.x,p.y); if on then h:Show(); else if h.moving then h:StopMovingOrSizing(); h.moving=false; end; h:Hide(); end end
 if on then panel:Hide(); A.editBar:Show(); A.Example(); else A.editBar:Hide(); end
end
function A.ToggleSettings() if panel:IsShown() then panel:Hide(); else panel:Show(); Refresh(); end end
function A.CreateUI()
 panel=CreateFrame("Frame","ASRCombatTextSettings",UIParent); panel:SetSize(430,500); panel:SetPoint("CENTER",UIParent,"CENTER",0,0); panel:SetFrameStrata("FULLSCREEN_DIALOG"); panel:SetFrameLevel(400); panel:SetClampedToScreen(true); S.Panel(panel,0.97); panel:SetScale(math.min(1,(UIParent:GetHeight()-24)/500));
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRCombatTextSettings",true); end
 panel.title=S.Label(panel,"",12,24,24,160); panel.edit=S.Button(panel,"",102,24,200,22,function() A.SetEditing(true); end); panel.lang=S.Button(panel,"",96,24,310,22,function() end);
 ASRLocale.Bind(panel.lang,function() return ASRCombatTextDB.language; end,function(code) ASRCombatTextDB.language=ASRLocale.Normalize(code); end,Refresh);
 panel.enabled=S.Button(panel,"",382,26,24,60,function() A.SetEnabled(not ASRCombatTextDB.enabled); Refresh(); end);
 panel.mode=S.Button(panel,"",382,26,24,92,function() ASRCombatTextDB.mode=ASRCombatTextDB.mode=="columns" and "enemies" or "columns"; A.ClearCombat(); Refresh(); end);
 kindButton=S.Button(panel,"",382,26,24,124,function() index=index%#targets+1; Refresh(); end);
 custom=S.Button(panel,"",185,25,24,156,function() if index>1 then A.SetCustom(targets[index],not Editable()); Refresh(); end end);
 shown=S.Button(panel,"",185,25,221,156,function() if index>1 then A.SetTypeShown(targets[index],not A.TypeShown(targets[index])); Refresh(); end end);
 for i,spec in ipairs({{"fontSize","Размер","Size",10,36,2},{"scrollSpeed","Скорость","Speed",0,300,10},{"lifetime","Время показа","Lifetime",0.6,4,0.2},{"rise","Высота","Distance",20,200,10},{"merge","Объединение, с","Merge, s",0,1,0.05},{"spacing","Мин. отступ","Min gap",0,80,1}}) do
  local key=spec[1]; local y=192+(i-1)*31; local r={key=key,ru=spec[2],en=spec[3]}; r.label=S.Label(panel,"",11,24,y+3,180); r.value=S.Label(panel,"",11,271,y+3,90); r.value:SetJustifyH("CENTER");
  local function Step(sign) if Editable() then Config()[key]=math.max(spec[4],math.min(spec[5],Config()[key]+sign*spec[6])); Refresh(); end end
  r.minus=S.Button(panel,"−",25,24,237,y,function() Step(-1); end); r.plus=S.Button(panel,"+",25,24,381,y,function() Step(1); end); rows[#rows+1]=r;
 end
 panel.icons=S.Button(panel,"",185,25,24,386,function() if Editable() then Config().icons=not Config().icons; Refresh(); end end);
 panel.short=S.Button(panel,"",185,25,221,386,function() if Editable() then Config().short=not Config().short; Refresh(); end end);
 S.Label(panel,"/asrtext · by AlexEnotov",10,24,452,320,S.muted); S.Button(panel,"×",25,24,381,452,function() panel:Hide(); end);
 A.settings=panel; panel:Hide();
 for _,key in ipairs(A.lanes) do local lane=key; local h=CreateFrame("Frame",nil,UIParent); h:SetSize(180,36); h:SetFrameStrata("FULLSCREEN_DIALOG"); h:SetMovable(true); h:SetClampedToScreen(true); h:EnableMouse(true); h:RegisterForDrag("LeftButton"); S.Panel(h,0.95); h.label=S.Label(h,T(names[lane][1],names[lane][2]),10,16,10,148);
  h:SetScript("OnDragStart",function(self) self.moving=true; self:StartMoving(); end); h:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); self.moving=false; local x,y=self:GetCenter(); ASRCombatTextDB.positions[lane]={x=x-UIParent:GetWidth()/2,y=y-UIParent:GetHeight()/2}; end); h:SetScript("OnHide",function(self) if self.moving then self:StopMovingOrSizing(); self.moving=false; end end); h:Hide(); handles[lane]=h;
 end
 A.editBar=CreateFrame("Frame",nil,UIParent); A.editBar:SetSize(240,58); A.editBar:SetPoint("TOP",UIParent,"TOP",0,-30); A.editBar:SetFrameStrata("FULLSCREEN_DIALOG"); S.Panel(A.editBar,1); A.testButton=S.Button(A.editBar,"Test",86,24,24,18,A.Example); A.doneButton=S.Button(A.editBar,"Done",86,24,130,18,function() A.SetEditing(false); end); A.editBar:Hide();
 if Minimap then local b=CreateFrame("Button","ASRCombatTextMinimap",Minimap); b:SetSize(28,28); b:SetFrameStrata("HIGH"); local function Place() local angle=math.rad(ASRCombatTextDB.minimapAngle); local radius=Minimap:GetWidth()/2+10; b:ClearAllPoints(); b:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius); end; Place(); b:RegisterForClicks("LeftButtonUp","RightButtonUp"); local disk=b:CreateTexture(nil,"BACKGROUND"); if IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") then
   disk:SetSize(59,59); disk:SetPoint("CENTER",b,"CENTER",0,0); disk:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\actionbutton-backdrop"); local rim=b:CreateTexture(nil,"ARTWORK"); rim:SetSize(59,59); rim:SetPoint("CENTER",b,"CENTER",0,0); rim:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\actionbutton-border");
  else disk:SetAllPoints(b); disk:SetTexture("Interface\\AddOns\\ASRCombatText\\media\\minimap.tga"); end; local mark=S.Label(b,"DMG",8,0,0,26); mark:ClearAllPoints(); mark:SetPoint("CENTER",b,"CENTER",0,0); mark:SetHeight(12); mark:SetJustifyH("CENTER");
  b:RegisterForDrag("LeftButton"); b:SetScript("OnDragStart",function(self) self.dragging=true; end); b:SetScript("OnDragStop",function(self) self.dragging=false; self.clickAfter=GetTime()+0.15; end);
  b:SetScript("OnUpdate",function(self) if not self.dragging then return; end; if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then self.dragging=false; return; end; local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale(); x,y=x/scale-cx,y/scale-cy; local angle; if math.atan2 then angle=math.atan2(y,x); elseif x==0 then angle=y>=0 and math.pi/2 or -math.pi/2; else angle=math.atan(y/x); if x<0 then angle=angle+math.pi; end end; ASRCombatTextDB.minimapAngle=math.deg(angle)%360; Place(); end);
  b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("ASR Combat Text"); GameTooltip:AddLine(T("ЛКМ — настройки, ПКМ — перемещение колонок","Left click: settings; right click: move columns"),0.8,0.8,0.82,true); GameTooltip:Show(); end); b:SetScript("OnLeave",function() GameTooltip:Hide(); end);
  b:SetScript("OnClick",function(self,button) if self.clickAfter and GetTime()<self.clickAfter then return; end; if button=="RightButton" then A.SetEditing(not A.editing); else A.ToggleSettings(); end end); A.minimap=b;
 end
 if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ASRCombatTextSettings"; end
 Refresh();
end

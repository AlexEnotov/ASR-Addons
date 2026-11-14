local A,S=ASRLoot,ASRStyle; local panel;
local function Hud(on)
 if not AZS_SetHudShown or not AZS_IsHudShown then return; end
 local d=ASRLootDB; local owner=AZS_API_HUD and AZS_API_HUD.loot;
 if on then
  if not d.nativeLoot then d.nativeLoot={previous=AZS_IsHudShown("loot") or owner=="ASRLoot"}; end
  if AZS_IsHudShown("loot") then AZS_SetHudShown("loot",false); end
 elseif d.nativeLoot then
  if d.nativeLoot.previous and (owner=="ASRLoot" or owner==nil) then AZS_SetHudShown("loot",true); end
  d.nativeLoot=nil;
 end
end
local function Rarity(r)
 local c=r~=nil and AZS_GEAR_RARITY and AZS_GEAR_RARITY[r]; if c then return c[2],c[3],c[4]; end
 local colors={[0]={1,1,1},{0.12,1,0},{0,0.44,0.87},{0.64,0.21,0.93},{1,0.5,0},{0.9,0.75,0.45}};
 c=colors[r]; if c then return unpack(c); end; return 0.7,0.7,0.73;
end
local function RarityName(r)
 local names={[0]="Обычный","Необычный","Редкий","Эпический","Легендарный","PvP"};
 if names[r] then return A.T(names[r]); end
 local tier=r and AZS_GEN and AZS_GEN.gearTiers and AZS_GEN.gearTiers[r-5];
 return tier and tier.name or A.T("Неизвестная редкость");
end
function A.Refresh()
 if not panel or not A.ready then return; end
 local editing=A.editing or ASRSuite and ASRSuite.editing;
 panel:SetFrameStrata(editing and "FULLSCREEN_DIALOG" or "HIGH"); panel:SetFrameLevel(editing and 450 or 10);
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRLootTracker",editing and true or false); end
 local enabled=ASRLootDB.enabled~=false;
 Hud(enabled and ASRLootDB.replaceNative and A.InRun());
 local run=A.InRun() and A.EnsureRun() or ASRLootDB.run or {};
 local rows=A.Rows(); local visible=enabled and (A.InRun() and run.panelOpen or A.inspect or editing);
 if not visible then panel:Hide(); return; end
 local count=math.min(15,#rows); local gridHeight=count>0 and math.ceil(count/5)*30 or 14;
 panel:SetWidth(196); panel:SetScale(ASRLootDB.scale); panel:SetHeight(64+gridHeight+(ASRLootDB.mode=="all" and 14 or 0)); panel:Show();
 S.Panel(panel,ASRSuite and ASRSuiteDB and ASRSuiteDB.trackerOpacity or 0.9);
 panel.title:SetText("|cff8cd123ASR|r / "..A.T("Добыча"));
 panel.empty:SetText(A.T("Пока нет предметов")); if count==0 then panel.empty:Show(); else panel.empty:Hide(); end
 A.offset=math.max(0,math.min(A.offset or 0,math.max(0,#rows-15)));
 for i,row in ipairs(panel.rows) do
  local item=rows[i+A.offset];
  if i>count then row:Hide();
  else
   row:Show();
   if item then
    local icon=item.icon or "INV_Misc_QuestionMark"; if not string.find(icon,"[\\/]") then icon="Interface\\Icons\\"..icon; end; row.icon:SetTexture(icon);
    local r,g,b=Rarity(item.rarity); row:SetBackdropBorderColor(r,g,b,1);
    row.count:SetText(item.count>1 and "×"..item.count or "");
    row.item=item;
   else row:Hide(); row.item=nil; end
  end
 end
 panel.footer:ClearAllPoints(); panel.footer:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-(50+gridHeight));
 panel.footer:SetText(ASRLootDB.mode=="all" and string.format(A.T("Золото: %d"),run.gold or 0) or "");
 if S.SyncChildren then S.SyncChildren(panel); end
end
function A.CreateUI()
 if panel then return; end
 panel=CreateFrame("Frame","ASRLootTracker",UIParent);
 panel.asrDockInsets=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") and {left=1.5,right=1.5,top=10,bottom=11} or nil; A.frame=panel; panel:SetSize(196,78); panel:SetScale(ASRLootDB.scale); panel:SetFrameStrata("HIGH"); panel:SetFrameLevel(10); panel:SetClampedToScreen(true);
 local p=ASRLootDB.position;
 if p then panel:SetPoint(p.point or "TOPLEFT",UIParent,p.relative or "TOPLEFT",tonumber(p.x) or 330,tonumber(p.y) or -80); else panel:SetPoint("TOPLEFT",UIParent,"TOPLEFT",330,-80); end
 panel.title=S.Label(panel,"",9,20,23,129); panel.close=S.Button(panel,"×",20,16,156,22,A.Close);
 panel.empty=S.Label(panel,"",9,20,48,156,S.muted); panel.rows={};
 panel.titleHit=CreateFrame("Frame",nil,panel); panel.titleHit:SetSize(132,20); panel.titleHit:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-20); panel.titleHit:EnableMouse(true);
 panel.titleHit:SetScript("OnEnter",function(self)
  local run=ASRLootDB.run or {}; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("ASR Loot");
  GameTooltip:AddLine(A.T(ASRLootDB.mode=="all" and "Вся добыча" or "Только новые"));
  GameTooltip:AddLine(string.format(A.T("Новые: %d · Дубликаты: %d"),run.newCount or 0,run.duplicateCount or 0));
  GameTooltip:AddLine(string.format(A.T("Золото за дубликаты: %d"),run.gold or 0)); GameTooltip:Show();
 end); panel.titleHit:SetScript("OnLeave",function() GameTooltip:Hide(); end);
 for i=1,15 do
  local row=CreateFrame("Frame",nil,panel); row:SetSize(24,24); row:SetPoint("TOPLEFT",panel,"TOPLEFT",20+((i-1)%5)*30,-(48+math.floor((i-1)/5)*30)); row:EnableMouse(true);
  row:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});
  row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("TOPLEFT",row,"TOPLEFT",1,-1); row.icon:SetTexCoord(0.08,0.92,0.08,0.92);
  row.count=S.Label(row,"",9,0,14,24); row.count:SetJustifyH("RIGHT");
  row:SetScript("OnEnter",function(self)
   if not self.item then return; end; local item=self.item; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(item.name,Rarity(item.rarity));
   GameTooltip:AddLine(RarityName(item.rarity),Rarity(item.rarity));
   if item.count>1 then GameTooltip:AddLine(string.format(A.T("Количество: %d"),item.count)); end
   GameTooltip:AddLine(item.kind=="new" and A.T("Новый") or A.T("Продано").." · +"..item.gold,0.8,0.8,0.82);
   GameTooltip:Show();
  end); row:SetScript("OnLeave",function() GameTooltip:Hide(); end);
  row:EnableMouseWheel(true); row:SetScript("OnMouseWheel",function(self,d) A.offset=(A.offset or 0)-d*5; A.Refresh(); end); panel.rows[i]=row;
 end
 panel.footer=S.Label(panel,"",9,20,70,156,S.muted);
 panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton");
 panel:SetScript("OnDragStart",function(self) if not ASRSuite or not ASRSuite.CanMovePanel or ASRSuite.CanMovePanel("loot") then self:StartMoving(); self.moving=true; end end);
 panel:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); self.moving=false; local point,_,relative,x,y=self:GetPoint(); ASRLootDB.position={point=point,relative=relative,x=x,y=y}; end);
 panel.titleHit:RegisterForDrag("LeftButton"); panel.titleHit:SetScript("OnDragStart",function() panel:GetScript("OnDragStart")(panel); end); panel.titleHit:SetScript("OnDragStop",function() panel:GetScript("OnDragStop")(panel); end);
 panel:EnableMouseWheel(true); panel:SetScript("OnMouseWheel",function(self,d) A.offset=(A.offset or 0)-d*5; A.Refresh(); end); panel:Hide(); A.Refresh();
end
function A.BindSuite()
 local suite=ASRSuite; if not suite or not suite.ready then return; end
 if ASRSuiteDB and ASRLootDB.language~=ASRSuiteDB.language then A.SetLanguage(ASRSuiteDB.language); end
 if A.suiteBound then return; end; A.suiteBound=true;
 suite.RegisterSettingsPage("loot","ASR Loot",function(page)
  page.lootLabels={};
  local function Label(key,y) local f=S.Label(page,A.T(key),11,36,y+3,432); page.lootLabels[#page.lootLabels+1]={frame=f,key=key}; return f; end
  local function Check(key,y,get,set)
   local f=CreateFrame("CheckButton",nil,page,"UICheckButtonTemplate"); f:SetSize(24,24); f:SetPoint("TOPLEFT",page,"TOPLEFT",6,-y); Label(key,y);
   f:SetScript("OnClick",function() set(not get()); A.Refresh(); suite.DrawSettings(); end); return f;
  end
  page.lootTitle=S.Label(page,"|cff8cd123ASR|r Loot",16,8,0,480);
  page.lootEnabled=Check("Модуль включён",32,function() return ASRLootDB.enabled; end,A.SetEnabled);
  page.lootOpen=S.Button(page,"",230,26,8,66,A.Open); page.lootClose=S.Button(page,"",230,26,246,66,A.Close);
  page.lootStart=Check("Открывать в начале забега",102,function() return ASRLootDB.openOnStart; end,function(v) if v then A.SetAutoOpen("start"); else ASRLootDB.openOnStart=false; end end);
  page.lootDrop=Check("Открывать при выпадении предмета",132,function() return ASRLootDB.openOnDrop; end,function(v) if v then A.SetAutoOpen("drop"); else ASRLootDB.openOnDrop=false; end end);
  page.lootMode=S.Button(page,"",468,26,8,166,function() A.SetMode(ASRLootDB.mode=="all" and "new" or "all"); suite.DrawSettings(); end);
  page.lootNative=Check("Скрыть обычные уведомления о добыче",202,function() return ASRLootDB.replaceNative; end,function(v) ASRLootDB.replaceNative=v; end);
  local scaleLabel=S.Label(page,A.T("Масштаб"),11,8,242,280); page.lootLabels[#page.lootLabels+1]={frame=scaleLabel,key="Масштаб"};
  page.lootScale=S.Label(page,"",11,338,242,100); page.lootScale:SetJustifyH("CENTER");
  local function Scale(delta) ASRLootDB.scale=math.max(0.5,math.min(1.5,ASRLootDB.scale+delta)); A.Refresh(); suite.DrawSettings(); end
  page.lootScaleMinus=S.Button(page,"−",26,25,304,238,function() Scale(-0.01); end); page.lootScalePlus=S.Button(page,"+",26,25,450,238,function() Scale(0.01); end);
  for i,key in ipairs({"Выбери автоматическое открытие в начале забега или при выпадении вещи. Без обеих галочек панель открывается вручную.","Учитываются постоянные броня и оружие. Звёзды не отслеживаются.","Сумма золота — только за проданные дубликаты в этом забеге."}) do local f=S.Label(page,A.T(key),10,8,280+(i-1)*44,468,S.muted); f:SetHeight(36); page.lootLabels[#page.lootLabels+1]={frame=f,key=key}; end
 end,function(page)
  if not page.lootEnabled then return; end
  page.lootEnabled:SetChecked(ASRLootDB.enabled); page.lootNative:SetChecked(ASRLootDB.replaceNative); page.lootMode.text:SetText(A.T(ASRLootDB.mode=="all" and "Вся добыча" or "Только новые"));
  page.lootScale:SetText(math.floor(ASRLootDB.scale*100+0.5).."%");
  page.lootStart:SetChecked(ASRLootDB.openOnStart); page.lootDrop:SetChecked(ASRLootDB.openOnDrop);
  page.lootOpen.text:SetText(A.T("Открыть панель")); page.lootClose.text:SetText(A.T("Закрыть панель"));
  for _,entry in ipairs(page.lootLabels) do entry.frame:SetText(A.T(entry.key)); end
 end);
 if suite.RegisterPanel then suite.RegisterPanel("loot",{frame=panel,setEditing=function(on) A.editing=on; A.Refresh(); end,available=function() return panel:IsShown(); end,
  savePosition=function(r) ASRLootDB.position={point="TOPLEFT",relative="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; end}); end
 if suite.RegisterCompatibilityAddon then suite.RegisterCompatibilityAddon("loot","ASR Loot",function() return true; end,{{id="tracker",title="ASR Loot",get=function() return ASRLootDB.enabled; end,set=A.SetEnabled}}); end
end

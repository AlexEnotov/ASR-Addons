local A,S=ASRLoot,ASRStyle; local panel;
local function Fit(label,text,width)
 label:SetText(text); label:SetWidth(width); local size=11;
 while size>9 and label:GetStringWidth()>width do size=size-1; label:SetFont(S.font,size,""); end
 if label:GetStringWidth()>width then
  local chars={}; for c in string.gmatch(text,"[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=c; end
  repeat table.remove(chars); label:SetText(table.concat(chars).."…"); until #chars==0 or label:GetStringWidth()<=width;
 end
end
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
function A.Refresh()
 if not panel or not A.ready then return; end
 local editing=A.editing or ASRSuite and ASRSuite.editing;
 panel:SetFrameStrata(editing and "FULLSCREEN_DIALOG" or "HIGH"); panel:SetFrameLevel(editing and 450 or 10);
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRLootTracker",editing and true or false); end
 local enabled=ASRLootDB.enabled~=false;
 Hud(enabled and ASRLootDB.replaceNative and A.InRun());
 local rows=A.Rows(); local visible=enabled and (A.InRun() and #rows>0 or A.inspect or editing);
 if not visible then panel:Hide(); return; end
 local count=math.min(6,math.max(1,#rows)); local run=ASRLootDB.run or {};
 panel:SetHeight(122+count*28); panel:Show();
 S.Panel(panel,ASRSuite and ASRSuiteDB and ASRSuiteDB.trackerOpacity or 0.9);
 panel.title:SetText("|cff8cd123ASR|r / "..A.T("Добыча"));
 panel.mode.text:SetText(A.T(ASRLootDB.mode=="all" and "Вся добыча" or "Только новые"));
 panel.summary:SetText(string.format(A.T("Новые: %d · Дубликаты: %d"),run.newCount or 0,run.duplicateCount or 0));
 A.offset=math.max(0,math.min(A.offset or 0,math.max(0,#rows-6)));
 for i,row in ipairs(panel.rows) do
  local item=rows[i+A.offset];
  if i>count then row:Hide();
  else
   row:Show();
   if item then
    local icon=item.icon or "INV_Misc_QuestionMark"; if not string.find(icon,"[\\/]") then icon="Interface\\Icons\\"..icon; end; row.icon:SetTexture(icon);
    row.name:SetFont(S.font,11,""); Fit(row.name,item.name,174); row.name:SetTextColor(Rarity(item.rarity));
    row.count:SetText(item.count>1 and "×"..item.count or "");
    row.info:SetText(item.kind=="new" and A.T("Новый") or (A.T("Продано").." · +"..item.gold));
    row.item=item;
   else row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); row.name:SetText(A.T("Пока нет предметов")); row.name:SetTextColor(0.7,0.7,0.73); row.info:SetText(""); row.count:SetText(""); row.item=nil; end
  end
 end
 panel.footer:ClearAllPoints(); panel.footer:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-(103+count*28));
 panel.footer:SetText(ASRLootDB.mode=="all" and string.format(A.T("Золото за дубликаты: %d"),run.gold or 0) or (#rows>6 and A.T("Прокрутка колёсиком") or ""));
 if S.SyncChildren then S.SyncChildren(panel); end
end
function A.CreateUI()
 if panel then return; end
 panel=CreateFrame("Frame","ASRLootTracker",UIParent); A.frame=panel; panel:SetSize(270,150); panel:SetFrameStrata("HIGH"); panel:SetFrameLevel(10); panel:SetClampedToScreen(true);
 local p=ASRLootDB.position;
 if p then panel:SetPoint(p.point or "TOPLEFT",UIParent,p.relative or "TOPLEFT",tonumber(p.x) or 330,tonumber(p.y) or -80); else panel:SetPoint("TOPLEFT",UIParent,"TOPLEFT",330,-80); end
 panel.title=S.Label(panel,"",11,16,18,210); panel.close=S.Button(panel,"×",20,18,232,16,function() A.inspect=false; A.SetEnabled(false); end);
 panel.mode=S.Button(panel,"",238,23,16,43,function() A.SetMode(ASRLootDB.mode=="all" and "new" or "all"); end);
 panel.summary=S.Label(panel,"",10,16,74,238,S.muted); panel.rows={};
 for i=1,6 do
  local row=CreateFrame("Frame",nil,panel); row:SetSize(238,28); row:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-(98+(i-1)*28)); row:EnableMouse(true);
  row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(24,24); row.icon:SetPoint("TOPLEFT",row,"TOPLEFT",0,0);
  row.name=S.Label(row,"",11,30,0,174); row.info=S.Label(row,"",9,30,14,174,S.muted); row.count=S.Label(row,"",10,204,2,34); row.count:SetJustifyH("RIGHT");
  row:SetScript("OnEnter",function(self)
   if not self.item then return; end; local item=self.item; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(item.name,Rarity(item.rarity));
   if item.rarity==nil then GameTooltip:AddLine(A.T("Неизвестная редкость"),0.7,0.7,0.73); end
   GameTooltip:AddLine(item.kind=="new" and A.T("Новый") or A.T("Продано").." · +"..item.gold,0.8,0.8,0.82);
   GameTooltip:Show();
  end); row:SetScript("OnLeave",function() GameTooltip:Hide(); end);
  row:EnableMouseWheel(true); row:SetScript("OnMouseWheel",function(self,d) A.offset=(A.offset or 0)-d; A.Refresh(); end); panel.rows[i]=row;
 end
 panel.footer=S.Label(panel,"",10,16,131,238,S.muted);
 panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton");
 panel:SetScript("OnDragStart",function(self) if not ASRSuite or not ASRSuite.CanMovePanel or ASRSuite.CanMovePanel("loot") then self:StartMoving(); self.moving=true; end end);
 panel:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); self.moving=false; local point,_,relative,x,y=self:GetPoint(); ASRLootDB.position={point=point,relative=relative,x=x,y=y}; end);
 panel:EnableMouseWheel(true); panel:SetScript("OnMouseWheel",function(self,d) A.offset=(A.offset or 0)-d; A.Refresh(); end); panel:Hide(); A.Refresh();
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
  page.lootTitle=S.Label(page,"ASR Loot",16,8,0,480);
  page.lootEnabled=Check("Показать трекер добычи",32,function() return ASRLootDB.enabled; end,A.SetEnabled);
  page.lootMode=S.Button(page,"",468,26,8,66,function() A.SetMode(ASRLootDB.mode=="all" and "new" or "all"); suite.DrawSettings(); end);
  page.lootNative=Check("Скрыть обычные уведомления о добыче",104,function() return ASRLootDB.replaceNative; end,function(v) ASRLootDB.replaceNative=v; end);
  for i,key in ipairs({"Учитываются постоянные броня и оружие. Звёзды не отслеживаются.","Сумма золота — только за проданные дубликаты в этом забеге."}) do local f=S.Label(page,A.T(key),10,8,146+(i-1)*44,468,S.muted); f:SetHeight(36); page.lootLabels[#page.lootLabels+1]={frame=f,key=key}; end
 end,function(page)
  if not page.lootEnabled then return; end
  page.lootEnabled:SetChecked(ASRLootDB.enabled); page.lootNative:SetChecked(ASRLootDB.replaceNative); page.lootMode.text:SetText(A.T(ASRLootDB.mode=="all" and "Вся добыча" or "Только новые"));
  for _,entry in ipairs(page.lootLabels) do entry.frame:SetText(A.T(entry.key)); end
 end);
 if suite.RegisterPanel then suite.RegisterPanel("loot",{frame=panel,setEditing=function(on) A.editing=on; A.Refresh(); end,available=function() return panel:IsShown(); end,
  savePosition=function(r) ASRLootDB.position={point="TOPLEFT",relative="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; end}); end
 if suite.RegisterCompatibilityAddon then suite.RegisterCompatibilityAddon("loot","ASR Loot",function() return true; end,{{id="tracker",title="ASR Loot",get=function() return ASRLootDB.enabled; end,set=A.SetEnabled}}); end
end

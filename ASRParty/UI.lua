local A,S=ASRParty,ASRStyle;
local prefixes={"AzerothSurvivorsPartyUnitButton","AzeritePartyUnitButton","PartyMemberFrame"};
local native,hooked={},{}; A.nativeRecords=native;
function A.MuteNative(frame)
 if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do A.MuteNative(child); end end
 if not native[frame] then native[frame]={alpha=A.Safe(frame.GetAlpha,frame) or 1,mouse=A.Safe(frame.IsMouseEnabled,frame)}; end
 frame:SetAlpha(0); if frame.EnableMouse then frame:EnableMouse(false); end
 if frame.HookScript and not hooked[frame] then
  hooked[frame]=true; frame:HookScript("OnShow",function(self) if A.active and native[self] then self:SetAlpha(0); if self.EnableMouse then self:EnableMouse(false); end end end);
 end
end
function A.HideNative()
 for _,prefix in ipairs(prefixes) do for i=1,4 do local f=_G[prefix..i]; if f then A.MuteNative(f); end end end
end
function A.RestoreNative()
 local pieces={}; for frame,saved in pairs(native) do local depth=0; local parent=A.Safe(frame.GetParent,frame); while parent do depth=depth+1; parent=A.Safe(parent.GetParent,parent); end; pieces[#pieces+1]={frame=frame,saved=saved,depth=depth}; end
 table.sort(pieces,function(a,b) return a.depth<b.depth; end);
 for _,piece in ipairs(pieces) do local frame,saved=piece.frame,piece.saved;
  frame:SetAlpha(saved.alpha);
  if frame.EnableMouse then frame:EnableMouse(saved.mouse~=false); end; native[frame]=nil;
 end
end
local function Color(class)
 local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]; if c then return c.r,c.g,c.b; end; return 0.45,0.75,0.35;
end
local function Fit(label,text,width)
 text=tostring(text or ""); label:SetWidth(width); label:SetText(text);
 if label:GetStringWidth()<=width then return; end
 local chars={}; for c in string.gmatch(text,"[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=c; end
 repeat table.remove(chars); label:SetText(table.concat(chars).."…"); until #chars==0 or label:GetStringWidth()<=width;
end
function A.Inspect(row)
 if not row or row.preview or A.editing or ASRSuite and ASRSuite.editing then return; end
 if A.draggedUntil and GetTime and GetTime()<A.draggedUntil then return; end
 if A.Bool(UnitExists,row.unit) and AZS_InspectUnit then AZS_InspectUnit(row.unit); end
end
local function Tooltip(button,refresh)
 local m=button.model; if not m or m.preview or A.editing or ASRSuite and ASRSuite.editing then return; end
 if not refresh then GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); A.tooltipOwner=button; end; GameTooltip:SetText(m.name,Color(m.class));
 GameTooltip:AddLine(A.ClassLabel(m).." · "..A.T("Уровень").." "..tostring(m.level or "—"));
 GameTooltip:AddLine(A.T("Здоровье")..": "..A.Short(m.hp).." / "..A.Short(m.max),0.85,0.85,0.87);
 if m.meter then
  GameTooltip:AddLine(A.T("Урон")..": "..A.Short(m.meter.dmg).." · DPS: "..A.Short(m.meter.dps),0.85,0.85,0.87);
  if m.meter.share~=nil then GameTooltip:AddLine(A.T("Доля урона")..": "..tostring(m.meter.share).."%",0.85,0.85,0.87); end
 end
 if m.down then GameTooltip:AddLine(A.T("Лежит"),1,0.35,0.35); end
 if m.revive then GameTooltip:AddLine(A.T("Воскрешение")..": "..math.floor(math.max(0,math.min(1,m.revive))*100).."%",1,0.82,0); end
 if m.rescuing then GameTooltip:AddLine(A.T("Помогает тебе"),0.4,1,0.4); end
 if m.peer then GameTooltip:AddLine(A.T("Умения")..": "..#(m.peer.spells or {}).." · "..A.T("Бижутерия")..": "..#(m.peer.gear or {}),0.85,0.85,0.87);
 else GameTooltip:AddLine(A.T("Данные ещё не получены"),0.65,0.65,0.65); end
 GameTooltip:AddLine(A.T("ЛКМ — окно персонажа"),0.55,0.8,0.55); GameTooltip:Show();
end
local function MakeRow(parent)
 local row=CreateFrame("Button",nil,parent); row:SetWidth(196); row:RegisterForClicks("LeftButtonUp");
 row:SetBackdropColor(0.025,0.03,0.035,0.9); row:SetBackdropBorderColor(0.75,0.75,0.77,1);
 row.bar=CreateFrame("StatusBar",nil,row); row.bar:SetMinMaxValues(0,1); row.bar:SetStatusBarTexture((IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI")) and "Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\hp_lowmid_bar" or "Interface\\TargetingFrame\\UI-StatusBar");
 row.bar:SetFrameLevel(row:GetFrameLevel()+1);
 row.barCase=row.bar:CreateTexture(nil,"BACKGROUND"); row.barCase:SetPoint("CENTER",row.bar,"CENTER",0,0); row.barCase:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\hp_mid_case"); row.barCase:SetTexCoord(203/1024,820/1024,69/256,189/256);
 row.portraitLayer=CreateFrame("Frame",nil,row); row.portraitLayer:EnableMouse(false); row.portraitLayer:SetAllPoints(row); row.portraitLayer:SetFrameLevel(row:GetFrameLevel()+3);
 row.portrait=row.portraitLayer:CreateTexture(nil,"ARTWORK"); row.portrait:SetSize(32,32); row.portrait:SetPoint("TOPLEFT",row,"TOPLEFT",20,-15); row.portrait:SetTexCoord(0,1,0,1);
 row.portraitBorder=row.portraitLayer:CreateTexture(nil,"ARTWORK"); row.portraitBorder:SetSize(39,39); row.portraitBorder:SetPoint("CENTER",row.portrait,"CENTER",0,0);
 if IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") then
  row.portraitBorder:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\orb_case_hi"); row.portraitBorder:SetTexCoord(23/256,232/256,6/256,232/256);
 else row.portraitBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); row.barCase:SetTexture(nil); end
 row.levelBadge=CreateFrame("Frame",nil,row); row.levelBadge:SetSize(24,24); row.levelBadge:EnableMouse(false);
 row.levelDisk=row.levelBadge:CreateTexture(nil,"BACKGROUND"); row.levelDisk:SetPoint("CENTER",row.levelBadge,"CENTER",0,0); row.levelDisk:SetSize(42,42);
 row.levelRim=row.levelBadge:CreateTexture(nil,"ARTWORK"); row.levelRim:SetPoint("CENTER",row.levelBadge,"CENTER",0,0); row.levelRim:SetSize(42,42);
 local skin=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI");
 if skin then row.levelDisk:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\actionbutton-backdrop"); row.levelRim:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\actionbutton-border"); row.levelDisk:SetVertexColor(0.67,0.67,0.67,1); row.levelRim:SetVertexColor(0.9,0.9,0.9,1); end
 row.portraitSlices={}; for i=1,32 do row.portraitSlices[i]=row.portraitLayer:CreateTexture(nil,"OVERLAY"); end
 row.name=S.Label(row,"",10,54,7,96); row.levelText=S.Label(row,"",9,54,23,96,S.muted);
 row.badgeText=S.Label(row.levelBadge,"",11,0,0,24); row.badgeText:ClearAllPoints(); row.badgeText:SetPoint("CENTER",row.levelBadge,"CENTER",0,0); row.badgeText:SetHeight(14); row.badgeText:SetJustifyH("CENTER"); row.badgeText:SetFont(S.font,11,"OUTLINE");
 row.healthOverlay=CreateFrame("Frame",nil,row); row.healthOverlay:EnableMouse(false); row.healthOverlay:SetFrameLevel(row.bar:GetFrameLevel()+1);
 row.healthEdges={}; for i=1,4 do row.healthEdges[i]=row.healthOverlay:CreateTexture(nil,"ARTWORK"); row.healthEdges[i]:SetTexture(skin and "Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\hp_mid_case" or nil); end
 row.hp=S.Label(row.healthOverlay,"",9,0,0,90); row.hp:SetJustifyH("CENTER"); row.status=S.Label(row,"",9,6,58,144,S.muted);
 row:SetScript("OnClick",function(self) A.Inspect(self.model); end);
 row:SetScript("OnEnter",function(self) self.hovered=true; self:SetBackdropBorderColor(140/255,209/255,35/255,1); Tooltip(self); end);
 row:SetScript("OnLeave",function(self) self.hovered=false; self:SetBackdropBorderColor(0.75,0.75,0.77,1); if A.tooltipOwner==self then A.tooltipOwner=nil; GameTooltip:Hide(); end end); return row;
end
-- Explicit texture slices clip the portrait to a circle even in clients whose
-- SetMask is a no-op. Keep the native image contained within the orb artwork.
function A.PaintPortrait(row,unit,key)
 local size=row.portrait:GetWidth();
 if row.portraitKey~=key then
  row.portraitKey=key; if SetPortraitTexture then SetPortraitTexture(row.portrait,unit); end
  row.portrait:SetSize(size,size); local handle=A.Safe(row.portrait.GetTexture,row.portrait);
  for i,part in ipairs(row.portraitSlices) do
   local copied=handle and pcall(part.SetTexture,part,handle);
   if not copied and SetPortraitTexture then part:SetSize(size,size); SetPortraitTexture(part,unit); end
   local top=(i-1)/32; local bottom=i/32; local dy=math.max(math.abs(top-0.5),math.abs(bottom-0.5)); local half=math.sqrt(math.max(0,0.25-dy*dy));
   if half>0 then
    part:ClearAllPoints(); part:SetPoint("TOPLEFT",row.portrait,"TOPLEFT",(0.5-half)*size,-top*size); part:SetSize(2*half*size,(bottom-top)*size); part:SetTexCoord(0.5-half,0.5+half,top,bottom);
   else part:SetSize(0.01,0.01); end
  end
 end
 row.portrait:Hide(); for i,part in ipairs(row.portraitSlices) do if i>1 and i<32 then part:Show(); else part:Hide(); end end
end
local function Paint(row,m,mode)
 row.model=m; local compact=mode=="compact"; row:SetHeight(compact and 82 or 102);
 row.portrait:Hide(); for _,part in ipairs(row.portraitSlices) do part:Hide(); end; row.portraitBorder:Hide(); row.levelBadge:Hide(); row.status:Hide(); row.bar:ClearAllPoints(); row.name:ClearAllPoints(); row.levelText:ClearAllPoints(); row.portrait:ClearAllPoints();
 row.name:SetFont(S.font,compact and 10 or 11,""); row.hp:SetFont(S.font,compact and 9 or 10,""); row.levelText:SetFont(S.font,compact and 9 or 11,compact and "" or "OUTLINE");
 row.name:SetPoint("TOPLEFT",row,"TOPLEFT",compact and 16 or 82,compact and -20 or -24); Fit(row.name,(m.leader and "★ " or "")..m.name,compact and 138 or 96);
 row.levelText:SetWidth(24); row.levelText:SetJustifyH("CENTER"); row.levelText:SetText(m.level and m.level>0 and tostring(m.level) or "—");
 if compact then row.levelText:Show(); row.levelText:SetPoint("TOPRIGHT",row,"TOPRIGHT",-20,-20); row.levelText:SetTextColor(unpack(S.muted));
 else
  row.portrait:SetSize(36,36); row.portrait:SetPoint("TOPLEFT",row,"TOPLEFT",28,-35); row.portraitBorder:ClearAllPoints(); row.portraitBorder:SetPoint("TOPLEFT",row,"TOPLEFT",16,-18); row.portraitBorder:SetSize(60,65);
  row.portrait:Show(); row.portraitBorder:Show(); row.levelBadge:ClearAllPoints(); row.levelBadge:SetPoint("TOPLEFT",row,"TOPLEFT",18,-24); row.levelBadge:Show();
  row.levelText:Hide(); row.badgeText:SetText(row.levelText:GetText()); row.badgeText:SetTextColor(1,1,1,1);
  local unit=m.preview and "player" or m.unit; local key=tostring(A.Safe(UnitGUID,unit) or "")..":"..tostring(m.name);
  A.PaintPortrait(row,unit,key)
  row.status:ClearAllPoints(); row.status:SetPoint("TOPLEFT",row,"TOPLEFT",82,-37); row.status:SetWidth(96); row.status:Show();
  Fit(row.status,A.ClassLabel(m),96);
 end
 local caseWidth=compact and 164 or 111; local caseHeight=compact and 28 or 32; local caseLeft=compact and 16 or 67; local caseTop=compact and 34 or 50;
 -- Match the native player fill (385x37) to its visible case (716x188, cropped 617/1024 by 120/256).
 local width=caseWidth*(385/(716*617/1024)); row.bar:SetSize(width,caseHeight*(37/(188*120/256))); row.bar:SetPoint("CENTER",row,"TOPLEFT",caseLeft+caseWidth/2,-(caseTop+caseHeight/2)); row.barCase:SetSize(caseWidth,caseHeight);
 row.healthOverlay:SetSize(caseWidth,caseHeight); row.healthOverlay:ClearAllPoints(); row.healthOverlay:SetPoint("TOPLEFT",row,"TOPLEFT",caseLeft,-caseTop);
 local cuts={{0,1,0,0.29},{0,1,0.71,1},{0,0.054,0.29,0.71},{0.946,1,0.29,0.71}};
 for i,c in ipairs(cuts) do local edge=row.healthEdges[i]; edge:ClearAllPoints(); edge:SetPoint("TOPLEFT",row.healthOverlay,"TOPLEFT",c[1]*caseWidth,-c[3]*caseHeight); edge:SetSize((c[2]-c[1])*caseWidth,(c[4]-c[3])*caseHeight); edge:SetTexCoord((203+c[1]*617)/1024,(203+c[2]*617)/1024,(69+c[3]*120)/256,(69+c[4]*120)/256); end
 row.healthOverlay:SetFrameLevel(row.bar:GetFrameLevel()+1); row.portraitLayer:SetFrameLevel(row.bar:GetFrameLevel()+2); row.levelBadge:SetFrameLevel(row.bar:GetFrameLevel()+3);
 row.name:SetTextColor(Color(m.class)); row.hp:SetHeight(compact and 12 or 15); row.hp:ClearAllPoints(); row.hp:SetPoint("CENTER",row.healthOverlay,"CENTER",0,2);
 local fraction=m.hp and m.max and m.max>0 and math.max(0,math.min(1,m.hp/m.max)) or 0;
 local status=m.connected==false and A.T("Не в сети") or m.down and A.T("Мёртв") or m.rescuing and A.T("Помогает тебе") or "";
 local text=A.HealthText(m.hp,m.max);
 if m.rescuing and not compact then Fit(row.status,A.T("Воскрешает"),96); row.status:SetTextColor(0.4,1,0.4); else row.status:SetTextColor(unpack(S.muted)); end
 if m.connected==false then row.bar:SetStatusBarColor(0.3,0.3,0.3); text=status;
 elseif m.down then
  row.bar:SetStatusBarColor(0.65,0.16,0.12); fraction=0; text=status;
  if m.revive then fraction=math.max(0,math.min(1,m.revive)); row.bar:SetStatusBarColor(1,0.8,0.15); text=(compact and A.T("Воскрешение").." " or "")..math.floor(fraction*100).."%"; if not compact then Fit(row.status,A.T("Воскрешение"),86); end; end
 else row.bar:SetStatusBarColor(0.85,0.06,0.15); end
 row.bar:SetValue(fraction); Fit(row.hp,text,width-4);
 row:SetAlpha(m.connected==false and 0.65 or 1); row:Show();
 if row.hovered then row:SetBackdropBorderColor(140/255,209/255,35/255,1);
  local now=GetTime and GetTime() or 0; if A.tooltipOwner==row and now>=(row.tooltipAt or 0) then row.tooltipAt=now+0.5; Tooltip(row,true); end
 end
end
function A.PartyInsets()
 if IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") then return {left=1.5,right=1.5,top=10,bottom=11}; end
 return {left=0,right=0,top=0,bottom=0};
end
function A.ChainGap(frame)
 local ratio=(frame.GetEffectiveScale and frame:GetEffectiveScale() or ASRPartyDB.scale)/(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1);
 return (ASRSuiteDB and ASRSuiteDB.dockingGap or 4)/math.max(0.01,ratio);
end
local function Place(frame)
 if frame.moving then return; end
 if ASRSuite and ASRSuite.ready and ASRSuiteDB and ASRSuiteDB.docking and ASRSuiteDB.docking.party then return; end
 local p=ASRPartyDB.positions[ASRPartyDB.mode]; frame:ClearAllPoints();
 if p then frame:SetPoint(p.point,UIParent,p.relative,p.x,p.y); else frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",28,-210); end
end
function A.SetOverlay(on)
 local f=A.frame; if not f then return; end; on=on and true or false;
 if f.partyOverlay==on then return; end; f.partyOverlay=on;
 if A.tooltipOwner then A.tooltipOwner=nil; GameTooltip:Hide(); end
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRPartyPanel",on); end
 f:SetFrameStrata(on and "FULLSCREEN_DIALOG" or "HIGH"); f:SetFrameLevel(on and 450 or 20); S.SyncChildren(f);
end
function A.Refresh()
 if not A.ready or not A.frame then return; end; local f=A.frame; local members=A.Snapshot(); A.members=members;
 ASRLocale.UseFont(ASRPartyDB.language); ASRLocale.ApplyFonts(f,ASRPartyDB.language);
 local preview=#members==0 and (A.editing or A.preview);
 if not ASRPartyDB.enabled or #members==0 and not preview and not ASRPartyDB.showHeader then A.StopDrag(); A.SetOverlay(false); f:Hide(); A.active=false; A.RestoreNative(); return; end
 if preview then members={
  {name="ASR Warrior",level=40,class="WARRIOR",hp=1000,max=1000,preview=true},
  {name="ASR Mage",level=36,class="MAGE",hp=400,max=800,preview=true},
  {name="ASR Rogue",level=38,class="ROGUE",hp=0,max=900,down=true,preview=true},
  {name="ASR Paladin",level=39,class="PALADIN",hp=0,max=1100,down=true,revive=0.5,preview=true},
  {name="ASR Priest",level=37,class="PRIEST",hp=700,max=700,rescuing=true,preview=true}
 }; end
 A.SetOverlay(A.editing or ASRSuite and ASRSuite.editing or A.preview);
 A.active=not preview and #members>0; f:SetScale(ASRPartyDB.scale); f.asrDockInsets=A.PartyInsets();
 local count=not preview and #members==0 and A.T("Соло") or tostring(preview and #members or #members+1); Fit(f.title,"|cff8cd123ASR|r / "..A.T("Группа").." · "..count,132);
 local opacity=ASRSuite and ASRSuite.ready and ASRSuite.GetPanelOpacity and ASRSuite.GetPanelOpacity("party",ASRPartyDB.opacity) or ASRPartyDB.opacity;
 S.Panel(f.header,opacity); f:SetBackdrop(nil);
 local showHeader=ASRPartyDB.showHeader or A.editing or A.preview or ASRSuite and ASRSuite.editing;
 if showHeader then f.header:Show(); else f.header:Hide(); end
 local y=0; local previous=showHeader and f.header or nil; local gap=A.ChainGap(f); local inset=f.asrDockInsets;
 for i,m in ipairs(members) do
  if previous then y=y+previous:GetHeight()-inset.bottom-inset.top+gap; end
  local row=f.rows[i]; row:ClearAllPoints(); row:SetPoint("TOPLEFT",f,"TOPLEFT",0,-y); S.Panel(row,opacity); Paint(row,m,ASRPartyDB.mode); previous=row;
 end
 for i=#members+1,#f.rows do f.rows[i].model=nil; f.rows[i]:Hide(); end
 f:SetHeight(y+previous:GetHeight()); Place(f); f:Show(); if A.active then A.HideNative(); else A.RestoreNative(); end
end
function A.CreateUI()
 local f=CreateFrame("Frame","ASRPartyPanel",UIParent); A.frame=f; f:SetSize(196,132); f:SetFrameStrata("MEDIUM"); f:SetFrameLevel(20); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton");
 f:SetScript("OnDragStart",function(self) if A.CanMove() then self:StartMoving(); self.moving=true; end end); f:SetScript("OnDragStop",A.StopDrag);
 f.header=CreateFrame("Frame",nil,f); f.header:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.header:SetSize(196,64); f.header:EnableMouse(true); f.header:RegisterForDrag("LeftButton");
 f.title=S.Label(f.header,"",10,20,24,130); f.settings=S.Button(f.header,"≡",20,17,156,22,function() A.settings:Show(); A.DrawSettings(); end);
 f.header:SetScript("OnDragStart",function() f:GetScript("OnDragStart")(f); end); f.header:SetScript("OnDragStop",A.StopDrag);
 f.rows={}; for i=1,5 do
  local row=MakeRow(f); f.rows[i]=row; row:RegisterForDrag("LeftButton");
  row:SetScript("OnDragStart",function() f:GetScript("OnDragStart")(f); end); row:SetScript("OnDragStop",A.StopDrag);
 end
 f:Hide(); A.Refresh();
end

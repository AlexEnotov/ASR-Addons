-- Endless HUD: the server's countdown is authoritative; AZS_SCHEDULE.at belongs to the map.
local A,S=ASRSuite,ASRStyle;
local GREEN={140/255,209/255,35/255,1};
local function Num(v) local n=tonumber(v); if n and n==n and n>=0 and n<1e15 then return n; end end
local function Count(v) return math.floor(Num(v) or 0); end
local function Clock(v) v=math.max(0,math.ceil(tonumber(v) or 0)); return string.format("%d:%02d",math.floor(v/60),v%60); end
local function Enabled(r) return r and (r.endless==true or tonumber(r.endless)==1); end
local function Bosses(units)
 local out={}; for _,u in ipairs(units or {}) do if (u.kind=="boss" or u.kind=="final") and (not Num(u.hp) or Num(u.hp)>0) then out[#out+1]=u; end end; return out;
end
-- Pure reducer, also replayed against captured live API data in tests. State is bounded and saved.
function A.EndlessStep(r,z,schedule,units,state)
 r=r or {}; z=z or {}; local now=Num(r.t);
 if not Enabled(r) or not now then return nil,state; end
 local order={}; for _,b in ipairs(schedule or {}) do if b.name and b.name~="" then order[#order+1]={name=b.name,index=b.index,final=b.final}; end end
 if #order==0 then return nil,state; end
 local identity=tostring(z.run or "")..":"..tostring(z.map or z.zone or "");
 local killed=Count(r.bk or r.bo); local n=#order;
 if type(state)~="table" or state.identity~=identity or state.size~=n or now<(Num(state.lastTime) or 0)-3 or killed<(Num(state.lastKilled) or 0) then
  state={identity=identity,size=n,baseBosses=n,spawned=0,baseKills=Count(r.kills),lastTime=now,lastKilled=killed};
 end
 local alive=Bosses(units); local done=math.max(0,killed-Count(state.baseBosses));
 local spawned=math.max(Count(state.spawned),done+#alive);
 local nb=tonumber(r.nbin); if nb==nil then nb=tonumber(r.nb); end
 if nb and (nb~=nb or math.abs(nb)==math.huge) then nb=nil; end
 local changed=spawned>Count(state.spawned);
 if changed then state.spawnTime=now; end
 if nb and nb>=0 then
  -- t+nb is stable to the protocol's one-second rounding. Rebase only on a new countdown.
  local target=now+nb;
  if not state.nextAt or math.abs(target-state.nextAt)>3 or changed then
   state.nextAt=target;
   state.interval=math.max(1,target-(Num(state.spawnTime) or now));
   if state.interval<nb then state.interval=math.max(1,nb); end
  end
 else state.nextAt=nil; end
 state.spawned=spawned; state.lastTime=now; state.lastKilled=killed;
 local live={};
 for _,u in ipairs(alive) do
  local index;
  for i,b in ipairs(order) do if b.name==u.name then index=i; break end end
  local serial=spawned;
  if index then serial=spawned-((spawned-index)%n); if serial<1 then serial=index; end end
  live[#live+1]={id=u.id,name=u.name,hp=Num(u.hp),hpm=Num(u.hpm),serial=serial};
 end
 table.sort(live,function(a,b) return a.serial<b.serial; end);
 local start=math.max(1,spawned); if live[1] then start=math.min(start,live[1].serial); end
 local rows={};
 for i=0,3 do
  local serial=start+i; local slot=(serial-1)%n+1; local status=serial<=spawned and "dead" or "future"; local unit;
  for _,u in ipairs(live) do if u.serial==serial then status="up"; unit=u; break end end
  if serial==spawned+1 then status="next"; end
  rows[#rows+1]={serial=serial,name=order[slot].name,index=slot,round=math.floor((serial-1)/n)+1,status=status,unit=unit};
 end
 local nextSerial=spawned+1;
 local displayRound=math.floor((math.max(1,spawned)-1)/n)+1;
 if spawned>0 and spawned%n==0 and done>=spawned and #live==0 then displayRound=displayRound+1; end
 local bossRows={};
 for i,b in ipairs(order) do
  local serial=(displayRound-1)*n+i; local status=serial<=spawned and "dead" or "future";
  for _,u in ipairs(live) do if u.serial==serial then status="up"; break end end
  if serial==nextSerial then status="next"; end
  bossRows[i]={name=b.name,status=status,serial=serial};
 end
 return {time=now,level=Count(r.lvl),zone=z.zname or z.zone or "",difficulty=z.diff,heroic=z.heroic,tier=z.dt,affixes=z.affixes,kills=Count(r.kills),endlessKills=math.max(0,Count(r.kills)-Count(state.baseKills)),
  killed=done,spawned=spawned,round=displayRound,nextRound=math.floor(spawned/n)+1,bossRows=bossRows,
  nextName=order[(nextSerial-1)%n+1].name,nextIn=nb and nb>=0 and nb or nil,
  nextAt=state.nextAt,interval=state.interval,
  progress=nb and nb>=0 and math.max(0,math.min(1,1-nb/math.max(1,state.interval or nb))) or 0,
  live=live,rows=rows,start=start},state;
end

local function HudOwner() return AZS_API_HUD and AZS_API_HUD.clock; end
function A.EndlessRestoreHud()
 local d=ASRSuiteDB and ASRSuiteDB.endlessHud;
 if not d then return; end
 if d.previous and AZS_SetHudShown and (HudOwner()=="ASRSuite" or HudOwner()==nil) then AZS_SetHudShown("clock",true); end
 ASRSuiteDB.endlessHud=nil;
end
local function HideNative()
 if not AZS_SetHudShown or not AZS_IsHudShown then return false; end
 if not ASRSuiteDB.endlessHud then
  ASRSuiteDB.endlessHud={previous=AZS_IsHudShown("clock") or HudOwner()=="ASRSuite"};
 end
 if AZS_IsHudShown("clock") then AZS_SetHudShown("clock",false); end
 return true;
end
local function Label(parent,text,size,x,y,w,color) return S.Label(parent,text,size,x,y,w,color); end
local function Font(label,size)
 local template=_G["AzeriteFont"..tostring(size).."Outline"];
 if template and template.GetFont then local path,actual,flags=template:GetFont(); label:SetFont(path,actual or size,flags or "");
 else label:SetFont(S.font,size,""); end
end
local function Fit(label,text,size,width)
 text=tostring(text or ""); label:SetWidth(width); Font(label,size); label:SetText(text);
 while size>9 and label:GetStringWidth()>width do size=size-1; Font(label,size); end
 if label:GetStringWidth()>width then
  local chars={}; for c in string.gmatch(text,"[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=c; end
  repeat table.remove(chars); label:SetText(table.concat(chars).."…"); until #chars==0 or label:GetStringWidth()<=width;
 end
end
local function Objective(parent,y)
 local row=CreateFrame("Frame",nil,parent); row:SetSize(246,22); row:SetPoint("TOPLEFT",parent,"TOPLEFT",20,-y);
 row.mark=CreateFrame("Frame",nil,row); row.mark:SetSize(14,14); row.mark:SetPoint("LEFT",row,"LEFT",0,0);
 local skin=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI"); local base="Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\";
 row.ring=row:CreateTexture(nil,"BACKGROUND"); row.ring:SetTexture(skin and base.."point_plate" or "Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall"); row.ring:SetSize(skin and 41 or 14,skin and 41 or 14); row.ring:SetPoint("CENTER",row.mark,"CENTER",0,0);
 row.dot=row:CreateTexture(nil,"ARTWORK"); row.dot:SetTexture(skin and base.."point_crystal" or "Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall"); row.dot:SetSize(10,10); row.dot:SetPoint("CENTER",row.mark,"CENTER",0,0);
 row.name=Label(row,"",13,24,2,222); row.name:SetHeight(18); return row;
end
local function Mark(row,status)
 if status=="future" then row.dot:Hide(); else row.dot:Show();
  local c=status=="dead" and {0.45,0.85,0.1} or {1,0.6,0.1}; row.dot:SetVertexColor(unpack(c)); end
end
function A.EndlessDisplayClock(m)
 local now=AZS_GetRunTime and tonumber(AZS_GetRunTime()) or m.time;
 if not now or now~=now or math.abs(now)==math.huge then now=m.time; end
 if m.nextIn~=nil and m.nextAt then
  m.nextIn=math.max(0,m.nextAt-now); m.progress=math.max(0,math.min(1,1-m.nextIn/math.max(1,m.interval or m.nextIn)));
 end
 m.time=now; return m;
end
local AFFIX_ICONS={Bolstering="Spell_Nature_Strength",Sanguine="Spell_Shadow_LifeDrain",Explosive="Spell_Fire_SelfDestruct"};
local HEX_ICONS={frenzy="Spell_Shadow_UnholyFrenzy",surge="Spell_Shadow_AuraOfDarkness",frailty="Spell_Shadow_FingerOfDeath",wither="Ability_Warrior_SavageBlow"};
local function Affixes(f,m,y)
 local entries={};
 for name in string.gmatch(m.affixes or "","[^,]+") do entries[#entries+1]={name=name,icon=AFFIX_ICONS[name] or "INV_Misc_QuestionMark"}; end
 for _,hex in ipairs(AZS_HEXES or {}) do
  local left=(tonumber(hex["until"]) or 0)-m.time;
  if left>0 and HEX_ICONS[hex.key] then entries[#entries+1]={name=hex.key,icon=HEX_ICONS[hex.key],left=left}; end
 end
 f.affixIcons=f.affixIcons or {};
 for i=1,math.min(8,#entries) do
  local entry=entries[i]; local icon=f.affixIcons[i];
  if not icon then
   icon=CreateFrame("Frame",nil,f); icon:SetSize(24,24); icon:EnableMouse(true); f.affixIcons[i]=icon;
   icon.texture=icon:CreateTexture(nil,"ARTWORK"); icon.texture:SetAllPoints(icon); icon.texture:SetTexCoord(0.08,0.92,0.08,0.92);
   icon:SetBackdrop({edgeFile="Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\border-aura",edgeSize=12}); icon:SetBackdropBorderColor(69/255,59/255,49/255,1);
   icon.time=Label(icon,"",11,0,5,24); icon.time:SetJustifyH("CENTER");
   icon:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(AZS_L and AZS_L[self.caption] or self.caption); GameTooltip:Show(); end);
   icon:SetScript("OnLeave",function() GameTooltip:Hide(); end);
  end
  icon:SetPoint("TOPLEFT",f,"TOPLEFT",10+(i-1)*32,-y); icon.caption=entry.name; icon.texture:SetTexture("Interface\\Icons\\"..entry.icon); icon.time:SetText(entry.left and math.ceil(entry.left) or ""); icon:Show();
 end
 for i=math.min(8,#entries)+1,#f.affixIcons do f.affixIcons[i]:Hide(); end
 return #entries>0 and 36 or 0;
end
function A.EndlessDifficulty(m)
 local d=m.difficulty;
 if d and d~="" then
  local lower=string.lower(tostring(d));
  if lower=="normal" or d=="Обычный" then return A.T("Обычный"); end
  if lower=="heroic" or d=="Героический" then return A.T("Героический"); end
  return tostring(d);
 end
 return A.T(((tonumber(m.heroic) or 0)>0 or (tonumber(m.tier) or 0)>0) and "Героический" or "Обычный");
end
function A.InitEndless()
 if ASRSuiteDB.endlessEnabled==nil then ASRSuiteDB.endlessEnabled=true; end
 if A.endlessFrame then return; end
 local f=CreateFrame("Frame","ASREndlessTracker",UIParent); A.endlessFrame=f; f:SetSize(270,254); f:SetFrameStrata("MEDIUM"); f:SetFrameLevel(20); f:Hide();
 f.head=CreateFrame("Frame",nil,f); f.head:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.head:SetSize(270,78);
 f.head:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,tile=true,tileSize=16,insets={left=3,right=3,top=3,bottom=3}});
 f.head:SetBackdropColor(0.16,0.12,0.09,0.92); f.head:SetBackdropBorderColor(0.55,0.5,0.45,1);
 f.title=Label(f.head,"ENDLESS",11,16,10,90,GREEN); Font(f.title,11);
 f.round=Label(f.head,"",11,106,10,148); f.round:SetJustifyH("RIGHT");
 f.levelText=Label(f.head,"",15,16,30,148); f.time=Label(f.head,"",15,168,30,86); f.time:SetJustifyH("RIGHT"); Font(f.time,15);
 f.zone=Label(f.head,"",15,16,51,238,{1,0.82,0,1});
 f.difficulty=Label(f.head,"",15,16,51,100,{0.73,0.73,0.73,1});
 f.enemy=Objective(f,122); f.counts=f.enemy.name; f.rows={};
 f.slot=CreateFrame("Frame",nil,f); f.slot:SetPoint("TOPLEFT",f,"TOPLEFT",4,-86); f.slot:SetSize(262,28);
 f.bar=CreateFrame("StatusBar",nil,f.slot); f.bar:SetPoint("CENTER",f.slot,"CENTER",0,0); f.bar:SetSize(262,12);
 if f.bar.SetStatusBarTexture then f.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); f.bar:SetStatusBarColor(unpack(GREEN)); end
 f.bar:SetMinMaxValues(0,1); local bg=f.bar:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f.bar); bg:SetTexture(0.12,0.14,0.10,1);
 f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton");
 f:SetScript("OnDragStart",function(self) if A.CanMovePanel("endless") then self:StartMoving(); self.moving=true; end end);
 f.saveDrag=function(self) local p,_,rel,x,y=self:GetPoint(); ASRSuiteDB.endlessPosition={p,rel,x,y}; self.placed=true; end;
 f:SetScript("OnDragStop",function(self) A.StopDrag(self); end);
 f:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:SetText("ASR Endless");
  GameTooltip:AddLine(A.T("Таймер приходит из игры. Следующий босс определяется по очереди карты."),0.8,0.82,0.85,true);
  GameTooltip:AddLine(A.T("Враги — за весь забег. Боссы — только в бесконечном режиме."),0.8,0.82,0.85,true);
  GameTooltip:Show();
 end); f:SetScript("OnLeave",function() GameTooltip:Hide(); end);
end
local function Place(f)
 if f.moving then return; end
 if ASRSuiteDB.endlessPosition then
  if not f.placed then local p=ASRSuiteDB.endlessPosition; f:ClearAllPoints(); f:SetPoint(p[1],UIParent,p[2],p[3],p[4]); f.placed=true; end
 else
  f:ClearAllPoints();
  if AZSTrackerFrame then f:SetPoint("BOTTOMRIGHT",AZSTrackerFrame,"BOTTOMRIGHT",0,0);
  elseif AZSMeterFrame then f:SetPoint("BOTTOMRIGHT",AZSMeterFrame,"TOPRIGHT",10,46);
  else f:SetPoint("RIGHT",UIParent,"RIGHT",-24,160); end
 end
end
function A.DrawEndless(m)
 local f=A.endlessFrame; if not f or not m then return; end
 local objectivesY=m.nextIn~=nil and 122 or 86;
 if m.nextIn~=nil then f.slot:Show(); else f.slot:Hide(); end
 objectivesY=objectivesY+Affixes(f,m,objectivesY);
 f.enemy:ClearAllPoints(); f.enemy:SetPoint("TOPLEFT",f,"TOPLEFT",20,-objectivesY);
 f:SetHeight(objectivesY+22+#m.bossRows*22); Place(f);
 Fit(f.round,string.format(A.T("Круг %d · Боссы: %d"),m.round,m.killed),11,148);
 Fit(f.levelText,string.format(A.T("Уровень %d"),m.level),15,148); f.time:SetText(Clock(math.floor(m.time)));
 Fit(f.difficulty,A.EndlessDifficulty(m),15,100);
 local difficultyWidth=f.difficulty:GetStringWidth();
 Fit(f.zone,m.zone,15,math.max(80,238-difficultyWidth-6));
 f.difficulty:ClearAllPoints(); f.difficulty:SetPoint("TOPLEFT",f.head,"TOPLEFT",16+f.zone:GetStringWidth()+6,-51);
 Fit(f.counts,string.format(A.T("Убито врагов %d"),m.kills),13,222); Mark(f.enemy,"next");
 if not f.charge and AZS_BuildBossChargeBar then
  f.chargeHolder=CreateFrame("Frame",nil,f.slot);
  local fill,width=AZS_BuildBossChargeBar(f.chargeHolder); f.charge=fill;
  f.chargeHolder:SetScale(262/width); f.chargeHolder:SetPoint("CENTER",f.slot,"CENTER",0,0); f.bar:Hide();
 end
 for i,b in ipairs(m.bossRows) do
  local row=f.rows[i];
  if not row then row=Objective(f,144+(i-1)*22); f.rows[i]=row; end
  row:ClearAllPoints(); row:SetPoint("TOPLEFT",f,"TOPLEFT",20,-(objectivesY+i*22));
  row:Show(); Mark(row,b.status);
  local text=string.format(A.T("%s убит %d / 1"),b.name,b.status=="dead" and 1 or 0);
  if b.status=="next" then text=b.name.." · "..(m.nextIn and Clock(m.nextIn) or "—"); elseif b.status=="up" then text=b.name.." · "..A.T("В бою"); end
  Fit(row.name,text,13,222); local shade=b.status=="dead" and 0.75 or 1; row.name:SetTextColor(shade,shade,shade,1);
 end
 for i=#m.bossRows+1,#f.rows do f.rows[i]:Hide(); end
 if f.charge then f.charge(m.progress,m.nextIn and Clock(m.nextIn).." · "..math.floor(m.progress*100).."%" or A.T("В бою"),not f:IsShown()); else f.bar:SetValue(m.progress); end
 f:Show();
end
local tick=0;
function A.UpdateEndless(dt,force)
 if not A.endlessFrame then return; end
 local f=A.endlessFrame;
 if f.moving and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then A.StopDrag(f); end
 tick=tick+(dt or 0); if not force and tick<0.1 then return; end; tick=0;
 local r=AZS_RUN or {}; local phase=r.ph;
 local active=Enabled(r) and (phase=="playing" or phase=="choosing" or phase=="paused" or phase=="dead");
 if not active then
  f:Hide(); A.EndlessRestoreHud(); A.endlessModel=nil;
  if phase and not Enabled(r) then ASRSuiteDB.endlessState=nil; end
  return;
 end
 local model,state=A.EndlessStep(r,AZS_ZONE,AZS_SCHEDULE,AZS_UNITS,ASRSuiteDB.endlessState);
 if model then A.EndlessDisplayClock(model); end
 ASRSuiteDB.endlessState=state; A.endlessModel=model;
 if model and ASRSuiteDB.endlessEnabled~=false and HideNative() then A.DrawEndless(model);
 else f:Hide(); A.EndlessRestoreHud(); end
end

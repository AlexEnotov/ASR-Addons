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
 return {time=now,level=Count(r.lvl),zone=z.zname or z.zone or "",difficulty=z.diff,heroic=z.heroic,tier=z.dt,kills=Count(r.kills),endlessKills=math.max(0,Count(r.kills)-Count(state.baseKills)),
  killed=done,spawned=spawned,round=displayRound,nextRound=math.floor(spawned/n)+1,bossRows=bossRows,
  nextName=order[(nextSerial-1)%n+1].name,nextIn=nb and nb>=0 and nb or nil,
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
local function Fit(label,text,size,width)
 text=tostring(text or ""); label:SetWidth(width); label:SetFont(S.font,size,""); label:SetText(text);
 while size>9 and label:GetStringWidth()>width do size=size-0.5; label:SetFont(S.font,size,""); end
 if label:GetStringWidth()>width then
  local chars={}; for c in string.gmatch(text,"[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=c; end
  repeat table.remove(chars); label:SetText(table.concat(chars).."…"); until #chars==0 or label:GetStringWidth()<=width;
 end
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
 local f=CreateFrame("Frame","ASREndlessTracker",UIParent); A.endlessFrame=f; f:SetSize(270,207); f:SetFrameStrata("MEDIUM"); f:SetFrameLevel(20); f:Hide();
 f.title=Label(f,"ENDLESS",12,8,0,110,GREEN); f.round=Label(f,"",11,120,1,142); f.round:SetJustifyH("RIGHT");
 f.levelText=Label(f,"",13,8,20,144); f.time=Label(f,"",13,158,20,104); f.time:SetJustifyH("RIGHT");
 f.zone=Label(f,"",12,8,41,254,{1,0.82,0,1});
 f.counts=Label(f,"",11,8,61,254,S.muted); f.rows={};
 f.slot=CreateFrame("Frame",nil,f); f.slot:SetPoint("TOPLEFT",f,"TOPLEFT",4,-80); f.slot:SetSize(262,28);
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
 f:SetHeight(112+#m.bossRows*19); Place(f);
 f.round:SetText(string.format(A.T("Круг %d"),m.round));
 Fit(f.levelText,string.format(A.T("Уровень %d"),m.level),13,144); f.time:SetText(Clock(math.floor(m.time)));
 Fit(f.zone,m.zone.." · "..A.EndlessDifficulty(m),12,254);
 Fit(f.counts,string.format(A.T("Враги: %d  ·  Боссы: %d"),m.kills,m.killed),11,254);
 if not f.charge and AZS_BuildBossChargeBar then
  f.chargeHolder=CreateFrame("Frame",nil,f.slot);
  local fill,width=AZS_BuildBossChargeBar(f.chargeHolder); f.charge=fill;
  f.chargeHolder:SetScale(262/width); f.chargeHolder:SetPoint("CENTER",f.slot,"CENTER",0,0); f.bar:Hide();
 end
 for i,b in ipairs(m.bossRows) do
  local row=f.rows[i];
  if not row then
   row=CreateFrame("Frame",nil,f); row:SetSize(254,19); row:SetPoint("TOPLEFT",f,"TOPLEFT",8,-(108+(i-1)*19)); f.rows[i]=row;
   row.marker=Label(row,"",11,0,0,16,GREEN); row.name=Label(row,"",12,19,0,179); row.right=Label(row,"",11,202,0,52); row.right:SetJustifyH("RIGHT");
  end
  row:Show(); Fit(row.name,b.name,12,179);
  local color=b.status=="up" and {1,0.65,0.2,1} or (b.status=="next" and GREEN or S.muted);
  row.name:SetTextColor(unpack(color)); row.marker:SetText(b.status=="dead" and "✓" or b.status=="up" and "!" or b.status=="next" and "›" or "·"); row.marker:SetTextColor(unpack(color));
  local right=b.status=="next" and (m.nextIn and Clock(m.nextIn) or "—") or A.T(b.status=="dead" and "Убит" or b.status=="up" and "В бою" or "");
  Fit(row.right,right,10,52); row.right:SetTextColor(unpack(color));
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
 ASRSuiteDB.endlessState=state; A.endlessModel=model;
 if model and ASRSuiteDB.endlessEnabled~=false and HideNative() then A.DrawEndless(model);
 else f:Hide(); A.EndlessRestoreHud(); end
end

local A=ASRCombatText; local root,pool,active,cursor={}, {}, {},nil; local poll=0; local primed=false; local order=0;
local colors={normal={1,1,1},critical={1,0.78,0.2},heal={0.35,1,0.5},taken={1,0.3,0.3}};
local function Amount(n,short)
 if short and n>=1e6 then return string.format("%.1fm",n/1e6); elseif ASRCombatTextDB.short and n>=1000 then return string.format("%.1fk",n/1000); end
 return string.format("%.0f",n);
end
local function Caption(t)
 t.text:SetText((t.lane=="taken" and "−" or t.lane=="heal" and "+" or "")..Amount(t.amount,A.EffectiveOptions(t.profile).short)..(t.count>1 and " ×"..t.count or ""));
end
local function Free(t) t:Hide(); t.live=false; end
function A.ClearCombat()
 for _,t in ipairs(active) do Free(t); end; active={}; A.active=active;
end
local function Acquire()
 for _,t in ipairs(pool) do if not t.live then return t; end end
 if #pool>=512 then for i,t in ipairs(active) do if t.queued then table.remove(active,i); Free(t); return t; end end; local t=table.remove(active,1); Free(t); return t; end
 local t=CreateFrame("Frame",nil,root); t:SetSize(170,36); t:EnableMouse(false);
 t.text=t:CreateFontString(nil,"OVERLAY"); t.text:SetPoint("LEFT",t,"LEFT",26,0); t.text:SetWidth(140); t.text:SetHeight(34); t.text:SetJustifyH("LEFT");
 t.icon=t:CreateTexture(nil,"ARTWORK"); t.icon:SetSize(20,20); t.icon:SetPoint("LEFT",t,"LEFT",2,0); t.icon:SetTexCoord(0.07,0.93,0.07,0.93); pool[#pool+1]=t; return t;
end
local function SameArea(a,b) return a.anchor==b.anchor and (a.anchor or a.lane==b.lane); end
local function CanDisplay(t,now)
 local options=A.EffectiveOptions(t.profile);
 for _,other in ipairs(active) do if other~=t and SameArea(t,other) and A.TypeShown(other.profile) then
  if other.queued then if other.order<t.order then return false; end
  else
   local old=A.EffectiveOptions(other.profile); local age=math.max(0,now-(other.displayStarted or other.started));
   local remaining=old.lifetime-age; local position=math.min(age*old.scrollSpeed,old.rise);
   if old.spacing>0 and old.scrollSpeed>0 then remaining=math.min(remaining,(old.rise-position)/old.scrollSpeed); end
   local spacing=math.max(options.spacing,old.spacing);
   if remaining>0 and spacing>0 then
    local horizon=math.min(remaining,options.lifetime);
    if options.spacing>0 and options.scrollSpeed>0 then horizon=math.min(horizon,options.rise/options.scrollSpeed); end
    local ending=math.min(position+old.scrollSpeed*horizon,old.rise)-options.scrollSpeed*horizon;
    if math.min(position,ending)<spacing-0.001 then return false; end
   end
  end
 end end; return true;
end
function A.AddHit(event,now,example)
 if not A.ready or not ASRCombatTextDB.enabled or not example and not A.InRun() then return; end
 local amount=A.Number(event.amount); if not amount or amount<=0 then return; end
 if event.periodic and not A.TypeShown("periodic") then return; end
 local lane=event.kind=="taken" and "taken" or event.kind=="heal" and "heal" or event.critical and "critical" or "normal";
 local profile=lane=="normal" and event.periodic and "periodic" or lane;
 if not A.TypeShown(profile) then return; end
 local options=A.EffectiveOptions(profile);
 if lane=="heal" then amount=math.max(0,amount-(A.Number(event.overheal) or 0)); if amount<=0 then return; end end
 now=now or GetTime();
 local anchor=ASRCombatTextDB.mode=="enemies" and event.kind=="damage" and event.anchorId or nil;
 local key=profile..":"..tostring(event.spellId or event.abilityName or "attack")..":"..tostring(event.periodic==true)..":"..tostring(anchor or "");
 for _,t in ipairs(active) do
  if options.merge>0 and t.key==key and not example and not t.example and now-t.started<=options.merge then t.amount=t.amount+amount; t.count=t.count+1; Caption(t); return t; end
 end
 local t=Acquire(); t.live=true; t.key=key; t.lane=lane; t.profile=profile; t.amount=amount; t.count=1; t.started=now; t.anchor=anchor; t.example=example; t.age=0; t.spawnOffset=0; order=order+1; t.order=order; t.displayStarted=nil; t.queued=true; t:Hide();
 t.visualHeight=math.max(options.fontSize+4,options.icons and 20 or 0);
 if CanDisplay(t,now) then t.queued=false; t.displayStarted=now; end;
 -- Every number moves by age and speed only; new hits never push older ones.
 local fontSize=options.fontSize; t:SetHeight(fontSize+12); t.text:SetHeight(fontSize+8); t.text:SetFont(ASRStyle.font,fontSize,"OUTLINE"); t.text:SetTextColor(unpack(colors[lane]));
 local icon; if event.spellId and GetSpellInfo then icon=select(3,GetSpellInfo(event.spellId)); end
 if not icon or icon=="" then icon="Interface\\Icons\\INV_Misc_QuestionMark"; end
 t.icon:SetTexture(icon); if options.icons then t.icon:Show(); else t.icon:Hide(); end
 t.text:ClearAllPoints(); t.text:SetPoint("LEFT",t,"LEFT",options.icons and 26 or 2,0);
 Caption(t); active[#active+1]=t; A.active=active; return t;
end
function A.PollEvents()
 if not AZS_GetCombatTextEvents then return; end
 for page=1,4 do
  local result=AZS_GetCombatTextEvents(cursor,256); if type(result)~="table" then return; end
  cursor=result.cursor;
  if primed then for _,event in ipairs(result.events or {}) do A.AddHit(event,GetTime()); end end
  if not result.hasMore then break end
 end
 primed=true;
end
function A.ApplyCombat()
 if ASRCombatTextDB.enabled then
  if ASRCombatTextDB.nativeDamage==nil and GetCVar then ASRCombatTextDB.nativeDamage=GetCVar("CombatDamage"); end
  if SurvivorUI_DamageMode and SurvivorUI_SetDamageMode then if ASRCombatTextDB.previousSurvivorMode==nil then ASRCombatTextDB.previousSurvivorMode=SurvivorUI_DamageMode(); end; SurvivorUI_SetDamageMode("none"); end
  if GetCVar and SetCVar then if ASRCombatTextDB.nativeDamage==nil then ASRCombatTextDB.nativeDamage=GetCVar("CombatDamage"); end; SetCVar("CombatDamage","0"); end
 else A.ClearCombat(); A.RestoreNative(); end
end
function A.RestoreNative()
 if ASRCombatTextDB.previousSurvivorMode and SurvivorUI_SetDamageMode then SurvivorUI_SetDamageMode(ASRCombatTextDB.previousSurvivorMode); ASRCombatTextDB.previousSurvivorMode=nil; end
 if ASRCombatTextDB and ASRCombatTextDB.nativeDamage~=nil and SetCVar then SetCVar("CombatDamage",ASRCombatTextDB.nativeDamage); ASRCombatTextDB.nativeDamage=nil; end
end
function A.CreateCombat()
 root=CreateFrame("Frame","ASRCombatNumbers",UIParent); root:SetAllPoints(UIParent); root:SetFrameStrata("HIGH"); root:EnableMouse(false); A.active=active;
 local events=CreateFrame("Frame","ASRCombatTaken"); events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED"); events:RegisterEvent("PLAYER_LOGOUT");
 events:SetScript("OnEvent",function(self,event,...)
  if event=="PLAYER_LOGOUT" then A.RestoreNative(); return; end
  if not ASRCombatTextDB.enabled or not A.InRun() then return; end
  local _,sub,source,_,_,destination=...; if destination~=UnitGUID("player") or source==destination then return; end
  local amount,crit,spell;
  if sub=="SWING_DAMAGE" then amount,_,_,_,_,_,crit=select(9,...);
  elseif sub=="SPELL_DAMAGE" or sub=="SPELL_PERIODIC_DAMAGE" or sub=="RANGE_DAMAGE" then spell,_,_,amount,_,_,_,_,_,crit=select(9,...); else return; end
  A.AddHit({kind="taken",amount=amount,critical=crit,spellId=spell,periodic=sub=="SPELL_PERIODIC_DAMAGE"});
 end);
end
function A.UpdateCombat(dt)
 poll=poll+dt; if poll>=0.05 then poll=0; A.PollEvents(); end
 local now=GetTime(); local anchors={}; local unique={};
 for _,t in ipairs(active) do if t.anchor and not unique[t.anchor] then unique[t.anchor]=true; anchors[#anchors+1]=t.anchor; end end
 local places={};
 if #anchors>0 and AZS_ProjectCombatTextAnchors then
  local result=AZS_ProjectCombatTextAnchors(anchors,"follow");
  for _,entry in ipairs(result and result.entries or {}) do places[entry.anchorId]=entry; end
 end
 local blocked={};
 for _,t in ipairs(active) do if t.queued then
  local area=t.anchor and "anchor:"..tostring(t.anchor) or "lane:"..t.lane;
  if not blocked[area] then if CanDisplay(t,now) then t.queued=false; t.displayStarted=now; else blocked[area]=true; end end
 end end
 local ratio=WorldFrame and WorldFrame.GetEffectiveScale and WorldFrame:GetEffectiveScale()/UIParent:GetEffectiveScale() or 1;
 for i=#active,1,-1 do
  local t=active[i]; local options=A.EffectiveOptions(t.profile); t.age=t.queued and 0 or now-(t.displayStarted or t.started); local fraction=t.age/options.lifetime;
  if fraction>=1 or (not t.queued and options.spacing>0 and options.scrollSpeed>0 and t.age*options.scrollSpeed>=options.rise) or not A.TypeShown(t.profile) or not ASRCombatTextDB.enabled or not A.InRun() and not t.example then Free(t); table.remove(active,i);
  elseif t.queued then t:Hide();
  else
   local p=ASRCombatTextDB.positions[t.lane]; local x,y=UIParent:GetWidth()/2+p.x,UIParent:GetHeight()/2+p.y;
   local visible=true;
   if t.anchor then local entry=places[t.anchor]; if entry and entry.state=="onScreen" and entry.x and entry.y then x,y=entry.x*ratio,entry.y*ratio; else visible=false; end end
   local direction=t.lane=="taken" and -1 or 1;
   t:ClearAllPoints(); t:SetPoint("LEFT",UIParent,"BOTTOMLEFT",x,y+direction*(math.min(t.spawnOffset+t.age*options.scrollSpeed,options.rise)));
   t:SetAlpha(math.min(1,(1-fraction)*3)*A.GetPanelOpacity("combat",ASRCombatTextDB.combatOpacity,"text")); if visible then t:Show(); else t:Hide(); end
  end
 end
end
function A.Example()
 for i,lane in ipairs(A.lanes) do A.AddHit({kind=lane=="taken" and "taken" or lane=="heal" and "heal" or "damage",critical=lane=="critical",amount=1234+i*137,abilityName="Example"},GetTime(),true); end
end

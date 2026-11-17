ASRParty={VERSION="0.6.3",ready=false}; local A=ASRParty;
ASRLocale.RegisterTranslations("party","en",{
 ["Группа"]="Party",["Соло"]="Solo",["Всегда показывать заголовок группы"]="Always show party header",["Классический"]="Classic",["Компактный"]="Compact",["Вид панели"]="Panel style",["Модуль включён"]="Module enabled",
 ["Закрепить"]="Lock panel",["Масштаб"]="Scale",["Фон трекера"]="Tracker background",["Сбросить положение"]="Reset position",
 ["Предпросмотр"]="Preview",["Лежит"]="Down",["Мёртв"]="Dead",["Не в сети"]="Offline",["Воскрешение"]="Reviving",["Помогает тебе"]="Reviving you",["Воскрешает"]="Reviving ally",
 ["Здоровье"]="Health",["Уровень"]="Level",["Урон"]="Damage",["Доля урона"]="Damage share",["Умения"]="Abilities",["Бижутерия"]="Jewelry",
 ["Данные ещё не получены"]="Data not received yet",["ЛКМ — окно персонажа"]="Left click: character window",
 ["Перетащи заголовок, чтобы переместить группу."]="Drag the header to move the party.",
 ["С Suite перемещение — через «Изменить интерфейс»."]="With Suite, use Edit interface to move panels.",
 ["Изменить интерфейс"]="Edit interface",["Язык"]="Language",["Формат ХП"]="Health format",["Короткие числа"]="Short numbers",["Полные числа"]="Full numbers",["Проценты"]="Percent",["Число и процент"]="Value and percent",
});
function A.T(key) return ASRLocale.Text("party",ASRPartyDB and ASRPartyDB.language or "en",key); end
local classNames={WARRIOR="Warrior",MAGE="Mage",ROGUE="Rogue",PALADIN="Paladin",PRIEST="Priest",HUNTER="Hunter",DRUID="Druid",SHAMAN="Shaman",WARLOCK="Warlock",DEATHKNIGHT="Death Knight",MONK="Monk",DEMONHUNTER="Demon Hunter",EVOKER="Evoker"};
function A.ClassLabel(member) local english=classNames[member.class]; return english and ASRLocale.Text("names",ASRPartyDB.language,english,english) or member.className or member.class or ""; end
function A.Safe(fn,...) if type(fn)~="function" then return nil; end; local ok,a,b,c=pcall(fn,...); if ok then return a,b,c; end end
function A.Bool(fn,...)
 if type(fn)~="function" then return nil; end; local ok,v=pcall(fn,...); if ok then return v~=nil and v~=false and v~=0; end
end
function A.Number(value) local n=tonumber(value); if n and n==n and math.abs(n)<1e15 then return n; end end
function A.Short(value)
 local n=A.Number(value); if not n then return "—"; end
 local units={{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"k"}};
 for _,u in ipairs(units) do if math.abs(n)>=u[1] then return string.format("%.1f",n/u[1]):gsub("%.0$","")..u[2]; end end
 return tostring(math.floor(n+0.5));
end
A.healthFormats={"short","full","percent","both"};
function A.HealthFormatName(mode)
 return ({short="Короткие числа",full="Полные числа",percent="Проценты",both="Число и процент"})[mode] or "Короткие числа";
end
function A.HealthText(hp,max,mode)
 mode=mode or ASRPartyDB.healthFormat; hp=A.Number(hp); max=A.Number(max);
 if not hp or not max or max<=0 then return "— / —"; end
 local percent=tostring(math.floor(math.max(0,math.min(1,hp/max))*100+0.5)).."%";
 if mode=="percent" then return percent; end
 if mode=="both" then return A.Short(hp).." ("..percent..")"; end
 if mode=="full" then return string.format("%.0f / %.0f",hp,max); end
 return A.Short(hp).." / "..A.Short(max);
end
function A.Init()
 if type(ASRPartyDB)~="table" then ASRPartyDB={}; end; local d=ASRPartyDB;
 if type(d.enabled)~="boolean" then d.enabled=true; end; if type(d.locked)~="boolean" then d.locked=false; end
 if type(d.showHeader)~="boolean" then d.showHeader=true; end
 if not ({short=true,full=true,percent=true,both=true})[d.healthFormat] then d.healthFormat="short"; end
 d.mode=d.mode=="compact" and "compact" or "classic"; d.language=ASRLocale.Normalize(d.language);
 d.scale=math.max(0.5,math.min(1.5,A.Number(d.scale) or 0.85)); d.opacity=math.max(0,math.min(1,A.Number(d.opacity) or 0.8));
 if type(d.positions)~="table" then d.positions={}; end; A.ready=true;
end
function A.Snapshot()
 local out={}; local revive=A.Safe(AZS_GetRevive) or AZS_REVIVE or {}; local down={};
 for _,v in ipairs(revive.friends or {}) do if v.name then down[v.name]=v; end end
 local dead=A.Safe(AZS_GetDownedPartyMembers); for _,v in ipairs(type(dead)=="table" and dead or {}) do if v.name then down[v.name]=v; end end
 local meters={}; for _,v in ipairs(AZS_PARTY or {}) do if v.name then meters[v.name]=v; end end
 for i=1,4 do
  local unit="party"..i;
  if A.Bool(UnitExists,unit) and not A.Bool(UnitIsUnit,unit,"player") then
   local name=A.Safe(UnitName,unit); local className,class=A.Safe(UnitClass,unit); local hp=A.Number(A.Safe(UnitHealth,unit)); local max=A.Number(A.Safe(UnitHealthMax,unit));
   local row={unit=unit,name=name or "?",class=class,className=className,level=A.Number(A.Safe(UnitLevel,unit)),hp=hp,max=max,
    connected=A.Bool(UnitIsConnected,unit),leader=A.Bool(UnitIsPartyLeader,unit),meter=meters[name],peer=AZS_PEERS and AZS_PEERS[name]};
   local friend=down[name]; row.down=friend~=nil or hp~=nil and max~=nil and max>0 and hp<=0 or A.Bool(UnitIsDeadOrGhost,unit) or A.Bool(UnitIsDead,unit);
   row.revive=friend and A.Number(friend.reviveShare or friend.share);
   if revive.reviving==name then row.revive=A.Number(revive.rshare); end
   row.rescuing=(revive.down==1 or revive.down==true) and revive.by==name;
   out[#out+1]=row;
  end
 end
 return out;
end
function A.CanMove() if A.editing then return true; end; if ASRSuite and ASRSuite.ready then return ASRSuite.CanMovePanel("party"); end; return not ASRPartyDB.locked; end
function A.SavePosition(frame)
 local point,_,relative,x,y=frame:GetPoint(); ASRPartyDB.positions[ASRPartyDB.mode]={point=point,relative=relative,x=x,y=y};
end
function A.StopDrag()
 local f=A.frame; if f and f.moving then f:StopMovingOrSizing(); f.moving=false; A.SavePosition(f); A.draggedUntil=(GetTime and GetTime() or 0)+0.2; end
end
function A.SetMode(mode)
 if mode~="classic" and mode~="compact" then return; end; A.StopDrag(); ASRPartyDB.mode=mode; A.Refresh(); A.DrawSettings();
end
function A.SetLanguage(value) ASRPartyDB.language=ASRLocale.Normalize(value); if A.ready then A.Refresh(); A.DrawSettings(); end end
function A.SetEnabled(value) ASRPartyDB.enabled=value and true or false; A.Refresh(); A.DrawSettings(); end
function A.ResetPosition() A.StopDrag(); ASRPartyDB.positions[ASRPartyDB.mode]=nil; if ASRSuiteDB and ASRSuiteDB.docking then ASRSuiteDB.docking.party=nil; end; A.Refresh(); end
local runtime=CreateFrame("Frame","ASRPartyRuntime"); runtime:RegisterEvent("ADDON_LOADED"); runtime:RegisterEvent("PARTY_MEMBERS_CHANGED"); runtime:RegisterEvent("PLAYER_ENTERING_WORLD"); runtime:RegisterEvent("RAID_ROSTER_UPDATE"); runtime:RegisterEvent("PLAYER_LOGOUT");
runtime:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" and name=="ASRParty" then A.Init(); A.CreateUI(); A.CreateSettings();
 elseif event=="PLAYER_LOGOUT" then A.StopDrag(); end
 if A.ready then A.BindSuite(); A.Refresh(); end
end);
local elapsed=0;
runtime:SetScript("OnUpdate",function(self,dt)
 if not A.ready then return; end
 if A.frame.moving and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then A.StopDrag(); end
 elapsed=elapsed+dt; if elapsed<0.15 then return; end; elapsed=0; A.BindSuite(); A.Refresh();
end);
SLASH_ASRPARTY1="/asrparty";
SlashCmdList.ASRPARTY=function(msg)
 if not A.ready then return; end; msg=string.lower(string.match(msg or "","^%s*(.-)%s*$"));
 if msg=="classic" or msg=="compact" then A.SetMode(msg);
 elseif msg=="on" or msg=="off" then A.SetEnabled(msg=="on");
 elseif msg=="lock" or msg=="unlock" then ASRPartyDB.locked=msg=="lock"; A.DrawSettings();
 elseif msg=="reset" then A.ResetPosition();
 elseif ASRLocale.IsLanguage(msg) then A.SetLanguage(msg);
 else if A.settings:IsShown() then A.settings:Hide(); else A.settings:Show(); end; A.DrawSettings(); end
end;

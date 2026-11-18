ASRLoot={VERSION="0.6.4",ready=false}; local A=ASRLoot;
local translations={
 ["Новые"]="New",["Все"]="All",["Переключить режим"]="Switch mode",["Масштаб"]="Scale",["Добыча"]="Loot",["Только новые"]="New items only",["Вся добыча"]="All drops",["Новый"]="New",["Продано"]="Sold",["Неизвестная редкость"]="Unknown rarity",
 ["Новые: %d · Дубликаты: %d"]="New: %d · Duplicates: %d",["Золото за дубликаты: %d"]="Duplicate gold: %d",["Пока нет предметов"]="No items yet",["Прокрутка колёсиком"]="Scroll with mouse wheel",
 ["Показать трекер добычи"]="Show loot tracker",["Скрыть обычные уведомления о добыче"]="Hide native loot notifications",["Режим трекера"]="Tracker mode",
 ["Модуль включён"]="Module enabled",["Открыть панель"]="Open panel",["Закрыть панель"]="Close panel",["Открывать в начале забега"]="Open at run start",["Открывать при выпадении предмета"]="Open when an item drops",
 ["Обычный"]="Common",["Необычный"]="Uncommon",["Редкий"]="Rare",["Эпический"]="Epic",["Легендарный"]="Legendary",["Количество: %d"]="Count: %d",["Золото: %d"]="Gold: %d",
 ["Выбери автоматическое открытие в начале забега или при выпадении вещи. Без обеих галочек панель открывается вручную."]="Choose automatic opening at run start or when an item drops. With both unchecked, open the panel manually.",
 ["Учитываются постоянные броня и оружие. Звёзды не отслеживаются."]="Tracks permanent armor and weapons. Stars are not tracked.",
 ["Сумма золота — только за проданные дубликаты в этом забеге."]="Gold counts sold duplicates in this run only.",
 ["Статистика включает данные до установки трекера в этом забеге."]="The total includes data from before the tracker was installed in this run.",
};
ASRLocale.RegisterTranslations("loot","en",translations);
function A.T(key) return ASRLocale.Text("loot",ASRLootDB and ASRLootDB.language or "en",key); end
function A.Number(v) local n=tonumber(v); if n and n==n and n>=0 and n<1e15 then return n; end end
function A.Clean(s)
 s=tostring(s or ""); s=string.gsub(s,"|c%x%x%x%x%x%x%x%x",""); s=string.gsub(s,"|r","");
 s=string.gsub(s,"|H.-|h(.-)|h","%1"); return string.match(s,"^%s*(.-)%s*$");
end
local upper={"А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"};
local lower={"а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"};
function A.Key(name) local s=string.lower(A.Clean(name)); for i,v in ipairs(upper) do s=string.gsub(s,v,lower[i]); end; return s; end
local function Escape(s) return (string.gsub(s,"([^%w])","%%%1")); end
function A.ParseDuplicate(message)
 local text=A.Clean(message);
 for _,token in ipairs(ASRLootMetadata.duplicates) do
  local name,amount=string.match(text,"^(.-)%s+"..Escape(token).."%s*:%s*%+([%d][%d%s,%.]*)%s+[^%d]+$");
  if name then
   local gold=A.Number(string.gsub(amount,"[%s,%.]","")); name=A.Clean(name);
   if gold and name~="" and #name<=300 then return {name=name,gold=gold}; end
  end
 end
end
local slots={
 {0,{"helm","helmet","шлем","головной убор"}},{1,{"shoulder","pauldron","spaulder","наплеч"}},{2,{"chest","robe","breastplate","нагр","кираса","одеяние"}},
 {3,{"belt","waist","пояс","кушак","ремень","girdle"}},{4,{"legging","pants","trousers","понож","штаны","брюки"}},{5,{"boot","sabatons","сапог","ботин","сабатон","набедренники"}},
 {6,{"bracer","wrist","наручи","браслет"}},{7,{"gauntlet","glove","перчат","рукавиц"}},
};
local function Class()
 local key=AZS_ZONE and AZS_ZONE.class; if not key and UnitClass then local _,token=UnitClass("player"); key=token; end
 return string.lower(tostring(key or ""));
end
function A.CacheItem(item)
 if not item or not item.name or item.name=="" then return; end
 local key=A.Key(item.name); local old=ASRLootDB.items[key] or {name=item.name};
 if item.icon and item.icon~="" then old.icon=item.icon; end
 if A.Number(item.rarity) then old.rarity=tonumber(item.rarity); end
 ASRLootDB.items[key]=old; return old;
end
function A.Resolve(name)
 local key=A.Key(name); local cached=ASRLootDB.items[key]; if cached and cached.icon and cached.rarity~=nil then return cached; end
 local class=Class(); local spec=ASRLootMetadata.sets[class]; local rarity,slot,icon; local armor=spec and spec.armor;
 local function Has(aliases,exact)
  for _,alias in ipairs(aliases or {}) do local part=A.Key(alias); if part~="" and (exact and key==part or not exact and string.find(key,part,1,true)) then return #part; end end
 end
 local weapon,ambiguous;
 for _,candidate in ipairs(ASRLootMetadata.weapons or {}) do if Has(candidate.names,true) then
  if candidate.class==class then weapon=candidate; ambiguous=false; break end
  if weapon and (weapon.icon~=candidate.icon or weapon.rarity~=candidate.rarity) then ambiguous=true; else weapon=candidate; end
 end end
 if weapon and not ambiguous then rarity=weapon.rarity; icon=weapon.icon; end
 if rarity==nil then
  local longest=0; local foundClass;
  for token,definition in pairs(ASRLootMetadata.sets) do for index,names in ipairs(definition.names) do local length=Has(names);
   if length and (length>longest or length==longest and token==class) then longest=length; rarity=index-1; armor=definition.armor; foundClass=token; end
  end end
  for _,info in ipairs(slots) do if Has(info[2]) then slot=info[1]; break end end
  if slot==nil then for index,nouns in ipairs(ASRLootMetadata.slotNames or {}) do if Has(nouns) then slot=index-1; break end end end
  if slot~=nil and rarity~=nil then
   for _,look in ipairs(AZS_GEN and AZS_GEN.setLooks or {}) do
    if look.class==(foundClass or class) and look.rarity==rarity then for _,piece in ipairs(look.pieces or {}) do if piece[1]==slot then icon="INV_"..piece[4]; break end end end
   end
   if not icon and rarity==0 and armor then icon="INV_"..ASRLootMetadata.commonIcons[armor][slot+1]; end
  end
  if rarity==nil then for index,tier in ipairs(AZS_GEN and AZS_GEN.gearTiers or {}) do
   local aliases=ASRLootMetadata.tierNames or {};
   if Has(aliases[tier.weapon] or {tier.weapon},true) then
    rarity=index+5; local icons=tier.weapon_icons and tier.weapon_icons[class]; if icons and #icons==1 then icon="INV_"..icons[1]; end; break
   elseif Has(aliases[tier.name] or {tier.name}) then
    rarity=index+5; local icons=tier.armor_icons and tier.armor_icons[armor]; if slot~=nil and icons and icons[slot+1] then icon="INV_"..icons[slot+1]; end; break
   end
  end end
 end
 return {name=name,icon=cached and cached.icon or icon,rarity=cached and cached.rarity or rarity};
end
function A.InRun() local p=AZS_RUN and AZS_RUN.ph; return p=="playing" or p=="choosing" or p=="paused" or p=="ready" or p=="dead" or p=="victory"; end
function A.EnsureRun()
 local r,z=AZS_RUN or {},AZS_ZONE or {}; local clock=A.Number(r.t) or 0;
 -- AZSRUN and AZSZONE can arrive separately after reload. Only a server run
 -- identifier proves a new session; missing fields or a rewound clock do not.
 local id=z.run and tostring(z.run)~="" and tostring(z.run) or nil;
 local run=ASRLootDB.run;
 local oldId=type(run)=="table" and (run.serverId or run.id) or nil;
 local legacyMatch=id and type(run)=="table" and not run.serverId and type(run.id)=="string" and string.sub(run.id,1,#id+1)==id..":";
 if type(run)~="table" or (id and oldId and oldId~=id and not legacyMatch) then
  run={id=id,serverId=id,entries={},newCount=0,duplicateCount=0,gold=0,observedGold=0,lastTime=clock,panelOpen=ASRLootDB.openOnStart~=false}; ASRLootDB.run=run; A.offset=0; A.lastChat=nil;
 end
 if run.panelOpen==nil then run.panelOpen=ASRLootDB.openOnStart~=false; end
 if id then run.id=id; run.serverId=id; run.lastTime=clock; end; return run;
end
local function Add(run,name,kind)
 local e={name=name,key=A.Key(name),kind=kind,time=AZS_RUN and AZS_RUN.t or 0,wall=GetTime()};
 run.entries[#run.entries+1]=e; if #run.entries>500 then table.remove(run.entries,1); end; A.offset=0; return e;
end
local function PaintMetadata(e,item) if item then e.icon=item.icon or e.icon; if item.rarity~=nil then e.rarity=item.rarity; end end end
local function OpenForDrop(kind)
 if ASRLootDB.openOnDrop and (kind=="new" or ASRLootDB.mode=="all") then A.EnsureRun().panelOpen=true; end
end
function A.NewDrop(fields)
 if not A.ready or not fields or not fields.name then return; end
 local name=A.Clean(fields.name); if name=="" then return; end
 local run=A.EnsureRun(); local meta=A.CacheItem({name=name,icon=fields.icon,rarity=fields.rarity});
 local e=Add(run,name,"new"); PaintMetadata(e,meta); run.newCount=run.newCount+1;
 OpenForDrop("new");
 if A.Refresh then A.Refresh(); end
end
function A.Duplicate(message,event)
 if not A.ready or not A.InRun() then return; end
 local parsed=A.ParseDuplicate(message); if not parsed then return; end
 local run=A.EnsureRun(); local clean=A.Clean(message); local last=A.lastChat;
 if last and last.message==clean and last.event~=event and GetTime()-last.at<0.25 then return; end
 A.lastChat={message=clean,event=event,at=GetTime()};
 local e=Add(run,parsed.name,"duplicate"); e.gold=parsed.gold; PaintMetadata(e,A.Resolve(parsed.name));
 run.duplicateCount=run.duplicateCount+1; run.observedGold=run.observedGold+parsed.gold; run.gold=run.gold+parsed.gold;
 OpenForDrop("duplicate");
 if A.Refresh then A.Refresh(); end
end
function A.Reconcile(fields)
 if not A.ready then return; end
 local run=A.EnsureRun(); local gold=A.Number(fields and fields.dupgold);
 if gold then run.reportedGold=gold; run.gold=math.max(run.gold,gold); end
 if A.Refresh then A.Refresh(); end
end
function A.Rows()
 local run=ASRLootDB.run; local rows,by,resolved={},{},{};
 for i=#(run and run.entries or {}),1,-1 do
  local e=run.entries[i];
  if not e.icon or e.rarity==nil then local hint=resolved[e.key]; if not hint then hint=A.Resolve(e.name); resolved[e.key]=hint; end; PaintMetadata(e,hint); end
  if ASRLootDB.mode=="all" or e.kind=="new" then
   local key=e.key..":"..e.kind..":"..tostring(e.rarity); local row=by[key];
   if not row then row={name=e.name,icon=e.icon,rarity=e.rarity,kind=e.kind,count=0,gold=0}; by[key]=row; rows[#rows+1]=row; end
   row.count=row.count+1; row.gold=row.gold+(e.gold or 0);
  end
 end
 return rows;
end
function A.SetLanguage(language) ASRLootDB.language=ASRLocale.Normalize(language); if A.Refresh then A.Refresh(); end end
function A.SetMode(mode) ASRLootDB.mode=mode=="all" and "all" or "new"; A.offset=0; if A.Refresh then A.Refresh(); end end
function A.SetEnabled(on) ASRLootDB.enabled=on and true or false; if A.Refresh then A.Refresh(); end end
function A.Open()
 ASRLootDB.enabled=true;
 if A.InRun() then A.EnsureRun().panelOpen=true; A.inspect=false; else A.inspect=true; end
 if A.Refresh then A.Refresh(); end
end
function A.Close()
 A.inspect=false; if ASRLootDB.run then ASRLootDB.run.panelOpen=false; end
 if A.Refresh then A.Refresh(); end
end
function A.SetAutoOpen(mode)
 ASRLootDB.openOnStart=mode=="start"; ASRLootDB.openOnDrop=mode=="drop";
end
function A.Init()
 ASRLootDB=type(ASRLootDB)=="table" and ASRLootDB or {};
 local d=ASRLootDB; d.items=type(d.items)=="table" and d.items or {};
 d.language=ASRLocale.Normalize(d.language or ASRSuiteDB and ASRSuiteDB.language or "en");
 if d.enabled==nil then d.enabled=true; end; if d.replaceNative==nil then d.replaceNative=true; end
 if d.openOnStart==nil then d.openOnStart=true; end; if d.openOnDrop==nil then d.openOnDrop=false; end
 if d.openOnStart and d.openOnDrop then d.openOnDrop=false; end
 if not A.Number(d.scale) then d.scale=ASRStatsDB and ASRStatsDB.scale or 0.85; end; d.scale=math.max(0.5,math.min(1.5,d.scale));
 d.mode=d.mode=="all" and "all" or "new"; A.ready=true;
end
local runtime=CreateFrame("Frame","ASRLootRuntime"); runtime:RegisterEvent("ADDON_LOADED"); runtime:RegisterEvent("CHAT_MSG_SYSTEM"); runtime:RegisterEvent("CHAT_MSG_LOOT");
runtime:SetScript("OnEvent",function(self,event,arg)
 if event=="ADDON_LOADED" then
  if arg=="ASRLoot" then
   A.Init(); A.CreateUI();
   AZS.On("AZSLOOT",function(msg) A.NewDrop(AZS_Fields(msg)); end);
   AZS.On("AZSEND",function(msg) A.Reconcile(AZS_Fields(msg)); end);
   AZS.On("AZSARMOR",function() for _,item in ipairs(AZS_ARMOR or {}) do A.CacheItem(item); end end);
  end
 elseif A.ready then A.Duplicate(arg,event); end
end);
local elapsed=0;
runtime:SetScript("OnUpdate",function(self,dt)
 if not A.ready then return; end
 elapsed=elapsed+dt; if elapsed<0.25 then return; end; elapsed=0;
 if A.InRun() then A.EnsureRun(); for _,item in ipairs(AZS_ARMOR or {}) do A.CacheItem(item); end end
 if A.BindSuite then A.BindSuite(); end; if A.Refresh then A.Refresh(); end
end);
SLASH_ASRLOOT1="/asrloot";
SlashCmdList.ASRLOOT=function(msg)
 if not A.ready then return; end
 if ASRTrackerStyle.Command(ASRLootDB,msg,A.Refresh) then return end;
 if msg=="all" or msg=="new" then A.SetMode(msg);
 elseif ASRLocale.IsLanguage(msg) then A.SetLanguage(msg);
 elseif msg=="hide" then A.Close();
 else if A.frame and A.frame:IsShown() then A.Close(); else A.Open(); end end
end;

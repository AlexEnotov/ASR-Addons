-- Original implementation for Reborn's Lua 5.1 interface. No network or executable imports.
ASAdvisor = { VERSION = "0.5.8", catalog = {}, byKey = {}, aliases = {}, ready = false };
local A = ASAdvisor;
local function trim(s) return (string.gsub(s or "", "^%s*(.-)%s*$", "%1")); end
A.Trim = trim;
function A.Lower(s)
  s=string.lower(s or "");
  s=string.gsub(s,"\208[\144-\175]",function(c) local n=string.byte(c,2)+32; return n<192 and "\208"..string.char(n) or "\209"..string.char(n-64); end);
  return (string.gsub(s,"Ё","ё"));
end
function A.Plain(s)
  return trim((string.gsub(string.gsub(tostring(s or ""), "|c%x%x%x%x%x%x%x%x", ""), "|r", "")));
end
function A.Local(s)
  if ASAdvisorDB and ASAdvisorDB.options and ASAdvisorDB.options.language=="en" then return s; end
  return (ASAdvisorNamesRU and ASAdvisorNamesRU[s]) or (AZS_L and AZS_L[s]) or s;
end
function A.Icon(s)
  if not s or s == "" then return "Interface\\Icons\\INV_Misc_QuestionMark"; end
  if string.find(s, "\\", 1, true) then return s; end
  return "Interface\\Icons\\" .. s;
end
function A.Class()
  local _, token = UnitClass("player");
  return token or "HUNTER";
end
function A.ClassName(token)
  local c = AZS_GEN and AZS_GEN.classByToken and AZS_GEN.classByToken[token];
  return c and A.Local(c.name) or token;
end
function A.Print(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff55ddc6ASR Advisor|r  " .. s); end end
function A.Copy(t)
  if type(t) ~= "table" then return t; end
  local out = {}; for k,v in pairs(t) do out[k] = A.Copy(v); end; return out;
end
function A.BuildCatalog()
  A.catalog, A.byKey, A.aliases, A.itemNames = {}, {}, {}, {};
  local function add(row, group, class)
    local r = { key = row.key, name = A.Local(row.name), english = row.name, icon = row.icon, group = group, class = class };
    A.catalog[#A.catalog + 1] = r;
    A.byKey[(class or group) .. ":" .. r.key] = r;
    if group ~= "spell" then
      A.aliases[A.Plain(r.name)] = r; A.aliases[A.Plain(r.english)] = r;
      if AZS_L then A.aliases[A.Plain(AZS_L[row.name])] = r; end
      if ASAdvisorNamesRU and ASAdvisorNamesRU[row.name] then A.aliases[ASAdvisorNamesRU[row.name]]=r; end
      local m = ASAdvisorMechanics and ASAdvisorMechanics.items[r.key];
      for _,name in ipairs(m and m.aliases or {}) do A.aliases[name] = r; end
      for _,name in ipairs({r.name,r.english,AZS_L and AZS_L[row.name] or row.name}) do
        A.itemNames[name]=A.itemNames[name] or {}; local found=false; for _,v in ipairs(A.itemNames[name]) do if v==r then found=true; end end; if not found then A.itemNames[name][#A.itemNames[name]+1]=r; end
      end
    end
    return r;
  end
  for token, list in pairs(AZS_GEN.spells or {}) do for _,r in ipairs(list) do add(r, "spell", token); end end
  for _,r in ipairs(AZS_GEN.jewels or {}) do
    local m = ASAdvisorMechanics and ASAdvisorMechanics.items[r.key];
    add(r, m and m.slot or "unknown");
  end
  for _,r in ipairs(AZS_GEN.amulets or {}) do add(r, "amulet"); end
  for _,m in ipairs(ASAdvisorMechanics.legends or {}) do
    local classes={}; for token in pairs(AZS_GEN.spells or {}) do if A.byKey[token..":"..m.spell] then classes[#classes+1]=token; end end
    if #classes>0 then
      ASAdvisorMechanics.items[m.key]={slot="amulet",behavior="",classes=classes,legend=m,effects={}};
      local r=add(m,"amulet"); r.legend=m; r.baseName=ASAdvisorDB.options.language=="en" and m.name or m.ru;
      local spell=A.byKey[classes[1]..":"..m.spell]; r.name=r.baseName.." · "..spell.name;
      for _,name in ipairs({m.name,m.ru}) do
        A.itemNames[name]=A.itemNames[name] or {}; local found=false; for _,v in ipairs(A.itemNames[name]) do if v==r then found=true; end end; if not found then A.itemNames[name][#A.itemNames[name]+1]=r; end
        A.aliases[name]=r;
      end
    end
  end
end
function A.ResolveItem(value,token)
  local name=A.Plain(type(value)=="table" and value.name or value); local list=A.itemNames and A.itemNames[name];
  if not list then return A.aliases[name]; end
  local candidates={}; for _,r in ipairs(list) do if A.AvailableTo(r,token or A.Class()) then candidates[#candidates+1]=r; end end
  if #candidates==1 then return candidates[1]; end
  local raw=type(value)=="table" and A.Lower((value.text or "").." "..(value.effect or "").." "..(value.note or "")) or "";
  local match;
  for _,r in ipairs(candidates) do if r.legend then local spell=A.byKey[(token or A.Class())..":"..r.legend.spell];
    local ru=spell and ASAdvisorNamesRU[spell.english];
    if spell and (string.find(raw,A.Lower(spell.english),1,true) or ru and string.find(raw,A.Lower(ru),1,true)) then if match then return; end; match=r; end
  end end
  return match;
end
function A.Info(b, key, group)
  if group=="spell" then local p=A.FindPick(b,key); if p and p.any then return {key=key,name="Any",group="spell",any=true,icon="INV_Misc_QuestionMark",class=b.class}; end end
  return A.byKey[(group == "spell" and b.class or group) .. ":" .. key];
end
function A.ItemInfo(b,key)
  local p=b and b.itemRules and b.itemRules[key];
  if p and p.any then return {key=key,name="Any",group=p.group,any=true,icon="INV_Misc_QuestionMark"}; end
  return A.aliasItem(key);
end
function A.ItemRule(b,key)
  b.itemRules=b.itemRules or {}; b.itemRules[key]=b.itemRules[key] or {group=(A.ItemInfo(b,key) or {}).group,value=0,value2=0};
  return b.itemRules[key];
end
function A.AvailableTo(row,token)
  local m=ASAdvisorMechanics.items[row.key];
  if not m or not m.classes or #m.classes==0 then return true; end
  for _,class in ipairs(m.classes) do if class==token then return true; end end
  return false;
end
function A.Active(token)
  if not A.ready then return nil; end
  local id = ASAdvisorDB.active[token or A.Class()];
  for _,b in ipairs(ASAdvisorDB.builds) do if b.id == id and b.class == (token or A.Class()) then return b; end end
end
function A.NewBuild(token)
  local db = ASAdvisorDB;
  local b = { id = db.nextId, class = token, name = A.ClassName(token) .. " · "..A.T("Новый билд"), spells = {}, items = {}, itemRules={}, description="",style = "balanced" };
  db.nextId = db.nextId + 1;
  local c = AZS_GEN.classByToken[token];
  if c and A.byKey[token .. ":" .. c.starter] then b.spells[1] = { key = c.starter, rank = 10 }; end
  db.builds[#db.builds+1] = b; db.active[token] = b.id;
  return b;
end
function A.Init()
  if type(ASAdvisorDB) ~= "table" then ASAdvisorDB = {}; end
  local d = ASAdvisorDB;
  d.version = 1;
  if type(d.builds) ~= "table" then d.builds = {}; end
  if type(d.active) ~= "table" then d.active = {}; end
  if type(d.options) ~= "table" then d.options = {}; end
  local o=d.options;
  if o.language~="ru" and o.language~="en" then o.language="ru"; end
  o.opacity=math.min(1,math.max(0.15,tonumber(o.opacity) or 0.84));
  o.trackerOpacity=math.min(1,math.max(0.1,tonumber(o.trackerOpacity) or 0.42));
  o.scale=math.min(1.3,math.max(0.55,tonumber(o.scale) or 0.85));
  o.trackerScale=math.min(1.3,math.max(0.5,tonumber(o.trackerScale) or 0.85));
  o.trackerWidth=math.min(520,math.max(240,tonumber(o.trackerWidth) or 280));
  o.trackerHeight=math.min(600,math.max(110,tonumber(o.trackerHeight) or 280));
  if o.plannerWidth then o.plannerWidth=math.min(1240,math.max(760,tonumber(o.plannerWidth) or 880)); end
  if o.plannerHeight then o.plannerHeight=math.min(1000,math.max(500,tonumber(o.plannerHeight) or 540)); end
  if o.previewWidth then o.previewWidth=math.min(1240,math.max(760,tonumber(o.previewWidth) or 760)); end
  if o.previewHeight then o.previewHeight=math.min(1000,math.max(340,tonumber(o.previewHeight) or 520)); end
  if o.trackerMode~="detailed" then o.trackerMode="compact"; end
  if o.pickStyle~="band" and o.pickStyle~="arrow" then o.pickStyle="inline"; end
  if type(o.statCaps)~="table" then o.statCaps={}; end
  if o.statCaps.cooldown==nil then o.statCaps.cooldown=80; end
  if o.layoutVersion~=2 then o.plannerPos=nil; o.trackerPos=nil; o.layoutVersion=2; end
  if type(d.observed) ~= "table" then d.observed = {}; end
  if type(d.diagnostics) ~= "table" then d.diagnostics = {}; end
  d.nextId = tonumber(d.nextId) or 1;
  for _,b in ipairs(d.builds) do
    b.itemRules=b.itemRules or {}; b.description=b.description or "";
    if tonumber(b.id) and b.id >= d.nextId then d.nextId = b.id + 1; end
  end
  A.BuildCatalog(); A.ready = true;
end
function A.FindPick(b,key)
  for i,p in ipairs(b and b.spells or {}) do if p.key == key then return p,i; end end
end
function A.HasItem(b,key)
  for i,k in ipairs(b and b.items or {}) do if k == key then return i; end end
end
function A.Toggle(b,r)
  if r.group == "spell" then
    local _,i = A.FindPick(b,r.key);
    if i then table.remove(b.spells,i); elseif #b.spells < 6 then b.spells[#b.spells+1] = { key=r.key, rank=10 }; else return "В билде уже 6 умений."; end
  else
    local i = A.HasItem(b,r.key);
    if i then table.remove(b.items,i); return; end
    local n = 0;
    for _,k in ipairs(b.items) do local x = A.ItemInfo(b,k); if x and x.group == r.group then n=n+1; end end
    local cap = r.group == "amulet" and 8 or 2;
    if n >= cap then return "Сначала убери предмет из этой группы."; end
    b.items[#b.items+1] = r.key;
  end
end
function A.RemovePick(b,key,group)
  if group=="spell" then local _,i=A.FindPick(b,key); if i then table.remove(b.spells,i); end
  else local i=A.HasItem(b,key); if i then table.remove(b.items,i); if b.itemRules then b.itemRules[key]=nil; end end end
end
function A.MovePick(b,key,group,direction)
  if group=="spell" then
    local _,i=A.FindPick(b,key); if i and b.spells[i+direction] then b.spells[i],b.spells[i+direction]=b.spells[i+direction],b.spells[i]; end
  else
    local indices={};
    for i,k in ipairs(b.items) do local row=A.ItemInfo(b,k); if row and row.group==group then indices[#indices+1]=i; end end
    for n,i in ipairs(indices) do if b.items[i]==key and indices[n+direction] then local j=indices[n+direction]; b.items[i],b.items[j]=b.items[j],b.items[i]; return; end end
  end
end
function A.ItemPriority(b,key,group)
  local n=0;
  for _,k in ipairs(b and b.items or {}) do
    local row=A.ItemInfo(b,k);
    if row and row.group==group then n=n+1; if k==key then return n; end end
  end
end
function A.aliasItem(key)
  for _,g in ipairs({"ring","trinket","amulet","unknown"}) do local r=A.byKey[g..":"..key]; if r then return r; end end
end
function A.Snapshot()
  local ph = AZS_GetPhase and AZS_GetPhase() or (AZS_RUN and AZS_RUN.ph);
  if AZS_ZONE and tonumber(AZS_ZONE.hub) == 1 then ph=nil; end
  local s = { phase=ph, spells={}, gear={}, stats={}, inRun=ph~=nil };
  if ph and ph ~= "ready" then
    if A.RunStats then s.stats=A.RunStats(); end
    for _,v in ipairs(AZS_SPELLS or {}) do s.spells[v.key] = v; end
    for _,v in ipairs(AZS_GEAR or {}) do s.gear[#s.gear+1] = v; end
  end
  return s;
end
function A.Checksum(s)
  local a,b=1,0; for i=1,#s do a=(a+string.byte(s,i))%65521; b=(b+a)%65521; end
  -- Avoid platform-dependent conversion of a number above signed 32-bit range.
  return string.format("%04x%04x",b,a);
end
local function enc(s) return (string.gsub(s,"([^%w_ %-%.])",function(c) return string.format("%%%02X",string.byte(c)); end)); end
local function dec(s)
  if string.find(string.gsub(s,"%%%x%x",""),"%%") then return nil; end
  return (string.gsub(s,"%%(%x%x)",function(h) return string.char(tonumber(h,16)); end));
end
local function split(s,sep)
  local out,from={},1;
  while true do local i,j=string.find(s,sep,from,true); if not i then out[#out+1]=string.sub(s,from); return out; end
    out[#out+1]=string.sub(s,from,i-1); from=j+1;
  end
end
function A.AddAny(b,group)
  local count=group=="spell" and #b.spells or 0;
  if group~="spell" then for _,key in ipairs(b.items) do local r=A.ItemInfo(b,key); if r and r.group==group then count=count+1; end end end
  if count>=(group=="spell" and 6 or group=="amulet" and 8 or 2) then return nil,A.T("Сначала убери предмет из этой группы."); end
  local prefix=({spell="@s",ring="@r",trinket="@t",amulet="@a"})[group]; if not prefix then return; end
  local n=1; while A.FindPick(b,prefix..n) or A.HasItem(b,prefix..n) do n=n+1; end
  local key=prefix..n;
  if group=="spell" then b.spells[#b.spells+1]={key=key,any=true,options={},rank=0};
  else b.items[#b.items+1]=key; b.itemRules=b.itemRules or {}; b.itemRules[key]={group=group,any=true,options={},value=0,value2=0}; end
  return key;
end
local function hex(s) return (string.gsub(s,".",function(c) return string.format("%02x",string.byte(c)); end)); end
local function unhex(s)
  if #s%2~=0 or string.find(s,"[^%x]") then return nil; end
  return (string.gsub(s,"%x%x",function(v) return string.char(tonumber(v,16)); end));
end
local function packed(prefix,payload) return prefix..":"..A.Checksum(payload)..":"..hex(payload); end
local function unpacked(code,prefix)
  code=string.gsub(code,"%s","");
  local hash,body=string.match(code,"^"..prefix..":(%x%x%x%x%x%x%x%x):(%x+)$");
  local payload=body and unhex(body);
  if payload and string.lower(hash)==A.Checksum(payload) then return payload; end
end
function A.NormalizeLegacy(code)
  code=string.gsub(code,"\r\n","\n"); code=string.gsub(code,"\r","\n");
  return trim(code);
end
function A.Export(b)
  local picks={};
  for _,p in ipairs(b.spells) do picks[#picks+1]=table.concat({p.key,p.rank or 0,p.cd or 0,p.damage or 0,p.targets or 0,p.any and 1 or 0,table.concat(p.options or {},"."),enc(p.note or ""),p.radius or 0,p.duration or 0},"~"); end
  local rules={};
  for _,key in ipairs(b.items) do local p=b.itemRules and b.itemRules[key]; if p then
    rules[#rules+1]=table.concat({key,p.group or (A.ItemInfo(b,key) or {}).group or "",p.value or 0,p.value2 or 0,p.any and 1 or 0,table.concat(p.options or {},"."),enc(p.note or ""),p.value3 or 0,p.value4 or 0,p.value5 or 0,p.value6 or 0},"~");
  end end
  local payload=table.concat({b.class,enc(b.name),b.style or "balanced",table.concat(picks,","),table.concat(b.items,","),enc(b.description or ""),table.concat(rules,",")},"|");
  return packed("ASR3",payload);
end
function A.Decode(code)
  if type(code)~="string" or #code>128000 then return nil,"Код слишком длинный."; end
  code=trim(code);
  local modern=string.sub(code,1,5)=="ASR3:";
  local payload;
  if modern then payload=unpacked(code,"ASR3");
  else
    code=A.NormalizeLegacy(code);
    local hash,body=string.match(code,"^ASA[12]:(%x%x%x%x%x%x%x%x):(.*)$");
    if hash and string.lower(hash)==A.Checksum(body) then payload=body;
    elseif hash then body=string.gsub(body,"||","|"); if string.lower(hash)==A.Checksum(body) then payload=body; end end
  end
  if not payload then return nil,"Неверный формат или контрольная сумма."; end
  local f=split(payload,"|");
  if #f~=(modern and 7 or 5) or not AZS_GEN.classByToken[f[1]] then return nil,"Неизвестный класс или версия кода."; end
  local name=dec(f[2]);
  if not name or #name<1 or #name>320 or string.find(name,"[%z\1-\31|]") then return nil,"Некорректное название."; end
  if f[3]~="balanced" and f[3]~="damage" and f[3]~="survival" then return nil,"Неизвестный профиль."; end
  local b={class=f[1],name=name,style=f[3],spells={},items={},itemRules={},description=modern and dec(f[6]) or ""};
  if not b.description or #b.description>8000 or string.find(b.description,"[%z\1-\8\11\12\14-\31]") then return nil,"Некорректное название."; end
  local seen={};
  local function options(raw,group)
    local out,used={},{};
    if raw=="" then return out; end
    for _,key in ipairs(split(raw,".")) do
      local row=group=="spell" and A.byKey[b.class..":"..key] or A.aliasItem(key);
      if not row or row.group~=group or used[key] or #out>=64 then return nil; end
      used[key]=true; out[#out+1]=key;
    end
    return out;
  end
  if f[4]~="" then
    for _,entry in ipairs(split(f[4],",")) do
      local v=split(entry,"~"); local key=v[1];
      local any=modern and v[6]=="1";
      if (modern and #v~=8 and #v~=9 and #v~=10 or not modern and #v~=5) or (any and not string.match(key,"^@s%d+$")) or (not any and not A.byKey[b.class..":"..key]) or seen[key] or #b.spells>=6 then return nil,"Неизвестное или повторное умение."; end
      seen[key]=true; local nums={};
      for j=2,5 do
        local n=tonumber(v[j]);
        if not n or n~=n or n<0 or n>1000000000 or not string.match(v[j],"^%d+%.?%d*$") then return nil,"Некорректная цель характеристики."; end
        nums[j]=n;
      end
      if nums[2]>999 or nums[2]~=math.floor(nums[2]) or nums[5]>999 or nums[5]~=math.floor(nums[5]) then return nil,"Ранг/цели должны быть целыми (0–999)."; end
      local opts=modern and options(v[7],"spell") or {}; local note=modern and dec(v[8]) or "";
      if not opts or not note or #note>2000 or (modern and v[6]~="0" and v[6]~="1") then return nil,"Неизвестное или повторное умение."; end
      local radius=v[9] and tonumber(v[9]) or 0;
      if not radius or radius~=radius or radius<0 or radius>1e9 then return nil,"Некорректная цель характеристики."; end
      local duration=0; if v[10] then duration=tonumber(v[10]); end;
      if not duration or duration~=duration or duration<0 or duration>1e9 then return nil,"Некорректная цель характеристики."; end
      b.spells[#b.spells+1]={key=key,duration=duration,rank=nums[2],cd=nums[3],damage=nums[4],targets=nums[5],radius=radius,any=any or nil,options=opts,note=note};
    end
  end
  if modern and f[7]~="" then for _,entry in ipairs(split(f[7],",")) do
    local v=split(entry,"~"); local key=v[1]; local group=v[2]; local value,value2=tonumber(v[3]),tonumber(v[4]);
    local note=v[7] and dec(v[7]); local opts=v[6] and options(v[6],group);
    if (#v~=7 and #v~=11) or b.itemRules[key] or not ({ring=true,trinket=true,amulet=true})[group] or not value or not value2 or value~=value or value2~=value2 or value<0 or value2<0 or value>1e9 or value2>1e9 or not opts or not note or #note>2000 or (v[5]~="0" and v[5]~="1") then return nil,"Некорректная цель характеристики."; end
    if v[5]=="1" and not string.match(key,"^@"..({ring="r",trinket="t",amulet="a"})[group].."%d+$") then return nil,"Неизвестный или повторный предмет."; end
    b.itemRules[key]={group=group,value=value,value2=value2,any=v[5]=="1" or nil,options=opts,note=note};
    for j=3,6 do local n=v[j+5] and tonumber(v[j+5]) or 0;
      if not n or n~=n or n<0 or n>1e9 then return nil,"Некорректная цель характеристики."; end
      b.itemRules[key]["value"..j]=n;
    end
  end end
  local counts={};
  if f[5]~="" then for _,key in ipairs(split(f[5],",")) do
    local r=A.ItemInfo(b,key);
    if not r or seen[key] or #b.items>=12 then return nil,"Неизвестный или повторный предмет."; end
    seen[key]=true; counts[r.group]=(counts[r.group] or 0)+1;
    if counts[r.group]>(r.group=="amulet" and 8 or 2) then return nil,"Превышено число предметов в группе."; end
    b.items[#b.items+1]=key;
  end end
  for key,p in pairs(b.itemRules) do if not A.HasItem(b,key) or (not p.any and (not A.aliasItem(key) or A.aliasItem(key).group~=p.group)) then return nil,"Неизвестный или повторный предмет."; end end
  return b;
end
function A.Import(code)
  if type(code)~="string" then return nil,"Неверный формат или контрольная сумма."; end
  if string.sub(trim(code),1,6)=="ASAL1:" or string.sub(trim(code),1,6)=="ASRL3:" then return A.ImportLibrary(code); end
  local b,err=A.Decode(code); if not b then return nil,err; end
  b.id=ASAdvisorDB.nextId; ASAdvisorDB.nextId=b.id+1;
  ASAdvisorDB.builds[#ASAdvisorDB.builds+1]=b; ASAdvisorDB.active[b.class]=b.id;
  return b;
end
function A.ExportLibrary()
  local codes={}; for _,b in ipairs(ASAdvisorDB.builds) do codes[#codes+1]=A.Export(b); end
  local payload=table.concat(codes,"\n");
  return packed("ASRL3",payload);
end
function A.ImportLibrary(code)
  if type(code)~="string" or #code>1000000 then return nil,"Библиотека слишком большая."; end
  local payload;
  if string.sub(trim(code),1,6)=="ASRL3:" then payload=unpacked(code,"ASRL3");
  else
    code=A.NormalizeLegacy(code); local hash,body=string.match(code,"^ASAL1:(%x%x%x%x%x%x%x%x):(.*)$");
    if hash and string.lower(hash)==A.Checksum(body) then payload=body; end
  end
  if not payload then return nil,"Повреждён код библиотеки."; end
  local decoded={};
  for line in string.gmatch(payload,"[^\n]+") do
    local b,err=A.Decode(line); if not b then return nil,err; end
    decoded[#decoded+1]=b; if #decoded>100 then return nil,"За один раз можно импортировать до 100 билдов."; end
  end
  if #decoded==0 then return nil,"Библиотека пуста."; end
  -- Validate the complete library before changing saved state.
  for _,b in ipairs(decoded) do
    b.id=ASAdvisorDB.nextId; ASAdvisorDB.nextId=b.id+1;
    ASAdvisorDB.builds[#ASAdvisorDB.builds+1]=b; ASAdvisorDB.active[b.class]=b.id;
  end
  return decoded[1],nil,#decoded;
end

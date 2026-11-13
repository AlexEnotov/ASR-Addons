local A=ASAdvisor;
A.CapStats={
  {"cooldown","Сокращение КД","cdr","%"},{"crit","Шанс критического удара","crit","%"},
  {"damage","Урон","dmg","%"},{"crit_damage","Критический урон","critd","%"},
  {"area","Область действия","area","%"},{"echo","Повторное применение","echo","%"},
  {"reduction","Снижение урона","red","%"},{"speed","Скорость передвижения","spd","%"},
  {"luck","Удача","luck","%"},{"gold","Золото","gold","%"},
  {"xp","Опыт","xp","%"},{"pickup","Радиус подбора","pick","%"},
  {"lifesteal","Лечение от урона","ls","%"},{"regen","ОЗ/с","regen",""},
  {"kill_heal","ОЗ за убийство","kh",""},{"buff","Сила усилений","buff","%"},
  {"dot_haste","Частота периодического урона","dot","%"},{"targets","Доп. цели","tgt",""},
};
-- The native character sheet explicitly documents the effective CDR ceiling at 80%.
A.GameStatCaps={cooldown=80};
function A.RunStats()
  local raw=AZS_RUNSTATS or {}; local out={};
  for _,stat in ipairs(A.CapStats) do local value=tonumber(raw[stat[3]]); if value and value==value and math.abs(value)<1e12 then out[stat[1]]=value; end end
  return out;
end
function A.StatCap(key)
  local caps=ASAdvisorDB.options.statCaps or {}; local custom=tonumber(caps[key]); local actual=A.GameStatCaps[key];
  if custom and custom>0 and custom==custom and custom<1e12 then return actual and math.min(actual,custom) or custom; end
  return actual;
end
local aliases={leech="lifesteal",health="max_health"};
A.ItemGoalFields={"value","value2","value3","value4","value5","value6"};
local function n(s) return tonumber((string.gsub(s or "",",","."))); end
local words={
  {"crit_damage",{"critical strike damage","critical damage","критического урона","критический урон"}},
  {"cooldown",{"cooldown","cdr","кд","перезаряд","восстановлен"}}, {"luck",{"luck","удач"}}, {"gold",{"gold","золот"}},
  {"crit",{"critical","крит"}}, {"health",{"max health","maximum health","максималь","макс. здоров"}},
  {"echo",{"echo","double","cast twice","двойн","повторн"}}, {"targets",{"targets"," целей"," цели"," целям"}},
  {"reduction",{"damage reduction","damage taken","входящ","снижает урон","снижение урона"}},
  {"pickup",{"pickup","подбор","сбора"}},
  {"regen",{"health per second","здоровья в секунду","здоровье в секунду","оз/с"}},
  {"kill_heal",{"health per kill","здоровье за убийство","здоровья за убийство"}},
  {"buff",{"buff","усилени"}}, {"dot_haste",{"damage over time","периодического урона","tick"}},
  {"area",{"area","область","области","радиус"}}, {"speed",{"movement","скорость передвиж"}},
  {"pickup",{"pickup","сбора"}}, {"xp",{"experience","опыт"}}, {"leech",{"heals you","lifesteal","вампир","исцеляет","лечение от урона","исцеление от урона","похищение"}},
  {"damage",{"damage","урон","урона"}},
};
local short={damage={"УРН","DMG"},cooldown={"КД","CD"},luck={"УДЧ","LCK"},gold={"ЗОЛ","GOLD"},crit={"КРИТ","CRIT"},crit_damage={"КР.УРН","CR.DMG"},health={"ОЗ","HP"},max_health={"ОЗ","HP"},reduction={"ЗАЩ","DR"},area={"РАД","RAD"},speed={"СКОР","SPD"},pickup={"СБОР","PICK"},xp={"ОПТ","XP"},leech={"ЛЕЧ","LEECH"}};
function A.StatLabel(key,fallback)
  local pair=short[key]; return pair and pair[ASAdvisorDB.options.language=="en" and 2 or 1] or fallback or "?";
end
local baseLabels={damage="Урон",cooldown="Сокращение КД",luck="Удача",gold="Золото",crit="Шанс критического удара",crit_damage="Критический урон",max_health="Макс. здоровье",reduction="Снижение урона",regen="ОЗ/с",speed="Скорость передвижения",pickup="Радиус подбора",xp="Опыт",lifesteal="Лечение от урона",kill_heal="ОЗ за убийство",echo="Повторное применение",thorns="Отражение урона",targets="Доп. цели",area="Область действия",dot_haste="Частота периодического урона",buff="Сила усилений",lives="Воскрешения"};
local flatBase={regen=true,kill_heal=true,targets=true,lives=true};
local function fmt(v) return (string.gsub(string.gsub(string.format("%.2f",v),"0+$",""),"%.$","")); end
local function say(ru,en,...) return string.format(ASAdvisorDB.options.language=="en" and en or ru,...); end
function A.SpellAction(m)
  local s=m.shapeData and m.shapeData[m.shape] or {}; local action;
  if m.shape=="strike" or m.shape=="execute" then action=say("Поражает до %s противников.","Strikes up to %s enemies.",s.targets or 1);
  elseif m.shape=="ground" then action=say("Создаёт область периодического урона на земле.","Creates an area of periodic damage on the ground.");
  elseif m.shape=="nova" then action=say("Наносит урон противникам вокруг точки взрыва.","Damages enemies around the point of impact.");
  elseif m.shape=="dot" then action=say("Накладывает периодический урон на несколько целей.","Applies damage over time to several targets.");
  elseif m.shape=="cone" then action=say("Поражает противников перед персонажем по площади.","Hits enemies in an area in front of the character.");
  elseif m.shape=="chain" then action=say("Урон перескакивает между ближайшими противниками.","Damage jumps between nearby enemies.");
  elseif m.shape=="missiles" then action=say("Выпускает несколько снарядов.","Fires multiple projectiles.");
  elseif m.shape=="heal" then action=say("Восстанавливает здоровье персонажа.","Restores the character's health.");
  elseif m.shape=="shield" then action=say("Создаёт щит, поглощающий входящий урон.","Creates a shield that absorbs incoming damage.");
  elseif m.shape=="haste" then action=say("Временно ускоряет перезарядку способностей на %s%%.","Temporarily speeds up ability cooldowns by %s%%.",s.pct or 0);
  elseif m.shape=="fury" then action=say("Временно усиливает наносимый урон на %s%%.","Temporarily increases damage dealt by %s%%.",s.pct or 0);
  elseif m.shape=="immune" then action=say("Временно даёт невосприимчивость к урону.","Temporarily grants immunity to damage.");
  elseif m.shape=="summon" or m.shape=="command" then action=say("Призывает питомцев или приказывает им атаковать.","Summons pets or commands them to attack.");
  elseif m.shape=="totem" then action=say("Размещает тотем с периодическим действием.","Places a totem with a periodic effect.");
  elseif m.shape=="thorns" then action=say("Возвращает урон атакующим противникам.","Returns damage to attacking enemies.");
  elseif m.shape=="orbit" then action=say("Создаёт вращающиеся вокруг персонажа объекты.","Creates objects orbiting the character.");
  elseif m.shape=="sphere" then action=say("Создаёт сферы с восстанавливающим эффектом.","Creates spheres with a restorative effect.");
  elseif m.shape=="empower" then action=say("Временно усиливает способности персонажа.","Temporarily empowers the character's abilities.");
  elseif m.shape=="passive" or m.shape=="bond" then action=say("Даёт пассивное усиление.","Grants a passive enhancement.");
  elseif m.shape=="proc" then
    local effects={arcs={"Поражает противников магическими разрядами в области.","Hits enemies with magical arcs in an area."},mark={"Накладывает метку на противников в области.","Applies a mark to enemies in an area."},sheep={"Превращает противников в овец.","Transforms enemies into sheep."},holy_burst={"Вызывает вспышку святой энергии в области.","Creates a burst of holy energy in an area."},combo={"Особый эффект, связанный с серией атак.","A special effect linked to a chain of attacks."},shards={"Использует осколки для особого эффекта.","Uses shards for a special effect."},rage={"Особый эффект ярости в области.","A special rage effect in an area."}};
    local e=effects[s.kind]; action=e and say(e[1],e[2]) or say("Особое действие умения.","A special spell effect.");
  else action=say("Особое действие умения.","A special spell effect."); end
  local lines={action};
  if s.secs and s.secs>0 then lines[#lines+1]=say("Действует %s сек.","Lasts %s sec.",fmt(s.secs)); end
  if s.every then lines[#lines+1]=say("Срабатывает каждые %s сек.","Triggers every %s sec.",fmt(s.every)); end
  if s.count then lines[#lines+1]=say("Количество: %s.","Count: %s.",s.count); end
  local riders={slow={"Замедление","Slow"},root={"Обездвиживание","Root"},stun={"Оглушение","Stun"},weaken={"Ослабление","Weaken"},flee={"Страх","Fear"},mend={"Лечение","Healing"},drain={"Похищение здоровья","Health drain"},guard={"Защита","Protection"}};
  for key,p in pairs(m.rider or {}) do local title=riders[key]; if title then lines[#lines+1]=say(title[1],title[2])..(p.pct and " "..fmt(p.pct).."%" or "")..(p.secs and say(" на %s сек."," for %s sec.",fmt(p.secs)) or "").."."; end end
  return table.concat(lines,"\n");
end
function A.BaseItemText(row)
  local m=ASAdvisorMechanics.items[row.key]; if not m then return A.T("Базовые данные предмета недоступны."); end
  if m.legend then return A.LegendDescription(m.legend,m.classes); end
  local parts={A.T(row.group=="amulet" and "Базовые значения · ранг 1" or "Базовые значения · до редкости и улучшений")};
  local explanation={lifesteal={"Возвращает часть нанесённого урона в виде здоровья.","Restores part of damage dealt as health."},kill_heal={"Восстанавливает здоровье за убийства.","Restores health on kills."},regen={"Постоянно восстанавливает здоровье.","Continuously restores health."},cooldown={"Сокращает время перезарядки способностей.","Reduces ability cooldowns."},area={"Увеличивает область действия способностей.","Increases the area affected by abilities."},echo={"Даёт шанс повторного применения способности.","Grants a chance to repeat an ability."},lives={"Даёт дополнительные воскрешения.","Grants additional revivals."}};
  local seen={}; local function explain(effect) local e=explanation[effect]; if e and not seen[effect] then parts[#parts+1]=say(e[1],e[2]); seen[effect]=true; end end
  explain(m.behavior); for _,pair in ipairs(m.effects or {}) do explain(pair[1]); end
  local function add(effect,value)
    local label=baseLabels[effect];
    if label then parts[#parts+1]=A.T(label)..": "..fmt(value*(flatBase[effect] and 1 or 100))..(flatBase[effect] and "" or "%"); return true; end
  end
  for _,pair in ipairs(m.effects or {}) do add(pair[1],pair[2]); end
  if m.base then
    if m.behavior=="reduction_and_health" then add("reduction",m.base); parts[#parts+1]=A.T("Также увеличивает максимум здоровья.");
    elseif m.behavior=="health_and_reduction" then add("max_health",m.base); parts[#parts+1]=A.T("Также снижает входящий урон.");
    elseif not add(m.behavior,m.base) then parts[#parts+1]=A.T("Базовая сила особого эффекта")..": "..fmt(m.base*100).."%"; end
  end
  local specialLabels={ignite="Горение от критических ударов",jump="Перескок урона",splash="Урон по соседним целям",explode="Сила взрыва"};
  for _,pair in ipairs(m.specials or {}) do parts[#parts+1]=A.T(specialLabels[pair[1]] or "Базовая сила особого эффекта")..": "..fmt(pair[2]*100).."%"; end
  if m.specialName=="cheat_death" then parts[#parts+1]=A.T("Защита от смертельного удара."); end
  if m.classes and #m.classes>0 then local names={}; for _,token in ipairs(m.classes) do names[#names+1]=A.ClassName(token); end; parts[#parts+1]=A.T("Классовый амулет")..": "..table.concat(names,", "); end
  if #parts==1 then parts[#parts+1]=A.T("Числовые параметры не извлечены."); end
  return table.concat(parts,"\n");
end
function A.LegendDescription(m,classes)
  local parts={A.T("Классовый амулет")}; local names={};
  for _,token in ipairs(classes or {}) do names[#names+1]=A.ClassName(token); end
  parts[#parts+1]=table.concat(names,", ");
  local spell; for _,token in ipairs(classes or {}) do spell=A.byKey[token..":"..m.spell]; if spell then break end end
  parts[#parts+1]=A.T("Усиление умения")..": "..(spell and spell.name or "?");
  local labels={area="Область действия",damage="Урон",targets="Доп. цели",cooldown="Сокращение КД",duration="Длительность",burn="Горение",stun="Оглушение",splash="Урон по соседним целям",heal="Лечение",weaken="Ослабление",share="Доля урона",chance="Шанс",secs="Длительность",radius="Радиус",reset="Сброс перезарядки",jump="Перескок урона",slow="Замедление",crit="Шанс критического удара",echo="Повторное применение",absorb="Поглощение",pierce="Пробивание",execute="Добивание"};
  local function value(key,v)
    if key=="targets" or key=="count" then return fmt(v); end
    if key=="secs" or key=="duration" then return fmt(v)..A.T(" сек."); end
    if key=="radius" then return fmt(v)..A.T(" м"); end
    return fmt(v*100).."%";
  end
  for _,effect in ipairs(m.effects) do
    if type(effect)=="string" then parts[#parts+1]=A.T(labels[effect] or "Особый эффект");
    else for key,v in pairs(effect) do
      if type(v)=="number" then parts[#parts+1]=A.T(labels[key] or "Особый эффект")..": "..value(key,v);
      elseif type(v)=="table" then local details={}; for _,field in ipairs({"chance","share","secs","radius","count"}) do if type(v[field])=="number" then details[#details+1]=A.T(labels[field] or "Количество").." "..value(field,v[field]); end end; parts[#parts+1]=A.T(labels[key] or "Особый эффект")..(#details>0 and ": "..table.concat(details,", ") or ""); end
    end end
  end
  parts[#parts+1]=A.T("Базовые параметры · без улучшений"); return table.concat(parts,"\n");
end
function A.BaseItemMetrics(row)
  local m=row and ASAdvisorMechanics.items[row.key]; local result={}; if not m then return result; end
  local function add(effect,value)
    result[#result+1]={kind=effect,value=value*(flatBase[effect] and 1 or 100),unit=flatBase[effect] and "" or "%",text=A.T(baseLabels[effect] or "Особый эффект")};
  end
  for _,pair in ipairs(m.effects or {}) do add(pair[1],pair[2]); end
  if m.base then
    if m.behavior=="reduction_and_health" then add("reduction",m.base); result[#result+1]={kind="max_health",unit="%"};
    elseif m.behavior=="health_and_reduction" then add("max_health",m.base); result[#result+1]={kind="reduction",unit="%"};
    else add(m.behavior,m.base); end
  end
  for _,pair in ipairs(m.specials or {}) do add(pair[1],pair[2]); end
  if m.legend then for _,effect in ipairs(m.legend.effects) do if type(effect)=="table" then for key,value in pairs(effect) do if type(value)=="number" then add(key,value); end end end end end
  return result;
end
function A.SpellDescription(row,baseOnly)
  local raw=not baseOnly and AZS_SPELLTIPS and AZS_SPELLTIPS[row.key];
  if raw and A.Snapshot().spells[row.key] then return A.T("Текущие значения")..": "..raw; end
  local m=ASAdvisorMechanics.spells and ASAdvisorMechanics.spells[row.key];
  if not m then return A.T("Точное описание появится при получении умения в забеге."); end
  local parts={A.T("Базовые параметры · без улучшений"),A.SpellAction(m)};
  if m.hit and m.hit>0 then parts[#parts+1]=A.T("Урон")..": "..fmt(m.hit); end
  if m.cooldown then parts[#parts+1]=A.T("перезарядка")..": "..fmt(m.cooldown)..A.T(" сек."); end
  if m.radius then parts[#parts+1]=A.T("Радиус")..": "..fmt(m.radius)..A.T(" м"); end
  if m.targets then parts[#parts+1]=A.T("число целей")..": "..m.targets; end
  local timed=m.shapeData and m.shapeData[m.shape]; if timed and timed.secs then parts[#parts+1]=A.T("Длительность")..": "..fmt(timed.secs)..A.T(" сек."); end
  parts[#parts+1]=A.T("Точное описание с эффектами доступно у взятого умения.");
  return table.concat(parts,"\n");
end
function A.BaseFacts(row)
  if not row or row.any then return A.T("Любой вариант"); end
  local parts={};
  if row.group=="spell" then
    local m=ASAdvisorMechanics.spells and ASAdvisorMechanics.spells[row.key];
    if m then
      if m.cooldown then parts[#parts+1]=A.StatLabel("cooldown").." "..fmt(m.cooldown)..A.T(" сек."); end
      if m.hit and m.hit>0 then parts[#parts+1]=A.StatLabel("damage").." "..fmt(m.hit); end
      if m.radius then parts[#parts+1]=A.StatLabel("area").." "..fmt(m.radius)..A.T(" м"); end
      if m.targets then parts[#parts+1]="×"..m.targets; end
      local timed=m.shapeData and m.shapeData[m.shape]; if timed and timed.secs then parts[#parts+1]=A.T("Длительность").." "..fmt(timed.secs)..A.T(" сек."); end
    end
  else
    for i,m in ipairs(A.BaseItemMetrics(row)) do if m.value then parts[#parts+1]=A.StatLabel(m.kind,A.T("Бонус").." "..i).." "..fmt(m.value)..(m.unit or ""); end end
  end
  return A.T("Базовые")..": "..(#parts>0 and table.concat(parts," · ") or A.T("Подробности при наведении"));
end
function A.GoalText(p,group)
  local parts={};
  local fields=group=="spell" and {"rank","cd","damage","targets","radius","duration"} or A.ItemGoalFields;
  for i,key in ipairs(fields) do if (tonumber(p[key]) or 0)>0 then
    local name=({rank="Ранг",cd="КД",damage="Урон",targets="Цели",radius="Радиус",duration="Длительность"})[key];
    parts[#parts+1]=(name and A.T(name) or A.T("Бонус").." "..i)..(key=="cd" and " ≤ " or " ≥ ")..p[key];
  end end
  return #parts>0 and table.concat(parts," · ") or A.T("Без ограничения");
end
function A.ItemDescription(row,live)
  for _,g in ipairs(live.gear or {}) do
    local actual=A.ResolveItem(g);
    if actual and actual.key==row.key and g.text and g.text~="" then return A.T("Текущие значения")..": "..g.text,"current"; end
  end
  return A.BaseItemText(row),"base";
end
local function kind(text)
  text=" "..A.Lower(text);
  for _,row in ipairs(words) do for _,needle in ipairs(row[2]) do if string.find(text,needle,1,true) then return row[1]; end end end
end
function A.ItemCapped(row,card,live)
  local m=ASAdvisorMechanics.items[row.key]; if not m then return false; end
  local benefits={}; local unknown=m.legend~=nil or m.specialName~=nil or #(m.specials or {})>0;
  local function add(key) key=aliases[key] or key; benefits[key]=true; end
  if (card.mode=="grow" or card.mode=="empower") and card.detail and card.detail~="" then
    local changes=0;
    for entry in string.gmatch(card.detail,"[^%^]+") do
      local label,from,to,way=string.match(entry,"^(.-)=(.-)=(.-)=(.)$");
      if not label then unknown=true;
      elseif way=="+" then
        changes=changes+1; local key=m.base and m.behavior~="" and m.behavior or kind(label);
        if key then add(key); else unknown=true; end
      end
    end
    if changes==0 then return false; end
  else
    if m.base then add(m.behavior); end
    for _,effect in ipairs(m.effects or {}) do add(effect[1]); end
    if m.legend or m.specialName or #(m.specials or {})>0 then unknown=true; end
  end
  if unknown or not next(benefits) then return false; end
  for key in pairs(benefits) do
    local limit=A.StatCap(key); local current=live.stats and tonumber(live.stats[key]);
    if not limit or not current or current<limit-0.00001 then return false; end
  end
  return true;
end
-- Only a single numeric benefit per segment is accepted. Multi-number proc text stays unknown.
function A.ItemMetrics(gear)
  local result={}; local raw=A.Plain(gear and gear.text or "");
  raw=string.gsub(string.gsub(raw,", "," · "),"\n"," · ");
  for segment in string.gmatch(raw.." · ","(.-) · ") do
    local values,percent={},{};
    for value in string.gmatch(segment,"(%d+[%.,]?%d*)%%") do percent[#percent+1]=n(value); end
    for value in string.gmatch(segment,"(%d+[%.,]?%d*)") do values[#values+1]=n(value); end
    local v,unit;
    if #percent==1 and #values==1 then v=percent[1]; unit="%";
    elseif #percent==0 and #values==1 then v=values[1]; unit=""; end
    if segment~="" then result[#result+1]={value=v,unit=unit or "",kind=kind(segment),text=segment}; end
  end
  return result;
end
function A.ShortItem(gear)
  local parts={}; for i,m in ipairs(A.ItemMetrics(gear)) do if i<=6 then
    parts[#parts+1]=m.value and (A.StatLabel(m.kind,A.T("Бонус").." "..i).." "..m.value..m.unit) or A.T("Особый эффект");
  end end
  return table.concat(parts," · ");
end
function A.WornForKey(b,key,live)
  local rule=b.itemRules and b.itemRules[key];
  if rule and rule.any then
    local assigned=A.AnyAssignments(b,live,rule.group); local g=assigned[key]; return g;
  end
  for _,g in ipairs(live.gear or {}) do local r=A.ResolveItem(g); if r and r.key==key then return g; end end
end
local function accepts(rule,key)
  if not rule.options or #rule.options==0 then return true; end
  for _,option in ipairs(rule.options) do if key==option then return true; end end
  return false;
end
A.AnyAccepts=accepts;
-- Match each owned non-fixed pick to at most one Any slot. Augmenting paths preserve constrained choices.
function A.AnyAssignments(b,live,group)
  local slots,candidates,explicit={},{},{};
  if group=="spell" then
    for _,p in ipairs(b.spells) do if p.any then slots[#slots+1]=p; else explicit[p.key]=true; end end
    for key,s in pairs(live.spells or {}) do if not explicit[key] and (tonumber(s.rank) or 0)>0 and A.byKey[b.class..":"..key] then candidates[#candidates+1]={key=key,value=key}; end end
  else
    for _,key in ipairs(b.items) do local row=A.ItemInfo(b,key); if row and row.group==group then
      local p=b.itemRules and b.itemRules[key]; if p and p.any then local s=A.Copy(p); s.key=key; slots[#slots+1]=s; else explicit[key]=true; end
    end end
    for _,g in ipairs(live.gear or {}) do local row=A.ResolveItem(g); if g.slot==group and not (row and explicit[row.key]) then candidates[#candidates+1]={key=row and row.key,value=g}; end end
  end
  table.sort(candidates,function(x,y) return tostring(x.key)<tostring(y.key); end);
  local owner={}; local function assign(index,seen)
    local slot=slots[index];
    for j,c in ipairs(candidates) do if not seen[j] and accepts(slot,c.key) then
      seen[j]=true;
      if not owner[j] or assign(owner[j],seen) then owner[j]=index; return true; end
    end end
    return false;
  end
  for i=1,#slots do assign(i,{}); end
  local out={}; for j,i in pairs(owner) do out[slots[i].key]=candidates[j].value; end; return out;
end
function A.MatchSpell(b,key,live)
  if not A.byKey[b.class..":"..tostring(key)] then return; end
  local exact,priority=A.FindPick(b,key); if exact and not exact.any then return exact,priority; end
  local assignments=A.AnyAssignments(b,live,"spell");
  for i,p in ipairs(b.spells) do if p.any and assignments[p.key]==key then return p,i; end end
  for _,p in ipairs(b.spells) do if not p.any and (not live.spells[p.key] or (tonumber(live.spells[p.key].rank) or 0)<=0) then return; end end
  for i,p in ipairs(b.spells) do if p.any and not assignments[p.key] and accepts(p,key) then return p,i; end end
end
function A.MatchItem(b,row,live)
  if not row then return; end
  if A.HasItem(b,row.key) then return row.key,A.ItemRule(b,row.key); end
  local assignments=A.AnyAssignments(b,live,row.group);
  for _,key in ipairs(b.items) do local p=b.itemRules and b.itemRules[key]; if p and p.any and p.group==row.group then
    local g=assignments[key]; local owned=g and A.ResolveItem(g);
    if owned and owned.key==row.key then return key,p; end
  end end
  if row.group~="amulet" then
    for _,key in ipairs(b.items) do local r=A.ItemInfo(b,key); if r and r.group==row.group and not r.any and not A.WornForKey(b,key,live) then return; end end
  end
  for _,key in ipairs(b.items) do local p=b.itemRules and b.itemRules[key];
    if p and p.any and p.group==row.group and not assignments[key] and accepts(p,row.key) then return key,p; end
  end
end
function A.TrackerEntries(b,live)
  local spells,items,usedSpell,usedGear={},{},{},{};
  local token=b and b.class or A.Class();
  local assignments=b and A.AnyAssignments(b,live,"spell") or {};
  local function spell(row,key,planned)
    local current=key and live.spells[key]; local stats=key and A.SpellStats(key,live) or {};
    local parts={}; if current then
      if stats.cd then parts[#parts+1]=A.StatLabel("cooldown").." "..stats.cd.."s"; end
      if stats.damage then parts[#parts+1]=A.StatLabel("damage").." "..stats.damage; end
      if stats.targets then parts[#parts+1]=A.T("Цели").." "..stats.targets; end
      if stats.duration then parts[#parts+1]=A.T("Длительность").." "..stats.duration..A.T(" сек."); end
      if stats.radius then parts[#parts+1]=A.StatLabel("area").." "..stats.radius..A.T(" м"); end
      usedSpell[key]=true;
    end
    spells[#spells+1]={row=row,owned=current~=nil,rank=current and current.rank,detail=table.concat(parts," · "),planned=planned};
  end
  for _,p in ipairs(b and b.spells or {}) do
    local key=p.any and assignments[p.key] or p.key;
    local row=key and A.byKey[token..":"..key] or A.Info(b,p.key,"spell"); spell(row,key,true);
  end
  for key in pairs(live.spells) do if not usedSpell[key] and A.byKey[token..":"..key] then spell(A.byKey[token..":"..key],key,false); end end
  for _,key in ipairs(b and b.items or {}) do
    local row=A.ItemInfo(b,key); local g=A.WornForKey(b,key,live);
    if g then usedGear[g]=true; if row.any then row=A.ResolveItem(g) or {name=g.name,icon=g.icon,group=g.slot}; end end
    items[#items+1]={row=row,owned=g~=nil,detail=g and A.ShortItem(g) or "",planned=true};
  end
  for _,g in ipairs(live.gear) do if not usedGear[g] then
    local row=A.ResolveItem(g) or {name=g.name,icon=g.icon,group=g.slot};
    items[#items+1]={row=row,owned=true,detail=A.ShortItem(g),planned=false};
  end end
  return spells,items;
end

local A=ASAdvisor;
A.SchoolColors={physical="dfd5c4",holy="ffe58a",fire="ff9360",frost="80dfff",nature="83dc89",shadow="bb95e8",arcane="d5a0ff",bleed="ff7272",heal="79e6ae"};
local schools={physical="Физический урон",holy="Светлая магия",fire="Огонь",frost="Холод",nature="Природа",shadow="Тьма",arcane="Тайная магия"};
function A.Tint(value,hex) return "|cff"..hex..tostring(value).."|r"; end
function A.ClassHex(row,token)
  local class=AZS_GEN and AZS_GEN.classByToken and AZS_GEN.classByToken[row and row.class or token or A.Class()];
  return class and class.hex or "8cd123";
end
function A.SetClassText(font,row,token)
  local hex=A.ClassHex(row,token); font:SetTextColor(tonumber(string.sub(hex,1,2),16)/255,tonumber(string.sub(hex,3,4),16)/255,tonumber(string.sub(hex,5,6),16)/255,1);
end
function A.SpellTags(row)
  local m=ASAdvisorMechanics.spells and ASAdvisorMechanics.spells[row.key]; if not m then return ""; end
  local shape=m.shape; local tags={};
  local function add(key) tags[#tags+1]=A.T(key); end
  if m.targets then add("Таргетное");
  elseif shape=="missiles" then add("Таргетное");
  elseif shape=="ground" or shape=="cone" or shape=="nova" or shape=="orbit" or shape=="proc" and m.radius or shape=="totem" and (m.radius or 0)>0 then add("Массовое");
  elseif shape=="chain" then add("Таргетное"); add("Цепь"); end
  if shape=="ground" then add("Область на земле"); add("Периодическое");
  elseif shape=="cone" then add("Конус");
  elseif shape=="nova" then add("Круговая область");
  elseif shape=="orbit" then add("Вокруг персонажа");
  elseif shape=="dot" then add("Периодическое");
  elseif shape=="heal" or shape=="sphere" then add("Исцеление");
  elseif shape=="shield" then add("Щит"); add("Поглощение");
  elseif shape=="fury" or shape=="haste" or shape=="empower" then add("Усиление");
  elseif shape=="immune" then add("Защита"); add("Невосприимчивость");
  elseif shape=="thorns" then add("Защита"); add("Ответный урон");
  elseif shape=="summon" or shape=="command" then add("Питомцы");
  elseif shape=="passive" or shape=="bond" then add("Пассивное");
  elseif shape=="totem" then add("Тотем");
  elseif shape=="missiles" then add("Снаряды"); end
  if schools[m.school] then add(schools[m.school]); end
  -- A support effect does not imply a co-op-only restriction. Use explicit
  -- game wording, never a spell's WoW name, for mode/support badges.
  local current=A.Lower(A.Plain(AZS_SPELLTIPS and AZS_SPELLTIPS[row.key] or ""));
  if string.find(current,"co-op",1,true) or string.find(current,"кооператив",1,true) then add("Co-op"); end
  if string.find(current,"solo only",1,true) or string.find(current,"только соло",1,true) then add("Только соло"); end
  if string.find(current,"allies",1,true) or string.find(current,"союзник",1,true) then add("Поддержка союзников"); end
  return table.concat(tags," · ");
end
function A.ColorTooltipLine(line,row)
  local raw=A.Plain(line); if raw=="" then return ""; end
  local m=row and (row.legend and ASAdvisorMechanics.spells[row.legend.spell] or row.group=="spell" and ASAdvisorMechanics.spells[row.key]);
  local damage=A.SchoolColors[m and m.school] or "dfd5c4"; local words={};
  local function add(value,hex) if value and value~="" then words[#words+1]={value=A.Lower(value),hex=hex}; end end
  for _,phrase in ipairs({"Базовые параметры · без улучшений","Базовые значения · до редкости и улучшений","Базовые значения · ранг 1","Базовые","Описание"}) do add(A.T(phrase),"d5bc83"); end
  add(A.T("Текущие значения"),"8cd123"); add(A.T("Вне билда"),"ffb15c");
  local literals={
    holy={"светлой магии","светлая магия","holy damage"},fire={"магии огня","огнём","огнем","огня","огонь","fire damage","burning damage","burn damage","горением","горения","горение"},
    frost={"магии льда","холодом","холод","льдом","frost damage"},nature={"сил природы","природы","природа","nature damage"},
    shadow={"тёмной магией","темной магией","тёмной магии","темной магии","тьма","shadow damage"},arcane={"тайной магией","тайной магии","тайная магия","arcane damage"},
    physical={"физический урон","физического урона","physical damage"},bleed={"кровотечением","кровотечения","кровотечение","bleed damage"},
    heal={"исцеление","исцеляет","лечение","healing"},
  };
  for school,list in pairs(literals) do for _,phrase in ipairs(list) do add(phrase,A.SchoolColors[school]); end end
  for _,phrase in ipairs({"урон","урона","урону","damage","УРН","DMG"}) do add(phrase,damage); end
  local token=row and row.class or A.Class(); local class=AZS_GEN and AZS_GEN.classByToken and AZS_GEN.classByToken[token];
  if class then add(A.Local(class.name),A.ClassHex(row,token)); end
  local lower=A.Lower(raw); local out,from={},1;
  while from<=#raw do
    local bestStart,bestEnd,best;
    for _,word in ipairs(words) do local i,j=string.find(lower,word.value,from,true);
      if i and (not bestStart or i<bestStart or i==bestStart and j>bestEnd) then bestStart,bestEnd,best=i,j,word; end
    end
    if not best then out[#out+1]=string.sub(raw,from); break end
    out[#out+1]=string.sub(raw,from,bestStart-1); out[#out+1]=A.Tint(string.sub(raw,bestStart,bestEnd),best.hex); from=bestEnd+1;
  end
  return table.concat(out);
end

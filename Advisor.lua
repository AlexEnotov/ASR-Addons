local A=ASAdvisor;
local function number(s)
  s=string.gsub(string.gsub(s or "","%s",""),",",".");
  return tonumber(s);
end
-- Parse only explicit amounts in supported game tooltip wording; never substitute base damage.
function A.DamageFromTip(text)
  text=A.Plain(text);
  for _,space in ipairs({" "," "," "}) do text=string.gsub(text,space," "); end
  local values={};
  for n in string.gmatch(text,"(%d[%d%s%.,]*)%s+ед%.%s+урона") do values[#values+1]=number(n); end
  if #values==0 then
    for _,school in ipairs({"physical","shadow","fire","frost","nature","arcane","holy"}) do
      for n in string.gmatch(text,"(%d[%d%.,]*)%s+"..school.." damage") do values[#values+1]=number(n); end
    end
    if #values==0 then for n in string.gmatch(text,"(%d[%d%.,]*) damage") do values[#values+1]=number(n); end end
  end
  if #values~=1 then return nil; end
  return values[1];
end
function A.TargetsFromTip(text)
  text=A.Plain(text);
  local n=string.match(text,"Поражает до (%d+) противников") or string.match(text,"Hits up to (%d+) enemies") or string.match(text,"Strikes up to (%d+) enemies");
  if n then return tonumber(n); end
  if string.find(text,"Поражает ближайшего противника",1,true) or string.find(text,"Hits the nearest enemy",1,true) then return 1; end
end
function A.DurationFromTip(text)
  text=A.Plain(text);
  local values={};
  for _,pattern in ipairs({"в течение%s+(%d+[%.,]?%d*)%s*сек", "за%s+(%d+[%.,]?%d*)%s*сек", "на%s+(%d+[%.,]?%d*)%s*сек", "for%s+(%d+[%.,]?%d*)%s*sec", "over%s+(%d+[%.,]?%d*)%s*sec"}) do
    for value in string.gmatch(text,pattern) do values[#values+1]=number(value); end
  end
  -- Multiple timed effects cannot be assigned to the main duration safely.
  if #values==1 then return values[1]; end
end
function A.SpellStats(key,live)
  local s=live.spells[key]; local tip=AZS_SPELLTIPS and AZS_SPELLTIPS[key];
  if not s then return {}; end
  return { rank=tonumber(s.rank), cd=tonumber(s.cdmax), damage=A.DamageFromTip(tip), targets=A.TargetsFromTip(tip), duration=A.DurationFromTip(tip), radius=A.RadiusFromTip(key,tip) };
end
function A.RadiusFromTip(key,text)
  local m=ASAdvisorMechanics.spells and ASAdvisorMechanics.spells[key];
  if not m or not m.radius then return; end
  text=A.Plain(text);
  local values={};
  for value in string.gmatch(text,"радиус[^%s]*%s+(%d+[%.,]?%d*)%s*м") do values[#values+1]=number(value); end
  if #values==0 then for value in string.gmatch(text,"within%s+(%d+[%.,]?%d*)%s+yd") do values[#values+1]=number(value); end end
  -- Ground effects describe placement range first and effect radius last.
  if #values>0 then return values[#values]; end
end
function A.Boosts(card)
  local out={};
  for code,amount in string.gmatch(tostring(card.lines or ""),"(%a)(%d+)") do
    local field=({d="damage",m="damage",c="cd",t="targets",a="radius",u="duration",k="crit",h="heal",b="absorb"})[code];
    if field and tonumber(amount)>0 then out[field]=true; end
  end
  return out;
end
function A.GoalStatus(p,stats)
  local out={};
  for _,field in ipairs({"cd","damage","targets","radius","duration"}) do
    local goal=tonumber(p[field]) or 0;
    if goal>0 then
      local value=stats[field];
      out[field]=value==nil and "unknown" or ((field=="cd" and value<=goal+0.00001) or (field~="cd" and value>=goal)) and "met" or "needed";
    end
  end
  return out;
end
function A.ScoreSpell(b,card,live,index)
  local p,priority=A.MatchSpell(b,card.key,live);
  local r={index=index,card=card,score=0,reason=A.T("Вне выбранного билда"),kind="off"};
  if not p then return r; end
  r.any=p.any==true;
  local current=live.spells[card.key];
  local cap=tonumber(AZS_CARDS and AZS_CARDS.slm) or 6;
  local used=0; for _,s in pairs(live.spells) do if (tonumber(s.rank) or 0)>0 then used=used+1; end end
  if not current or (tonumber(current.rank) or 0)<=0 then
    if tonumber(card.new)==1 and used>=cap then r.reason=A.T("Нет свободного слота"); return r; end
    r.score=(p.any and 600 or 1200)-priority*20+(tonumber(card.rarity) or 0); r.reason=p.any and "Any" or A.T("Нужное умение").." · "..A.T("приоритет").." "..priority; r.kind="planned"; return r;
  end
  local stats=A.SpellStats(card.key,live);
  local status=A.GoalStatus(p,stats);
  -- Explicit stat goals define completion of the whole pick. Unspecified boosts
  -- may help while a goal remains open, but cannot revive a completed pick.
  local hasStatGoals,complete=false,true;
  for _,value in pairs(status) do hasStatGoals=true; if value~="met" then complete=false; end end
  if hasStatGoals and complete then
    r.reason=A.T("Карточка не улучшает недостигнутую цель"); r.kind="met"; return r;
  end
  local boosts=A.Boosts(card);
  local needed,unknown,any=false,false,false;
  local labels={cd="перезарядка",damage="урон",targets="число целей",radius="Радиус",duration="Длительность"};
  local reasons={};
  for _,field in ipairs({"cd","damage","targets","radius","duration"}) do
    if status[field] then
      any=true;
      if boosts[field] and status[field]=="needed" then needed=true; reasons[#reasons+1]=field=="cd" and A.T("нужно сократить перезарядку") or A.T(labels[field]).." "..A.T("ниже цели");
      elseif boosts[field] and status[field]=="unknown" then unknown=true; end
    end
  end
  -- Zero is uncapped, not disabled. Positive caps still stop their own improvement type.
  for field in pairs(boosts) do
    if status[field]==nil then
      needed=true;
      reasons[#reasons+1]=A.T(labels[field] or field).." · "..A.T("без ограничения");
    end
  end
  if any then
    if needed then
      r.score=(p.any and 450 or 900)-priority*20+(tonumber(card.rarity) or 0); r.reason=table.concat(reasons,", ");
      r.kind="planned";
    elseif unknown then r.reason=A.T("Нельзя проверить цель: нет точного значения"); r.kind="unknown";
    else r.reason=A.T("Карточка не улучшает недостигнутую цель"); r.kind="met"; end
    return r;
  end
  local goal=tonumber(p.rank) or 0;
  if goal>0 and stats.rank and stats.rank>=goal then r.reason=A.T("Целевой ранг уже достигнут"); r.kind="met"; return r; end
  r.score=(p.any and 350 or 700)-priority*20+(tonumber(card.rarity) or 0); r.reason=A.T("Улучшение умения из билда"); r.kind="planned";
  return r;
end
-- Compare only explicit totals for simple multiplicative damage/echo bonuses.
-- Health, luck, cooldowns, crit and compound effects are not treated as equivalent percentages.
function A.ItemDamageGain(row,card,worn)
  if not worn or (card.mode~="grow" and card.mode~="empower") then return; end
  local m=ASAdvisorMechanics.items[row.key]; local behavior=m and m.behavior;
  if behavior~="damage" and behavior~="echo" then return; end
  local entries={}; for entry in string.gmatch(card.detail or "","[^%^]+") do entries[#entries+1]=entry; end
  if #entries~=1 then return; end
  local name,from,to,way=string.match(entries[1],"^(.-)=(.-)=(.-)=(.)$");
  if not name or way~="+" then return; end
  local before=string.match(A.Plain(from),"^%+?(%d+[%.,]?%d*)%%$");
  local after=string.match(A.Plain(to),"^%+?(%d+[%.,]?%d*)%%$");
  before=before and number(before); after=after and number(after);
  if not before or not after or after<=before then return; end
  return (1+after/100)/(1+before/100)-1;
end
function A.ScoreItem(b,card,live,index)
  local row=A.ResolveItem(card,b.class);
  local r={index=index,card=card,score=0,reason=A.T("Предмет вне билда"),kind="off"};
  if card.mode=="gold" then return r; end
  local key,rule=A.MatchItem(b,row,live);
  if key then
    r.any=rule.any==true;
    if A.ItemCapped(row,card,live) then r.reason=A.T("Достигнут общий кап характеристики"); r.kind="met"; return r; end
    local priority=A.ItemPriority(b,key,row.group) or 1;
    if row.group=="amulet" then
      for _,g in ipairs(live.gear or {}) do
        if g.slot=="amulet" then
          local worn=A.ResolveItem(g);
          local wornPriority=worn and A.ItemPriority(b,worn.key,"amulet");
          if wornPriority and wornPriority<priority then r.reason=A.T("Амулет ниже надетого по приоритету"); return r; end
        end
      end
    end
    local worn=A.WornForKey(b,key,live);
    local hasGoal=false; for _,field in ipairs(A.ItemGoalFields) do if (rule[field] or 0)>0 then hasGoal=true; end end
    if worn and hasGoal then
      local metrics=A.ItemMetrics(worn); local unmet,unknown=false,false;
      for i,field in ipairs(A.ItemGoalFields) do if (rule[field] or 0)>0 then
        local v=metrics[i] and metrics[i].value;
        if v==nil then unknown=true; elseif v<rule[field] then unmet=true; end
      end end
      if not unmet then r.reason=A.T(unknown and "Нельзя проверить цель: нет точного значения" or "Предмет достиг цели"); r.kind=unknown and "unknown" or "met"; return r; end
    end
    local hasDetail,improves=false,false;
    for way in string.gmatch(card.detail or "","=[^=^]*=[^=^]*=(.)") do hasDetail=true; if way~="=" then improves=true; end end
    if hasDetail and not improves then r.reason=A.T("Предмет достиг максимума"); return r; end
    -- Positions in different equipment groups cannot define a global priority.
    r.score=rule.any and 450 or 900;
    r.damageGain=A.ItemDamageGain(row,card,worn);
    r.reason=A.T((card.mode=="grow" or card.mode=="empower") and "Улучшение предмета из билда" or "Предмет из билда"); r.kind="planned";
    return r;
  end
  if not row then r.reason=A.T("Неизвестный предмет: только данные карточки"); r.kind="unknown"; end
  return r;
end
function A.Recommend(b,offer,live)
  local list={};
  if not b or b.class~=A.Class() or not live.inRun or not offer then return list; end
  for i,c in ipairs(offer.cards or {}) do
    list[#list+1]=offer.kind=="jewel" and A.ScoreItem(b,c,live,i) or A.ScoreSpell(b,c,live,i);
  end
  if offer.kind=="jewel" then
    local top=0; for _,r in ipairs(list) do top=math.max(top,r.score); end
    local comparable=top>0; local candidates=0;
    for _,r in ipairs(list) do if r.score==top then candidates=candidates+1; if r.damageGain==nil then comparable=false; end end end
    if comparable and candidates>1 then
      for _,r in ipairs(list) do if r.score==top then
        r.score=top+r.damageGain*100;
        r.reason=A.T("Ожидаемый прирост урона по бонусу")..": +"..string.format("%.1f",r.damageGain*100).."%";
      end end
    end
  end
  table.sort(list,function(x,y) if x.score~=y.score then return x.score>y.score; end; return x.index<y.index; end);
  return list;
end
-- Only explicit, fully verified goals permit retiring an already owned spell.
function A.BanishCandidate(b,offer,live)
  if offer.kind~="spell" or (tonumber(offer.bn) or 0)<=0 then return; end
  local best,lowest;
  for i,card in ipairs(offer.cards or {}) do
    local current=live.spells[card.key];
    local p,priority=A.MatchSpell(b,card.key,live);
    local button=_G["AZSCard"..i.."Banish"];
    if p and current and (tonumber(current.rank) or 0)>0 and tonumber(card.new)~=1 and button and button:IsShown() and not button.off then
      local status=A.GoalStatus(p,A.SpellStats(card.key,live));
      local hasStats,complete=false,true;
      for _,value in pairs(status) do hasStats=true; if value~="met" then complete=false; end end
      if not hasStats then complete=(tonumber(p.rank) or 0)>0 and tonumber(current.rank)>=tonumber(p.rank); end
      if complete and (not lowest or priority>lowest) then best=i; lowest=priority; end
    end
  end
  return best;
end
function A.NextAction(b,offer,live)
  local list=A.Recommend(b,offer,live);
  if not b or #list==0 then return nil,list; end
  if list[1].score>0 then
    local indices={[list[1].index]=true}; local anyIndices={};
    for _,candidate in ipairs(list) do
      if candidate.any and candidate.score>0 then indices[candidate.index]=true; anyIndices[candidate.index]=true; end
      if offer.kind=="jewel" and math.abs(candidate.score-list[1].score)<0.000001 then indices[candidate.index]=true; end
    end
    return {kind="card",index=list[1].index,indices=indices,anyIndices=anyIndices,reason=list[1].reason},list;
  end
  local banish=A.BanishCandidate(b,offer,live);
  if banish then return {kind="banish",index=banish,reason=A.T("Цели умения выполнены — можно изгнать")},list; end
  local reroll=_G.AZSCardsReroll;
  local cost=tonumber(offer.rc); local gold=tonumber(AZS_RUN and AZS_RUN.gold) or 0;
  local canPay=(tonumber(offer.rr) or 0)>0 or (cost~=nil and cost>=0 and gold>=cost);
  if reroll and reroll:IsShown() and not reroll.off and canPay then return {kind="reroll",reason=A.T("Нет подходящих карточек — переброс доступен")},list; end
  local skip=_G.AZSCardsSkip;
  if skip and skip:IsShown() and not skip.off and (offer.kind=="spell" or offer.kind=="jewel") then return {kind="skip",reason=A.T("Нет подходящих карточек — пропусти выбор")},list; end
  return nil,list;
end
function A.Capture()
  local live=A.Snapshot(); if not live.inRun then return nil,"Сначала начни забег."; end
  local b=A.NewBuild(A.Class()); b.name=A.ClassName(b.class).." · "..A.T("Текущий забег"); b.spells={};
  for _,s in ipairs(AZS_SPELLS or {}) do
    if A.byKey[b.class..":"..s.key] and #b.spells<6 and (tonumber(s.rank) or 0)>0 then b.spells[#b.spells+1]={key=s.key,rank=tonumber(s.rank)}; end
  end
  for _,g in ipairs(live.gear) do local row=A.ResolveItem(g); if row and not A.HasItem(b,row.key) then A.Toggle(b,row); end end
  return b;
end

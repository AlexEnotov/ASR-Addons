ASRStats={VERSION="0.1.14"}; local A=ASRStats;
-- Factor fields are the game's character-sheet protocol, not a cached item database.
-- Fallback fields in AZSSTATS are already percentages; never multiply them again.
A.sections={
 {"Атака","Offense",{1,0.55,0.35}, {
 {"Крит","Crit","crit","crit","pct",0,"Шанс критического удара.","Critical strike chance."},
 {"Крит. урон","Crit dmg","cm","critd","bonus",1,"Бонус к критическому урону сверх базовых 100%, как в окне характеристик игры.","Critical damage bonus above the base 100%, matching the game character sheet."},
 {"Урон","Damage","dmg","dmg","bonus",1,"Бонус к урону умений.","Bonus spell damage."},
 {"КД","Cooldown","cd","cdr","cdr",1,"На сколько сокращена перезарядка умений.","Reduction to spell cooldowns."},
 {"Повтор","Echo","echo","echo","pct",0,"Шанс повторного применения умения.","Chance to repeat a spell."}}},
 {"Защита","Defense",{0.4,0.7,1}, {
 {"Здоровье","Health","hp",nil,"flat",0,"Максимальное здоровье.","Maximum health."},
 {"Щит","Shield","shield",nil,"shield",0,"Сколько урона сейчас может поглотить щит.","Damage your shield can still absorb."},
 {"Реген/с","Regen /s","reg","regen","decimal",0,"Восстановление здоровья в секунду.","Health restored per second."},
 {"Вампиризм","Lifesteal","lch","ls","pct",0,"Лечение от нанесённого урона.","Healing from damage dealt."},
 {"Сниж. урона","Dmg reduction","arm","red","pct",0,"Доля предотвращаемого входящего урона.","Incoming damage reduction."},
 {"ОЗ за убийство","Kill heal","heal","kh","decimal",0,"Лечение за убийство.","Healing per kill."},
 {"Отражение","Thorns","thn",nil,"pct",0,"Возвращаемая атакующему доля урона.","Damage reflected to attackers."},
 {"Воскрешения","Lives","liv",nil,"flat",0,"Оставшиеся воскрешения.","Remaining revivals."}}},
 {"Радиус","Reach",{0.75,0.55,1}, {
 {"Область","Area","area","area","bonus",1,"Увеличение области действия умений.","Larger spell areas and ranges."},
 {"Доп. цели","Extra targets","cnt","tgt","flat",0,"Дополнительные цели умений.","Additional spell targets."},
 {"Подбор","Pickup",false,"pick","bonus",0,"Бонус к радиусу подбора опыта и золота, как в окне игры.","Bonus pickup range, matching the game character sheet."}}},
 {"Полезность","Utility",{0.4,0.9,0.6}, {
 {"Скорость","Speed","spd","spd","bonus",1,"Бонус к скорости передвижения.","Bonus movement speed."},
 {"Опыт","Experience","xp","xp","bonus",1,"Бонус к получаемому опыту.","Bonus experience gained."},
 {"Золото","Gold","gold","gold","bonus",1,"Бонус к получаемому золоту.","Bonus gold gained."},
 {"Удача","Luck","luck","luck","pct",0,"Повышение шанса редких карточек.","Better odds of rare cards."},
 {"Сила эффектов","Buff power","bp","buff","pct",0,"Усиление временных положительных эффектов.","Stronger temporary buffs."}}},
 {"Период. урон","Damage over time",{0.35,0.85,0.85}, {
 {"Стаки","DoT stacks","dots",nil,"flat",0,"Число одновременно действующих копий периодического эффекта.","Simultaneous stacks of a periodic effect."},
 {"Частота тиков","DoT haste","doth","dot","pct",0,"Ускорение периодического урона.","Faster periodic damage ticks."}}},
 {"Бонус урона","Bonus damage",{1,0.8,0.4}, {
 {"Элитам/боссам","Vs elites","big",nil,"pct",0},
 {"Добивание","Execute","exe",nil,"pct",0},
 {"Под контролем","Vs controlled","cc",nil,"pct",0},
 {"Под DoT","Vs afflicted","dotd",nil,"pct",0},
 {"Урон под щитом","Shield damage","shd",nil,"pctbonus",0,"Бонус к наносимому урону, пока есть поглощающий щит. Это не прочность щита.","Bonus damage dealt while an absorb shield is active. This is not the shield amount."},
 {"Ближний бой","Melee","auto",nil,"pct",0},
 {"Урон питомцев","Pet damage","pet",nil,"pct",0}}},
};
function A.Number(value)
 local n=tonumber(value); if n and n==n and math.abs(n)<1e12 then return n; end
end
function A.Value(row,raw,fallback,run)
 if row[5]=="shield" then return A.Number(run and run.sh); end
 -- Reborn's native character sheet is authoritative when the field exists.
 -- AZS factors may have different precision or semantics (notably pickup).
 if row[4] then local native=A.Number(fallback and fallback[row[4]]); if native~=nil then return native; end end
 local v=A.Number(raw and raw[row[3]]);
 if v~=nil then
  if row[5]=="bonus" then return (v-1)*100; elseif row[5]=="cdr" then return (1-v)*100; elseif row[5]=="pct" or row[5]=="pctbonus" then return v*100; end
  return v;
 end
 if row[4] then return A.Number(fallback and fallback[row[4]]); end
end
function A.Format(row,value,english)
 if value==nil then return "—"; end
 if math.abs(value)<0.00001 then value=0; end
 if row[5]=="flat" or row[5]=="shield" then return string.format("%.0f",value); end
 if row[5]=="decimal" then return string.format("%.1f",value); end
 if row[5]=="yards" then return string.format("%.1f",value)..(english and " yd" or " м"); end
 local result=string.format("%.1f",value); result=string.gsub(result,"%.0$","");
 if row[5]=="bonus" or row[5]=="cdr" or row[5]=="pctbonus" then if value>0 then result="+"..result; end end
 return result.."%";
end

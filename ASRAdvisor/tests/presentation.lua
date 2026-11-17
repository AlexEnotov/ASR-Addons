local A=ASAdvisor; local n=0; local function check(ok,label) assert(ok,label); n=n+1; end
local measureFont=CreateFrame("Frame",nil,UIParent):CreateFontString(nil); measureFont:SetFont("Fonts\\FRIZQT__.TTF",11,"");
local function measure(value) measureFont:SetText(value); return measureFont:GetStringWidth(); end
local wrapped=A.WrapTooltipText("Создаёт область периодического урона радиусом 8 м на 8 сек. Каждый противник получает 48 ед. урона.",290,measure);
local safe=true; for i,line in ipairs(wrapped) do if measure(line)>290 or string.match(line,"^м[%s%.]") or string.match(line,"^сек%.") or string.match(line,"^ед%.") then safe=false; end end
check(safe and string.find(table.concat(wrapped,"\n"),"8 м",1,true) and string.find(table.concat(wrapped,"\n"),"48 ед.",1,true),"pixel-based wrapping keeps numbers and units together and fits the available width");
local long=A.WrapTooltipText(string.rep("Ж",100),90,measure); safe=true;
for _,line in ipairs(long) do if measure(line)>90 or not utf8.len(line) then safe=false; end end
check(safe and #long>1,"an overlong word can wrap without breaking UTF-8 characters");
local oldLanguage=ASAdvisorDB.options.language; A.SetLanguage("ru");
local cons=A.byKey["PALADIN:consecration"]; local exorcism=A.byKey["PALADIN:exorcism"]; local shock=A.byKey["PALADIN:holy_shock"];
check(ASAdvisorMechanics.spells.consecration.school=="holy","spell school comes from game metadata");
check(string.find(A.SpellTags(exorcism),"Таргетное",1,true) and not string.find(A.SpellTags(exorcism),"%d"),"targeted tags do not duplicate target counts from the description");
check(string.find(A.SpellTags(shock),"Таргетное",1,true) and not string.find(A.SpellTags(shock),"%d"),"projectile tags retain classification without duplicating numeric counts");
check(string.find(A.SpellTags(cons),"Массовое",1,true) and string.find(A.SpellTags(cons),"Область на земле",1,true),"ground damage is classified as AOE");
check(string.find(A.SpellTags(A.byKey["MAGE:cone_of_cold"]),"Конус",1,true),"cone shape is explicit");
check(string.find(A.SpellTags(A.byKey["PALADIN:holy_light"]),"Исцеление",1,true),"healing is identified without guessing from its icon");
check(string.find(A.SpellTags(A.byKey["PALADIN:sacred_shield"]),"Щит",1,true),"shield role comes from spell shape");
local description=A.SpellDescription(exorcism,true);
check(string.find(description,"Поражает противника в радиусе 25 м",1,true) and string.find(description,"135 ед. урона от светлой магии",1,true) and string.find(description,"каждые 3.5 сек.",1,true),"base description is a complete sentence with targeting, range, school damage and cooldown before acquisition");
check(not string.find(description,"Точное описание с эффектами",1,true),"base description does not claim that description is unavailable");
local hammer=A.byKey["PALADIN:hammer_of_the_righteous"];
check(string.find(A.SpellDescription(hammer,true),"до 3 противников в радиусе 6 м",1,true) and string.find(A.BaseFacts(hammer),"Дальность 6 м",1,true),"Hammer of the Righteous includes its six-unit target range in full and compact base descriptions");
local ground=A.SpellDescription(A.byKey["HUNTER:frost_trap"],true);
check(string.find(ground,"радиусом 10 м",1,true) and string.find(ground,"на расстоянии до 6 м",1,true),"ground effect radius remains distinct from its placement range");
local line="Урон от светлой магии: 135 · Урон горением: 50"; local painted=A.ColorTooltipLine(line,exorcism);
check(A.Plain(painted)==line and string.find(painted,"|cffffe58a",1,true) and string.find(painted,"|cffff9360",1,true),"school and burning colors preserve all displayed text");
check(string.find(A.ColorTooltipLine("Текущие значения",cons),"|cff8cd123",1,true) and string.find(A.ColorTooltipLine("Базовые параметры · без улучшений",cons),"|cffd5bc83",1,true),"base and current sections have distinct heading colors");
check(A.ClassHex(cons)=="f58cba","Paladin title uses Paladin class color");
local oldTip=AZS_SPELLTIPS.exorcism; AZS_SPELLTIPS.exorcism="Supports nearby allies in co-op.";
check(string.find(A.SpellTags(exorcism),"Кооператив",1,true) and string.find(A.SpellTags(exorcism),"Поддержка союзников",1,true),"mode and support tags require explicit game wording");
AZS_SPELLTIPS.exorcism=nil; check(not string.find(A.SpellTags(exorcism),"Кооператив",1,true),"absence of mode data is not presented as a co-op restriction"); AZS_SPELLTIPS.exorcism=oldTip;
local ui=ASAdvisorPlanner; if ui:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); A.ToggleUI(); local cell;
ui.search:SetText(""); ui.tabs.spell.scripts.OnClick(ui.tabs.spell);
for _,c in ipairs(ui.catalogRows) do if c:IsShown() and c.row and c.row.group=="spell" and not c.row.addAny and not c.row.any then cell=c; break end end
check(cell~=nil,"a spell tooltip is reachable in the planner"); cell.scripts.OnEnter(cell);
check(ui.tip.title.textColor[2]>0.7 and ui.tip.title.textColor[1]>0.5,"planner tooltip title uses the Hunter class color");
check(string.find(ui.tip.body:GetText(),"|cff",1,true),"color markup survives tooltip line wrapping and rendering");
for _,part in ipairs(ui.tip.lines) do check(not string.find(part,"|cff",1,true),"wrapping measures plain text without counting color codes"); end
cell.scripts.OnLeave(cell); A.ToggleUI();
A.SetLanguage("en");
check(string.find(A.SpellTags(A.byKey["PALADIN:consecration"]),"AOE",1,true),"English tags use AOE");
check(string.find(A.SpellDescription(A.byKey["PALADIN:exorcism"],true),"135 holy damage",1,true),"English base description uses the spell school");
A.SetLanguage(oldLanguage);
print("Passed "..n.." tooltip colors, spell roles and base description checks");

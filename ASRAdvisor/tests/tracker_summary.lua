local A=ASAdvisor; local count=0; local function check(ok,name) assert(ok,name); count=count+1; end
check(A.TrackerNumber(15052)=="15.1K" and A.TrackerNumber(12)=="12","small damage remains readable while thousands are shortened");
check(A.TrackerNumber(15052000)=="15.1M" and A.TrackerNumber(15052000000)=="15.1B" and A.TrackerNumber(15052000000000)=="15.1T","million billion and trillion damage use compact suffixes");
check(A.TrackerNumber(999960)=="1M" and #A.TrackerNumber(1e18)<12,"rounding promotes units and extreme damage stays bounded");
local language=ASAdvisorDB.options.language; local tips=AZS_SPELLTIPS; A.SetLanguage("ru");
AZS_SPELLTIPS={consecration="Каждый противник в радиусе 80 м получает 15052000000000 ед. урона в течение 319 сек."};
local live={inRun=true,spells={consecration={rank=50,cdmax=1.6}},gear={}};
local spells=A.TrackerEntries({class="PALADIN",spells={{key="consecration",rank=0}},items={}},live);
check(spells[1].detail:find("Длит. 319с",1,true) and not spells[1].detail:find("Длительность",1,true),"tracker uses short duration wording with attached seconds");
check(spells[1].detail:find("15.1T",1,true) and spells[1].detail:find("80м",1,true),"trillion damage and radius units remain compact");
check(A.SpellStats("consecration",live).damage==15052000000000,"formatting does not round the underlying goal comparison value");
local row=A.aliasItem("legend_consecration"); local gear={slot="amulet",name="Амулет инферно: Освящение",text="Особый эффект · Бонус 2 118.6% · Бонус 3 237.2%"};
check(A.ShortItem(gear,row)=="Особый бонус","class amulet summary contains only its special bonus label");
local b={class="PALADIN",spells={},items={row.key},itemRules={}}; local _,items=A.TrackerEntries(b,{inRun=true,spells={},gear={gear}});
check(items[1].detail=="Особый бонус","planned class amulet uses the short label in tracker entries");
check(A.ShortItem({text="Luck 30% · Gold 25%"},A.aliasItem("south_seas_kelp")):find("30%%"),"ordinary jewelry retains its numeric bonuses");
A.SetLanguage("en"); check(A.ShortItem(gear,row)=="Special bonus" and A.T("Длит.")=="Dur.","compact labels support English"); A.SetLanguage(language); AZS_SPELLTIPS=tips;
print("Passed "..count.." compact tracker summary checks");

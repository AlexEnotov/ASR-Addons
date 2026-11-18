local A=ASAdvisor; local count=0;
local function check(ok,label) assert(ok,label); count=count+1; end
local legends=0;
local classes={};
for _,row in ipairs(A.catalog) do if row.legend then
 local m=row.legend;
 for token in pairs(AZS_GEN.spells) do if A.AvailableTo(row,token) then
  local spell=A.byKey[token..":"..m.spell];
  classes[token]=true;
  check(A.ResolveItem(m.nativeKey,token)==row,"official item ID resolves to the planner row");
  local ru=ASAdvisorNamesRU[spell.english] or spell.english;
  for _,name in ipairs({m.name..": "..spell.english,m.ru..": "..ru,m.ru.." · "..ru}) do
   local gear={slot="amulet",name=name,text=""};
   check(A.ResolveItem(gear,token)==row,"qualified class amulet name resolves: "..name);
   local b={class=token,spells={},items={row.key},itemRules={}};
   local live={inRun=true,spells={},gear={gear}};
   check(A.WornForKey(b,row.key,live)==gear,"owned class amulet is recognized without depending on the viewed character class");
   local _,items=A.TrackerEntries(b,live);
   check(#items==1 and items[1].owned and items[1].planned and items[1].row==row,"class amulet appears once as owned and planned");
   check(A.ScoreItem(b,{name=name,mode="grow"},live,1).score>0,"class amulet upgrade matches its planned item");
  end
  legends=legends+1;
 end end
end end
local classCount=0; for _ in pairs(classes) do classCount=classCount+1; end
check(legends==#ASAdvisorResolvedLegends and classCount==12,"all official amulets are available across all 12 classes");
for _,spell in ipairs({"lightning_shield","healing_wave","call_of_flame","demonic_knowledge"}) do
  check(not A.aliasItem("legend_"..spell),"no amulet is inferred for "..spell);
end
local row=A.aliasItem("legend_consecration");
local gear={slot="amulet",name="Амулет инферно: Освящение",text=""};
local b={class="PALADIN",spells={},items={row.key,"south_seas_kelp","enlightenment"},itemRules={}};
local live={inRun=true,spells={},gear={gear}};
check(A.ResolveItem(gear,"PALADIN")==row,"Inferno/Consecration screenshot resolves exactly");
check(A.ResolveItem(gear,"MAGE")==nil,"a qualified class amulet is not accepted for a different class");
local score=A.ScoreItem(b,{name="Choker of Enlightenment",mode="new"},live,1);
check(score.score==0 and score.reason==A.T("Амулет ниже надетого по приоритету"),"existing priority rule blocks lower amulets after Inferno is recognized");
b.items={"south_seas_kelp",row.key}; live.gear={{slot="amulet",name="Pristine Enchanted South Seas Kelp",text=""}};
score=A.ScoreItem(b,{name="Амулет инферно: Освящение",mode="new"},live,1);
check(score.score==0 and score.reason==A.T("Амулет ниже надетого по приоритету"),"existing priority rule also blocks a lower-priority class amulet");
b.items={row.key,"south_seas_kelp"};
check(A.ScoreItem(b,{name="Амулет инферно: Освящение",mode="new"},live,1).score>0,"higher-priority class amulet remains recommended");
row=A.aliasItem("legend_mind_sear");
check(row and A.AvailableTo(row,"PRIEST") and not A.AvailableTo(row,"PALADIN"),"confirmed Mind Sear amulet is available only to priest builds");
gear={slot="amulet",name="Амулет инферно: Иссушение разума",text="Live server bonus description"};
b={class="PRIEST",name="Legacy priest build",spells={},items={"legend_mind_sear","enlightenment"},itemRules={}};
live={inRun=true,spells={},gear={gear}};
check(A.ResolveItem(gear,"PRIEST")==row and A.ResolveItem("Amulet of the Inferno: Mind Sear","PRIEST")==row,"Russian screenshot and English Mind Sear names identify the same item");
local _,items=A.TrackerEntries(b,live);
check(#items==1 and items[1].owned and items[1].planned and items[1].row==row,"Mind Sear is planned once and hides the lower-priority backup");
check(A.ScoreItem(b,{name="Choker of Enlightenment",mode="new"},live,1).score==0,"confirmed Mind Sear amulet participates in normal amulet priority rules");
local class=A.Class; A.Class=function() return "PRIEST"; end;
local desc,source=A.ItemDescription(row,live); A.Class=class;
check(source=="current" and desc:find(gear.text,1,true),"actual acquired bonus text still takes precedence");
local base=A.BaseItemText(row);
check(base:find(A.T("Длительность")..": 100%",1,true) and base:find(A.T("Взрыв при убийстве"),1,true),"Mind Sear shows resolved effects and percentage duration");
local decoded=A.Decode(A.Export(b));
check(decoded and decoded.items[1]=="legend_mind_sear","the old Mind Sear key survives export and import");

for key,slot in pairs({
  elder_council_signet="ring", darkmoon_volcano="trinket", theralions_mirror="trinket",
  bell_of_enraging_resonance="trinket", heart_of_ignacious="trinket", fury_of_angerforge="trinket",
  dragonwrath="amulet", fangs_of_the_father="amulet",
}) do
  check(A.aliasItem(key) and A.aliasItem(key).group==slot,"new jewelry is selectable in its slot: "..key);
end
local ring=A.aliasItem("elder_council_signet");
check(A.BaseItemText(ring):find("0.8%",1,true) and #A.BaseItemMetrics(ring)==0,"temporary ring bonus is shown in the tooltip");
local fangs=A.aliasItem("fangs_of_the_father");
check(A.AvailableTo(fangs,"ROGUE") and not A.AvailableTo(fangs,"MAGE"),"the new amulet respects class restrictions");
local tempest=A.aliasItem("legend_stormstrike");
local tempestDesc=A.BaseItemText(tempest);
check(tempestDesc:find(A.T("Параметры бонуса доступны в описании полученного амулета."),1,true)
  and not tempestDesc:find(A.T("Базовые значения · ранг 1"),1,true),"flag-only effect does not claim to have rank-one values");
local saved=ASAdvisorDB.observed[tempest.key];
ASAdvisorDB.observed[tempest.key]="Recorded native effect";
local tooltip,origin=A.ItemDescription(tempest,{gear={}});
check(origin=="observed" and tooltip:find("Recorded native effect",1,true),"flag-only effect can show previously observed game text");
ASAdvisorDB.observed[tempest.key]=saved;
print("Passed "..count.." class amulet identification and existing priority checks");

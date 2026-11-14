local A=ASAdvisor; local count=0;
local function check(ok,label) assert(ok,label); count=count+1; end
local legends=0;
for _,row in ipairs(A.catalog) do if row.legend then
 local m=row.legend;
 for token in pairs(AZS_GEN.spells) do if A.AvailableTo(row,token) then
  local spell=A.byKey[token..":"..m.spell];
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
check(legends>50,"the whole class amulet catalogue was exercised");
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
print("Passed "..count.." class amulet identification and existing priority checks");

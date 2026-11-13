local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local b={class="HUNTER",spells={},items={"accuria","chosen","hoj","south_seas_kelp","enlightenment"},itemRules={}};
local live={inRun=true,spells={},gear={
  {slot="ring",name="Кольцо Аккурии",text="+191% к урону"},
  {slot="trinket",name="Рука Правосудия",text="Шанс двойного заклинания 26.8%"},
  {slot="amulet",name="Нетронутая зачарованная ламинария Южных морей",text="+115.7% к удаче · +40% к золоту"},
}};
local ring={name="Кольцо Аккурии",mode="grow",rarity=2,detail="Урон=191%=212.9%=+"};
local justice={name="Рука Правосудия",mode="grow",rarity=4,detail="Шанс двойного заклинания=26.8%=43.3%=+"};
local amulet={name="Ожерелье просветления",mode="new",rarity=3,detail="Золото=40%=0%=-^Удача=115.7%=57.7%=-"};
local offer={kind="jewel",rr=3,cards={ring,justice,amulet}};
local action,list=A.NextAction(b,offer,live);
check(action and action.kind=="card" and action.index==2 and not action.indices[1],"user screenshot: Hand of Justice beats Accuria despite second trinket position");
local r=A.ScoreItem(b,ring,live,1); local h=A.ScoreItem(b,justice,live,2);
check(math.abs(r.damageGain-((3.129/2.91)-1))<0.000001,"ring gain is relative to existing damage bonus");
check(math.abs(h.damageGain-((1.433/1.268)-1))<0.000001,"double-cast gain is relative to existing expected casts");
check(A.ScoreItem(b,amulet,live,3).score==0,"lower-priority amulet cannot replace preferred equipped amulet");
offer.cards={justice,ring,amulet}; action=A.NextAction(b,offer,live);
check(action.index==1,"card order does not reverse the benefit comparison");
ring.detail="Урон=191%=300%=+"; offer.cards={ring,justice}; action=A.NextAction(b,offer,live);
check(action.index==1 and not action.indices[2],"ring can win when its actual relative damage gain is larger");
ring.detail="Урон=191%=212.9%=+";
b.itemRules.hoj={group="trinket",value=25}; action=A.NextAction(b,offer,live);
check(action.index==1 and not action.indices[2],"fulfilled explicit target still excludes an otherwise strong upgrade");
b.itemRules.hoj=nil; justice.detail="Шанс двойного заклинания=26,8%=43,3%=+"; action=A.NextAction(b,offer,live);
check(action.index==2,"localized decimal commas are supported");
justice.detail=""; action=A.NextAction(b,offer,live);
check(action.indices[1] and action.indices[2],"unknown gain is presented as an alternative rather than given a fake group priority");
check(A.ItemDamageGain(A.aliasItem("hoj"),{mode="grow",detail="Шанс=26.8%=43.3%=+^Урон=0%=10%=+"},live.gear[2])==nil,"compound bonuses are not reduced to one arbitrary percentage");
check(A.ItemDamageGain(A.aliasItem("hoj"),{mode="grow",detail="Шанс=26.8%=43.3%=+"},nil)==nil,"unowned item does not reuse a relative upgrade formula");
check(A.ItemDamageGain(A.aliasItem("quick_strike"),{mode="grow",detail="КД=10%=20%=+"},live.gear[1])==nil,"cooldown percentages are not equated to direct damage multipliers");
print("Passed "..count.." jewelry priority regression checks");

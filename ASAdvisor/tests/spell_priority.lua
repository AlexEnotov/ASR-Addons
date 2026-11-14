local A=ASAdvisor; local count=0;
local function check(ok,label) assert(ok,label); count=count+1; end
local oldClass,oldTips=UnitClass,AZS_SPELLTIPS; UnitClass=function() return "Paladin","PALADIN"; end; AZS_SPELLTIPS={};
local b={class="PALADIN",items={},itemRules={},spells={
 {key="consecration",rank=0,cd=0,damage=0,radius=0,duration=0},
 {key="exorcism",rank=0,damage=999999999},
 {key="hammer_of_wrath",rank=0,damage=999999999},
 {key="holy_shock",rank=0,damage=999999999},
 {key="holy_wrath",rank=0,damage=999999999},
 {key="judgement",rank=0,damage=999999999},
}};
local live={inRun=true,gear={},spells={}};
for _,p in ipairs(b.spells) do live.spells[p.key]={key=p.key,rank=3,cdmax=4}; AZS_SPELLTIPS[p.key]="Hits for 100 holy damage."; end
local offer={kind="spell",cards={{key="exorcism",lines="d25",rarity=4},{key="consecration",lines="d25",rarity=0},{key="holy_shock",lines="d25",rarity=4}}};
local action=A.NextAction(b,offer,live);
check(action and action.index==2,"first-priority uncapped Consecration beats lower-priority spells with explicit unfinished goals");
local first=A.ScoreSpell(b,offer.cards[2],live,2).score;
b.spells[1].damage=999999999;
check(A.ScoreSpell(b,offer.cards[2],live,2).score==first,"adding an unreachable threshold does not increase a spell's priority");
b.spells[1].damage=0;
offer.cards[2].lines="a18"; action=A.NextAction(b,offer,live);
check(action and action.index==2,"uncapped radius cards use the same build order as damage cards");
offer.cards[2].lines="u15"; action=A.NextAction(b,offer,live);
check(action and action.index==2,"uncapped duration cards keep first priority");
offer.cards[2].lines="c7"; action=A.NextAction(b,offer,live);
check(action and action.index==2,"uncapped cooldown cards keep first priority");
b.spells[1],b.spells[2]=b.spells[2],b.spells[1]; action=A.NextAction(b,offer,live);
check(action and action.index==1,"moving another spell earlier changes the recommendation");
b.spells[1],b.spells[2]=b.spells[2],b.spells[1];
b.spells[1].cd=5; action=A.NextAction(b,offer,live);
check(action and action.index==1,"completed explicit goals still retire the higher-priority spell");
b.spells[1].cd=0; b.spells[1].rank=3;
check(A.ScoreSpell(b,offer.cards[2],live,2).score==0,"completed explicit rank still stops upgrades when there are no stat goals");
b.spells[1].rank=0;
check(A.ScoreSpell(b,offer.cards[2],live,2).score>0,"zero rank means uncapped rather than completed");
live.spells.exorcism=nil; offer.cards[1].new=1; action=A.NextAction(b,offer,live);
check(action and action.index==1,"acquiring a missing planned spell retains its existing preference over upgrades");
b={class="PALADIN",items={},itemRules={},spells={
 {key="consecration",rank=0,cd=0,damage=0,radius=0,duration=0},
 {key="exorcism",rank=0},{key="hammer_of_wrath",rank=0},{key="holy_wrath",rank=0},
 {key="divine_storm",rank=0,cd=3,damage=0,radius=0},
}};
live={inRun=true,gear={},spells={consecration={rank=5,cdmax=5.5},holy_wrath={rank=1},divine_storm={rank=6,cdmax=3.1}}};
offer={kind="spell",cards={{key="consecration",lines="a18",rarity=1},{key="holy_wrath",lines="a18",rarity=1},{key="divine_storm",lines="a25",rarity=2}}};
action=A.NextAction(b,offer,live);
check(action and action.index==1,"exact screenshot: uncapped Consecration beats Divine Storm area card with cooldown 3.1 versus goal 3");
offer.cards[1],offer.cards[3]=offer.cards[3],offer.cards[1]; action=A.NextAction(b,offer,live);
check(action and action.index==3,"exact screenshot choice follows build priority rather than screen position");
UnitClass=oldClass; AZS_SPELLTIPS=oldTips;
print("Passed "..count.." spell priority and zero-goal checks");

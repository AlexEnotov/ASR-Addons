local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local oldClass,oldTips=UnitClass,AZS_SPELLTIPS; UnitClass=function() return "Paladin","PALADIN"; end; AZS_SPELLTIPS={};
local p={key="consecration",rank=0,cd=1,radius=10,damage=0};
local b={class="PALADIN",spells={p},items={},itemRules={}};
local live={inRun=true,spells={consecration={rank=3,cdmax=2}},gear={},stats={}};
local function score(lines) return A.ScoreSpell(b,{key=p.key,lines=lines},live,1); end
for _,rank in ipairs({0,1}) do
 p.rank=rank;
 for _,cd in ipairs({2,1}) do for _,radius in ipairs({5,10}) do
  live.spells.consecration.cdmax=cd; AZS_SPELLTIPS.consecration="Each enemy within "..radius.." yd takes 100 holy damage.";
  check((score("c10").score>0)==(cd>1),"CD-only card follows its own goal");
  check((score("a18").score>0)==(radius<10),"radius-only card follows its own goal");
  check((score("d20").score>0)==(rank==0),"zero damage goal is unlimited only in rank-zero mode");
  check((score("c10a18").score>0)==(cd>1 or radius<10),"mixed targeted card remains useful until both goals are met");
  check((score("c10d20").score>0)==(rank==0 or cd>1),"mixed capped/uncapped card follows rank mode");
  check((score("a18k10").score>0)==(rank==0 or radius<10),"other recognized bonus is allowed only in rank-zero mode");
 end end
end
p.cd=0; p.radius=0; p.rank=1; check(score("d20").score==0,"rank one without goals stops after acquisition");
p.rank=0; check(score("d20").score>0 and score("c10").score>0,"all zero goals allow every upgrade");
p.rank=5; check(score("d20").score>0,"positive rank without goals accepts upgrades before rank reached");
p.rank=1; p.cd=1; live.spells.consecration=nil;
check(score("").score>0,"selective spell is acquired before testing its upgrade goals");
live.spells.consecration={rank=1,cdmax=2}; check(score("d20").score==0 and score("c10").score>0,"rank one with CD goal selects only CD after acquiring spell");
p.rank=0; p.radius=10; AZS_SPELLTIPS.consecration="Unknown"; check(score("a18").kind=="unknown" and score("a18d20").score>0,"unknown radius does not fabricate completion or block independent uncapped damage");
p.rank=0; p.cd=3; p.radius=0; live.spells.consecration={rank=4,cdmax=2.7};
p.banish=true; check(score("a12").kind=="banish","manual ready-to-ban spell cannot also receive an upgrade recommendation");
live.spells.consecration.cdmax=4; check(score("a12").score>0,"manual ban does not stop useful upgrades before its conditions are reached");
p.banish=nil;
-- Exact screenshot: all three lowest-priority slots are auto; only Storm remains unlimited.
local stormBuild={class="PALADIN",spells={{key="consecration",rank=0},{key="hammer_of_justice",rank=1},{key="judgement",rank=1},{key="holy_wrath",rank=1},{key="divine_storm",rank=0,cd=3},{key="hammer_of_wrath",rank=1}},items={},itemRules={}};
local stormLive={inRun=true,spells={holy_wrath={rank=1},divine_storm={rank=4,cdmax=2.7},hammer_of_wrath={rank=1}},gear={}};
local stormOffer={kind="spell",bn=1,cards={{key="holy_wrath",lines="c10"},{key="divine_storm",lines="a12"},{key="hammer_of_wrath",lines="c7"}}};
local stormPlan=A.BanishPlan(stormBuild); check(not stormPlan.divine_storm and stormPlan.judgement,"automatic outline skips Storm and fills remaining slot from lower eligible priority");
AZSCardsFrame:Show(); local bans=A.BanishCandidates(stormBuild,stormOffer,stormLive); local action=A.NextAction(stormBuild,stormOffer,stormLive);
check(action.kind=="card" and action.index==2 and not bans[2],"screenshot Storm area upgrade is recommended without an automatic ban mark");
check(bans[1] and bans[3],"finished rank-one spells remain eligible for their independent automatic bans");
UnitClass=oldClass; AZS_SPELLTIPS=oldTips;
local ring=A.aliasItem("dragonslayer");
if not ring then for _,r in ipairs(A.catalog) do local m=A.BaseItemMetrics(r); if r.group=="ring" and m[1] and m[1].kind=="crit" then ring=r; break; end end end
assert(ring,"crit ring fixture");
b={class="HUNTER",spells={},items={ring.key},itemRules={[ring.key]={group="ring",value=80}}};
live={inRun=true,spells={},stats={crit=79},gear={{slot="ring",name=ring.english or ring.name,text="Critical strike chance 90%"}}};
local card={name=ring.english or ring.name,mode="grow",detail="Critical strike chance=90%=100%=+"};
check(A.ScoreItem(b,card,live,1).score>0,"item bonus above goal cannot replace a lower character total");
live.stats.crit=80; live.gear[1].text="Critical strike chance 16%";
check(A.ScoreItem(b,card,live,1).kind=="met","other equipment can satisfy eighty percent character crit goal");
live.stats={}; check(A.ScoreItem(b,card,live,1).kind=="unknown","missing total never falls back to sixteen percent item bonus");
live.stats.crit=83; local metrics=A.ItemGoalMetrics(ring,live,live.gear[1]); check(metrics[1].value==83 and metrics[1].kind=="crit","editor metrics use total character crit");
check(A.ItemGoalMetrics(ring,live)[1].value==83,"character stats are available even before the planned item is worn");
local kelp=A.aliasItem("south_seas_kelp"); local worn={text="Luck 20% · Gold 30%"};
metrics=A.ItemGoalMetrics(kelp,{stats={luck=105,gold=200}},worn); check(metrics[1].value==105 and metrics[2].value==200,"multiple jewelry targets use their respective totals");
local savedStats,savedGear,savedZone,previousClass=AZS_RUNSTATS,AZS_GEAR,AZS_ZONE,UnitClass;
UnitClass=function() return "Hunter","HUNTER"; end;
AZS_RUNSTATS={crit=83}; AZS_GEAR={live.gear[1]}; AZS_ZONE={hub=0}; AZS_RUN.ph="playing"; AZSCardsFrame:Hide(); A.offer=false;
local build=A.NewBuild("HUNTER"); build.items={ring.key}; build.itemRules={[ring.key]={group="ring",value=80}};
local ui=ASAdvisorPlanner; if not ui:IsShown() then A.ToggleUI(); end;
for _,name in ipairs({"preview","settings","caps","description","code"}) do if ui[name]:IsShown() then ui[name].back.scripts.OnClick(ui[name].back); end end;
A.Redraw(); ui.itemCells.ring[1].scripts.OnClick(ui.itemCells.ring[1]);
check(ui.inline.current:GetText():find("83",1,true) and not ui.inline.current:GetText():find("16",1,true),"build inspector displays total eighty-three percent crit instead of ring sixteen percent");
AZS_RUNSTATS.crit=79; Emit("AZSSTATS",""); ASAdvisorRuntime.scripts.OnUpdate(ASAdvisorRuntime,0.3);
check(ui.inline.current:GetText():find("79",1,true),"character goal values refresh with native stat events");
AZS_GEAR={}; A.Redraw(); check(ui.inline.current:GetText():find("79",1,true),"unworn item still shows current character goal value");
AZS_RUNSTATS,AZS_GEAR,AZS_ZONE,UnitClass=savedStats,savedGear,savedZone,previousClass;
print("Passed "..count.." goal mode and total character stat checks");

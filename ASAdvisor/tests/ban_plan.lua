local A=ASAdvisor; local n=0; local function check(ok,label) assert(ok,label); n=n+1; end
local b={class="HUNTER",name="Banish plan",style="balanced",description="",items={},itemRules={},spells={}};
for i=1,6 do b.spells[i]={key=AZS_GEN.spells.HUNTER[i].key,rank=1}; end
local plan,count=A.BanishPlan(b);
check(count==3 and plan[b.spells[6].key]=="auto" and plan[b.spells[5].key] and plan[b.spells[4].key] and not plan[b.spells[1].key],"without manual choices the last three build priorities are automatic ban choices");
check(A.SetBanish(b,b.spells[1].key,true),"first manual choice is accepted"); plan=A.BanishPlan(b);
check(plan[b.spells[1].key]=="manual" and plan[b.spells[6].key]=="auto" and plan[b.spells[5].key]=="auto" and not plan[b.spells[4].key],"one manual choice reserves its slot and two lowest priorities fill the rest");
A.SetBanish(b,b.spells[2].key,true); plan=A.BanishPlan(b);
check(plan[b.spells[1].key] and plan[b.spells[2].key] and plan[b.spells[6].key] and not plan[b.spells[5].key],"two manual choices leave one automatic lowest-priority slot");
A.SetBanish(b,b.spells[3].key,true); plan=A.BanishPlan(b);
check(plan[b.spells[3].key]=="manual" and not plan[b.spells[6].key],"three manual choices disable automatic selections");
check(not A.SetBanish(b,b.spells[4].key,true) and A.BanishCount(b)==3,"fourth manual choice is refused without changing the build");
local decoded=A.Decode(A.Export(b)); check(decoded and decoded.spells[1].banish and decoded.spells[2].banish and decoded.spells[3].banish,"manual ban choices survive build sharing");
local bad=A.Copy(b); bad.spells[4].banish=true; check(A.Decode(A.Export(bad))==nil,"import rejects more than three manual choices");
bad=A.Copy(b); for _,p in ipairs(bad.spells) do p.banish=nil; end; decoded=A.Decode(A.Export(bad)); check(decoded and A.BanishCount(decoded)==0,"builds without ban fields remain compatible");
local unlimited=b.spells[6]; unlimited.rank=0; unlimited.cd=3;
local automaticOnly=A.Copy(b); for _,pick in ipairs(automaticOnly.spells) do pick.banish=nil; end;
local autoPlan=A.BanishPlan(automaticOnly); check(not autoPlan[unlimited.key] and autoPlan[automaticOnly.spells[3].key],"automatic plan skips unlimited spell and uses next lowest eligible priority");
check(not A.BanishReady(unlimited,{rank=4,cd=2.7},"auto"),"automatic ban never retires rank-zero spell with other unlimited upgrades");
check(A.BanishReady(unlimited,{rank=4,cd=2.7},"manual"),"explicit manual ban can stop an unlimited spell after configured goals");
unlimited.cd=0;
check(not A.BanishReady(unlimited,{rank=4},"auto"),"all-zero spell remains unlimited for automatic bans");
local p=b.spells[1]; local stats={rank=1,cd=4};
check(not A.BanishReady(p,{rank=0},true) and not A.BanishReady(p,{},true),"unowned spells are never ready to banish");
check(A.BanishReady(p,stats,true),"all zero thresholds require only owning the spell");
p.cd=3; check(not A.BanishReady(p,stats,true),"an unfinished cooldown blocks a ban"); stats.cd=3; check(A.BanishReady(p,stats,true),"exact cooldown boundary satisfies the ban condition");
p.damage=100; check(not A.BanishReady(p,stats,true),"unknown damage cannot satisfy a ban condition"); stats.damage=100; check(A.BanishReady(p,stats,true),"all configured stat conditions must be verified");
p.cd=0; p.damage=0; p.rank=2; check(not A.BanishReady(p,stats,true),"explicit rank is required when no stat goals are set"); stats.rank=2; check(A.BanishReady(p,stats,true),"rank boundary allows a ban");
check(not A.BanishReady(p,stats,false),"an eligible unselected spell is not marked");
local ui=ASAdvisorPlanner; if ui:IsShown() then A.ToggleUI(); end
local active=A.NewBuild("HUNTER"); active.spells=A.Copy(b.spells); A.ToggleUI();
ui.spellCells[1].scripts.OnClick(ui.spellCells[1]);
check(ui.inline.banish:IsShown() and ui.inline.banish:GetChecked(),"selected spell exposes its saved checkbox");
for i=1,3 do check(ui.spellCells[i].banBorder:IsShown(),"all three manual choices remain visibly outlined"); end
ui.spellCells[4].scripts.OnClick(ui.spellCells[4]); ui.inline.banish:SetChecked(true); ui.inline.banish.scripts.OnClick(ui.inline.banish);
check(not ui.inline.banish:GetChecked() and not active.spells[4].banish and A.BanishCount(active)==3,"the checkbox rolls back when a fourth manual ban is attempted");
ui.spellCells[1].scripts.OnClick(ui.spellCells[1]);
ui.inline.banish:SetChecked(false); ui.inline.banish.scripts.OnClick(ui.inline.banish);
check(not active.spells[1].banish and A.BanishCount(active)==2 and ui.spellCells[5].banBorder:IsShown(),"unchecking a manual choice immediately restores the lowest-priority automatic outline");
A.ToggleUI();
local live={inRun=true,spells={},gear={}}; for _,pick in ipairs(active.spells) do live.spells[pick.key]={rank=5,cdmax=1}; end
active.spells[1].rank=0;
active.spells[6].rank=5;
local offer={kind="spell",bn=3,cards={{key=active.spells[1].key,lines="d25"},{key=active.spells[6].key,lines="d25"}}};
AZSCardsFrame:Show(); local candidates=A.BanishCandidates(active,offer,live); local action=A.NextAction(active,offer,live);
check(candidates[2] and action.kind=="card" and action.index==1,"ban hints do not replace the normal higher-priority upgrade recommendation");
AZS_CARDS=offer; AZS_SPELLS={}; for _,pick in ipairs(active.spells) do AZS_SPELLS[#AZS_SPELLS+1]={key=pick.key,rank=5,cdmax=1}; end
AZS_RUN.ph="playing"; ASAdvisorDB.options.enabled=true; A.offer=true; A.RefreshUI();
check(ASAdvisorCardMark1:IsShown() and ASAdvisorBanishMark2:IsShown(),"ordinary choice and independent ban button are highlighted at the same time");
check(not ASAdvisorBanishMark1:IsShown(),"an unselected spell does not receive a ban indicator");
offer.bn=0; check(next(A.BanishCandidates(active,offer,live))==nil,"no ban indicators without charges");
offer.bn=3; offer.cards[2].new=1; check(not A.BanishCandidates(active,offer,live)[2],"new-spell acquisition cards never receive a ban indicator");
AZSCardsFrame:Hide();
print("Passed "..n.." explicit/automatic ban plan checks");

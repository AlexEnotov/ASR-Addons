local A=ASRLoot; local checks=0; local function check(ok,name) assert(ok,name); checks=checks+1; end
AZS_ZONE={run="r1",zone="elwynn",class="hunter"}; AZS_RUN={t=20,ph="playing"};
ASRLootRuntime.scripts.OnEvent(ASRLootRuntime,"ADDON_LOADED","ASRLoot");
check(A.ready and ASRLootDB.language=="en" and ASRLootDB.mode=="new","fresh standalone installation defaults to English and new items only");
local p=A.ParseDuplicate("Шлем следопыта уже подобрано: +20 золото.");
check(p and p.name=="Шлем следопыта" and p.gold==20,"exact user screenshot is parsed");
p=A.ParseDuplicate("|cffffffffTracker's Helm|r already collected: |cffffff00+1,200 gold.|r");
check(p and p.name=="Tracker's Helm" and p.gold==1200,"colored English duplicate with a formatted amount is parsed");
for _,text in ipairs({"Получено золото: +20 золото.","Хоггер yells: Грр... свежее мясо!","Шлем следопыта роняет +20 золото.","Шлем следопыта уже подобрано: -20 золото.","Tracker's Helm already collected: +nan gold.","Вы получили +500 золото за достижение."}) do check(not A.ParseDuplicate(text),"unrelated rewards and invalid amounts are ignored"); end
local meta=A.Resolve("Шлем следопыта"); check(meta.rarity==0 and meta.icon=="INV_Helmet_18","first-time common hunter duplicate resolves rarity and icon from verified metadata");
AZS_GEN={setLooks={{class="hunter",rarity=4,pieces={{0,35601,1,"Helmet_15"}}}}};
meta=A.Resolve("Шлем Склепного охотника"); check(meta.rarity==4 and meta.icon=="INV_Helmet_15","class set icon comes from the live game catalog");
meta=A.Resolve("Unknown future weapon"); check(meta.rarity==nil and meta.icon==nil,"unknown metadata is not assigned a false rarity or icon");
Emit("AZSLOOT","rarity=3;icon=INV_Helmet_42;name=New helm");
check(ASRLootDB.run.newCount==1 and #A.Rows()==1 and A.frame:IsShown(),"new loot event immediately appears in new-only mode");
A.Duplicate("Шлем следопыта уже подобрано: +20 золото.","CHAT_MSG_SYSTEM");
check(ASRLootDB.run.gold==20 and ASRLootDB.run.duplicateCount==1 and #A.Rows()==1,"new-only mode hides duplicates but keeps their counters");
A.SetMode("all"); check(#A.Rows()==2 and A.Rows()[1].kind=="duplicate","all mode reveals duplicate items");
check(A.frame.footer:GetText()=="Duplicate gold: 20","footer sums duplicate gold only");
A.Duplicate("Шлем следопыта уже подобрано: +20 золото.","CHAT_MSG_LOOT"); check(ASRLootDB.run.duplicateCount==1,"same message delivered through two event channels is counted once");
Advance(0.5); A.Duplicate("Шлем следопыта уже подобрано: +20 золото.","CHAT_MSG_SYSTEM");
check(ASRLootDB.run.gold==40 and A.Rows()[1].count==2 and A.Rows()[1].gold==40,"separate identical drops are aggregated without losing gold");
-- A new acquisition and a genuine repeat can occur together; never merge by timestamp.
A.NewDrop({name="Шлем следопыта",rarity=0,icon="INV_Helmet_18"});
A.Duplicate("Шлем следопыта уже подобрано: +20 золото.","CHAT_MSG_SYSTEM");
check(ASRLootDB.run.newCount==2 and ASRLootDB.run.duplicateCount==3,"new and duplicate drops of the same item stay independent");
A.Reconcile({dupgold=100}); check(ASRLootDB.run.gold==100,"end summary fills missed earlier duplicate gold");
Advance(1); A.Duplicate("Шлем следопыта уже подобрано: +20 золото.","CHAT_MSG_SYSTEM");
check(ASRLootDB.run.gold==120,"endless drops continue adding after a map-end reconciliation");
A.Reconcile({dupgold=100}); check(ASRLootDB.run.gold==120,"repeated older end summaries cannot reduce or double-count gold");
A.Reconcile({dupgold=120}); check(ASRLootDB.run.gold==120,"matching summary does not add the total twice");
local old=ASRLootDB.run; A.Init(); check(ASRLootDB.run==old and ASRLootDB.mode=="all","reload initialization preserves run entries and selected mode");
A.SetLanguage("ru"); check(A.frame.footer:GetText()=="Золото за дубликаты: 120","Russian interface follows the selected language");
AZS_ZONE.run="r2"; AZS_RUN.t=0; A.EnsureRun(); check(ASRLootDB.run.gold==0 and #ASRLootDB.run.entries==0,"new run resets session counters");
for i=1,510 do A.NewDrop({name="Piece "..i,rarity=1,icon="INV_Test"}); end
check(#ASRLootDB.run.entries==500 and ASRLootDB.run.newCount==510,"retained journal is bounded while totals remain exact");
local seen=false; local first=A.offset or 0; A.frame.scripts.OnMouseWheel(A.frame,-1000); check(A.offset>first,"long loot lists can be scrolled");
local shown=true; AZS_API_HUD={};
function AZS_IsHudShown(part) return shown; end
function AZS_SetHudShown(part,on) check(part=="loot","only native loot notifications are changed"); shown=on; AZS_API_HUD.loot=not on and "ASRLoot" or nil; end
A.SetEnabled(true); check(not shown,"enabled tracker hides native duplicate acquisition notifications");
A.SetEnabled(false); check(shown and not A.frame:IsShown(),"disabling restores native notifications");
shown=false; AZS_API_HUD.loot="OtherAddon"; A.SetEnabled(true); A.SetEnabled(false); check(not shown,"prior third-party HUD choice is preserved");
print("PASS: "..checks.." standalone loot checks");

local A=ASRCombatText; local n=0; local function check(ok,label) assert(ok,label); n=n+1; end
AZS_RUN={ph="playing"}; local external="survivor"; Cvars.CombatDamage="0";
function SurvivorUI_DamageMode() return external; end
function SurvivorUI_SetDamageMode(mode) external=mode; Cvars.CombatDamage=mode=="game" and "1" or "0"; end
ASRCombatTextRuntime.scripts.OnEvent(ASRCombatTextRuntime,"ADDON_LOADED","ASRCombatText");
check(ASRCombatTextDB.language=="en","fresh combat text defaults to English"); ASRCombatTextDB.language="ru"; A.RefreshConfig(); check(ASRCombatTextDB.language=="ru","refresh preserves an existing language choice");
check(ASRSuite==nil and ASRStats==nil and A.ready,"combat text works without suite, Stats or builder");
check(A.minimap:IsShown(),"standalone module exposes its own minimap button");
check(external=="none" and Cvars.CombatDamage=="0","module takes over only combat text while enabled");
A.SetEnabled(false); check(external=="survivor" and Cvars.CombatDamage=="0","disable restores prior third-party mode rather than forcing defaults");
A.SetEnabled(false); check(external=="survivor","repeated disable does not change the restored provider");
SurvivorUI_SetDamageMode=nil; SurvivorUI_DamageMode=nil; Cvars.CombatDamage="1";
A.SetEnabled(true); check(Cvars.CombatDamage=="0","module suppresses native numbers during its own rendering");
A.SetEnabled(false); check(Cvars.CombatDamage=="1","native numbers return when they were the previous provider");
A.SetEnabled(true); ASRCombatTaken.scripts.OnEvent(ASRCombatTaken,"PLAYER_LOGOUT"); check(Cvars.CombatDamage=="1","logout restores the original preference before the addon can be disabled");
A.SetEnabled(true); A.PollEvents(); Feed[1]={kind="damage",amount=123,spellId=1}; A.PollEvents(); check(#A.active==1 and A.active[1].amount==123,"standalone runtime reads damage directly from game API");
SlashCmdList.ASRCOMBATTEXT(""); check(A.settings:IsShown(),"standalone settings are reachable without the suite");
ASRCombatTextDB.fontSize=27; A.SetCustom("heal",true); ASRCombatTextDB.types.heal.values.fontSize=31;
check(A.EffectiveOptions("heal").fontSize==31 and A.EffectiveOptions("normal").fontSize==27,"standalone supports inherited and individual profiles");
A.SetEditing(true); check(A.editBar:IsShown(),"standalone module has its own layout editor"); A.SetEditing(false);
A.SetEnabled(true); A.ClearCombat();
local d=ASRCombatTextDB; d.mode="columns"; d.spacing=24; d.merge=0; d.rise=55; d.scrollSpeed=59; d.lifetime=0.8; d.fontSize=14;
for _,kind in ipairs(A.typeKeys) do A.SetCustom(kind,false); A.SetTypeShown(kind,true); end
local origins={}; for _,lane in ipairs(A.lanes) do origins[lane]={x=d.positions[lane].x,y=d.positions[lane].y}; end
local bounded=true; local separated=true;
for i=1,800 do
 local lane=A.lanes[(i-1)%4+1]; Advance(0.01);
 local hit=A.AddHit({kind=lane=="taken" and "taken" or lane=="heal" and "heal" or "damage",critical=lane=="critical",amount=100,spellId=1}); A.UpdateCombat(0);
 local visible={};
 for _,t in ipairs(A.active) do if not t.queued then
  visible[#visible+1]=t; local direction=t.lane=="taken" and -1 or 1; local travel=(t.point[5]-UIParent:GetHeight()/2-d.positions[t.lane].y)*direction;
  if travel<0 or travel>d.rise+0.001 then bounded=false; end
 end end
 for j=1,#visible do for k=j+1,#visible do local a,b=visible[j],visible[k]; if a.lane==b.lane and math.abs(a.point[5]-b.point[5])<24-0.001 then separated=false; end end end
end
check(bounded,"sustained bursts in all four lanes remain inside the configured area instead of drifting below it");
check(separated,"the screenshot settings enforce a 24-unit gap throughout dense sustained combat");
local unchanged=true; for lane,p in pairs(origins) do if d.positions[lane].x~=p.x or d.positions[lane].y~=p.y then unchanged=false; end end
check(unchanged,"dense combat never changes saved lane positions");
A.ClearCombat(); local first=A.AddHit({kind="damage",amount=10,spellId=1}); local waiting=A.AddHit({kind="damage",amount=20,spellId=2});
check(waiting.queued and not waiting:IsShown(),"positive spacing queues a new number rather than overlapping the origin");
Advance(0.81); A.UpdateCombat(0);
check(not waiting.queued and waiting.age==0 and waiting:IsShown(),"queued numbers receive their full lifetime only when displayed");
A.ClearCombat(); d.lifetime=2; d.rise=200; A.SetCustom("periodic",true); d.types.periodic.values.scrollSpeed=150;
first=A.AddHit({kind="damage",amount=10,spellId=1}); Advance(0.9); A.UpdateCombat(0);
waiting=A.AddHit({kind="damage",amount=20,spellId=2,periodic=true});
check(waiting.queued,"a faster custom type waits when it would catch up with a slower visible number");
A.ClearCombat(); d.spacing=1; d.icons=true; d.scrollSpeed=50;
first=A.AddHit({kind="damage",amount=10,spellId=1}); waiting=A.AddHit({kind="damage",amount=20,spellId=2});
check(waiting.queued,"one-unit spacing still waits until text positions are one unit apart");
Advance(0.02); A.UpdateCombat(0);
local gap=math.abs(first.point[5]-waiting.point[5]);
check(not waiting.queued and math.abs(gap-1)<0.001 and gap<first.visualHeight,"one-unit spacing permits overlapping icons without adding their height");
A.ClearCombat(); d.icons=false; d.fontSize=36;
first=A.AddHit({kind="damage",amount=10,spellId=1}); waiting=A.AddHit({kind="damage",amount=20,spellId=2}); Advance(0.02); A.UpdateCombat(0);
check(not waiting.queued and math.abs(math.abs(first.point[5]-waiting.point[5])-1)<0.001,"font size and icon visibility do not change the configured distance");
A.ClearCombat(); d.spacing=0; d.icons=true; for _,kind in ipairs(A.typeKeys) do A.SetCustom(kind,false); end
local savedSpellInfo=GetSpellInfo; GetSpellInfo=function() return "Unknown",nil,nil; end;
for _,event in ipairs({{kind="damage",critical=true,spellId=999},{kind="damage",periodic=true,spellId=999},{kind="heal",spellId=999},{kind="taken"},{kind="damage"}}) do
 event.amount=10; local hit=A.AddHit(event); A.UpdateCombat(0);
 check(hit.icon:IsShown() and hit.icon.texturePath=="Interface\\Icons\\INV_Misc_QuestionMark" and hit.text.point[4]==26,"unknown icons use the question mark with aligned text for every damage type");
end
GetSpellInfo=function() return "Unknown",nil,""; end;
local unknown=A.AddHit({kind="damage",amount=10,spellId=998});
check(unknown.icon.texturePath=="Interface\\Icons\\INV_Misc_QuestionMark","empty icon paths use the question mark");
d.icons=false; A.SetCustom("critical",true); d.types.critical.values.icons=true;
unknown=A.AddHit({kind="damage",amount=10,critical=true}); A.UpdateCombat(0);
check(unknown.icon:IsShown() and unknown.text.point[4]==26,"individual icon setting controls both fallback visibility and text alignment");
d.icons=true; d.types.critical.values.icons=false;
unknown=A.AddHit({kind="damage",amount=10,critical=true}); A.UpdateCombat(0);
check(not unknown.icon:IsShown() and unknown.text.point[4]==2,"disabled icons do not leave an empty indent");
GetSpellInfo=savedSpellInfo;
A.SetEnabled(false);
print("Passed "..n.." standalone combat text checks");

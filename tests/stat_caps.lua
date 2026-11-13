local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local o=ASAdvisorDB.options; local saved=A.Copy(o.statCaps); o.statCaps={cooldown=80};
local b={class="HUNTER",spells={},items={"quick_strike"},itemRules={quick_strike={group="ring",value=100}}};
local card={name="Quick Strike Ring",mode="grow",detail="Cooldown reduction=40%=45%=+"};
local live={inRun=true,spells={},stats={cooldown=80},gear={{slot="ring",name="Quick Strike Ring",text="Cooldown reduction 40%"}}};
check(A.ScoreItem(b,card,live,1).score==0,"global CDR cap overrides unreachable item goal 100");
b.itemRules.quick_strike.value=0; check(A.ScoreItem(b,card,live,1).score==0,"global CDR cap also overrides uncapped item goal zero");
o.statCaps.cooldown=100; check(A.ScoreItem(b,card,live,1).score==0,"incorrect personal CDR cap cannot exceed native 80 percent maximum");
o.statCaps.cooldown=0; check(A.ScoreItem(b,card,live,1).score==0,"clearing personal cap still respects the native CDR ceiling");
o.statCaps.cooldown=60; live.stats.cooldown=60; check(A.ScoreItem(b,card,live,1).score==0,"user may set a lower personal CDR cap");
o.statCaps.cooldown=80; live.stats.cooldown=79.9; check(A.ScoreItem(b,card,live,1).score>0,"a known value below cap remains eligible");
live.stats={}; check(A.ScoreItem(b,card,live,1).score>0,"unknown aggregate stats are not treated as a reached cap");
live.stats.cooldown=80;
local row=A.aliasItem("malice_stone"); local mixed={mode="grow",detail="Cooldown reduction=20%=25%=+^Echo=20%=30%=+"};
check(not A.ItemCapped(row,mixed,live),"useful uncapped second bonus preserves a mixed upgrade");
mixed.detail="Cooldown reduction=20%=25%=+";
check(A.ItemCapped(row,mixed,live),"a mixed item card improving only a capped stat is filtered");
o.statCaps.echo=30; live.stats.echo=30; mixed.detail="Cooldown reduction=20%=25%=+^Echo=20%=30%=+";
check(A.ItemCapped(row,mixed,live),"card is filtered when all of its improved bonuses are capped");
o.statCaps.damage=200; live.stats.damage=200;
check(A.ItemCapped(A.aliasItem("accuria"),{mode="grow",detail="Урон=100%=120%=+"},live),"damage caps use aggregate damage rather than the item's smaller bonus");
local healing=A.ItemMetrics({text="Исцеление от урона 3%"}); check(healing[1].kind=="leech","healing is not mistaken for targets or damage");
local pickup=A.ItemMetrics({text="Радиус подбора 20%"}); check(pickup[1].kind=="pickup","pickup radius is not mistaken for spell area");
local area=A.ItemMetrics({text="Область действия 20%"}); check(area[1].kind=="area","spell area retains its separate cap");
AZSCardsFrame:Show(); local action=A.NextAction(b,{kind="jewel",rr=3,cards={card}},live);
check(action and action.kind=="reroll","reroll is suggested instead of a capped-only card");
AZS_RUN.ph="playing"; AZS_RUNSTATS={cdr="80",crit="100",echo="26.8",dmg="191"};
local snapshot=A.Snapshot(); check(snapshot.stats.cooldown==80 and snapshot.stats.echo==26.8,"real AZSSTATS packet fields are read in native percentage units");
AZS_RUN.ph="ready"; check(next(A.Snapshot().stats)==nil,"previous run's stat values do not leak into ready phase"); AZS_RUN.ph="playing";
local p=ASAdvisorPlanner; AZSCardsFrame:Hide(); A.offer=false; if not p:IsShown() then A.ToggleUI(); end
if p.preview:IsShown() then click(p.preview.back); end; click(p.settingsButton); click(p.settings.caps);
check(p.caps:IsShown() and not p.settings:IsShown(),"global stat caps have a dedicated settings page");
local e=p.caps.fields.cooldown; e:SetFocus(); e:SetText("65"); e.scripts.OnEnterPressed(e);
check(o.statCaps.cooldown==65,"cap input saves on Enter");
local luck=p.caps.fields.luck; luck:SetFocus(); luck:SetText("50"); click(p.caps.back);
check(o.statCaps.luck==50,"cap input saves on leaving the caps page without Enter");
click(p.settings.caps); e=p.caps.fields.cooldown; local before=o.statCaps.cooldown; e:SetText("bad"); e.scripts.OnEnterPressed(e);
check(o.statCaps.cooldown==before,"invalid cap text cannot corrupt a saved limit"); e:SetText(tostring(before));
AZS_RUNSTATS.cdr="70"; Emit("AZSSTATS",""); ASAdvisorRuntime.scripts.OnUpdate(ASAdvisorRuntime,0.3);
check(string.find(p.caps.labels.cooldown:GetText(),"70",1,true),"caps page updates current totals on AZSSTATS events");
for _,field in pairs(p.caps.fields) do check(field.point[4]+field:GetWidth()<=p.work:GetWidth() and -field.point[5]+field:GetHeight()<p.caps.back.point[5]*-1,"cap input fits above the page footer"); end
o.statCaps=saved; AZS_RUNSTATS={};
print("Passed "..count.." global stat cap regression checks");

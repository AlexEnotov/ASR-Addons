local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local p=ASAdvisorPlanner; if p:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); b.name="Resize regression";
b.spells={{key="auto_shot",rank=1},{key="aimed_shot",rank=0,damage=500}}; b.items={"quick_strike","south_seas_kelp"};
AZSCardsFrame:Hide(); A.offer=false; AZS_RUN.ph="playing"; AZS_SPELLS={{key="auto_shot",rank=1,cdmax=1}}; AZS_GEAR={};
ASAdvisorDB.options.trackerMode="detailed"; ASAdvisorDB.options.trackerWidth=260; ASAdvisorDB.options.trackerHeight=110;
A.RefreshUI(); local t=ASAdvisorTracker;
local function rows() local n=0; for _,r in ipairs(t.rows) do if r:IsShown() then n=n+1; end end; return n; end
local initial=rows(); t.resize.scripts.OnMouseDown(t.resize,"LeftButton");
t:SetSize(300,400); t.scripts.OnSizeChanged(t);
check(t.sizing and ASAdvisorDB.options.trackerWidth==300 and ASAdvisorDB.options.trackerHeight==400,"dimensions update while mouse is still held");
check(rows()==initial,"all jewelry rows remain visible during live width resize");
t:SetSize(240,110); t.scripts.OnSizeChanged(t);
for _,r in ipairs(t.rows) do if r:IsShown() then
  check(-r.point[5]+r:GetHeight()<=t.viewport:GetHeight(),"no visible tracker row crosses viewport bottom while shrinking");
  check(r:GetParent()==t.content and t.content:GetParent()==t.viewport,"tracker rows are physically clipped by scroll viewport");
end end
t.resize.scripts.OnMouseUp(t.resize);
check(not t.sizing and (t.stopCount or 0)>0,"resize release stops native sizing");
t.scripts.OnDragStart(t); check(t.moving,"drag begins");
AZSCardsFrame:Show(); A.offer=true; A.RefreshUI();
check(not t.moving and not t.sizing and not t:IsShown(),"card selection cancels drag before hiding tracker");
AZSCardsFrame:Hide(); A.offer=false; A.RefreshUI();
check(t:IsShown() and not t.moving and not t.sizing,"tracker returns detached from mouse after card choice");
t.resize.scripts.OnMouseDown(t.resize,"LeftButton");
t:SetSize(300,400); t.scripts.OnSizeChanged(t); AZSCardsFrame:Show(); A.offer=true; A.RefreshUI();
check(not t.sizing,"card selection also cancels resize");
AZSCardsFrame:Hide(); A.offer=false; A.RefreshUI();
t.scripts.OnDragStart(t); IsMouseButtonDown=function() return false; end; A.CheckPointerRelease(); IsMouseButtonDown=nil;
check(not t.moving,"release outside tracker cancels drag via global pointer check");
check(not t.resize.text and not p.resize.text and #t.resize.children==4,"resize handles draw corner strokes without a boxed caption");
b.items[#b.items+1]="earthstrike"; AZS_GEAR={{slot="trinket",name="Earthstrike",text="+30% damage"}};
Emit("AZSGEAR",""); ASAdvisorRuntime.scripts.OnUpdate(ASAdvisorRuntime,0.3);
local found=false; for _,r in ipairs(t.rows) do if r:IsShown() and r.row.key=="earthstrike" then found=string.find(r.detail:GetText(),"30",1,true)~=nil; end end
check(found,"new gear and stats refresh without another resize");
ASAdvisorDB.options.plannerHeight=900; ASAdvisorDB.options.previewHeight=nil; A.ToggleUI();
if p.description:IsShown() then click(p.description.back); end; if p.settings:IsShown() then click(p.settings.back); end; if p.preview:IsShown() then click(p.preview.back); end; if p.code:IsShown() then click(p.code.back); end
click(p.spellCells[2]);
check(string.find(p.inline.base:GetText(),A.T("Базовые"),1,true) and string.find(p.inline.base:GetText(),"255",1,true),"base spell stats are visible directly in inspector");
check(p.inline.title:GetText()==A.Local("Aimed Shot") and p.planLeft.text:GetText()==A.T("Раньше") and p.inline.remove.text:GetText()==A.T("Убрать"),"selection toolbar names the item and explains its actions");
for _,cell in ipairs(p.spellCells) do check(not cell.remove:IsShown(),"plan icons have no stacked delete buttons"); end
click(p.itemCells.ring[1]); check(string.find(p.inline.base:GetText(),"9%%"),"base jewelry bonus is visible directly in inspector");
AZS_GEAR={{slot="ring",name="Quick Strike Ring",text="+20% cooldown reduction"}};
p.itemCells.ring[1].scripts.OnEnter(p.itemCells.ring[1]);
check(string.find(p.tip.body:GetText(),"9%%") and string.find(p.tip.body:GetText(),"20%%"),"tooltip labels both base and current jewelry stats");
check(p.tip.body:GetParent()==p.tip,"tooltip body renders in the same frame as its visible title");
p.itemCells.ring[1].scripts.OnLeave(p.itemCells.ring[1]);
click(p.previewButton);
check(p:GetHeight()==p.preview.sheet:GetHeight()+150 and p:GetWidth()==760,"preview fits its sheet independently of oversized editor");
for _,cell in ipairs(p.preview.sheet.rows) do if cell:IsShown() then check(not cell.body:IsShown() and cell.body:GetText()=="" and (not cell.goals:IsShown() or -cell.goals.point[5]+cell.goals:GetHeight()<=cell:GetHeight()),"preview excludes ability descriptions and fits all goal text"); end end
check(p.preview.scroll:GetHeight()>=p.preview.sheet:GetHeight(),"small build preview fits its viewport");
click(p.preview.back); click(p.spellCells[2]); local n=#b.spells; click(p.inline.remove);
check(#b.spells==n-1,"single selection toolbar removes the selected entry immediately");
local liveBefore=p.inline.current:GetText(); AZS_SPELLS={{key="auto_shot",rank=1,cdmax=0.5}}; Emit("AZSSPELLS",""); ASAdvisorRuntime.scripts.OnUpdate(ASAdvisorRuntime,0.3);
check(p.inline.current:GetText()~=liveBefore and string.find(p.inline.current:GetText(),"0.5",1,true),"open editor values refresh on live game data events");
print("Passed "..count.." v0.4.1 regression checks");

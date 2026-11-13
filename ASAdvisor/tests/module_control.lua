local A=ASAdvisor; local count=0; local function check(ok,label) assert(ok,label); count=count+1; end
if ASAdvisorPlanner:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); b.spells={{key="aimed_shot",rank=10}}; b.items={}; ASAdvisorDB.options.enabled=true; ASAdvisorDB.options.trackerHidden=false;
AZS_RUN.ph="playing"; AZS_SPELLS={}; AZS_GEAR={}; AZS_CARDS={kind="spell",rr=1,cards={{key="aimed_shot",new=1,lines="d25"}}}; AZSCardsFrame:Show(); A.offer=true; A.RefreshUI();
check(A.currentAction and A.currentAction.kind=="card","enabled builder produces live recommendation");
ASAdvisorDB.options.enabled=false; A.RefreshUI(); check(A.currentAction==nil and not ASAdvisorTracker:IsShown() and not ASAdvisorHints:IsShown(),"module off hides tracker and all recommendation overlays");
ASAdvisorDB.options.enabled=true; A.RefreshUI(); check(A.currentAction and A.currentAction.kind=="card","reenabling builder restores recommendations");
AZSCardsFrame:Hide(); A.offer=false; A.RefreshUI();
local previous=ASRSuite; ASRSuite={CanMovePanel=function() return A.suiteEditing; end};
ASAdvisorTracker.scripts.OnDragStart(ASAdvisorTracker); check(not ASAdvisorTracker.moving,"global lock blocks builder tracker dragging outside edit mode");
A.SetEditMode(true); ASAdvisorTracker.scripts.OnDragStart(ASAdvisorTracker); check(ASAdvisorTracker.moving,"interface editing allows the builder tracker to move"); ASAdvisorTracker.scripts.OnDragStop(ASAdvisorTracker); A.SetEditMode(false); ASRSuite=previous;
print("Passed "..count.." builder module controls checks");

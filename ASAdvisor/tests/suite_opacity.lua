local A=ASAdvisor; local checks=0; local function check(ok,name) assert(ok,name); checks=checks+1; end
local originalSuite=ASRSuite; local editorOpacity=ASAdvisorDB.options.opacity; local trackerOpacity=ASAdvisorDB.options.trackerOpacity;
ASRSuite={GetPanelOpacity=function(module,value) assert(module=="builder"); return 0.73; end};
A.ApplyLayout(); A.RefreshUI();
check(ASAdvisorPlanner.backdropColor[4]==0.73,"builder editor respects shared suite opacity");
check(ASAdvisorTracker.backdropColor[4]==0.73,"builder tracker respects shared suite opacity");
check(ASAdvisorDB.options.opacity==editorOpacity and ASAdvisorDB.options.trackerOpacity==trackerOpacity,"shared opacity never overwrites builder's local preferences");
ASRSuite.GetPanelOpacity=function(module,value) return value; end; A.ApplyLayout(); A.RefreshUI();
check(ASAdvisorPlanner.backdropColor[4]==editorOpacity and ASAdvisorTracker.backdropColor[4]==trackerOpacity,"module override restores both local builder opacities");
ASRSuite=originalSuite;
print("Passed "..checks.." suite opacity bridge checks");

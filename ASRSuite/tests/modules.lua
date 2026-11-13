local A=ASRSuite; local count=0; local function check(ok,label) assert(ok,label); count=count+1; end
local nav=0; for id in pairs(A.navigation) do if id~="future" then nav=nav+1; end end
check(nav==5 and not A.navigation.heal and not A.navigation.critical,"sidebar contains modules only, with damage types inside Combat text");
check(A.pages.builder.unavailable,"missing builder shows installation placeholder instead of inert settings");
ASRStatsDB.locked=false; ASRStatsPanel.settings.close.scripts.OnClick(ASRStatsPanel.settings.close); AZS_RUN.ph="playing";
A.SetEditing(false); ASRSuiteDB.lockPanels=true;
local grip; for _,f in ipairs(ASRStatsPanel.children) do if f.scripts.OnDragStart then grip=f; break; end end
check(grip~=nil,"Stats exposes its normal drag handle"); grip.scripts.OnDragStart(grip); check(not ASRStatsPanel.moving,"global lock blocks ordinary Stats dragging");
A.SetEditing(true); grip.scripts.OnDragStart(grip); check(ASRStatsPanel.moving,"shared edit mode overrides global lock"); grip.scripts.OnDragStop(grip); A.SetEditing(false);
ASRSuiteDB.lockPanels=false; grip.scripts.OnDragStart(grip); check(ASRStatsPanel.moving,"unlocked panels can be dragged normally"); grip.scripts.OnDragStop(grip); ASRSuiteDB.lockPanels=true;
A.SetModuleEnabled("stats",false); check(not ASRStatsPanel:IsShown(),"module off hides Stats independently of layout mode");
A.SetModuleEnabled("stats",true); check(ASRStatsPanel:IsShown(),"reenabling Stats restores live panel and saved options");
local selected;
A.RegisterDisplaySource("party","game","Game",nil,function() selected="game"; end);
A.RegisterDisplaySource("party","addon","Addon",function() return false; end,function() selected="addon"; end);
local combatSource=ASRSuiteDB.sources.combat;
check(not A.SelectDisplaySource("party","addon") and selected==nil,"unavailable display provider cannot be activated");
check(A.SelectDisplaySource("party","game") and selected=="game" and ASRSuiteDB.sources.combat==combatSource,"new module can register display providers without changing combat text selection");
A.SelectDisplaySource("combat","game"); check(not A.CombatConfig().enabled and Cvars.CombatDamage=="1","game text provider disables the ASR replacement");
A.SelectDisplaySource("combat","asr"); check(A.CombatConfig().enabled and Cvars.CombatDamage=="0","ASR provider replaces native combat numbers");
local display="third-party";
A.RegisterDisplaySource("party","replacement","Replacement",nil,function() local before=display; display="ASR"; return function() display=before; end; end);
A.SelectDisplaySource("party","replacement"); check(display=="ASR","registered module can own only its display element");
A.SetModuleEnabled("party",false); check(display=="third-party","disabling a provider restores captured third-party UI rather than forcing native UI");
A.SetLanguage("ru"); check(A.navigation.stats.text:GetText()=="Статы" and A.T("ASR Stats")=="ASR Статы","stats section follows Russian language");
A.SetLanguage("en"); check(A.navigation.stats.text:GetText()=="Stats","stats section follows English language"); A.SetLanguage("ru");
local provider=A.controls.compatibility.combat.combat;
check(A.compatibilityGroups.combat.frame:GetParent()==A.compatibilityGroups.stats.frame:GetParent(),"compatibility lists addon sections together rather than a second navigation menu");
check(not A.compatibilityScroll.bar:IsShown() and A.compatibilityScroll.maximum()==0,"short compatibility lists hide the scrollbar instead of suggesting hidden content");
check(A.controls.compatibility.combat.combatDefault~=nil and A.controls.compatibility.game==nil,"game alternative is beside the addon element, not an ambiguous addon category");
A.controls.compatibility.combat.combatDefault.scripts.OnClick(A.controls.compatibility.combat.combatDefault);
check(ASRSuiteDB.sources.combat=="game" and not A.CombatConfig().enabled and Cvars.CombatDamage=="1","adjacent game checkbox selects native numbers exclusively");
A.SetModuleEnabled("combat",true); provider.scripts.OnClick(provider); check(not A.CombatConfig().enabled and ASRSuiteDB.sources.combat=="previous","unchecking an addon element restores previous display");
provider.scripts.OnClick(provider); check(A.CombatConfig().enabled,"checking the addon element re-enables its replacement");
local replacement=false;
A.RegisterCompatibilityAddon("future-party","Future Party",nil,{{id="frames",title="Party frames",get=function() return replacement; end,set=function(on) replacement=on; end}});
check(A.controls.compatibility["future-party"].frames~=nil,"new addons add their own feature checkboxes without changing the compatibility layout");
local future=A.controls.compatibility["future-party"].frames; future.scripts.OnClick(future); check(replacement,"registered feature checkbox invokes its addon setter");
SlashCmdList.ASRSTATS("config");
check(ASRStatsPanel.strata=="FULLSCREEN_DIALOG" and ASRStatsPanel:GetFrameLevel()>=600 and MockOnTop.ASRStatsPanel,"Stats settings stay above tracker edit layers and native selection cards");
check(ASRStatsPanel.settings:GetFrameLevel()>ASRStatsPanel:GetFrameLevel() and ASRStatsPanel.settings.close:GetFrameLevel()>ASRStatsPanel.settings:GetFrameLevel(),"Stats settings controls stay above the raised backdrop");
ASRStatsPanel.settings.close.scripts.OnClick(ASRStatsPanel.settings.close);
check(ASRStatsPanel.strata=="HIGH" and ASRStatsPanel:GetFrameLevel()==10 and not MockOnTop.ASRStatsPanel,"closing Stats settings restores its normal tracker layer");
local barButtons={}; for _,f in ipairs({A.editBar:GetChildren()}) do if f.kind=="Button" then barButtons[#barButtons+1]=f; end end
check(#barButtons==3 and barButtons[1]:GetWidth()==barButtons[2]:GetWidth() and barButtons[2]:GetWidth()==barButtons[3]:GetWidth(),"layout bar buttons have equal widths");
check(barButtons[2].point[4]-barButtons[1].point[4]-barButtons[1]:GetWidth()==12 and barButtons[3].point[4]-barButtons[2].point[4]-barButtons[2]:GetWidth()==12,"layout bar buttons have equal gaps");
for i=1,15 do A.RegisterCompatibilityAddon("scroll-test-"..i,"Test "..i,nil,{{id="panel",title="Panel",get=function() return true; end,set=function() end}}); end
local scrolling=A.compatibilityScroll; check(scrolling.bar.shown~=false and scrolling.maximum()>500,"fifteen addons expose a bounded scroll range");
local cell=A.controls.compatibility.combat.combat;
cell.scripts.OnMouseWheel(cell,-1); check(scrolling.frame:GetVerticalScroll()==40 and scrolling.slider:GetValue()==40,"wheel over checkbox scrolls the list and synchronizes the thumb");
scrolling.slider:SetValue(scrolling.maximum()); check(scrolling.frame:GetVerticalScroll()==scrolling.maximum(),"dragging the thumb reaches the last addon");
scrolling.set(100000); check(scrolling.frame:GetVerticalScroll()==scrolling.maximum(),"scrolling stays within content bounds");
check(A.compatibilityGroups.combat.frame:GetHeight()<=60,"addon section is compact with details in tooltips");
local overlay=CreateFrame("Frame",nil,A.settings); overlay.asrOverlay=true; ASRStyle.SyncChildren(A.settings);
check(overlay.strata=="TOOLTIP" and overlay:GetFrameLevel()>=1000,"synchronizing window controls preserves tooltip overlays above nested scrolling rows"); overlay:Hide();
print("Passed "..count.." module and interface controls checks");

local A=ASRSuite; local n=0;
local function check(ok,name) assert(ok,name); n=n+1; end
AZS_RUN={ph="playing"}; AZS_STATS={hp=841};
ASRCombatTextRuntime.scripts.OnEvent(ASRCombatTextRuntime,"ADDON_LOADED","ASRCombatText");
ASRStatsRuntime.scripts.OnEvent(ASRStatsRuntime,"ADDON_LOADED","ASRStats");
ASRSuiteRuntime.scripts.OnEvent(ASRSuiteRuntime,"ADDON_LOADED","ASRSuite");
check(A.ready and A.minimap and not A.settings:IsShown(),"suite initializes quietly with minimap button");
check(ASRSuiteDB.language=="en","fresh suite installation defaults to English");
check(A.settings.strata=="FULLSCREEN_DIALOG" and A.settings:GetFrameLevel()>=400 and MockOnTop.ASRSuiteSettings,"common settings are registered above game selection screens");
check(not A.minimap.backdrop and A.minimap.rim and A.minimap.rim.texturePath=="Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\actionbutton-border","minimap button uses circular art instead of a rectangular backdrop");
check(Cvars.CombatDamage=="0","custom combat text suppresses stock damage numbers");
A.PollEvents(); Feed[1]={kind="damage",amount=100,spellId=1}; A.PollEvents();
check(#A.active==1 and A.active[1].amount==100,"native feed produces one outgoing hit");
A.PollEvents(); check(#A.active==1 and A.active[1].amount==100,"cursor prevents duplicate delivery");
A.AddHit({kind="damage",amount=50,spellId=1});
check(#A.active==1 and A.active[1].count==2 and A.active[1].amount==150,"same ability hits merge inside configured window");
A.AddHit({kind="damage",amount=70,spellId=1,critical=true});
check(#A.active==2 and A.active[2].lane=="critical","critical hits have an independent column");
A.AddHit({kind="heal",amount=200,overheal=150,spellId=2});
check(A.active[3].amount==50 and A.active[3].lane=="heal","healing subtracts overheal");
local count=#A.active; A.AddHit({kind="heal",amount=50,overheal=50}); check(#A.active==count,"fully overhealing events are not displayed");
Advance(0.4); A.AddHit({kind="damage",amount=25,spellId=1}); check(#A.active==4,"hits outside merge window remain separate");
A.CombatConfig().periodic=false; A.AddHit({kind="damage",amount=100,spellId=3,periodic=true}); check(#A.active==4,"periodic filter is respected"); A.CombatConfig().periodic=true;
A.CombatConfig().mode="enemies"; A.ClearCombat();
A.AddHit({kind="damage",amount=30,spellId=1,anchorId="enemy"}); A.AddHit({kind="damage",amount=30,spellId=1,anchorId="other"});
check(#A.active==2,"enemy mode does not merge hits from distinct targets");
A.UpdateCombat(0.01); check(A.active[1]:IsShown() and A.active[1].point[4]==300,"world projection places damage over its actual enemy");
A.AddHit({kind="damage",amount=30,spellId=1,anchorId="hidden"}); A.UpdateCombat(0.01); check(not A.active[3]:IsShown(),"behind-camera anchors are hidden");
Advance(5); A.UpdateCombat(0.1); check(#A.active==0,"finished combat text is released");
A.CombatConfig().merge=0; for i=1,100 do A.AddHit({kind="damage",amount=i,spellId=i}); end; check(#A.active<=512,"combat text pool stays bounded under dense damage"); A.ClearCombat();
A.CombatConfig().mode="columns"; A.CombatConfig().merge=0; A.CombatConfig().scrollSpeed=30; A.CombatConfig().rise=100; A.ClearCombat();
local first=A.AddHit({kind="damage",amount=10,spellId=1}); A.AddHit({kind="damage",amount=10,spellId=1});
check(#A.active==2,"zero merge fully disables grouping even for same-frame hits");
Advance(0.5); A.UpdateCombat(0.01); local oldY=first.point[5];
for i=1,30 do A.AddHit({kind="damage",amount=i,spellId=i}); end; A.UpdateCombat(0.01);
check(first.point[5]==oldY,"new hits do not push existing numbers or accelerate their movement");
local origin=UIParent:GetHeight()/2+A.CombatConfig().positions.normal.y;
check(math.abs(oldY-origin-15)<0.0001,"scroll speed determines travel independently of hit count");
Advance(0.2); A.UpdateCombat(0.01); check(math.abs(first.point[5]-oldY-6)<0.0001,"number continues at fixed configured speed"); A.ClearCombat();
A.CombatConfig().mode="enemies"; ASRStatsDB.locked=true; A.SetEditing(true);
check(A.CombatConfig().mode=="enemies","editing preserves the chosen enemy layout while exposing movable column handles");
check(ASRStatsPanel.strata=="FULLSCREEN_DIALOG" and MockOnTop.ASRStatsPanel,"Stats edit area remains above level-up cards");
check(A.controls.edit.point[5]==-24,"column edit action stays visible in settings header");
check(A.editing and ASRStats.editing and A.editBar:IsShown(),"shared edit mode includes Stats without changing its lock setting");
for _,f in pairs(A.handles) do check(f:IsShown(),"all four combat areas are movable in edit mode"); check(f.strata=="FULLSCREEN_DIALOG" and f:GetFrameLevel()>=450 and MockOnTop[f.name],"combat area is registered above game choice screens"); end
local f=A.handles.normal; f.scripts.OnDragStart(f); f.cx=430; f.cy=290; A.StopDrag(f);
check(A.CombatConfig().positions.normal.x==430-UIParent:GetWidth()/2 and A.CombatConfig().positions.normal.y==290-UIParent:GetHeight()/2,"drag stores position relative to screen center");
A.SetEditing(false); check(not ASRStats.editing and ASRStatsDB.locked and not f:IsShown(),"finish edit preserves Stats lock and hides handles");
A.Enabled(false); check(Cvars.CombatDamage=="1","disabling custom text restores native combat setting");
A.AddHit({kind="damage",amount=999}); check(#A.active==0,"disabled module does not emit numbers"); A.Enabled(true);
A.minimap.scripts.OnClick(A.minimap,"LeftButton"); check(A.settings:IsShown(),"minimap left click opens common settings");
A.settings:SetFrameLevel(900); A.RefreshStatus();
local function Above(parent) for _,child in ipairs({parent:GetChildren()}) do check(child:GetFrameLevel()>parent:GetFrameLevel() and child:GetFrameStrata()==parent:GetFrameStrata(),"every child control stays above the raised window background"); Above(child); end end
Above(A.settings);
check(A.minimap.mark.point[1]=="CENTER" and A.minimap.mark.point[4]==0 and A.minimap.mark.point[5]==0,"ASR label is centered on the circular minimap button");
A.minimap.scripts.OnClick(A.minimap,"RightButton"); check(A.editing,"minimap right click toggles shared edit mode"); A.SetEditing(false);
local survivor="survivor"; function SurvivorUI_DamageMode() return survivor; end; function SurvivorUI_SetDamageMode(mode) survivor=mode; end
A.SelectDisplaySource("combat","survivor"); check(survivor=="survivor" and not A.CombatConfig().enabled,"compatibility selects SurvivorUI and disables ASR text");
A.SelectDisplaySource("combat","asr"); check(survivor=="none" and A.CombatConfig().enabled,"ASR source replaces SurvivorUI combat text");
AZS_RUN.ph="hub"; A.SetEditing(true); check(ASRStatsPanel:IsShown(),"Stats can be positioned in hub while editing"); A.SetEditing(false); check(not ASRStatsPanel:IsShown(),"Stats hides in hub after editing");
A.Enabled(false); check(Cvars.CombatDamage=="1","native combat text restoration stays correct after repeated changes");
AZS_RUN.ph="playing"; A.Enabled(true); A.ClearCombat();
ASRCombatTaken.scripts.OnEvent(ASRCombatTaken,"COMBAT_LOG_EVENT_UNFILTERED",0,"SPELL_DAMAGE","Enemy","Enemy",0,"Player","Player",0,1,"Spell",1,123,0,1,0,0,0,true);
check(#A.active==1 and A.active[1].lane=="taken" and A.active[1].amount==123,"incoming damage uses real WotLK combat-log field positions");
A.CombatConfig().heals=false; A.AddHit({kind="heal",amount=30}); check(#A.active==1,"healing switch suppresses healing events");
ASRCombatTaken.scripts.OnEvent(ASRCombatTaken,"PLAYER_LOGOUT"); check(Cvars.CombatDamage=="1","logout restores native text preference");
ASAdvisorDB={options={language="ru"}}; ASAdvisor={SetLanguage=function(lang) ASAdvisorDB.options.language=lang; end};
local oldSize=A.CombatConfig().fontSize; local oldPosition=A.CombatConfig().positions.normal.x;
A.settings:Show(); A.SetLanguage("en");
check(ASRStatsDB.language=="en" and ASAdvisorDB.options.language=="en","suite language synchronizes Stats and builder");
check(A.controls.enabled.label:GetText()=="Combat text","dynamic combat controls translate immediately");
check(A.controls.steps.lifetime.value:GetText():find(" s",1,true),"duration controls use localized units");
local function EnglishOnly(frame)
 if frame.kind=="FontString" then local text=frame:GetText() or ""; check(not text:find(string.char(208),1,true) and not text:find(string.char(209),1,true),"English settings contain no untranslated Russian labels"); end
 for _,child in ipairs(frame.children or {}) do EnglishOnly(child); end
end
EnglishOnly(A.settings); EnglishOnly(A.editBar);
for _,handle in pairs(A.handles) do EnglishOnly(handle); end
local tipTitle,tipBody; GameTooltip.SetText=function(self,text) tipTitle=text; end; GameTooltip.AddLine=function(self,text) tipBody=text; end;
A.minimap.scripts.OnEnter(A.minimap); check(tipBody:find("Left click",1,true),"minimap instructions follow suite language");
A.controls.steps.merge.minus.scripts.OnEnter(A.controls.steps.merge.minus); check(tipBody:find("total damage",1,true),"merge tooltip explains totals in the selected language");
SlashCmdList.ASRSTATS("config"); local languageButton=ASRStatsPanel.settings.settings[1].button; languageButton.scripts.OnClick(languageButton); languageButton.localePopup.options.ru.scripts.OnClick(languageButton.localePopup.options.ru);
check(ASRSuiteDB.language=="ru" and ASRStatsDB.language=="ru" and ASAdvisorDB.options.language=="ru","standalone Stats language control also updates the whole suite");
check(A.CombatConfig().fontSize==oldSize and A.CombatConfig().positions.normal.x==oldPosition,"language changes preserve layout and combat preferences");
print("Passed "..n.." ASR Suite integration checks and Lua 5.1 syntax");

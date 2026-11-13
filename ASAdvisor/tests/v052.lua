local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local p=ASAdvisorPlanner; if p:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); b.spells={}; for i=1,6 do b.spells[i]={key=AZS_GEN.spells.HUNTER[i].key,rank=1}; end
b.items={"accuria","quick_strike","earthstrike","chosen","south_seas_kelp","eye_of_hakkar","malice_stone"};
AZSCardsFrame:Hide(); A.offer=false; AZS_RUN.ph="playing"; AZS_SPELLS={}; AZS_GEAR={};
local o=ASAdvisorDB.options; o.trackerMode="compact"; A.RefreshUI(); local t=ASAdvisorTracker;
check(t.builds.point[5]<=-11 and t.mode.point[5]<=-11,"compact header buttons start inside the thick frame");
local n=0; for _,icon in ipairs(t.icons) do if icon:IsShown() then
  n=n+1; check(-icon.point[5]+icon:GetHeight()<=t:GetHeight()-16,"compact icon clears the bottom border");
  check(icon.point[4]>=16 and icon.point[4]+icon:GetWidth()<=t:GetWidth()-16,"compact icon clears both side borders");
end end
check(n==13,"all compact spell and jewelry icons fit inside the panel");
o.trackerMode="detailed"; o.trackerHeight=110; A.RefreshUI();
n=0; local bottom=0; for _,row in ipairs(t.rows) do if row:IsShown() then n=n+1; bottom=math.max(bottom,-row.point[5]+row:GetHeight()); end end
check(n==13,"detailed mode shows every entry even with an old short-height preference");
check(bottom<=t.content:GetHeight() and 53+t.viewport:GetHeight()<=t:GetHeight()-16,"detailed content fits its scroll child and viewport stays within the frame");
check(t.scrollHint:IsShown() and t.maxOffset>0,"short detailed mode advertises scrolling");
t.scripts.OnMouseWheel(t,-100); check(t.offset==t.maxOffset and t.rows[13]:IsShown() and t.rows[1]:IsShown(),"mouse wheel reaches the bottom without dropping entries from scroll content");
check(t:GetHeight()*(t.scale or 1)<=UIParent:GetHeight()-24,"complete detailed tracker scales to screen height");
check(t.sizeDirection=="BOTTOMRIGHT","tracker resize controls both width and maximum height");
A.ToggleUI(); if p.preview:IsShown() then click(p.preview.back); end
check(p.work.point[5]==-84 and p.side.point[5]==-84,"editor content begins below padded header");
for _,button in ipairs({p.close,p.previewButton,p.descriptionButton,p.settingsButton}) do
  check(button.point[5]<=-28 and -button.point[5]+button:GetHeight()<=84,"editor header button stays inside the frame and above content");
end
for _,button in ipairs({p.import,p.export,p.capture}) do check(84-button.point[5]+button:GetHeight()<=p:GetHeight()-16,"sidebar action clears bottom frame"); end
click(p.previewButton);
check(84-p.preview.export.point[5]+p.preview.export:GetHeight()<=p:GetHeight()-16,"preview action clears bottom frame");
check(p:GetHeight()>=p.preview.sheet:GetHeight()+150,"preview reserves the padded header and footer");
A.ToggleUI(); o.pickStyle="band"; AZS_CARDS={kind="spell",rr=2,cards={{key=b.spells[1].key,new=1,rarity=0}}}; AZSCardsFrame:Show(); A.offer=true; A.RefreshUI();
local marker=ASAdvisorCardMark1;
check(marker:IsShown() and marker.backdrop and marker.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8","recommendation band uses a dark panel instead of the legacy gradient");
check(not marker.bands and marker.text.textColor[2]==1 and marker.text.textColor[3]>0.8 and marker.backdropColor[2]>marker.backdropColor[1],"recommendation band uses bright turquoise lettering on an opaque dark teal panel");
o.pickStyle="arrow"; A.RefreshUI(); check(marker.arrow:IsShown() and not marker.text:IsShown() and not marker.backdrop,"arrow variant remains selectable");
o.pickStyle="inline"; A.RefreshUI(); check(marker.backdrop and marker.text:IsShown() and not marker.arrow:IsShown(),"inline variant uses the same updated panel styling");
print("Passed "..count.." v0.5.2 regression checks");

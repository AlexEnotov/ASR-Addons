local A=ASAdvisor; local n=0;
local function check(ok,name) assert(ok,name); n=n+1; end
local p=ASAdvisorPlanner; if p:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); b.spells={{key="aimed_shot",rank=1},{key="rapid_fire",rank=1}}; b.items={"accuria","quick_strike","earthstrike"};
AZSCardsFrame:Hide(); A.offer=false; AZS_RUN.ph="playing"; AZS_SPELLS={}; AZS_GEAR={}; ASAdvisorDB.options.trackerMode="compact"; A.RefreshUI();
local t=ASAdvisorTracker;
function UIParent:GetEffectiveScale() return 1; end
function t:GetEffectiveScale() return self.scale or 1; end
function t:GetLeft()
 local point,_,relative,x=self:GetPoint(); local scale=self:GetEffectiveScale();
 local base=relative=="CENTER" and UIParent:GetWidth()/2 or 0;
 return (base+x*scale-(point=="CENTER" and self:GetWidth()*scale/2 or 0))/scale;
end
function t:GetTop()
 local point,_,relative,_,y=self:GetPoint(); local scale=self:GetEffectiveScale();
 local base=relative=="TOPLEFT" and UIParent:GetHeight() or relative=="CENTER" and UIParent:GetHeight()/2 or 0;
 return (base+y*scale+(point=="CENTER" and self:GetHeight()*scale/2 or 0))/scale;
end
t:SetPoint("CENTER",UIParent,"CENTER",-100,40);
local left,top=t:GetLeft()*t:GetEffectiveScale(),t:GetTop()*t:GetEffectiveScale();
for i=1,6 do
 t.mode.scripts.OnClick(t.mode);
 check(math.abs(t:GetLeft()*t:GetEffectiveScale()-left)<0.000001 and math.abs(t:GetTop()*t:GetEffectiveScale()-top)<0.000001,"mode switching preserves screen top-left through size and scale changes");
 if ASAdvisorDB.options.trackerMode=="detailed" then
  check(t.sectionLabels.spell:IsShown() and t.sectionLabels.jewel:IsShown(),"detailed tracker separates spells and jewelry");
  check(-t.rows[3].point[5]>-t.sectionLabels.jewel.point[5],"jewelry heading precedes the first item");
 else check(t.spellLabel:IsShown() and t.itemLabel:IsShown(),"compact tracker labels both groups"); end
end
check(ASAdvisorDB.options.trackerAnchor.left==left and ASAdvisorDB.options.trackerAnchor.top==top,"stable screen anchor is saved for reload");
ASAdvisorDB.options.trackerMode="detailed"; AZS_SPELLS={{key="aimed_shot",rank=6,cdmax=0.8}};
AZS_SPELLTIPS.aimed_shot="Поражает до 2 противников, нанося 1815 ед. урона."; A.RefreshUI();
check(t.rows[1].rank:IsShown() and t.rows[1].rank:GetText()=="R6" and t.rows[1].rank.point[5]==t.rows[1].name.point[5],"rank is aligned with the spell name");
check(not string.find(t.rows[1].detail:GetText(),"R6",1,true) and string.find(t.rows[1].detail:GetText(),A.T("Цели").." 2",1,true),"stat line spells out target count and does not repeat rank");
b.spells={{key="aimed_shot",rank=1},{key="rapid_fire",rank=1}}; b.items={};
AZS_SPELLS={{key="aimed_shot",rank=1,cdmax=1},{key="auto_shot",rank=2,cdmax=0.8}};
AZS_GEAR={{slot="ring",name="Band of Accuria",text="+20% damage"}};
ASAdvisorDB.options.trackerHeight=140; ASAdvisorDB.options.trackerMode="detailed"; A.RefreshUI();
check(t.sectionLabels.extra:IsShown() and string.find(t.sectionLabels.extra:GetText(),"2",1,true),"unplanned spell and item are identified together outside the build");
check(t.extraIcons[1]:IsShown() and t.extraIcons[2]:IsShown() and not t.rows[3]:IsShown(),"extra equipment uses a compact icon strip instead of full stat rows");
check(t.rows[2]:GetHeight()<t.rows[1]:GetHeight() and not t.rows[2].detail:IsShown(),"unacquired build entries use a single dimmed row");
check(t:GetHeight()<=140 and t.maxOffset>0,"extra picks cannot stretch the detailed tracker below its configured height");
t.rows[1].scripts.OnMouseWheel(t.rows[1],-1); local scrolled=t.offset;
check(scrolled>0 and t.viewport:GetVerticalScroll()==scrolled,"scrolling over an entry moves the viewport");
A.RefreshUI(); check(t.offset==scrolled,"live refresh preserves scroll position");
ASAdvisorDB.options.trackerMode="compact"; A.RefreshUI();
local warned=false; for _,icon in ipairs(t.icons) do if icon:IsShown() and icon.outside then warned=icon.warning:IsShown(); end end
check(warned and not t.extraIcons[1]:IsShown(),"compact mode marks extras without retaining the detailed icon strip");
ASAdvisorDB.options.trackerMode="detailed"; A.RefreshUI();
check(t.sectionLabels.spell.fontSize==10 and -t.sectionLabels.spell.point[5]-(-t.extraIcons[1].point[5]+t.extraIcons[1]:GetHeight())<=6,"category headings are larger and stay close to the preceding icons");
local hover=t.rows[1]; local wheel=hover:GetScript("OnMouseWheel"); hover:GetScript("OnEnter")(hover);
check(t.tip.strata=="TOOLTIP" and t.tip:GetFrameLevel()>t:GetFrameLevel()+50 and t.tip.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8" and t.tip.backdropColor[4]==1,"tracker tooltip uses an opaque overlay above content rows");
check(t.tip.point[2]==t and (t.tip.point[3]=="TOPRIGHT" or t.tip.point[3]=="TOPLEFT"),"tracker description is anchored beside the panel instead of across its entries");
t.tip:SetFrameLevel(1); hover:GetScript("OnEnter")(hover); check(t.tip:GetFrameLevel()>=1000,"showing a tooltip restores its overlay level after layout changes");
hover:GetScript("OnLeave")(hover); check(hover:GetScript("OnMouseWheel")==wheel,"leaving the tooltip restores the tracker's original wheel handler");
print("Passed "..n.." tracker mode checks");

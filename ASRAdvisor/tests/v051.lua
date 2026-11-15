local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local p=ASAdvisorPlanner; if p:IsShown() then A.ToggleUI(); end
local b=A.NewBuild("HUNTER"); b.spells={};
for i=1,6 do b.spells[i]={key=AZS_GEN.spells.HUNTER[i].key,rank=1}; end
b.items={"accuria","quick_strike","earthstrike","chosen","south_seas_kelp","eye_of_hakkar","malice_stone"};
AZSCardsFrame:Hide(); A.offer=false; AZS_RUN.ph="playing"; AZS_SPELLS={}; AZS_GEAR={};
local o=ASAdvisorDB.options; o.trackerMode="detailed"; o.trackerWidth=280; o.trackerHeight=280; o.trackerOpacity=1;
A.RefreshUI(); local t=ASAdvisorTracker;
for i=1,40 do t.scripts.OnMouseWheel(t,-1); end
local visible=0; for _,r in ipairs(t.rows) do if r:IsShown() then visible=visible+1; end end
check(visible>1 and t.rows[13]:IsShown(),"overscrolling ends at a filled page containing the final item");
check(t.offset==t.maxOffset and math.abs(t.offset+t.viewport:GetHeight()-t.content:GetHeight())<0.001,"tracker pixel offset is bounded by the final viewport");
local offset=t.offset; t.scripts.OnMouseWheel(t,-50); check(t.offset==offset,"further downward scroll does not empty the page");
o.trackerHeight=600; A.RefreshUI(); t.scripts.OnMouseWheel(t,-50);
check(t.offset==0 and t.maxOffset==0,"tracker cannot scroll when every entry fits");
check(t.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8" and t.backdropColor[4]==1,"100 percent tracker opacity uses an opaque texture");
check(t.backdrop.edgeFile=="Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\border-tooltip","tracker reuses the exact in-game meter/spectate border");
o.opacity=1; A.ToggleUI(); if p.preview:IsShown() then click(p.preview.back); end
check(p.backdropColor[4]==1 and p.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8","100 percent editor opacity covers the game world");
o.opacity=0.4; A.Redraw(); check(p.backdropColor[4]==0.4,"editor background still honors partial opacity"); o.opacity=1;
click(p.settingsButton);
check(p.settings.pickStyle:GetWidth()<=360 and p.settings.tracker:GetWidth()<=240,"settings actions have bounded widths");
check(p.settings.pickStyle.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8","buttons use a scalable solid fill instead of a stretched native red texture");
click(p.settings.back); click(p.spellCells[1]);
local pick=p.inline.pick; pick.cd=1; pick.damage=100; pick.targets=2; pick.radius=8; A.Redraw();
for key,e in pairs(p.inline.fields) do if e:IsShown() then
  local c=p.inline.captions[key]; local cy=-c.point[5]; local ey=-e.point[5];
  check(cy+c:GetHeight()<=ey,"caption clears its input: "..key);
  for otherKey,other in pairs(p.inline.fields) do if otherKey~=key and other:IsShown() then
    local x,y=e.point[4],-e.point[5]; local ox,oy=other.point[4],-other.point[5];
    check(x+e:GetWidth()<=ox or ox+other:GetWidth()<=x or y+e:GetHeight()<=oy or oy+other:GetHeight()<=y,"requirement inputs never overlap");
    local cx=c.point[4]; check(cx+c:GetWidth()<=ox or ox+other:GetWidth()<=cx or cy+c:GetHeight()<=oy or oy+other:GetHeight()<=cy,"captions clear adjacent input rows");
  end end
end end
local kelp=A.aliasItem("south_seas_kelp"); local originalName=kelp.name; kelp.name=string.rep("Длинное название амулета ",8);
o.previewHeight=nil; click(p.previewButton); local sheet=p.preview.sheet;
check(sheet.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8" and sheet.backdropColor[4]==1,"share preview uses a fully opaque dark background");
check(sheet.title.textColor[1]>0.9 and sheet.author.textColor[1]>0.7,"preview title and footer use readable light ink");
for _,cell in ipairs(sheet.rows) do if cell:IsShown() then
  check(cell.title:GetHeight()>=cell.title:GetStringHeight(),"full preview name has enough height");
  check(not cell.goals:IsShown() or cell.goals:GetHeight()>=cell.goals:GetStringHeight(),"full preview goals have enough height");
  check(not cell.goals:IsShown() or -cell.goals.point[5]>=-cell.title.point[5]+cell.title:GetHeight(),"preview goals start below the complete name");
  check(not cell.goals:IsShown() or -cell.goals.point[5]+cell.goals:GetHeight()<=cell:GetHeight(),"full preview text fits inside its card");
end end
kelp.name=originalName;
print("Passed "..count.." v0.5.1 regression checks");

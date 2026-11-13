local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local p=ASAdvisorPlanner;
if p.caps:IsShown() then click(p.caps.back); end
if p.settings:IsShown() then click(p.settings.back); end
if p:IsShown() then A.ToggleUI(); end
ASAdvisorDB.active.HUNTER=nil; AZS_SPELLS={};
for i=1,4 do AZS_SPELLS[i]={key=AZS_GEN.spells.HUNTER[i].key,rank=1,cdmax=1}; end
AZSCardsFrame:Hide(); A.offer=false; AZS_RUN.ph="playing"; ASAdvisorDB.options.trackerMode="compact"; A.RefreshUI();
local t=ASAdvisorTracker;
check(t.brand.point[4]>=24 and -t.brand.point[5]>=23,"tracker branding clears the visible inner metal edge");
check(t.builds.point[4]>=24 and -t.builds.point[5]>=23 and t.builds.point[4]+t.builds:GetWidth()<=t:GetWidth()-24,"build button is inside safe inner header bounds");
check(-t.mode.point[5]>=23 and t.mode.point[4]+t.mode:GetWidth()<=t:GetWidth()-24,"mode button is inside safe inner header bounds");
for _,icon in ipairs(t.icons) do if icon:IsShown() then check(-icon.point[5]>=58 and icon.point[4]>=24 and -icon.point[5]+icon:GetHeight()<=t:GetHeight()-24,"compact icon stays inside padded content"); end end
local b=A.NewBuild("HUNTER"); b.name="Test shared build"; b.spells={{key="auto_shot",rank=0},{key="aimed_shot",rank=2,cd=0.9}}; b.items={"accuria","quick_strike","earthstrike","south_seas_kelp"}; b.description=string.rep("Длинное описание общего билда и порядка выбора. ",30);
A.ToggleUI();
check(p.brand.point[4]>=24 and -p.brand.point[5]>=28 and -p.credit.point[5]>=54,"main branding clears the same safe inner border");
for _,control in ipairs({p.close,p.settingsButton,p.descriptionButton,p.previewButton}) do check(-control.point[5]>=28 and -control.point[5]+control:GetHeight()<84,"main header controls clear the frame and content below"); end
click(p.previewButton); local sheet=p.preview.sheet;
check(sheet.brand:GetText()=="AZEROTH SURVIVORS REBORN" and sheet.headerRule~=nil,"preview has a distinct cover heading and separator");
check(sheet.title.point[4]>=sheet.crest.point[4]+sheet.crest:GetWidth()+12,"preview title clears the enlarged class crest");
check(sheet.description:GetHeight()>=sheet.description:GetStringHeight() and string.find(sheet.description:GetText(),"...",1,true),"long build excerpt is shortened explicitly instead of clipped invisibly");
check(sheet.author:GetText()=="by AlexEnotov" and sheet.footerBrand:GetText()=="ASR ADVISOR","preview has a separate brand and author footer");
local unconstrained=false; local constrained=false;
for _,cell in ipairs(sheet.rows) do if cell:IsShown() then
  check(cell.backdrop==nil and cell.slot~=nil and cell.order:GetText()~="","preview entry uses a numbered icon slot instead of a button-like card border");
  check(not string.find(cell.title:GetText(),"^%d+%."),"priority number is separate from the entry title");
  if cell.row.key=="auto_shot" then unconstrained=not cell.goals:IsShown() and cell.goals:GetText()==""; end
  if cell.row.key=="aimed_shot" then constrained=cell.goals:IsShown() and string.find(cell.goals:GetText(),"0.9",1,true); end
end end
check(unconstrained and constrained,"preview suppresses repeated uncapped labels while retaining actual goals");

local saved={};
for _,cell in ipairs(sheet.rows) do
  saved[cell.goals]=cell.goals.GetText;
  cell.goals.GetText=function(self) local value=saved[self](self); if value=="" then return nil; end; return value; end;
end
A.Redraw();
for field,method in pairs(saved) do field.GetText=method; end
check(-sheet.author.point[5]+sheet.author:GetStringHeight()<=sheet:GetHeight(),"native nil text on empty goal labels cannot interrupt preview footer layout");

for _,cell in ipairs(sheet.rows) do if cell:IsShown() then check(-cell.point[5]+cell:GetHeight()<=-sheet.rule.point[5], "all preview entries remain above the completed footer" ); end end
print("Passed "..count.." v0.5.3 regression checks" );

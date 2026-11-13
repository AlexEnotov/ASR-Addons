local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(f) f.scripts.OnClick(f); end
local p=ASAdvisorPlanner; local b=A.NewBuild("HUNTER"); b.name="Journal regression";
b.spells={{key="auto_shot",rank=1},{key="aimed_shot",rank=0,cd=0.9,damage=500,targets=5},{key="frost_trap",rank=0,radius=12}}; b.items={"jeklik","quick_strike","earthstrike"};
if not p:IsShown() then A.ToggleUI(); end
if p.description:IsShown() then click(p.description.back); end; if p.preview:IsShown() then click(p.preview.back); end; if p.settings:IsShown() then click(p.settings.back); end
p.sizing=true; p:SetWidth(1240); p:SetHeight(900); p.scripts.OnSizeChanged(p); p.sizing=false;
click(p.tabs.amulet);
local total=1; for _,row in ipairs(A.catalog) do if row.group=="amulet" and A.AvailableTo(row,"HUNTER") then total=total+1; end end
local shown=0; local reachedClass=false;
for _,cell in ipairs(p.catalogRows) do if cell:IsShown() then
  shown=shown+1; local row=cell.row;
  if not row.addAny then local m=ASAdvisorMechanics.items[row.key]; local restricted=m and m.classes and #m.classes>0;
    if restricted then reachedClass=true; else check(not reachedClass,"ordinary amulets precede all class amulets"); end
  end
end end
check(total>24 and shown==total and not p.nextCatalog:IsShown(),"wide catalogue shows more than 24 icons without artificial pagination");
p.sizing=true; p:SetWidth(760); p:SetHeight(900); p.scripts.OnSizeChanged(p); p.sizing=false;
check(p.catalogRows[25]:IsShown() and -p.catalogRows[25].point[5]>=148,"additional icons flow into third and later catalogue rows");
click(p.spellCells[2]);
local left=p.inline; local right=p.quickDescription;
check(left:GetWidth()<=280 and right.point[4]>=left.point[4]+left:GetWidth(),"compact requirements sit left of separate description editor");
for key,e in pairs(left.fields) do if e:IsShown() then
  check(e.point[4]+e:GetWidth()<=left:GetWidth() and -e.point[5]+e:GetHeight()<=left:GetHeight(),"requirement field stays inside compact inspector: "..key);
end end
check(right.edit.viewport:GetHeight()>250,"expanded window height is used by description editor");
right.edit:SetFocus(); right.edit:SetText("Порядок выбора и советы автора.");
check(b.description=="Порядок выбора и советы автора.","inline description saves directly to the selected build");
click(right.more); check(p.description.edit:GetText()==b.description,"expanded description opens the same text");
p.description.edit:SetText("Дополненное описание в отдельной вкладке."); click(p.description.back);
check(right.edit:GetText()==b.description and string.find(right.edit:GetText(),"Дополненное",1,true),"full description changes appear back in inline editor");
check(p.credit:GetText()=="by AlexEnotov" and p.credit:IsShown(),"author credit is visible in editor header");
check(p.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8" and string.find(string.lower(p.backdrop.edgeFile),"tooltip",1,true),"editor uses native tooltip framing with a solid background");
check(p.name.fontPath==GameFontNormal:GetFont(),"editor reuses the game's font");
local frost=A.SpellDescription(A.byKey["HUNTER:frost_trap"],true);
check(string.find(frost,"область периодического урона",1,true) and string.find(frost,"Обездвиживание",1,true),"base spell description explains action and rider, not just raw stats");
local jeklik=A.BaseItemText(A.aliasItem("jeklik"));
check(string.find(jeklik,"Возвращает часть",1,true) and string.find(jeklik,"3%%") and string.find(jeklik,"за убийства",1,true),"amulet description explains both health effects and base values");
local target; for _,cell in ipairs(p.catalogRows) do if cell:IsShown() and cell.row.key=="jeklik" then target=cell; break end end
check(target~=nil,"ordinary amulet remains reachable on first page"); target.scripts.OnEnter(target);
check(p.tip.body:GetParent()==p.tip and p.tip.body.textColor[4]==1 and p.tip.body.alpha==1,"tooltip body is opaque and shares the visible title's rendering layer");
check(string.find(p.tip.body:GetText(),"3%%")~=nil,"visible tooltip text includes actual base bonus"); target.scripts.OnLeave(target);
ASAdvisorDB.options.previewHeight=nil; click(p.previewButton);
local sheet=p.preview.sheet;
check(sheet.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8" and sheet.crest.icon.texturePath~=nil,"share preview uses the dark game panel and a class crest");
check(string.find(sheet.author:GetText(),"by AlexEnotov",1,true),"author credit is included in shareable build sheet");
check(sheet.sections.ring.point[5]==sheet.sections.trinket.point[5] and sheet.sections.ring.point[4]<sheet.sections.trinket.point[4],"rings and trinkets share a row instead of leaving a blank grid column");
check(p:GetHeight()>=sheet:GetHeight()+150,"preview opens tall enough for the complete screenshot sheet");
for i,cell in ipairs(sheet.rows) do if cell:IsShown() then for j=1,i-1 do local other=sheet.rows[j]; if other:IsShown() then
  local x,y=cell.point[4],-cell.point[5]; local ox,oy=other.point[4],-other.point[5];
  check(x+cell:GetWidth()<=ox+0.01 or ox+other:GetWidth()<=x+0.01 or y+cell:GetHeight()<=oy+0.01 or oy+other:GetHeight()<=y+0.01,"share sheet tiles have no overlap");
end end end end
print("Passed "..count.." v0.5 regression checks");

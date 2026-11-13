local A=ASAdvisor; local count=0;
local function check(ok,name) assert(ok,name); count=count+1; end
local function click(frame) frame.scripts.OnClick(frame); end
local b=A.NewBuild("HUNTER");
b.spells={{key="auto_shot",rank=0,cd=11},{key="rapid_fire",rank=0,cd=12},{key="frost_trap",rank=0,cd=13},{key="arcane_shot",rank=0,cd=14},{key="aimed_shot",rank=0,cd=15}};
AZSCardsFrame:Hide(); AZS_RUN.ph="playing"; AZS_SPELLS={}; AZS_GEAR={}; A.offer=false;
local p=ASAdvisorPlanner; if p:IsShown() then A.ToggleUI(); end; A.ToggleUI();
if p.description:IsShown() then click(p.description.back); end
if p.settings:IsShown() then click(p.settings.back); end
if p.preview:IsShown() then click(p.preview.back); end
if p.code:IsShown() then click(p.code.back); end
click(p.spellCells[1]); local field=p.inline.fields.cd; field:SetFocus(); field:SetText("0.75");
for i=2,5 do click(p.spellCells[i]); end
check(b.spells[1].cd==0.75,"pending edit saved to original spell without Enter");
for i=2,5 do check(b.spells[i].cd==10+i,"switching spell does not copy previous field contents"); end
field.scripts.OnEditFocusLost(field);
check(b.spells[5].cd==15,"late focus callback cannot overwrite next spell");
click(p.spellCells[3]);
check(p.inline.fields.radius:IsShown() and not p.inline.fields.targets:IsShown(),"ground spell uses radius instead of nonexistent target cap");
local radius=p.inline.fields.radius; radius:SetFocus(); radius:SetText("15.5"); click(p.spellCells[1]);
check(b.spells[3].radius==15.5 and not b.spells[1].radius,"radius goal remains bound to its own spell");
AZS_SPELLTIPS.frost_trap="Падает на самую плотную группу противников в радиусе 6 м: каждый противник в радиусе 13 м от этой точки получает 24 ед. урона.";
local live={inRun=true,spells={frost_trap={key="frost_trap",rank=2,cdmax=4}},gear={}};
check(A.SpellStats("frost_trap",live).radius==13,"effect radius is not confused with placement range");
local areaBuild={class="HUNTER",spells={{key="frost_trap",rank=0,radius=15.5}},items={}};
check(A.ScoreSpell(areaBuild,{key="frost_trap",lines="a18"},live,1).score>0,"radius upgrade recommended below radius goal");
areaBuild.spells[1].radius=13;
check(A.ScoreSpell(areaBuild,{key="frost_trap",lines="a18"},live,1).score==0,"radius upgrade stops at goal");
AZS_SPELLTIPS.frost_trap=nil;
check(A.GoalStatus(areaBuild.spells[1],A.SpellStats("frost_trap",live)).radius=="unknown","missing live radius never substituted by base radius");
b.items={"quick_strike","south_seas_kelp"}; b.itemRules={}; A.Redraw(); click(p.itemCells.ring[1]);
check(p.inline.fields.value:IsShown() and not p.inline.fields.value2:IsShown(),"single-property ring exposes one goal only");
click(p.itemCells.amulet[1]);
check(p.inline.fields.value:IsShown() and p.inline.fields.value2:IsShown() and not p.inline.fields.value3:IsShown(),"two-property amulet exposes two goals");
local second=p.inline.fields.value2; second:SetFocus(); second:SetText("25"); click(p.itemCells.ring[1]);
check(b.itemRules.south_seas_kelp.value2==25 and b.itemRules.quick_strike.value2==0,"switching jewelry preserves metric ownership");
local legend=A.aliasItem("legend_aimed_shot");
check(legend and A.AvailableTo(legend,"HUNTER") and not A.AvailableTo(legend,"MAGE"),"legend amulets discovered and restricted by spell class");
check(string.find(A.BaseItemText(legend),A.Local("Aimed Shot"),1,true),"class amulet description identifies enhanced spell");
local sameName={}; for _,r in ipairs(A.catalog) do if r.legend and A.AvailableTo(r,"HUNTER") then sameName[r.legend.name]=(sameName[r.legend.name] or 0)+1; end end
local ambiguous; for name,n in pairs(sameName) do if n>1 then ambiguous=name; break end end
check(ambiguous and A.ResolveItem({name=ambiguous},"HUNTER")==nil,"ambiguous class amulet name is not guessed");
local target; for _,r in ipairs(A.catalog) do if r.legend and r.legend.name==ambiguous and A.AvailableTo(r,"HUNTER") then target=r; break end end
local spell=A.byKey["HUNTER:"..target.legend.spell];
check(A.ResolveItem({name=ambiguous,effect=spell.english},"HUNTER")==target,"class amulet resolved by actual enhanced spell description");
local c=A.Copy(b); c.spells[3].radius=15.5; c.itemRules.south_seas_kelp.value3=7; c.itemRules.south_seas_kelp.value6=9;
local decoded,err=A.Decode(A.Export(c));
check(decoded and decoded.spells[3].radius==15.5 and decoded.itemRules.south_seas_kelp.value3==7 and decoded.itemRules.south_seas_kelp.value6==9,err or "radius and six jewelry goals survive export/import");
local rule=A.ItemRule(c,"south_seas_kelp"); rule.value=0; rule.value2=0; rule.value3=30; rule.value6=0;
local itemLive={inRun=true,spells={},gear={{slot="amulet",name="Pristine Enchanted South Seas Kelp",text="+30% luck · +25% gold · +30% damage"}}};
check(A.ScoreItem(c,{name="Pristine Enchanted South Seas Kelp",mode="grow"},itemLive,1).score==0,"third jewelry goal participates in completion checks");
local before=#b.spells; click(p.spellCells[2].remove);
check(#b.spells==before-1,"plan removal takes one click");
local disposable=A.NewBuild("HUNTER"); A.Redraw(); click(p.delete);
local exists=false; for _,build in ipairs(ASAdvisorDB.builds) do if build==disposable then exists=true; end end
check(not exists,"build removal takes one click");
ASAdvisorDB.active.HUNTER=b.id; b.description=string.rep("Длинное описание для проверки переноса. ",30); A.Redraw();
click(p.descriptionButton);
check(p.description.edit.viewport:GetHeight()>100 and p.description.note.viewport:GetHeight()>=60,"description and note retain independent viewports");
check(p.description.note.viewport.point[5]<p.description.noteLabel.point[5]-p.description.noteLabel:GetHeight(),"note input is placed below wrapped label");
click(p.previewButton);
check(p.preview:IsShown() and p.preview.sheet.title:GetText()==b.name and p.preview.sheet.rows[1]:IsShown(),"preview renders build title and plan cards");
check(p.preview.sheet.description:GetHeight()>16,"long preview description wraps naturally");
for i,cell in ipairs(p.preview.sheet.rows) do if cell:IsShown() then for j=1,i-1 do local other=p.preview.sheet.rows[j]; if other:IsShown() then
  local x,y=cell.point[4],-cell.point[5]; local ox,oy=other.point[4],-other.point[5];
  check(x+cell:GetWidth()<=ox+0.01 or ox+other:GetWidth()<=x+0.01 or y+cell:GetHeight()<=oy+0.01 or oy+other:GetHeight()<=y+0.01,"preview tiles never overlap");
end end end end
p.sizing=true; p:SetWidth(760); p:SetHeight(700); p.scripts.OnSizeChanged(p); p.sizing=false;
check(p.work:GetWidth()==728 and p.preview.sheet:GetWidth()==680 and not p.side:IsShown(),"resizing reflows compact screenshot preview");
click(p.preview.back);
check(p.inline:GetWidth()<=p.work:GetWidth() and p.nextCatalog.point[4]+p.nextCatalog:GetWidth()<=p.work:GetWidth(),"narrow editor keeps controls within work area");
click(p.settingsButton); check(p.settings.pickStyle:GetWidth()<=p.work:GetWidth(),"settings adapt to resized window");
click(p.settings.back); A.ToggleUI();
ASAdvisorDB.options.trackerMode="detailed"; ASAdvisorDB.options.trackerWidth=260; ASAdvisorDB.options.trackerHeight=180;
b.items={"south_seas_kelp"}; AZS_GEAR={{slot="amulet",name="Pristine Enchanted South Seas Kelp",text="+30% luck · +25% gold"}};
A.RefreshUI();
check(ASAdvisorTracker:GetWidth()==260 and ASAdvisorTracker:GetHeight()>180,"detailed tracker keeps chosen width and expands to fit every entry");
check(not ASAdvisorTracker.scrollHint:IsShown(),"full detailed tracker needs no scroll affordance");
ASAdvisorTracker.scripts.OnMouseWheel(ASAdvisorTracker,-5); A.RefreshUI();
local wrapped=false; for _,row in ipairs(ASAdvisorTracker.rows) do if row:IsShown() then
  check(-row.detail.point[5]>=row.name:GetHeight(),"tracker details placed below full wrapped name");
  if row.row.group=="amulet" then wrapped=row.name:GetHeight()>12; end
end end
check(wrapped,"long amulet name wraps without colliding with stats");
local oldPayload="HUNTER|Old build|balanced|aimed_shot~1~0~0~0~0~~|quick_strike||quick_strike~ring~9~0~0~~";
local hex=string.gsub(oldPayload,".",function(c) return string.format("%02x",string.byte(c)); end);
local old=A.Decode("ASR3:"..A.Checksum(oldPayload)..":"..hex);
check(old and old.spells[1].radius==0 and old.itemRules.quick_strike.value3==0,"previous ASR3 codes remain importable");
A.ToggleUI(); click(p.spellCells[1]); b.spells[1].note=string.rep("Очень длинная заметка. ",250);
p.spellCells[1].scripts.OnEnter(p.spellCells[1]);
check(p.tip.maxScroll>0 and p.tip:GetHeight()<UIParent:GetHeight(),"long tooltip is bounded and scrollable");
p.spellCells[1].scripts.OnMouseWheel(p.spellCells[1],-1);
check(p.tip.scrollOffset>0,"mouse wheel scrolls overflowing tooltip text");
p.spellCells[1].scripts.OnLeave(p.spellCells[1]);
print("Passed "..count.." v0.4 regression checks");

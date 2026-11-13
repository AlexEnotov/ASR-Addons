-- One compact editor root. Settings/import replace its content instead of stacking windows.
local A=ASAdvisor;
local FONT=GameFontNormal:GetFont();
local function panelOpacity(value,category) return ASRSuite and ASRSuite.GetPanelOpacity and ASRSuite.GetPanelOpacity("builder",value,category) or value; end
local mint={0.88,0.90,0.94,1}; local muted={0.66,0.68,0.72,1}; local text={0.96,0.96,0.97,1}; local pickColor={0.25,1,0.83,1};
local PANEL="Interface\\DialogFrame\\UI-DialogBox-Background";
local BORDER="Interface\\Tooltips\\UI-Tooltip-Border";
local HAS_SKIN=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI");
local WINDOW_BORDER=HAS_SKIN and "Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\border-tooltip" or BORDER;
local function windowBackdrop()
  return {bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=WINDOW_BORDER,tile=true,edgeSize=HAS_SKIN and 32 or 16,insets={left=8,right=8,top=8,bottom=8}};
end
local main,tracker; local layoutBusy=false; local trackerLayoutBusy=false;
local view={tab="spell",class=nil,page=0,buildPage=0,query="",selected=nil,group="spell",mode="editor",editAny=false};
local function label(p,value,size,x,y,w,color)
  local t=p:CreateFontString(nil,"OVERLAY"); t:SetFont(FONT,size or 11,"");
  t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y); if w then t:SetWidth(w); end
  t.asFontSize=size or 11; t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); t:SetTextColor(unpack(color or text)); t:SetText(value or ""); return t;
end
local function box(parent,name,w,h,x,y,alpha)
  local f=CreateFrame("Frame",name,parent); f:SetSize(w,h);
  if x then f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); end
  f:SetBackdrop({bgFile=PANEL,edgeFile=BORDER,tile=true,tileSize=32,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});
  f:SetBackdropColor(0.055,0.055,0.06,alpha or 0); f:SetBackdropBorderColor(0.58,0.58,0.6,0.9); return f;
end
local function button(p,value,w,h,x,y,fn)
  local f=CreateFrame("Button",nil,p); f:SetSize(w,h); f:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=BORDER,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}});
  f:SetBackdropColor(0.075,0.075,0.085,0.98); f:SetBackdropBorderColor(0.48,0.49,0.52,0.9);
  f.text=label(f,value,10,5,0,w-10); f.text:ClearAllPoints(); f.text:SetPoint("CENTER",f,"CENTER",0,0); f.text:SetHeight(h-4); f.text:SetJustifyV("MIDDLE"); f.text:SetJustifyH("CENTER");
  f:SetScript("OnClick",fn);
  f:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(mint)); self:SetBackdropColor(0.16,0.17,0.19,1); end);
  f:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.48,0.49,0.52,0.9); self:SetBackdropColor(0.075,0.075,0.085,0.98); end);
  return f;
end
local function edit(p,w,h,x,y)
  local e=CreateFrame("EditBox",nil,p); e:SetSize(w,h); e:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);
  e:SetFont(FONT,11,""); e:SetAutoFocus(false); e:SetTextInsets(6,6,2,2);
  e:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile=BORDER,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}});
  e:SetBackdropColor(0.025,0.025,0.03,0.95); e:SetBackdropBorderColor(0.38,0.39,0.42,1);
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus(); end); return e;
end
local function placeholder(e,key,width)
  local f=label(e,"",12,8,-6,width,muted); e.placeholder=f;
  local function update()
    f:SetText(A.T(key)); if e:GetText()=="" and not e:HasFocus() then f:Show(); else f:Hide(); end
  end
  local changed=e:GetScript("OnTextChanged"); e:SetScript("OnTextChanged",function(self,...) if changed then changed(self,...); end; update(); end);
  e:SetScript("OnEditFocusGained",update); e:SetScript("OnEditFocusLost",update); e.UpdatePlaceholder=update; update();
end
local function texture(p,path,size,x,y)
  local t=p:CreateTexture(nil,"ARTWORK"); t:SetSize(size,size); t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);
  t:SetTexture(A.Icon(path)); t:SetTexCoord(0.07,0.93,0.07,0.93); return t;
end
local function scrollEdit(parent,name,w,h,x,y)
  local viewport=box(parent,nil,w,h,x,y,0.8);
  local scroll=CreateFrame("ScrollFrame",name,viewport,"UIPanelScrollFrameTemplate");
  scroll:SetPoint("TOPLEFT",viewport,"TOPLEFT",4,-4); scroll:SetSize(w-30,h-8);
  local e=CreateFrame("EditBox",nil,scroll); e:SetMultiLine(true); e:SetAutoFocus(false); e:SetFont(FONT,11,""); e:SetTextInsets(6,6,4,4); e:SetSize(w-32,h-8); e:SetMaxLetters(8000); e:EnableMouse(true); scroll:SetScrollChild(e);
  e.viewport=viewport; e.scroll=scroll;
  e.Fit=function(self)
    local lines=0; local chars=math.max(16,math.floor(self:GetWidth()/6));
    for line in string.gmatch(self:GetText().."\n","(.-)\n") do lines=lines+math.max(1,math.ceil(#line/chars)); end
    self:SetHeight(math.max(self.scroll:GetHeight(),lines*16+12));
  end
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus(); end);
  return e;
end
local function edited() return A.Active(view.class); end
local function status(s) if main then main.status:SetText(A.T(s)); end end
local function refresh() A.dirty=true; if A.Redraw then A.Redraw(); end end
local function stopInteraction(f)
  if not f or not (f.moving or f.sizing) then return; end
  local moving,sizing=f.moving,f.sizing; f:StopMovingOrSizing(); f.moving=false; f.sizing=false;
  if moving and f.positionKey then local point,_,rel,x,y=f:GetPoint(); ASAdvisorDB.options[f.positionKey]={point=point,rel=rel,x=x,y=y}; end
  if sizing and f.SaveSize then f:SaveSize(); end
end
local function resizeCorner(parent)
  local f=CreateFrame("Button",nil,parent); f:SetSize(18,18); f:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-7,7);
  f:SetFrameLevel(parent:GetFrameLevel()+8);
  for i=1,2 do local length=i*5; local t=f:CreateTexture(nil,"OVERLAY"); t:SetTexture(mint[1],mint[2],mint[3],0.65); t:SetSize(length,1); t:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-3,3+i*3);
    local v=f:CreateTexture(nil,"OVERLAY"); v:SetTexture(mint[1],mint[2],mint[3],0.65); v:SetSize(1,length); v:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-3-i*3,3);
  end
  f:SetScript("OnMouseDown",function(_,mouse) if mouse=="LeftButton" then if parent.positionKey=="trackerPos" and ASRSuite and ASRSuite.CanMovePanel and not ASRSuite.CanMovePanel("builder") then return; end; stopInteraction(parent); parent.sizing=true; parent:StartSizing(parent.sizeDirection or "BOTTOMRIGHT"); end end);
  f:SetScript("OnMouseUp",function() stopInteraction(parent); end);
  f:SetScript("OnHide",function() stopInteraction(parent); end);
  return f;
end
function A.CheckPointerRelease()
  if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then stopInteraction(main); stopInteraction(tracker); end
end
local function movable(f,key)
  f.positionKey=key;
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton");
  f:SetScript("OnDragStart",function(self) if key=="trackerPos" and ASRSuite and ASRSuite.CanMovePanel and not ASRSuite.CanMovePanel("builder") then return; end; self.moving=true; self:StartMoving(); end);
  f:SetScript("OnDragStop",function(self) stopInteraction(self); end);
  f:SetScript("OnMouseUp",function(self) stopInteraction(self); end);
  local pos=ASAdvisorDB.options[key];
  if pos then f:SetPoint(pos.point,UIParent,pos.rel,pos.x,pos.y); else f:SetPoint("CENTER",UIParent,"CENTER",0,0); end
end
local function RestoreTipWheel(f)
 if f and f.wheelAnchor then f.wheelAnchor:SetScript("OnMouseWheel",f.wheelScript); f.wheelAnchor:EnableMouseWheel(f.wheelScript~=nil); f.wheelAnchor=nil; f.wheelScript=nil; end
end
-- Tooltips keep their own overlay layer above scrolling tracker rows.
local function tip(root,anchor,title,body)
  if not root.tip then
    root.tip=box(root,nil,300,104,nil,nil,1); root.tip.asrOverlay=true; root.tip:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=BORDER,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}}); root.tip:SetFrameLevel(root:GetFrameLevel()+100); root.tip:SetClampedToScreen(true);
    root.tip.title=label(root.tip,"",12,12,-10,276,mint); root.tip.body=label(root.tip,"",11,12,-34,276,text);
    root.tip.scrollHint=label(root.tip,"",9,12,-90,276,mint);
  end
  local f=root.tip; RestoreTipWheel(f); f:SetFrameStrata("TOOLTIP"); f:SetFrameLevel(math.max(1000,root:GetFrameLevel()+100)); f:SetAlpha(1); local raw=A.Plain(body or "");
  f:ClearAllPoints(); f:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-5); f:SetBackdropColor(0.06,0.06,0.065,1);
  f.title:SetText(title); local width=raw=="" and math.max(80,math.min(300,(f.title.GetStringWidth and f.title:GetStringWidth() or #title*5)+24)) or 300;
  f:SetWidth(width);
  if root==tracker then
    local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale(); local right=root.GetRight and root:GetRight();
    f:ClearAllPoints(); if right and right*ratio+(width+8)*ratio>UIParent:GetWidth()-8 then f:SetPoint("TOPRIGHT",root,"TOPLEFT",-8,-18); else f:SetPoint("TOPLEFT",root,"TOPRIGHT",8,-18); end
  end
  f.title:SetWidth(width-24); f.body:SetWidth(width-24); f.body:SetTextColor(text[1],text[2],text[3],1); f.body:SetAlpha(1);
  f.title:SetHeight(0); local th=math.max(14,f.title.GetStringHeight and f.title:GetStringHeight() or 14); f.title:SetHeight(th);
  f.body:ClearAllPoints(); f.body:SetPoint("TOPLEFT",f,"TOPLEFT",12,-(18+th));
  local limit=math.max(12,math.floor((width-24)/6)); f.lines={};
  for line in string.gmatch(raw.."\n","(.-)\n") do
    local chars={}; for char in string.gmatch(line,".[\128-\191]*") do chars[#chars+1]=char; end
    if #chars==0 then f.lines[#f.lines+1]=""; else
      local from=1; while from<=#chars do local last=math.min(#chars,from+limit-1);
        if last<#chars then for j=last,from+math.floor(limit/2),-1 do if chars[j]==" " then last=j; break end end end
        f.lines[#f.lines+1]=table.concat(chars,"",from,last); from=last+1;
      end
    end
  end
  if raw=="" then f.lines={}; end
  f.visibleLines=math.max(3,math.floor((UIParent:GetHeight()*0.6-th-40)/14));
  f.maxScroll=math.max(0,#f.lines-f.visibleLines)*14; f.scrollOffset=0;
  f.UpdateBody=function(self)
    local first=math.floor(self.scrollOffset/14)+1; local out={};
    for i=first,math.min(#self.lines,first+self.visibleLines-1) do out[#out+1]=self.lines[i]; end
    self.body:SetText(table.concat(out,"\n")); self.body:SetHeight(math.max(1,#out*14));
    self:SetHeight(24+th+#out*14+(self.maxScroll>0 and 18 or 0));
  end
  f:UpdateBody(); f:Show();
  f.wheelAnchor=anchor; f.wheelScript=anchor:GetScript("OnMouseWheel");
  if f.maxScroll>0 then
    f.scrollHint:ClearAllPoints(); f.scrollHint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,6); f.scrollHint:SetText(A.T("Прокрутка колёсиком")); f.scrollHint:Show();
    anchor:EnableMouseWheel(true); anchor:SetScript("OnMouseWheel",function(_,delta) f.scrollOffset=math.max(0,math.min(f.maxScroll,f.scrollOffset-delta*42)); f:UpdateBody(); end);
  else f.scrollHint:Hide(); end
end
local function hideTip(root) if root and root.tip then RestoreTipWheel(root.tip); root.tip:Hide(); end end
local function hint(b,key)
  b:SetScript("OnEnter",function(self) local root=self:GetParent()==tracker and tracker or main; if root then tip(root,self,A.T(key)); end end);
  b:SetScript("OnLeave",function() hideTip(main); hideTip(tracker); end);
end
local function itemTip(root,cell,row)
  if row.addAny then tip(root,cell,"Any",A.T("Любой вариант или выбранный список взаимозаменяемых вариантов.")); return; end
  if row.any then
    local b=root==main and edited() or A.Active(); local p=b and (row.group=="spell" and A.FindPick(b,row.key) or A.ItemRule(b,row.key)); local names={};
    for _,key in ipairs(p and p.options or {}) do local r=row.group=="spell" and A.byKey[b.class..":"..key] or A.aliasItem(key); names[#names+1]=r and r.name or "?"; end
    tip(root,cell,"Any",#names>0 and table.concat(names,", ") or A.T("Любой вариант")); return;
  end
  local desc;
  if row.group=="spell" then
    desc=A.SpellDescription(row,true);
    if A.Snapshot().spells[row.key] then desc=desc.."\n\n"..A.SpellDescription(row); end
  else
    desc=A.BaseItemText(row); local current,source=A.ItemDescription(row,A.Snapshot()); if source=="current" then desc=desc.."\n\n"..current; end
  end
  local b=root==main and edited() or A.Active();
  local p=b and (row.group=="spell" and A.FindPick(b,row.key) or b.itemRules and b.itemRules[row.key]);
  if p and p.note and p.note~="" then desc=(desc and desc.."\n" or "")..p.note; end
  if cell.outside then desc=A.T("Вне билда").."\n\n"..(desc or ""); end
  tip(root,cell,row.name,desc or A.T("В забеге ещё не получено описание. Базовые числа не подставляются."));
end
local CLASS_COORDS={
  WARRIOR={0,0.25,0,0.25},MAGE={0.25,0.5,0,0.25},ROGUE={0.5,0.75,0,0.25},DRUID={0.75,1,0,0.25},
  HUNTER={0,0.25,0.25,0.5},SHAMAN={0.25,0.5,0.25,0.5},PRIEST={0.5,0.75,0.25,0.5},WARLOCK={0.75,1,0.25,0.5},
  PALADIN={0,0.25,0.5,0.75},DEATHKNIGHT={0.25,0.5,0.5,0.75},
};
local function classIcon(t,token)
  local coords=CLASS_COORDS[token];
  if coords then t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); t:SetTexCoord(unpack(coords));
  else t:SetTexture(A.Icon("classicon_"..string.lower(token))); t:SetTexCoord(0.06,0.94,0.06,0.94); end
end
function A.ApplyLayout()
  if not main then return; end
  local o=ASAdvisorDB.options;
  main:SetScale(math.min(o.scale,(UIParent:GetWidth()-24)/main:GetWidth(),(UIParent:GetHeight()-24)/main:GetHeight()));
  main:SetBackdropColor(0.035,0.035,0.04,panelOpacity(o.opacity,"menu"));
  if tracker then tracker:SetBackdropColor(0.04,0.04,0.045,panelOpacity(o.trackerOpacity)); end
end
function A.ResetLayout()
  ASAdvisorDB.options.plannerPos=nil; ASAdvisorDB.options.trackerPos=nil; ASAdvisorDB.options.trackerAnchor=nil; if tracker then tracker.restoreAnchor=nil; end
  ASAdvisorDB.options.plannerWidth=nil; ASAdvisorDB.options.plannerHeight=nil; ASAdvisorDB.options.trackerWidth=280; ASAdvisorDB.options.trackerHeight=280;
  if main then main:SetWidth(880); end
  if main then main:ClearAllPoints(); main:SetPoint("CENTER",UIParent,"CENTER",0,0); end
  if tracker then tracker:ClearAllPoints(); tracker:SetPoint("TOPLEFT",UIParent,"TOPLEFT",18,-150); end
end
local function saveInline()
  if not main or not main.inline then return; end
  local values={};
  for key,e in pairs(main.inline.fields) do
    if e.boundPick and e.pending then
    local raw=string.gsub(A.Trim(e:GetText()),",","."); local n=tonumber(raw=="" and "0" or raw);
    if not n or n~=n or n<0 or n>1000000000 or ((key=="rank" or key=="targets") and (n>999 or n~=math.floor(n))) then status(A.T("Введи положительное число или 0")); return false; end
    values[#values+1]={field=key,pick=e.boundPick,value=n,edit=e};
    end
  end
  for _,v in ipairs(values) do v.pick[v.field]=v.value; v.edit.pending=false; end
  A.dirty=true; return true;
end
local function selectedRow()
  local b=edited(); if not b then return; end
  if view.group=="spell" then
    local p=A.FindPick(b,view.selected); if p then return A.Info(b,p.key,"spell"),p; end
  elseif A.HasItem(b,view.selected) then return A.ItemInfo(b,view.selected),A.ItemRule(b,view.selected); end
end
local function selectPick(row)
  if saveInline()==false then return; end
  for _,e in pairs(main.inline.fields) do e:ClearFocus(); end
  view.selected=row.key; view.group=row.group; view.editAny=false; status(""); refresh();
end
local function buildCell(p,x,y)
  local f=button(p,"",34,34,x,y,function(self) if self.row then selectPick(self.row); end end);
  f.icon=texture(f,nil,30,2,-2); f.number=label(f,"",9,2,-2,13);
  f.anyLabel=label(f,"Any",9,2,-22,30,mint); f.anyLabel:Hide();
  f.remove=button(f,"×",20,20,29,3,function(self)
    local cell=self:GetParent(); local b=edited(); if b and cell.row then
      saveInline(); for _,e in pairs(main.inline.fields) do e:ClearFocus(); end
      if main.inline.pick and main.inline.pick.key==cell.row.key then main.inline.pick=nil; end
      A.RemovePick(b,cell.row.key,cell.row.group); hideTip(main); refresh();
    end
  end);
  f.remove.text:SetTextColor(1,0.55,0.5); f.remove:SetFrameLevel(f:GetFrameLevel()+3); hint(f.remove,"Удалить из билда");
  f.remove:Hide();
  f:SetScript("OnEnter",function(self) if self.row then itemTip(main,self,self.row); end end);
  f:SetScript("OnLeave",function() hideTip(main); end); return f;
end
local function fillPlanCell(cell,row,n)
  cell.row=row;
  if not row then cell:Hide(); return; end
  cell.icon:SetTexture(A.Icon(row.icon)); cell.number:SetText(tostring(n));
  if row.any then cell.anyLabel:Show(); else cell.anyLabel:Hide(); end
  cell:SetBackdropBorderColor(unpack(view.selected==row.key and view.group==row.group and mint or {0.14,0.24,0.28,0.7})); cell:Show();
end
local function showMode(mode)
  stopInteraction(main); view.mode=mode;
  if main.quickDescription then main.quickDescription.edit:ClearFocus(); end
  if main.description then main.description.edit:ClearFocus(); main.description.note:ClearFocus(); end
  if main.caps then for _,field in pairs(main.caps.fields) do field:ClearFocus(); end end
  main:SetWidth(ASAdvisorDB.options[mode=="preview" and "previewWidth" or "plannerWidth"] or (mode=="preview" and 760 or 880));
  main:SetMinResize(760,mode=="preview" and 340 or 500); status(""); hideTip(main); refresh();
end
local function createMain()
  main=box(UIParent,"ASAdvisorPlanner",880,529,nil,nil,0.85); main:SetFrameStrata("DIALOG"); main:SetFrameLevel(30); movable(main,"plannerPos");
  main:SetBackdrop(windowBackdrop()); main:SetBackdropBorderColor(0.75,0.75,0.77,1);
  main:SetWidth(ASAdvisorDB.options.plannerWidth or 880);
  main:SetScript("OnHide",function() stopInteraction(main); saveInline(); if main.inline then for _,e in pairs(main.inline.fields) do e:ClearFocus(); end end; hideTip(main); end);
  if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ASAdvisorPlanner"; end
  main.brand=label(main,"ASR / ADVISOR",19,24,-30,240,mint);
  main.credit=label(main,"by AlexEnotov",9,25,-60,240,muted);
  main.brand:SetHeight(26); main.credit:SetHeight(14);
  main.settingsButton=button(main,"",110,28,710,-10,function() saveInline(); showMode(view.mode=="settings" and "editor" or "settings"); end);
  main.descriptionButton=button(main,"",118,28,582,-10,function() saveInline(); showMode(view.mode=="description" and "editor" or "description"); end);
  main.previewButton=button(main,"",104,28,468,-10,function() saveInline(); showMode(view.mode=="preview" and "editor" or "preview"); end);
  main.close=button(main,"×",32,28,832,-10,function() saveInline(); main:Hide(); end);
  main.side=box(main,nil,176,466,12,-52);
  main.work=CreateFrame("Frame",nil,main); main.work:SetSize(660,466); main.work:SetPoint("TOPLEFT",main,"TOPLEFT",204,-52);
  main.classButtons={};
  for i,c in ipairs(AZS_GEN.classes) do
    local token=c.token;
    local f=button(main.side,"",32,32,10+((i-1)%4)*39,-10-math.floor((i-1)/4)*37,function()
      saveInline(); view.class=token; view.selected=nil; view.page=0; view.buildPage=0; refresh();
    end);
    f.icon=texture(f,nil,28,2,-2); classIcon(f.icon,token);
    f:SetScript("OnEnter",function(self) tip(main,self,A.ClassName(token)); end); f:SetScript("OnLeave",function() hideTip(main); end);
    main.classButtons[token]=f;
  end
  main.buildsLabel=label(main.side,"",10,10,-134,156,muted);
  main.buildRows={};
  for i=1,4 do
    local f=button(main.side,"",156,36,10,-153-(i-1)*40,function(self) saveInline(); ASAdvisorDB.active[view.class]=self.build.id; view.selected=nil; view.editAny=false; refresh(); end);
    f.text:SetJustifyH("LEFT"); f.text:SetHeight(28); main.buildRows[i]=f;
  end
  main.prevBuild=button(main.side,"‹",32,26,10,-318,function() view.buildPage=math.max(0,view.buildPage-1); refresh(); end);
  main.buildPage=label(main.side,"",10,48,-325,70,muted); main.buildPage:SetJustifyH("CENTER");
  main.nextBuild=button(main.side,"›",32,26,134,-318,function() view.buildPage=view.buildPage+1; refresh(); end);
  main.new=button(main.side,"",46,30,10,-352,function() saveInline(); local b=A.NewBuild(view.class); b.name=A.ClassName(view.class).." · "..A.T("Билд"); view.selected=nil; refresh(); end); hint(main.new,"Новый билд");
  main.clone=button(main.side,"",46,30,65,-352,function()
    local b=edited(); if b then saveInline(); local c=A.Copy(b); c.id=ASAdvisorDB.nextId; ASAdvisorDB.nextId=c.id+1; c.name=c.name.." +"; ASAdvisorDB.builds[#ASAdvisorDB.builds+1]=c; ASAdvisorDB.active[c.class]=c.id; refresh(); end
  end); hint(main.clone,"Копировать билд");
  main.delete=button(main.side,"",46,30,120,-352,function()
    local b=edited(); if not b then return; end
    saveInline(); for _,e in pairs(main.inline.fields) do e.boundPick=nil; e.pending=false; e:ClearFocus(); end
    for i,v in ipairs(ASAdvisorDB.builds) do if v==b then table.remove(ASAdvisorDB.builds,i); break end end
    main.inline.pick=nil; ASAdvisorDB.active[b.class]=nil; view.selected=nil; A.deleteId=nil; refresh();
  end); hint(main.delete,"Удалить билд");
  main.capture=button(main.side,"",156,28,10,-392,function() local b,err=A.Capture(); if b then view.class=b.class; view.selected=nil; refresh(); else status(err); end end);
  main.import=button(main.side,"",75,28,10,-430,function() A.ShowCode("import"); end);
  main.export=button(main.side,"",75,28,91,-430,function() A.ShowCode("export"); end);
  main.editor=CreateFrame("Frame",nil,main.work); main.editor:SetAllPoints(main.work);
  local w=main.editor;
  main.name=edit(w,360,26,4,-3); main.name:SetMaxLetters(80);
  local function saveName(self) local b=self.boundBuild; if b and A.Trim(self:GetText())~="" then b.name=A.Trim(self:GetText()); end end
  main.name:SetScript("OnEditFocusLost",saveName);
  main.name:SetScript("OnEnterPressed",function(self) saveName(self); self:ClearFocus(); refresh(); end);
  main.classLabel=label(w,"",12,380,-9,274,muted);
  main.tabs={};
  for i,t in ipairs({{"spell","Умения"},{"ring","Кольца"},{"trinket","Аксессуары"},{"amulet","Амулеты"}}) do
    local key=t[1]; local f=button(w,"",98,28,4+(i-1)*104,-40,function() view.tab=key; view.page=0; view.editAny=false; refresh(); end);
    f.translation=t[2]; main.tabs[key]=f;
  end
  main.search=edit(w,232,28,424,-40); main.search:SetText("");
  main.search:SetScript("OnTextChanged",function(self) view.query=A.Lower(self:GetText()); view.page=0; refresh(); end);
  placeholder(main.search,"Поиск",160);
  main.searchCaption=label(w,"",9,426,-29,228,muted);
  main.catalogRows={};
  for i=1,192 do
    local f=button(w,"",34,34,4+((i-1)%12)*42,-68-math.floor((i-1)/12)*40,function(self)
      if not self.row then return; end
      local b=edited(); if not b then b=A.NewBuild(view.class); end
      local row,p=selectedRow(); local err;
      if view.editAny and p and p.any and row.group==view.tab then
        if self.row.addAny then p.options={}; else
          local found; for j,key in ipairs(p.options or {}) do if key==self.row.key then found=j; end end
          p.options=p.options or {}; if found then table.remove(p.options,found); else p.options[#p.options+1]=self.row.key; end
        end
      elseif self.row.addAny then
        local key; key,err=A.AddAny(b,view.tab); if key then view.selected=key; view.group=view.tab; end
      else err=A.Toggle(b,self.row); view.selected=self.row.key; view.group=self.row.group; end
      refresh(); if err then status(err); end
    end);
    f.icon=texture(f,nil,30,2,-2); f.mark=label(f,"",11,20,-20,14,mint);
    f:SetScript("OnEnter",function(self) if self.row then itemTip(main,self,self.row); end end);
    f:SetScript("OnLeave",function() hideTip(main); end); main.catalogRows[i]=f;
  end
  main.prevCatalog=button(w,"‹",32,24,4,-184,function() view.page=math.max(0,view.page-1); refresh(); end);
  main.catalogPage=label(w,"",9,42,-190,570,muted); main.catalogPage:SetJustifyH("CENTER");
  main.nextCatalog=button(w,"›",32,24,624,-184,function() view.page=view.page+1; refresh(); end);
  main.planHeading=label(w,"",10,4,-215,440,muted);
  main.planLeft=button(w,"‹",36,28,574,-211,function() local row=selectedRow(); if row then saveInline(); A.MovePick(edited(),row.key,row.group,-1); refresh(); end end); hint(main.planLeft,"Выше по приоритету");
  main.planRight=button(w,"›",36,28,620,-211,function() local row=selectedRow(); if row then saveInline(); A.MovePick(edited(),row.key,row.group,1); refresh(); end end); hint(main.planRight,"Ниже по приоритету");
  main.spellCells={}; for i=1,6 do main.spellCells[i]=buildCell(w,4+(i-1)*51,-225); end
  main.planHint=label(w,"",10,340,-235,310,muted); main.planHint:SetHeight(36);
  main.itemLabels={ring=label(w,"",10,4,-294,100,muted),trinket=label(w,"",10,112,-294,120,muted),amulet=label(w,"",10,226,-294,498,muted)};
  main.itemCells={ring={},trinket={},amulet={}};
  for _,g in ipairs({"ring","trinket","amulet"}) do
    local start=({ring=4,trinket=112,amulet=226})[g];
    for i=1,(g=="amulet" and 8 or 2) do main.itemCells[g][i]=buildCell(w,start+(i-1)*51,-312); end
  end
  -- Four thresholds are always inline; selecting a spell never opens a second window.
  main.inline=box(w,nil,652,100,4,-365); main.inline.fields={}; main.inline.captions={};
  main.inline.title=label(main.inline,"",11,9,-8,420,mint); main.inline.title:SetHeight(16);
  main.inline.remove=button(main.inline,"",58,22,580,-5,function() local row=selectedRow(); if row then saveInline(); A.RemovePick(edited(),row.key,row.group); view.selected=nil; refresh(); end end);
  for i,f in ipairs({{"rank","Ранг"},{"cd","КД ≤, сек."},{"damage","Урон ≥"},{"targets","Целей ≥"},{"radius","Радиус ≥, м"},{"duration","Длительность ≥, сек."},{"value","Бонус 1 ≥"},{"value2","Бонус 2 ≥"},{"value3","Бонус 3 ≥"},{"value4","Бонус 4 ≥"},{"value5","Бонус 5 ≥"},{"value6","Бонус 6 ≥"}}) do
    main.inline.captions[f[1]]=label(main.inline,"",9,9+(i-1)*100,-7,96,muted);
    local e=edit(main.inline,88,23,9+(i-1)*100,-23); main.inline.fields[f[1]]=e;
    e:SetScript("OnEnterPressed",function(self) if saveInline() then self:ClearFocus(); refresh(); end end);
    e:SetScript("OnEditFocusLost",function() saveInline(); end);
    e:SetScript("OnTextChanged",function(self) if not main.bindingInline then self.pending=true; end end);
  end
  main.inline.base=label(main.inline,"",10,9,-81,630,text); main.inline.base:SetHeight(28);
  main.inline.current=label(main.inline,"",10,9,-112,630,muted); main.inline.current:SetHeight(28);
  main.inline.help=label(main.inline,"",9,9,-145,630,muted); main.inline.help:SetHeight(20);
  main.inline.any=button(main.inline,"",200,25,420,-88,function() view.editAny=not view.editAny; view.tab=view.group; view.page=0; refresh(); end);
  main.inline.itemHelp=label(main.inline,"",11,12,-40,630,muted); main.inline.itemHelp:SetHeight(60);
  main.quickDescription=CreateFrame("Frame",nil,w);
  main.quickDescription.title=label(main.quickDescription,"",12,10,-9,220,mint);
  main.quickDescription.more=button(main.quickDescription,"",96,24,180,-4,function() saveInline(); showMode("description"); end);
  main.quickDescription.edit=scrollEdit(main.quickDescription,"ASAdvisorQuickDescription",300,210,0,-36);
  local quick=main.quickDescription.edit; placeholder(quick,"Нажми здесь и напиши описание билда: порядок выбора, особенности и советы.",270);
  quick:SetScript("OnTextChanged",function(self)
    if not main.bindingDescription and self.boundBuild then self.boundBuild.description=self:GetText(); A.dirty=true; end
    self:Fit(); if self.UpdatePlaceholder then self.UpdatePlaceholder(); end
  end);
  main.settings=CreateFrame("Frame","ASAdvisorSettings",main.work); main.settings:SetAllPoints(main.work);
  main.settings.title=label(main.settings,"",18,14,-14,630,mint);
  main.settings.language=label(main.settings,"",11,14,-62,220);
  main.settings.languageSelect=button(main.settings,"",294,30,310,-54,function() end);
  ASRLocale.Bind(main.settings.languageSelect,function() return ASAdvisorDB.options.language; end,function(code) if ASRSuite and ASRSuite.ready then ASRSuite.SetLanguage(code); else A.SetLanguage(code); end end);
  main.settings.enabled=button(main.settings,"",160,24,444,-14,function() local on=ASAdvisorDB.options.enabled==false; ASAdvisorDB.options.enabled=on; if ASRSuite and ASRSuite.SetModuleEnabled then ASRSuite.SetModuleEnabled("builder",on); end; refresh(); A.RefreshUI(); end);
  main.settings.steps={};
  for i,s in ipairs({{"opacity","Фон редактора",0.15,1,0.05},{"trackerOpacity","Фон трекера",0.1,1,0.05},{"scale","Масштаб редактора",0.55,1.3,0.05},{"trackerScale","Масштаб трекера",0.5,1.3,0.05}}) do
    local key,low,high,step=s[1],s[3],s[4],s[5]; local y=-100-(i-1)*43;
    local r={caption=label(main.settings,"",11,14,y-8,260),value=label(main.settings,"",12,377,y-8,130,mint),translation=s[2]}; r.value:SetJustifyH("CENTER");
    r.minus=button(main.settings,"−",44,30,310,y,function() ASAdvisorDB.options[key]=math.max(low,ASAdvisorDB.options[key]-step); A.ApplyLayout(); refresh(); A.RefreshUI(); end);
    r.plus=button(main.settings,"+",44,30,560,y,function() ASAdvisorDB.options[key]=math.min(high,ASAdvisorDB.options[key]+step); A.ApplyLayout(); refresh(); A.RefreshUI(); end);
    main.settings.steps[key]=r;
  end
  main.settings.pickStyle=button(main.settings,"",590,30,14,-276,function()
    local nextStyle={inline="band",band="arrow",arrow="inline"};
    ASAdvisorDB.options.pickStyle=nextStyle[ASAdvisorDB.options.pickStyle] or "inline"; refresh(); A.RefreshUI();
  end);
  main.settings.tracker=button(main.settings,"",282,30,14,-322,function() ASAdvisorDB.options.trackerHidden=not ASAdvisorDB.options.trackerHidden; refresh(); end);
  main.settings.reset=button(main.settings,"",282,30,322,-365,function() A.ResetLayout(); refresh(); end);
  main.settings.data=button(main.settings,"",282,30,322,-408,function() A.ShowCode("debug"); end); hint(main.settings.data,"Сведения для поиска ошибок аддона. Не влияют на игру.");
  main.settings.trackerMode=button(main.settings,"",282,30,322,-322,function() ASAdvisorDB.options.trackerMode=ASAdvisorDB.options.trackerMode=="compact" and "detailed" or "compact"; refresh(); A.RefreshUI(); end);
  main.settings.exportAll=button(main.settings,"",282,30,14,-365,function() A.ShowCode("library"); end);
  main.settings.back=button(main.settings,"",282,30,14,-408,function() showMode("editor"); end);
  main.settings.caps=button(main.settings,"",282,30,14,-365,function() showMode("caps"); end);
  main.caps=CreateFrame("Frame","ASAdvisorStatCaps",main.work); main.caps:SetAllPoints(main.work); main.caps.fields={}; main.caps.labels={};
  main.caps.title=label(main.caps,"",18,14,-14,620,mint); main.caps.help=label(main.caps,"",10,14,-46,620,muted); main.caps.help:SetHeight(34);
  for i,stat in ipairs(A.CapStats) do local key=stat[1]; main.caps.labels[key]=label(main.caps,"",10,14,-90,200,text); main.caps.labels[key]:SetHeight(28);
    local e=edit(main.caps,62,24,225,-90); main.caps.fields[key]=e;
    local function save(self)
      local raw=string.gsub(A.Trim(self:GetText()),",","."); local value=tonumber(raw=="" and "0" or raw);
      if not value or value~=value or value<0 or value>1e9 then status(A.T("Введи положительное число или 0")); return false; end
      ASAdvisorDB.options.statCaps[key]=value; A.dirty=true; return true;
    end
    e:SetScript("OnEditFocusLost",save); e:SetScript("OnEnterPressed",function(self) if save(self) then self:ClearFocus(); refresh(); A.RefreshUI(); end end);
  end
  main.caps.back=button(main.caps,"",160,28,14,-414,function() showMode("settings"); end);
  main.code=CreateFrame("Frame","ASAdvisorCodeDialog",main.work); main.code:SetAllPoints(main.work);
  main.code.title=label(main.code,"",18,14,-12,630,mint); main.code.help=label(main.code,"",11,14,-43,630,muted);
  local scroll=CreateFrame("ScrollFrame","ASAdvisorCodeScroll",main.code,"UIPanelScrollFrameTemplate"); main.code.scroll=scroll; scroll:SetPoint("TOPLEFT",main.code,"TOPLEFT",14,-80); scroll:SetSize(610,285);
  local e=CreateFrame("EditBox",nil,scroll); e:SetMultiLine(true); e:SetAutoFocus(false); e:SetFont(FONT,11,""); e:SetWidth(605); e:SetHeight(285); e:SetMaxLetters(1000000);
  e:SetScript("OnTextChanged",function(self) local lines=0; for line in string.gmatch(self:GetText().."\n","(.-)\n") do lines=lines+math.max(1,math.ceil(#line/80)); end; self:SetHeight(math.max(285,lines*15)); end);
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus(); showMode("editor"); end); scroll:SetScrollChild(e); main.code.edit=e;
  main.code.message=label(main.code,"",11,14,-385,630,muted);
  main.code.apply=button(main.code,"",145,26,14,-420,function()
    local b,err,count=A.Import(e:GetText()); if not b then main.code.message:SetText(A.T(err)); return; end
    view.class=b.class; view.selected=nil; showMode("editor"); status(A.T("Импортировано")..": "..tostring(count or 1));
  end);
  main.code.back=button(main.code,"",110,28,530,-420,function() showMode("editor"); end);
  main.description=CreateFrame("Frame","ASAdvisorDescription",main.work); main.description:SetAllPoints(main.work);
  main.description.title=label(main.description,"",18,14,-14,630,mint);
  main.description.edit=scrollEdit(main.description,"ASAdvisorDescriptionScroll",630,205,14,-55); local de=main.description.edit;
  de:SetScript("OnTextChanged",function(self)
    if not main.bindingDescription and self.boundBuild then self.boundBuild.description=self:GetText(); end
    self:Fit();
  end);
  main.description.noteLabel=label(main.description,"",11,14,-285,630,muted);
  main.description.note=scrollEdit(main.description,"ASAdvisorNoteScroll",630,90,14,-308); main.description.note:SetMaxLetters(2000);
  main.description.note:SetScript("OnTextChanged",function(self) if not main.bindingDescription and self.boundPick then self.boundPick.note=self:GetText(); end; self:Fit(); end);
  placeholder(de,"Нажми здесь и напиши описание билда: порядок выбора, особенности и советы.",585);
  placeholder(main.description.note,"Нажми здесь, чтобы добавить заметку к выбранному элементу.",600);
  main.description.back=button(main.description,"",110,28,14,-420,function() showMode("editor"); end);
  main.preview=CreateFrame("Frame","ASAdvisorPreview",main.work); main.preview:SetAllPoints(main.work);
  main.preview.scroll=CreateFrame("ScrollFrame","ASAdvisorPreviewScroll",main.preview,"UIPanelScrollFrameTemplate"); main.preview.scroll:SetPoint("TOPLEFT",main.preview,"TOPLEFT",0,0); main.preview.scroll:SetSize(630,400);
  main.preview.sheet=box(main.preview.scroll,nil,628,400,nil,nil,1); main.preview.sheet:SetBackdropColor(0.018,0.035,0.05,1); main.preview.scroll:SetScrollChild(main.preview.sheet);
  local sheet=main.preview.sheet;
  sheet.brand=label(sheet,"ASR / ADVISOR",10,16,-14,300,mint); sheet.title=label(sheet,"",23,16,-40,590); sheet.class=label(sheet,"",11,16,-75,590,mint);
  sheet.description=label(sheet,"",11,16,-100,590,muted); sheet.rows={};
  main.preview.export=button(main.preview,"",180,30,0,-420,function() A.ShowCode("export"); end);
  main.preview.back=button(main.preview,"",110,30,190,-420,function() showMode("editor"); end);
  main.resize=resizeCorner(main);
  main:SetResizable(true); main:SetMinResize(760,500); main:SetMaxResize(1240,1000);
  main.SaveSize=function(self)
    local prefix=view.mode=="preview" and "preview" or "planner";
    ASAdvisorDB.options[prefix.."Width"]=self:GetWidth(); ASAdvisorDB.options[prefix.."Height"]=self:GetHeight(); refresh();
  end;
  main:SetScript("OnSizeChanged",function(self) if self.sizing and not layoutBusy then self:SaveSize(); end end);
  main.status=label(main,"",9,204,-522,650,muted);
  main:Hide(); A.ApplyLayout();
end
local function ensure()
  if not main then view.class=A.Class(); createMain(); end
end
local function move(f,x,y)
  f:ClearAllPoints(); f:SetPoint("TOPLEFT",f:GetParent(),"TOPLEFT",x,-y);
end
local function measured(t,minHeight)
  local value=t:GetText() or "";
  if value=="" then local h=minHeight or 0; t:SetHeight(h); return h; end
  t:SetHeight(0); local h=t.GetStringHeight and t:GetStringHeight() or minHeight or 14;
  local size=t.asFontSize or 11; local capacity=math.max(1,math.floor(t:GetWidth()/(size*0.62))); local lines=0;
  for line in string.gmatch(value.."\n","(.-)\n") do
    local _,chars=string.gsub(line,"[^\128-\191]",""); lines=lines+math.max(1,math.ceil(chars/capacity));
  end
  h=math.ceil(math.max(minHeight or 14,h,lines*(size+3)))+2; t:SetHeight(h); return h;
end
local function previewBuild(b,width)
  local page=main.preview; local sheet=page.sheet; local ink={0.97,0.97,0.98,1}; local secondary={0.77,0.79,0.83,1};
  sheet:SetWidth(math.min(720,width-48)); sheet:ClearAllPoints(); sheet:SetPoint("TOP",page.scroll,"TOP",0,0);
  sheet:SetBackdrop(windowBackdrop()); sheet:SetBackdropColor(0.035,0.035,0.04,1); sheet:SetBackdropBorderColor(0.75,0.75,0.77,1);
  local inner=sheet:GetWidth()-48;
  if not sheet.crest then
    sheet.crest=box(sheet,nil,62,62,20,-27,0); sheet.crest.icon=texture(sheet.crest,nil,52,5,-5);
    sheet.author=label(sheet,"by AlexEnotov",10,20,-420,inner,secondary);
    sheet.rule=sheet:CreateTexture(nil,"ARTWORK"); sheet.rule:SetTexture(0.55,0.56,0.59,0.6); sheet.rule:SetHeight(1);
    sheet.headerRule=sheet:CreateTexture(nil,"ARTWORK"); sheet.headerRule:SetTexture(0.5,0.52,0.56,0.6); sheet.headerRule:SetHeight(1);
    sheet.footerBrand=label(sheet,"ASR ADVISOR",9,24,-420,200,secondary);
  end
  move(sheet.crest,24,28); sheet.crest:SetSize(72,72); sheet.crest.icon:SetSize(56,56); sheet.crest.icon:ClearAllPoints(); sheet.crest.icon:SetPoint("TOPLEFT",sheet.crest,"TOPLEFT",8,-8);
  classIcon(sheet.crest.icon,view.class); sheet.crest:SetBackdropBorderColor(0.65,0.66,0.7,1);
  sheet.brand:SetText("AZEROTH SURVIVORS REBORN"); move(sheet.brand,112,27); sheet.brand:SetTextColor(unpack(secondary));
  sheet.title:SetWidth(inner-88); sheet.title:SetFont(FONT,24,""); sheet.title.asFontSize=24; sheet.title:SetTextColor(unpack(ink)); sheet.title:SetText(b and b.name or A.T("Сначала создай билд")); local titleH=measured(sheet.title,28); move(sheet.title,112,45);
  move(sheet.class,112,53+titleH); sheet.class:SetWidth(inner-88); sheet.class:SetText(A.ClassName(view.class)); sheet.class:SetTextColor(unpack(secondary));
  local y=math.max(110,72+titleH); sheet.description:SetWidth(inner); move(sheet.description,24,y); sheet.description:SetTextColor(unpack(ink));
  if b and b.description and b.description~="" then
    local chars={}; for char in string.gmatch(b.description,".[\128-\191]*") do chars[#chars+1]=char; end
    local length=math.min(#chars,math.max(40,math.floor(inner/6.82)*3)); local shortened=length<#chars;
    sheet.description:SetText(table.concat(chars,"",1,length)..(shortened and "..." or "")); local dh=measured(sheet.description,14);
    while dh>50 and length>20 do length=length-5; shortened=true; sheet.description:SetText(table.concat(chars,"",1,length).."..."); dh=measured(sheet.description,14); end
    sheet.description:Show(); y=y+dh+12;
  else sheet.description:Hide(); end
  sheet.headerRule:ClearAllPoints(); sheet.headerRule:SetPoint("TOPLEFT",sheet,"TOPLEFT",24,-y); sheet.headerRule:SetWidth(inner); y=y+12;
  for _,cell in ipairs(sheet.rows) do cell:Hide(); end
  sheet.sections=sheet.sections or {}; local cellIndex=0;
  local function section(group,x,top,space,columns)
    local entries={};
    if group=="spell" then for i,pick in ipairs(b and b.spells or {}) do entries[#entries+1]={row=A.Info(b,pick.key,"spell"),pick=pick,number=i}; end
    else local n=0; for _,key in ipairs(b and b.items or {}) do local row=A.ItemInfo(b,key); if row and row.group==group then n=n+1; entries[#entries+1]={row=row,pick=A.ItemRule(b,key),number=n}; end end end
    local heading=sheet.sections[group]; if not heading then heading=label(sheet,"",11,x,-top,space,ink); sheet.sections[group]=heading; end
    if #entries==0 then heading:Hide(); return top; end
    move(heading,x,top); heading:SetWidth(space); heading:SetTextColor(unpack(ink)); heading:SetText(A.T(({spell="Умения",ring="Кольца",trinket="Аксессуары",amulet="Запасные амулеты"})[group]).."  ·  "..#entries); heading:Show(); top=top+21;
    local cardWidth=(space-(columns-1)*8)/columns;
    for i=1,#entries,columns do local rowHeight=0; local first=cellIndex+1;
      for j=i,math.min(i+columns-1,#entries) do
        local entry=entries[j]; cellIndex=cellIndex+1; local cell=sheet.rows[cellIndex];
        if not cell then
          cell=box(sheet,nil,cardWidth,48,x,-top,0.1); cell.icon=texture(cell,nil,30,7,-7); cell.title=label(cell,"",10,44,-7,cardWidth-51,ink); cell.goals=label(cell,"",9,44,-25,cardWidth-51,secondary); cell.body=label(cell,"",9,7,-45,cardWidth-14,secondary); sheet.rows[cellIndex]=cell;
          cell.slot=box(cell,nil,34,34,5,-5,0); cell.slot:SetBackdrop({edgeFile=BORDER,edgeSize=8}); cell.slot:SetBackdropBorderColor(0.6,0.62,0.66,0.9);
          cell.order=label(cell.slot,"",8,1,-1,14,ink);
          cell:EnableMouse(true); cell:SetScript("OnEnter",function(self) if self.row then itemTip(main,self,self.row); end end); cell:SetScript("OnLeave",function() hideTip(main); end);
        end
        cell:SetBackdrop(nil); cell.order:SetText(tostring(entry.number));
        cell.row=entry.row; cell:SetWidth(cardWidth); move(cell,x+((j-i)%columns)*(cardWidth+8),top);
        cell.title:SetWidth(cardWidth-51); cell.title:SetTextColor(unpack(ink)); cell.goals:SetTextColor(unpack(secondary)); cell.goals:SetWidth(cardWidth-51); cell.icon:SetTexture(A.Icon(entry.row.icon));
        cell.title:SetText(entry.row.name); local th=measured(cell.title,14);
        local goalText=A.GoalText(entry.pick,group); local hasGoals=goalText~=A.T("Без ограничения");
        move(cell.goals,44,9+th); cell.goals:SetText(hasGoals and goalText or ""); if hasGoals then cell.goals:Show(); else cell.goals:Hide(); end
        local gh=hasGoals and measured(cell.goals,12) or 0; cell.body:SetText(""); cell.body:Hide();
        rowHeight=math.max(rowHeight,math.max(38,(hasGoals and 13 or 11)+th+gh)); cell:Show();
      end
      for n=first,cellIndex do sheet.rows[n]:SetHeight(rowHeight); end; top=top+rowHeight+2;
    end
    return top+6;
  end
  y=section("spell",24,y,inner,2);
  local half=(inner-18)/2; local left=section("ring",24,y,half,1); local right=section("trinket",42+half,y,half,1); y=math.max(left,right);
  y=section("amulet",24,y,inner,3);
  sheet.rule:ClearAllPoints(); sheet.rule:SetPoint("TOPLEFT",sheet,"TOPLEFT",24,-y); sheet.rule:SetWidth(inner);
  move(sheet.author,24,y+14); sheet.author:SetWidth(inner); sheet.author:SetJustifyH("RIGHT"); sheet.author:SetText("by AlexEnotov"); sheet.author:SetTextColor(unpack(secondary));
  move(sheet.footerBrand,24,y+14); sheet.footerBrand:SetTextColor(unpack(secondary));
  sheet:SetHeight(y+54); page.export.text:SetText(A.T("Скопировать код билда")); page.back.text:SetText(A.T("Назад"));
end
function A.Redraw()
  if not main or not main:IsShown() or layoutBusy then return; end; layoutBusy=true;
  view.class=view.class or A.Class(); local b=edited();
  local width=main:GetWidth(); local workWidth=width-(view.mode=="preview" and 32 or 220);
  move(main.work,view.mode=="preview" and 16 or 204,84); move(main.side,12,84); if view.mode=="preview" then main.side:Hide(); main.status:Hide(); else main.side:Show(); main.status:Show(); end
  local columns=math.max(8,math.floor((workWidth-4)/42));
  local list={{key="@new",name="Any",group=view.tab,addAny=true,icon="INV_Misc_QuestionMark"}};
  for _,r in ipairs(A.catalog) do if r.group==view.tab and (r.group~="spell" or r.class==view.class) and A.AvailableTo(r,view.class) and (view.query=="" or string.find(A.Lower(r.name),view.query,1,true) or string.find(r.key,view.query,1,true)) then list[#list+1]=r; end end
  if view.tab=="amulet" then table.sort(list,function(x,y) if x==y then return false; elseif x.addAny then return true; elseif y.addAny then return false; end; local xm,ym=ASAdvisorMechanics.items[x.key],ASAdvisorMechanics.items[y.key]; local xc=xm and xm.classes and #xm.classes>0 or false; local yc=ym and ym.classes and #ym.classes>0 or false; if xc~=yc then return not xc; end; return x.name<y.name; end); end
  local rowBudget=math.max(3,math.floor(((ASAdvisorDB.options.plannerHeight or 650)-500)/40));
  local capacity=math.min(#main.catalogRows,columns*rowBudget); main.catalogCapacity=capacity;
  local catalogRows=math.max(1,math.ceil(math.min(#list,capacity)/columns)); local nav=68+catalogRows*40;
  local plan=nav+25; local spellY=plan+20; local itemLabel=spellY+40; local itemY=itemLabel+17; local inlineY=itemY+44;
  local amuletColumns=math.max(1,math.floor((workWidth-172)/40)); local amulets=0; for _,key in ipairs(b and b.items or {}) do local row=A.ItemInfo(b,key); if row and row.group=="amulet" then amulets=amulets+1; end end
  inlineY=inlineY+math.max(0,math.ceil(amulets/amuletColumns)-1)*40;
  local height=view.mode=="preview" and math.max(340,ASAdvisorDB.options.previewHeight or 520) or math.max(view.mode=="editor" and (inlineY+320+110) or 540,ASAdvisorDB.options.plannerHeight or 0);
  main:SetHeight(height); main.side:SetHeight(height-112); main.work:SetSize(workWidth,height-100); move(main.status,280,66); main.status:SetWidth(width-310); main.status:SetHeight(14); A.ApplyLayout();
  move(main.close,width-56,28); move(main.settingsButton,width-178,28); move(main.descriptionButton,width-306,28); move(main.previewButton,width-420,28);
  main.name:SetWidth(workWidth-290); move(main.classLabel,workWidth-274,9); main.previewButton.text:SetText(A.T("Превью"));
  for i,key in ipairs({"spell","ring","trinket","amulet"}) do local bw=(workWidth-12)/4; move(main.tabs[key],4+(i-1)*(bw+2),34); main.tabs[key]:SetSize(bw,25); main.tabs[key].text:SetWidth(bw-10); end
  main.search:Show(); main.search:SetWidth(180); move(main.search,workWidth-180,3); main.name:SetWidth(workWidth-194); main.classLabel:Hide(); main.searchCaption:Hide();
  local s=main.settings; local right=workWidth-16; local half=(workWidth-42)/2;
  move(s.languageSelect,right-294,54);
  for _,r in pairs(s.steps) do move(r.minus,right-294,-select(5,r.minus:GetPoint())); move(r.plus,right-44,-select(5,r.plus:GetPoint())); r.value:ClearAllPoints(); r.value:SetPoint("CENTER",r.minus,"CENTER",132,0); r.caption:SetWidth(right-320); end
  s.pickStyle:SetWidth(math.min(360,workWidth-28)); s.pickStyle.text:SetWidth(s.pickStyle:GetWidth()-18);
  local actionWidth=math.min(240,half);
  for _,pair in ipairs({{s.tracker,s.trackerMode,322},{s.caps,s.reset,365},{s.exportAll,s.back,408}}) do for i=1,2 do pair[i]:SetWidth(actionWidth); pair[i].text:SetWidth(actionWidth-16); move(pair[i],14+(i-1)*(actionWidth+18),pair[3]); end end; s.data:Hide();
  move(main.settings.enabled,workWidth-174,14);
  main.caps.help:SetWidth(workWidth-28); move(main.caps.back,14,height-142);
  local d=main.description; local descH=math.max(120,math.floor((height-240)*0.58));
  for _,info in ipairs({{d.edit,55,descH},{d.note,descH+98,math.max(76,height-descH-225)}}) do local e=info[1]; move(e.viewport,14,info[2]); e.viewport:SetSize(workWidth-30,info[3]); e.scroll:SetSize(workWidth-60,info[3]-8); e:SetWidth(workWidth-62); e:Fit(); e.placeholder:SetWidth(workWidth-84); end
  move(d.noteLabel,14,descH+74); d.noteLabel:SetWidth(workWidth-30); d.noteLabel:SetHeight(20); move(d.back,14,height-142);
  main.preview.scroll:SetSize(workWidth-26,height-150); move(main.preview.export,0,height-142); move(main.preview.back,190,height-142);
  main.code.scroll:SetSize(workWidth-44,height-262); main.code.edit:SetWidth(workWidth-49); move(main.code.message,14,height-177); move(main.code.apply,14,height-142); move(main.code.back,workWidth-130,height-142); main.code.help:SetWidth(workWidth-30);
  main.settingsButton.text:SetText(A.T("Настройки")); main.descriptionButton.text:SetText(A.T("Описание"));
  main.buildsLabel:SetText(A.T("Билды")); main.capture.text:SetText(A.T("Из забега")); main.import.text:SetText(A.T("Импорт")); main.export.text:SetText(A.T("Экспорт"));
  main.new.text:SetText(A.T("Новый")); main.clone.text:SetText(A.T("Копия")); main.delete.text:SetText(A.T("Удалить"));
  for _,action in ipairs({main.new,main.clone,main.delete}) do action:SetWidth(48); action.text:SetWidth(42); action.text:SetFont(FONT,9,""); end
  local builds={}; for _,v in ipairs(ASAdvisorDB.builds) do if v.class==view.class then builds[#builds+1]=v; end end
  local perPage=math.max(1,math.min(4,math.floor((height-116-144-153)/40)));
  local pages=math.max(1,math.ceil(#builds/perPage)); view.buildPage=math.min(view.buildPage,pages-1);
  for i,row in ipairs(main.buildRows) do local x=i<=perPage and builds[view.buildPage*perPage+i]; row.build=x;
    if x then row.text:SetText((x==b and "|cffdde2eb●|r " or "")..x.name); row:SetBackdropBorderColor(unpack(x==b and mint or muted)); row:Show(); else row:Hide(); end
  end
  local footer=height-116; move(main.prevBuild,10,footer-144); move(main.nextBuild,134,footer-144); move(main.buildPage,48,footer-137);
  move(main.new,10,footer-110); move(main.clone,65,footer-110); move(main.delete,120,footer-110);
  move(main.capture,10,footer-70); move(main.import,10,footer-32); move(main.export,91,footer-32);
  main.buildPage:SetText((view.buildPage+1).." / "..pages);
  for token,cell in pairs(main.classButtons) do cell:SetAlpha(token==view.class and 1 or 0.48); end
  for key,page in pairs({editor=main.editor,settings=main.settings,code=main.code,description=main.description,preview=main.preview,caps=main.caps}) do
    if key==view.mode then page:Show(); else page:Hide(); end
  end
  if view.mode=="caps" then
    main.caps.title:SetText(A.T("Общие капы характеристик")); main.caps.help:SetText(A.T("0 — без личного капа. Для сокращения КД учитывается игровой максимум 80%. Сравниваем суммарные текущие бонусы персонажа, а не число на предмете.")); main.caps.back.text:SetText(A.T("Назад"));
    local stats=A.Snapshot().stats; local columnWidth=(workWidth-42)/2;
    for i,stat in ipairs(A.CapStats) do local key=stat[1]; local x=14+((i-1)%2)*(columnWidth+14); local y=90+math.floor((i-1)/2)*33;
      local e=main.caps.fields[key]; move(e,x+columnWidth-64,y); if not e:HasFocus() then e:SetText(tostring(ASAdvisorDB.options.statCaps[key] or 0)); end
      local caption=main.caps.labels[key]; move(caption,x,y+2); caption:SetWidth(columnWidth-72); caption:SetText(A.T(stat[2]).." · "..A.T("Сейчас").." "..tostring(stats[key] or "?")..stat[4]);
    end
  elseif view.mode=="settings" then
    local s=main.settings; s:Show(); s.enabled.text:SetText(A.T("Модуль")..": "..A.T(ASAdvisorDB.options.enabled==false and "Выкл." or "Вкл.")); s.title:SetText(A.T("Настройки")); s.language:SetText(A.T("Язык")); s.languageSelect.text:SetText(ASRLocale.Name(ASAdvisorDB.options.language));
    s.pickStyle.text:SetText(A.T("Метка выбора")..": "..A.T(({inline="Внутри карточки",band="Полоса над карточкой",arrow="Стрелка над карточкой"})[ASAdvisorDB.options.pickStyle]));
    for key,r in pairs(s.steps) do r.caption:SetText(A.T(r.translation)); r.value:SetText(math.floor(ASAdvisorDB.options[key]*100+0.5).."%"); end
    s.tracker.text:SetText(A.T("Трекер")..": "..A.T(ASAdvisorDB.options.trackerHidden and "Выкл." or "Вкл.")); s.reset.text:SetText(A.T("Сбросить расположение"));
    s.data.text:SetText(A.T("Сведения для отчёта")); s.back.text:SetText(A.T("Назад"));
    s.caps.text:SetText(A.T("Общие капы характеристик"));
    s.trackerMode.text:SetText(A.T(ASAdvisorDB.options.trackerMode=="compact" and "Вид: компактный" or "Вид: подробный")); s.exportAll.text:SetText(A.T("Экспорт всех билдов"));
  elseif view.mode=="preview" then
    previewBuild(b,workWidth);
    if not ASAdvisorDB.options.previewHeight and not main.sizing then
      local fitted=math.max(340,math.min(1000,main.preview.sheet:GetHeight()+150)); main:SetHeight(fitted); main.work:SetHeight(fitted-100);
      main.preview.scroll:SetHeight(fitted-150); move(main.preview.export,0,fitted-142); move(main.preview.back,190,fitted-142); A.ApplyLayout();
    end
  elseif view.mode=="description" then
    main.description:Show(); main.description.title:SetText(A.T("Описание билда")); main.description.back.text:SetText(A.T("Назад"));
    local row,p=selectedRow(); main.bindingDescription=true;
    main.description.edit.boundBuild=b; main.description.note.boundPick=p;
    if not main.description.edit:HasFocus() then main.description.edit:SetText(b and b.description or ""); end
    main.description.noteLabel:SetText(A.T("Заметка элемента")..(row and ": "..row.name or ""));
    local noteY=descH+82+measured(main.description.noteLabel,16); move(main.description.note.viewport,14,noteY); main.description.note.viewport:SetHeight(math.max(60,height-158-noteY)); main.description.note.scroll:SetHeight(main.description.note.viewport:GetHeight()-8);
    if not main.description.note:HasFocus() then main.description.note:SetText(p and p.note or ""); end
    main.description.edit.UpdatePlaceholder(); main.description.note.UpdatePlaceholder();
    main.bindingDescription=false;
  elseif view.mode=="code" then main.code:Show();
  else
    main.editor:Show(); main.classLabel:SetText(A.ClassName(view.class));
    if main.name.boundBuild~=b then main.name:ClearFocus(); main.name.boundBuild=b; end
    if not main.name:HasFocus() then main.name:SetText(b and b.name or A.T("Сначала создай билд")); end
    for key,btn in pairs(main.tabs) do btn.text:SetText(A.T(btn.translation)); btn.text:SetTextColor(unpack(key==view.tab and mint or muted)); end
    main.searchCaption:SetText(A.T("Поиск"));
    local selected,selectedPick=selectedRow();
    if not selected and b and b.spells[1] then view.selected=b.spells[1].key; view.group="spell"; selected,selectedPick=selectedRow(); end
    local count=math.max(1,math.ceil(#list/capacity)); view.page=math.min(view.page,count-1);
    for i,cell in ipairs(main.catalogRows) do local row=i<=capacity and list[view.page*capacity+i] or nil; cell.row=row;
      if row then cell.icon:SetTexture(A.Icon(row.icon));
        local chosen=b and not row.addAny and (row.group=="spell" and A.FindPick(b,row.key) or row.group~="spell" and A.HasItem(b,row.key));
        if view.editAny and selectedPick and selectedPick.any then chosen=row.addAny and #(selectedPick.options or {})==0;
          for _,key in ipairs(selectedPick.options or {}) do if key==row.key then chosen=true; end end
        end
        cell.mark:SetText(row.addAny and "Any" or chosen and "✓" or ""); cell:SetAlpha(chosen and 1 or row.addAny and 0.85 or 0.5);
        cell.mark:SetWidth(row.addAny and 30 or 14); move(cell.mark,row.addAny and 2 or 19,21);
        cell:SetBackdropBorderColor(unpack(chosen and mint or {0.38,0.39,0.42,0.6})); cell:SetBackdropColor(0.18,0.19,0.22,chosen and 0.7 or 0.1); cell:Show();
      else cell:Hide(); end
    end
    main.catalogPage:SetText(A.T("Каталог").." · "..(#list-1)..(count>1 and "   "..(view.page+1).." / "..count or ""));
    if count>1 then main.prevCatalog:Show(); main.nextCatalog:Show(); else main.prevCatalog:Hide(); main.nextCatalog:Hide(); end
    for i,cell in ipairs(main.catalogRows) do move(cell,4+((i-1)%columns)*42,68+math.floor((i-1)/columns)*40); end
    move(main.prevCatalog,4,nav); move(main.nextCatalog,workWidth-36,nav); move(main.catalogPage,42,nav+7); main.catalogPage:SetWidth(workWidth-84);
    move(main.planHeading,4,plan+4);
    for i,control in ipairs({main.planLeft,main.planRight,main.inline.remove}) do
      control:ClearAllPoints(); control:SetPoint("TOPLEFT",main.inline,"TOPLEFT",9+(i-1)*64,-36); control:SetSize(58,22); control.text:SetWidth(52); control:SetFrameLevel(main.inline:GetFrameLevel()+2);
    end
    main.planLeft.text:SetText(A.T("Раньше")); main.planRight.text:SetText(A.T("Позже")); main.inline.remove.text:SetText(A.T("Убрать")); main.inline.remove.text:SetTextColor(1,0.6,0.55);
    move(main.planHint,340,spellY+4); move(main.inline,4,inlineY);
    main.planHeading:SetText(A.T("Ваш план").." · "..#(b and b.spells or {}).." / 6"); main.planHint:Hide();
    if view.editAny then main.planHint:SetText(A.T("Any: отмечай варианты в каталоге. Пустой список — любой.")); end
    for i,cell in ipairs(main.spellCells) do local p=b and b.spells[i]; move(cell,4+(i-1)*40,spellY); fillPlanCell(cell,p and A.Info(b,p.key,"spell"),i); end
    for _,g in ipairs({"ring","trinket","amulet"}) do
      main.itemLabels[g]:SetText(A.T(({ring="Кольца",trinket="Аксессуары",amulet="Запасные амулеты"})[g]));
      local x=({ring=4,trinket=88,amulet=172})[g]; move(main.itemLabels[g],x,itemLabel); main.itemLabels[g]:SetWidth(g=="amulet" and workWidth-172 or 80);
      local rows={}; for _,key in ipairs(b and b.items or {}) do local row=A.ItemInfo(b,key); if row and row.group==g then rows[#rows+1]=row; end end
      for i,cell in ipairs(main.itemCells[g]) do local n=g=="amulet" and amuletColumns or 2; move(cell,x+((i-1)%n)*40,itemY+math.floor((i-1)/n)*40); fillPlanCell(cell,rows[i],i); end
    end
    local row,p=selectedRow();
    if not row and b and b.spells[1] then view.selected=b.spells[1].key; view.group="spell"; row,p=selectedRow(); end
    if main.inline.pick~=p then saveInline(); for _,e in pairs(main.inline.fields) do e:ClearFocus(); end end
    local inspectorWidth=math.min(280,math.floor(workWidth*0.46)); local lowerHeight=height-inlineY-110;
    main.inline.pick=p; main.inline.active={}; main.inline:SetSize(inspectorWidth,lowerHeight); main.inline.current:SetWidth(inspectorWidth-20); main.inline.base:SetWidth(inspectorWidth-20); main.inline.help:SetWidth(inspectorWidth-20); main.inline.itemHelp:SetWidth(inspectorWidth-20);
    main.inline.title:SetWidth(inspectorWidth-20); main.inline.title:SetHeight(24); main.inline.title:SetText(row and row.name or A.T("Выбери элемент плана"));
    local quick=main.quickDescription; local quickWidth=workWidth-inspectorWidth-20; move(quick,inspectorWidth+16,inlineY); quick:SetSize(quickWidth,lowerHeight);
    quick.title:SetText(A.T("Описание билда")); quick.more.text:SetText(A.T("Развернуть")); move(quick.more,quickWidth-100,4); quick.title:SetWidth(quickWidth-115);
    quick.edit.viewport:SetSize(quickWidth,lowerHeight-36); quick.edit.scroll:SetSize(quickWidth-30,lowerHeight-44); quick.edit:SetWidth(quickWidth-32); quick.edit.placeholder:SetWidth(quickWidth-52);
    if quick.edit.boundBuild~=b then quick.edit:ClearFocus(); quick.edit.boundBuild=b; end
    main.bindingDescription=true; if not quick.edit:HasFocus() then quick.edit:SetText(b and b.description or ""); end; main.bindingDescription=false; quick.edit:Fit(); quick.edit.UpdatePlaceholder();
    main.inline.base:SetText(row and A.BaseFacts(row) or "");
    for _,control in ipairs({main.planLeft,main.planRight,main.inline.remove}) do if p then control:Show(); else control:Hide(); end end
    local fieldOrder={}; local worn,metrics;
    if p then
      if row.group=="spell" then
        local m=ASAdvisorMechanics.spells and ASAdvisorMechanics.spells[row.key];
        fieldOrder={"rank","cd","damage"};
        local timed=m and m.shapeData and m.shapeData[m.shape];
        if p.any or not m or timed and timed.secs or (p.duration or 0)>0 then fieldOrder[#fieldOrder+1]="duration"; end
        if p.any or not m or m.targets or (p.targets or 0)>0 then fieldOrder[#fieldOrder+1]="targets"; end
        if p.any or m and m.radius or (p.radius or 0)>0 then fieldOrder[#fieldOrder+1]="radius"; end
      else
        worn=b.class==A.Class() and A.WornForKey(b,row.key,A.Snapshot()); local baseMetrics=A.BaseItemMetrics(row); metrics=worn and A.ItemMetrics(worn) or baseMetrics;
        if worn then for i,m in ipairs(baseMetrics) do
          if not metrics[i] then metrics[i]={kind=m.kind,unit=m.unit}; elseif not metrics[i].kind then metrics[i].kind=m.kind; end
        end end
        local count=math.max(1,#metrics); if p.any then count=math.max(2,count); end
        for i,key in ipairs(A.ItemGoalFields) do if (p[key] or 0)>0 then count=math.max(count,i); end end
        for i=1,math.min(6,count) do fieldOrder[#fieldOrder+1]=A.ItemGoalFields[i]; end
      end
    end
    for i,key in ipairs(fieldOrder) do main.inline.active[key]=true; local step=(inspectorWidth-18)/2; local column=(i-1)%2; local line=math.floor((i-1)/2);
      move(main.inline.fields[key],9+column*step,81+line*44); main.inline.fields[key]:SetWidth(step-9); move(main.inline.captions[key],9+column*step,64+line*44); main.inline.captions[key]:SetWidth(step-8); main.inline.captions[key]:SetHeight(16);
    end
    local factsY=116+math.max(0,math.ceil(#fieldOrder/2)-1)*44; move(main.inline.base,9,factsY); main.inline.base:SetHeight(28); move(main.inline.current,9,factsY+34); main.inline.current:SetHeight(48); move(main.inline.help,9,factsY+88); main.inline.help:SetHeight(28); move(main.inline.any,9,factsY+68); main.inline.any:SetWidth(inspectorWidth-18);
    main.bindingInline=true;
    for key,e in pairs(main.inline.fields) do
      if main.inline.active[key] then e:Show(); main.inline.captions[key]:Show(); if e.boundPick~=p or not e:HasFocus() then e:SetText(tostring(p[key] or 0)); e.pending=false; end; e.boundPick=p;
      else e.boundPick=nil; e.pending=false; e:Hide(); main.inline.captions[key]:Hide(); end
    end
    main.bindingInline=false;
    for key,t in pairs(main.inline.captions) do t:SetText(A.T(({rank="Ранг",cd="КД ≤, сек.",damage="Урон ≥",targets="Целей ≥",radius="Радиус ≥, м",duration="Длительность ≥, сек.",value="Бонус 1 ≥",value2="Бонус 2 ≥",value3="Бонус 3 ≥",value4="Бонус 4 ≥",value5="Бонус 5 ≥",value6="Бонус 6 ≥"})[key])); end
    main.inline.any:Hide();
    if p and row.group=="spell" then
      local stats={}; if b.class==A.Class() then local key=p.key; if p.any then key=A.AnyAssignments(b,A.Snapshot(),"spell")[p.key]; end; if key then stats=A.SpellStats(key,A.Snapshot()); end end
      local values={A.T("КД").." "..tostring(stats.cd or "?").."s",A.T("Урон").." "..tostring(stats.damage or "?")};
      if main.inline.active.targets then values[#values+1]=A.T("Цели").." "..tostring(stats.targets or "?"); end
      if main.inline.active.duration then values[#values+1]=A.T("Длительность").." "..tostring(stats.duration or "?")..A.T(" сек."); end
      if main.inline.active.radius then values[#values+1]=A.T("Радиус").." "..tostring(stats.radius or "?")..A.T(" м"); end
      main.inline.current:SetText(A.T("Текущие значения")..": "..table.concat(values," · "));
      main.inline.help:SetText(A.T("0 — без порога. При целях по статам ранг не влияет на выбор.")); main.inline.help:Show(); main.inline.current:Show(); main.inline.itemHelp:Hide();
    elseif p then
      for i,key in ipairs(fieldOrder) do
        local m=metrics[i]; local behavior=ASAdvisorMechanics.items[row.key] and ASAdvisorMechanics.items[row.key].behavior;
        main.inline.captions[key]:SetText(A.StatLabel(m and m.kind or i==1 and behavior,A.T("Бонус").." "..i).." ≥"..(m and m.unit or ""));
      end
      main.inline.current:SetText(worn and A.T("Текущие значения")..": "..A.ShortItem(worn) or A.T("Текущих значений ещё нет: предмет не надет."));
      main.inline.help:SetText(A.T("Бонусы сравниваются по модулю. Например, сокращение КД 30% — цель 30.")); main.inline.help:Show(); main.inline.current:Show(); main.inline.itemHelp:Hide();
    else
      main.inline.help:Hide(); main.inline.current:Hide(); main.inline.itemHelp:Show();
      main.inline.itemHelp:SetText(row and A.T("Амулеты слева направо: от самого желанного к запасным.").."\n"..A.T("Лучший амулет заменяет худший. Обратную замену не советуем.") or A.T("Выбери умения из каталога"));
    end
    if p and p.any then main.inline.help:Hide(); main.inline.any.text:SetText(A.T(view.editAny and "Any: готово" or "Настроить Any")); main.inline.any:Show(); end
  end
  layoutBusy=false;
end
function A.ToggleUI()
  if not A.ready then return; end; ensure();
  if main:IsShown() then saveInline(); main:Hide(); else main:Show(); A.Redraw(); end
  A.RefreshUI();
end
function A.ShowCode(mode)
  ensure(); saveInline(); main:Show();
  local c=main.code; c.message:SetText(""); c.apply.text:SetText(A.T("Импортировать")); c.back.text:SetText(A.T("Назад"));
  if mode=="import" then
    c.title:SetText(A.T("Код билда или библиотеки")); c.help:SetText(A.T("Вставь код ASR3 или ASRL3. Старые ASA1/ASA2/ASAL1 тоже поддерживаются.")); c.edit:SetText(""); c.apply:Show();
  elseif mode=="debug" then
    c.title:SetText(A.T("Сведения для отчёта")); c.help:SetText(A.T("Технические сведения о подсказках аддона. Скопируй их при сообщении об ошибке. Запись событий: /asr debug."));
    local lines={"ASR Advisor "..A.VERSION,"Class="..A.Class(),"Phase="..tostring(A.Snapshot().phase)};
    local active=A.Active(); local action=A.currentAction;
    lines[#lines+1]="Build="..tostring(active and active.name).." Action="..tostring(action and action.kind).." Index="..tostring(action and action.index).." Reason="..tostring(action and action.reason);
    for _,s in ipairs(AZS_SPELLS or {}) do lines[#lines+1]=s.key.." rank="..tostring(s.rank).." cdmax="..tostring(s.cdmax).." tip="..tostring(AZS_SPELLTIPS and AZS_SPELLTIPS[s.key]); end
    for _,line in ipairs(ASAdvisorDB.diagnostics) do lines[#lines+1]=line; end
    c.edit:SetText(table.concat(lines,"\n")); c.apply:Hide();
  else
    local b=edited(); if mode~="library" and not b then status(A.T("Сначала создай билд")); return; end
    c.title:SetText(A.T(mode=="library" and "Экспорт всех билдов" or "Экспорт")); c.help:SetText(A.T("Ctrl+A, Ctrl+C — скопировать"));
    c.edit:SetText(mode=="library" and A.ExportLibrary() or A.Export(b)); c.apply:Hide();
  end
  showMode("code"); c.edit:SetFocus(); c.edit:HighlightText(); A.RefreshUI();
end

local cardMarks={}; local actionMarks={}; local hints;
local function hintRoot()
  if not hints then
    hints=CreateFrame("Frame","ASAdvisorHints",UIParent); hints:SetAllPoints(UIParent); hints:SetFrameStrata("FULLSCREEN_DIALOG"); hints:SetFrameLevel(250); hints:EnableMouse(false);
    if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASAdvisorHints",true); end
  end
  return hints;
end
local function trackerAnchor()
  if tracker.moving or tracker.sizing then return; end
  if tracker.restoreAnchor then local pos=tracker.restoreAnchor; tracker.restoreAnchor=nil; return pos; end
  if not tracker.GetLeft or not tracker.GetTop then return; end
  local left,top=tracker:GetLeft(),tracker:GetTop(); if not left or not top then return; end
  local ratio=tracker:GetEffectiveScale()/UIParent:GetEffectiveScale();
  return {left=left*ratio,top=top*ratio};
end
local function pinTracker(pos)
  if not pos then return; end
  local ratio=tracker:GetEffectiveScale()/UIParent:GetEffectiveScale();
  tracker:ClearAllPoints(); tracker:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",pos.left/ratio,pos.top/ratio);
  ASAdvisorDB.options.trackerAnchor=pos;
end
local function createTracker()
  tracker=box(UIParent,"ASAdvisorTracker",220,64,nil,nil,0.42); tracker:SetBackdrop(windowBackdrop()); tracker:SetBackdropBorderColor(0.75,0.75,0.77,1); tracker:SetFrameStrata("HIGH"); movable(tracker,"trackerPos");
  if not ASAdvisorDB.options.trackerPos then tracker:ClearAllPoints(); tracker:SetPoint("TOPLEFT",UIParent,"TOPLEFT",18,-150); end
  tracker.restoreAnchor=ASAdvisorDB.options.trackerAnchor;
  tracker.brand=label(tracker,"ASR",9,8,-7,30,mint);
  tracker.builds=button(tracker,"",58,19,155,-3,function() A.ToggleUI(); end);
  tracker.icons={};
  for i=1,6 do
    local f=CreateFrame("Frame",nil,tracker); f:SetSize(23,23); f:SetPoint("TOPLEFT",tracker,"TOPLEFT",8+(i-1)*34,-30); f:EnableMouse(true);
    f.icon=texture(f,nil,23,0,0); f.rank=label(f,"",8,11,-14,18);
    f:SetScript("OnEnter",function(self) if self.row then itemTip(tracker,self,self.row); end end); f:SetScript("OnLeave",function() hideTip(tracker); end); tracker.icons[i]=f;
  end
  tracker.empty=label(tracker,"",10,8,-32,173,muted);
  tracker.mode=button(tracker,"≡",24,19,128,-3,function() ASAdvisorDB.options.trackerMode=ASAdvisorDB.options.trackerMode=="compact" and "detailed" or "compact"; A.RefreshUI(); end);
  tracker.rows={}; tracker.jewels={};
  tracker.viewport=CreateFrame("ScrollFrame",nil,tracker); tracker.viewport:SetPoint("TOPLEFT",tracker,"TOPLEFT",8,-28); tracker.viewport:SetSize(264,220);
  tracker.content=CreateFrame("Frame",nil,tracker.viewport); tracker.content:SetSize(264,220); tracker.viewport:SetScrollChild(tracker.content);
  for i=1,48 do
    local r=CreateFrame("Frame",nil,tracker.content); r:SetSize(324,32); r:EnableMouse(true); r.icon=texture(r,nil,22,0,-3);
    r.name=label(r,"",10,31,-2,235); r.rank=label(r,"",9,240,0,38,muted); r.rank:SetJustifyH("RIGHT"); r.rank:SetHeight(13); r.detail=label(r,"",9,31,-18,235,muted);
    r:SetScript("OnEnter",function(self) if self.row then itemTip(tracker,self,self.row); end end); r:SetScript("OnLeave",function() hideTip(tracker); end); tracker.rows[i]=r;
    if i>6 then
      local f=CreateFrame("Frame",nil,tracker); f:SetSize(23,23); f:EnableMouse(true); f.icon=texture(f,nil,23,0,0); f.rank=label(f,"",8,11,-14,18);
      f:SetScript("OnEnter",function(self) if self.row then itemTip(tracker,self,self.row); end end); f:SetScript("OnLeave",function() hideTip(tracker); end); tracker.icons[i]=f;
    end
  end
  tracker.itemLabel=label(tracker,"",9,8,-60,200,muted); tracker.spellLabel=label(tracker,"",9,24,-56,200,muted);
  tracker.extraIcons={};
  tracker.sectionLabels={}; for _,key in ipairs({"spell","jewel","extra"}) do tracker.sectionLabels[key]=label(tracker.content,"",10,0,0,200,muted); end
  tracker:EnableMouseWheel(true); tracker.offset=0;
  tracker.Scroll=function(delta)
    if ASAdvisorDB.options.trackerMode~="detailed" then return; end
    tracker.offset=math.max(0,math.min(tracker.maxOffset or 0,(tracker.offset or 0)-delta*36)); tracker.viewport:SetVerticalScroll(tracker.offset);
  end;
  tracker:SetScript("OnMouseWheel",function(self,delta) tracker.Scroll(delta); end);
  for _,frame in ipairs({tracker.viewport,tracker.content}) do frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel",function(self,delta) tracker.Scroll(delta); end); end
  for _,row in ipairs(tracker.rows) do row:EnableMouseWheel(true); row:SetScript("OnMouseWheel",function(self,delta) tracker.Scroll(delta); end); end
  tracker.scrollHint=label(tracker,"",9,8,-260,210,muted);
  tracker.resize=resizeCorner(tracker);
  tracker.sizeDirection="BOTTOMRIGHT";
  tracker:SetResizable(true); tracker:SetMinResize(240,110); tracker:SetMaxResize(520,600);
  tracker.SaveSize=function(self) ASAdvisorDB.options.trackerWidth=self:GetWidth(); ASAdvisorDB.options.trackerHeight=self:GetHeight(); A.RefreshUI(); end;
  tracker:SetScript("OnSizeChanged",function(self) if self.sizing and not trackerLayoutBusy then self:SaveSize(); end end);
  tracker:SetScript("OnHide",function(self) stopInteraction(self); hideTip(tracker); end);
end
local function cardMark(i)
  local parent=_G["AZSCard"..i]; if not parent then return; end
  if not cardMarks[i] then
    local f=CreateFrame("Frame","ASAdvisorCardMark"..i,hintRoot()); f:SetSize(64,18); f:EnableMouse(false);
    f.text=label(f,"",12,2,-2,60,pickColor); f.text:SetJustifyH("CENTER"); f.text:SetHeight(20);
    f:SetScript("OnUpdate",function(self,dt)
      self.pulse=((self.pulse or 0)+dt)%2;
      local glow=0.78+0.22*math.cos(self.pulse*math.pi);
      self:SetBackdropBorderColor(pickColor[1]*glow,pickColor[2]*glow,pickColor[3]*glow,1);
    end); cardMarks[i]=f;
  end
  local f=cardMarks[i]; f:ClearAllPoints(); local style=ASAdvisorDB.options.pickStyle; local number=_G["AZSCard"..i.."Badge"];
  f:SetSize(64,18);
  if style=="band" then f:SetSize(parent:GetWidth(),28); f:SetPoint("BOTTOM",parent,"TOP",0,2);
  elseif style=="arrow" then f:SetSize(36,36); f:SetPoint("BOTTOM",parent,"TOP",0,2);
  elseif number and parent.tag then f:SetPoint("LEFT",number,"RIGHT",3,0); f:SetPoint("RIGHT",parent.tag,"LEFT",-3,0);
  else f:SetPoint("TOPLEFT",parent,"TOPLEFT",44,-23); end
  local w=math.max(20,f:GetWidth()); local font=parent.tagText and parent.tagText:GetFont() or FONT;
  f.text:ClearAllPoints(); f.text:SetPoint("CENTER",f,"CENTER",0,0); f.text:SetFont(font,style=="band" and 15 or math.max(7,math.min(12,w/5)),"OUTLINE"); f.text:SetWidth(w-8); f.text:SetTextColor(pickColor[1],pickColor[2],pickColor[3],1); f.spaced=w>=44;
  if style=="arrow" then
    f:SetBackdrop(nil); if not f.arrow then f.arrow=f:CreateTexture(nil,"OVERLAY"); f.arrow:SetAllPoints(f); f.arrow:SetTexture("Interface\\AddOns\\ASAdvisor\\media\\arrow-down.tga"); end
    f.arrow:SetVertexColor(pickColor[1],pickColor[2],pickColor[3],1); f.arrow:Show(); f.text:Hide();
  else
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=BORDER,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}});
    f:SetBackdropColor(0.015,0.12,0.1,1); f:SetBackdropBorderColor(pickColor[1],pickColor[2],pickColor[3],1); if f.arrow then f.arrow:Hide(); end; f.text:Show();
  end
  return f;
end
local function actionMark(kind,index)
  local mint=pickColor;
  local key=kind..(index or "");
  local parent=_G[kind=="banish" and ("AZSCard"..index.."Banish") or kind=="reroll" and "AZSCardsReroll" or "AZSCardsSkip"]; if not parent then return; end
  if not actionMarks[key] then
    local name=kind=="banish" and ("ASAdvisorBanishMark"..index) or kind=="reroll" and "ASAdvisorRerollMark" or "ASAdvisorSkipMark";
    local f=CreateFrame("Frame",name,hintRoot()); f:SetSize(64,28); f:EnableMouse(false);
    -- Follow the native caption bounds, not the padded button rectangle. No extra caption
    -- or floating element can cover the card's Banish control above this button.
    f.target=parent.text or parent;
    f:SetPoint("TOPLEFT",f.target,"TOPLEFT",-5,4); f:SetPoint("BOTTOMRIGHT",f.target,"BOTTOMRIGHT",5,-4);
    f.lines={};
    for _,edge in ipairs({"TOP","BOTTOM"}) do
      local t=f:CreateTexture(nil,"OVERLAY"); t:SetTexture(mint[1],mint[2],mint[3],1); t:SetHeight(2);
      t:SetPoint(edge.."LEFT",f,edge.."LEFT",0,0); t:SetPoint(edge.."RIGHT",f,edge.."RIGHT",0,0); f.lines[#f.lines+1]=t;
    end
    for _,corner in ipairs({"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}) do
      local t=f:CreateTexture(nil,"OVERLAY"); t:SetTexture(mint[1],mint[2],mint[3],1); t:SetSize(2,7); t:SetPoint(corner,f,corner,0,0); f.lines[#f.lines+1]=t;
    end
    actionMarks[key]=f;
  end
  return actionMarks[key];
end
function A.RefreshUI()
  if not A.ready or trackerLayoutBusy then return; end
  if not tracker then createTracker(); end
  if ASAdvisorDB.options.enabled==false or ASRSuite and ASRSuite.IsModuleEnabled and not ASRSuite.IsModuleEnabled("builder") then A.currentAction=nil; tracker:Hide(); if hints then hints:Hide(); end; return; end
  local editorOpen=main and main:IsShown();
  local live=A.Snapshot(); local b=A.Active();
  local buildId=b and b.id or false; if tracker.buildId~=buildId then tracker.offset=0; tracker.buildId=buildId; end
  local visible=A.offer and AZSCardsFrame and AZSCardsFrame:IsShown();
  local action=visible and A.NextAction(b,AZS_CARDS,live) or nil; A.currentAction=action;
  if visible and not editorOpen then hintRoot():Show(); elseif hints then hints:Hide(); end
  for i=1,4 do local mark=cardMark(i); if mark then
    if not editorOpen and action and action.kind=="card" and ((action.indices and action.indices[i]) or action.index==i) and _G["AZSCard"..i]:IsShown() then
      local any=action.anyIndices and action.anyIndices[i];
      mark.text:SetText(any and (mark.spaced and "A N Y" or "ANY") or A.T(mark.spaced and "Б И Л Д" or "БИЛД")); mark:Show();
    else mark:Hide(); end
  end end
  for _,kind in ipairs({"reroll","skip"}) do local mark=actionMark(kind); if mark then
    if not editorOpen and action and action.kind==kind then mark:SetAlpha(0.88+0.12*math.sin(GetTime()*4)); mark:Show(); else mark:Hide(); end
  end end
  for i=1,4 do local mark=actionMark("banish",i); if mark then
    if not editorOpen and action and action.kind=="banish" and action.index==i then mark:SetAlpha(0.88+0.12*math.sin(GetTime()*4)); mark:Show(); else mark:Hide(); end
  end end
  tracker:SetBackdropColor(0.04,0.04,0.045,panelOpacity(ASAdvisorDB.options.trackerOpacity));
  tracker.builds.text:SetText(b and b.name or A.T("Выбрать билд")); tracker.builds.text:SetJustifyH("LEFT"); tracker.builds.text:SetHeight(14);
  if not A.suiteEditing and (editorOpen or visible or ASAdvisorDB.options.trackerHidden or not live.inRun) then stopInteraction(tracker); hideTip(tracker); tracker:Hide(); return; end
  local anchor=trackerAnchor();
  tracker:Show(); tracker.empty:Hide(); tracker.itemLabel:Hide(); tracker.spellLabel:Hide(); for _,heading in pairs(tracker.sectionLabels) do heading:Hide(); end; tracker.scrollHint:Hide(); tracker:SetScale(math.min(ASAdvisorDB.options.trackerScale,(UIParent:GetWidth()-24)/ASAdvisorDB.options.trackerWidth,(UIParent:GetHeight()-24)/ASAdvisorDB.options.trackerHeight));
  trackerLayoutBusy=true;
  local spells,items=A.TrackerEntries(b,live); local entries={}; for _,v in ipairs(spells) do entries[#entries+1]=v; end; for _,v in ipairs(items) do entries[#entries+1]=v; end
  for _,f in ipairs(tracker.icons) do f:Hide(); end; for _,r in ipairs(tracker.rows) do r:Hide(); end
  for _,icon in ipairs(tracker.extraIcons) do icon:Hide(); end
  tracker.brand:ClearAllPoints(); tracker.brand:SetPoint("TOPLEFT",tracker,"TOPLEFT",24,-23); tracker.brand:SetHeight(tracker.builds:GetHeight()); tracker.brand:SetJustifyV("MIDDLE"); tracker.brand:SetFont(FONT,10,"");
  if ASAdvisorDB.options.trackerMode=="detailed" then
    local width=ASAdvisorDB.options.trackerWidth; local bodyHeight=0;
    tracker.resize:Show(); tracker.viewport:Show();
    local planned,extras={},{};
    for _,entry in ipairs(entries) do if b and not entry.planned then extras[#extras+1]=entry; else planned[#planned+1]=entry; end end
    table.sort(extras,function(x,y) return tostring(x.row.key or x.row.name)<tostring(y.row.key or y.row.name); end);
    if #extras>0 then
      local heading=tracker.sectionLabels.extra; heading:SetText(A.T("Вне билда").." · "..#extras); heading:SetTextColor(1,0.68,0.28,1); heading:SetWidth(width-48); heading:SetHeight(14); move(heading,0,0); heading:Show();
      local columns=math.max(1,math.floor((width-48)/24));
      for i,entry in ipairs(extras) do
        local icon=tracker.extraIcons[i];
        if not icon then
          icon=CreateFrame("Frame",nil,tracker.content); icon:SetSize(18,18); icon:EnableMouse(true); icon:EnableMouseWheel(true); icon.icon=texture(icon,nil,18,0,0);
          icon:SetScript("OnMouseWheel",function(self,delta) tracker.Scroll(delta); end);
          icon:SetScript("OnEnter",function(self) if self.row then itemTip(tracker,self,self.row); end end); icon:SetScript("OnLeave",function() hideTip(tracker); end); tracker.extraIcons[i]=icon;
        end
        icon.outside=true; icon.row=entry.row; icon.icon:SetTexture(A.Icon(entry.row.icon)); move(icon,((i-1)%columns)*24,18+math.floor((i-1)/columns)*20); icon:Show();
      end
      bodyHeight=18+math.ceil(#extras/columns)*20;
    end
    local lastGroup;
    for i,entry in ipairs(planned) do
      entry.trackerGroup=entry.row.group=="spell" and "spell" or "jewel";
    end
    for i,entry in ipairs(planned) do
      if entry.trackerGroup~=lastGroup then
        local group=entry.trackerGroup; lastGroup=group; local heading=tracker.sectionLabels[group];
        if bodyHeight>0 then bodyHeight=bodyHeight+3; end
        heading:SetText(A.T(group=="spell" and "Умения" or "Бижутерия")); heading:SetWidth(width-48); heading:SetHeight(14); move(heading,0,bodyHeight); heading:Show(); bodyHeight=bodyHeight+16;
      end
      local r=tracker.rows[i]; if not r then break end
      r.row=entry.row; r:SetWidth(width-48); local nameWidth=width-(entry.rank and 119 or 77); r.name:SetWidth(nameWidth); r.detail:SetWidth(width-77);
      if entry.rank then r.rank:SetText("R"..tostring(entry.rank)); move(r.rank,width-86,0); r.rank:Show(); else r.rank:Hide(); end
      r.name:SetFont(FONT,9,""); r.name.asFontSize=9; r.detail:SetFont(FONT,8,""); r.detail.asFontSize=8; r.icon:SetSize(18,18);
      local chars={}; for char in string.gmatch(entry.row.name,".[\128-\191]*") do chars[#chars+1]=char; end
      local limit=math.max(10,math.floor(nameWidth/5.6)); local name=#chars>limit and table.concat(chars,"",1,limit-3).."..." or entry.row.name;
      r.icon:SetTexture(A.Icon(entry.row.icon)); r.name:SetText(name); move(r.name,27,0); r.name:SetHeight(13);
      r.detail:SetText(entry.detail); move(r.detail,27,14); local detailH=0;
      if entry.owned and entry.detail~="" then r.detail:Show(); detailH=measured(r.detail,10); else r.detail:Hide(); end
      local rowH=entry.owned and math.max(24,15+detailH) or 19; move(r,0,bodyHeight); r:SetHeight(rowH); r:SetAlpha(entry.owned and 1 or 0.45); r:Show(); bodyHeight=bodyHeight+rowH;
    end
    local height=math.min(math.max(110,53+bodyHeight+30),ASAdvisorDB.options.trackerHeight); tracker:SetSize(width,height);
    local available=math.max(1,height-53-30); tracker.maxOffset=math.max(0,bodyHeight-available); tracker.offset=math.min(tracker.offset or 0,tracker.maxOffset);
    tracker.viewport:ClearAllPoints(); tracker.viewport:SetPoint("TOPLEFT",tracker,"TOPLEFT",24,-53); tracker.viewport:SetSize(width-48,available); tracker.content:SetSize(width-48,math.max(1,bodyHeight)); tracker.viewport:SetVerticalScroll(tracker.offset);
    if tracker.maxOffset>0 then tracker.scrollHint:ClearAllPoints(); tracker.scrollHint:SetPoint("BOTTOMLEFT",tracker,"BOTTOMLEFT",24,12); tracker.scrollHint:SetHeight(13); tracker.scrollHint:SetWidth(width-48); tracker.scrollHint:SetText(A.T("Прокрутка колёсиком")); tracker.scrollHint:Show(); end
    move(tracker.builds,54,23); tracker.builds:SetWidth(width-116); tracker.builds.text:SetWidth(width-126); move(tracker.mode,width-48,23);
    tracker:SetScale(math.min(ASAdvisorDB.options.trackerScale,(UIParent:GetWidth()-24)/width,(UIParent:GetHeight()-24)/height));
  else
    tracker.viewport:Hide(); tracker.resize:Hide(); tracker:SetWidth(232); move(tracker.builds,54,23); tracker.builds:SetWidth(116); tracker.builds.text:SetWidth(106); move(tracker.mode,184,23);
    local spellRows=math.ceil(#spells/6); local itemRows=math.ceil(#items/6); local spellStart=69; local itemStart=#spells>0 and (spellStart+spellRows*29+17) or 69;
    if #spells>0 then tracker.spellLabel:SetText(A.T("Умения")); move(tracker.spellLabel,24,51); tracker.spellLabel:SetHeight(13); tracker.spellLabel:Show(); end
    if #items>0 then tracker.itemLabel:SetText(A.T("Бижутерия")); move(tracker.itemLabel,24,itemStart-16); tracker.itemLabel:Show(); end
    local bottom=#items>0 and (itemStart+math.max(0,itemRows-1)*29+23) or (spellStart+math.max(0,spellRows-1)*29+23);
    tracker:SetHeight(math.max(86,bottom+24));
    for i,entry in ipairs(entries) do local f=tracker.icons[i]; if f then
      local index=i<=#spells and i-1 or i-#spells-1; local y=i<=#spells and (spellStart+math.floor(index/6)*29) or (itemStart+math.floor(index/6)*29);
      move(f,24+(index%6)*31,y); f.outside=b and not entry.planned;
      if not f.warning then f.warning=label(f,"!",9,16,0,8,{1,0.68,0.28,1}); end
      if f.outside then f.warning:Show(); else f.warning:Hide(); end
      f.row=entry.row; f.icon:SetTexture(A.Icon(entry.row.icon)); f:SetAlpha(entry.owned and 1 or 0.25); f.rank:SetText(entry.rank and tostring(entry.rank) or ""); f:Show();
    end end
  end
  if #entries==0 then tracker.empty:SetText(A.T("Открой /asa и выбери билд")); tracker.empty:Show(); end
  if anchor then
    -- Fit below the existing header instead of letting screen clamping move it.
    local scale=math.min(ASAdvisorDB.options.trackerScale,math.max(1,UIParent:GetWidth()-anchor.left-12)/tracker:GetWidth(),math.max(1,anchor.top-12)/tracker:GetHeight());
    tracker:SetScale(scale); pinTracker(anchor);
  end
  trackerLayoutBusy=false;
  if ASRSuite and ASRSuite.ApplyDocking then ASRSuite.ApplyDocking(); end
end

function A.SetEditMode(on)
 A.suiteEditing=on and true or false;
 if tracker then stopInteraction(tracker); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASAdvisorTracker",A.suiteEditing); end; tracker:SetFrameStrata(A.suiteEditing and "FULLSCREEN_DIALOG" or "HIGH"); tracker:SetFrameLevel(A.suiteEditing and 450 or 10); end
 A.RefreshUI(); if tracker and ASRStyle and ASRStyle.SyncChildren then ASRStyle.SyncChildren(tracker); end
end

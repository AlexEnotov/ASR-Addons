local A=ASRSuite;
local panels={}; local busy=false; local dragging; local elapsed=0; local SNAP=32; local GAP=2; local preview; local dragData;
local function Links() return ASRSuiteDB and ASRSuiteDB.docking or {}; end
local function Rect(frame)
 if not frame or not frame.GetLeft or not frame.GetTop then return; end
 local left,top=frame:GetLeft(),frame:GetTop(); if not left or not top then return; end
 local ratio=(frame.GetEffectiveScale and frame:GetEffectiveScale() or 1)/(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1);
 local padding=frame.asrDockInsets or {};
 return {left=left*ratio,top=top*ratio,width=frame:GetWidth()*ratio,height=frame:GetHeight()*ratio,ratio=ratio,insets={left=(padding.left or 0)*ratio,right=(padding.right or 0)*ratio,top=(padding.top or 0)*ratio,bottom=(padding.bottom or 0)*ratio}};
end
local function Visual(r)
 local i=r.insets or {left=0,right=0,top=0,bottom=0};
 return {left=r.left+i.left,top=r.top-i.top,width=r.width-i.left-i.right,height=r.height-i.top-i.bottom};
end
local function Ready(id)
 local p=panels[id]; if not p then return; end
 if p.available and not p.available() then return; end
 return p.frame;
end
local function Save(id)
 local p=panels[id]; local r=p and Rect(p.frame); if not r then return; end
 if p.save then p.save(r); end
end
local function Freeze(id)
 local p=panels[id]; local r=p and Rect(p.frame); if not r then return; end
 p.frame:ClearAllPoints(); p.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",r.left/r.ratio,r.top/r.ratio); p.anchored=false;
end
function A.IsDockDescendant(id,parent)
 local seen={}; while Links()[id] do
  if seen[id] then return true; end; seen[id]=true; id=Links()[id].parent; if id==parent then return true; end
 end; return false;
end
function A.ApplyDocking()
 if busy or not ASRSuiteDB or not ASRSuiteDB.docking then return; end; busy=true;
 local done,visiting={},{};
 local function Apply(id)
  if done[id] then return; end
  if visiting[id] then ASRSuiteDB.docking[id]=nil; return; end
  visiting[id]=true;
  local link=Links()[id]; local p=panels[id];
  if link and p then
   Apply(link.parent);
   if Links()[id]~=link then visiting[id]=nil; done[id]=true; return; end
   local child,parent=Ready(id),Ready(link.parent);
   if child and parent and not child.moving and dragging~=id then
    local c,r=Rect(child),Rect(parent);
    if c and r then
     local cv,rv=Visual(c),Visual(r); local ci,ri=c.insets,r.insets; local offset=link.offset or 0;
     if link.align=="start" then offset=0;
     elseif link.align=="end" then offset=(link.side=="top" or link.side=="bottom") and rv.width-cv.width or cv.height-rv.height; end
     local gap=GAP; local point,relative,x,y;
     if link.side=="bottom" then point,relative,x,y="TOPLEFT","BOTTOMLEFT",offset+ri.left-ci.left,ri.bottom+ci.top-gap;
     elseif link.side=="top" then point,relative,x,y="BOTTOMLEFT","TOPLEFT",offset+ri.left-ci.left,gap-ri.top-ci.bottom;
     elseif link.side=="right" then point,relative,x,y="TOPLEFT","TOPRIGHT",gap-ri.right-ci.left,offset+ci.top-ri.top;
     elseif link.side=="left" then point,relative,x,y="TOPRIGHT","TOPLEFT",ri.left+ci.right-gap,offset+ci.top-ri.top;
     else ASRSuiteDB.docking[id]=nil; end
     if point then child:ClearAllPoints(); child:SetPoint(point,parent,relative,x/c.ratio,y/c.ratio); p.anchored=true; Save(id); end
    end
   elseif p.anchored then Freeze(id); end
  end
  visiting[id]=nil; done[id]=true;
 end
 for id in pairs(panels) do Apply(id); end; busy=false;
end
function A.DockPanel(child,parent,side,offset,align)
 if child==parent or not panels[child] or not panels[parent] or A.IsDockDescendant(parent,child) then return false; end
 if side~="top" and side~="bottom" and side~="left" and side~="right" then return false; end
 ASRSuiteDB.docking[child]={parent=parent,side=side,offset=offset or 0,align=align or "offset"}; A.ApplyDocking(); return true;
end
function A.UndockPanel(id)
 Freeze(id); ASRSuiteDB.docking[id]=nil; Save(id);
end
local function SaveTree(parent)
 Save(parent); for id,link in pairs(Links()) do if link.parent==parent then SaveTree(id); end end
end
local function FindTarget(id,c)
  c=Visual(c); local best;
  for parent,p in pairs(panels) do
   if parent~=id and Ready(parent) and p.frame:IsShown() and not A.IsDockDescendant(parent,id) then
    local r=Rect(p.frame);
    if r then r=Visual(r);
     local horizontal=math.min(c.left+c.width,r.left+r.width)-math.max(c.left,r.left)>12;
     local vertical=math.min(c.top,r.top)-math.max(c.top-c.height,r.top-r.height)>12;
     local candidates={};
     if horizontal then candidates[#candidates+1]={side="bottom",distance=math.abs(c.top-(r.top-r.height-GAP)),offset=c.left-r.left,ending=r.width-c.width}; candidates[#candidates+1]={side="top",distance=math.abs(c.top-c.height-r.top-GAP),offset=c.left-r.left,ending=r.width-c.width}; end
     if vertical then candidates[#candidates+1]={side="right",distance=math.abs(c.left-r.left-r.width-GAP),offset=c.top-r.top,ending=c.height-r.height}; candidates[#candidates+1]={side="left",distance=math.abs(c.left+c.width-r.left+GAP),offset=c.top-r.top,ending=c.height-r.height}; end
     for _,candidate in ipairs(candidates) do
      if candidate.distance<=SNAP and (not best or candidate.distance<best.distance or candidate.distance==best.distance and parent<best.parent) then candidate.parent=parent; best=candidate; end
     end
    end
   end
  end
  return best;
end
local function Preview(best)
 if not best then if preview then preview:Hide(); end; return; end
 local r=Rect(Ready(best.parent)); if not r then return; end; r=Visual(r);
 if not preview then
  preview=CreateFrame("Frame","ASRDockingPreview",UIParent); preview:SetFrameStrata("FULLSCREEN_DIALOG"); preview:SetFrameLevel(900); preview:EnableMouse(false);
  preview.line=preview:CreateTexture(nil,"OVERLAY"); preview.line:SetTexture("Interface\\Buttons\\WHITE8X8"); preview.line:SetVertexColor(64/255,1,212/255,1);
  preview.text=ASRStyle.Label(preview,"",10,0,0,240,{64/255,1,212/255,1}); preview.text:ClearAllPoints(); preview.text:SetPoint("BOTTOMLEFT",preview,"TOPLEFT",0,3); preview.text:SetHeight(16);
  A.dockPreview=preview;
 end
 preview:ClearAllPoints(); preview:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",r.left,r.top); preview:SetSize(r.width,r.height); preview.line:ClearAllPoints();
 if best.side=="bottom" then preview.line:SetSize(r.width,2); preview.line:SetPoint("BOTTOMLEFT",preview,"BOTTOMLEFT",0,-GAP);
 elseif best.side=="top" then preview.line:SetSize(r.width,2); preview.line:SetPoint("TOPLEFT",preview,"TOPLEFT",0,GAP);
 elseif best.side=="left" then preview.line:SetSize(2,r.height); preview.line:SetPoint("TOPLEFT",preview,"TOPLEFT",-GAP,0);
 else preview.line:SetSize(2,r.height); preview.line:SetPoint("TOPRIGHT",preview,"TOPRIGHT",GAP,0); end
 preview.text:SetText(A.T("Отпусти — стыковка")); preview:Show();
 if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRDockingPreview",true); end
 preview:SetFrameLevel(900);
end
local function Cursor()
 if not GetCursorPosition then return; end
 local x,y=GetCursorPosition(); local scale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1; return x/scale,y/scale;
end
local function PositionDrag()
 local p=dragging and panels[dragging]; if not p or not dragData or not dragData.active then return; end
 local x,y=Cursor(); if not x then return; end
 local current=Rect(p.frame) or dragData.rect; local c={left=dragData.rect.left+x-dragData.x,top=dragData.rect.top+y-dragData.y,width=current.width,height=current.height,ratio=current.ratio,insets=current.insets};
 local best=A.editing and ASRSuiteDB.dockingEnabled and not (IsShiftKeyDown and IsShiftKeyDown()) and FindTarget(dragging,c) or nil;
 local left,top=c.left,c.top;
 if best then
  local r=Visual(Rect(Ready(best.parent))); local cv=Visual(c); local ci=c.insets; local offset=best.offset;
  if math.abs(offset)<=SNAP then offset=0; elseif math.abs(offset-best.ending)<=SNAP then offset=best.ending; end
  if best.side=="bottom" then left,top=r.left+offset-ci.left,r.top-r.height-GAP+ci.top;
  elseif best.side=="top" then left,top=r.left+offset-ci.left,r.top+GAP+cv.height+ci.top;
  elseif best.side=="right" then left,top=r.left+r.width+GAP-ci.left,r.top+offset+ci.top;
  else left,top=r.left-GAP-cv.width-ci.left,r.top+offset+ci.top; end
 end
 p.frame:ClearAllPoints(); p.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/c.ratio,top/c.ratio); Preview(best); return best;
end
function A.BeginDockDrag(id)
 if not A.editing or not panels[id] then return; end
 A.UndockPanel(id); dragging=id;
 local x,y=Cursor(); local r=Rect(panels[id].frame); dragData=x and r and {x=x,y=y,rect=r,active=false} or nil;
end
function A.EndDockDrag(id)
 if dragging~=id then return; end;
 local live=dragData and dragData.active; local liveBest=live and PositionDrag(); dragging=nil; dragData=nil; Preview(nil);
 local p=panels[id]; if p and p.frame.moving then p.frame:StopMovingOrSizing(); p.frame.moving=false; end
 local frame=Ready(id); local c=Rect(frame);
 if A.editing and ASRSuiteDB.dockingEnabled and c and not (IsShiftKeyDown and IsShiftKeyDown()) then
  local best; if live then best=liveBest; else best=FindTarget(id,c); end
  if best then
   local align="offset"; if math.abs(best.offset)<=SNAP then align="start"; elseif math.abs(best.offset-best.ending)<=SNAP then align="end"; end
   A.DockPanel(id,best.parent,best.side,best.offset,align);
  end
 end
 A.ApplyDocking(); SaveTree(id);
end
function A.ClearDocking()
 for id in pairs(Links()) do Freeze(id); Save(id); end; ASRSuiteDB.docking={};
end
local function Bind(id,frame)
 if not frame or not frame.GetScript or frame.asrDockBound then return; end
 local start,stop,up=frame:GetScript("OnDragStart"),frame:GetScript("OnDragStop"),frame:GetScript("OnMouseUp");
 if start then
  frame.asrDockBound=true;
  frame:SetScript("OnDragStart",function(self,...)
   A.BeginDockDrag(id); start(self,...);
   if dragging==id and dragData and panels[id].frame.moving then panels[id].frame:StopMovingOrSizing(); panels[id].frame.moving=true; dragData.active=true; PositionDrag(); end
  end);
  frame:SetScript("OnDragStop",function(self,...) if stop then stop(self,...); end; A.EndDockDrag(id); end);
  frame:SetScript("OnMouseUp",function(self,...) if up then up(self,...); end; A.EndDockDrag(id); end);
 end
 if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do Bind(id,child); end end
end
function A.RegisterDockPanel(id,frame,save,available)
 if type(id)=="string" and string.sub(id,1,5)=="text:" then return; end
 if not frame then return; end
 if panels[id] and panels[id].frame==frame then return; end
 panels[id]={frame=frame,save=save,available=available}; Bind(id,frame); A.ApplyDocking();
end
function A.InitDocking()
 if type(ASRSuiteDB.docking)~="table" then ASRSuiteDB.docking={}; end
 if type(ASRSuiteDB.dockingEnabled)~="boolean" then ASRSuiteDB.dockingEnabled=true; end
 for id,link in pairs(ASRSuiteDB.docking) do if type(id)~="string" or type(link)~="table" or type(link.parent)~="string" or link.parent==id or (link.offset~=nil and not A.Number(link.offset)) or string.sub(id,1,5)=="text:" or string.sub(link.parent,1,5)=="text:" then ASRSuiteDB.docking[id]=nil; end end
 local skin=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI");
 local insets=skin and {left=1.5,right=1.5,top=10,bottom=11} or {left=0,right=0,top=0,bottom=0};
 if ASRStatsPanel then ASRStatsPanel.asrDockInsets=insets; end; if ASAdvisorTracker then ASAdvisorTracker.asrDockInsets=insets; end
 A.RegisterDockPanel("stats",ASRStatsPanel,function(r) ASRStatsDB.position={point="TOPLEFT",relative="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; end,function() return ASRStatsPanel:IsShown() and not ASRStatsPanel.settings:IsShown(); end);
 A.RegisterDockPanel("builder",ASAdvisorTracker,function(r) ASAdvisorDB.options.trackerPos={point="TOPLEFT",rel="BOTTOMLEFT",x=r.left/r.ratio,y=r.top/r.ratio}; ASAdvisorDB.options.trackerAnchor={left=r.left,top=r.top}; end,function() return ASAdvisorTracker:IsShown(); end);
 A.dockPanels=panels;
end
function A.UpdateDocking(dt)
 if dragging then
  if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then A.EndDockDrag(dragging);
  elseif dragData and dragData.active then PositionDrag();
  else local c=Rect(Ready(dragging)); Preview(A.editing and ASRSuiteDB.dockingEnabled and c and not (IsShiftKeyDown and IsShiftKeyDown()) and FindTarget(dragging,c) or nil); end
 else Preview(nil); end
 elapsed=elapsed+dt; if elapsed<0.05 then return; end; elapsed=0;
 if (not panels.builder and ASAdvisorTracker) or (not panels.stats and ASRStatsPanel) then A.InitDocking(); end
 A.ApplyDocking();
end

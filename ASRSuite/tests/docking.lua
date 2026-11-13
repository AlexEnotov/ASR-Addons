local A=ASRSuite; local count=0;
local function check(ok,label) assert(ok,label); count=count+1; end
for _,lane in ipairs(A.lanes) do check(not A.dockPanels["text:"..lane],"combat text areas are excluded from magnetic docking"); end
ASRSuiteDB.docking["text:normal"]={parent="stats",side="right",offset=0};
ASRSuiteDB.docking.builder={parent="text:heal",side="bottom",offset=0}; A.InitDocking();
check(not ASRSuiteDB.docking["text:normal"] and not ASRSuiteDB.docking.builder,"legacy links to and from combat text are removed without changing saved area positions");
local function factor(point) return string.find(point,"RIGHT") and 1 or string.find(point,"LEFT") and 0 or 0.5,string.find(point,"BOTTOM") and 1 or string.find(point,"TOP") and 0 or 0.5; end
local function panel(x,y,w,h,scale)
 local f=CreateFrame("Frame",nil,UIParent); f:SetSize(w,h); f:SetScale(scale or 1); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y);
 local function bounds(self)
  local point,parent,relative,dx,dy=self:GetPoint(); local sx,sy=factor(point); local px,py=factor(relative); local ratio=self:GetEffectiveScale();
  local left,top,pw,ph=0,UIParent:GetHeight(),UIParent:GetWidth(),UIParent:GetHeight();
  if parent~=UIParent then local ps=parent:GetEffectiveScale(); left=parent:GetLeft()*ps; top=parent:GetTop()*ps; pw=parent:GetWidth()*ps; ph=parent:GetHeight()*ps; end
  return (left+px*pw+dx*ratio-sx*self:GetWidth()*ratio)/ratio,(top-py*ph+dy*ratio+sy*self:GetHeight()*ratio)/ratio;
 end
 function f:GetLeft() return (bounds(self)); end
 function f:GetTop() local _,top=bounds(self); return top; end
 return f;
end
local parent=panel(50,650,180,100); local child=panel(50,546,180,80); local grand=panel(900,300,90,60);
A.RegisterDockPanel("testParent",parent); A.RegisterDockPanel("testChild",child); A.RegisterDockPanel("testGrand",grand);
A.SetEditing(true); A.BeginDockDrag("testChild"); A.EndDockDrag("testChild");
check(ASRSuiteDB.docking.testChild.parent=="testParent" and ASRSuiteDB.docking.testChild.side=="bottom","dragged child snaps below the chosen parent");
grand:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",234,546); A.BeginDockDrag("testGrand"); A.EndDockDrag("testGrand");
check(ASRSuiteDB.docking.testGrand.parent=="testChild" and ASRSuiteDB.docking.testGrand.side=="right","side attachment uses the panel it was dragged toward as parent");
parent:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",70,620); A.ApplyDocking();
check(child:GetLeft()==70 and child:GetTop()==518 and grand:GetLeft()==252 and grand:GetTop()==518,"moving a root carries its complete vertical and horizontal subtree");
parent:SetHeight(140); A.ApplyDocking();
check(child:GetTop()==478 and grand:GetTop()==478,"new stats rows automatically move the attached tracker and its children down");
check(not A.DockPanel("testParent","testGrand","bottom",0,"start"),"a descendant cannot become its own ancestor");
A.BeginDockDrag("testChild"); child:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",400,400); A.EndDockDrag("testChild");
check(not ASRSuiteDB.docking.testChild and ASRSuiteDB.docking.testGrand.parent=="testChild","dragging a child detaches it with its own descendants only");
parent:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",100,600); A.ApplyDocking();
check(child:GetLeft()==400 and grand:GetLeft()==582,"detached subtree no longer follows the old parent");
local scaled=panel(100,100,160,70,0.75); A.RegisterDockPanel("testScaled",scaled);
check(A.DockPanel("testScaled","testParent","bottom",0,"start"),"panels with different scales can dock");
check(math.abs(scaled:GetLeft()*0.75-parent:GetLeft())<0.001 and math.abs(scaled:GetTop()*0.75-(parent:GetTop()-parent:GetHeight()-2))<0.001,"docking offsets preserve screen alignment and gap at different scales");
local links=A.Copy and A.Copy(ASRSuiteDB.docking) or nil;
local saved=ASRSuiteDB.docking.testScaled; A.UndockPanel("testScaled"); ASRSuiteDB.docking.testScaled=saved; A.ApplyDocking();
check(select(2,scaled:GetPoint())==parent,"saved docking relation recreates a native edge anchor");
A.ClearDocking(); check(next(ASRSuiteDB.docking)==nil and select(2,child:GetPoint())==UIParent,"clear docking preserves positions and releases relative anchors");
ASRSuiteDB.docking.testParent={parent="testChild",side="bottom",offset=0}; ASRSuiteDB.docking.testChild={parent="testParent",side="bottom",offset=0}; A.ApplyDocking();
check(not (ASRSuiteDB.docking.testParent and ASRSuiteDB.docking.testChild),"corrupt saved cycles are removed before creating native frame anchors"); A.ClearDocking();
local hookParent=panel(800,650,180,100); local hookChild=panel(800,570,180,80);
hookChild:SetScript("OnDragStart",function(self) self.moving=true; end);
hookChild:SetScript("OnDragStop",function(self) self.moving=false; end);
A.RegisterDockPanel("hookParent",hookParent); A.RegisterDockPanel("hookChild",hookChild);
local originalCursor=GetCursorPosition; local cursorX,cursorY=400,400; function GetCursorPosition() return cursorX,cursorY; end
MouseDown=true; hookChild:GetScript("OnDragStart")(hookChild); A.UpdateDocking(0.1);
check(A.dockPreview and A.dockPreview:IsShown(),"real drag handler highlights a parent even with a modest frame overlap");
check(hookChild:GetTop()==548,"live magnet snaps to the same small gap before releasing the mouse");
cursorY=300; A.UpdateDocking(0.01); check(hookChild:GetTop()==470 and not A.dockPreview:IsShown(),"dragging away releases the live magnet immediately without a saved link");
cursorY=400; A.UpdateDocking(0.01); check(hookChild:GetTop()==548 and A.dockPreview:IsShown(),"returning near the edge snaps again while the mouse is held");
hookChild:GetScript("OnMouseUp")(hookChild);
check(ASRSuiteDB.docking.hookChild and ASRSuiteDB.docking.hookChild.parent=="hookParent" and not hookChild.moving,"mouse release ends native movement before saving the snap relation");
check(hookChild:GetTop()==hookParent:GetTop()-hookParent:GetHeight()-2,"overlap resolves to a clear edge gap on release");
check(not A.dockPreview:IsShown(),"release removes the docking preview");
GetCursorPosition=originalCursor; MouseDown=false; A.SetEditing(false);
local paintedParent=panel(1080,650,180,100); local paintedChild=panel(0,0,180,80,0.75);
paintedParent.asrDockInsets={left=1.5,right=1.5,top=10,bottom=11}; paintedChild.asrDockInsets={left=1.5,right=1.5,top=10,bottom=11};
paintedChild:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",1090/0.75,580/0.75);
paintedChild:SetScript("OnDragStart",function(self) self.moving=true; end); paintedChild:SetScript("OnDragStop",function(self) self.moving=false; end);
A.RegisterDockPanel("paintedParent",paintedParent); A.RegisterDockPanel("paintedChild",paintedChild);
A.SetEditing(true); MouseDown=true; paintedChild:GetScript("OnDragStart")(paintedChild);
local parentVisibleBottom=paintedParent:GetTop()-paintedParent:GetHeight()+11;
check(math.abs((paintedChild:GetTop()*0.75-10*0.75)-(parentVisibleBottom-2))<0.001,"live snap leaves two units between visible metal edges, compensating texture padding and scale");
local snapped=paintedChild:GetTop(); paintedChild:GetScript("OnMouseUp")(paintedChild);
check(math.abs(paintedChild:GetTop()-snapped)<0.001,"saving the relative anchor does not change the visible snap gap");
check(math.abs(paintedChild:GetLeft()*0.75+1.5*0.75-(paintedParent:GetLeft()+1.5))<0.001,"left alignment follows visible borders rather than transparent margins");
A.ClearDocking(); MouseDown=false; A.SetEditing(false);
print("Passed "..count.." magnetic docking checks");

local A=ASRSuite; local S=ASRStyle; local window,status,minibutton; local controls={}; local pending={};
local translated={};
local function Label(parent,key,...) local f=S.Label(parent,A.T(key),...); if key~="" then translated[#translated+1]={region=f,key=key}; end; return f; end
local function Button(parent,key,...) local f=S.Button(parent,A.T(key),...); if key~="" then translated[#translated+1]={region=f.text,key=key}; end; return f; end
local names={normal="Обычный урон",critical="Критические удары",heal="Исцеление",taken="Полученный урон"};
local function Hint(frame,title,body)
 frame:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(A.T(title)); if body then GameTooltip:AddLine(A.T(body),0.8,0.8,0.82,true); end; GameTooltip:Show(); end); frame:SetScript("OnLeave",function() GameTooltip:Hide(); end);
end
local function Notify(message) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("ASR: "..A.T(message)); end end
local function ToggleEdit() A.SetEditing(not A.editing); if A.editing then window:Hide(); A.Example(); end end
function A.UpdateHandles()
 for key,handle in pairs(A.handles or {}) do
  A.StopDrag(handle); handle:ClearAllPoints(); local p=A.CombatConfig().positions[key]; handle:SetPoint("CENTER",UIParent,"CENTER",p.x,p.y);
  if A.editing and A.IsModuleEnabled("combat") then handle:Show(); else handle:Hide(); end
 end
 if A.editBar then if A.editing then A.editBar:Show(); else A.editBar:Hide(); end end
end
local function MiniPlace()
 if not minibutton then return; end
 local radians=math.rad(ASRSuiteDB.minimapAngle); local radius=Minimap:GetWidth()/2+10;
 minibutton:ClearAllPoints(); minibutton:SetPoint("CENTER",Minimap,"CENTER",math.cos(radians)*radius,math.sin(radians)*radius);
end
function A.TranslateLayout() for _,binding in ipairs(translated) do binding.region:SetText(A.T(binding.key)); end end
A.ToggleEdit=ToggleEdit;
function A.CreateUI()
 A.CreateSettings(); window=A.settings;
 A.handles={};
 for _,key in ipairs(A.lanes) do
  local lane=key; local f=CreateFrame("Frame","ASRCombatArea_"..lane,UIParent); f:SetSize(190,44); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(450); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRCombatArea_"..lane,true); end; f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f.lane=lane;
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10}); f:SetBackdropColor(0.03,0.05,0.06,0.9); f:SetBackdropBorderColor(0.25,1,0.83,1);
  Label(f,names[lane],11,8,6,174); Label(f,"Перетащи область",9,8,23,174,S.muted);
  f:SetScript("OnDragStart",function(self) self.moving=true; self:StartMoving(); end); f:SetScript("OnDragStop",A.StopDrag); f:SetScript("OnHide",A.StopDrag); f:Hide(); A.handles[lane]=f;
 end
 A.editBar=CreateFrame("Frame","ASRLayoutEditBar",UIParent); A.editBar:SetSize(390,62); A.editBar:SetPoint("TOP",UIParent,"TOP",0,-30); A.editBar:SetFrameStrata("FULLSCREEN_DIALOG"); A.editBar:SetFrameLevel(500); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRLayoutEditBar",true); end; S.Panel(A.editBar,1);
 Button(A.editBar,"Тест",106,24,24,19,function() A.Example(); end); Button(A.editBar,"Готово",106,24,142,19,function() A.SetEditing(false); end); Button(A.editBar,"Настройки",106,24,260,19,function() A.ToggleSettings(); end); A.editBar:Hide();
 if Minimap then
  minibutton=CreateFrame("Button","ASRSuiteMinimapButton",Minimap); minibutton:SetSize(28,28); minibutton:SetFrameStrata("HIGH"); minibutton:SetFrameLevel(Minimap:GetFrameLevel()+10); minibutton:RegisterForClicks("LeftButtonUp","RightButtonUp"); minibutton:RegisterForDrag("LeftButton");
  minibutton:SetBackdrop(nil); minibutton.disk=minibutton:CreateTexture(nil,"BACKGROUND");
  if IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") then
   local art="Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\";
   minibutton.disk:SetSize(59,59); minibutton.disk:SetPoint("CENTER",minibutton,"CENTER",0,0); minibutton.disk:SetTexture(art.."actionbutton-backdrop"); minibutton.disk:SetVertexColor(0.67,0.67,0.67,1);
   minibutton.rim=minibutton:CreateTexture(nil,"ARTWORK"); minibutton.rim:SetSize(59,59); minibutton.rim:SetPoint("CENTER",minibutton,"CENTER",0,0); minibutton.rim:SetTexture(art.."actionbutton-border"); minibutton.rim:SetVertexColor(0.9,0.9,0.9,1);
  else minibutton.disk:SetAllPoints(minibutton); minibutton.disk:SetTexture("Interface\\AddOns\\ASRSuite\\media\\minimap.tga"); end
  local mark=Label(minibutton,"ASR",9,0,0,26); mark:ClearAllPoints(); mark:SetPoint("CENTER",minibutton,"CENTER",0,0); mark:SetHeight(12); mark:SetJustifyH("CENTER"); mark:SetJustifyV("MIDDLE"); mark:SetFont(S.font,9,"OUTLINE"); mark:SetTextColor(1,1,1,1); minibutton.mark=mark;
  minibutton:SetScript("OnClick",function(self,button) if self.clickAfter and GetTime()<self.clickAfter then return; end; if button=="RightButton" then ToggleEdit(); else A.ToggleSettings(); end end);
  minibutton:SetScript("OnDragStart",function(self) self.dragging=true; self.clickAfter=GetTime()+0.15; end); minibutton:SetScript("OnDragStop",function(self) self.dragging=false; self.clickAfter=GetTime()+0.15; end);
  minibutton:SetScript("OnUpdate",function(self)
   if not self.dragging then return; end
   if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then self.dragging=false; return; end
   local x,y=GetCursorPosition(); local scale=Minimap:GetEffectiveScale(); local cx,cy=Minimap:GetCenter(); x,y=x/scale-cx,y/scale-cy;
   local angle;
   if math.atan2 then angle=math.atan2(y,x); elseif x==0 then angle=y>=0 and math.pi/2 or -math.pi/2; else angle=math.atan(y/x); if x<0 then angle=angle+math.pi; end end
   ASRSuiteDB.minimapAngle=math.deg(angle)%360; MiniPlace();
  end);
  Hint(minibutton,"ASR · by AlexEnotov","ЛКМ — настройки комплекса\nПКМ — режим редактирования\nПеретащи кнопку вокруг миникарты"); MiniPlace(); A.minimap=minibutton;
 end
 if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ASRSuiteSettings"; end
 window:Hide(); A.UpdateHandles(); A.DrawSettings();
end

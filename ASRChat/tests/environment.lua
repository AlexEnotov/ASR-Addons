local F=getmetatable(UIParent);
function F:SetParent(parent)
 if self.parent==parent then return; end
 if self.parent then for i,v in ipairs(self.parent.children) do if v==self then table.remove(self.parent.children,i); break end end end
 self.parent=parent; if parent then parent.children[#parent.children+1]=self; end
end
function F:GetAlpha() return self.alpha==nil and 1 or self.alpha; end
function F:SetAlpha(value)
 self.alpha=value;
 for _,child in ipairs(self.children or {}) do child:SetAlpha(value); end
end
function F:GetScale() return self.scale or 1; end
function F:GetEffectiveScale() return self:GetScale()*(self.parent and self.parent:GetEffectiveScale() or 1); end
function F:SetFont(path,size,flags) self.fontPath=path; self.fontSize=size; self.fontFlags=flags; end
function F:GetFont() return self.fontPath or "Fonts\\FRIZQT__.TTF",self.fontSize or 12,self.fontFlags or ""; end
function F:SetSpacing(n) self.spacing=n; end
function F:GetSpacing() return self.spacing or 0; end
function F:SetFading(v) self.fading=v; end
function F:GetFading() return self.fading==nil or self.fading; end
function F:SetTimeVisible(n) self.timeVisible=n; end
function F:GetTimeVisible() return self.timeVisible or 120; end
function F:SetFadeDuration(n) self.fadeDuration=n; end
function F:GetFadeDuration() return self.fadeDuration or 3; end
function F:IsMouseEnabled() return self.mouseEnabled; end
function F:EnableMouse(on) self.mouseEnabled=on; end
local function Native(name,docked,x)
 local f=CreateFrame("ScrollingMessageFrame",name,UIParent); f:SetSize(320,160); f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",x,-440); f:SetScale(1); f:SetFrameStrata("LOW"); f:SetFrameLevel(3); f.isDocked=docked; f.messages={};
 f:SetFont("native.ttf",14,"OUTLINE"); f:SetSpacing(1); f:SetTimeVisible(75); f:SetFadeDuration(4);
 f.AddMessage=function(self,text) self.messages[#self.messages+1]=text; end
 f.GetNumMessages=function(self) return #self.messages; end
 f.GetMessageInfo=function(self,i) return self.messages[i]; end
 f.ScrollUp=function(self) self.scrolled="up"; end; f.ScrollDown=function(self) self.scrolled="down"; end
 return f;
end
ChatFrame1=Native("ChatFrame1",true,24); ChatFrame2=Native("ChatFrame2",true,24); ChatFrame2:Hide(); ChatFrame3=Native("ChatFrame3",false,700);
ChatFrame1Tab=CreateFrame("Button","ChatFrame1Tab",UIParent); ChatFrame1Tab:SetAlpha(0.7); ChatFrame1Tab:EnableMouse(true);
ChatFrame1UpButton=CreateFrame("Button","ChatFrame1UpButton",UIParent); ChatFrame1UpButton:SetAlpha(0.8); ChatFrame1UpButton:EnableMouse(true);
ChatFrame1Background=ChatFrame1:CreateTexture("ChatFrame1Background","BACKGROUND"); ChatFrame1Background:SetAlpha(0.6); CHAT_FRAME_TEXTURES={"Background"};
ChatFrame1EditBox=CreateFrame("EditBox","ChatFrame1EditBox",UIParent); ChatFrame1EditBox:SetSize(340,30); ChatFrame1EditBox:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",24,60);
ChatFrame1EditBox.HookScript=false;
ChatFrame1EditBox:SetScript("OnEnterPressed",function() NativeInputSent=(NativeInputSent or 0)+1; end);
NUM_CHAT_WINDOWS=3; DEFAULT_CHAT_FRAME=ChatFrame1; SELECTED_DOCK_FRAME=ChatFrame1;
function GetChatWindowInfo(id) return id==1 and "General" or "Combat"; end
function FCF_SelectDockFrame(frame) SELECTED_DOCK_FRAME=frame; if frame==ChatFrame1 then ChatFrame1:Show(); ChatFrame2:Hide(); else ChatFrame1:Hide(); ChatFrame2:Show(); end end
ChatFrame1:AddMessage("Earlier native message");
NativeAddMessage=ChatFrame1.AddMessage;

function F:Show() local before=self.shown; self.shown=true; if before==false and self.scripts.OnShow then self.scripts.OnShow(self); end end
function F:Hide() local before=self.shown; self.shown=false; if before~=false and self.scripts.OnHide then self.scripts.OnHide(self); end end
function F:HookScript(event,fn) local old=self.scripts[event]; self.scripts[event]=function(...) if old then old(...); end; fn(...); end end
function F:GetRegions() local regions={}; for _,child in ipairs(self.children) do if child.kind=="Texture" or child.kind=="FontString" then regions[#regions+1]=child; end end; return unpack(regions); end
function F:GetObjectType() return self.kind; end
ChatFrameMenuButton=CreateFrame("Button","ChatFrameMenuButton",UIParent); ChatFrameMenuButton:SetAlpha(0.9); ChatFrameMenuButton:EnableMouse(true);
FriendsMicroButton=CreateFrame("Button","FriendsMicroButton",UIParent); FriendsMicroButton:SetAlpha(0.85); FriendsMicroButton:EnableMouse(true);
ChatMenuArt=ChatFrameMenuButton:CreateTexture(nil,"ARTWORK"); ChatMenuArt:SetAlpha(0.65);
AZS_FRIENDS={loading=false,friends={{name="A",online=true},{name="B",online=false},{name="C",online=true}}};
function AZS_ToggleFriends() FriendsOpened=(FriendsOpened or 0)+1; end
function ChatFrame_OpenChat(prefix,chat) OpenChatPrefix=prefix; OpenChatTarget=chat; ChatFrame1EditBox:Show(); ChatFrame1EditBox:SetText(prefix); ChatFrame1EditBox:SetFocus(); end

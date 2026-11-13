unpack=table.unpack;
table.getn=function(t) return #t; end;
local Frame={}; Frame.__index=Frame;
local allowed={"SetFont","SetJustifyH","SetJustifyV","SetTextColor","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetMovable","SetClampedToScreen","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetTextInsets","SetMaxLetters","SetMultiLine","SetVertexColor","SetTexCoord","SetTexture","HighlightText","SetScrollChild","EnableMouseWheel"};
allowed[#allowed+1]="SetGradientAlpha";
for _,name in ipairs({"SetResizable","SetMinResize","SetMaxResize","StartSizing"}) do allowed[#allowed+1]=name; end
for _,m in ipairs(allowed) do Frame[m]=function() end; end
function Frame:SetSize(w,h) self.w=w; self.h=h; end
function Frame:SetWidth(w) self.w=w; end
function Frame:SetHeight(h) self.h=h; end
function Frame:GetWidth() return self.w or 200; end
function Frame:GetHeight() return self.h or 100; end
function Frame:SetPoint(...) self.point={...}; end
function Frame:GetPoint() return unpack(self.point or {"CENTER",UIParent,"CENTER",0,0}); end
function Frame:ClearAllPoints() end
function Frame:SetAllPoints(p) self.w=p:GetWidth(); self.h=p:GetHeight(); end
function Frame:SetScript(k,v) self.scripts[k]=v; end
function Frame:GetScript(k) return self.scripts[k]; end
function Frame:RegisterEvent(e) self.events[e]=true; end
function Frame:SetFrameStrata(s) self.strata=s; end
function Frame:SetFrameLevel(n) self.level=n; end
function Frame:GetFrameLevel() return self.level or 1; end
function Frame:GetParent() return self.parent; end
function Frame:SetScale(s) self.scale=s; end
function Frame:SetAlpha(a) self.alpha=a; end
function Frame:SetTexture(path) self.texturePath=path; end
function Frame:SetTexCoord(...) self.coords={...}; end
function Frame:SetBackdropColor(...) self.backdropColor={...}; end
function Frame:SetText(t) self.textValue=t; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self); end end
function Frame:GetText() return self.textValue or ""; end
function Frame:GetNumLetters() return #self:GetText(); end
function Frame:HasFocus() return self.focus; end
function Frame:SetFocus() self.focus=true; if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self); end end
function Frame:ClearFocus() local old=self.focus; self.focus=false; if old and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self); end end
function Frame:GetFont() return "Fonts\\FRIZQT__.TTF",12; end
function Frame:SetFont(path,size) self.fontSize=size; self.fontPath=path; end
function Frame:GetStringWidth()
 local count=utf8.len(self:GetText()) or #self:GetText(); return count*(self.fontSize or 11)*0.55;
end
function Frame:GetStringHeight()
 local lines=0; local maxChars=math.max(1,math.floor(self:GetWidth()/((self.fontSize or 11)*0.55)));
 for line in string.gmatch((self:GetText() or "").."\n","(.-)\n") do local length=utf8.len(line) or #line; lines=lines+math.max(1,math.ceil(length/maxChars)); end
 return lines*((self.fontSize or 11)+2);
end
function Frame:SetVerticalScroll(value) self.verticalScroll=value; end
function Frame:GetVerticalScroll() return self.verticalScroll or 0; end
function Frame:StopMovingOrSizing() self.stopCount=(self.stopCount or 0)+1; end
function Frame:SetScrollChild(child) assert(child.kind~="FontString" and child.kind~="Texture","SetScrollChild requires a Frame, not a region"); self.scrollChild=child; end
function Frame:SetBackdrop(value) self.backdrop=value; end
function Frame:SetTextColor(...) self.textColor={...}; end
function Frame:Show() self.shown=true; end
function Frame:Hide() self.shown=false; end
function Frame:IsShown() return self.shown~=false and (not self.parent or self.parent:IsShown()); end
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent,children={},scripts={},events={},shown=true,level=parent and parent:GetFrameLevel()+1 or 1},Frame);
 if parent then parent.children[#parent.children+1]=f; end
 if name then assert(not _G[name],"Duplicate frame: "..name); _G[name]=f; end
 return f;
end
function Frame:CreateFontString(name) return CreateFrame("FontString",name,self); end
function Frame:CreateTexture(name) return CreateFrame("Texture",name,self); end
UIParent=CreateFrame("Frame","MockRoot"); UIParent:SetSize(1280,720);
GameFontNormal=CreateFrame("Font");
GameTooltip={SetOwner=function() end,SetText=function() end,AddLine=function() end,Show=function() end,Hide=function() end};
DEFAULT_CHAT_FRAME={AddMessage=function() end};
UISpecialFrames={}; SlashCmdList={};
function UnitClass() return "Охотник","HUNTER"; end
function IsAddOnLoaded(name) return name=="AzerothSurvivorsUI"; end
function GetTime() return 100; end
AZS_L=setmetatable({},{__index=function(_,k) return k; end});
function AZS_LocaleStrings(_,t) for k,v in pairs(t) do AZS_L[k]=v; end end
local handlers={};
AZS={On=function(p,f) handlers[p]=handlers[p] or {}; table.insert(handlers[p],f); end};
function Emit(p,msg) for _,fn in ipairs(handlers[p] or {}) do fn(msg); end end
MockOnTop={};
function AZS_SetOnTopOfScreens(name,on) MockOnTop[name]=on; end
AZS_ZONE={}; AZS_RUN={ph="playing"}; AZS_SPELLS={}; AZS_SPELLTIPS={}; AZS_GEAR={};
function AZS_GetPhase() return AZS_RUN.ph; end
AZSCardsFrame=CreateFrame("Frame","MockCards",UIParent); AZSCardsFrame:Hide();
for i=1,4 do
 local f=CreateFrame("Button","AZSCard"..i,AZSCardsFrame);
 f:SetSize(240,480);
 f.banish=CreateFrame("Button","AZSCard"..i.."Banish",f); f.banish.text=f.banish:CreateFontString(nil); f.banish.text:SetSize(150,18);
 f.tag=CreateFrame("Frame",nil,f); f.tag:SetSize(90,18); f.tagText=f.tag:CreateFontString(nil);
 f:CreateTexture("AZSCard"..i.."Badge"):SetSize(24,24);
end
CreateFrame("Button","AZSCardsReroll",AZSCardsFrame);
CreateFrame("Button","AZSCardsSkip",AZSCardsFrame);
AZSCardsReroll.text=AZSCardsReroll:CreateFontString(nil); AZSCardsReroll.text:SetSize(150,18);
AZSCardsSkip.text=AZSCardsSkip:CreateFontString(nil); AZSCardsSkip.text:SetSize(170,18);

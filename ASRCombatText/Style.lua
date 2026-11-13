-- Shared visual primitives for the ASR addon family. No dependency on Advisor.
ASRStyle=ASRStyle or {};
local S=ASRStyle; S.version=2;
S.font=GameFontNormal:GetFont(); S.text={0.96,0.96,0.97,1}; S.muted={0.66,0.68,0.72,1};
function S.Label(parent,value,size,x,y,width,color)
 local f=parent:CreateFontString(nil,"OVERLAY"); f:SetFont(S.font,size or 11,""); f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetWidth(width); f:SetHeight((size or 11)+5); f:SetJustifyH("LEFT"); f:SetJustifyV("MIDDLE"); f:SetTextColor(unpack(color or S.text)); f:SetText(value or ""); return f;
end
function S.Panel(frame,opacity)
 local skin=IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI");
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=skin and "Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\border-tooltip" or "Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=skin and 32 or 16,insets={left=8,right=8,top=8,bottom=8}});
 frame:SetBackdropColor(0.04,0.04,0.045,opacity or 1); frame:SetBackdropBorderColor(0.75,0.75,0.77,1);
end
function S.Button(parent,value,width,height,x,y,click)
 local f=CreateFrame("Button",nil,parent); f:SetFrameLevel(parent:GetFrameLevel()+2); f:SetAlpha(1); f:SetSize(width,height); f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}});
 f:SetBackdropColor(0.12,0.13,0.15,1); f:SetBackdropBorderColor(0.62,0.64,0.68,1);
 f.text=S.Label(f,value,10,4,2,width-8); f.text:ClearAllPoints(); f.text:SetPoint("CENTER",f,"CENTER",0,0); f.text:SetHeight(height-4); f.text:SetJustifyH("CENTER"); f.text:SetTextColor(0.96,0.96,0.97,1); f.text:SetAlpha(1);
 f:SetScript("OnClick",click); f:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(0.88,0.9,0.94,1); end); f:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.48,0.49,0.52,0.9); end); return f;
end

-- Raising a window may change only its own frame level in the client.
-- Keep real child frames (not font/texture regions) above every parent.
function S.SyncChildren(parent)
 if not parent or not parent.GetChildren then return; end
 for _,child in ipairs({parent:GetChildren()}) do
  if child.asrOverlay then child:SetFrameLevel(math.max(1000,parent:GetFrameLevel()+100)); child:SetFrameStrata("TOOLTIP");
  else child:SetFrameLevel(parent:GetFrameLevel()+2); if parent.GetFrameStrata then child:SetFrameStrata(parent:GetFrameStrata()); end end
  S.SyncChildren(child);
 end
end

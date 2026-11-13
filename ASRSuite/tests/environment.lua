local Frame=getmetatable(UIParent);
function Frame:SetOrientation(value) self.orientation=value; end
function Frame:SetValueStep(value) self.valueStep=value; end
function Frame:SetMinMaxValues(low,high) self.minimum=low; self.maximum=high; end
function Frame:SetThumbTexture(value) if not self.thumb then self.thumb=self:CreateTexture(nil,"ARTWORK"); end; self.thumb:SetTexture(value); end
function Frame:GetThumbTexture() return self.thumb; end
function Frame:SetValue(value) self.value=value; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value); end end
function Frame:GetValue() return self.value or 0; end
function Frame:RegisterForClicks() end
function Frame:SetChecked(value) self.checked=value; end
function Frame:GetChecked() return self.checked; end
function Frame:GetChildren() local out={}; for _,f in ipairs(self.children) do if f.kind~="FontString" and f.kind~="Texture" then out[#out+1]=f; end end; return unpack(out); end
function Frame:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM"; end
function Frame:Raise() self:SetFrameLevel(self:GetFrameLevel()+10); end
function Frame:GetEffectiveScale() return self.scale or 1; end
function Frame:GetCenter() return self.cx or UIParent:GetWidth()/2,self.cy or UIParent:GetHeight()/2; end
Minimap=CreateFrame("Frame","Minimap",UIParent); Minimap:SetSize(140,140);
WorldFrame=CreateFrame("Frame","WorldFrame",UIParent);
function UnitGUID() return "Player"; end
function GetSpellInfo(id) return "Test spell",nil,"Interface\\Icons\\Test"; end
local now=100; function GetTime() return now; end
function Advance(dt) now=now+dt; end
Cvars={CombatDamage="1"}; function GetCVar(key) return Cvars[key]; end; function SetCVar(key,value) Cvars[key]=value; end
Feed={};
function AZS_GetCombatTextEvents(cursor,limit)
 local list={}; local after=cursor or 0;
 for i=after+1,math.min(#Feed,after+limit) do list[#list+1]=Feed[i]; end
 return {events=list,cursor=math.min(#Feed,after+limit),hasMore=#Feed>after+limit};
end
function AZS_ProjectCombatTextAnchors(ids)
 local entries={}; for _,id in ipairs(ids) do entries[#entries+1]={anchorId=id,state=id=="hidden" and "behindCamera" or "onScreen",x=300,y=400}; end
 return {entries=entries};
end
MouseDown=false; function IsMouseButtonDown() return MouseDown; end
function GetCursorPosition() return 400,400; end

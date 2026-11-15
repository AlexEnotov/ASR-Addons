local F=getmetatable(UIParent);
function F:Show() local old=self.shown; self.shown=true; if old==false and self.scripts.OnShow then self.scripts.OnShow(self); end end
function F:Hide() local old=self.shown; self.shown=false; if old~=false and self.scripts.OnHide then self.scripts.OnHide(self); end end
function F:SetStatusBarTexture(path) self.barTexture=path; end
function F:SetStatusBarColor(...) self.barColor={...}; end
function F:SetBackdropBorderColor(...) self.backdropBorderColor={...}; end
function F:SetMask(path) self.maskPath=path; end
function F:GetAlpha() return self.alpha==nil and 1 or self.alpha; end
function F:SetAlpha(value) self.alpha=value; for _,child in ipairs(self.children or {}) do child:SetAlpha(value); end end
function F:EnableMouse(on) self.mouse=on; end
function F:IsMouseEnabled() return self.mouse; end
function F:HookScript(event,fn) local old=self.scripts[event]; self.scripts[event]=function(...) if old then old(...); end; fn(...); end; end
PartyTestUnits={};
function UnitExists(unit) return PartyTestUnits[unit]~=nil; end
function UnitIsUnit(a,b) return a==b; end
function UnitName(unit) return PartyTestUnits[unit] and PartyTestUnits[unit].name; end
function UnitClass(unit) local u=PartyTestUnits[unit]; return u and u.class,u and u.class; end
function UnitLevel(unit) return PartyTestUnits[unit] and PartyTestUnits[unit].level; end
function UnitHealth(unit) return PartyTestUnits[unit] and PartyTestUnits[unit].hp; end
function UnitHealthMax(unit) return PartyTestUnits[unit] and PartyTestUnits[unit].max; end
function UnitIsConnected(unit) return PartyTestUnits[unit] and PartyTestUnits[unit].connected; end
function UnitIsPartyLeader(unit) return unit=="party1"; end
function UnitIsDead() error("optional unit function unavailable in client"); end
function SetPortraitTexture(texture,unit) texture.portraitUnit=unit; texture:SetSize(256,256); end
RAID_CLASS_COLORS={MAGE={r=0.25,g=0.78,b=0.92},WARRIOR={r=0.78,g=0.61,b=0.43}};
AZS_REVIVE={}; AZS_PARTY={}; AZS_PEERS={};
function AZS_GetRevive() return AZS_REVIVE; end
function AZS_GetDownedPartyMembers() return {}; end
InspectedUnit=nil; function AZS_InspectUnit(unit) InspectedUnit=unit; end
AzerothSurvivorsPartyUnitButton1=CreateFrame("Button",nil,UIParent); AzerothSurvivorsPartyUnitButton1:SetAlpha(0.7); AzerothSurvivorsPartyUnitButton1:EnableMouse(true);
PartyTestAura=CreateFrame("Button",nil,AzerothSurvivorsPartyUnitButton1); PartyTestAura:EnableMouse(true);
PartyTestAura:SetAlpha(0.4);

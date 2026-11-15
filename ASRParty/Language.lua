-- Shared, independently shipped locale registry and picker. No Suite dependency.
if ASRLocale and ASRLocale.version>=2 then return; end
ASRLocale=ASRLocale or {languages={},order={},translations={}}; ASRLocale.version=2;
local L=ASRLocale; local serial=0;
function L.Register(code,name)
 if type(code)~="string" or type(name)~="string" then return; end
 if not L.languages[code] then L.order[#L.order+1]=code; end; L.languages[code]=name;
end
L.Register("ru","Русский"); L.Register("en","English");
function L.Normalize(code) return L.languages[code] and code or "en"; end
function L.Name(code) return (L.languages[code] or code or "English").." ▾"; end
function L.RegisterTranslations(module,code,strings,name)
 L.translations[module]=L.translations[module] or {}; L.translations[module][code]=strings;
 if name then L.Register(code,name); end
end
function L.Text(module,code,source,english)
 local all=L.translations[module] or {}; local own=all[code] or {};
 if own[source] then return own[source]; end
 if code=="ru" then return source; end
 return english or (all.en and all.en[source]) or source;
end
function L.Bind(button,get,set,refresh)
 if button.RegisterForClicks then button:RegisterForClicks("LeftButtonUp"); end
 button:SetScript("OnClick",function()
  if button.localePopup and button.localePopup:IsShown() then button.localePopup:Hide(); return; end
  local menu=button.localePopup;
  if L.openMenu and L.openMenu~=menu then L.openMenu:Hide(); end
  if not menu then
   serial=serial+1; menu=CreateFrame("Frame","ASRLanguageMenu"..serial,UIParent); button.localePopup=menu; menu.options={}; menu.owner=button; menu.offset=0;
   menu:SetWidth(184); menu:SetClampedToScreen(true); menu:EnableMouse(true); menu:EnableMouseWheel(true);
   menu:SetBackdrop(nil);
   menu:SetScript("OnHide",function(self) if L.openMenu==self then L.openMenu=nil; end; if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRLanguageMenu"..self.serial,false); end end); menu.serial=serial;
   menu:SetScript("OnUpdate",function(self)
    local down=IsMouseButtonDown and IsMouseButtonDown("LeftButton") or false;
    if not button:IsShown() then self:Hide();
    elseif down and not self.mouseWasDown and MouseIsOver and not MouseIsOver(self) and not MouseIsOver(button) then self:Hide(); end
    self.mouseWasDown=down;
   end);
  end
  local function Draw()
   local count=#L.order; local visible=math.min(8,count); menu.offset=math.max(0,math.min(count-visible,menu.offset)); menu:SetWidth(math.max(160,button:GetWidth())); menu:SetHeight(visible*26-2);
   for i,code in ipairs(L.order) do
    local option=menu.options[code];
    if not option then
     local key=code; option=CreateFrame("Button",nil,menu); option:SetSize(184,24); if option.RegisterForClicks then option:RegisterForClicks("LeftButtonUp"); end; menu.options[code]=option;
     option.text=option:CreateFontString(nil,"OVERLAY"); option.text:SetFont(GameFontNormal:GetFont(),11,""); option.text:SetPoint("LEFT",option,"LEFT",8,0); option.text:SetWidth(152); option.text:SetHeight(20); option.text:SetJustifyH("LEFT");
     option:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});
     option:SetScript("OnClick",function() menu:Hide(); set(key); if refresh then refresh(); end end);
     option:EnableMouseWheel(true); option:SetScript("OnMouseWheel",function(self,delta) menu.offset=menu.offset-delta; Draw(); end);
    end
    option:SetWidth(menu:GetWidth()); option.text:SetWidth(menu:GetWidth()-16); option:SetFrameStrata("TOOLTIP"); option:SetFrameLevel(menu:GetFrameLevel()+2); option.text:SetText((get()==code and "• " or "")..L.languages[code]); option.text:SetTextColor(0.96,0.96,0.97,1);
    option:SetBackdropColor(get()==code and 0.22 or 0.1,get()==code and 0.25 or 0.11,get()==code and 0.29 or 0.13,1);
    if i>menu.offset and i<=menu.offset+visible then option:ClearAllPoints(); option:SetPoint("TOPLEFT",menu,"TOPLEFT",0,-(i-menu.offset-1)*26); option:Show(); else option:Hide(); end
   end
  end
  menu:SetScript("OnMouseWheel",function(self,delta) self.offset=self.offset-delta; Draw(); end);
  local ratio=(button.GetEffectiveScale and button:GetEffectiveScale() or 1)/(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1);
  menu:SetScale(ratio); menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-2); menu.mouseWasDown=IsMouseButtonDown and IsMouseButtonDown("LeftButton") or false; L.openMenu=menu; menu:Show();
  if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRLanguageMenu"..menu.serial,false); end; menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(math.max(1000,button:GetFrameLevel()+20)); Draw();
 end);
end

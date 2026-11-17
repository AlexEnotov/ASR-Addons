-- Shared, independently shipped locale registry and picker. No Suite dependency.
if ASRLocale and ASRLocale.version>=5 then return; end
ASRLocale=ASRLocale or {languages={},order={},translations={}}; ASRLocale.version=5;
local L=ASRLocale; local serial=0;
function L.Register(code,name)
 if type(code)~="string" or type(name)~="string" then return; end
 if not L.languages[code] then L.order[#L.order+1]=code; end; L.languages[code]=name;
end
L.Register("ru","Русский"); L.Register("en","English");
for _,lang in ipairs({{"deDE","Deutsch"},{"frFR","Français"},{"esES","Español"},{"ptBR","Português"},{"itIT","Italiano"},{"plPL","Polski"},{"trTR","Türkçe"},{"jaJP","日本語"},{"zhCN","简体中文"},{"koKR","한국어"}}) do L.Register(lang[1],lang[2]); end
local aliases={enUS="en",ruRU="ru",de="deDE",fr="frFR",es="esES",pt="ptBR",it="itIT",pl="plPL",tr="trTR",ja="jaJP",zh="zhCN",ko="koKR"};
for _,code in ipairs(L.order) do aliases[string.lower(code)]=code; end
aliases.enus="en"; aliases.ruru="ru";
local function Known(code) if type(code)~="string" then return nil; end; code=aliases[code] or aliases[string.lower(code)] or code; return L.languages[code] and code or nil; end
function L.Normalize(code) return Known(code) or "en"; end
function L.IsLanguage(code) return Known(code)~=nil; end
function L.Name(code) return (L.languages[code] or code or "English").." ▾"; end
function L.RegisterTranslations(module,code,strings,name)
 L.translations[module]=L.translations[module] or {}; local target=L.translations[module][code] or {}; L.translations[module][code]=target;
 for key,value in pairs(strings) do if type(value)=="string" and value~="" then target[key]=value; end end
 if name then L.Register(code,name); end
end
function L.Text(module,code,source,english)
 if type(source)~="string" then return source; end
 code=L.Normalize(code); local all=L.translations[module] or {}; local own=all[code] or {};
 if type(own[source])=="string" and own[source]~="" then return own[source]; end
 if code=="ru" then return source; end
 if english and type(own[english])=="string" and own[english]~="" then return own[english]; end
 return english or (all.en and all.en[source]) or source;
end
local fonts={jaJP="Fonts\\KOSUGI.TTF",zhCN="Fonts\\ZCOOLKUAILE.TTF",koKR="Fonts\\NANUMGOTHIC.TTF"};
function L.Font(code,base) return fonts[L.Normalize(code)] or base or GameFontNormal:GetFont(); end
function L.UseFont(code) if ASRStyle then ASRStyle.baseFont=ASRStyle.baseFont or ASRStyle.font; ASRStyle.font=L.Font(code,ASRStyle.baseFont); end end
function L.ApplyFonts(root,code)
 local seen={}; local function Visit(frame)
  if not frame or seen[frame] then return; end; seen[frame]=true;
  if frame.GetFont and frame.SetFont then local ok,path,size,flags=pcall(frame.GetFont,frame); if ok and path and size then
   local base=path; for _,asian in pairs(fonts) do if path==asian then base=ASRStyle and ASRStyle.baseFont or GameFontNormal:GetFont(); break end end
   frame.asrBaseFont=frame.asrBaseFont or base; local selected=L.Font(code,frame.asrBaseFont);
   if path~=selected then frame:SetFont(selected,size,flags or ""); end
  end end
  if frame.GetRegions then for _,child in ipairs({frame:GetRegions()}) do Visit(child); end end
  if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do Visit(child); end end
  local label=type(frame.text)=="table" and frame.text or nil;
  if label and label.GetFont and label.GetStringWidth and label.GetWidth then
   local path,size,flags=label:GetFont(); if path and size then
    label.asrButtonSize=label.asrButtonSize or size; local target=label.asrButtonSize; label:SetFont(path,target,flags or "");
    while target>7.5 and label:GetStringWidth()>label:GetWidth() do target=target-0.5; label:SetFont(path,target,flags or ""); end
   end
  end
 end; Visit(root);
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
     option.text=option:CreateFontString(nil,"OVERLAY"); option.text:SetFont(L.Font(code),11,""); option.text:SetPoint("LEFT",option,"LEFT",8,0); option.text:SetWidth(152); option.text:SetHeight(20); option.text:SetJustifyH("LEFT");
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

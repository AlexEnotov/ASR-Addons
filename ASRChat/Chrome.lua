local A,S=ASRChat,ASRStyle;
local function ModalOpen()
 return A.settings and A.settings:IsShown() or A.copy and A.copy:IsShown() or ASRSuite and ASRSuite.settings and ASRSuite.settings:IsShown();
end
local function Focused(edit)
 if not edit or not edit:IsShown() then return false; end
 if edit.asrHasFocus~=nil then return edit.asrHasFocus==true; end
 if type(edit.HasFocus)=="function" then local value=A.Call(edit,"HasFocus"); return value==true or value==1; end
 return edit.asrHasFocus==true;
end
function A.PanelStyle(frame,style,opacity)
 if style=="stone" then S.Panel(frame,opacity);
 elseif style=="none" then frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); frame:SetBackdropColor(0.03,0.035,0.04,opacity);
 else frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}}); frame:SetBackdropColor(0.03,0.035,0.04,opacity); end
end
function A.FriendCount()
 local state=AZS_FRIENDS; if not state or state.loading then return nil; end
 local n=0; for _,friend in ipairs(state.friends or {}) do if friend.online==true or friend.online==1 or friend.online=="1" then n=n+1; end end
 return n;
end
local function Tip(button,key,detail)
 button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(A.T(key)); if detail then GameTooltip:AddLine(detail(),0.8,0.82,0.85,true); end; GameTooltip:Show(); end);
 button:SetScript("OnLeave",function() GameTooltip:Hide(); end);
end
function A.OpenPopup(button,entries,kind)
 if A.popup and A.popup:IsShown() and A.popup.owner==button then A.popup:Hide(); return; end
 if not A.popup then
  A.popup=CreateFrame("Frame","ASRChatPopup",UIParent); A.popup:SetFrameStrata("TOOLTIP"); A.popup:SetFrameLevel(1000); A.popup.rows={};
  A.popup:SetScript("OnHide",function() if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatPopup",false); end end);
 end
 local p=A.popup; p.owner=button; local scale=ASRChatDB.scale; local menuWidth=160; local rowHeight=24; p:SetScale(scale); p:SetSize(menuWidth,#entries*rowHeight+8);
 local ratio=(A.Call(button,"GetEffectiveScale") or 1)/(A.Call(UIParent,"GetEffectiveScale") or 1);
 local left=(A.Call(button,"GetLeft") or 24)*ratio; local top=(A.Call(button,"GetTop") or 300)*ratio;
 local x=kind=="tabs" and left or left+button:GetWidth()*ratio+8; local y=kind=="tabs" and top-button:GetHeight()*ratio-3 or top;
 local w,h=menuWidth*scale,p:GetHeight()*scale;
 x=math.max(8,math.min(UIParent:GetWidth()-w-8,x)); y=math.max(h+8,math.min(UIParent:GetHeight()-8,y));
 p:ClearAllPoints(); p:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale);
 p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}}); p:SetBackdropColor(0.035,0.04,0.045,0.98);
 GameTooltip:Hide();
 for i,entry in ipairs(entries) do
  local b=p.rows[i]; if not b then b=S.Button(p,"",152,22,4,4+(i-1)*24,function(self) local action=self.action; p:Hide(); action(); end); p.rows[i]=b; end
  b.text:SetText(entry.text); b.action=entry.action; b:Show();
 end
 for i=#entries+1,#p.rows do p.rows[i]:Hide(); end
 p:Show(); S.SyncChildren(p); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatPopup",true); end
end
function A.BeginInput(prefix)
 local selected=A.CurrentChat();
 if ChatFrame_OpenChat then ChatFrame_OpenChat(prefix,selected);
 else
  local name=A.Call(selected,"GetName"); local edit=name and _G[name.."EditBox"] or ChatFrameEditBox;
  if edit then if ChatEdit_ActivateChat then ChatEdit_ActivateChat(edit); else edit:Show(); end; edit:SetText(prefix); edit:SetFocus(); end
 end
 A.Apply();
end
local function Channels(button)
 local entries={};
 for _,item in ipairs({{"Сказать","/s "},{"Группа","/p "},{"Рейд","/raid "},{"Крик","/y "},{"Шёпот","/w "},{"Эмоция","/e "}}) do
  local prefix=item[2]; entries[#entries+1]={text=A.T(item[1]),action=function() A.BeginInput(prefix); end};
 end
 A.OpenPopup(button,entries);
end
function A.NewTab(parent)
 local tab=CreateFrame("Button",nil,parent); tab:SetSize(90,24); tab:EnableMouse(true); tab:RegisterForClicks("LeftButtonUp");
 tab.text=S.Label(tab,"",10,6,3,78); tab.text:SetJustifyH("CENTER");
 tab.line=tab:CreateTexture(nil,"OVERLAY"); tab.line:SetTexture("Interface\\Buttons\\WHITE8X8"); tab.line:SetHeight(2); tab.line:SetPoint("BOTTOMLEFT",tab,"BOTTOMLEFT",0,0); tab.line:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",0,0);
 tab:SetScript("OnClick",function(self) A.SelectChat(self.chat); end); return tab;
end
function A.StyleTab(tab,selected)
 tab:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); tab:SetBackdropColor(selected and 0.14 or 0.04,selected and 0.18 or 0.05,selected and 0.12 or 0.06,selected and 0.95 or 0.65);
 tab.line:SetVertexColor(selected and 140/255 or 0.3,selected and 209/255 or 0.32,selected and 35/255 or 0.35,selected and 1 or 0.6);
 tab.text:SetTextColor(selected and 140/255 or 0.8,selected and 209/255 or 0.82,selected and 35/255 or 0.85,1);
 tab.text:SetWidth(tab:GetWidth()-12);
end
function A.LayoutTabs(f,frames,selected,layout)
 local total=0; for _,entry in ipairs(frames) do total=total+entry.width+4; end
 local available=f:GetWidth()-layout.padding-56-layout.tabsX;
 local picker=layout.compact or total>available;
 for _,tab in ipairs(f.tabs) do tab:Hide(); tab:SetFrameLevel(f:GetFrameLevel()+12); end; f.tabPicker:SetFrameLevel(f:GetFrameLevel()+12); f.more:Hide();
 if picker then
  local name=A.T("Общий"); for _,entry in ipairs(frames) do if entry.frame==selected then name=entry.name; end end
  f.tabPicker:SetWidth(math.max(44,available)); f.tabPicker.text:SetWidth(math.max(32,available-12)); f.tabPicker.text:SetText(name.." ▾");
  f.tabPicker:ClearAllPoints(); f.tabPicker:SetPoint("TOPLEFT",f,"TOPLEFT",layout.tabsX,-(17+layout.shift)); f.tabPicker:Show();
 else
  f.tabPicker:Hide(); local x=layout.tabsX;
  for i,entry in ipairs(frames) do local tab=f.tabs[i]; tab:ClearAllPoints(); tab:SetPoint("TOPLEFT",f,"TOPLEFT",x,-(16+layout.shift)); tab:Show(); x=x+entry.width+4; end
 end
end
function A.CreateChrome(f)
 f.inputHolder=CreateFrame("Frame",nil,f); f.inputHolder:SetHeight(28); f.inputHolder:Hide();
 f.inputHolder:EnableMouse(true); f.inputHolder:SetScript("OnMouseDown",function() if ASRChatDB.alwaysShowInput and not A.inputActive then A.BeginInput(""); end end);
 f.tabPicker=S.Button(f,"",130,24,16,17,function(self)
  local entries={}; for _,entry in ipairs(A.ChatFrames()) do local chat=entry.frame; entries[#entries+1]={text=A.Safe(GetChatWindowInfo,entry.id) or tostring(entry.id),action=function() A.SelectChat(chat); end}; end
  A.OpenPopup(self,entries,"tabs");
 end);
 f.rail=CreateFrame("Frame",nil,f); f.rail:SetSize(20,102); f.rail:SetPoint("TOPLEFT",f,"TOPLEFT",16,-50);
 local function Tool(text,y,action,key)
  local b=S.Button(f.rail,text,20,18,0,y,action); b.text:SetFont(S.font,10,""); Tip(b,key); return b;
 end
 f.menuButton=Tool("≡",21,Channels,"Канал сообщения");
 f.friendsButton=Tool("—",0,function() if A.popup then A.popup:Hide(); end; if AZS_ToggleFriends then AZS_ToggleFriends(); elseif ToggleFriendsFrame then ToggleFriendsFrame(); end end,"Друзья в сети");
 f.up=Tool("↑",42,function() A.Call(A.CurrentChat(),"ScrollUp"); end,"Выше");
 f.down=Tool("↓",63,function() A.Call(A.CurrentChat(),"ScrollDown"); end,"Ниже");
 f.bottom=Tool("⇓",84,function() A.Call(A.CurrentChat(),"ScrollToBottom"); end,"Последние сообщения");
 Tip(f.copyButton,"Копировать чат"); Tip(f.settings,"Настройки"); Tip(f.tabPicker,"Вкладки");
end
function A.ApplyChrome(f,frames)
 local d=ASRChatDB; local width,height=f:GetWidth(),f:GetHeight(); local padding=d.frameStyle=="stone" and 18 or 6; local shift=padding-18;
 local compact=width<320; local title=(d.showHeader or A.editing) and not compact;
 f.header:Show(); if title then f.title:Show(); else f.title:Hide(); end
 f.title:SetWidth(74); f.header:SetWidth(width-padding*2); f.header:ClearAllPoints(); f.header:SetPoint("TOPLEFT",f,"TOPLEFT",padding,-(16+shift));
 f.rail:ClearAllPoints(); f.rail:SetPoint("TOPLEFT",f,"TOPLEFT",16+shift,-(50+shift));
 f.settings:ClearAllPoints(); f.settings:SetPoint("TOPRIGHT",f,"TOPRIGHT",-padding,-(18+shift));
 f.copyButton:ClearAllPoints(); f.copyButton:SetPoint("TOPRIGHT",f.settings,"TOPLEFT",-6,0);
 local inputBottom=d.frameStyle=="stone" and 26 or 8;
 local inputTop=d.inputTop and 48+shift or height-inputBottom-28;
 local besideTools=d.showTools and inputTop<158+shift;
 local inputLeft=besideTools and 42+shift or padding;
 local inputRight=not d.inputTop and inputBottom<20 and A.CanMove() and math.max(padding,24) or padding;
 f.inputHolder:SetWidth(width-inputLeft-inputRight); f.inputHolder:ClearAllPoints();
 local focused=false;
 for _,entry in ipairs(frames) do if Focused(_G["ChatFrame"..entry.id.."EditBox"]) then focused=true; end end
 if Focused(ChatFrameEditBox) then focused=true; end
 focused=focused and not ModalOpen();
 if d.inputTop then f.inputHolder:SetPoint("TOPLEFT",f,"TOPLEFT",inputLeft,-(48+shift)); else f.inputHolder:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",inputLeft,inputBottom); end
 f.inputHolder:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}}); f.inputHolder:SetBackdropColor(0.04,0.05,0.06,0.95);
 -- Keep the native edit box reachable by Enter even while its presentation is invisible.
 f.inputHolder:Show();
 A.inputActive=focused;
 if d.showTools then f.rail:Show(); else f.rail:Hide(); end
 local count=A.FriendCount(); f.friendsButton.text:SetText(count and tostring(count) or "—"); f.friendsButton.text:SetTextColor(0.4,1,0.4,1);
 return {padding=padding,shift=shift,compact=compact,tabsX=title and 98+shift or padding,left=d.showTools and 42+shift or padding,top=52+shift+(d.inputTop and 34 or 0),bottom=not d.inputTop and inputBottom+44 or padding+10};
end
function A.UpdateVisibility(dt)
 local f=A.frame; if not f or not A.active then return; end
 local visible=ASRChatDB.alwaysShowChat or A.editing or f.moving or f.sizing or A.inputActive
  or MouseIsOver and MouseIsOver(f) or A.popup and A.popup:IsShown();
 A.chromeAlpha=visible and 1 or math.max(0,(A.chromeAlpha or 1)-(dt or 0)/0.4);
 local inputVisible=ASRChatDB.alwaysShowInput or A.editing or not ModalOpen() and A.inputActive;
 A.inputAlpha=inputVisible and 1 or math.max(0,(A.inputAlpha or 0)-(dt or 0)/0.4);
 f.inputHolder:SetAlpha(A.inputAlpha);
 -- This client overwrites descendant alpha when setting a parent's alpha.
 -- Leave the root untouched so it cannot reset the input or native message art.
 for _,part in ipairs({f.skin,f.header,f.rail,f.tabPicker,f.more,f.grip}) do if part then part:SetAlpha(A.chromeAlpha); end end
 for _,tab in ipairs(f.tabs) do tab:SetAlpha(A.chromeAlpha); end
end
function A.ApplyLayers(f)
 local modal=A.settings and A.settings:IsShown() or A.copy and A.copy:IsShown() or ASRSuite and ASRSuite.settings and ASRSuite.settings:IsShown();
 local raised=A.editing and not modal;
 if f.editOverlay~=raised then f.editOverlay=raised; if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatPanel",raised); end end
 f:SetFrameStrata(raised and "FULLSCREEN_DIALOG" or "HIGH"); f:SetFrameLevel(raised and 450 or 20); S.SyncChildren(f);
 f.skin:SetFrameLevel(f:GetFrameLevel());
end
function A.DebugInput()
 print("ASR INPUT D2",tostring(ASRChatDB.alwaysShowInput),tostring(A.editing),tostring(A.inputActive),tostring(A.inputAlpha),tostring(A.frame.inputHolder:GetAlpha()),tostring(A.lastInputEvent));
 local seen={}; local function Inspect(edit)
  if not edit or seen[edit] then return; end; seen[edit]=true;
  print("ASR BOX",tostring(A.Call(edit,"GetName")),"shown="..tostring(edit:IsShown()),"tracked="..tostring(edit.asrHasFocus),"native="..tostring(A.Call(edit,"HasFocus")),"hooks="..tostring(edit.asrFocusHook));
 end
 Inspect(ChatFrameEditBox); for _,entry in ipairs(A.ChatFrames()) do Inspect(_G["ChatFrame"..entry.id.."EditBox"]); end
end

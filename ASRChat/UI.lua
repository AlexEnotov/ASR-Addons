local A,S=ASRChat,ASRStyle;
local saved,decor,history={}, {}, {}; local hooked={}; A.savedNative=saved;
local function Capture(f)
 if saved[f] then return saved[f]; end
 local points={}; for i=1,(A.Call(f,"GetNumPoints") or 1) do local p={A.Call(f,"GetPoint",i)}; if p[1] then points[#points+1]=p; end end
 local font,size,flags=A.Call(f,"GetFont");
 local r={parent=f:GetParent(),points=points,width=f:GetWidth(),height=f:GetHeight(),scale=A.Call(f,"GetScale") or 1,strata=A.Call(f,"GetFrameStrata"),level=A.Call(f,"GetFrameLevel"),font=font,size=size,flags=flags,
  spacing=A.Call(f,"GetSpacing"),fading=A.Call(f,"GetFading"),time=A.Call(f,"GetTimeVisible"),fadeDuration=A.Call(f,"GetFadeDuration"),mouseWheel=f:GetScript("OnMouseWheel")};
 saved[f]=r; return r;
end
local function Quiet(f)
 if not f then return; end
 if not decor[f] then decor[f]={alpha=A.Call(f,"GetAlpha") or 1,mouse=A.Call(f,"IsMouseEnabled")}; end
 f:SetAlpha(0); if decor[f].mouse~=nil then A.Call(f,"EnableMouse",false); end
 if f.HookScript and not hooked[f] then hooked[f]=true; f:HookScript("OnShow",function(self) if A.active and decor[self] then self:SetAlpha(0); if decor[self].mouse~=nil then A.Call(self,"EnableMouse",false); end end end);
  if hooksecurefunc then A.Safe(hooksecurefunc,f,"SetAlpha",function(self,alpha) if self==f and A.active and decor[f] and alpha~=0 then f:SetAlpha(0); end end); end
 end
end
function A.QuietTree(f)
 if not f then return; end;
 if f.GetRegions then for _,region in ipairs({f:GetRegions()}) do Quiet(region); end end
 if f.GetChildren then for _,child in ipairs({f:GetChildren()}) do A.QuietTree(child); end end
 Quiet(f);
end
A.CaptureFrame=Capture;
local function Release(f,preserveGeometry)
 local r=saved[f]; if not r then return; end
 if not preserveGeometry then f:SetParent(r.parent); f:ClearAllPoints(); for _,p in ipairs(r.points) do f:SetPoint(unpack(p)); end; f:SetSize(r.width,r.height); f:SetScale(r.scale); end
  if r.strata then f:SetFrameStrata(r.strata); end; if r.level then f:SetFrameLevel(r.level); end
  if r.font then f:SetFont(r.font,r.size,r.flags); end
  if r.spacing~=nil then A.Call(f,"SetSpacing",r.spacing); end
  if r.fading~=nil then A.Call(f,"SetFading",r.fading); end
  if r.time~=nil then A.Call(f,"SetTimeVisible",r.time); end
  if r.fadeDuration~=nil then A.Call(f,"SetFadeDuration",r.fadeDuration); end
  if r.wheelChanged then f:SetScript("OnMouseWheel",r.mouseWheel); end
  if r.wrapper and f.AddMessage==r.wrapper then f.AddMessage=r.addMessage; end
 saved[f]=nil;
end
local function Unquiet(f)
 local r=f and decor[f]; if not r then return; end
 decor[f]=nil; f:SetAlpha(r.alpha); if r.mouse~=nil then A.Call(f,"EnableMouse",r.mouse~=false and r.mouse~=0); end;
end
function A.Restore()
 A.active=false; if A.frame then A.frame.editOverlay=false; end; if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatPanel",false); end; if A.popup then A.popup:Hide(); end
 for f in pairs(saved) do Release(f); end
 local pieces={}; for f in pairs(decor) do local depth=0; local parent=A.Call(f,"GetParent"); while parent do depth=depth+1; parent=A.Call(parent,"GetParent"); end; pieces[#pieces+1]={frame=f,depth=depth}; end
 table.sort(pieces,function(a,b) return a.depth<b.depth; end);
 for _,piece in ipairs(pieces) do Unquiet(piece.frame); end
 if A.survivorTaken then SurvivorUIDB.chatLook=A.survivorLook; A.survivorTaken=false; A.Safe(SurvivorUI_StyleChatPanel); end
 A.active=false;
end
local function Remember(f,r)
 if not f.AddMessage or r.wrapper then return; end
 history[f]=history[f] or {}; r.addMessage=f.AddMessage;
 r.wrapper=function(self,text,...)
  if text then local lines=history[self]; lines[#lines+1]=tostring(text); if #lines>300 then table.remove(lines,1); end end
  return r.addMessage(self,text,...);
 end; f.AddMessage=r.wrapper;
end
function A.Plain(text)
 return tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|H.-|h(.-)|h","%1"):gsub("|T.-|t","");
end
function A.CopyText(f)
 local lines={}; local count=A.Call(f,"GetNumMessages");
 if count and count>0 and f.GetMessageInfo then for i=math.max(1,count-299),count do local text=A.Call(f,"GetMessageInfo",i); if text then lines[#lines+1]=A.Plain(text); end end
 else for _,text in ipairs(history[f] or {}) do lines[#lines+1]=A.Plain(text); end end
 return table.concat(lines,"\n");
end
local function Frames()
 local out={};
 for i=1,(NUM_CHAT_WINDOWS or 7) do local f=_G["ChatFrame"..i]; if f and (i==1 or f.isDocked) then out[#out+1]={frame=f,id=i}; end end
 return out;
end
A.ChatFrames=Frames;
function A.SetEditMode(on)
 A.editing=on and true or false; local f=A.frame; if not f then return; end
 A.Apply();
end
function A.CurrentChat() return A.selectedChat or SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME or ChatFrame1; end
local function Select(f)
 if not f then return; end; if A.popup then A.popup:Hide(); end; A.selectedChat=f;
 if FCF_SelectDockFrame then A.Safe(FCF_SelectDockFrame,f); end
 SELECTED_DOCK_FRAME=f; for _,entry in ipairs(Frames()) do if entry.frame==f then f:Show(); else entry.frame:Hide(); end end
 A.Apply();
end
A.SelectChat=Select;
local function EditBox(edit,f)
 if not edit then return; end; local r=Capture(edit); edit:SetParent(f.inputHolder);
 if not edit.asrFocusHook then
  edit.asrFocusHook=true;
  local function Hook(event,after)
   local native=edit:GetScript(event);
   edit:SetScript(event,function(...) if native then native(...); end; after(); end);
  end
  local function RefreshInput(on) edit.asrHasFocus=on; A.lastInputEvent=on and "focus-gained" or "focus-lost/hide"; if A.active then A.Apply(); end end
  Hook("OnEditFocusGained",function() RefreshInput(true); end);
  Hook("OnEditFocusLost",function() RefreshInput(false); end);
  Hook("OnHide",function() RefreshInput(false); end);
  local function EndInput()
   A.lastInputEvent="enter/escape";
   edit.asrHasFocus=false;
   if not A.active then return; end
   A.Call(edit,"ClearFocus");
   if A.active then A.Apply(); end
  end
  Hook("OnEnterPressed",EndInput); Hook("OnEscapePressed",EndInput);
 end
 edit:ClearAllPoints(); edit:SetPoint("TOPLEFT",f.inputHolder,"TOPLEFT",0,0); edit:SetScale(1); edit:SetSize(f.inputHolder:GetWidth(),28);
 edit:SetFrameStrata(f:GetFrameStrata()); edit:SetFrameLevel(f:GetFrameLevel()+8); if r.font then edit:SetFont(r.font,ASRChatDB.fontSize,r.flags); end
 if edit.GetRegions then for _,region in ipairs({edit:GetRegions()}) do if A.Call(region,"GetObjectType")=="Texture" then Quiet(region); end end end

end
function A.Apply()
 if not A.ready or not A.frame then return; end; local f=A.frame; local d=ASRChatDB;
 if not d.enabled or not ChatFrame1 then if A.active then A.Restore(); end; f:Hide(); return; end
 if not A.active and SurvivorUIChatPanel and SurvivorUIChatPanel:IsShown() and SurvivorUIDB and SurvivorUI_StyleChatPanel then
  A.survivorTaken=true; A.survivorLook=SurvivorUIDB.chatLook; SurvivorUIDB.chatLook="text"; SurvivorUI_StyleChatPanel();
 end
 A.active=true;
 if not f.moving and not f.sizing then
  f:SetSize(d.width,d.height); f:SetScale(d.scale);
  if not (ASRSuiteDB and ASRSuiteDB.docking and ASRSuiteDB.docking.chat) then
   f:ClearAllPoints(); local p=d.position; if p then f:SetPoint(p.point,UIParent,p.relative,p.x,p.y); else f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",28,110); end
  end
 end
 local opacity=not d.ownOpacity and ASRSuite and ASRSuite.ready and ASRSuite.GetPanelOpacity and ASRSuite.GetPanelOpacity("chat",d.opacity) or d.opacity;
 f.skin:SetSize(f:GetWidth(),f:GetHeight()); A.PanelStyle(f.skin,d.frameStyle,opacity); A.ApplyLayers(f);
 f.asrDockInsets=d.frameStyle=="stone" and IsAddOnLoaded and IsAddOnLoaded("AzerothSurvivorsUI") and {left=1.5,right=1.5,top=10,bottom=11} or {left=0,right=0,top=0,bottom=0};
 f.title:SetText("|cff8cd123ASR|r / "..(d.language=="ru" and "Чат" or "Chat"));
 local move=A.CanMove(); if move then f.grip:Show(); else f.grip:Hide(); end
 local frames=Frames(); local selected=A.selectedChat or SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME or ChatFrame1; local found=false;
 for _,entry in ipairs(frames) do if entry.frame==selected then found=true; end end; if not found then selected=ChatFrame1; A.selectedChat=selected; end
 SELECTED_DOCK_FRAME=selected;
 -- Return windows detached through the native UI without moving their new seat.
 local managed={}; for _,entry in ipairs(frames) do managed[entry.frame]=true; end
 for chat,r in pairs(saved) do if r.chatId and not managed[chat] then
  local id=r.chatId; Release(chat,chat:GetParent()~=f and chat:GetParent()~=chat.asrClipContent);
  if chat.asrViewport then chat.asrViewport:Hide(); end
  local edit=_G["ChatFrame"..id.."EditBox"]; if edit then Release(edit,edit:GetParent()~=f); end
  Unquiet(_G["ChatFrame"..id.."Tab"]);
  for _,piece in ipairs(CHAT_FRAME_TEXTURES or {}) do Unquiet(_G["ChatFrame"..id..piece]); end
  for _,part in ipairs({"UpButton","DownButton","BottomButton","ButtonFrame"}) do Unquiet(_G["ChatFrame"..id..part]); end
 end end
 -- Snapshot the complete native dock before changing an ancestor or edit box.
 for _,entry in ipairs(frames) do Capture(entry.frame); local edit=_G["ChatFrame"..entry.id.."EditBox"]; if edit then Capture(edit); end end
 if ChatFrameEditBox then Capture(ChatFrameEditBox); end
 local layout=A.ApplyChrome(f,frames); local top=layout.top; local inset=layout.left; local textHeight=math.max(30,f:GetHeight()-top-layout.bottom);
 for _,name in ipairs({"ChatFrameMenuButton","FriendsMicroButton","ChatFrameChannelButton"}) do A.QuietTree(_G[name]); end
 for index,entry in ipairs(frames) do
  local chat,id=entry.frame,entry.id; local r=Capture(chat); r.chatId=id; Remember(chat,r);
  if chat==selected then chat:Show(); else chat:Hide(); end
  if not chat.asrViewport then
   local viewport=CreateFrame("ScrollFrame",nil,f); local content=CreateFrame("Frame",nil,viewport);
   viewport:SetScrollChild(content); content:SetPoint("TOPLEFT",viewport,"TOPLEFT",0,0);
   chat.asrViewport=viewport; chat.asrClipContent=content;
  end
  local viewport=chat.asrViewport; local content=chat.asrClipContent;
  viewport:ClearAllPoints(); viewport:SetPoint("TOPLEFT",f,"TOPLEFT",inset,-top); viewport:SetSize(f:GetWidth()-inset-layout.padding,textHeight);
  viewport:SetFrameStrata(f:GetFrameStrata()); viewport:SetFrameLevel(f:GetFrameLevel()+1);
  content:SetSize(viewport:GetWidth(),textHeight); content:SetFrameLevel(f:GetFrameLevel()+1);
  if chat==selected then viewport:Show(); else viewport:Hide(); end
  chat:SetParent(content);
  local p,rel,relativePoint,x,y=chat:GetPoint();
  if p~="TOPLEFT" or rel~=f or relativePoint~="TOPLEFT" or x~=inset or y~=-top or A.Call(chat,"GetNumPoints")~=1 then
   chat:ClearAllPoints(); chat:SetPoint("TOPLEFT",f,"TOPLEFT",inset,-top);
  end
  chat:SetScale(1); chat:SetSize(f:GetWidth()-inset-layout.padding,textHeight); chat:SetFont(r.font or S.font,d.fontSize,r.flags or "");
  A.Call(chat,"SetSpacing",d.spacing); A.Call(chat,"SetFading",d.fading); A.Call(chat,"SetTimeVisible",d.timeVisible); A.Call(chat,"SetFadeDuration",2);
  chat:SetFrameStrata(f:GetFrameStrata()); chat:SetFrameLevel(f:GetFrameLevel()+2);
  if not r.wheelChanged then
   r.wheelChanged=true; chat:EnableMouseWheel(true); chat:SetScript("OnMouseWheel",function(self,delta)
    if IsShiftKeyDown and IsShiftKeyDown() then A.Call(self,delta>0 and "ScrollToTop" or "ScrollToBottom"); else A.Call(self,delta>0 and "ScrollUp" or "ScrollDown"); end
   end);
  end
  Quiet(_G["ChatFrame"..id.."Tab"]);
  for _,piece in ipairs(CHAT_FRAME_TEXTURES or {}) do Quiet(_G["ChatFrame"..id..piece]); end
  for _,part in ipairs({"UpButton","DownButton","BottomButton","ButtonFrame"}) do A.QuietTree(_G["ChatFrame"..id..part]); end
  for _,side in ipairs({"TopLeft","TopRight","BottomLeft","BottomRight","Top","Bottom","Left","Right"}) do A.QuietTree(_G["ChatFrame"..id.."Resize"..side]); end
  EditBox(_G["ChatFrame"..id.."EditBox"],f);
  local tab=f.tabs[index]; if not tab then tab=A.NewTab(f); f.tabs[index]=tab; end
  tab.chat=chat; local name=A.Safe(GetChatWindowInfo,id) or (id==1 and A.T("Общий") or tostring(id));
  tab.text:SetText(name); tab.text:SetFont(S.font,10,""); local width=math.max(42,math.min(110,tab.text:GetStringWidth()+18));
  tab:SetWidth(width); entry.width=width; entry.name=name;
  A.StyleTab(tab,chat==selected);

 end
 A.LayoutTabs(f,frames,selected,layout);
 for i=#frames+1,#f.tabs do f.tabs[i]:Hide(); end
 EditBox(ChatFrameEditBox,f); f:Show(); A.UpdateVisibility();
end
function A.OpenCopy()
 if A.settings then A.settings:Hide(); end; if ASRSuite and ASRSuite.settings then ASRSuite.settings:Hide(); end; if A.popup then A.popup:Hide(); end
 if not A.copy then
  local f=CreateFrame("Frame","ASRChatCopy",UIParent); A.copy=f; f:SetSize(520,370); f:SetScale(math.min(1,(UIParent:GetWidth()-24)/520,(UIParent:GetHeight()-24)/370)); f:SetPoint("CENTER",UIParent,"CENTER",0,0); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(650); S.Panel(f,0.98);
  f.title=S.Label(f,"",11,28,26,420); S.Button(f,"×",24,24,468,24,function() f:Hide(); end);
  f.scroll=CreateFrame("ScrollFrame",nil,f); f.scroll:SetSize(464,232); f.scroll:SetPoint("TOPLEFT",f,"TOPLEFT",28,-65);
  f.edit=CreateFrame("EditBox",nil,f.scroll); f.edit:SetSize(450,232); f.edit:SetMultiLine(true); f.edit:SetAutoFocus(false); f.edit:SetFont(S.font,11,""); f.scroll:SetScrollChild(f.edit);
  f.scroll:EnableMouseWheel(true); f.scroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,math.min(math.max(0,f.edit:GetHeight()-232),self:GetVerticalScroll()-delta*40))); end);
  f.edit:SetScript("OnTextChanged",function(self) self:SetHeight(math.max(232,A.Call(self,"GetStringHeight") or 232)); end);
  f.edit:SetScript("OnEscapePressed",function() f:Hide(); end);
  f.select=S.Button(f,"",464,26,28,320,function() f.edit:SetFocus(); f.edit:HighlightText(); end);
  f:SetScript("OnHide",function() f.edit:ClearFocus(); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatCopy",false); end; A.Apply(); end);
 end
 local f=A.copy; f.title:SetText(A.T("Последние сообщения текущей вкладки. Ctrl+C — копировать.")); f.select.text:SetText(A.T("Выделить всё"));
 local text=A.CopyText(A.CurrentChat()); if text=="" then text=A.T("Пока нет сообщений"); end
 f.edit:SetText(text); f.scroll:SetVerticalScroll(0); f:Show(); S.SyncChildren(f); if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASRChatCopy",true); end; f.edit:SetFocus(); f.edit:HighlightText(); A.Apply();
end
function A.CreateUI()
 local f=CreateFrame("Frame","ASRChatPanel",UIParent); A.frame=f; f:SetSize(396,220); f:SetFrameStrata("HIGH"); f:SetFrameLevel(20); f:SetMovable(true); f:EnableMouse(true); f:SetResizable(true); f:SetMinResize(196,180); f:SetMaxResize(900,600); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton"); f.tabs={};
 f.skin=CreateFrame("Frame",nil,f); f.skin:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); f.skin:EnableMouse(false);
 f:SetScript("OnDragStart",function(self) if A.CanMove() then self:StartMoving(); self.moving=true; end end); f:SetScript("OnDragStop",A.StopDrag);
 f.header=CreateFrame("Frame",nil,f); f.header:SetSize(360,24); f.header:SetPoint("TOPLEFT",f,"TOPLEFT",18,-16); f.header:EnableMouse(false); f.header:RegisterForDrag("LeftButton");
 f.header:SetScript("OnDragStart",function() f:GetScript("OnDragStart")(f); end); f.header:SetScript("OnDragStop",A.StopDrag);
 f.title=S.Label(f.header,"",11,0,3,200);
 f.settings=S.Button(f.header,"≡",22,19,0,0,function() A.settings:Show(); end); f.settings:ClearAllPoints(); f.settings:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-17);
 f.copyButton=S.Button(f.header,"C",22,19,0,0,A.OpenCopy); f.copyButton:ClearAllPoints(); f.copyButton:SetPoint("TOPRIGHT",f.settings,"TOPLEFT",-5,0);
 f.more=S.Button(f,">",20,20,0,0,function()
  local frames=Frames(); local current=SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME or ChatFrame1; local index=1;
  for i,entry in ipairs(frames) do if entry.frame==current then index=i; end end
  if #frames>0 then Select(frames[index%#frames+1].frame); end
 end);
 f.grip=CreateFrame("Button",nil,f); f.grip:SetSize(18,18); f.grip:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1); f.grip.text=S.Label(f.grip,"+",12,0,0,18);
 f.grip.text:ClearAllPoints(); f.grip.text:SetPoint("CENTER",f.grip,"CENTER",0,0); f.grip.text:SetJustifyH("CENTER");
 f.grip:SetScript("OnMouseDown",function(self,button) if button=="LeftButton" and A.CanMove() then f:StartSizing("BOTTOMRIGHT"); f.sizing=true; end end); f.grip:SetScript("OnMouseUp",A.StopDrag); A.CreateChrome(f); f:Hide(); A.Apply();
end

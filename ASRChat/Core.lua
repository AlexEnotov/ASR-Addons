ASRChat={VERSION="0.6.4",ready=false}; local A=ASRChat;
ASRLocale.RegisterTranslations("chat","en",{
 ["Всегда показывать чат"]="Always show chat",["Всегда показывать поле ввода"]="Always show input field",
 ["Модуль включён"]="Module enabled",["Вид"]="Appearance",["Поведение"]="Behavior",
 ["Ширина"]="Width",["Высота"]="Height",["Масштаб"]="Scale",["Размер текста"]="Text size",
 ["Фон"]="Background",["Фон: свой"]="Background: own",["Фон: общий"]="Background: shared",["Интервал строк"]="Line spacing",["Рамка: камень"]="Frame: stone",["Рамка: простая"]="Frame: simple",
 ["Закрепить"]="Lock panel",["Затухание сообщений"]="Fade messages",["Показывать сообщения, сек."]="Keep messages, sec.",
 ["Ввод сверху"]="Input above chat",["Скрыть кнопки прокрутки"]="Hide scroll buttons",["Показывать заголовок"]="Show header",
 ["Копировать чат"]="Copy chat",["Сбросить положение"]="Reset position",["Изменить интерфейс"]="Edit interface",
 ["Перетащи заголовок. Угол справа снизу меняет размер."]="Drag the header. Drag the lower-right corner to resize.",
 ["Выделить всё"]="Select all",["Последние сообщения текущей вкладки. Ctrl+C — копировать."]="Recent messages in the current tab. Ctrl+C to copy.",
 ["Пока нет сообщений"]="No messages yet",["Пример сообщения группы"]="Example party message",["Получена новая вещь"]="New item received",
 ["Настройки"]="Settings",["Рамка: нет"]="Frame: none",["Показывать кнопки"]="Show buttons",["Канал сообщения"]="Message channel",["Друзья в сети"]="Friends online",["Выше"]="Scroll up",["Ниже"]="Scroll down",["Последние сообщения"]="Latest messages",["Вкладки"]="Chat tabs",["Сказать"]="Say",["Группа"]="Party",["Рейд"]="Raid",["Крик"]="Yell",["Шёпот"]="Whisper",["Эмоция"]="Emote",["Общий"]="General",["Сообщения и команды остаются штатными."]="Messages and commands use the native chat.",
});
function A.T(key) return ASRLocale.Text("chat",ASRChatDB and ASRChatDB.language or "en",key); end
function A.Safe(fn,...) if type(fn)~="function" then return; end; local ok,a,b,c,d,e,f=pcall(fn,...); if ok then return a,b,c,d,e,f; end end
function A.Call(object,method,...) if object then return A.Safe(object[method],object,...); end end
local defaults={enabled=true,locked=false,width=396,height=220,scale=0.85,fontSize=12,opacity=0.75,spacing=2,fading=true,timeVisible=30,inputTop=false,alwaysShowChat=false,hideButtons=true,showTools=true,showHeader=true,stone=true,ownOpacity=false,language="en"};
function A.Init()
 if type(ASRChatDB)~="table" then ASRChatDB={}; end; local d=ASRChatDB;
 if type(d.alwaysShowInput)~="boolean" then d.alwaysShowInput=false; end
 for key,value in pairs(defaults) do if type(d[key])~=type(value) then d[key]=value; end end
 for key,limits in pairs({width={196,900},height={180,600},scale={0.5,1.5},fontSize={10,22},opacity={0,1},spacing={0,8},timeVisible={5,300}}) do
  local n=tonumber(d[key]); if not n or n~=n then n=defaults[key]; end; d[key]=math.max(limits[1],math.min(limits[2],n));
 end
 if not ({stone=true,simple=true,none=true})[d.frameStyle] then d.frameStyle=d.stone and "stone" or "simple"; end
 d.language=ASRLocale.Normalize(d.language); A.ready=true;
end
function A.CanMove() if A.editing then return true; end; if ASRSuite and ASRSuite.ready then return ASRSuite.CanMovePanel("chat"); end; return not ASRChatDB.locked; end
function A.StopDrag()
 local f=A.frame; if not f then return; end
 if f.moving or f.sizing then
  local sizing=f.sizing; f:StopMovingOrSizing(); f.moving=false; f.sizing=false;
  if sizing then ASRChatDB.width=math.max(196,math.min(900,f:GetWidth())); ASRChatDB.height=math.max(180,math.min(600,f:GetHeight())); end
  local point,_,relative,x,y=f:GetPoint(); ASRChatDB.position={point=point,relative=relative,x=x,y=y};
  A.Apply(); A.DrawSettings();
 end
end
function A.SetEnabled(on) A.StopDrag(); ASRChatDB.enabled=on and true or false; A.Apply(); A.DrawSettings(); end
function A.SetLanguage(value) ASRChatDB.language=ASRLocale.Normalize(value); A.Apply(); A.DrawSettings(); end
function A.ResetPosition() ASRChatDB.position=nil; if ASRSuiteDB and ASRSuiteDB.docking then ASRSuiteDB.docking.chat=nil; end; A.Apply(); end
local runtime=CreateFrame("Frame","ASRChatRuntime"); runtime:RegisterEvent("ADDON_LOADED"); runtime:RegisterEvent("PLAYER_ENTERING_WORLD"); runtime:RegisterEvent("PLAYER_LOGOUT");
runtime:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" and name=="ASRChat" then A.Init(); A.CreateUI(); A.CreateSettings(); end
 if event=="PLAYER_LOGOUT" then A.StopDrag(); end
 if A.ready then A.BindSuite(); A.Apply(); end
end);
local elapsed=0;
runtime:SetScript("OnUpdate",function(self,dt)
 if not A.ready then return; end
 if A.debugDelay then A.debugDelay=A.debugDelay-dt; if A.debugDelay<=0 then A.debugDelay=nil; A.DebugInput(); end end
 A.UpdateVisibility(dt);
 if A.frame and (A.frame.moving or A.frame.sizing) and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then A.StopDrag(); end
 if A.frame and A.frame.sizing then A.Apply(); return; end
 elapsed=elapsed+dt; if elapsed<0.3 then return; end; elapsed=0; A.BindSuite(); A.Apply();
end);
SLASH_ASRCHAT1="/asrchat";
SlashCmdList.ASRCHAT=function(msg)
 if not A.ready then return; end; msg=string.lower(string.match(msg or "","^%s*(.-)%s*$"));
 if msg=="on" or msg=="off" then A.SetEnabled(msg=="on");
 elseif msg=="lock" or msg=="unlock" then ASRChatDB.locked=msg=="lock"; A.Apply(); A.DrawSettings();
 elseif msg=="debug" then A.debugDelay=2;
 elseif msg=="copy" then A.OpenCopy(); elseif msg=="reset" then A.ResetPosition();
 elseif ASRLocale.IsLanguage(msg) then A.SetLanguage(msg);
 else if A.settings:IsShown() then A.settings:Hide(); else A.settings:Show(); end end
end;

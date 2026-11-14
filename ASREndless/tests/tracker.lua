local A=ASREndless; local checks=0;
local function check(ok,name) assert(ok,name); checks=checks+1; end
local schedule={}; for i,name in ipairs({"Хоггер","Матушка Клык","Рахк'Зор","Мистер Смайт","Эдвин Ван Клиф"}) do schedule[i]={index=i,name=name,at=i*180,state="dead",final=i==5 and 1 or 0}; end
local zone={run="azs:r123",map=1,zname="Элвиннский лес"};
local state;
local function step(t,bk,nb,units)
 local r={t=t,bk=bk,nb=nb,nbin=nb,endless=1,ph="playing",lvl=59,kills=36068};
 local m; m,state=A.EndlessStep(r,zone,schedule,units or {},state); return m;
end
local function boss(index,id) return {kind=index==5 and "final" or "boss",name=schedule[index].name,id=id or index,hp=500,hpm=1000}; end
local m=step(205.3,5,60);
check(m.nextIn==60 and m.nextName=="Хоггер" and m.round==1 and m.killed==0,"live capture: first countdown starts at 60 seconds");
check(m.rows[1].status=="next" and m.progress==0,"completed map entries do not hide endless countdown");
m=step(235.3,5,30); check(math.abs(m.progress-0.5)<0.01,"bar advances from authoritative countdown");
m=step(265,5,0,{boss(1)}); check(m.spawned==1 and m.live[1].name=="Хоггер" and m.nextName=="Матушка Клык","appearance advances queue before a boss dies");
m=step(267.2,5,-1,{boss(1)}); check(m.nextIn==nil and m.rows[1].status=="up","unavailable timer is not rendered as a negative time");
m=step(271.2,6,114); check(m.killed==1 and m.rows[1].status=="dead" and m.nextIn==114,"live capture: first kill and next countdown");
m=step(386.4,6,-1,{boss(2)}); check(m.spawned==2 and m.live[1].serial==2,"live capture: second boss follows map order");
m=step(388.4,7,117); check(m.killed==2 and m.nextName=="Рахк'Зор","live capture: second kill");
m=step(506,7,-1,{boss(3)}); check(m.spawned==3 and m.rows[2].name=="Мистер Смайт","live capture: third boss");
step(507.3,8,118); m=step(625.9,9,119); check(m.spawned==4 and m.killed==4,"boss killed between polls still advances the queue");
m=step(746.9,10,119); check(m.round==2 and m.nextRound==2 and m.nextName=="Хоггер","fifth kill prepares the next round");
check(m.bossRows[1].status=="next" and m.bossRows[2].status=="future","completed round resets all old defeated markers");
m=step(866.7,11,119); check(m.spawned==6 and m.round==2 and m.nextName=="Матушка Клык","live capture: first kill in the next round");
local saved=state; local before=m.spawned; m,state=A.EndlessStep({t=873.3,bk=11,nb=112,endless=1},zone,schedule,{},saved);
check(m.spawned==before and m.round==2,"saved reducer state survives reload");
local late=A.EndlessStep({t=873.3,bk=11,nb=112,endless=1},zone,schedule,{});
check(late.round==2 and late.spawned==6,"installing midway reconstructs progress from total boss kills");
state=nil; m=step(510,6,-1,{boss(2),boss(3)});
check(m.spawned==3 and #m.live==2 and m.nextName=="Мистер Смайт","two live bosses are counted independently from kills");
check(m.live[1].serial==2 and m.live[2].serial==3 and m.rows[1].status=="up","queue retains the oldest living boss");
m=step(515,7,-1,{boss(3)}); check(m.spawned==3,"killing an older boss does not advance the queue again");
m,state=A.EndlessStep({t=20,bk=5,nb=60,endless=1},{run="azs:r456",map=1},schedule,{},state);
check(m.spawned==0 and m.round==1,"another run on the same map resets counters");
check(A.EndlessStep({t=20,endless=0},zone,schedule,{})==nil,"ordinary map mode never replaces tracker");
check(A.EndlessStep({t=20,endless=1},zone,{}, {})==nil,"missing schedule falls back to native HUD");

local shown=true; local calls={}; AZS_API_HUD={};
function AZS_IsHudShown(part) return shown; end
function AZS_SetHudShown(part,on) check(part=="clock","only tracker/clock HUD is changed"); shown=on; AZS_API_HUD.clock=not on and "ASREndless" or nil; calls[#calls+1]=on; end
AZS_RUN={t=900,bk=11,nb=85,endless=1,ph="playing",kills=36068,lvl=59}; AZS_ZONE=zone; AZS_SCHEDULE=schedule; AZS_UNITS={};
ASREndlessDB.endlessEnabled=true; ASREndlessDB.endlessState=nil; A.SetLanguage("en");
A.UpdateEndless(0,true);
check(A.endlessFrame:IsShown() and not shown,"endless tracker atomically replaces native tracker");
check(A.endlessFrame.rows[2].status:GetText()=="1:25" and A.endlessFrame.rows[2].status.justifyH=="RIGHT","next boss displays countdown in the right status column");
check(A.endlessFrame.rows[1].name:GetText()=="Hogger" and A.endlessFrame.rows[1].status:GetText()=="Defeated","boss name and defeated status follow suite English without kill fractions");
check(A.endlessFrame.zone:GetText()=="Elwynn Forest" and A.endlessFrame.rows[2].name:GetText()=="Mother Fang","Russian API map and boss names display in English");
check(A.endlessFrame.levelText.fontSize==13 and A.endlessFrame.rows[1].name.fontSize==12,"level and boss labels use smaller type");
check(#A.endlessFrame.rows==5 and A.endlessFrame.rows[2].dot:IsShown() and not A.endlessFrame.rows[3].dot:IsShown(),"full boss list uses native filled and empty objective sockets");
check(not A.endlessFrame.backdrop and A.endlessFrame.head.backdrop and not A.endlessFrame.viewport,"only the native-style header has a background and frame");
check(A.endlessFrame:GetHeight()==244,"five native-sized boss rows fit below the compact header");
check(A.endlessFrame.difficulty:GetText()=="Normal","map caption includes normal difficulty in English");
check(A.EndlessDifficulty({heroic=1})=="Heroic" and A.EndlessDifficulty({difficulty="Heroic 5"})=="Heroic 5","heroic flag and named tiers are retained");
local charge;
function AZS_BuildBossChargeBar(holder) return function(value,text) charge={value=value,text=text}; end,293; end
A.UpdateEndless(0,true); check(charge and charge.text=="0%" and not A.endlessFrame.bar:IsShown(),"native charge bar shows percentages only");
A.endlessModel.zone=string.rep("Очень длинное имя карты ",8); A.DrawEndless(A.endlessModel);
check(A.endlessFrame.zone:GetStringWidth()+A.endlessFrame.difficulty:GetStringWidth()+6<=246,"map and gray difficulty caption fit together without wrapping");
zone.zname="Naxxramas"; zone.diff="Heroic V"; zone.affixes="Bolstering,Sanguine"; A.UpdateEndless(0,true);
check(A.endlessFrame.zone:GetText()=="Naxxramas" and A.endlessFrame.difficulty:GetText()=="Heroic V","other maps retain the server's Roman-numeral heroic tier");
check(#A.endlessFrame.affixIcons==2 and A.endlessFrame.affixIcons[1]:IsShown() and A.endlessFrame:GetHeight()==280,"heroic affix icons have their own space above objectives");
zone.affixes=nil; zone.diff=nil; A.UpdateEndless(0,true); check(not A.endlessFrame.affixIcons[1]:IsShown(),"obsolete affix icons are removed");
A.SetLanguage("ru"); A.UpdateEndless(0,true);
check(A.endlessFrame.round:GetText():find("Круг 2",1,true),"Russian labels follow suite language");
check(A.endlessFrame.zone:GetText()=="Наксрамас" and A.endlessFrame.rows[1].name:GetText()=="Хоггер","switching back to Russian translates English catalog names");
check(A.EndlessName("My custom community map")=="My custom community map","unknown community names are preserved");
A.SetLanguage("en"); check(A.EndlessDifficulty({difficulty="Героический V"})=="Heroic V","localized heroic tier also follows suite language");
local oldNative,oldCatalog=AZS_L,AZS_GEN;
AZS_L={Hogger="Hogger-fr"}; AZS_GEN={zones={{name="Elwynn Forest",bosses={{name="Hogger"}}}}};
check(A.EndlessName("Hogger-fr")=="Hogger","native catalog resolves names received in another game language");
ASRLocale.Register("test-locale","Test"); ASRLocale.RegisterTranslations("world","test-locale",{Hogger="Test Hogger"}); A.SetLanguage("test-locale");
check(A.EndlessName("Hogger-fr")=="Test Hogger","world-name translations support additional registered languages");
AZS_L,AZS_GEN=oldNative,oldCatalog; A.SetLanguage("ru");
check(A.settings.enabled~=nil,"Endless section contains a visibility checkbox");
A.settings.enabled.scripts.OnClick();
check(not A.endlessFrame:IsShown() and shown and ASREndlessDB.endlessEnabled==false,"settings checkbox restores native HUD immediately");
A.settings.enabled.scripts.OnClick(); check(A.endlessFrame:IsShown() and not shown,"settings checkbox enables replacement again");
AZS_RUN.ph="paused"; A.UpdateEndless(0,true); check(A.endlessFrame:IsShown(),"pause retains endless tracker");
AZS_RUN.ph="dead"; A.UpdateEndless(0,true); check(A.endlessFrame:IsShown(),"death screen retains run summary until exit");
AZS_RUN={ph="ready",endless=0}; A.UpdateEndless(0,true);
check(not A.endlessFrame:IsShown() and shown and not ASREndlessDB.endlessState,"leaving endless restores HUD and clears run state");
shown=false; AZS_API_HUD.clock="OtherAddon";
AZS_RUN={t=900,bk=11,nb=85,endless=1,ph="playing"}; A.UpdateEndless(0,true);
ASREndlessDB.endlessEnabled=false; A.UpdateEndless(0,true);
check(not shown and AZS_API_HUD.clock=="OtherAddon","pre-existing hidden clock is not enabled by cleanup");
-- Reload may leave API ownership in saved variables; a non-endless load must release it.
ASREndlessDB.endlessHud={previous=true}; AZS_API_HUD.clock="ASREndless"; AZS_RUN={}; A.UpdateEndless(0,true);
check(shown and ASREndlessDB.endlessHud==nil,"reload outside endless releases persisted HUD suppression");
local displayTime=100; function AZS_GetRunTime() return displayTime; end
local function clockModel() return {time=100,nextIn=10,nextAt=110,interval=10,progress=0}; end
local last=11;
for i=0,19 do
 displayTime=100+i*0.5; local display=A.EndlessDisplayClock(clockModel()); local seconds=math.ceil(display.nextIn);
 check(seconds==10-math.floor(i/2) and last-seconds<=1,"interpolated countdown ticks once per second between protocol packets"); last=seconds;
end
displayTime=105; local paused=A.EndlessDisplayClock(clockModel()); local pausedAgain=A.EndlessDisplayClock(clockModel());
check(paused.nextIn==pausedAgain.nextIn and paused.progress==0.5,"frozen game clock freezes the countdown and progress bar");
check(A.EndlessDisplayClock({time=100}).nextIn==nil,"missing server countdown is never invented");
AZS_GetRunTime=nil;
ASREndlessDB.endlessEnabled=true; A.SetLanguage("en");
print("PASS: "..checks.." endless tracker checks");

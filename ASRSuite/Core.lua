ASRSuite={VERSION="0.4.3",ready=false}; local A=ASRSuite;
local defaults={enabled=true,mode="columns",fontSize=16,lifetime=1.6,rise=85,merge=0.35,spacing=0,icons=true,periodic=true,heals=true,taken=true,short=true,minimapAngle=220,opacity=0.95};
A.lanes={"normal","critical","heal","taken"};
A.positions={normal={x=-190,y=25},critical={x=190,y=25},heal={x=-100,y=-125},taken={x=100,y=-125}};
function A.Number(v) local n=tonumber(v); if n and n==n and math.abs(n)<1e12 then return n; end end
function A.InRun() local ph=AZS_RUN and AZS_RUN.ph; return ph=="playing" or ph=="ready" or ph=="choosing" or ph=="dead"; end
function A.Init()
 if type(ASRSuiteDB)~="table" then ASRSuiteDB={}; end
 A.hadLegacyCombat=ASRSuiteDB.fontSize~=nil or ASRSuiteDB.positions~=nil or ASRSuiteDB.types~=nil;
 for k,v in pairs(defaults) do if type(ASRSuiteDB[k])~=type(v) then ASRSuiteDB[k]=v; end end
 if A.CombatConfig().mode~="columns" and A.CombatConfig().mode~="enemies" then A.CombatConfig().mode="columns"; end
 for _,spec in ipairs({{"fontSize",10,36},{"lifetime",0.6,4},{"rise",20,200},{"merge",0,1},{"spacing",0,80},{"minimapAngle",0,360},{"opacity",0.2,1}}) do ASRSuiteDB[spec[1]]=math.max(spec[2],math.min(spec[3],A.Number(ASRSuiteDB[spec[1]]) or defaults[spec[1]])); end
 if not A.Number(A.CombatConfig().scrollSpeed) then A.CombatConfig().scrollSpeed=A.CombatConfig().rise/A.CombatConfig().lifetime; end
 A.CombatConfig().scrollSpeed=math.max(0,math.min(300,A.CombatConfig().scrollSpeed));
 if type(A.CombatConfig().positions)~="table" then A.CombatConfig().positions={}; end
 for _,key in ipairs(A.lanes) do local p=A.CombatConfig().positions[key]; if type(p)~="table" or not A.Number(p.x) or not A.Number(p.y) then A.CombatConfig().positions[key]={x=A.positions[key].x,y=A.positions[key].y}; end end
 A.AttachCombat(); A.InitProfiles(); A.InitIntegration(); A.InitLanguage(); A.ready=true;
end
function A.StopDrag(frame)
 if not frame or not frame.moving then return; end
 frame:StopMovingOrSizing(); frame.moving=false;
 local cx,cy=frame:GetCenter(); if cx and cy and frame.lane then A.CombatConfig().positions[frame.lane]={x=cx-UIParent:GetWidth()/2,y=cy-UIParent:GetHeight()/2}; end
 if frame.saveDrag then frame.saveDrag(frame); end
end
function A.SetEditing(on)
 A.editing=on and true or false; if GameTooltip then GameTooltip:Hide(); end
 if A.editing and A.ClearCombat then A.ClearCombat(); end
 if ASRStats and ASRStats.SetEditMode then ASRStats.SetEditMode(A.editing); end
 if ASAdvisor and ASAdvisor.SetEditMode then ASAdvisor.SetEditMode(A.editing); end
 for _,adapter in pairs(A.panelAdapters or {}) do if adapter.setEditing then adapter.setEditing(A.editing); end end
 if A.UpdateHandles then A.UpdateHandles(); end
 if A.DrawSettings then A.DrawSettings(); end
 if A.ApplyDocking then A.ApplyDocking(); end
end
function A.Enabled(on)
 if A.HasCombat() then ASRCombatText.SetEnabled(on and true or false); end
 if A.DrawSettings then A.DrawSettings(); end
end
function A.ResetPositions()
 for _,key in ipairs(A.lanes) do A.CombatConfig().positions[key]={x=A.positions[key].x,y=A.positions[key].y}; end
 if A.UpdateHandles then A.UpdateHandles(); end
end
local clock=CreateFrame("Frame","ASRSuiteRuntime"); clock:RegisterEvent("ADDON_LOADED"); clock:RegisterEvent("PLAYER_ENTERING_WORLD");
clock:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" and name=="ASRSuite" then
  A.Init(); A.CreateCombat(); A.CreateSources(); A.CreateUI(); A.InitDocking(); if A.HasCombat() then if not A.SelectDisplaySource("combat",ASRSuiteDB.sources.combat) then A.Enabled(false); end end
  AZS.On("AZSEND",function() A.ClearCombat(); end); AZS.On("AZSZONE",function() A.ClearCombat(); end);
 elseif event=="PLAYER_ENTERING_WORLD" and A.ready then A.ApplyCombat(); end
end);
local elapsed=0;
clock:SetScript("OnUpdate",function(self,dt)
 if not A.ready then return; end
 if A.UpdateDocking then A.UpdateDocking(dt); end
 -- ASR Combat Text owns its own runtime, even without the suite.
 if A.editing then for _,frame in pairs(A.handles or {}) do if frame.moving and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then A.StopDrag(frame); end end end
 elapsed=elapsed+dt; if elapsed>=0.5 then elapsed=0; if A.RefreshStatus then A.RefreshStatus(); end end
end);
SLASH_ASRSUITE1="/asrhub";
SlashCmdList.ASRSUITE=function(msg) if not A.ready then return; end; if msg=="edit" then A.SetEditing(not A.editing); else A.ToggleSettings(); end end;

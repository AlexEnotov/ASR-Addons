ASRCombatText={VERSION="0.1.6",ready=false}; local A=ASRCombatText;
A.lanes={"normal","critical","heal","taken"}; A.typeKeys={"normal","critical","heal","taken","periodic"};
A.positions={normal={x=-190,y=25},critical={x=190,y=25},heal={x=-100,y=-125},taken={x=100,y=-125}};
local defaults={enabled=true,mode="columns",fontSize=16,lifetime=1.6,rise=85,merge=0.35,spacing=0,icons=true,periodic=true,heals=true,taken=true,short=true,combatOpacity=1,language="en",minimapAngle=250};
A.styleFields={{"fontSize",10,36},{"scrollSpeed",0,300},{"lifetime",0.6,4},{"rise",20,200},{"merge",0,1},{"spacing",0,80},{"icons"},{"short"}};
function A.Number(v) local n=tonumber(v); if n and n==n and math.abs(n)<1e12 then return n; end end
function A.InRun() local p=AZS_RUN and AZS_RUN.ph; return p=="playing" or p=="choosing" or p=="ready" or p=="dead"; end
function A.RefreshConfig()
 if type(ASRCombatTextDB)~="table" then ASRCombatTextDB={}; end; local d=ASRCombatTextDB;
 for k,v in pairs(defaults) do if type(d[k])~=type(v) then d[k]=v; end end
 if d.mode~="columns" and d.mode~="enemies" then d.mode="columns"; end
 d.language=ASRLocale.Normalize(d.language);
 d.scrollSpeed=A.Number(d.scrollSpeed) or d.rise/d.lifetime;
 for _,spec in ipairs(A.styleFields) do if spec[2] then d[spec[1]]=math.max(spec[2],math.min(spec[3],A.Number(d[spec[1]]) or 0)); end end
 d.combatOpacity=math.max(0,math.min(1,A.Number(d.combatOpacity) or 1));
 if type(d.positions)~="table" then d.positions={}; end
 if type(d.types)~="table" then d.types={}; end
 for _,kind in ipairs(A.typeKeys) do
  if A.positions[kind] then local p=d.positions[kind]; if type(p)~="table" or not A.Number(p.x) or not A.Number(p.y) then d.positions[kind]={x=A.positions[kind].x,y=A.positions[kind].y}; end end
  local p=d.types[kind]; if type(p)~="table" then p={}; d.types[kind]=p; end
  if type(p.custom)~="boolean" then p.custom=false; end
  if type(p.shown)~="boolean" then p.shown=not (kind=="heal" and d.heals==false or kind=="taken" and d.taken==false or kind=="periodic" and d.periodic==false); end
  if type(p.values)~="table" then p.values={}; end
  for _,spec in ipairs(A.styleFields) do local k=spec[1]; if spec[2] then p.values[k]=math.max(spec[2],math.min(spec[3],A.Number(p.values[k]) or d[k])); elseif type(p.values[k])~="boolean" then p.values[k]=d[k]; end end
 end
end
function A.EffectiveOptions(kind) local p=ASRCombatTextDB.types[kind]; return p and p.custom and p.values or ASRCombatTextDB; end
function A.SetCustom(kind,on) local p=ASRCombatTextDB.types[kind]; if on and not p.initialized then for _,f in ipairs(A.styleFields) do p.values[f[1]]=ASRCombatTextDB[f[1]]; end; p.initialized=true; end; p.custom=on; end
function A.TypeShown(kind) local d=ASRCombatTextDB; local p=d.types[kind]; return (not p or p.shown~=false) and not (kind=="heal" and d.heals==false or kind=="taken" and d.taken==false or kind=="periodic" and d.periodic==false); end
function A.SetTypeShown(kind,on) local d=ASRCombatTextDB; d.types[kind].shown=on; if kind=="heal" then d.heals=on; elseif kind=="taken" then d.taken=on; elseif kind=="periodic" then d.periodic=on; end end
function A.GetPanelOpacity(_,localValue,category) if ASRSuite and ASRSuite.GetPanelOpacity and ASRSuite.ready then return ASRSuite.GetPanelOpacity("combat",localValue,category); end; return localValue; end
function A.SetEnabled(on) ASRCombatTextDB.enabled=on; A.ApplyCombat(); end
function A.AttachSuite(on) A.suiteAttached=on; if A.minimap then if on then A.minimap:Hide(); else A.minimap:Show(); end end; if on and A.settings then A.settings:Hide(); end; if on and A.SetEditing then A.SetEditing(false); end end
local frame=CreateFrame("Frame","ASRCombatTextRuntime"); frame:RegisterEvent("ADDON_LOADED"); frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" and name=="ASRCombatText" then A.RefreshConfig(); A.ready=true; A.CreateCombat(); A.CreateUI(); A.ApplyCombat(); AZS.On("AZSEND",A.ClearCombat); AZS.On("AZSZONE",A.ClearCombat);
 elseif event=="PLAYER_ENTERING_WORLD" and A.ready then A.ApplyCombat(); end
end);
frame:SetScript("OnUpdate",function(self,dt) if A.ready then A.UpdateCombat(dt); if A.settings and A.settings:IsShown() then ASRStyle.SyncChildren(A.settings); end; if A.editBar and A.editBar:IsShown() then ASRStyle.SyncChildren(A.editBar); end; end end);
SLASH_ASRCOMBATTEXT1="/asrtext"; SlashCmdList.ASRCOMBATTEXT=function(msg) if not A.ready then return; end; if A.suiteAttached then if msg=="edit" then ASRSuite.SetEditing(not ASRSuite.editing); else ASRSuite.SelectSettingsPage("combat"); ASRSuite.settings:Show(); end; elseif msg=="edit" then A.SetEditing(not A.editing); else A.ToggleSettings(); end end;

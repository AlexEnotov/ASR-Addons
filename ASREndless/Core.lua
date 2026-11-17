ASREndless={VERSION="0.6.3",ready=false}; local A=ASREndless;
local keys={"endlessEnabled","endlessPosition","endlessState","endlessHud"};
local function Copy(v) if type(v)~="table" then return v; end; local t={}; for k,x in pairs(v) do t[k]=Copy(x); end; return t; end
function A.Init()
 if type(ASREndlessDB)~="table" then ASREndlessDB={}; end
 if ASREndlessDB.endlessEnabled==nil then ASREndlessDB.endlessEnabled=true; end
 if ASREndlessDB.locked==nil then ASREndlessDB.locked=true; end
 ASREndlessDB.language=ASRLocale.Normalize(ASREndlessDB.language); A.ready=true;
end
function A.MigrateSuite()
 local old=ASRSuiteDB; if type(old)~="table" then return; end
 -- An old Suite must not render a second tracker or compete for HUD ownership.
 if ASRSuite and ASRSuite.InitEndless and not A.legacySuite then
  if ASRSuite.endlessFrame then ASRSuite.endlessFrame:Hide(); end
  A.legacySuite=true; ASRSuite.InitEndless=function() end;
  ASRSuite.endlessFrame=A.endlessFrame;
  ASRSuite.UpdateEndless=function(dt,force)
   if force then
    ASREndlessDB.endlessEnabled=old.endlessEnabled; ASREndlessDB.endlessPosition=Copy(old.endlessPosition);
    A.endlessFrame.placed=nil; A.UpdateEndless(0,true);
   end
  end;
 end
 if not ASREndlessDB.migratedSuite then
  for _,key in ipairs(keys) do if old[key]~=nil then ASREndlessDB[key]=Copy(old[key]); old[key]=nil; end end
  if old.language then ASREndlessDB.language=ASRLocale.Normalize(old.language); end
  ASREndlessDB.migratedSuite=true;
 end
 if A.legacySuite then old.endlessEnabled=ASREndlessDB.endlessEnabled; old.endlessPosition=Copy(ASREndlessDB.endlessPosition); end
 if A.endlessFrame then A.endlessFrame.placed=nil; end
end
function A.SetEditMode(on)
 A.editing=on and true or false; local f=A.endlessFrame; if not f then return; end
 if f.editOverlay~=A.editing then
  f.editOverlay=A.editing;
  if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens("ASREndlessTracker",A.editing); end
 end
 f:SetFrameStrata(A.editing and "FULLSCREEN_DIALOG" or "MEDIUM"); f:SetFrameLevel(A.editing and 450 or 20);
 ASRStyle.SyncChildren(f);
end
function A.CanMovePanel()
 if ASRSuite and ASRSuite.ready then return ASRSuite.CanMovePanel("endless"); end
 return not ASREndlessDB.locked;
end
function A.StopDrag(frame)
 if frame and frame.moving then frame:StopMovingOrSizing(); frame.moving=false; if frame.saveDrag then frame.saveDrag(frame); end end
end
function A.SetEnabled(on) ASREndlessDB.endlessEnabled=on and true or false; if A.legacySuite then ASRSuiteDB.endlessEnabled=ASREndlessDB.endlessEnabled; end; A.UpdateEndless(0,true); end
function A.ResetPosition() ASREndlessDB.endlessPosition=nil; if A.legacySuite then ASRSuiteDB.endlessPosition=nil; end; if A.endlessFrame then A.endlessFrame.placed=nil; end; A.UpdateEndless(0,true); end
function A.BindSuite()
 local suite=ASRSuite; if not suite or not suite.ready then return; end
 if A.legacySuite and ASREndlessDB.language~=ASRSuiteDB.language then A.SetLanguage(ASRSuiteDB.language); end
 if A.boundSuite==suite then return; end
 A.MigrateSuite(); A.boundSuite=suite;
 if suite.RegisterPanel then suite.RegisterPanel("endless",{frame=A.endlessFrame,available=function() return A.endlessFrame:IsShown(); end,
  setEditing=A.SetEditMode,
  savePosition=function(r) ASREndlessDB.endlessPosition={"TOPLEFT","BOTTOMLEFT",r.left/r.ratio,r.top/r.ratio}; A.endlessFrame.placed=true; end}); end
 if suite.RegisterCompatibilityAddon then suite.RegisterCompatibilityAddon("endless","ASR Endless",function() return true; end,{{id="tracker",title="Показывать трекер Endless",get=function() return ASREndlessDB.endlessEnabled; end,set=A.SetEnabled}}); end
 A.SetLanguage(ASRSuiteDB.language); A.SetEditMode(suite.editing);
end
local runtime=CreateFrame("Frame","ASREndlessRuntime"); runtime:RegisterEvent("ADDON_LOADED");
runtime:SetScript("OnEvent",function(self,event,name)
 if name=="ASREndless" then A.Init(); A.InitEndless(); A.CreateSettings(); end
 if A.ready and name=="ASRSuite" then A.MigrateSuite(); A.BindSuite(); end
end);
runtime:SetScript("OnUpdate",function(self,dt) if A.ready then A.BindSuite(); A.UpdateEndless(dt); end end);
SLASH_ASRENDLESS1="/asrendless";
SlashCmdList.ASRENDLESS=function(msg)
 if not A.ready then return; end
 if msg=="on" or msg=="off" then A.SetEnabled(msg=="on");
 elseif msg=="reset" then A.ResetPosition();
 elseif msg=="unlock" or msg=="lock" then ASREndlessDB.locked=msg=="lock";
 elseif ASRLocale.IsLanguage(msg) then A.SetLanguage(msg);
 else if A.settings:IsShown() then A.settings:Hide(); else A.settings:Show(); end; A.DrawSettings(); end
end;

local A=ASAdvisor;
local clock=CreateFrame("Frame","ASAdvisorRuntime");
clock:RegisterEvent("ADDON_LOADED"); clock:RegisterEvent("PLAYER_ENTERING_WORLD");
local elapsed=0;
local function trace(prefix,msg)
  if A.ready and ASAdvisorDB.options.debug then
    local log=ASAdvisorDB.diagnostics; log[#log+1]=prefix.." "..string.sub(msg or "",1,3000);
    while #log>32 do table.remove(log,1); end
  end
end
local function register()
  for _,prefix in ipairs({"AZSCARDS","AZSCARDTIP","AZSSPELLS","AZSSPELLTIP","AZSGEAR","AZSSTATS","AZSRUN","AZSZONE","AZSEND"}) do
    local eventPrefix=prefix;
    AZS.On(eventPrefix,function(msg)
      trace(eventPrefix,msg);
      if not A.ready then return; end
      if eventPrefix=="AZSCARDS" then A.offer=true;
      elseif eventPrefix=="AZSEND" or eventPrefix=="AZSZONE" then A.offer=false;
      elseif eventPrefix=="AZSRUN" and AZS_RUN and AZS_RUN.ph~="choosing" then A.offer=false; end
      if eventPrefix=="AZSGEAR" then
        for _,g in ipairs(AZS_GEAR or {}) do local row=A.ResolveItem(g); if row and g.text and #g.text<4000 then ASAdvisorDB.observed[row.key]=g.text; end end
      end
      A.dirty=true;
    end);
  end
end
clock:SetScript("OnEvent",function(self,event,name)
  if event=="ADDON_LOADED" and name=="ASAdvisor" then
    A.Init(); register();
    if AZS_SetOnTopOfScreens then
      -- Register only the editor root. Child pages render in that hierarchy, never as separate top-level windows.
      AZS_SetOnTopOfScreens("ASAdvisorPlanner",true);
    end
    A.Print(A.VERSION.." · /asr");
  elseif event=="PLAYER_ENTERING_WORLD" and A.ready then
    A.offer=AZSCardsFrame and AZSCardsFrame:IsShown() or false; A.dirty=true;
  end
end);
clock:SetScript("OnUpdate",function(self,dt)
  if not A.ready then return; end
  if A.CheckPointerRelease then A.CheckPointerRelease(); end
  elapsed=elapsed+dt;
  if elapsed<0.2 then return; end; elapsed=0;
  -- Actual visibility guards against stale offers after a pick, skip, reroll or reload.
  A.offer=AZSCardsFrame and AZSCardsFrame:IsShown() or false;
  if A.dirty and A.Redraw then A.Redraw(); end
  A.RefreshUI(); A.dirty=false;
end);
SLASH_ASADVISOR1="/asa";
SLASH_ASADVISOR2="/asadvisor";
SLASH_ASADVISOR3="/asr";
SlashCmdList.ASADVISOR=function(msg)
  if not A.ready then return; end
  msg=A.Trim(msg);
  if msg=="debug" then
    ASAdvisorDB.options.debug=not ASAdvisorDB.options.debug;
    A.Print(A.T(ASAdvisorDB.options.debug and "Запись данных включена" or "Запись данных выключена"));
  elseif msg=="data" then A.ShowCode("debug");
  elseif msg=="tracker" then ASAdvisorDB.options.trackerHidden=not ASAdvisorDB.options.trackerHidden; A.RefreshUI();
  elseif msg=="reset" then
    A.ResetLayout();
  else A.ToggleUI(); end
end;

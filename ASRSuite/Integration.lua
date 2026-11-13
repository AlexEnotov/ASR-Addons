local A=ASRSuite;
A.displaySources={}; A.panelAdapters={};
A.compatibilityAddons={};
-- Each addon exposes only the interface elements it can actually manage.
-- Feature setters own their state and restoration, not the settings page.
function A.RegisterCompatibilityAddon(id,title,available,features)
 local spec={id=id,title=title,available=available,features=features};
 for i,entry in ipairs(A.compatibilityAddons) do if entry.id==id then A.compatibilityAddons[i]=spec; if A.RefreshCompatibility then A.RefreshCompatibility(); end; return; end end
 A.compatibilityAddons[#A.compatibilityAddons+1]=spec;
 if A.RefreshCompatibility then A.RefreshCompatibility(); end
end
function A.SetCompatibilitySource(component,source,on)
 if on then return A.SelectDisplaySource(component,source); end
 if ASRSuiteDB.sources[component]==source then return A.SelectDisplaySource(component,"previous"); end
 return true;
end
function A.InitIntegration()
 local d=ASRSuiteDB;
 if type(d.moduleEnabled)~="table" then d.moduleEnabled={}; end
 for _,id in ipairs({"stats","builder","combat"}) do if type(d.moduleEnabled[id])~="boolean" then d.moduleEnabled[id]=id~="combat" or A.CombatConfig().enabled; end end
 if type(d.lockPanels)~="boolean" then d.lockPanels=true; end
 if type(d.sources)~="table" then d.sources={}; end
 d.sources.combat=d.sources.combat or (A.HasCombat() and A.CombatConfig().enabled and "asr" or "previous"); if not A.HasCombat() or (d.sources.combat=="asr" and not A.CombatConfig().enabled) then d.sources.combat="previous"; d.moduleEnabled.combat=false; end
end
function A.IsModuleEnabled(id)
 if ASRSuiteDB and ASRSuiteDB.moduleEnabled and ASRSuiteDB.moduleEnabled[id]==false then return false; end
 if id=="combat" and (not A.HasCombat() or not A.CombatConfig().enabled) then return false; end
 if id=="builder" and ASAdvisorDB and ASAdvisorDB.options and ASAdvisorDB.options.enabled==false then return false; end
 if id=="stats" and ASRStatsDB and ASRStatsDB.enabled==false then return false; end
 return true;
end
function A.CanMovePanel(id) return A.editing or not ASRSuiteDB or not ASRSuiteDB.lockPanels; end
function A.SetModuleEnabled(id,on)
 ASRSuiteDB.moduleEnabled[id]=on and true or false;
 if id=="combat" then if on then A.SelectDisplaySource("combat","asr"); else A.Enabled(false); ASRSuiteDB.sources.combat="previous"; end;
 elseif id=="stats" and ASRStatsDB then ASRStatsDB.enabled=on;
 elseif id=="builder" and ASAdvisorDB and ASAdvisorDB.options then ASAdvisorDB.options.enabled=on;
 else local adapter=A.panelAdapters[id]; if adapter and adapter.setEnabled then adapter.setEnabled(on); end; if not on then A.ReleaseDisplaySource(id); end end
 A.RefreshModules();
end
function A.RegisterPanel(id,adapter) A.panelAdapters[id]=adapter; if A.RegisterDockPanel then local frame=adapter.frame or adapter.getFrame and adapter.getFrame(); if frame then A.RegisterDockPanel(id,frame,adapter.savePosition,adapter.available); end end end
function A.RegisterDisplaySource(component,id,title,available,apply,restore)
 A.displaySources[component]=A.displaySources[component] or {}; A.displaySources[component][id]={title=title,available=available,apply=apply,restore=restore};
end
function A.SelectDisplaySource(component,id)
 local spec=A.displaySources[component] and A.displaySources[component][id]; if not spec or spec.available and not spec.available() then return false; end
 A.activeSources=A.activeSources or {}; local previous=A.activeSources[component]; A.activeRestorers=A.activeRestorers or {}; if previous==spec and A.activeRestorers[component] then return true; end; if previous and previous~=spec and A.activeRestorers[component] then A.activeRestorers[component](); end
 ASRSuiteDB.sources[component]=id; local restore=spec.apply(); A.activeRestorers[component]=type(restore)=="function" and restore or spec.restore; A.activeSources[component]=spec; if A.DrawSettings then A.DrawSettings(); end; return true;
end
function A.ReleaseDisplaySource(component) local restore=A.activeRestorers and A.activeRestorers[component]; if restore then restore(); A.activeRestorers[component]=nil; end; if A.activeSources then A.activeSources[component]=nil; end end
function A.CreateSources()
 A.RegisterDisplaySource("combat","previous","Как было до ASR",nil,function() ASRSuiteDB.moduleEnabled.combat=false; A.Enabled(false); end);
 A.RegisterDisplaySource("combat","game","Стандартный текст игры",nil,function()
  ASRSuiteDB.moduleEnabled.combat=false; A.Enabled(false);
  local mode=SurvivorUI_DamageMode and SurvivorUI_DamageMode(); local cvar=GetCVar and GetCVar("CombatDamage");
  if SurvivorUI_SetDamageMode then SurvivorUI_SetDamageMode("game"); end; if SetCVar then SetCVar("CombatDamage","1"); end
  return function() if mode and SurvivorUI_SetDamageMode then SurvivorUI_SetDamageMode(mode); end; if cvar and SetCVar then SetCVar("CombatDamage",cvar); end end;
 end);
 A.RegisterDisplaySource("combat","asr","Текст ASR",A.HasCombat,function()
  ASRSuiteDB.moduleEnabled.combat=true; A.Enabled(true);
 end);
 A.RegisterDisplaySource("combat","survivor","Текст SurvivorUI",function() return SurvivorUI_SetDamageMode~=nil; end,function()
  ASRSuiteDB.moduleEnabled.combat=false; A.Enabled(false);
  local mode=SurvivorUI_DamageMode and SurvivorUI_DamageMode(); local cvar=GetCVar and GetCVar("CombatDamage"); SurvivorUI_SetDamageMode("survivor");
  return function() if mode and SurvivorUI_SetDamageMode then SurvivorUI_SetDamageMode(mode); end; if cvar and SetCVar then SetCVar("CombatDamage",cvar); end end;
 end);
 local function Source(source)
  return {{id="combat",title=source=="asr" and "Показывать числа ASR" or "Показывать числа SurvivorUI",description="Включение заменяет другие числа урона. Выключение возвращает прежний режим.",get=function() return ASRSuiteDB.sources.combat==source; end,set=function(on) A.SetCompatibilitySource("combat",source,on); end,
   fallback={title="Текст игры",get=function() return ASRSuiteDB.sources.combat=="game"; end,set=function(on) A.SetCompatibilitySource("combat","game",on); end}}};
 end
 A.RegisterCompatibilityAddon("combat","ASR Combat Text",A.HasCombat,Source("asr"));
 A.RegisterCompatibilityAddon("stats","ASR Stats",function() return ASRStats~=nil; end,{{id="panel",title="Показывать панель характеристик",description="Текущие характеристики персонажа отдельной панелью. Выключено — панель скрыта.",get=function() return A.IsModuleEnabled("stats"); end,set=function(on) A.SetModuleEnabled("stats",on); end}});
 A.RegisterCompatibilityAddon("builder","ASR Advisor",function() return ASAdvisor~=nil; end,{{id="module",title="Включить билдер и подсказки",description="Выключено — трекер и подсказки выбора не работают. Сохранённые билды остаются.",get=function() return A.IsModuleEnabled("builder"); end,set=function(on) A.SetModuleEnabled("builder",on); end}});
 A.RegisterCompatibilityAddon("survivor","SurvivorUI",function() return SurvivorUI_SetDamageMode~=nil; end,Source("survivor"));
end

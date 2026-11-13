local A=ASRSuite;
A.typeKeys={"normal","critical","heal","taken","periodic"};
A.styleFields={{"fontSize",10,36},{"scrollSpeed",0,300},{"lifetime",0.6,4},{"rise",20,200},{"merge",0,1},{"spacing",0,80},{"icons"},{"short"}};
function A.InitProfiles()
 local db=ASRSuiteDB;
 if type(db.moduleOverrides)~="table" then db.moduleOverrides={}; end
 for _,id in ipairs({"stats","builder","combat"}) do if type(db.moduleOverrides[id])~="table" then db.moduleOverrides[id]={}; end; if type(db.moduleOverrides[id].opacity)~="boolean" then db.moduleOverrides[id].opacity=false; end end
 db.trackerOpacity=math.max(0,math.min(1,A.Number(db.trackerOpacity) or db.opacity));
 db.textOpacity=math.max(0,math.min(1,A.Number(db.textOpacity) or 1));
 for _,module in pairs(db.moduleOverrides) do if type(module)=="table" and type(module.menuOpacity)~="boolean" then module.menuOpacity=false; end end
end
function A.EffectiveOptions(kind) if A.HasCombat() then return ASRCombatText.EffectiveOptions(kind); end; return A.CombatConfig(); end
function A.SetCustom(kind,on) if A.HasCombat() then ASRCombatText.SetCustom(kind,on); end end
function A.TypeShown(kind) return A.HasCombat() and ASRCombatText.TypeShown(kind); end
function A.SetTypeShown(kind,on) if A.HasCombat() then ASRCombatText.SetTypeShown(kind,on); end end
function A.GetPanelOpacity(module,localValue,category)
 if not ASRSuiteDB then return localValue; end
 local p=ASRSuiteDB.moduleOverrides and ASRSuiteDB.moduleOverrides[module];
 if category=="menu" then return p and p.menuOpacity and localValue or ASRSuiteDB.opacity; end
 if category=="text" then return p and p.opacity and localValue or ASRSuiteDB.textOpacity; end
 return p and p.opacity and localValue or ASRSuiteDB.trackerOpacity;
end
function A.RefreshModules()
 if ASRStats and ASRStats.Refresh then ASRStats.Refresh(); end
 if ASAdvisor then if ASAdvisor.ApplyLayout then ASAdvisor.ApplyLayout(); end; if ASAdvisor.RefreshUI then ASAdvisor.RefreshUI(); end end
 if A.DrawSettings then A.DrawSettings(); end
end

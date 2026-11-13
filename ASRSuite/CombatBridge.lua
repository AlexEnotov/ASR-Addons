local A=ASRSuite;
local textKeys={"enabled","mode","fontSize","lifetime","rise","merge","spacing","icons","periodic","heals","taken","short","scrollSpeed","positions","types","combatOpacity"};
function A.CombatConfig() return ASRCombatTextDB or A.fallbackConfig or ASRSuiteDB; end
function A.HasCombat() return ASRCombatText and ASRCombatText.ready==true; end
function A.AttachCombat()
 if A.HasCombat() then
  if not ASRSuiteDB.combatMigrated and A.hadLegacyCombat then
   for _,key in ipairs(textKeys) do if ASRSuiteDB[key]~=nil then ASRCombatTextDB[key]=ASRSuiteDB[key]; end end
   ASRSuiteDB.combatMigrated=true; ASRCombatText.RefreshConfig();
  end
  for _,key in ipairs(textKeys) do ASRSuiteDB[key]=nil; end
  ASRSuiteDB.combatMigrated=true; ASRCombatText.AttachSuite(true);
 else
  A.fallbackConfig={}; for _,key in ipairs(textKeys) do A.fallbackConfig[key]=ASRSuiteDB[key]; if not A.hadLegacyCombat then ASRSuiteDB[key]=nil; end end
 end
 for _,name in ipairs({"AddHit","ClearCombat","PollEvents","UpdateCombat","Example","RestoreNative","ApplyCombat"}) do local method=name;
  A[method]=function(...) if A.HasCombat() then local result=ASRCombatText[method](...); A.active=ASRCombatText.active; return result; end end
 end
 A.CreateCombat=function() end;
end

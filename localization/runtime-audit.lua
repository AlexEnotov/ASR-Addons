local modules={builder=true,stats=true,combat=true,suite=true,endless=true,loot=true,party=true,chat=true};
local original=ASRLocale.Text;
local calls=0;
ASRLocale.Text=function(module,code,source,english)
 local result=original(module,code,source,english);
 if modules[module] and code~="en" and code~="ru" and type(result)=="string" then
  calls=calls+1;
  assert(not result:find("[\208\209]"),"Untranslated runtime UI: "..module.." "..tostring(code).." "..tostring(source));
  assert(not result:find("undefined",1,true),"Invalid runtime UI text");
 end
 return result;
end;
local old={};
if ASRStatsDB and SlashCmdList and SlashCmdList.ASRSTATS then ASRStatsDB.enabled=true; SlashCmdList.ASRSTATS("config"); end
for _,entry in ipairs({{ASRStatsDB},{ASRCombatTextDB},{ASRSuiteDB},{ASREndlessDB},{ASRLootDB},{ASRPartyDB},{ASRChatDB}}) do if entry[1] then old[#old+1]={entry[1],entry[1].language}; end end
for _,code in ipairs({"deDE","frFR","esES","ptBR","itIT","plPL","trTR","jaJP","zhCN","koKR"}) do
 if ASRSuite and ASRSuite.ready then ASRSuite.SetLanguage(code); end
 if ASRStatsDB and ASRStats and ASRStats.Refresh then ASRStatsDB.language=code; ASRStats.Refresh(); end
 if ASRCombatTextDB and ASRCombatText and ASRCombatText.ToggleSettings then ASRCombatTextDB.language=code; ASRCombatText.ToggleSettings(); ASRCombatText.ToggleSettings(); end
 for _,module in ipairs({ASREndless or false,ASRLoot or false,ASRParty or false,ASRChat or false}) do if module and module.ready and module.SetLanguage then module.SetLanguage(code); end end
end
ASRLocale.Text=original;
for _,entry in ipairs(old) do entry[1].language=entry[2]; end
assert(calls>0,"runtime audit exercised visible UI text");
print("PASS: runtime UI translation audit across all ten added languages");

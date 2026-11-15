const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const parser=require('luaparse'); const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync(path.resolve(__dirname,'../../ASRAdvisor/tests/mock.lua'),'utf8'),'UI mock');
run(fs.readFileSync(path.resolve(__dirname,'../../ASRSuite/tests/environment.lua'),'utf8'),'suite mock');

for(const file of ['Language.lua','Style.lua','Core.lua','Locale.lua','WorldNames.lua','Tracker.lua','Settings.lua']){const code=fs.readFileSync(path.resolve(__dirname,'..',file),'utf8');parser.parse(code,{luaVersion:'5.1'});run(code,file);}
run('ASREndlessRuntime.scripts.OnEvent(ASREndlessRuntime,"ADDON_LOADED","ASREndless"); assert(not ASRSuite and ASREndless.ready and ASREndlessDB.language=="en");','standalone load');
run(fs.readFileSync(path.join(__dirname,'tracker.lua'),'utf8'),'endless tracker');
run(fs.readFileSync(path.join(__dirname,'standalone.lua'),'utf8'),'standalone controls');
for(const file of ['Language.lua','Style.lua','Core.lua','CombatBridge.lua','Profiles.lua','Integration.lua','Docking.lua','Locale.lua','Transfer.lua','Settings.lua','UI.lua'])run(fs.readFileSync(path.resolve(__dirname,'../../ASRSuite',file),'utf8'),'suite '+file);
run(fs.readFileSync(path.join(__dirname,'migration.lua'),'utf8'),'migration and integration');

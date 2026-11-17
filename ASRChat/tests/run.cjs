const fs=require('fs'),path=require('path');
require('./english-regression.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const parser=require('luaparse');const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['../../ASRAdvisor/tests/mock.lua','../../ASRSuite/tests/environment.lua','environment.lua'])run(fs.readFileSync(path.resolve(__dirname,file),'utf8'),file);
for(const file of ['Language.lua','Translations.lua','Style.lua','Core.lua','UI.lua','Chrome.lua','Settings.lua']){const code=fs.readFileSync(path.resolve(__dirname,'..',file),'utf8');parser.parse(code,{luaVersion:'5.1'});run(code,file);}
run(fs.readFileSync(path.join(__dirname,'standalone.lua'),'utf8'),'standalone Chat');
for(const file of ['Language.lua','Translations.lua','Style.lua','Core.lua','CombatBridge.lua','Profiles.lua','Integration.lua','Docking.lua','Locale.lua','Transfer.lua','Settings.lua','UI.lua'])run(fs.readFileSync(path.resolve(__dirname,'../../ASRSuite',file),'utf8'),'suite '+file);
run(fs.readFileSync(path.join(__dirname,'suite.lua'),'utf8'),'Chat Suite');
run(fs.readFileSync(path.resolve(__dirname,'../../localization/runtime-audit.lua'),'utf8'),'runtime localization audit');

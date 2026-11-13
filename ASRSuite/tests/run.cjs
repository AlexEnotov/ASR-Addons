const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const parser=require('luaparse'); const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync(path.resolve(__dirname,'../../ASAdvisor/tests/mock.lua'),'utf8'),'UI mock');
run(fs.readFileSync(path.join(__dirname,'environment.lua'),'utf8'),'suite mock');
for(const file of ['Language.lua','Style.lua','Core.lua','CombatText.lua','UI.lua'])run(fs.readFileSync(path.resolve(__dirname,'../../ASRCombatText',file),'utf8'),'combat '+file);
for(const file of ['Language.lua','Style.lua','Data.lua','Main.lua'])run(fs.readFileSync(path.resolve(__dirname,'../../ASRStats',file),'utf8'),'stats '+file);
for(const file of ['Language.lua','Style.lua','Core.lua','CombatBridge.lua','Profiles.lua','Integration.lua','Docking.lua','Locale.lua','Settings.lua','UI.lua']){const code=fs.readFileSync(path.resolve(__dirname,'..',file),'utf8');parser.parse(code,{luaVersion:'5.1'});run(code,file);}
run(fs.readFileSync(path.join(__dirname,'scenarios.lua'),'utf8'),'suite tests');

const disk=fs.readFileSync(path.resolve(__dirname,'../media/minimap.tga'));
if(disk[18+3]!==0 || disk[18+(32*64+32)*4+3]!==255)throw Error('Minimap art must have transparent corners and an opaque circular center');
run(fs.readFileSync(path.join(__dirname,'profiles.lua'),'utf8'),'profiles tests');
run(fs.readFileSync(path.join(__dirname,'modules.lua'),'utf8'),'module tests');
run(fs.readFileSync(path.join(__dirname,'docking.lua'),'utf8'),'docking tests');
run(fs.readFileSync(path.join(__dirname,'languages.lua'),'utf8'),'language tests');

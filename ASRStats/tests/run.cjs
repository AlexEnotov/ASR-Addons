const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const parser=require('luaparse');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync(path.resolve(__dirname,'../../ASRAdvisor/tests/mock.lua'),'utf8'),'UI mock');
run('local F=getmetatable(UIParent); function F:SetTextColor(...) self.textColor={...}; end;','text color capture');
for(const file of ['Language.lua','Translations.lua','Style.lua','Data.lua','Main.lua']){const code=fs.readFileSync(path.resolve(__dirname,'..',file),'utf8');parser.parse(code,{luaVersion:'5.1'});run(code,file);}
run(fs.readFileSync(path.join(__dirname,'stats.lua'),'utf8'),'stats tests');
run(fs.readFileSync(path.join(__dirname,'caps.lua'),'utf8'),'live stat cap colors');
run(fs.readFileSync(path.resolve(__dirname,'../../localization/runtime-audit.lua'),'utf8'),'runtime localization audit');

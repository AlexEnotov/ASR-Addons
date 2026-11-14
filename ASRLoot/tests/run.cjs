const fs=require('fs'),path=require('path');
function dep(name){try{return require(name);}catch(e){if(e.code!=='MODULE_NOT_FOUND')throw e;return require(path.resolve(__dirname,'../../.asadvisor-tools/node_modules',name));}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=dep('fengari'),parse=dep('luaparse');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync(path.resolve(__dirname,'../../ASAdvisor/tests/mock.lua'),'utf8'),'UI mock');
run(fs.readFileSync(path.resolve(__dirname,'../../ASRSuite/tests/environment.lua'),'utf8'),'environment');
run('function AZS_Fields(msg) local out={} for k,v in string.gmatch(msg,"(%w+)=([^;]*)") do out[k]=v end return out end','wire parser');
for(const file of ['Language.lua','Style.lua','Metadata.lua','Core.lua','UI.lua']){const code=fs.readFileSync(path.resolve(__dirname,'..',file),'utf8');parse.parse(code,{luaVersion:'5.1'});run(code,file);}
run(fs.readFileSync(path.join(__dirname,'loot.lua'),'utf8'),'loot tests');
for(const file of ['Language.lua','Style.lua','Core.lua','CombatBridge.lua','Profiles.lua','Integration.lua','Docking.lua','Locale.lua','WorldNames.lua','Endless.lua','Settings.lua','UI.lua'])run(fs.readFileSync(path.resolve(__dirname,'../../ASRSuite',file),'utf8'),'suite '+file);
run('ASRSuiteRuntime.scripts.OnEvent(ASRSuiteRuntime,"ADDON_LOADED","ASRSuite"); ASRLoot.BindSuite(); assert(ASRSuite.pages.loot and ASRSuite.navigation.loot,"loot adds a suite settings page"); ASRSuite.SetLanguage("ru"); ASRLoot.BindSuite(); assert(ASRLootDB.language=="ru","shared language propagates"); local p=ASRSuite.pages.loot; p.lootEnabled.scripts.OnClick(); assert(ASRLootDB.enabled,"suite switch enables loot"); p.lootMode.scripts.OnClick(); assert(ASRLootDB.mode=="new","suite mode switches independently of capture"); local scale=ASRLootDB.scale; p.lootScalePlus.scripts.OnClick(); assert(math.abs(ASRLootDB.scale-scale-0.01)<0.0001,"loot scale uses one percent steps"); assert(ASRSuite.panelAdapters.loot,"loot registers with the layout editor"); print("PASS: loot suite integration");','suite integration');

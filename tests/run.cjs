const fs=require('node:fs');
const path=require('node:path');
function dependency(name) {
 try { return require(name); }
 catch (error) { if(error.code!=='MODULE_NOT_FOUND') throw error; return require(path.join(__dirname,'../../.asadvisor-tools/node_modules',name)); }
}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=dependency('fengari');
const parse=dependency('luaparse');
const root=path.resolve(__dirname,'..');
const game=process.argv[2] || process.env.AZS_ADDON_PATH;
if(!game) throw Error('Pass the installed AzerothSurvivors addon directory: npm test -- "D:/path/to/Interface/AddOns/AzerothSurvivors"');
for(const file of fs.readdirSync(root).filter(n=>n.endsWith('.lua'))) parse.parse(fs.readFileSync(path.join(root,file),'utf8'),{luaVersion:'5.1'});
const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
const arrow=fs.readFileSync(path.join(root,'media/arrow-down.tga'));
if(arrow[2]!==2 || arrow.readUInt16LE(12)!==32 || arrow.readUInt16LE(14)!==32 || arrow[16]!==32 || arrow.length!==4114) throw Error('Invalid arrow texture');
for(let i=18;i<arrow.length;i+=4) if(arrow[i+3] && (arrow[i]!==arrow[i+1] || arrow[i+1]!==arrow[i+2])) throw Error('Recommendation arrow must use the neutral theme');
function run(code,name){
 if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK || lua.lua_pcall(L,0,0,0)!==lua.LUA_OK){throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
}
run(fs.readFileSync(path.join(__dirname,'mock.lua'),'utf8'),'mock');
run(fs.readFileSync(path.join(game,'Generated/Content.lua'),'utf8'),'game catalog');
run(fs.readFileSync(path.join(game,'Generated/Content_ruRU.lua'),'utf8'),'game Russian');
for(const file of ['Mechanics.lua','Names.lua','Core.lua','Locale.lua','Stats.lua','Advisor.lua','UI.lua','Runtime.lua']) run(fs.readFileSync(path.join(root,file),'utf8'),file);
run(fs.readFileSync(path.join(__dirname,'scenarios.lua'),'utf8'),'scenarios');
run(fs.readFileSync(path.join(__dirname,'extended.lua'),'utf8'),'extended');
run(fs.readFileSync(path.join(__dirname,'v040.lua'),'utf8'),'v040');
run(fs.readFileSync(path.join(__dirname,'v041.lua'),'utf8'),'v041');
run(fs.readFileSync(path.join(__dirname,'v050.lua'),'utf8'),'v050');
run(fs.readFileSync(path.join(__dirname,'v051.lua'),'utf8'),'v051');
run(fs.readFileSync(path.join(__dirname,'v052.lua'),'utf8'),'v052');
run(fs.readFileSync(path.join(__dirname,'item_priority.lua'),'utf8'),'item_priority');
run(fs.readFileSync(path.join(__dirname,'stat_caps.lua'),'utf8'),'stat_caps');
run(fs.readFileSync(path.join(__dirname,'v053.lua'),'utf8'),'v053');
run(fs.readFileSync(path.join(__dirname,'duration.lua'),'utf8'),'duration');
console.log('PASS: Lua 5.1 syntax, game catalog integration, recommendation scenarios, import validation and UI smoke.');


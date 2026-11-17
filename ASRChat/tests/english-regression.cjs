// Published v0.6.2 replaced, rather than merged, each registered dictionary.
// Chat must retain its entire English UI even with that legacy behavior.
const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
for(const name of ['../../ASRAdvisor/tests/mock.lua','../../ASRSuite/tests/environment.lua','environment.lua','../Language.lua'])run(fs.readFileSync(path.resolve(__dirname,name),'utf8'),name);
run('ASRLocale.RegisterTranslations=function(module,code,strings) ASRLocale.translations[module]=ASRLocale.translations[module] or {}; ASRLocale.translations[module][code]=strings; end;','legacy registry');
run(fs.readFileSync(path.resolve(__dirname,'../Core.lua'),'utf8'),'standalone Chat core');
run(`ASRChatDB={language='en'};
 local expected={['Модуль включён']='Module enabled',['Вид']='Appearance',['Поведение']='Behavior',['Ширина']='Width',['Пример сообщения группы']='Example party message',['Получена новая вещь']='New item received',['Настройки']='Settings',['Всегда показывать чат']='Always show chat',['Всегда показывать поле ввода']='Always show input field'};
 for source,value in pairs(expected) do assert(ASRChat.T(source)==value,'English dictionary overwritten: '..source); end
 ASRChatDB.language='ru'; assert(ASRChat.T('Вид')=='Вид','explicit Russian preference preserved');
 print('PASS: standalone Chat English settings survive legacy dictionary replacement');`, 'English UI regression');

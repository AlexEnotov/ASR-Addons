const fs=require('node:fs'),path=require('node:path');
const parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..');
const modules={ASRAdvisor:'builder',ASRStats:'stats',ASRCombatText:'combat',ASRSuite:'suite',ASREndless:'endless',ASRLoot:'loot',ASRParty:'party',ASRChat:'chat'};
function state(){const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);return L;}
function run(L,code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));}
function file(L,name){run(L,fs.readFileSync(path.join(root,name),'utf8'),name);}
const catalog=require('./catalog.json');
// Check direct localization calls too: a complete dictionary is insufficient
// if a newly added source string never made it into that dictionary.
for(const [folder,module]of Object.entries(modules)){
 const L=state();
 function literal(n){if(n?.type!=='StringLiteral')return null;run(L,'_SOURCE_LITERAL='+n.raw,'source literal');lua.lua_getglobal(L,to_luastring('_SOURCE_LITERAL'));const s=to_jsstring(lua.lua_tostring(L,-1));lua.lua_pop(L,1);return s;}
 function visit(n){if(!n||typeof n!=='object')return;
  if(n.type==='CallExpression'){
   const name=n.base.type==='Identifier'?n.base.name:n.base.type==='MemberExpression'?n.base.identifier.name:'';
   if(['L','T','say'].includes(name)){
    const source=literal(n.arguments[0]);
    if(source&&/[\u0400-\u04ff]/.test(source)&&!catalog[module][source])throw Error(folder+' missing source string: '+source);
   }
  }
  for(const value of Object.values(n))if(Array.isArray(value))value.forEach(visit);else if(value&&typeof value==='object')visit(value);
 }
 for(const name of fs.readdirSync(path.join(root,folder)).filter(n=>n.endsWith('.lua')&&!['Language.lua','Translations.lua'].includes(n)))visit(parser.parse(fs.readFileSync(path.join(root,folder,name),'utf8'),{luaVersion:'5.1'}));
}
for(const [folder,module]of Object.entries(modules)){
 const L=state();file(L,folder+'/Language.lua');file(L,folder+'/Translations.lua');
 run(L,`
 assert(#ASRLocale.order==12,'game language count');
 for _,code in ipairs(ASRLocale.order) do assert(ASRLocale.Normalize(code)==code); end
 assert(ASRLocale.Normalize('enUS')=='en'); assert(ASRLocale.Normalize('ruRU')=='ru');
 assert(ASRLocale.Normalize('unknown')=='en');
 assert(ASRLocale.Normalize('kokr')=='koKR' and ASRLocale.Normalize('DEDE')=='deDE');
 assert(ASRLocale.IsLanguage('koKR') and ASRLocale.IsLanguage('kokr') and not ASRLocale.IsLanguage('copy'));
 local module='${module}'; local en=ASRLocale.translations[module].en;
 for _,code in ipairs(ASRLocale.order) do
  if code~='ru' then for key,value in pairs(en) do
   local expected=(ASRLocale.translations[module][code] or {})[key] or value;
   assert((ASRLocale.translations[module][code] or {})[key],module..' untranslated '..code..': '..key);
   assert(ASRLocale.Text(module,code,key)==expected,'translation or English fallback');
   if value:find('%%s') or value:find('%%d') or value:find('%%%.%df') then
    assert(pcall(string.format,expected,17,23,31,41,53,61),module..' invalid format '..code..': '..key);
   end
  end end
 end
 ASRLocale.RegisterTranslations('test','en',{one='One'});
 ASRLocale.RegisterTranslations('test','en',{two='Two'});
 ASRLocale.RegisterTranslations('test','deDE',{one='Eins',two=''});
 assert(ASRLocale.Text('test','deDE','one')=='Eins');
 assert(ASRLocale.Text('test','deDE','two')=='Two','merged dictionary fallback');
 assert(ASRLocale.Text('test','jaJP','missing','Explicit English')=='Explicit English');
 assert(ASRLocale.Text('test','ru','Исходный')=='Исходный');
 assert(ASRLocale.Text('test','en',nil)==nil);
 for _,dict in pairs(ASRLocale.translations[module]) do for key,value in pairs(dict) do assert(not value:find('undefined',1,true),'invalid composed translation: '..key); end end
 if module=='stats' then assert(ASRLocale.Text(module,'koKR','ASR / СТАТЫ')=='ASR / 능력치'); end
 if module=='builder' then
  assert(ASRLocale.Text(module,'koKR','урона от светлой магии','holy damage')=='신성 피해','dynamic source uses translated English alias');
  assert(ASRLocale.Text(module,'deDE','unregistered source','fire damage')=='Feuerschaden');
 end
 local old=ASRLocale;`,folder+' standalone locales');
 // Loading another standalone registry must preserve all earlier dictionaries.
 file(L,'ASRSuite/Language.lua');
 run(L,`assert(ASRLocale.Text('test','deDE','two')=='Two');`,folder+' load order');
}
const L=state();file(L,'ASRAdvisor/tests/mock.lua');file(L,'ASRParty/Language.lua');file(L,'ASRParty/Translations.lua');
run(L,`
 local function font(path,size)
  return {path=path,size=size,GetFont=function(self) return self.path,self.size,'OUTLINE'; end,
   SetFont=function(self,p,s,f) self.path=p;self.size=s;self.flags=f; end};
 end
 local text=font('Fonts\\\\FRIZQT__.TTF',13);
 local root={GetRegions=function() return text; end};
 ASRLocale.ApplyFonts(root,'jaJP'); assert(text.path=='Fonts\\\\KOSUGI.TTF' and text.size==13);
 ASRLocale.ApplyFonts(root,'zhCN'); assert(text.path=='Fonts\\\\ZCOOLKUAILE.TTF');
 ASRLocale.ApplyFonts(root,'koKR'); assert(text.path=='Fonts\\\\NANUMGOTHIC.TTF');
 ASRLocale.ApplyFonts(root,'deDE'); assert(text.path=='Fonts\\\\FRIZQT__.TTF' and text.flags=='OUTLINE');
 assert(ASRLocale.Text('names','ru','Warrior','Warrior')=='Воин');
 assert(ASRLocale.Text('names','deDE','Mage','Mage')~='Mage');
`, 'fonts and native class names');
console.log('PASS: source string coverage, complete UI dictionaries in 12 languages, formatted descriptions, English fallback, standalone loading, CJK fonts and class names.');

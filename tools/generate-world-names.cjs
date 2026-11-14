const fs=require('node:fs'),path=require('node:path'),parse=require('luaparse');
const base=process.argv[2];
if(!base)throw Error('Pass the installed AzerothSurvivors/Generated directory');
function read(file){return parse.parse(fs.readFileSync(path.join(base,file),'latin1'),{luaVersion:'5.1',encodingMode:'pseudo-latin1'});}
function val(n){if(n.type==='StringLiteral')return Buffer.from(n.value,'latin1').toString('utf8');if(n.type==='NumericLiteral'||n.type==='BooleanLiteral')return n.value;if(n.type==='TableConstructorExpression'){let o={},i=1;for(const f of n.fields)o[f.type==='TableValue'?i++:f.type==='TableKeyString'?f.key.name:val(f.key)]=val(f.value);return o;}throw Error(n.type);}
const ast=read('Content.lua');const assignment=ast.body.find(n=>n.type==='AssignmentStatement'&&n.variables.some(v=>v.type==='MemberExpression'&&v.base.name==='AZS_GEN'&&v.identifier.name==='zones'));
const names=new Set();for(const zone of Object.values(val(assignment.init[0]))){names.add(zone.name);if(zone.boss)names.add(zone.boss);for(const b of Object.values(zone.bosses||{}))names.add(b.name);}
const ru=read('Content_ruRU.lua');const call=ru.body.find(n=>n.type==='CallStatement'&&n.expression.base.name==='AZS_LocaleStrings');const translations=val(call.expression.arguments[1]);
const rows=[...names].sort().filter(n=>translations[n]).map(n=>' ['+JSON.stringify(n)+']='+JSON.stringify(translations[n])+',');
fs.writeFileSync(path.join(__dirname,'../ASRSuite/WorldNames.lua'),'-- Display names only, from the installed game catalog; mechanics stay in AZS_GEN.\n-- Other languages can register translations in the shared "world" dictionary.\nASRLocale.RegisterTranslations("world","ru",{\n'+rows.join('\n')+'\n});\n');console.log('World display names:',rows.length);

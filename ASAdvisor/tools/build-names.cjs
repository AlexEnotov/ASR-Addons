const fs=require('node:fs');
const path=require('node:path');
const game=process.argv[2];
if(!game) throw Error('Usage: node build-names.cjs <AzerothSurvivors addon directory>');
const content=fs.readFileSync(path.join(game,'Generated/Content.lua'),'utf8');
const ru=fs.readFileSync(path.join(game,'Generated/Content_ruRU.lua'),'utf8');
const catalog=content.slice(0,content.indexOf('AZS_GEN.races'))+content.slice(content.indexOf('AZS_GEN.jewels'),content.indexOf('AZS_GEN.gearTiers'));
const names=new Set([...catalog.matchAll(/\bname\s*=\s*("(?:[^"\\]|\\.)*")/g)].map(x=>JSON.parse(x[1])));
const translations={};
for(const m of ru.matchAll(/\[("(?:[^"\\]|\\.)*")\]\s*=\s*("(?:[^"\\]|\\.)*")/g)) {
 const key=JSON.parse(m[1]); if(names.has(key)) translations[key]=JSON.parse(m[2]);
}
if(Object.keys(translations).length<150) throw Error('Incomplete game name translations');
const quote=s=>JSON.stringify(s);
const out=['-- Display-only Russian names from this installation; game mechanics stay in AZS_GEN.','ASAdvisorNamesRU = {'];
for(const [key,value] of Object.entries(translations)) out.push('  ['+quote(key)+'] = '+quote(value)+',');
out.push('}'); fs.writeFileSync(path.join(__dirname,'..','Names.lua'),out.join('\n')+'\n');
console.log('Russian display names:',Object.keys(translations).length);

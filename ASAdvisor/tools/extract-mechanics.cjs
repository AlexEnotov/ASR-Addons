// Read-only extraction of factual metadata from the installed Reborn executable.
// Names/catalogs are read from AZS_GEN at runtime; this supplements missing slot/behavior metadata.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const exe = process.argv[2];
if (!exe) throw Error('Usage: node extract-mechanics.cjs <AzerothSurvivorsGame.exe>');
const bytes = fs.readFileSync(exe);
if (bytes.toString('ascii', 0, 2) !== 'MZ') throw Error('Not a PE executable');
const source = bytes.toString('utf8');
const result = {};
// Match records even when an embedded resource has had its newlines stripped.
const starts = [...source.matchAll(/\[\[(jewel|amulet)\]\]\s*key\s*=\s*"([a-z0-9_]+)"/g)];
for (const match of starts) {
  const relativeEnd = source.slice(match.index + match[0].length, match.index + 12000).search(/\[\[[a-z_]+\]\]/);
  let end = relativeEnd < 0 ? match.index + 12000 : match.index + match[0].length + relativeEnd;
  const body = source.slice(match.index, end).split(/(?:base|tbc|wotlk|cata)\/[a-zA-Z0-9_./-]+\.toml/)[0];
  const field = key => body.match(new RegExp('\\b' + key + '\\s*=\\s*"([^"\\r\\n]+)"'))?.[1];
  const slot = match[1] === 'amulet' ? 'amulet' : field('slot');
  if (!['ring','trinket','amulet'].includes(slot)) continue;
  const aliases = [...body.matchAll(/\b(?:en|ru)\s*=\s*"([^"\r\n]+)"/g)].map(x => x[1]);
  const baseText=body.match(/\bbase\s*=\s*([-+\d.eE]+)/)?.[1];
  const base=baseText===undefined?undefined:Number(baseText);
  const effectsText=body.match(/\beffects\s*=\s*(\[\[.*?\]\])/s)?.[1];
  const effects=effectsText?JSON.parse(effectsText):[];
  const specialBody=body.match(/\bspecial\s*=\s*\{([^}]+)\}/)?.[1];
  const specials=specialBody?[...specialBody.matchAll(/([a-z_]+)\s*=\s*([-+\d.eE]+)/g)].map(x=>[x[1],Number(x[2])]):[];
  const specialName=field('special');
  const classes=JSON.parse(body.match(/\bclasses\s*=\s*(\[[^\]]*\])/)?.[1] || '[]');
  result[match[2]] = { slot, behavior: field('behavior') || '', aliases: [...new Set(aliases)],base,effects,specials,specialName,classes };
}
if (Object.keys(result).length < 30 || result.accuria?.slot !== 'ring' || !result.ashen_band) {
  throw Error('Incomplete extraction: executable layout/content changed. Output was not written.');
}
const quote = s => '"' + s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\r/g, '\\r').replace(/\n/g, '\\n') + '"';
const lua=value=>typeof value==='number'?String(value):typeof value==='boolean'?(value?'true':'false'):typeof value==='string'?quote(value):Array.isArray(value)?'{ '+value.map(lua).join(', ')+' }':'{ '+Object.entries(value).map(([key,v])=>key+' = '+lua(v)).join(', ')+' }';
const inline=raw=>JSON.parse(raw.replace(/\b([a-z_]+)\s*=/g,'"$1":'));
const lines = ['-- Generated factual metadata; refresh with tools/extract-mechanics.cjs.',
  '-- Runtime names, icons and class spell pools come from the game AZS_GEN.',
  'ASAdvisorMechanics = {', '  source = ' + quote(crypto.createHash('sha256').update(bytes).digest('hex')) + ',', '  items = {'];
for (const key of Object.keys(result).sort()) {
  const r = result[key];
  const pairs=list=>'{ '+list.map(([key,value])=>'{ '+quote(key)+', '+value+' }').join(', ')+' }';
  const base=Number.isFinite(r.base)?', base = '+r.base:'';
  lines.push('    [' + quote(key) + '] = { slot = ' + quote(r.slot) + ', behavior = ' + quote(r.behavior) + ', aliases = { ' + r.aliases.map(quote).join(', ') + ' }'+base+', effects = '+pairs(r.effects)+', specials = '+pairs(r.specials)+', classes = { '+r.classes.map(x=>quote(x.toUpperCase())).join(', ')+' }'+(r.specialName?', specialName = '+quote(r.specialName):'')+' },');
}
lines.push('  },', '  spells = {');
for(const match of source.matchAll(/\[\[spell\]\]\s*key\s*=\s*"([a-z0-9_]+)"/g)) {
 const tail=source.slice(match.index+match[0].length,match.index+16000);
 const body=tail.split(/\[\[[a-z_]+\]\]|(?:base|tbc|wotlk|cata)\/[a-zA-Z0-9_./-]+\.toml/)[0];
 const shape=body.match(/^shape\s*=\s*(.*)$/m)?.[1]||'';
 const data={shape:shape.match(/\{\s*([a-z_]+)\s*=/)?.[1]||''};
 if(shape) data.shapeData=inline(shape);
 const rider=body.match(/^rider\s*=\s*(.*)$/m)?.[1]; if(rider)data.rider=inline(rider);
 for(const key of ['radius','targets']) {const value=shape.match(new RegExp('\\b'+key+'\\s*=\\s*([\\d.]+)'))?.[1];if(value)data[key]=Number(value);}
 for(const key of ['hit','cooldown','range']){const value=body.match(new RegExp('^'+key+'\\s*=\\s*([\\d.]+)','m'))?.[1];if(value)data[key]=Number(value);}
 const fields=Object.entries(data).map(([key,value])=>key+' = '+lua(value));
 lines.push('    ['+quote(match[1])+'] = { '+fields.join(', ')+' },');
}
lines.push('  },', '  legends = {');
for(const match of source.matchAll(/\[\[legend\]\]\s*key\s*=\s*"([a-z0-9_]+)"/g)) {
 const body=source.slice(match.index+match[0].length,match.index+12000).split(/\[\[[a-z_]+\]\]|(?:base|tbc|wotlk|cata)\/[a-zA-Z0-9_./-]+\.toml/)[0];
 const field=key=>body.match(new RegExp('^'+key+'\\s*=\\s*"([^"\\r\\n]+)"','m'))?.[1];
 const names=body.match(/^name\s*=\s*\{([^\r\n]*)\}/m)?.[1]||'';
 const en=names.match(/\ben\s*=\s*"([^"]+)"/)?.[1]; const ru=names.match(/\bru\s*=\s*"([^"]+)"/)?.[1];
 if(!en||!ru||!field('spell')) continue;
 const raw=body.match(/^effects\s*=\s*(\[[^\r\n]*\])/m)?.[1]||'[]';
 const effects=JSON.parse(raw.replace(/\b([a-z_]+)\s*=/g,'"$1":'));
 const lua=value=>typeof value==='number'?String(value):typeof value==='string'?quote(value):Array.isArray(value)?'{ '+value.map(lua).join(', ')+' }':'{ '+Object.entries(value).map(([key,v])=>key+' = '+lua(v)).join(', ')+' }';
 lines.push('    { key = '+quote('legend_'+match[1])+', spell = '+quote(field('spell'))+', name = '+quote(en)+', ru = '+quote(ru)+', icon = '+quote(field('icon')||'INV_Misc_QuestionMark')+', effects = '+lua(effects)+' },');
}
lines.push('  }', '}');
const out = path.resolve(__dirname, '..', 'Mechanics.lua');
fs.writeFileSync(out, lines.join('\n') + '\n', 'utf8');
console.log('Extracted', Object.keys(result).length, 'items into', out);

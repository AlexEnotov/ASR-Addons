const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const parser = require('luaparse');
const root = path.resolve(__dirname, '..');
const modules = ['ASAdvisor', 'ASRStats', 'ASRCombatText', 'ASRSuite'];
for (const folder of modules) {
  const dir = path.join(root, folder);
  const toc = fs.readFileSync(path.join(dir, folder + '.toc'), 'utf8');
  for (const name of fs.readdirSync(dir).filter(n => n.endsWith('.lua'))) {
    parser.parse(fs.readFileSync(path.join(dir, name), 'utf8'), {luaVersion:'5.1'});
  }
  for (const line of toc.split(/\r?\n/).map(s => s.trim()).filter(s => s && !s.startsWith('#'))) {
    if (!fs.existsSync(path.join(dir, line.replaceAll('\\', '/')))) throw Error('Missing TOC file: ' + folder + '/' + line);
  }
}
for (const folder of ['ASRStats', 'ASRCombatText', 'ASRSuite']) {
  execFileSync(process.execPath, [path.join(root, folder, 'tests/run.cjs')], {stdio:'inherit', cwd:root});
}
console.log('PASS: all module Lua syntax, TOC files, stats/combat/suite scenarios.');
console.log('Builder catalog scenarios require a local game: npm run test:game -- <AzerothSurvivors directory>');

local A=ASAdvisor;
local text=ASRLocale.Text;
local calls=0;
ASRLocale.Text=function(module,code,source,english)
 local result=text(module,code,source,english);
 if module=="builder" and code~="en" and code~="ru" and type(source)=="string" then
  calls=calls+1;
  -- Cyrillic in source keys is UTF-8 D0/D1; generated translations must not
  -- fall back to these keys in other languages, including dynamic keys.
  assert(not result:find("[\208\209]"),"Untranslated builder text: "..code.." "..source);
  assert(not result:find("undefined",1,true),"Invalid composed text");
 end
 return result;
end;
for _,code in ipairs(ASRLocale.order) do if code~="ru" and code~="en" then
 A.SetLanguage(code); A.RefreshUI();
 for _,m in pairs(ASAdvisorMechanics.spells) do A.BaseSpellProse(m); A.SpellAction(m); end
 for _,school in ipairs({"holy","fire","frost","nature","shadow","arcane","physical"}) do
  local description=A.BaseSpellProse({shape="strike",school=school,hit=84});
  assert(not description:find(school.." damage",1,true),"Untranslated damage school: "..code.." "..school);
 end
 for _,row in ipairs(A.catalog) do if row.group~="spell" then A.BaseItemText(row); end end
end end
ASRLocale.Text=text; A.SetLanguage("en");
assert(calls>1000,"description audit exercised dynamic strings");
print("PASS: dynamic descriptions, damage schools, item effects and builder screens in all added languages");

local A=ASRSuite;
local LIMIT=2000000;
local specs={suite="ASRSuiteDB",stats="ASRStatsDB",combat="ASRCombatTextDB",loot="ASRLootDB",endless="ASREndlessDB"};
local excluded={suite={endlessState=true,endlessHud=true},combat={nativeDamage=true,previousSurvivorMode=true},loot={run=true,items=true,nativeLoot=true},stats={},endless={endlessState=true,endlessHud=true,migratedSuite=true}};
local function Copy(value,omit)
 if type(value)~="table" then return value; end
 local out={}; for k,v in pairs(value) do if not (omit and omit[k]) then out[k]=Copy(v); end end; return out;
end
local function Checksum(s)
 local x,y=1,0; for i=1,#s do x=(x+string.byte(s,i))%65521; y=(y+x)%65521; end
 return string.format("%04x%04x",y,x);
end
-- A bounded, typed data codec. Imported text is never evaluated as Lua.
local function Encode(value,depth)
 depth=(depth or 0)+1; assert(depth<=20,"depth");
 local kind=type(value);
 if kind=="boolean" then return value and "b1" or "b0"; end
 if kind=="string" then return "s"..#value..":"..value; end
 if kind=="number" then assert(value==value and math.abs(value)<1e12,"number"); local s=string.format("%.17g",value); return "n"..#s..":"..s; end
 assert(kind=="table","type"); local keys={};
 for k in pairs(value) do assert(type(k)=="string" or type(k)=="number","key"); keys[#keys+1]=k; end
 table.sort(keys,function(x,y) if type(x)~=type(y) then return type(x)<type(y); end; return x<y; end);
 local out={"t"..#keys..":"}; for _,k in ipairs(keys) do out[#out+1]=Encode(k,depth); out[#out+1]=Encode(value[k],depth); end; return table.concat(out);
end
local function Parse(s)
 local pos,nodes=1,0;
 local function Read(depth)
  nodes=nodes+1; assert(depth<=20 and nodes<=100000,"limits");
  local tag=string.sub(s,pos,pos); pos=pos+1;
  if tag=="b" then local v=string.sub(s,pos,pos); pos=pos+1; assert(v=="0" or v=="1","boolean"); return v=="1"; end
  local first,last,length=string.find(s,"^(%d+):",pos); assert(first,"length"); length=tonumber(length); assert(length and length<=LIMIT,"length"); pos=last+1;
  if tag=="t" then
   assert(length<=20000,"table"); local out={}; for i=1,length do local k=Read(depth+1); assert(type(k)=="string" or type(k)=="number","key"); assert(out[k]==nil,"duplicate"); out[k]=Read(depth+1); end; return out;
  end
  assert(tag=="s" or tag=="n","tag"); assert(pos+length-1<=#s,"truncated"); local v=string.sub(s,pos,pos+length-1); pos=pos+length;
  if tag=="s" then return v; end
  v=tonumber(v); assert(v and v==v and math.abs(v)<1e12,"number"); return v;
 end
 local result=Read(1); assert(pos==#s+1,"trailing"); return result;
end
function A.CaptureSettings()
 local out={}; for key,global in pairs(specs) do if type(_G[global])=="table" then out[key]=Copy(_G[global],excluded[key]); end end
 if ASAdvisorDB and ASAdvisor then
  out.builder={options=Copy(ASAdvisorDB.options or {}),active=Copy(ASAdvisorDB.active or {})};
  if ASAdvisor.Export then out.builder.builds={}; for _,b in ipairs(ASAdvisorDB.builds or {}) do out.builder.builds[#out.builder.builds+1]={id=b.id,code=ASAdvisor.Export(b)}; end end
 end
 return out;
end
function A.ExportSettings()
 local ok,raw=pcall(function() return Encode(A.CaptureSettings()); end);
 if not ok or #raw*2+32>LIMIT then return nil,"Не удалось экспортировать настройки."; end
 return "ASRSET1:"..Checksum(raw)..":"..string.gsub(raw,".",function(c) return string.format("%02x",string.byte(c)); end);
end
local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true};
local function Num(v) return type(v)=="number" and v==v and math.abs(v)<1e12; end
local function BoolMap(t) assert(type(t)=="table","map"); for k,v in pairs(t) do assert(type(k)=="string" and type(v)=="boolean","map"); end end
local function Position(t)
 assert(type(t)=="table","position");
 if t.point or t.relative or t.rel then assert(anchors[t.point] and anchors[t.relative or t.rel] and Num(t.x) and Num(t.y),"anchor");
 elseif t[1] then assert(anchors[t[1]] and anchors[t[2]] and Num(t[3]) and Num(t[4]),"anchor");
 else assert(Num(t.x) and Num(t.y),"position"); end
end
local function Validate(t,reference,depth)
 assert(type(t)=="table" and depth<20,"table");
 for k,v in pairs(t) do
  local expected=reference and reference[k];
  if expected~=nil then assert(type(v)==type(expected),"type"); end
  if k=="hiddenStats" or k=="moduleEnabled" then BoolMap(v);
  elseif k=="moduleOverrides" then assert(type(v)=="table"); for _,entry in pairs(v) do BoolMap(entry); end
  elseif k=="sources" then assert(type(v)=="table"); for _,entry in pairs(v) do assert(type(entry)=="string"); end
  elseif k=="statCaps" then assert(type(v)=="table"); for _,entry in pairs(v) do assert(Num(entry) and entry>=0); end
  elseif k=="settingsPosition" or k=="position" or k=="trackerPos" or k=="plannerPos" or k=="previewPos" or k=="endlessPosition" then Position(v);
  elseif k=="trackerAnchor" then assert(type(v)=="table" and Num(v.left) and Num(v.top));
  elseif k=="positions" then assert(type(v)=="table"); for _,entry in pairs(v) do Position(entry); end
  elseif k=="docking" then
   assert(type(v)=="table"); for id,link in pairs(v) do assert(type(id)=="string" and type(link)=="table" and type(link.parent)=="string" and ({top=true,bottom=true,left=true,right=true})[link.side] and (link.offset==nil or Num(link.offset)) and (link.align==nil or ({start=true,ending=true,["end"]=true,offset=true})[link.align])); end
  elseif type(v)=="table" then Validate(v,type(expected)=="table" and expected or nil,depth+1);
  else assert(type(v)=="string" or type(v)=="boolean" or Num(v),"value"); end
 end
end
function A.DecodeSettings(text)
 if type(text)~="string" or #text>LIMIT then return nil,"Некорректный код настроек."; end
 local prefix,checksum,hex=string.match(string.gsub(text,"%s",""),"^(ASRSET%d+):(%x+):(%x+)$");
 if prefix~="ASRSET1" or not hex or #hex%2~=0 or #checksum~=8 then return nil,"Некорректный код настроек."; end
 local raw=string.gsub(hex,"%x%x",function(pair) return string.char(tonumber(pair,16)); end);
 if Checksum(raw)~=string.lower(checksum) then return nil,"Код настроек повреждён или скопирован не полностью."; end
 local ok,data=pcall(function()
  local out=Parse(raw); assert(type(out)=="table" and type(out.suite)=="table","suite"); local reference=A.CaptureSettings();
  for key,value in pairs(out) do
   assert(specs[key] or key=="builder","module");
   if key~="builder" then Validate(value,reference[key],1); for k in pairs(excluded[key]) do value[k]=nil; end
   else
    assert(type(value)=="table" and type(value.options)=="table" and type(value.active)=="table","builder"); Validate(value.options,reference.builder and reference.builder.options,1);
    for token,id in pairs(value.active) do assert(type(token)=="string" and Num(id) and id>0 and id%1==0); end
    if value.builds then
     assert(type(value.builds)=="table" and ASAdvisor and ASAdvisor.Decode,"builder required"); local ids={}; local count=0;
     for i,entry in pairs(value.builds) do
      count=count+1;
      assert(Num(i) and i>0 and i%1==0 and type(entry)=="table" and Num(entry.id) and entry.id>0 and entry.id%1==0 and not ids[entry.id] and type(entry.code)=="string"); ids[entry.id]=true;
      assert(ASAdvisor.Decode(entry.code),"build");
     end
     assert(count==#value.builds,"sparse builds");
    end
   end
  end
  return out;
 end);
 if not ok then return nil,"Некорректные настройки или несовместимая версия аддонов."; end
 for key in pairs(data) do if key=="builder" then if type(ASAdvisorDB)~="table" then return nil,"Сначала установи все аддоны, указанные в коде."; end
 elseif type(_G[specs[key]])~="table" then return nil,"Сначала установи все аддоны, указанные в коде."; end end
 return data;
end
function A.ImportSettings(text)
 local data,err=A.DecodeSettings(text); if not data then return false,err; end
 local replacements={};
 for key,value in pairs(data) do
  if key=="builder" then
   local target=Copy(ASAdvisorDB); target.options=Copy(value.options); target.active=Copy(value.active);
   if value.builds then
    target.builds={}; target.nextId=1;
    for _,entry in ipairs(value.builds) do local b=ASAdvisor.Decode(entry.code); b.id=entry.id; target.builds[#target.builds+1]=b; target.nextId=math.max(target.nextId,entry.id+1); end
   end
   replacements.ASAdvisorDB=target;
  else
   local target=Copy(value); for keep in pairs(excluded[key]) do target[keep]=_G[specs[key]][keep]; end; replacements[specs[key]]=target;
  end
 end
 for global,value in pairs(replacements) do _G[global]=value; end
 if not data.endless and data.suite and data.suite.endlessEnabled~=nil and ASREndlessDB then for _,key in ipairs({"endlessEnabled","endlessPosition"}) do ASREndlessDB[key]=Copy(data.suite[key]); end end
 return true;
end
function A.CreateSettingsTransfer(parent,close)
 local S=ASRStyle; local f=CreateFrame("Frame",nil,parent); f:SetSize(500,465); f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0); f:Hide();
 f.title=S.Label(f,"",16,8,0,360); f.note=S.Label(f,"",10,8,34,468,S.muted); f.note:SetHeight(44);
 local scroll=CreateFrame("ScrollFrame",nil,f); scroll:SetSize(448,300); scroll:SetPoint("TOPLEFT",f,"TOPLEFT",8,-88);
 scroll:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10}); scroll:SetBackdropColor(0.03,0.03,0.035,0.95);
 local body=CreateFrame("Frame",nil,scroll); body:SetSize(448,300); scroll:SetScrollChild(body);
 local edit=CreateFrame("EditBox",nil,body); edit:SetPoint("TOPLEFT",body,"TOPLEFT",5,-5); edit:SetWidth(438); edit:SetHeight(290); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFont(S.font,9,""); edit:SetMaxLetters(LIMIT); f.edit=edit;
 local slider=CreateFrame("Slider",nil,f); slider:SetSize(14,300); slider:SetPoint("TOPLEFT",f,"TOPLEFT",478,-88); slider:SetOrientation("VERTICAL"); slider:SetValueStep(1); slider:SetMinMaxValues(0,0); slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob"); slider:GetThumbTexture():SetSize(14,28);
 slider:SetScript("OnValueChanged",function(self,value) scroll:SetVerticalScroll(value or 0); end);
 local maximum=0;
 edit:SetScript("OnTextChanged",function(self)
  local lines=0; for line in string.gmatch((self:GetText() or "").."\n","(.-)\n") do lines=lines+math.max(1,math.ceil(#line/80)); end
  local height=math.max(290,lines*13+10); self:SetHeight(height); body:SetHeight(height+10); maximum=math.max(0,height+10-300); slider:SetMinMaxValues(0,maximum); slider:SetValue(math.min(scroll:GetVerticalScroll(),maximum));
 end);
 edit:SetScript("OnEscapePressed",function(self) self:ClearFocus(); end);
 for _,region in ipairs({scroll,body,edit,slider}) do region:EnableMouseWheel(true); region:SetScript("OnMouseWheel",function(self,delta) slider:SetValue(math.max(0,math.min(maximum,scroll:GetVerticalScroll()-delta*52))); end); end
 f.back=S.Button(f,"",92,25,384,0,function() edit:ClearFocus(); f:Hide(); close(); end);
 f.select=S.Button(f,"",226,27,8,402,function() edit:SetFocus(); edit:HighlightText(); end);
 f.apply=S.Button(f,"",226,27,250,402,function()
  local ok,err=A.ImportSettings(edit:GetText()); f.status:SetText(A.T(err or "Настройки импортированы. Перезагрузка интерфейса…"));
  if ok and ReloadUI then edit:ClearFocus(); ReloadUI(); end
 end);
 f.status=S.Label(f,"",10,8,439,468,S.muted); f.status:SetHeight(24);
 function f:Draw()
  self.title:SetText(A.T(self.mode=="export" and "Экспорт настроек" or "Импорт настроек"));
  self.note:SetText(A.T(self.mode=="export" and "Все настройки ASR, расположение панелей и сохранённые билды. Выдели код и скопируй Ctrl+C." or "Вставь код через Ctrl+V. Импорт заменит настройки и билды из кода и перезагрузит интерфейс."));
  self.back.text:SetText(A.T("Назад")); self.select.text:SetText(A.T("Выделить всё")); self.apply.text:SetText(A.T("Импортировать и перезагрузить"));
  if self.mode=="export" then self.apply:Hide(); else self.apply:Show(); end
 end
 function f:Open(mode)
  self.mode=mode; self:Draw(); self.status:SetText(""); local code,err;
  if mode=="export" then code,err=A.ExportSettings(); end
  edit:SetText(code or ""); slider:SetValue(0); self:Show(); edit:SetFocus(); if code then edit:HighlightText(); end; if err then self.status:SetText(A.T(err)); end
 end
 f:Draw(); return f;
end

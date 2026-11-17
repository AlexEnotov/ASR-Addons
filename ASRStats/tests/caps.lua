local A=ASRStats; local count=0;
local function check(ok,label) assert(ok,label); count=count+1; end
local function gold(row) local c=row.value.textColor; return c and c[1]==1 and c[2]==0.82 and c[3]==0; end
local function normal(row) local c=row.value.textColor; return c and c[1]==0.96 and c[2]==0.96 and c[3]==0.97; end
local rows={}; for _,row in ipairs(ASRStatsPanel.rows) do rows[row.definition[3]]=row; end
AZS_RUN={ph="playing"}; ASRStatsDB.hidden=false; ASRStatsDB.hideZeros=false;
AZS_RUNSTATS={crit=100,cdr=79.9,red=75,echo=60,dmg=250,dot=50};
AZS_CAPS=nil; AZS_GetStatCaps=nil; A.Refresh();
check(normal(rows.crit) and normal(rows.arm),"missing caps API leaves numbers in their normal color");
AZS_CAPS={}; AZS_GetStatCaps=function() return AZS_CAPS; end; A.Refresh();
check(normal(rows.crit) and normal(rows.arm),"empty initial caps never imply zero or hardcoded caps");
local original={crit=100,cdr=80,red=75,echo=60,haste=50}; AZS_CAPS=original; Emit("AZSCAPS","");
check(gold(rows.crit) and gold(rows.arm) and gold(rows.echo),"live cap event colors numeric values exactly at their caps");
check(normal(rows.cd),"value below its actual cap stays normal");
check(normal(rows.dmg) and normal(rows.doth),"uncapped damage and DoT frequency do not borrow a different stat's cap");
check(rows.crit.value:GetText()=="100%" and rows.cd.value:GetText()=="+79.9%","highlight does not change numeric formatting");
local label=rows.crit.name.textColor; check(label[1]==0.96 and label[2]==0.96 and label[3]==0.97,"stat names retain their usual color");
AZS_RUNSTATS.cdr=80; Emit("AZSSTATS",""); check(gold(rows.cd),"current-value update highlights newly reached cap");
AZS_CAPS={crit=100,cdr=80,red=90,echo=60}; Emit("AZSCAPS","");
check(normal(rows.arm) and original.red==75,"a raised character cap removes the old highlight without mutating prior API data");
AZS_RUNSTATS.red=90; A.Refresh(); check(gold(rows.arm),"changed character cap is used on subsequent refreshes");
AZS_RUNSTATS.crit=99.96; A.Refresh(); check(normal(rows.crit),"rounding the displayed percentage cannot falsely mark a cap reached");
AZS_RUNSTATS.cdr=81; A.Refresh(); check(gold(rows.cd),"over-cap reported values are also highlighted");
AZS_CAPS={}; Emit("AZSCAPS",""); check(normal(rows.cd) and normal(rows.arm),"unknown caps remove prior highlights");
AZS_CAPS={red=90}; AZS_GetStatCaps=function() error("unavailable optional API"); end; A.Refresh();
check(gold(rows.arm) and normal(rows.cd),"API failure safely falls back to the current global caps table");
AZS_CAPS={red=-1,crit="unknown",echo=math.huge}; A.Refresh();
check(normal(rows.arm) and normal(rows.crit) and normal(rows.echo),"invalid cap values never color stats as capped");
check(A.IsCapped(rows.echo.definition,0,{echo=0}),"an explicit numeric zero cap remains distinct from an unknown cap");
check(not A.IsCapped(rows.echo.definition,nil,{echo=60}),"an unknown current value cannot reach a cap");
AZS_GetStatCaps=nil; AZS_CAPS=nil;
print("Passed "..count.." live stat-cap color checks");

local A=ASRSuite; local checks=0; local function check(ok,name) assert(ok,name); checks=checks+1; end
local db=ASAdvisorDB; local b=ASAdvisor.NewBuild("HUNTER"); b.name="Полный перенос билда"; b.spells={{key="aimed_shot",rank=0,cd=1,radius=0,banish=true}}; b.items={"accuria"}; b.itemRules={accuria={group="ring",value=80}};
ASAdvisorDB.builds={b}; ASAdvisorDB.active={HUNTER=b.id}; ASAdvisorDB.options.trackerPos={point="TOPLEFT",rel="BOTTOMLEFT",x=99,y=520};
ASAdvisorDB.runBans={id="live-run",spells={auto_shot=true}}; ASAdvisorDB.observed={accuria="Do not export observation"}; ASAdvisorDB.diagnostics={"Do not export diagnostic log"};
local code=assert(A.ExportSettings()); local payload=assert(A.DecodeSettings(code));
check(#payload.builder.builds==1 and not payload.builder.observed and not payload.builder.runBans,"builder profile includes library without run bans or observed item cache");
ASAdvisorDB.builds={}; ASAdvisorDB.active={}; ASAdvisorDB.options.trackerPos=nil;
check(A.ImportSettings(code),"full profile accepts validated builder codes");
local restored=ASAdvisorDB.builds[1]; check(restored.name==b.name and restored.spells[1].banish and restored.itemRules.accuria.value==80,"build descriptions, spell rules and jewelry thresholds survive transfer");
check(ASAdvisorDB.active.HUNTER==restored.id and ASAdvisorDB.nextId>restored.id,"active build identities and future IDs remain consistent");
check(ASAdvisorDB.options.trackerPos.x==99 and ASAdvisorDB.runBans.spells.auto_shot and ASAdvisorDB.observed.accuria,"import restores layout without replacing live bans or caches");
print("Passed "..checks.." complete builder profile checks");

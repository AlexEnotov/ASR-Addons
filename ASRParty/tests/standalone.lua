local A=ASRParty; local n=0; local function check(v,label) assert(v,label); n=n+1; end
ASRPartyRuntime.scripts.OnEvent(ASRPartyRuntime,"ADDON_LOADED","ASRParty");
check(A.ready and not ASRSuite and ASRPartyDB.language=="en","standalone initializes in English");
check(A.frame:IsShown() and A.frame.header:IsShown() and not A.active and AzerothSurvivorsPartyUnitButton1:GetAlpha()==0.7,"solo load does not touch native frames");
check(A.frame.title:GetText():find("Solo",1,true),"solo header uses a status rather than a misleading player count");
SlashCmdList.ASRPARTY(""); check(A.settings:IsShown() and A.frame:IsShown() and A.frame.rows[1].model.preview,"settings show a harmless solo preview");
check(#A.frame.rows==5 and A.frame.rows[5]:IsShown(),"solo preview contains five sample members");
check(A.frame.rows[1].bar:GetValue()==1 and A.frame.rows[2].bar:GetValue()==0.5,"preview includes full and half health");
check(A.frame.rows[3].model.down and A.frame.rows[3].hp:GetText()=="Dead","preview includes a dead member");
check(A.frame.rows[3].bar:GetValue()==0,"dead preview has an empty health bar");
check(A.frame.rows[1].bar:GetHeight()<=A.frame.rows[1].healthOverlay:GetHeight()*0.43,"health fill stays inside the decorative frame opening");
check(math.abs(A.frame.rows[1].bar:GetHeight()/A.frame.rows[1].healthOverlay:GetHeight()-37/(188*120/256))<0.0001,"health fill matches the native player frame vertical ratio");
check(A.frame.rows[4].bar:GetValue()==0.5 and A.frame.rows[4].hp:GetText():find("50%%"),"preview includes revival progress");
check(A.frame.rows[5].status:GetText()=="Reviving ally","preview identifies the rescuer");
A.frame.rows[1].scripts.OnClick(A.frame.rows[1]); check(not InspectedUnit,"preview cannot inspect a real party member");
SlashCmdList.ASRPARTY(""); check(A.frame:IsShown() and not A.frame.rows[1]:IsShown(),"closing settings removes solo samples but preserves the always-visible header");
ASRPartyDB.showHeader=false; A.Refresh(); check(not A.frame:IsShown(),"solo header is hidden when always-show is off");
A.settings.partyControls.showHeader.scripts.OnClick(); check(A.frame:IsShown() and A.frame.header:IsShown(),"enabling header while solo immediately shows it");
check(A.HealthText(1200,2400,"short")=="1.2k / 2.4k" and A.HealthText(1200,2400,"full")=="1200 / 2400","short and full health formats");
check(A.HealthText(1200,2400,"percent")=="50%" and A.HealthText(1200,2400,"both")=="1.2k (50%)","percent and combined health formats");
A.settings.partyControls.healthFormat.scripts.OnClick(); check(ASRPartyDB.healthFormat=="full" and A.settings.partyControls.healthPreview:GetText()=="1200 / 2400","format button updates its example immediately");
ASRPartyDB.healthFormat="short";
PartyTestUnits.party1={name="Ultra",class="MAGE",level=36,hp=590,max=800,connected=true}; A.Refresh();
check(A.frame:IsShown() and A.active and #A.members==1,"real party member draws without Suite");
ASRPartyDB.showHeader=false; A.Refresh();
check(not A.frame.header:IsShown() and A.frame.rows[1].point[5]==0,"hidden header leaves no blank space above the first member");
A.editing=true; A.Refresh(); check(A.frame.header:IsShown(),"editing restores the hidden header for dragging and settings");
A.editing=false; ASRPartyDB.showHeader=true; A.Refresh();

check(A.frame:GetWidth()==196 and A.frame.rows[1]:GetHeight()==102 and A.frame.rows[1].portrait.portraitUnit=="party1","classic uses common width and live portrait");
check(A.frame.rows[1].hp:GetText()=="590 / 800" and A.frame.rows[1].levelText:GetText()=="36","classic contains current health and level");
check(not A.frame.backdrop and A.frame.header.backdrop and A.frame.rows[1].backdrop,"header and each member have separate frames without a shared outer frame");
check(A.frame.header:GetWidth()==196 and A.frame.rows[1]:GetWidth()==196 and A.frame.asrDockInsets.top==10 and A.frame.asrDockInsets.bottom==11,"chain uses tracker width and visible border insets for docking");
check(A.frame.title:GetText():find("2",1,true) and A.frame.rows[1].status:GetText()=="Mage","header counts players and classic secondary text contains the localized class");
check(A.frame.rows[1].portraitBorder.texturePath:find("orb_case_hi",1,true) and A.frame.rows[1].bar.barTexture:find("hp_lowmid_bar",1,true) and A.frame.rows[1].barCase.texturePath:find("hp_mid_case",1,true),"portrait and health use the actual player-frame assets");
check(A.frame.header:GetHeight()>=64 and A.frame.title.point[5]==-24 and A.frame.settings.point[5]==-22,"header fits the full-size stone border and aligned content");
check(A.frame.rows[1].portrait:GetWidth()==36 and A.frame.rows[1].levelBadge:IsShown(),"classic has a larger round portrait with numeric level badge");
check(A.frame.rows[1].levelBadge:GetWidth()==24 and A.frame.rows[1].badgeText:GetText()=="36" and A.frame.rows[1].levelRim.texturePath:find("actionbutton-border",1,true),"level uses the same circular disk and rim as ASR minimap button");
local portrait=A.frame.rows[1].portrait; check(not portrait:IsShown(),"unclipped native portrait remains hidden");
for _,part in ipairs(A.frame.rows[1].portraitSlices) do if part:IsShown() then
 local x,y=part.point[4],-part.point[5]; local w,h=part:GetWidth(),part:GetHeight(); local r=portrait:GetWidth()/2;
 for _,corner in ipairs({{x,y},{x+w,y},{x,y+h},{x+w,y+h}}) do check((corner[1]-r)^2+(corner[2]-r)^2<=r*r+0.0001,"every portrait slice remains inside its circle even if native portrait calls resize the texture"); end
end end
check(A.settings.close.point[5]==-26 and A.settings.close.point[4]+A.settings.close:GetWidth()<=A.settings:GetWidth()-24,"close button is inset from top and right stone border");
local h=A.frame.rows[1].healthOverlay; local bar=A.frame.rows[1].bar;
check(h.point[4]==67 and h.point[4]+h:GetWidth()==178 and A.frame.rows[1].name.point[4]==82,"health case and text align from portrait gap to shared right padding");
check(bar:GetWidth()<h:GetWidth() and bar:GetHeight()<h:GetHeight() and h:GetFrameLevel()>bar:GetFrameLevel(),"health fill is inset and decorative edge layer is above it");
check(A.settings.partyControls.mode.point[4]==20 and A.settings.partyControls.mode:GetWidth()==290 and A.settings.partyControls.labels[1][1].point[5]==-26,"standalone settings content respects frame margins");
local owners,shows=0,0; GameTooltip.SetOwner=function() owners=owners+1; end; GameTooltip.Show=function() shows=shows+1; end;
local hovered=A.frame.rows[1]; hovered.scripts.OnEnter(hovered); local first=owners; A.Refresh(); Advance(0.6); A.Refresh();
check(owners==first and hovered.backdropBorderColor[2]==209/255,"refresh preserves hover border and does not repeatedly reset tooltip ownership");
hovered.scripts.OnLeave(hovered); check(A.tooltipOwner==nil and hovered.backdropBorderColor[1]==0.75,"leaving immediately restores normal border without a darker second hover state");
local initialScale=ASRPartyDB.scale;
for _,scale in ipairs({0.65,0.85,1.2}) do
 ASRPartyDB.scale=scale; A.Refresh(); local row=A.frame.rows[1]; local top=-row.point[5];
 check(math.abs((top+10-(A.frame.header:GetHeight()-11))*scale-4)<0.0001,"internal attachment gap remains four visible units at every scale");
end
ASRPartyDB.scale=initialScale; A.Refresh();
check(AzerothSurvivorsPartyUnitButton1:GetAlpha()==0 and not AzerothSurvivorsPartyUnitButton1:IsMouseEnabled() and not PartyTestAura:IsMouseEnabled(),"native portraits and their child hit areas are suppressed");
A.frame.rows[1].scripts.OnClick(A.frame.rows[1]); check(InspectedUnit=="party1","left click opens unchanged native character window");
SlashCmdList.ASRPARTY("unlock"); A.frame.scripts.OnDragStart(A.frame); check(A.frame.moving,"classic header allows dragging");
A.frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",100,-120); A.frame.scripts.OnDragStop(A.frame);
check(ASRPartyDB.positions.classic.x==100 and not A.frame.moving,"classic placement saved");
SlashCmdList.ASRPARTY("compact"); check(A.frame.rows[1]:GetHeight()==82 and not A.frame.rows[1].portrait:IsShown(),"compact style removes portrait and reduces height");
check(-A.frame.rows[1].healthOverlay.point[5]+A.frame.rows[1].healthOverlay:GetHeight()<=A.frame.rows[1]:GetHeight()-20,"compact health artwork has clearance above the bottom stone border");
A.frame.scripts.OnDragStart(A.frame); A.frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",200,-240); A.frame.scripts.OnDragStop(A.frame);
check(ASRPartyDB.positions.compact.x==200 and ASRPartyDB.positions.classic.x==100,"each view has independent saved placement");
InspectedUnit=nil; A.frame.rows[1].scripts.OnClick(A.frame.rows[1]); check(not InspectedUnit,"releasing a group drag does not accidentally inspect"); Advance(0.3);
SlashCmdList.ASRPARTY("classic"); check(A.frame.point[4]==100,"switching back restores classic placement");
SlashCmdList.ASRPARTY("lock"); A.frame.scripts.OnDragStart(A.frame); check(not A.frame.moving,"standalone lock blocks dragging");
AZS_PARTY={{name="Ultra",dmg=10000,dps=500,share=60}}; AZS_PEERS.Ultra={spells={{key="fireball",rank=3}},gear={{name="Ring"}}}; A.Refresh();
check(A.members[1].meter.dps==500 and #A.members[1].peer.spells==1,"meter and peer loadouts are joined by current name");
PartyTestUnits.party1.hp=0; AZS_REVIVE={friends={{name="Ultra",share=0.4}}}; A.Refresh();
check(A.members[1].down and A.frame.rows[1].bar:GetValue()==0.4 and A.frame.rows[1].hp:GetText():find("40%%"),"downed friend shows revive progress even when UnitIsDead throws");
AZS_REVIVE={reviving="Ultra",rshare=0.8}; A.Refresh(); check(A.members[1].revive==0.8,"own revive target uses authoritative progress");
PartyTestUnits.party1.connected=nil; A.Refresh(); check(A.frame.rows[1].hp:GetText()=="Offline","legacy nil connection status displays offline");
PartyTestUnits.party1.connected=true; PartyTestUnits.party1.hp=nil; PartyTestUnits.party1.max=nil; AZS_REVIVE={}; A.Refresh();
check(not A.members[1].down and A.frame.rows[1].hp:GetText()=="— / —","unknown health is not fabricated as dead");
PartyTestUnits.party1.name=string.rep("Оченьдлинноеимя",8); A.Refresh(); check(A.frame.rows[1].name:GetStringWidth()<=96,"long UTF-8 names fit classic layout");
SlashCmdList.ASRPARTY("off"); check(not A.frame:IsShown() and AzerothSurvivorsPartyUnitButton1:GetAlpha()==0.7 and AzerothSurvivorsPartyUnitButton1:IsMouseEnabled() and PartyTestAura:IsMouseEnabled(),"disabling restores previous native appearance and mouse handling");
check(PartyTestAura:GetAlpha()==0.4,"native child alpha is restored after its parent under recursive client alpha writes");
SlashCmdList.ASRPARTY("on"); check(A.frame:IsShown() and AzerothSurvivorsPartyUnitButton1:GetAlpha()==0,"reenabling replaces native frames again");
AzeritePartyUnitButton2=CreateFrame("Button",nil,UIParent); AzeritePartyUnitButton2:SetAlpha(1); A.Refresh(); check(AzeritePartyUnitButton2:GetAlpha()==0,"late-created native party buttons are discovered");
PartyTestUnits={}; A.Refresh(); check(A.frame:IsShown() and not A.frame.rows[1]:IsShown() and AzeritePartyUnitButton2:GetAlpha()==1,"leaving group releases native frames");
local db=ASRPartyDB; A.Init(); check(ASRPartyDB==db and db.positions.compact.x==200,"reload initialization preserves both views' positions");


check(A.frame.rows[1].portraitLayer:GetFrameLevel()>A.frame.rows[1].bar:GetFrameLevel(),"portrait frame stays above panel background and overlaps the health joint");
check(A.frame.rows[1].levelBadge.point[1]=="TOPLEFT" and A.frame.rows[1].levelBadge.point[4]==18 and A.frame.rows[1].levelBadge.point[5]==-24,"level medallion is inset on the upper left portrait edge");

-- Check artwork bounds against the visible stone frame, with inner clearance.
local r=A.frame.rows[1]; local orb=r.portraitBorder; local health=r.healthOverlay;
for _,region in ipairs({orb,health,r.levelBadge}) do
 local x,y=region.point[4],-region.point[5];
 check(x>=16 and x+region:GetWidth()<=180 and y>=18 and y+region:GetHeight()<=85,"classic artwork stays clear of all four visible stone edges");
end
local orbRight=orb.point[4]+orb:GetWidth();
check(orbRight-health.point[4]>=0 and orbRight-health.point[4]<=9,"health joins portrait with at most nine units of overlap");
print("PASS: "..n.." standalone party checks");

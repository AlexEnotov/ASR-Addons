-- Confirmed live entries absent from the client's explicit legend records.
-- Keep these separate so refreshing extracted metadata cannot remove them.
-- Name, spell and icon confirmed by the Mind Sear drop; base effect numbers
-- are intentionally unknown until authoritative metadata is available.
local extras={
 {key="legend_mind_sear",spell="mind_sear",name="Amulet of the Inferno",ru="Амулет инферно",icon="INV_Jewelry_Necklace_AhnQiraj_04",effects={},incomplete=true},
};
local known={}; for _,m in ipairs(ASAdvisorMechanics.legends) do known[m.key]=true; end
for _,m in ipairs(extras) do if not known[m.key] then ASAdvisorMechanics.legends[#ASAdvisorMechanics.legends+1]=m; end end

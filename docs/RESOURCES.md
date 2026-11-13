# Source and resource notes

- `ASAdvisor/media/arrow-*.tga`: generated UI glyphs; generator is `ASAdvisor/tools/build-arrow.cjs`.
- `ASRCombatText/media/minimap.tga` and `ASRSuite/media/minimap.tga`: small circular fallback textures created for these addons. No SurvivorUI texture files are bundled.
- Game icons, fonts and border textures are referenced by existing installation paths at runtime. They are not copied into release ZIPs and remain the property of their respective owners.
- `ASAdvisor/Mechanics.lua` is generated factual item/mechanic metadata; `Names.lua` contains display names/translations read from the game. The source-generation tools remain in the repository, outside release ZIPs. These data files need to be considered separately from the license of original ASR implementation code; adding a root license does not claim ownership of game names or translations.
- SurvivorUI was inspected for integration behavior. The runtime uses its exposed controls when available; its source tree is not included in this repository.
- Fengari and luaparse are test-only npm dependencies installed from their upstream packages. They are not included in addon ZIPs. Their dependency license notices remain in node_modules when installed for development.

Before publication, review the diff and these provenance notes together with the selected code license. This is a resource inventory, not a claim that third-party content can be relicensed.

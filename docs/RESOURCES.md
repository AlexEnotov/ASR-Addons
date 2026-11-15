# Source and resource notes

- `assets/branding/icons/asr-*.png`: original ASR icon artwork generated and edited with the built-in image generation tool and approved by the project owner. These design masters are outside runtime addon folders and are not included by the release packager. See `docs/ICON-STYLE.md` for the approved appearance and reusable prompt.

- `ASRAdvisor/media/arrow-*.tga`: generated UI glyphs; generator is `ASRAdvisor/tools/build-arrow.cjs`.
- `ASRCombatText/media/minimap.tga` and `ASRSuite/media/minimap.tga`: small circular fallback textures created for these addons. No SurvivorUI texture files are bundled.
- Game icons, fonts and border textures are referenced by existing installation paths at runtime. They are not copied into release ZIPs and remain the property of their respective owners.
- `ASRAdvisor/Mechanics.lua` is generated factual item/mechanic metadata; `Names.lua` contains display names/translations read from the game. The source-generation tools remain in the repository, outside release ZIPs. These data files need to be considered separately from the license of original ASR implementation code; adding a root license does not claim ownership of game names or translations.
- SurvivorUI was inspected for integration behavior. The runtime uses its exposed controls when available; its source tree is not included in this repository.
- `ASRSuite/WorldNames.lua` contains map and boss display-name pairs from the installed game's generated catalog. It contains no game mechanics or descriptions. Regenerate with `node tools/generate-world-names.cjs <installed AzerothSurvivors/Generated directory>`. These game names/translations are separate from the license of original ASR code.
- `ASRLoot/Metadata.lua` contains verified class-set names, localized duplicate markers and built-in common armor icon names from the installed game. `tools/generate-loot-metadata.cjs` validates source names when regenerating these display hints. Item icons are referenced from the client, not redistributed. Native item metadata takes precedence; unknown items are not assigned invented data.
- Fengari and luaparse are test-only npm dependencies installed from their upstream packages. They are not included in addon ZIPs. Their dependency license notices remain in node_modules when installed for development.

Before publication, review the diff and these provenance notes together with the selected code license. This is a resource inventory, not a claim that third-party content can be relicensed.

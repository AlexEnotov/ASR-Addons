# ASR Addons v0.6.0

Five independently installable addons, with optional shared settings. Fresh
installations default to English; existing language choices and builds are kept.

## Downloads

Extract the ZIPs you need into `Interface/AddOns`, or use **ASR-All-v0.6.0.zip**
for all five. Use the release Assets, not GitHub's Source code archives.

- **ASRAdvisor-v0.6.0.zip** — build editor, sharing, recommendations and tracker.
- **ASRStats-v0.6.0.zip** — selectable character statistics.
- **ASRCombatText-v0.6.0.zip** — movable, configurable combat numbers.
- **ASRSuite-v0.6.0.zip** — shared settings, layout editor and Endless tracker.
- **ASRLoot-v0.6.0.zip** — new permanent equipment and sold duplicate drops.

Suite is optional for the other four addons. Endless is included in Suite.
The game's own addons are required and are not bundled. `SHA256SUMS` covers
all six ZIPs.

## What's new

- **Loot:** a compact icon panel with New/All filters, rarity and hover details,
  duplicate gold totals, run persistence across reloads and opening preferences.
- **Endless in Suite:** replace the completed map objectives with repeating boss
  rounds, living/defeated status and the next spawn countdown. Show map difficulty,
  level, time and enemies slain using the native tracker style.
- **Advisor:** recognize class amulets, preserve build priority, hide obsolete
  backup amulets and separate confirmed banned spells. Plan up to three bans
  and display one primary recommendation without automating choices.
- **Build goals:** jewelry targets now compare total character stats. Spell goals
  can retire completed improvements individually while leaving others unlimited.
- **Stats:** choose which individual statistics appear.
- **Suite:** export/import all installed ASR settings and build libraries,
  including panel positions, scales and docking. Unify tracker sizing and spacing;
  improve the language picker and compact settings layout.
- **Readability:** clearer colored spell tooltips, base descriptions, rank badges
  and compact summaries. Combat Text and Advisor abbreviate billions/trillions.

## Upgrading

Review saved jewelry goals: their numbers are preserved, but now mean the total
character stat, not one item's bonus. Rank zero keeps unconfigured spell upgrades
unlimited; a positive rank with stat goals selects only configured improvements.
Existing Advisor tracker widths reset once to the shared base width.

Settings import replaces the included settings and saved build libraries after
validation and reloads the UI. Export your current settings first if you want a
backup. Live loot and ban journals are separate from settings profiles.

## Validation and limits

Automated Lua 5.1, standalone modules, game catalogue/recommendation scenarios,
settings transfer, docking and package checks passed. Loot drops and duplicate
display were checked in solo play on Reborn 0.6.5. Release ZIPs are also checked
with the current addon-index validator.

Unknown future equipment retains an explicit question-mark/unknown-rarity
fallback until metadata is available. Bans observed by Advisor survive reloads;
the public API cannot recover bans made before observation. Very dense combat,
all map variants and co-op still warrant further live testing.

See [CHANGELOG](../CHANGELOG.md) for the consolidated details.

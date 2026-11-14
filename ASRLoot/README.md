# ASR Loot

Standalone permanent-equipment drop tracker for Azeroth Survivors Reborn.
It tracks armor and weapons, not run jewelry or item stars. Suite is optional.

- **New items only**: newly acquired equipment from native loot events.
- **All drops**: also includes sold duplicates from the game's localized system
  messages, with a running duplicate-gold total for the current run.
- The header shows **New** / **All**; click that button to change the filter.
- A compact icon grid uses rarity borders; hover an icon for its name and rarity.
- Opens at run start by default. Suite can select opening on a matching drop
  instead, or manual opening. Closing preserves background tracking.
- Repeated identical items are grouped, newest first. Scroll for older entries.
- The current run, selected mode and observed item metadata survive reloads.
- End-of-run duplicate gold reconciles missed earlier gold without adding the
  same total twice. Further Endless drops continue adding to that total.
- Native loot notifications can be restored by disabling their replacement.

Use `/asrloot` to show the tracker, `/asrloot new` or `/asrloot all` to switch modes,
and `/asrloot hide` to hide it. `/asrloot en` and `/asrloot ru` select a language
without Suite. With Suite, use its **ASR Loot** settings section and shared language.
Move the panel in Suite edit mode; standalone it can be dragged directly.

## Data and limitations

The tracker uses `AZSLOOT`, exact localized duplicate-message markers, `AZSARMOR`
and the final `AZSEND.dupgold`. Coins and unrelated gold rewards are not counted.
The full account collection is not scanned. Only drops observed after enabling
the addon are listed; an end summary can supply the full run's duplicate-gold total.
No boss source is guessed from timing.

Authoritative item icons/rarities are cached from native loot and worn-equipment
messages. Verified class-set name hints and the native `AZS_GEN.setLooks` table
resolve additional armor duplicates and base weapons using verified class/tier tables.
Armor-slot and item-name aliases include the game's extracted translations;
higher tiers use the live game catalog. Already saved unknown entries are
refreshed when metadata becomes available, including an already-owned common hunter
helmet on the first observation. Unrecognized items retain their name and gold
but show a question-mark icon and unknown rarity rather than an invented value.
Item names remain as supplied by the game. The UI supports English and Russian;
duplicate-message markers are taken from the game's available translations.

The journal retains at most 500 drop entries; totals include older entries too.
This is a local unreleased addon; live drop-event verification remains necessary.

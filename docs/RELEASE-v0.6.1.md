# ASR Addons v0.6.1

**ASR Endless is now a standalone addon.** Install it on its own or use it with
the optional ASR Suite settings and layout editor. Suite itself no longer bundles
the tracker. Its existing appearance and boss countdown behavior are preserved.

## Downloads

Extract the packages you need into `Interface/AddOns`, or install
**ASR-All-v0.6.1.zip** for the entire family:

- **ASRAdvisor-v0.6.1.zip** — build editor, recommendations and tracker.
- **ASRStats-v0.6.1.zip** — selectable character statistics.
- **ASRCombatText-v0.6.1.zip** — configurable combat numbers.
- **ASRSuite-v0.6.1.zip** — optional shared settings and interface editor.
- **ASRLoot-v0.6.1.zip** — permanent equipment drops and duplicate gold.
- **ASREndless-v0.6.1.zip** — Endless boss rounds and countdowns.

Six individual packages plus one combined ZIP; `SHA256SUMS` covers all seven.
Each functional addon works without Suite. Fresh installations default to English.
Use these Assets rather than GitHub's Source code archives.

## Upgrading Endless

Existing Suite users who want to keep the tracker should install **both updated
Suite and ASR Endless**, or the combined package. The first joint launch transfers
the saved visibility, panel position and boss progress into the standalone addon.
Settings export/import includes the new module and accepts older Suite profiles.

Without Suite, `/asrendless` opens its own settings. `/asrendless on` and
`/asrendless off` toggle the tracker; `/asrendless unlock`, `/asrendless lock`
and `/asrendless reset` manage movement and position. Disabling restores the
native tracker. With Suite, the Endless page and shared layout editor remain.

## Validation

Automated Lua 5.1 checks, independent addon loading, 77 existing Endless scenarios,
standalone controls, one-time migration, shared controls and settings transfer
passed, alongside the other module/game-catalogue tests. All seven ZIPs are
checked with the current addon-index validator. The new standalone packaging
still warrants live verification; the previous embedded tracker was tested during
development. This release does not change the other modules' gameplay features.

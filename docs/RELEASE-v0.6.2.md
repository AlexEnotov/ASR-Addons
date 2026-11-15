# ASR Addons v0.6.2

Eight independent addons for Azeroth Survivors Reborn. ASR Suite is optional.

## New addons

- **ASR Chat** — move and resize native chat, switch tabs, customize fonts,
  spacing, backgrounds and borders, and copy recent messages. Includes compact
  tab controls, an online-friends counter and separate visibility options for
  controls and input. Controls fade smoothly while messages keep their own
  display duration. Command: `/asrchat`.
- **ASR Party** — classic portrait frames or compact party rows, movable panels,
  class colors, levels, selectable health-number formats and death/revival
  status. Clicking a member keeps the native character window. Command:
  `/asrparty`. Live co-op coverage remains limited.

## Improvements and fixes

- Advisor's main folder is now **ASRAdvisor**. Existing builds and settings are
  preserved through a small settings-only **ASAdvisor** bridge included in the
  same ZIP. The priest's Inferno/Mind Sear amulet is available in the builder.
- Suite has consistent module names, a version display, separate About and
  Compatibility pages, copyable links and matching menu/compatibility ordering.
- Magnetic docking favors free edges near the cursor, avoids occupied edges
  and keeps docking hints on screen.
- Endless stays above game dimming while editing the interface.
- Chat keeps messages above input during resizing, prevents messages from
  jumping when controls fade, and respects message lifetime settings.
- Disabling Party and Chat restores native controls and decoration, including
  the client's parent/child transparency behavior.

## Downloads

Each feature addon works independently: Advisor, Stats, Combat Text, Endless,
Loot, Party and Chat. Suite provides shared settings and interface editing.
Choose an individual ZIP, or **ASR-All-v0.6.2.zip** for all eight addons.

## Upgrading Advisor

Close the game. Back up `WTF`, replace the old `Interface/AddOns/ASAdvisor`
folder with **both** folders in the Advisor ZIP: `ASRAdvisor` and `ASAdvisor`.
The latter is only a settings bridge and should stay enabled during migration.
Do not keep the old full Advisor code beside the new addon. Restart the game.

Catalogue updates require maintainer review and signing before they appear in
the game's launcher. GitHub release downloads are available immediately.

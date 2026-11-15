# ASR Party

Standalone movable party frames for Azeroth Survivors Reborn. Requires the game's
AzerothSurvivors and AzerothSurvivorsAPI addons; ASR Suite is optional.

- **Classic:** larger round portrait with a numeric level badge, name, class and
  native sculpted health bar in a taller individual frame.
- **Compact:** smaller rows with name, level and health, without portraits.
- Left click opens the same native character window as the original party portraits.
- Hover for received damage-meter and loadout information and revive status.
- Downed, offline and revive progress displays use the available game data.
- Each view saves its own position. Scale uses the family's 196-unit base width.
- The header can stay visible even while solo, or appear only while editing/opening settings.
- Health numbers support short/full values, percent, or value with percent;
  settings show an immediate example of the selected format.
- A separate header counts all players; each member has its own permanently
  attached frame. Visible border gaps follow Suite's docking gap across scales.
- Group difficulty scaling is not shown: no confirmed coefficient is exposed in
  the checked party data. No percentage is guessed from the number of players.
- Layout editing raises the entire chain above game dimming/screens. Hover
  highlighting persists during live updates without resetting tooltip ownership.
- Classic uses the native player orb frame and health-bar artwork, with the
  level kept in a separate round medallion on the edge. Explicit circular portrait
  slices prevent oversize native images leaking outside their frame.
- Native party portraits return when the module is disabled or the group is gone.

## Controls

- `/asrparty` — settings, with a solo preview when not in a group.
- `/asrparty classic` / `/asrparty compact` — switch views.
- `/asrparty on` / `/asrparty off` — enable or restore native portraits.
- `/asrparty unlock` / `/asrparty lock` — standalone movement lock.
- `/asrparty reset` — reset the current view's position.
- `/asrparty en` / `/asrparty ru` — language.

Drag the header to move the group. With Suite installed, use its Edit interface
mode and shared panel lock. The Party section supports view, scale, visibility,
language and reset controls; Suite profiles include both saved positions.

Data comes from party1–party4 unit functions, AZS_PARTY, AZS_PEERS and revive APIs.
Missing data stays unknown; another player's cooldowns, full character statistics
and permanent armor are not inferred. Preview members are examples and cannot
open a real character window. Other party-frame replacement addons should be
disabled to avoid duplicate custom panels.

This is a local development addition. Automated checks cover the two layouts,
native-frame restoration, inspection, dragging, late native buttons, party state,
Suite controls and profiles. Real co-op visuals still need an in-game check.

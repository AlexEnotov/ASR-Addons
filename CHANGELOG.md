# Changelog

Player-facing changes are grouped by release. Work in progress stays under
**Unreleased** until a release is prepared. Small layout and wording adjustments
are summarized with the feature they improve rather than listed individually.

## Unreleased

## v0.6.2 — 2026-11-15

- **ASR Chat — new addon:** movable and resizable native chat, wide tabs and a
  compact tab picker, custom channel/friends/scroll controls, appearance previews,
  stone/simple/borderless styles and copying recent messages. Hide the interface
  smoothly while messages retain their configured lifetime; chat controls and
  input have separate always-visible options. Keep input and message bounds stable
  during resizing and fading. Settings, layout editing and profile transfer work
  independently or through Suite.
- **ASR Party — new addon:** movable classic portrait frames and compact health
  rows, individual member frames, class colors, levels, health-number formats,
  death and revival states, and native character inspection on click. Includes
  five-state previews, an optional solo/group header and Suite integration.
- **ASR Advisor:** rename the main addon folder to `ASRAdvisor`. A minimal
  `ASAdvisor` settings bridge preserves existing builds and preferences. Add the
  confirmed priest Inferno/Mind Sear amulet without inventing missing base bonuses.
- **ASR Suite:** consistent module names and version display, separate About and
  Compatibility pages below module navigation, copyable links and compatibility
  controls ordered like the menu. Improve magnetic docking: prefer free edges
  near the cursor, avoid occupied edges and keep hints within the screen.
- **ASR Endless:** keep the tracker and its native charge bar above game dimming
  while editing the interface, restoring normal layers afterward.
- Ship eight standalone addon ZIPs and a complete ASR-All pack. Party's live
  co-op coverage remains limited; automated and local preview checks are included.

## v0.6.1 — 2026-11-15

- Extract ASR Endless from Suite into an independently installable addon with
  its own settings window, enable/disable commands, language and movement lock.
- Keep optional Suite settings, shared layout editing and full settings transfer.
  Migrate the embedded tracker visibility, position and run state once; support
  old settings profile codes and restore the native HUD when Suite is used alone.
- Ship six independent addon ZIPs plus an all-in-one ZIP. No changes to the
  other modules' gameplay behavior.

## v0.6.0 — 2026-11-15

### ASR Loot — new standalone addon

- Resolve duplicate base weapons from verified embedded class/tier tables,
  including localized names, and recognize all extracted armor-slot nouns
  such as plate belts. Use native metadata for additional gear tiers and
  refresh existing unknown journal entries as metadata becomes available.

- Track permanent armor and weapon acquisitions in two modes: new items only,
  or all drops including sold duplicates. Display icons, rarity, grouped repeat
  counts and the current run's total gold from duplicates.
- Preserve loot during reload while run and zone snapshots arrive separately;
  reset only after a changed server run ID is confirmed. Migrate old identities.
- Save the current run across reloads and reconcile duplicate gold against the
  end summary, continuing correctly into Endless. Bound retained entries to 500
  while preserving totals. Ignore coins and unrelated rewards.
- Use a compact rarity-bordered icon grid with hover details and a New/All
  filter button in the tracker header. Open at run start
  by default, on a matching drop, or manually through Suite controls.
- Add optional Suite settings, shared language and layout-editor integration;
  standalone controls remain available through `/asrloot`.
- Use native item metadata and verified equipment hints. Unrecognized duplicate
  metadata uses a question-mark/unknown-rarity fallback. Real duplicate drops
  and display were checked in game; unresolved future item metadata retains
  the explicit fallback.

### ASR Advisor

- Keep tracker summaries compact with abbreviated duration/units and K/M/B/T
  damage formatting. Show class-specific amulets as Special bonus, preserving
  their full effects in hover descriptions and exact values for goal checks.

- Hide lower-priority backup amulets after a preferred amulet is equipped.
  Move confirmed banned spells into a separate muted-red icon group without
  stats/ranks in both tracker modes. Persist observed bans across reloads, reset
  them per run, and require a sent ban command plus server charge confirmation.
  Keep a bounded set of run journals through transient reload IDs and persist
  pending ban confirmations across reloads. Earlier unobserved bans are
  unavailable from current public spell snapshots.
- Show one primary action: a useful card suppresses ban highlighting; otherwise
  highlight only the selected ban candidate before reroll/skip alternatives.

- Use total character stats for jewelry build goals and current values in the
  editor, rather than the bonus printed on an individual item. Missing totals
  remain unknown. Preserve per-item goals, priority and global-cap rules.
- Separate spell goal modes: rank zero keeps unconfigured improvements unlimited
  and retires completed goals independently; positive rank with stat goals
  accepts only improvements toward those goals. Mixed cards remain useful when
  any allowed improvement remains. Rank-only goals still stop at that rank.
  Automatic bans preserve rank-zero spells with unlimited improvements; explicit
  manual bans stop upgrade recommendations once their conditions are satisfied.

- Recognize qualified class-specific amulet names, including Inferno amulets,
  when matching equipped items to a build. Existing amulet priority rules now
  apply to these items correctly.
- Preserve build order for spell upgrades with no configured goals. A lower
  priority spell with a stat goal no longer automatically outranks an uncapped
  higher priority spell, including the Consecration/Divine Storm case.
- Add ban planning: choose up to three spells manually; remaining slots are
  filled from the lowest build priorities. Ban hints appear when no useful pick remains, after
  acquisition and fulfillment of configured goals. No actions are automated.
- Present base spell mechanics as readable descriptions before acquisition,
  alongside current descriptions when available. Include targeting range and
  descriptive ability-role tags without repeating target/projectile counts.
- Keep compact tracker spell ranks readable with outlined white digits on a
  dark corner badge that expands for multi-digit ranks.
- Improve tooltip readability with class and damage-school colors, distinct
  base/current headings, measured text wrapping and numeric units kept together.

### ASR Stats

- Choose individual tracker stats in Suite, grouped by category, with a scrollable
  list and enable/disable-all controls. Preserve choices across runs and reloads;
  collapse empty categories and apply hide-zero filtering independently.

### ASR Combat Text

- Abbreviate billions and trillions instead of displaying large multiples of
  millions. Respect the individual damage type's number-format setting.
- Accept very large finite combat amounts and handle aggregation overflow safely.

### ASR Suite

- Simplify the shared language picker to full-width language tiles without an
  outer frame. Prevent the opening mouse press from dismissing the list, and
  close other ASR language pickers when opening a new one. Keep popup tiles on
  the tooltip layer so fullscreen settings backgrounds cannot cover them.

- Add complete settings export/import under General, including per-module
  preferences, panel positions/scales, docking links, Endless options and saved
  builder libraries/active selections. Validate a bounded data-only code before
  applying all sections, then reload the UI. Preserve live run records and HUD
  restoration state; reject incomplete profiles and missing required modules.

- Standardize Stats, Loot and both Advisor tracker modes on a 196-unit base
  width, with one-percent scale controls. Existing Advisor widths reset once;
  manual detailed-mode resizing remains available. Align tracker side padding
  and compact vertical layout; measure colored stat text without counting
  formatting codes as visible characters. Unify visible docking gaps
  on every side with an adjustable gap, including Loot texture padding.
- Apply the lime ASR prefix consistently to module headings.

- Add **Endless**, a module inside Suite, with an automatic replacement for the
  native run tracker only during endless play. Endless does not have a separate package. Disabling it restores the previous native tracker visibility.
- Track map boss order, repeat rounds, living and defeated bosses, endless boss
  kills, character level, run time and total enemies killed. Preserve progress
  across reloads and reconstruct it when enabled midway through a run.
- Show the next boss's countdown with smooth phase-aware time between updates,
  plus the native boss progress bar displaying percentage only.
- Match the native header, objective indicators and heroic modifier icons;
  show map difficulty, including named tiers. Place boss status and countdown
  in a separate right-aligned column and reset defeated markers for a new round.
- Translate known map and boss names according to the suite language independently
  of the game language. Preserve unknown community-map names.
- Add an Endless settings section with visibility, layout editing and position
  reset controls. Compact vertical spacing across settings content while
  preserving navigation and horizontal margins.

## v0.5.14

First combined release of four independently installable addons in one repository:
ASR Advisor, ASR Stats, ASR Combat Text and optional ASR Suite. Also available as
one combined download.

- Compact, height-limited Advisor tracker with scrolling and a separate strip for
  acquired abilities/items outside the build; improved tooltip visibility.
- Magnetic docking for Advisor and Stats panels with live snapping, a fixed
  border gap, parent/child movement and following dynamic panel size changes.
- Shared settings, compatibility controls and consistent settings layering.
- Extensible language selectors, English defaults and preserved saved choices.
- Standalone Combat Text with shared/per-type appearance, merging, movable lanes
  and question-mark icons for unknown sources.
- Fixed combat-text spacing and downward drift: a bounded queue preserves
  configured distances without pushing existing numbers. Spacing is measured
  between text positions, allowing intentional partial icon overlap.
- GPL-3.0-only for original implementation code, validated independent release
  packages and continuous integration.

See [release notes](docs/RELEASE-v0.5.14.md) for distribution details and validation.

The earlier Advisor-only release was v0.5.8. Its published artifacts are unchanged.

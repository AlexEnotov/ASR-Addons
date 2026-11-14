# Changelog

Player-facing changes are grouped by release. Work in progress stays under
**Unreleased** until a release is prepared. Small layout and wording adjustments
are summarized with the feature they improve rather than listed individually.

## Unreleased

### ASR Advisor

- Recognize qualified class-specific amulet names, including Inferno amulets,
  when matching equipped items to a build. Existing amulet priority rules now
  apply to these items correctly.
- Preserve build order for spell upgrades with no configured goals. A lower
  priority spell with a stat goal no longer automatically outranks an uncapped
  higher priority spell, including the Consecration/Divine Storm case.
- Add ban planning: choose up to three spells manually; remaining slots are
  filled from the lowest build priorities. Independent ban hints appear after
  acquisition and fulfillment of configured goals. No actions are automated.
- Present base spell mechanics as readable descriptions before acquisition,
  alongside current descriptions when available. Include targeting range and
  descriptive ability-role tags without repeating target/projectile counts.
- Improve tooltip readability with class and damage-school colors, distinct
  base/current headings, measured text wrapping and numeric units kept together.

### ASR Combat Text

- Abbreviate billions and trillions instead of displaying large multiples of
  millions. Respect the individual damage type's number-format setting.
- Accept very large finite combat amounts and handle aggregation overflow safely.

### ASR Suite

- Add **Endless**, a module inside Suite, with an automatic replacement for the
  native run tracker only during endless play. This is not a fifth standalone
  addon. Disabling it restores the previous native tracker visibility.
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

# ASR Addons v0.5.14

The first combined release of four independently installable ASR addons. Existing Advisor builds and preferences are preserved. All fresh installations default to English; Russian is available in the language dropdown.

## Download and install

Choose the ZIPs you need from Assets and extract them into `Interface/AddOns`:

- **ASRAdvisor-v0.5.14.zip** — build planner, recommendations and tracker (Advisor 0.5.14).
- **ASRStats-v0.5.14.zip** — current character statistics (Stats 0.1.14).
- **ASRCombatText-v0.5.14.zip** — movable combat numbers with individual type settings (Combat Text 0.1.6).
- **ASRSuite-v0.5.14.zip** — optional shared settings and interface editor (Suite 0.4.3).

Suite is optional. The other three addons work independently. The game's native AzerothSurvivors and AzerothSurvivorsAPI components are not included. GitHub's Source code archives are not installable addon packages. SHA256SUMS contains checksums for the four ZIPs.

## Changes

- Move the addon family into one repository, preserving Advisor's history. Add GPL-3.0-only for original implementation code, packaging validation and CI.
- Compact, height-limited Advisor tracker with scrolling, smaller unacquired rows and a separate strip for acquired abilities/items outside the build. Improve tooltip visibility and positioning.
- Optional magnetic docking for Advisor and Stats panels: live preview, a small fixed border gap, parent/child movement and automatic adjustment when panel size changes. Hold Shift to bypass snapping.
- Compact, scrollable compatibility controls and consistent settings panel layering.
- Extensible language dropdowns, English defaults and preservation of saved language choices.
- Combat Text supports shared or per-type appearance, merging, independently movable lanes, and a question-mark icon whenever a hit has no known icon.
- Minimum number spacing is an absolute distance between text positions; it does not add icon height. Small values allow partial overlap, and zero allows full overlap. A bounded queue preserves positive spacing without shifting the column origin or accelerating existing numbers.

## Validation and limitations

Lua 5.1 syntax, standalone module behavior, shared settings, docking, language selection, packaging and Advisor scenarios against the installed game catalogue passed automated checks. In-game layout and combat text were checked during development. Extremely dense combat still needs further live testing: positive spacing can delay queued hits, and the rendering pool is bounded to 512 entries. Third-party game resources are referenced from the installed client rather than redistributed.

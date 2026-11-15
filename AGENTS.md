# Project conventions

When creating or changing addon icons, read `docs/ICON-STYLE.md` and use the approved masters in `assets/branding/icons/` as visual references. Preserve the silver square frame, dark interior background, lime ASR accents, and transparency only outside the frame. These four designs were selected by the project owner; future addon icons should extend this family.

## Changelog and versions

Tracker sizing uses a common 196-unit base width. Stats, Loot and the default
Advisor modes occupy one unit; future wider panels may occupy multiple units,
accounting for the visible docking gap when spanning adjacent panels. This is
a shared sizing grid, not a requirement to make every addon equally wide.
Use consistent border geometry and 1% scale controls. Preserve deliberate manual
resizing where supported.

Record substantial player-facing additions and fixes in `CHANGELOG.md` under
`Unreleased`. Consolidate small layout, wording and iterative fixes into their
parent feature instead of listing every development step. Git commits retain
the detailed development history.

Do not bump addon versions, common release tags or package filenames for each
edit, local installation, screenshot iteration or test. Assign the next version
once when preparing an actual release containing the accumulated changes.
The common GitHub release tag is the player-facing distribution version; older
internal module counters are separate and must not be presented as successive
suite-wide releases. Review version consistency during release preparation.
Do not publish, tag, or replace existing release assets merely to record work.

## Catalogue pull requests

Submit each new addon to `Syiana/azs-addons` in its own pull request containing
one new `addons/<id>.toml` file. Do not combine different addons in one PR.
Run the official offline pin and check commands; include `index.json` only if
they change it. Handle changes to an existing addon's folder metadata in a
separate PR, updating only the affected pin. Leave routine version updates for
unchanged entries to the catalogue's daily pin workflow.

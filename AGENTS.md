# Project conventions

When creating or changing addon icons, read `docs/ICON-STYLE.md` and use the approved masters in `assets/branding/icons/` as visual references. Preserve the silver square frame, dark interior background, lime ASR accents, and transparency only outside the frame. These four designs were selected by the project owner; future addon icons should extend this family.

## Changelog and versions

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

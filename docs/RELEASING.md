# Release and store submission

This document prepares publication; running the checks or packager does not publish anything.

## Distribution model

Use one GitHub repository and one release containing four assets:

| Store ID | Asset pattern | Folder |
| --- | --- | --- |
| `asr-advisor` | `ASRAdvisor-v*.zip` | `ASAdvisor` |
| `asr-stats` | `ASRStats-v*.zip` | `ASRStats` |
| `asr-combat-text` | `ASRCombatText-v*.zip` | `ASRCombatText` |
| `asr-suite` | `ASRSuite-v*.zip` | `ASRSuite` |

Each ID has its own catalogue entry. `requires = []` is deliberate: Suite is optional and the native game addons are not entries to install from this catalogue. Do not add Suite as a mandatory dependency of a standalone module.

## Before the first submission

1. GPL-3.0-only has been selected for original ASR implementation code; the complete text is in root `LICENSE`. Keep third-party notices and the resource inventory; do not relicense material owned by others.
2. If renaming the GitHub repository, update the Git remote, README links and all four `catalog/*.toml` repository values. Keep technical addon folders and SavedVariables unchanged.
3. Review the source changes since `v0.5.8`, run both test commands in the root README and verify the modules in the game independently and together.
4. Select a new common release tag after `v0.5.8`; the first combined release uses `v0.5.14`. Record module changes in the release notes. Module TOC versions can differ; the store's distribution version is the common release tag.
5. Run `./tools/package.ps1 -Tag <tag>`. Inspect `release/` and hashes. Repeating a build with unchanged input produces identical bytes. Only attach that tag's four ZIPs and optional checksum file; never attach a second ZIP matching the same module pattern.
6. Commit the prepared source and packaging files, push to the author's repository, then create a Git tag pointing at the exact source used to build the ZIPs. Upload assets to a **draft** release first and review it.
7. Publish a normal release only when ready. Drafts and prereleases are ignored by the index bot. Do not replace bytes in an already pinned asset; use a new tag for any correction.
8. When explicitly authorized, submit the four proposed TOML entries to `Syiana/azs-addons`. Do not upload addon source to that repository. Reborn compatibility remains `untested` until an actual game version has been recorded from testing.

The existing release `v0.5.8` and its `ASRAdvisor-0.5.8.zip` asset predate this naming convention. Leave those published bytes intact; new assets include `-v` as in the patterns above.

## What the catalogue does

The official index fetches eligible GitHub release assets, validates ZIP structure and proposes a pin with the tag, URL, size and SHA-256. Maintainers review and merge; game maintainers sign the index. Only then does a player's launcher offer the pinned package. Merely pushing a branch, publishing source or opening an entry PR does not install an addon for players.

ZIP roots contain exactly the declared addon folder; its matching TOC uses Interface 30300. License text is copied inside each addon folder so it survives installation. Tests, tools, manifests, node_modules and game assets are excluded. The local validator covers generated package structure, sizes and TOC references; the official `tools/pin.py` validation is still required when submitting to the store.

Official rules: https://github.com/Syiana/azs-addons/blob/main/README.md

Compatibility integrations register an addon through ASRSuite.RegisterCompatibilityAddon(id, title, available, features). Each feature provides id, title, get, set and optional available callbacks. The list shows installed providers; each provider owns the precise changes and restoration for its elements. No settings UI edits are needed for a new provider.

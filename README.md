# ASR Addons — by AlexEnotov

Independent addons for **Azeroth Survivors Reborn**, with an optional shared settings and interface editor. Russian and English interfaces.

| Addon | Install folder | Command | Purpose |
| --- | --- | --- | --- |
| ASR Advisor | `ASAdvisor` | `/asr` | Build planner, tracker and card recommendations |
| ASR Stats | `ASRStats` | `/asrstats config` | Current character stats |
| ASR Combat Text | `ASRCombatText` | `/asrtext` | Movable combat numbers with per-type settings |
| ASR Suite | `ASRSuite` | `/asrhub` | Shared settings, compatibility controls, interface editor and automatic Endless tracker |
| ASR Loot | `ASRLoot` | `/asrloot` | Permanent equipment drops, new items and duplicate gold |

Install only what you need. Advisor, Stats, Combat Text and Loot work without Suite. Suite discovers installed modules; it does not require all of them. All modules require the game's native AzerothSurvivors addon; some also use AzerothSurvivorsAPI as declared in their TOCs. These native game components are not bundled. The v0.6.0 release includes all five modules. Endless is included in Suite.

## Installation

Download the individual addon ZIPs from the [latest release](https://github.com/AlexEnotov/ASR-Addons/releases/latest)'s **Assets** section. Extract each directly into `Interface/AddOns`. For example: `Interface/AddOns/ASAdvisor/ASAdvisor.toc`. GitHub's automatically generated **Source code** archives are for development and cannot be installed through the game's addon catalogue.

Technical folder names and SavedVariables names stay unchanged, preserving existing builds and preferences. Read each module's README for its controls and limitations.

## Repository layout

```text
ASAdvisor/       builder source, tests, metadata tools and original glyphs
ASRStats/        character stats source and tests
ASRCombatText/   standalone combat text source and tests
ASRSuite/        optional shared settings source and tests
ASRLoot/         standalone equipment drop tracker and tests
tools/          repository checks and release packaging
catalog/        store entry templates (four accepted; Loot submitted with v0.6.0)
docs/           release process and resource notes
.github/        checks; no automatic publication
```

The repository retains the builder's original Git history. Runtime addon folders are independent. Repository test dependencies are development-only and never shipped to players.

## Development

Node.js 22 and PowerShell 7:

```powershell
npm ci --ignore-scripts
npm test
npm run test:game -- "D:/path/to/game/Interface/AddOns/AzerothSurvivors"
./tools/package.ps1 -Tag v0.6.0
```

`npm test` checks Lua 5.1 syntax for all modules, TOC resources and Stats/Combat Text/Suite scenarios. The builder's full recommendation tests require a locally installed native game catalogue, supplied explicitly to `test:game`; CI does not redistribute it. Mocked UI tests do not replace in-game visual checks.

Packaging writes five independently installable, deterministic ZIPs, an ASR-All bundle and `SHA256SUMS` to ignored `release/`. The tag is the shared distribution release version; all five module TOC/runtime versions are aligned to 0.6.0 for this release. The store displays the pinned release tag.

See [the release process](docs/RELEASING.md). Original ASR implementation code is licensed under **GPL-3.0-only**. Copyright (C) 2026 AlexEnotov. See [LICENSE](LICENSE) for the full terms and [resource notes](docs/RESOURCES.md) for game data and third-party material, whose rights remain with their respective owners.

Fresh installations default to English in all five addons. Saved language preferences are preserved on update.

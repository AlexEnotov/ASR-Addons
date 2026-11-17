# ASR Addons — by AlexEnotov

Independent addons for **Azeroth Survivors Reborn**, with an optional shared settings and interface editor.

Built-in interface languages match the game: English, Russian, German, French,
Spanish, Brazilian Portuguese, Italian, Polish, Turkish, Japanese, Simplified
Chinese and Korean. Select a language in Suite or in an individual addon's
settings. Missing translations use English. Translations of game content use
the installed game's terminology; Japanese, Chinese and Korean use its bundled
fonts. Settings, tooltips, generated effect descriptions and diagnostic labels
are translated; raw descriptions and player-written text received from the game
retain their original language.

| Addon | Install folder | Command | Purpose |
| --- | --- | --- | --- |
| ASR Advisor | `ASRAdvisor` | `/asr` | Build planner, tracker and card recommendations |
| ASR Stats | `ASRStats` | `/asrstats config` | Current character stats |
| ASR Combat Text | `ASRCombatText` | `/asrtext` | Movable combat numbers with per-type settings |
| ASR Suite | `ASRSuite` | `/asrhub` | Shared settings, compatibility controls, interface editor |
| ASR Endless | `ASREndless` | `/asrendless` | Endless boss rounds and countdowns |
| ASR Loot | `ASRLoot` | `/asrloot` | Permanent equipment drops, new items and duplicate gold |
| ASR Party | `ASRParty` | `/asrparty` | Classic and compact party frames |
| ASR Chat | `ASRChat` | `/asrchat` | Movable native chat, appearance and copying |

Install only what you need. All seven feature addons work without Suite. Suite discovers installed modules; it does not require all of them. All modules require the game's native AzerothSurvivors addon; some also use AzerothSurvivorsAPI as declared in their TOCs. These native game components are not bundled. The v0.6.3 release includes eight standalone addons.

## Installation

Download the individual addon ZIPs from the [latest release](https://github.com/AlexEnotov/ASR-Addons/releases/latest)'s **Assets** section. Extract each directly into `Interface/AddOns`. For example: `Interface/AddOns/ASRAdvisor/ASRAdvisor.toc`. GitHub's automatically generated **Source code** archives are for development and cannot be installed through the game's addon catalogue.

When upgrading Advisor from v0.6.1 or earlier, close the game and replace the old `ASAdvisor` addon folder with **both** folders from the new Advisor ZIP: `ASRAdvisor` and `ASAdvisor`. Do not leave old Lua files inside `ASAdvisor`: the replacement is a settings-only bridge, not a second copy of Advisor. Keep the bridge enabled for migration. SavedVariables names are unchanged, so builds and preferences are preserved. Back up your `WTF` folder before upgrading. Read each module's README for its controls and limitations.

## Repository layout

```text
ASRAdvisor/      builder source, tests, metadata tools and original glyphs
ASAdvisor/       settings-only bridge for existing Advisor installations
ASRStats/        character stats source and tests
ASRCombatText/   standalone combat text source and tests
ASRSuite/        optional shared settings source and tests
ASRLoot/         standalone equipment drop tracker and tests
ASREndless/      standalone endless boss tracker and tests
ASRParty/        standalone party frames and tests
ASRChat/         standalone native chat controls and tests
tools/          repository checks and release packaging
catalog/        store entry templates (one per standalone addon)
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
./tools/package.ps1 -Tag v0.6.3
```

`npm test` checks Lua 5.1 syntax for all modules, TOC resources and Stats/Combat Text/Suite scenarios. The builder's full recommendation tests require a locally installed native game catalogue, supplied explicitly to `test:game`; CI does not redistribute it. Mocked UI tests do not replace in-game visual checks.

Packaging writes eight independently installable, deterministic ZIPs, an ASR-All bundle and `SHA256SUMS` to ignored `release/`. The tag is the shared distribution release version; module TOC/runtime versions are aligned to 0.6.3. The Advisor ZIP and bundle also include the settings-only legacy bridge. The store displays the pinned release tag.

See [the release process](docs/RELEASING.md). Original ASR implementation code is licensed under **GPL-3.0-only**. Copyright (C) 2026 AlexEnotov. See [LICENSE](LICENSE) for the full terms and [resource notes](docs/RESOURCES.md) for game data and third-party material, whose rights remain with their respective owners.

Fresh installations default to English in all eight addons. Saved language preferences are preserved on update.

## Validation notes

**ASR Party** includes classic and compact previews and automated party-state
scenarios. Live co-op coverage remains limited.

**ASR Chat** has been checked locally for native tabs, input, resizing and fading.
Its tests model the client's recursive alpha writes and focus compatibility.

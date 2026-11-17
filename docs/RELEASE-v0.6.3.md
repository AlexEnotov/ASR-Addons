# ASR Addons v0.6.3

## Built-in languages across all eight addons

- Added German, French, Spanish, Brazilian Portuguese, Italian, Polish, Turkish,
  Japanese, Simplified Chinese and Korean alongside English and Russian.
- Translated settings, tooltips, stat explanations, recommendation reasons,
  generated ability descriptions and diagnostic labels.
- Change the shared language through Suite, or choose a language in standalone
  addon settings. Chat and Party also accept native language codes in their chat
  commands, for example `/asrchat deDE` and `/asrparty koKR`.
- Japanese, Chinese and Korean use fonts already included with the game.
- Missing translations fall back to English. Player-written build names/notes
  and descriptions received from the game retain their original language.

## Fixes and improvements

- **ASR Chat:** fixed Russian settings appearing when English was selected.
  Repeated translation registrations no longer erase the English dictionary.
- **ASR Advisor:** fixed untranslated damage-school fragments in generated
  descriptions, localized wildcard and co-op labels, and preserved tooltip
  fonts when switching languages.
- **ASR Stats:** numeric values turn gold when they reach a live game-provided
  stat cap. Values return to their normal color when below the cap; unknown
  caps do not trigger highlighting.
- Fixed invalid Stats headings, improved localized party class names and
  case-insensitive language commands, and kept language choices compatible with
  existing English/Russian preferences.

## Installation

Eight independent addon ZIPs and one complete **ASR-All-v0.6.3.zip** pack are
available below. Suite remains optional. Extract the chosen addon folders into
`Interface/AddOns`, replacing the previous files, then restart or reload the
game. Existing settings and builds are preserved.

Checks cover all language dictionaries, English fallback, dynamic descriptions,
standalone/Suite behavior and release archive contents. Translations may still
benefit from native-speaker feedback; please include the addon, language and a
screenshot when reporting wording or layout issues.

GitHub downloads are available immediately. The in-game catalogue follows its
normal maintainer/pin update process.

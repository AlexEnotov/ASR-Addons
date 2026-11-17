# Built-in localizations

Each standalone module ships its own `Language.lua` and generated
`Translations.lua`. No language addon or Suite dependency is required.
`Language.lua` is a shared versioned registry: the first installed module loads
it, and subsequent modules merge their dictionaries without erasing earlier
entries. Existing `en`/`ru` preferences remain valid; native `enUS`/`ruRU` aliases
are normalized when read.

The language list matches the game's native `Locale.lua`: enUS, ruRU, deDE,
frFR, esES, ptBR, itIT, plPL, trTR, jaJP, zhCN and koKR. English remains the
fresh-install default. The registry first uses a nonempty selected-language
entry and then the supplied or registered English text. Russian source keys
remain the existing Russian translations.

`ui.tsv` contains authored interface translations. `catalog.json` maps existing
source keys to their English fallback. `native.json` contains only the relevant
terminology extracted from the installed game's locale/content tables, and
`name-keys.json` restricts its use to the supported class/catalog/world names.
These data do not add mechanics or infer missing class-amulet bindings.
The current UI catalog, including detailed effect templates and diagnostics,
has translations for all ten added languages. English fallback remains for
future missing entries and game content not covered by the native dictionaries.
Raw game descriptions and player-authored builds/notes are not rewritten.
Generated dictionaries also include English aliases for dynamic source keys
whose supplied English fallback matches a translated phrase. Heading components
are required during generation, and invalid JavaScript sentinel text is rejected.

Generate with `node tools/build-locales.cjs`. Use `--check` to verify that the
shipped copies match the inputs. The generator verifies language counts,
duplicate phrases and printf placeholders. TSV rows may use `\n` for line breaks
and `\x20` for a significant trailing space in a translated prefix.
`npm test` verifies generated copies, coverage of direct T/L/say source calls,
complete UI dictionaries, formatting of translated descriptions, fallback,
registry load order, CJK fonts and the existing module behavior.
Runtime audits exercise each module's settings in all added languages, and the
game-backed builder test also renders spell shapes, damage schools and item
effects to detect untranslated dynamic fragments.
Check translations and long labels in the
running game before release; automatic tests do not establish translation quality.

Japanese, Simplified Chinese and Korean use the native bundled KOSUGI,
ZCOOLKUAILE and NANUMGOTHIC fonts. The addon changes its own frames, and the
native chat fonts it already manages, without changing global game fonts or
the game's language. Restoring a Latin language restores the original font.

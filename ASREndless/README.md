# ASR Endless

Standalone endless-mode boss tracker for Azeroth Survivors Reborn. Replaces the
native completed-map objectives only during Endless, and restores them when
disabled or outside that mode. No ASR Suite dependency.

Shows repeating boss rounds, living/defeated bosses, the next boss countdown,
native-style progress bar, map/difficulty, level, run time and enemies slain.
The countdown uses the game's reported time; unknown map names are preserved.

## Controls

- `/asrendless` — open standalone settings.
- `/asrendless on` / `/asrendless off` — enable/disable the replacement.
- `/asrendless unlock` / `/asrendless lock` — allow/prevent dragging.
- `/asrendless reset` — reset the tracker position.
- `/asrendless en` / `/asrendless ru` — change language.

Fresh installations use English. Settings and run progress survive `/reload`.
With Suite installed, use its Endless page, shared language and interface editor;
the shared panel lock takes precedence over the standalone movement lock.

## Upgrade from the embedded tracker

Install ASREndless alongside ASRSuite 0.6.1 or newer. The first joint load copies
the old Suite visibility, position and run progress into ASREndlessDB, then
removes the old runtime fields. The transfer runs once; subsequent standalone
edits are preserved. Suite alone no longer includes an Endless tracker.

Old Suite settings export codes remain supported. New profiles store Endless
preferences separately and exclude live boss state/HUD ownership.

The addon uses the game's native AzerothSurvivors and AzerothSurvivorsAPI addons.
It neither spawns bosses nor automates gameplay. Solo captures and automated
scenarios cover the existing tracker; the standalone extraction is additionally
tested for independent loading, controls, migration and Suite integration.

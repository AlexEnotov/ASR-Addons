# Endless tracker

ASR Suite 0.5.1 includes a tracker that replaces the native run tracker only in
endless mode. Enable or disable it in **ASR Suite → Endless**. Disabling it or
leaving endless mode restores the previous native clock/tracker visibility.
The native boss health bars are not replaced. The display uses the suite language
and has no panel background or border. Move it in interface edit mode; reset its
position in Endless. By default its bottom edge follows the native tracker's bottom
edge to leave the damage meter clear.

The tracker shows the map with difficulty (including named Heroic tiers), hero
level, run clock, total enemies killed, bosses killed in endless mode, current
round, the complete map boss list and the next spawn countdown. Boss rows are
single lines with next/alive/defeated markers. Defeating the final boss of a round
prepares the next round and resets the defeated markers. Round numbers appear only
in the header. Labels are fitted to their available width without wrapping.
The native `AZS_BuildBossChargeBar` supplies the progress bar's appearance; its fill
is driven by the API countdown. A plain status bar is a fallback without that UI.

## API and tracking

Verified with a live Elwynn run on 2026-11-14: first endless boss after 60 run
seconds, subsequent spawns every 120 run seconds, including the next map-order
cycle. These intervals are observations, **not constants used by the addon**.

- `AZS_RUN.endless` selects the mode.
- `AZS_RUN.nbin`, with `nb` as compatibility fallback, supplies the countdown.
- `AZS_UNITS` supplies living bosses and health.
- `AZS_SCHEDULE` supplies boss order and names. Its `at` values remain the original
  map schedule and must not be used for endless timing. `dead` also means a boss
  has not yet reappeared; it does not mean that boss was killed this endless round.
- `AZS_RUN.bk` (fallback `bo`) counts total boss kills. Subtract the map boss count
  for endless kills. Kills plus living bosses determine spawn progression, so a
  boss killed between polls still advances the queue and killing an older living
  boss does not advance it twice.

`ASRSuiteDB.endlessState` preserves bounded tracking state across reloads and
resets for a different run or a reset run clock. Installing midway reconstructs
progress from counters. Future boss names and round numbers are inferred from
the map order; they are not an explicit future endless schedule from the API.
When the schedule or HUD switch API is unavailable, the native tracker remains.
When first installed during an interval, bar fill starts from the first observed
countdown; the displayed remaining time is still the game's actual countdown.

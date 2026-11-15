# ASR Chat

Standalone appearance and layout controls for Azeroth Survivors Reborn's native
chat. Suite is optional.

- Move by the ASR header and resize with the lower-right corner. Suite adds its
  shared interface editing, docking and movement lock.
- The custom toolbar replaces native chat controls, stages channel commands,
  opens the native friends window with the actual online count, and scrolls messages.
- Wide layouts show connected tabs beside the optional title; narrow layouts use
  a separate tab-picker button.
- Native message frames, channel tabs, links and command input keep their usual
  behavior. Detached native chat windows are left alone.
- Adjust width, height, scale, font size, line spacing, background and stone/simple/borderless
  frame. Settings include a sample of the selected appearance.
- Configure fading, message lifetime, input above/below, header and native scroll
  buttons. The native input sits in a styled field inside the panel.
- Separate always-visible options control the interface and input field. Inactive
  controls fade smoothly; messages retain their own configured display duration.
  Message geometry stays fixed when controls disappear.
- Copy the current native tab's latest 300 messages. If native history getters
  are unavailable, a bounded memory-only buffer collects messages since enabling.
  Chat history is never stored in SavedVariables or Suite settings exports.
- Disabling restores captured native anchors, parents, scale, fonts, fading,
  scripts, tabs and decoration. An active SurvivorUI chat panel is suspended while
  ASR Chat owns the chat, then restored on disable.

## Commands

`/asrchat` opens settings; `on`, `off`, `lock`, `unlock`, `reset`, `copy`, `en`,
and `ru` are available as subcommands. `/asrchat off` restores the native layout.

The width defaults to two ASR layout units (396). Width and height can also be
resized manually. The scale step is 1%. Settings and position persist across
reloads and are included in Suite profile transfer. Language changes immediately
with Suite, or independently when Suite is absent.

Only built-in game textures and fonts are used. The addon does not send chat
messages automatically, change message subscriptions, or replace chat commands.

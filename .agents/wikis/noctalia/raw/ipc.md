# IPC & Keybinds for Noctalia v5+

Source: <https://docs.noctalia.dev/noctalia/ipc/>

<!-- Verbatim upstream page: long code lines and site anchors are kept as-is. -->
<!-- markdownlint-disable MD001 MD013 MD025 MD051 -->

Retrieved: 2026-10-02

IPC commands let you control Noctalia from a terminal, a compositor keybind, a
script, or a hook.

All commands use this shape:

```text
noctalia msg <command>
```

For example:

```text
noctalia msg dock-toggle
noctalia msg volume-up
noctalia msg panel-toggle launcher
noctalia msg screenshot-region
```

Note

These pages list commands exactly as you run them. The same `noctalia msg ...`
form is used in terminals, compositor keybinds, hooks, hot-corner commands, and
idle command fields.

## Command lists

[Shell](/noctalia/ipc/shell/)Status, config reload, settings, window switcher,
and session actions.

[Surfaces](/noctalia/ipc/surfaces/)Bar, panels, dock, desktop widgets, and
lockscreen widgets.

[Media & UI](/noctalia/ipc/media-and-ui/)Notifications, clipboard, media
controls, wallpaper, theme, and screenshots.

[Plugins](/noctalia/ipc/plugins/)Plugin event dispatch and plugin/source
management.

[System Controls](/noctalia/ipc/system-controls/)Volume, microphone, brightness,
night light, Wi-Fi, Bluetooth, caffeine, power profile, and display power.

## Compositor keybinds

A compositor keybind only needs to launch a Noctalia command. The command part
is compositor-agnostic:

```text
noctalia msg panel-toggle launcher
noctalia msg panel-toggle control-center
noctalia msg settings-toggle
noctalia msg volume-up
```

Use your compositor’s normal `exec`, `spawn`, or command-binding syntax to run
those commands.

[Niri](/noctalia/compositor-settings/niri/)Niri bind syntax, overview
integration, wallpaper backdrop, and blur.

[Hyprland](/noctalia/compositor-settings/hyprland/)Hyprland Lua bind syntax,
persistent workspaces, and blur.

[Sway / Scroll](/noctalia/compositor-settings/sway-scroll/)Sway-style bind
syntax for Noctalia launcher, panels, settings, audio, and brightness.

[Mango](/noctalia/compositor-settings/mango/)Mango effects and bind syntax for
Noctalia launcher, panels, settings, audio, and brightness.

## Discovering commands

Not sure what else you can control? You can see all IPC commands via this
terminal command:

```text
noctalia msg --help
```

## Using IPC in config

Config command fields run through the shell. Use the canonical IPC CLI when a
command needs to call Noctalia, and compose it with other shell commands when
needed:

```text
[idle.behavior.custom]
timeout = 660
action = "command"
command = "noctalia msg session lock && notify-send 'Session locked'"


[hooks]
started = "noctalia msg panel-toggle launcher"
```

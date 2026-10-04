# Compositor integration

What a compositor must provide for noctalia, and how this repo wires it into
Hyprland without tying the noctalia aspect to one window manager.

## Pattern

The noctalia aspect writes its Hyprland pieces under
`lib.mkIf config.wayland.windowManager.hyprland.enable`. A future window
manager adds its own guarded block next to it. Hyprland's own keymap stays in
the Hyprland aspect; only the shell's binds live with the shell.

## Pieces, from the [Hyprland page](../raw/compositor-settings-hyprland.md)

- Autostart: an `hl.on("hyprland.start", ...)` hook. This repo runs it as
  `uwsm app -- noctalia`, so noctalia gets its own systemd scope under UWSM.
  The HM `systemd.enable` user unit is deliberately not used.
- Layer rule: `^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$`
  gets blur, `ignore_alpha = 0.5` and `no_anim`, so Hyprland's layer
  animations do not fight noctalia's. v1's `noctalia-background-*` namespace
  is from v4. `noctalia:regionSelector` gets `no_anim` too.
- Window rule: the settings window (`dev.noctalia.Noctalia`) floats at
  1080x920.
- Keybinds call `noctalia msg ...`. ALT+Tab uses `window-switcher hold`.

## UWSM

- `shell.launch_apps_as_systemd_services = true` makes apps launched from the
  launcher run as transient user services. That only works when noctalia runs
  under the systemd user manager, which `uwsm app` provides. See
  [shell configuration](../raw/configuration-shell.md) and the NixOS note in
  [getting started on NixOS](../raw/getting-started-nixos.md).
- The session menu's logout row runs `uwsm stop`, so the session's units stop
  cleanly. Declaring any `[[shell.session.actions]]` row replaces the whole
  default list, so all five rows are restated.

## Idle

Idle is noctalia's (`[idle.behavior.*]`, see [idle](../raw/services-idle.md)).
Actions are `lock`, `screen_off`, `suspend`, `lock_and_suspend` or
`command`. No hypridle or hyprlock is needed.

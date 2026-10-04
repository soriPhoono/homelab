# Noctalia

Noctalia is a Wayland desktop shell: bar, launcher, control center,
notifications, OSD, lock screen, idle handling, wallpaper and screenshots in one
process.

## Versions

- v5 is a C++ rewrite that no longer runs on Quickshell. v4 was a Quickshell
  (QML) shell. Memory efficiency is the reason this repo requires v5.
- nixpkgs ships v5 as `pkgs.noctalia` (5.1.0 at the time of writing). The
  older `noctalia-shell` attribute and the Stylix `noctalia-shell` target are
  the deprecated v4 path.

## In this repo

- Package and config: the Home Manager `programs.noctalia` module, from nixpkgs
  rather than a flake input. Store source:
  `/nix/store/da7apr6rx9mpa0ljpircmwwsxnmrjb43-source/modules/programs/noctalia.nix`.
  Options are `enable`, `package`, `settings` (TOML), `customPalettes`
  (JSON), `checkConfig` and `systemd.enable`.
- Aspect: `den.aspects.sphoono.desktop.wm.shells.noctalia`. It is Home Manager
  only; there is no host aspect, because the system services noctalia uses are
  provided by other aspects.
- Greeter: `den.aspects.desktop.greeters.noctalia`, a NixOS display manager
  (`services.displayManager.noctalia-greeter`).

## CLI

`noctalia msg <command>` is the IPC entry point used by keybinds. Notable
commands: `panel-toggle <id>`, `session <lock|logout|...>`,
`window-switcher hold`, `screenshot-region`, `screenshot-fullscreen <mode>`,
`screenshot-annotate`, `keyboard-backlight-up/down`, `power-cycle`,
`wifi-status` and `bluetooth-status` (print `on`/`off`). There is no airplane
mode command. See [IPC](../raw/ipc.md) and
[system controls](../raw/ipc-system-controls.md).

`noctalia config validate <file>` checks one TOML file. Errors exit 1;
unknown keys are only warnings. `noctalia config export [full]` prints the
merged config. See [configuration](../raw/configuration.md).

## Related

- [Settings layering](../concepts/settings-layering.md)
- [Stylix palette mapping](../concepts/stylix-palette-mapping.md)
- [Compositor integration](../concepts/compositor-integration.md)

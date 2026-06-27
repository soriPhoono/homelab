# Home configurations

## General structure

Home manager top-level configs are organized as follows.

### Currently implemented

- `username` — global config. Passed to all home-manager targets for that user.
- `username@hostname` — host-specific config.
- `username@system_name`
  - If the host is declared as a NixOS system in the repo, the config is pulled into that system build.
  - If the host is not declared as a system, the config is exported as a standalone home-manager environment.

### WIP

- `username@droid` — nix-on-droid config, pulled in automatically.
- `username@wsl` — WSL config, pulled in automatically by the WSL module.

## Design conventions

Config should be modular and never duplicated. If pure config (not package declarations, which are system-specific) appears in multiple places, it belongs in the core user home environment.

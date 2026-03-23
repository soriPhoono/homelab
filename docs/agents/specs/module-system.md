# Module System Spec

This repository uses a modular, composable Nix module system that simplifies complex configurations into manageable pieces.

## Design Philosophy

- **Composable**: Modules should define settings and services but only activate them when `enable = true;`.
- **Opinionated Defaults**: Modules should provide sane defaults for the project but allow for overrides.
- **Auto-Discovery**: Modules in `nix/modules/nixos/` and `nix/modules/home/` are automatically exported by the flake and imported into configurations.

## Module Structure

Modules are typically organized as:

```nix
{ lib, pkgs, config, ... }:
let
  cfg = config.my-module;
in {
  options.my-module = {
    enable = lib.mkEnableOption "My Module";
    # ... additional options
  };

  config = lib.mkIf cfg.enable {
    # ... system configuration or user packages
  };
}
```

## Hierarchy

### NixOS Modules (`nix/modules/nixos/`)

- `core/`: Fundamental settings for all machines (boot, users, nixconf, secrets).
- `desktop/`: Configuration for graphical environments, fonts, and display managers.
- `hosting/`: Settings for servers, Docker, K3s, and virtualization.

### Home Manager Modules (`nix/modules/home/`)

- `core/`: Common user-level settings (Git, SSH, Fish shell).
- `userapps/`: Individual applications like Firefox, Discord, and editors.
- `development/`: Language runtimes, LSP servers, and specialized dev tools.

## Discovery and Export

The flake uses `lib.discover` to find and export all modules within `nix/modules/`. This means adding a new module file automatically makes its options available across the entire flake.

# Homes Directory

This directory contains Home Manager configurations for users. These can be standalone configurations or integrated into NixOS systems, but this folder specifically targets **standalone** or **externally buildable** home configurations.

## Adding a New Home

1. Create a new directory. Valid naming patterns:
   - `username` (Generic home for that user)
   - `username@hostname` (Host-specific home for that user)
1. Create a `default.nix` file.
1. Create a `meta.json` file.

### `meta.json` Format

```json
{
  "system": "x86_64-linux"
}
```

## Discovery

### Standalone Home Configurations (`homeConfigurations`)

The `flake.nix` automatically discovers user configurations for standalone Home Manager installation.
It combines:

1. `homes/<user>` (Base configuration)
1. `homes/<user>@global` (Supplementary configuration for non-NixOS systems, if present)

These are exported as `homeConfigurations.<user>`.

### Nix-on-Droid Configurations

For Nix-on-Droid systems, the `modules/droid/users.nix` module handles user configuration.
It automatically imports:

1. `homes/<user>` (Base configuration)
1. `homes/<user>@droid` (Supplementary configuration for Droid environment, if present)

### System-Bound Homes

Configurations named `user@hostname` (e.g., `soriphoono@zephyrus`) are **system-bound supplementary configurations**.
These are **not** standalone; they are imported **in addition to** the base `homes/<user>` configuration by the NixOS system's `core.users` module.
This allows `homes/soriphoono` to provide the universal base (shell, common apps), while `homes/soriphoono@zephyrus` provides machine-specific overrides (monitors, keybindings, specific hardware settings).
These are NOT exported as `homeConfigurations` in the flake.

## Future Plans: System Manager

We plan to integrate **System Manager** for non-NixOS Linux distributions (e.g., Debian, Ubuntu servers).
These configurations will reside in `environments/` and will function similarly to Droid or NixOS systems, providing system-level configuration management without full OS replacement.
Homes for these systems will likely follow a similar pattern: `user` + `user@<environment-name>`. The `user` directory will contain the base configuration, and `user@<environment-name>` will contain the environment-specific configuration. Like system services and etc entries.

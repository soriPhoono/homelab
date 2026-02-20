# Testing & Verification

This document outlines the testing strategies and known limitations within the homelab flake.

## CI/CD Pipeline & Automated Checks

The primary mechanism for verification is `nix flake check`. This command runs a series of checks defined in `flake.nix`, including:

- Unit tests for custom library functions.
- Structural tests for configuration directories (`tests/structure.nix`).
- Nix-on-Droid environment integrity checks (`tests/droid-env.nix`).
- Build verification for Home Manager configurations (`tests/home-builds.nix`).
- Build verification for NixOS configurations (`tests/nixos-builds.nix`).

All pure checks run together under the standard `nix flake check` invocation.

### Nix-on-Droid Limitations

**Important:** While the Nix-on-Droid *environment* checks are included in the standard check suite, fully *building* Nix-on-Droid configurations requires impure evaluation.

**Reason:** `nix-on-droid` relies on `proot` and hardcoded store paths, which necessitates usage of `builtins.storePath`. This builtin is restricted in "pure" evaluation mode. Attempting to build `nix-on-droid` configurations in a pure context results in:

> `error: 'builtins.storePath' is not allowed in pure evaluation mode`

### Building Nix-on-Droid Configurations

To fully build a Nix-on-Droid configuration, pass `--impure`:

```bash
nix build .#nixOnDroidConfigurations.default.activationPackage --impure
```

# Testing & Verification

This document outlines the testing strategies and known limitations within the homelab flake.

## CI/CD Pipeline & Automated Checks

The primary mechanism for verification is `nix flake check`. This command runs a series of checks defined in `flake.nix`, including:

- Unit tests for custom library functions.
- Structural tests for configuration directories.
- Build verification for NixOS and Home Manager configurations.

### Nix-on-Droid Limitations

**Important:** Nix-on-Droid configurations are currently **excluded** from standard `nix flake check` runs.

**Reason:** `nix-on-droid` relies on `proot` and hardcoded store paths, which necessitates usage of `builtins.storePath`. This builtin is restricted in "pure" evaluation mode, which `nix flake check` enforces strict adherence to. Attempting to check `nix-on-droid` configurations in a pure context results in the error:

> `error: 'builtins.storePath' is not allowed in pure evaluation mode`

### Testing Nix-on-Droid

To verify Nix-on-Droid configurations, you must run builds manually with the `--impure` flag. This bypasses the purity restrictions and allows the configuration to build.

**Command:**

```bash
nix build .#droid-checks --impure
```

**Example:**

```bash
nix build .#droid-checks --impure
```

## Future Improvements

We aim to integrate `nix-on-droid` checks into the automated pipeline. Possible solutions include:

- Running `nix flake check` with `--impure` in CI (though this relaxes checks for everything).
- Mocking the `nix-on-droid` modules to avoid `builtins.storePath` during check time.
- Isolating `nix-on-droid` checks into a separate impure check suite.

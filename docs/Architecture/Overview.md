# Architecture & Logic

## 1. The Discovery Mechanism

The `flake.nix` file implements custom builder functions that enable automatic ingestion of modules, systems, homes, and droids without manually updating the `outputs` set.

### How it works

1. **Read Dir**: `builtins.readDir` scans target directories (`systems/`, `homes/`, `droids/`).
1. **Filter**: It looks for directories containing a `default.nix` or standalone `.nix` files.
1. **Meta Injection**: It reads `meta.json` from the directory to determine the architecture (`system`) of the target.
1. **MapAttrs**: It maps these discovered paths to `nixosSystem`, `homeManagerConfiguration`, or `nixOnDroidConfiguration` builders.

### Home Directory Conventions

The `homes/` directory supports three naming patterns, each with distinct semantics:

| Pattern | Purpose | Exported as `homeConfigurations`? |
| :--- | :--- | :---: |
| `homes/user` | Base configuration — universal across all machines | ✅ (combined with `@global` if present) |
| `homes/user@global` | Supplementary config for non-NixOS / standalone installs | ✅ (merged into `homeConfigurations.user`) |
| `homes/user@hostname` | Machine-specific overrides — imported by the NixOS system | ❌ (system-bound only) |

This allows a single `homeConfigurations.user` export that is portable, while still enabling per-machine customization through the NixOS system's own `core.users` module.

## 2. Overlays & Extensions

Overlays are used extensively to modify package behavior.

- **Location**: `overlays/default.nix` (and others in that dir).
- **Usage**: They are applied globally to both NixOS systems and Home Manager configurations to ensure package consistency across the entire fortress.

Extra overlays are injected from flake inputs:

- `nur.overlays.default` — NUR (Nix User Repository).
- `mcps.overlays.default` — MCP server tools.

## 3. Template System

Templates provide scaffolding for new components.

- **Location**: `templates/`
- **Usage**: `nix flake init -t .#<template-name>`
- **Discovery**: Similar to systems, templates are auto-discovered based on directory structure (each template directory must contain a `flake.nix` with a `description`).

## 4. Nix-on-Droid

Android device configurations live in `droids/`.

- **Builder**: `mkDroid` in `flake.nix` — wraps `nix-on-droid.lib.nixOnDroidConfiguration`.
- **Discovery**: Same `lib.discover` helper as systems; each subdirectory of `droids/` with a `default.nix` is auto-discovered.
- **Home Manager**: Droid configs embed Home Manager via `droidModules`. The `modules/droid/` module set (distinct from `modules/nixos/`) handles Android-specific setup.

## 5. Environments (Planned)

`environments/` will hold System Manager configurations for non-NixOS Linux hosts (e.g., Debian/Ubuntu servers). These will provide system-level management without replacing the host OS kernel or bootloader.

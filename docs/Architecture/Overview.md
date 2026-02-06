# Architecture & Logic

## 1. The Discovery Mechanism

The `flake.nix` file implements a `discover` function that allows for automatic ingestion of modules, systems, and homes without manually updating the `outputs` set.

### How it works

1. **Read Dir**: `builtins.readDir` scans target directories (`systems`, `homes`).
1. **Filter**: It looks for directories containing a `default.nix` or standalone `.nix` files.
1. **Meta Injection**: It reads `meta.json` from the directory to determine the architecture (`system`) of the target.
1. **MapAttrs**: It maps these discovered paths to `nixosSystem` or `homeManagerConfiguration` builders.

## 2. Overlays & Extensions

Overlays are used extensively to modify package behavior.

- **Location**: `overlays/default.nix` (and others in that dir).
- **Usage**: They are applied globally to both NixOS systems and Home Manager configurations to ensure package consistency across the entire fortress.

## 3. Template System

Templates provide scaffolding for new components.

- **Location**: `templates/`
- **Usage**: `nix flake init -t .#<template-name>`
- **Discovery**: Similar to systems, templates are auto-discovered based on directory structure.

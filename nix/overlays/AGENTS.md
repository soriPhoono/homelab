# Package Overlays

This directory contains Nix package overlays that modify or extend the global `pkgs` set. Overlays are auto-discovered and applied before any module evaluation, ensuring custom packages are available throughout the flake.

## Discovery Mechanism

The `nix/overlays/default.nix` applies the same `lib.homelab.core.discover` pattern used for modules:

```nix
lib.mapAttrs' (name: _: {
  name = lib.removeSuffix ".nix" name;
  value = import (./. + "/${name}") { inherit inputs lib; };
}) (
  lib.filterAttrs (
    name: type:
      (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
      || (type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
  ) (builtins.readDir ./.)
)
```

All `.nix` files and directories with `default.nix` are imported and exported as an attribute set. The resulting overlays are applied to `nixpkgs` in the `pkgsBatch` definition within `flake.nix`, alongside external overlays from NUR and nix-skills.

## Overlay Structure

Each overlay file receives `inputs` and `lib` as arguments and should return a function conforming to the standard Nix overlay signature:

```nix
{ inputs, lib, ... }:
final: prev: {
  # Package definitions or modifications
}
```

## Current Overlays

### run-application

Provides a `run-application` shell wrapper utility. This overlay injects a custom package into the global `pkgs` set, making it available as `pkgs.run-application` for use in module configurations.

## Adding a New Overlay

1. Create a `.nix` file or directory with `default.nix` in this directory
1. Export a function with signature `{ inputs, lib, ... } -> final -> prev -> { ... }`
1. The overlay is automatically discovered and applied — no manual registration required

**Naming convention:** The overlay's attribute name is derived from the filename with `.nix` removed. For example, `run-application.nix` becomes `pkgs.run-application`.

## Overlay Application Order

Overlays are applied in the following sequence (as defined in `flake.nix`):

1. Internal overlays from `nix/overlays/` (auto-discovered)
1. NUR overlay (`nur.overlays.default`)
1. nix-skills overlay (`nix-skills.overlays.default`)

The order determines precedence when multiple overlays define the same package attribute.

# Systems Directory

This directory contains the top-level NixOS configurations for all physical and virtual machines managed by this flake.

## Adding a New System

1. Create a new directory: `systems/<hostname>`
1. Create a `default.nix` file (listing modules/imports).
1. Create a `meta.json` file (optional, but recommended for architecture definition).

### `meta.json` Format

```json
{
  "system": "x86_64-linux"
}
```

## Discovery

The `flake.nix` automatically discovers any directory in `systems/` that contains a `default.nix` file and creates a `nixosConfiguration` for it with the same name as the directory.

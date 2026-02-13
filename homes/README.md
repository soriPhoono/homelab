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

The `flake.nix` automatically discovers these directories.

- If the directory is named `user`, it creates a home configuration named `user`.
- If the directory is named `user@host`, it creates a home configuration named `user@host`, and injects `hostName = "host"` into special args.

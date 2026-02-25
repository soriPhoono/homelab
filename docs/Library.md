# Discovery Library

The custom library ([lib/default.nix](../lib/default.nix)) is the engine that enables the modular and dynamic nature of this homelab.

## 🛠️ Key Functions

### `discover`

The `discover` function recursively scans a directory for `.nix` files and subdirectory `default.nix` entries. It automatically returns an attribute set mapping names to file paths, which is then passed to system and home builders.

- **Used by**: `flake.nix` to find all host and user configurations.

### `mkSystem`

A wrapper around `nixpkgs.lib.nixosSystem`.

- **Logic**: Automatically injects global modules (core/security/networking), system-specific metadata, and specialized hardware configurations.
- **Discovery**: Uses system names found in `systems/`.

### `mkHome`

A unified builder for standalone Home Manager configurations.

- **Logic**: Handles the injection of `userapps` vs `core` home modules. It also facilitates **Home Specialization** by merging global user profiles with system-specific overrides.

### `readMeta`

Parses `meta.json` files within module or system directories to provide descriptive information for automated documentation and CLI tools.

## 🧩 Templates

We provide a set of standardized templates in specific directories (e.g., `modules/hosting/blocks`) to simplify the creation of new Docker services or system profiles.

# Discovery Mechanism Spec

This repository uses a dynamic discovery mechanism to automatically identify and configure systems and user environments based on directory structure.

## `lib.discover` Function

Defined in `nix/lib/default.nix`, this function scans a directory and returns an attribute set mapping names to file paths. It detects:

- Standalone `.nix` files (excluding `default.nix`).
- Subdirectories containing a `default.nix` file.

## System Discovery (`nix/systems/`)

The root `flake.nix` calls `lib.discover ./nix/systems`. For each item found (e.g., `zephyrus`), it calls `mkSystem`, which:

1. Reads metadata from `meta.json` if available.
1. Sets the hostname to the name of the folder/file.
1. Imports common NixOS modules and the specific machine configuration.

## Home Manager Discovery (`nix/homes/`)

The discovery for Home Manager environments is more specialized:

- **Base Home**: A folder like `nix/homes/soriphoono/` represents a user's base configuration.
- **Host-Specific Home**: A folder like `nix/homes/soriphoono@zephyrus/` provides overrides for a specific machine.
- **Standalone Discovery**: The flake scans `nix/homes/` and automatically generates `homeConfigurations` for base homes and standalone host-specific homes (where the host is not managed as a NixOS system in this repo).

## Benefits

- **Minimal Boilerplate**: Adding a new machine or user is as simple as creating a new folder in the appropriate directory.
- **Maintainability**: No need to manually update `flake.nix` for every new configuration entry.

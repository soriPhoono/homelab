# Directory Structure Spec

This spec outlines the organization of the repository and where different types of configuration reside.

## Root Directory

- `flake.nix`: Main entry point for the entire project.
- `flake.lock`: Version-pinned inputs for reproducibility.
- `shell.nix`: Development shell definition (accessible via `nix develop`).
- `treefmt.nix`: Auto-formatting configuration for multiple languages.
- `pre-commit.nix`: Git hooks for linting and security checks.
- `secrets.nix`: Agenix secret definitions (used by `agenix-shell`).
- `.sops.yaml`: SOPS configuration for encrypted secrets.
- `docs/agents/`: Documentation specifically for AI agents.

## The `nix/` Folder

- `homes/`: User-specific Home Manager configurations.
  - `<user>/`: Base configuration for a user.
  - `<user>@<host>/`: Host-specific configuration for a user.
- `lib/`: Custom Nix helper functions (e.g., `lib.discover`).
- `modules/`: Reusable Nix modules.
  - `nixos/`: NixOS system-level modules (services, hardware, core settings).
  - `home/`: Home Manager user-level modules (shell, desktop apps, editors).
- `overlays/`: Custom Nixpkgs overlays to patch or add packages.
- `pkgs/`: Custom Nix package definitions and an installer project.
- `systems/`: NixOS machine-specific configurations (zephyrus, lg-laptop).
- `templates/`: Nix flake templates for bootstrapping new projects.

## Secret Storage

- `secrets/`: Folder for global or shared encrypted secrets (age/sops).
- `nix/homes/<user>/secrets.yaml`: User-specific encrypted secrets.
- `nix/systems/<host>/secrets.yaml`: Machine-specific encrypted secrets.

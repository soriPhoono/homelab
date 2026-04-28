# AGENTS.md

High-signal context for AI agents working in this Nix-based homelab repository ("The Data Fortress").

> [!TIP]
> For a detailed guide on agent skills, repository structure, and operational mandates, see [**`.agents/AGENTS.md`**](.agents/AGENTS.md).

## Important Commands & Workflows

- **Dev Shell is Mandatory:** Always run `direnv allow` or enter `nix develop`. This automatically evaluates `actions.nix` and regenerates `.github/workflows/`.
- **Do not edit `.github/workflows/*.yml` manually.** Edit `actions.nix`, then enter the dev shell to regenerate workflows.
- **Formatting:** Run `nix fmt`. Do not run individual formatters (it uses `treefmt` under the hood for Nix, YAML, and Markdown).
- **Validation:** Always run `nix flake check` before committing. Pre-commit hooks are also enabled in the dev shell.
- **Deployment:** Use `nh os switch .` (for NixOS) or `nh home switch .` (for standalone Home Manager).

## Architecture & Discovery Quirks

This repo relies heavily on dynamic discovery (`nix/lib/discover`). You rarely need to manually add files to an `imports` list.

- **Modules:** Any directory in `nix/modules/nixos/` or `nix/modules/home/` with a `default.nix` (or any standalone `.nix` file) is automatically imported.
- **Custom Packages:** Files or directories in `nix/pkgs/` are automatically exported as flake `packages`.
- **NixOS Systems:** Directories in `nix/systems/<hostname>` with a `default.nix` are automatically exported as `nixosConfigurations`.
- **Home Manager Quirks (VERY IMPORTANT):**
  - **Standalone Homes:** Directories like `nix/homes/user` or `nix/homes/user@hostname` (where `hostname` does **not** exist in `nix/systems/`) are exported as standalone `homeConfigurations`.
  - **System-integrated Homes:** Directories like `nix/homes/user@hostname` (where `hostname` **exists** in `nix/systems/`) are **NOT** standalone. They are automatically imported by the NixOS configuration via the `core.users` module (`nix/modules/nixos/core/users.nix`).
  - When adding a user to a NixOS system, add them to `core.users` in the system config, and create the corresponding `nix/homes/user` and/or `nix/homes/user@hostname` folders. The system will auto-import them.

## Hardware & Disk

- **Disko:** Declarative disk partitioning is defined in `nix/systems/<hostname>/disko.nix`.
- **Hardware constraints:** We use `nixos-facter` for hardware support. To add a new system, run `nixos-facter > facter.json` to generate the facts, then set `reportPath = ./facter.json;` in the system's `default.nix`.

## Secrets

- **System/User Secrets:** Managed via `sops-nix`. Keys are typically host SSH keys. Encrypted files must match the rules in `.sops.yaml`.
- **Dev Shell Secrets:** Managed via `agenix` and `agenix-shell` (configured in `secrets.nix`). Decrypted automatically in the `nix develop` shell if the required identity key is present.

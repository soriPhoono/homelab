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

## Cursor Cloud specific instructions

This is a Nix flake-based infrastructure-as-code repository. There is no traditional application to "run" — validation means the flake evaluates and builds correctly.

### Environment startup

The update script handles installing Nix (Determinate installer) and direnv if not already present, starting `nix-daemon`, and sourcing the Nix profile. After the update script completes, the dev shell is ready via `nix develop` or `direnv allow`.

### Key commands

See the "Important Commands & Workflows" section above. The essential commands are:

- `nix develop` — enter the dev shell (installs pre-commit hooks, provides `alejandra`, `nixd`, `sops`, `kubectl`, etc.)
- `nix fmt` — format all Nix, YAML, and Markdown files via treefmt
- `nix flake check` — run all validation checks (treefmt + pre-commit)
- `nix eval .#nixosConfigurations --apply builtins.attrNames` — list NixOS hosts
- `nix eval .#homeConfigurations --apply builtins.attrNames` — list standalone Home Manager configs
- `nix build .#homeConfigurations.<name>.activationPackage --dry-run` — dry-run build a home config
- `nix eval .#nixosConfigurations.<host>.config.networking.hostName` — evaluate a NixOS config

### Gotchas

- The `nix-daemon` must be running for multi-user Nix operations. The update script starts it automatically, but if builds fail with "cannot connect to socket", run `nix-daemon &>/dev/null &`.
- The `[agenix] WARNING: no readable identities found!` warning in the dev shell is expected — the cloud VM has no SSH keys for decrypting secrets. This does not block evaluation or builds.
- `nix fmt` may reformat YAML files in `k3s/`. If your task does not involve those files, revert formatting-only changes with `git checkout -- k3s/`.
- Warnings about `eval-cores` and `lazy-trees` unknown settings are harmless and can be ignored.
- Current configs: NixOS hosts are `zephyrus` and `lg-laptop`; standalone Home Manager configs are `sphoono` and `spookyskelly`.

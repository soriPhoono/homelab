# Home Manager Core Modules

The `modules/home/core` directory contains the base user environment configuration.

## Structure

- `default.nix`: Main entry point.
- `shells/`: Shell configuration (Bash, Zsh, Fish, Nushell).

## Modules

### Root Files

- `git.nix`: Git configuration (identity, aliases, extra config).
- `ssh.nix`: SSH client configuration (keys, hosts).
- `secrets.nix`: User-level secret management (sops/agenix).
- `gitops.nix`: User-level GitOps configuration.

### `shells`

- **Purpose**: managing command-line environments.
- **Files**:
  - `fish.nix`: Fish shell configuration.
  - `starship.nix`: Starship prompt configuration.
  - `fastfetch.nix`: Fastfetch system information tool.

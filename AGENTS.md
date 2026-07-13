# AGENTS.md

## Project Overview

NixOS homelab configuration flake managing 4 machines (ares, zephyrus, lg-laptop, testbench) across 2 users (sphoono, spookyskelly). Built with flakes, home-manager (NixOS-integrated), sops-nix secrets, and a modular auto-discovery pattern.

**Key technologies:** NixOS, Home Manager, flakes, sops-nix, disko, treefmt, git-hooks.nix, Stylix, Hyprland/KDE/COSMIC, k0s, Docker, Traefik, Tailscale, AI coding agents (opencode, pi, hermes-agent, github-copilot).

## Architecture

### Flake structure

The flake (`flake.nix`) uses `flake-parts` with these builder functions:

| Builder | Purpose |
|---------|---------|
| `mkSystem` | Builds a NixOS configuration from `nix/systems/<hostname>/` |
| `mkHome` | Builds a Home Manager configuration from `nix/homes/<user>/` or `nix/homes/<user>@<hostname>/` |

### Module auto-discovery

Modules in `nix/modules/nixos/` and `nix/modules/home/` are auto-imported via `lib.homelab.core.discover`. Dropping a `.nix` file (or directory with `default.nix`) into the tree is enough to register it — no manual `imports` edits.

### NixOS module groups

| Group | Path | Purpose |
|-------|------|---------|
| `core` | `nix/modules/nixos/core/` | Boot, hardware, networking, users, secrets, security |
| `desktop` | `nix/modules/nixos/desktop/` | DEs (Hyprland, KDE, COSMIC), services, gaming |
| `hosting` | `nix/modules/nixos/hosting/` | Media stack, Docker/k0s, Traefik proxy |
| `themes` | `nix/modules/nixos/themes/` | Stylix with base16 scheme support |

### Home Manager module groups

| Group | Path | Purpose |
|-------|------|---------|
| `core` | `nix/modules/home/core/` | Shells, git, SSH, secrets, email |
| `desktop` | `nix/modules/home/desktop/` | Window managers (Hyprland), Wayland env |
| `apps` | `nix/modules/home/apps/` | Browsers, editors, agents, media, office |

### Home config layering

```
nix/homes/<user>/default.nix              # Base config (shared across all hosts)
nix/homes/<user>@<hostname>/default.nix   # Host-specific overrides
```

Both layers are merged. Host-specific configs for NixOS-managed hosts are consumed by the system build (not exported standalone).

### Package overlays

Custom packages are defined in `nix/overlays/` and auto-discovered by `overlays/default.nix`. External overlays: `nur.overlays.default`, `nix-skills.overlays.default`.

### Systems

| Hostname | User(s) | Desktop | Purpose |
|----------|---------|---------|---------|
| ares | sphoono | Hyprland + SDDM | Workstation, gaming + VR |
| zephyrus | sphoono | Hyprland + ReGreet | Laptop, media server |
| lg-laptop | spookyskelly | KDE Plasma | Laptop |
| testbench | sphoono | Hyprland + SDDM | VM/testing |

## Setup Commands

```bash
# Enter dev shell (or use direnv)
nix develop

# Evaluate the full flake
nix flake check
nix flake check --all-systems
```

## Development Workflow

### Quick iteration (single system)

```bash
# Build a NixOS system
nix build .#nixosConfigurations.zephyrus.config.system.build.toplevel

# Build a home configuration
nix build .#homeConfigurations.sphoono.activationPackage

# Deploy (requires target machine)
nh os switch . -- --flake .#zephyrus
nh home switch . -- --flake .#sphoono@zephyrus
```

### Formatting

All formatting, linting, and secret scanning runs automatically via pre-commit hooks on `git commit`:

- `alejandra` (Nix formatter)
- `deadnix` (Nix dead code)
- `statix` (Nix linter)
- `actionlint` (GitHub Actions)
- `yamlfmt` (YAML)
- `mdformat` (Markdown)
- `gitleaks` (secret scanning)
- `nil` (Nix LSP linting)

To run manually: `nix fmt` (format all) or `treefmt` (if in dev shell).

### Full validation before push

```bash
nix flake check --all-systems
```

This evaluates all NixOS configurations, home configurations, dev shells, and flake checks (pre-commit, treefmt).

## Code Style Guidelines

### Nix conventions

- **Indentation**: 2 spaces
- **Encoding**: UTF-8, LF line endings
- **Format**: `alejandra` (auto-formats on save in VS Code, runs in pre-commit)
- **Pattern**: Modules use `{ lib, config, pkgs, ... }: with lib; { ... }` style
- **Options**: Always use `mkEnableOption`, `mkOption` with explicit `type`, `default`, `description`
- **Configs**: Use `mkIf`, `mkMerge`, `mkDefault`, `mkForce` for conditional composition
- **Guarding**: Guard cross-module dependencies with `options ? "depName"` checks
- **Descriptions**: Multiline strings, accurate descriptions, include `example` where useful

### File organization

```
nix/
  homes/       - Home Manager user configs
  lib.nix      - Custom library (homelab.core.discover, homelab.development, homelab.types)
  modules/
    nixos/     - System-level modules (core, desktop, hosting, themes)
    home/      - User-level modules (core, desktop, apps)
  overlays/    - Package overlays (auto-discovered)
  systems/     - Per-host NixOS configs (each with meta.json, disko.nix, secrets.yml, facter.json)
```

### Naming conventions

- **Options**: `camelCase.moduleName.optionName`
- **Types**: `types.attrOf`, `types.submodule`, `types.oneOf`, `types.coercedTo`
- **Secrets**: sops-nix with age keys, per-system and per-user `secrets.yml`

## AI Agent Configuration

This repo manages AI agent config for OpenCode, pi, Hermes Agent, and GitHub Copilot.

Each agent has its own set of options defined via `homelab.development.mkAgent` in `lib.nix`, including MCP servers, skills, subagents, commands, and context. Per-agent configs live at `nix/homes/<user>/configs/<agent>/`. There is no shared development layer — each agent is fully self-contained.

## Secrets Management

Secrets use **sops-nix** with age encryption. Key files:

- `.sops.yaml` — creation rules mapping paths to allowed age keys
- `nix/systems/<hostname>/secrets.yml` — system-level secrets
- `nix/homes/<user>/secrets.yml` — user-level secrets

To edit a secret file:

```bash
sops nix/systems/zephyrus/secrets.yml
```

## Build and Deployment

### CI/CD

GitHub Actions CI (auto-generated from `actions.nix`):

- Trigger: `pull_request` to `main`
- Gate: `nix flake check --all-systems` (evaluate)
- Builds: each NixOS system toplevel + standalone home activation packages
- Cache: Cachix (`homelab`), Magic Nix Cache
- Weekly: `update-flake-lock.yml` auto-creates PRs for dependency updates

### Disk provisioning

```bash
nix run .#writeDisks -- --flake .#<hostname>
nix run .#install -- --flake .#<hostname>
```

## Pull Request Guidelines

- Branch format: `<type>/<issue-number>-<name>` (e.g. `feat/42-add-sunshine-module`)
- Commit format: Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `style:`, `refactor:`)
- Pre-commit hooks must pass (nil, treefmt, gitleaks)
- Run `nix flake check --all-systems` before pushing
- One logical change per commit

## Testing

Testing is done via flake evaluation. There are no runtime test suites:

```bash
# Validate all configs evaluate
nix flake check --all-systems

# Validate a single system
nix flake check

# Build a specific config to catch eval + build errors
nix build .#nixosConfigurations.zephyrus.config.system.build.toplevel
```

## Troubleshooting

- **Stale flake lock**: `nix flake update` (or specific input: `nix flake update nixpkgs`)
- **Pre-commit failures**: Check `git diff` — treefmt may have auto-fixed formatting. Stage changes and retry.
- **sops decryption errors**: Ensure age key is available (`ssh-to-age` or `age-keygen`). Check `.sops.yaml` rules match the file path.
- **NixOS eval errors**: Use `nix eval --show-trace` for detailed trace. Check for missing `lib.mkIf` guards on cross-module option reads.
- **Home-manager + NixOS version mismatch**: The config uses `nixpkgs` unstable; HM warnings about version mismatch are expected and safe.

# Homelab

## The Data Fortress

This repository is a comprehensive, declarative infrastructure-as-code configuration for a personal homelab. It manages physical machines, user environments, and hosted services through NixOS, Home Manager, and Nix Flakes.

## Core Philosophy

1. **Declarative Everything**: Infrastructure state is defined exclusively in code. Manual mutations are ephemeral and will be overwritten on next deployment.
1. **Single Command Deployment**: System activation uses `nh os switch .` (NixOS) or `nh home switch .` (standalone Home Manager).
1. **Dynamic Discovery**: Module auto-import via `lib.homelab.core.discover` eliminates manual `imports` lists. Adding a file to the correct directory is sufficient.
1. **Validation-Driven Development**: `nix flake check` is the gate. Pre-commit hooks enforce formatting and evaluation before any commit.

## Architecture

### Flake Outputs

| Output | Description |
| :--- | :--- |
| `nixosConfigurations` | Auto-discovered from `nix/systems/`. Current: **zephyrus**, **lg-laptop** |
| `homeConfigurations` | Auto-discovered from `nix/homes/` for non-system-bound homes. Current: **sphoono**, **spookyskelly** |
| `nixosModules` | Auto-discovered from `nix/modules/nixos/`. Exported: `core`, `desktop`, `hosting`, `themes`, `default` |
| `homeModules` | Auto-discovered from `nix/modules/home/`. Exported: `core`, `userapps`, `default` |
| `devShells.default` | Development environment with Nix tooling, secret managers, and CI generators |
| `checks` | Pre-commit hooks and treefmt validation across supported architectures |
| `githubActions` | CI workflow definitions generated from `actions.nix` |

### Directory Structure

| Path | Role |
| :--- | :--- |
| `nix/homes/` | Home Manager configurations. Base (`user`), host-specific (`user@hostname`), or standalone (`user@home-name`) |
| `nix/lib.nix` | Custom library: `homelab.core.discover` (auto-import), `homelab.types.ai` (MCP server types) |
| `nix/modules/nixos/` | System-level modules: `core`, `desktop`, `hosting`, `themes` |
| `nix/modules/home/` | User-level modules: `core`, `userapps` (desktop, development, data-fortress, content-creation) |
| `nix/overlays/` | Auto-discovered package overlays modifying the global `pkgs` set |
| `nix/pkgs/` | Custom package declarations, auto-exported as flake `packages` |
| `nix/secrets/` | Encrypted secrets managed via `sops-nix` |
| `nix/systems/` | Top-level NixOS host configurations. Each directory is a machine |
| `nix/templates/` | Scaffolding for new systems, modules, and projects |

### Key Inputs

| Input | Purpose |
| :--- | :--- |
| `nixpkgs` (unstable) | Primary package set |
| `home-manager` | User environment management |
| `flake-parts` | Flake composition framework |
| `disko` | Declarative disk partitioning |
| `sops-nix` | Secret management (system and user) |
| `stylix` | System-wide theming via base16 |
| `hyprland` | Wayland compositor |
| `jovian` | SteamOS/Deck integration |
| `comin` | GitOps-based NixOS deployment |
| `nixos-facter-modules` | Hardware fact collection |
| `agenix-shell` | Dev shell secret decryption |
| `treefmt-nix` | Multi-language formatting |
| `git-hooks-nix` | Pre-commit hook management |
| `determinate` | Determinate Systems Nix enhancements |

### Dynamic Discovery

The `lib.homelab.core.discover` function performs filesystem introspection to automatically import modules:

- **NixOS Modules**: Any `.nix` file or directory with `default.nix` in `nix/modules/nixos/` is exported.
- **Home Manager Modules**: Same pattern applied to `nix/modules/home/`.
- **NixOS Systems**: Any directory in `nix/systems/` with a `default.nix` becomes a `nixosConfiguration`.
- **Overlays**: Any `.nix` file or directory in `nix/overlays/` is applied to the global `pkgs` set.
- **Home Configurations**: The flake evaluates `nix/homes/` with three naming patterns:
  - `user` — Base configuration layer, shared across all deployments
  - `user@home-name` — Standalone Home Manager export (hostname not in `nix/systems/`)
  - `user@hostname` — System-bound overrides (hostname exists in `nix/systems/`), imported by the NixOS config, not exported standalone

## Systems Inventory

### zephyrus

ASUS ROG Zephyrus G14 (`GA401QM`) — primary development workstation.

- **CPU**: AMD Ryzen 9 5900HS (8C/16T)
- **GPU**: AMD Radeon iGPU + NVIDIA RTX 3060 (laptop mode)
- **RAM**: 16GB DDR4
- **Desktop**: Hyprland + SDDM (sddm-astronaut, jake_the_dog theme)
- **Key Services**: Docker, VirtualBox, media stack (Jellyfin, \*arr suite), Caddy reverse proxy
- **Theme**: Catppuccin Macchiato
- **Full hardware facts**: [`nix/systems/zephyrus/facter.json`](nix/systems/zephyrus/facter.json)

### lg-laptop

LG laptop — secondary workstation.

- **GPU**: Intel Arc (device ID `a7a0`)
- **Desktop**: KDE Plasma
- **Key Services**: Media stack, Caddy reverse proxy
- **Theme**: Catppuccin Macchiato
- **Full hardware facts**: [`nix/systems/lg-laptop/facter.json`](nix/systems/lg-laptop/facter.json)

## Module System

### NixOS Module Options

| Option Namespace | Purpose |
| :--- | :--- |
| `core.*` | Base system: hardware, networking, boot, users, secrets, Nix configuration |
| `core.hardware.*` | Hardware abstraction: CPU vendor, GPU drivers (AMD/Intel/NVIDIA), HID devices, ADB, Bluetooth |
| `core.networking.*` | NetworkManager, OpenSSH, Tailscale with Serve integration |
| `core.boot.*` | Bootloader (systemd-boot), Plymouth splash, kernel selection |
| `core.users.*` | User provisioning with admin roles, SSH keys, and secret access |
| `desktop.*` | Desktop environment stack (gated by `desktop.enable`) |
| `desktop.environments.*` | Display managers (SDDM, greetd), window managers (Hyprland), desktop environments (KDE, Cosmic) |
| `desktop.services.*` | ASUS daemon, Flatpak, PipeWire, printing, virtualization |
| `desktop.tools.*` | Docker, VirtualBox, AppImage, partition manager |
| `desktop.features.*` | Gaming profiles with console support |
| `hosting.*` | Self-hosted services: Caddy proxy, media stack, homepage dashboard |
| `hosting.media.*` | Jellyfin, Overseerr, Sonarr, Radarr, Prowlarr, FlareSolverr, qBittorrent |
| `hosting.proxy.*` | Declarative Caddy reverse proxy with DNS configuration |
| `themes.*` | Stylix integration with base16 scheme selection |

### Home Manager Module Options

| Option Namespace | Purpose |
| :--- | :--- |
| `core.*` | Base user environment: shells, applications, email, SSH, secrets |
| `core.shells.*` | Bash, Fish, Starship prompt, Fastfetch |
| `core.apps.*` | Git, Yazi file manager |
| `userapps.*` | User-facing applications organized by category |
| `userapps.desktop.*` | Browsers (Firefox, Zen), communication (Discord, Matrix, Signal, Telegram), file managers, office suites, media players |
| `userapps.development.*` | Editors (Neovim, VSCode, Zed, Cursor), AI agents (Gemini, OpenCode, Cursor), terminal emulators (Ghostty, Kitty), MCP servers, GitHub CLI |
| `userapps.data-fortress.*` | Personal data: Bitwarden, Nextcloud, Obsidian, media management |
| `userapps.content-creation.*` | Blender, GIMP, Inkscape, Krita, Kdenlive, Audacity, OBS Studio |

## Quick Start

### Prerequisites

- Nix with flakes enabled
- `direnv` for automatic dev shell activation
- Determinate Nix (recommended for caching)

### Development Environment

```bash
direnv allow
# or
nix develop
```

The dev shell provides: `nixd`, `nil`, `alejandra`, `vulnix`, `gh`, `age`, `agenix`, `sops`, `disko`, `nixos-facter`, and auto-deploys GitHub Actions from `actions.nix`.

### Validation

```bash
nix fmt        # Format Nix, YAML, and Markdown
nix flake check # Run all checks (pre-commit + treefmt)
```

### Deployment

**NixOS system:**

```bash
nh os switch .#<hostname>
```

**Standalone Home Manager:**

```bash
nh home switch .#<username>
```

**System-integrated Home Manager:**

Home configurations for users on NixOS hosts are deployed automatically via `nh os switch`. The `core.users` module in each system configuration handles user creation and Home Manager integration.

## Secrets Management

Two complementary systems manage secrets at different layers:

| System | Scope | Mechanism |
| :--- | :--- | :--- |
| **sops-nix** | System and user secrets at deployment time | Encrypted YAML in repo, decrypted via host SSH keys (NixOS) or age keys (Home Manager) |
| **agenix** | Dev shell secrets for developer tooling | Encrypted files decrypted on dev shell entry via age identity key |

Sops rules are defined in `.sops.yaml` with path-based encryption targeting specific hosts and users. Age keys are managed per-system and per-admin.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, branching strategy, and commit conventions.

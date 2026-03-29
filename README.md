# Homelab

## 🏰 Project Overview: The Data Fortress

This repository is a comprehensive, declarative configuration for my personal infrastructure (homelab). It manages everything from physical servers and desktops to virtualized environments and single-board computers leveraging the declarative nature of the nix ecosystem, docker-compose, and kubernetes manifests via fluxCD.

### NixOS

Built on **NixOS** and **Home Manager**, it leverages **Nix Flakes** for reproducibility and hermetic builds.

### Docker Compose

# Todo

### Kubernetes

# Todo

## 🧠 Core Philosophy

1. **Declarative everything**: If it's not in code, it doesn't exist (outside of personal documents and other individually controlled files).
1. **Single Command Invocation**: Deployment and updates should be one command using `nh` (i.e. `nh os switch .` or `nh home switch .` for environments running standalone HM).
1. **Dynamic Discovery**: The system automatically finds code. You shouldn't have to manually import every new file outside of defining module structure.
1. **Stability**: `nix flake check` is the law. If it fails, fix it before pushing.

## 🏗️ Architecture

This repository uses a modern Flake-based structure with automatic discovery logic.

### Directory Structure

| Directory | Role | Description |
| :--- | :--- | :--- |
| **`homes/`** | **Users** | Home Manager configurations. Core (`user`), Standalone (`user@home-name`) or system-bound (`user@hostname`). |
| **`lib/`** | **Helpers** | Utility functions used throughout the flake. |
| **`modules/`** | **Logic** | Reusable modules. `nixos/` for NixOS-level, `home/` for user-level. |
| **`nvim/`** | **Neovim** | Neovim configurations built with nvf. |
| **`overlays/`** | **Overlays** | Package overlays used throughout the flake. (Internal pkg modifications) |
| **`pkgs/`** | **Software** | Custom package declarations. |
| **`secrets/`** | **Secrets** | Encrypted secrets used throughout the flake for developer facing integrations. |
| **`systems/`** | **Hosts** | Top-level NixOS configurations for machines. Each folder is a host toplevel module. |
| **`templates/`** | **Scaffolding** | Boilerplates for creating new systems, modules, or general projects. |

### Dynamic Discovery

The `lib/` directory includes custom logic to automatically import configurations:

- **Systems**: Any directory in `systems/` with a `default.nix` is automatically exposed as a `nixosConfiguration`.
- **Homes**: The flake scans `homes/` for three naming patterns:
  - `user` — Base configuration, used everywhere as a base configuration layer.
  - `user@home-name` — Supplementary config for standalone installs. Combined with the base and exported as `homeConfigurations.user@home-name`.
  - `user@hostname` — Machine-specific overrides, imported by the NixOS system configuration itself. **Not** exported as a standalone `homeConfiguration`.

## 🚀 Quick Start

### Prerequisites

- Nix installed with Flakes enabled.
- `direnv` (recommended) for automatic dev shell loading.
- `determinate-nix` (recommended) for caching and build performance.

### Development Environment

Simply `cd` into the directory. `direnv` will automatically load a dev shell with all necessary tools (`nix`, `sops`, `age`, etc.).

```bash
direnv allow
# or
nix develop
```

### Validating Changes

Always run the flake check before pushing or deploying.

```bash
nix flake check
```

This is enforced via pre-commit hooks.

### Deployment

**Deploy a NixOS System:**

```bash
nixos-rebuild switch --flake .#<hostname>
```

**Deploy a Home Manager Configuration:**

```bash
home-manager switch --flake .#<username>
```

## 🔐 Secrets Management

Secrets are managed using `agenix` for developer integration required secrets, exported automatically into the devshell when a compatible age key is available as an environment variable. Encrypted secrets are stored in the repo, and keys are derived from host SSH keys or age user keys (for home manager based sops secrets), which are version controlled and deployed to the target system via `sops-nix` if the system has a compatible host ssh key, or age key for home manager based sops secrets.

## 🤝 Contributing

See [docs/Meta/CONTRIBUTING](docs/Meta/CONTRIBUTING.md) for detailed guidelines.

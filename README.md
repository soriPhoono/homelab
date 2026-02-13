# Homelab: The Data Fortress

## 🏰 Project Overview

This repository is the "Data Fortress," a comprehensive, declarative configuration for my personal infrastructure. It manages everything from physical servers and desktops to virtualized environments and single-board computers.

Built on **NixOS** and **Home Manager**, it leverages **Nix Flakes** for reproducibility and hermetic builds.

## 🧠 Core Philosophy

1. **Declarative everything**: If it's not in code, it doesn't exist.
1. **Single Command Invocation**: Deployment and updates should be one command.
1. **Dynamic Discovery**: The system automatically finds code. You shouldn't have to manually import every new file.
1. **Stability**: `nix flake check` is the law.

## 🏗️ Architecture

This repository uses a modern Flake-based structure with automatic discovery logic.

### Directory Structure

| Directory | Role | Description |
| :--- | :--- | :--- |
| **`systems/`** | **Hosts** | Top-level NixOS configurations for machines. Each folder is a host. |
| **`homes/`** | **Users** | Home Manager configurations. Can be standalone or integrated. |
| **`modules/`** | **Logic** | Reusable modules. `distro/` for OS-level, `home/` for user-level. |
| **`pkgs/`** | **Software** | Custom packages and overrides. |
| **`lib/`** | **Helpers** | Utility functions used throughout the flake. |
| **`templates/`** | **Scaffolding** | Boilerplate for creating new systems or modules. |

### Dynamic Discovery

The `flake.nix` file includes custom logic to automatically import configurations:

- **Systems**: Any directory in `systems/` with a `default.nix` is automatically exposed as a `nixosConfiguration`.
- **Homes**: Any directory in `homes/` is exposed as a `homeManagerConfiguration`.

## 🚀 Quick Start

### Prerequisites

- Nix installed with Flakes enabled.
- `direnv` (recommended) for automatic dev shell loading.

### Development Environment

Simply `cd` into the directory. `direnv` will automatically load a dev shell with all necessary tools (`nix`, `colmena`, `sops`, `age`, etc.).

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

### Deployment

**Deploy a NixOS System:**

```bash
nixos-rebuild switch --flake .#<hostname>
```

**Deploy a Home Manager Configuration:**

```bash
home-manager switch --flake .#<username>@<hostname>
```

## 🔐 Secrets Management

Secrets are managed using `sops-nix` and `agenix`. Encrypted secrets are stored in the repo, and keys are derived from host SSH keys or user keys.

## 🤝 Contributing

See [docs/Meta/CONTRIBUTING](docs/Meta/CONTRIBUTING.md) for detailed guidelines.

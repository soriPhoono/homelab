# AGENTS.md - Homelab "The Data Fortress"

This document provides high-level architectural context and development guidelines for AI agents interacting with this Nix-based homelab project.

## 🏰 Project Overview

**The Data Fortress** is a comprehensive, declarative infrastructure-as-code repository for managing physical servers, desktops, and virtual environments. It is built on the **Nix** ecosystem, specifically leveraging **NixOS**, **Home Manager**, and **Nix Flakes** for reproducibility and hermetic builds.

### Core Technologies

- **NixOS & Home Manager**: Declarative system and user configuration.
- **Flake-parts**: Modular flake structure.
- **nh (nix-helper)**: Primary CLI for system/home deployments.
- **sops-nix & agenix**: Encrypted secrets management.
- **Disko**: Declarative disk partitioning.
- **nixos-facter**: Hardware-specific configuration discovery.

______________________________________________________________________

## 🏗️ Architecture & Discovery

The project uses a **Dynamic Discovery Mechanism** to automate module imports and system/home exports.

### Module System

#### Nixos

Configurations are categorized into three main layers:

1. **Core**: Essential system services, networking, and user management.
2. **Desktop**: UI environments (KDE, SDDM), gaming, and productivity tools.
3. **Hosting**: Server-side workloads (Docker, K3s).

#### Home Manager

# TODO

### Discovery Logic (`lib.discover`)

The system automatically finds and imports configurations:

- **Systems**: Any directory in `nix/systems/` with a `default.nix` is exported as a `nixosConfiguration`.
- **Homes**: Scanned from `nix/homes/`.
  - `user` (base layer)
  - `user@home-name` (standalone Home Manager export)
  - `user@hostname` (host-specific overrides, imported by the system configuration)

______________________________________________________________________

## 🚀 Building & Deployment

### Development Environment

The project uses `direnv` and `flake-parts` to provide a consistent development shell.

```bash
direnv allow  # Preferred
nix develop   # Alternative
```

### Deployment Commands

Deployment is recommended via the `nh` (nix-helper) tool:

- **Deploy System**: `nh os switch .` (targets current hostname) or `nixos-rebuild switch --flake .#<hostname>`
- **Deploy Home**: `nh home switch .` or `home-manager switch --flake .#<username>`

### Validation

Strict adherence to `nix flake check` is required before any deployment or push. This is enforced by `pre-commit` hooks.

```bash
nix flake check
```

______________________________________________________________________

## 🛠️ Development Workflow

### Adding a New System

1. Create a directory: `nix/systems/<hostname>/`.
1. Add `default.nix` and `disko.nix`.
1. (Optional) Run `nixos-facter` to generate `facter.json` for hardware support.
1. Run `nix flake check` to verify the new configuration.

### Formatting & Linting

The project uses `treefmt` with the following tools:

- **Nix**: `alejandra` (formatter), `deadnix` (dead code), `statix` (linting).
- **YAML**: `yamlfmt`.
- **Markdown**: `mdformat`.

______________________________________________________________________

## 📂 Key Files & Directories

- `flake.nix`: Entry point, inputs, and output generation logic.
- `nix/lib/`: Custom library functions (Discovery, Metadata reading).
- `nix/modules/`: Reusable NixOS (`nixos/`) and Home Manager (`home/`) modules.
- `nix/systems/`: Machine-specific configurations.
- `nix/homes/`: User-specific Home Manager configurations.
- `secrets.nix`: Definition of `agenix` secrets for the dev shell.
- `.sops.yaml`: SOPS configuration for encrypted secrets.

______________________________________________________________________

## 🔐 Secrets Management

- **System Secrets**: Managed via `sops-nix`. Keys are typically host SSH keys.
- **User/Dev Secrets**: Managed via `agenix`. Decrypted automatically in the `nix develop` shell if the required key is present.
- **Encryption**: Secrets are stored as encrypted YAML/Age files in `nix/systems/<host>/secrets.yml` or `secrets/`.

______________________________________________________________________

## 🧪 Testing & CI

- **Local Checks**: `nix flake check` evaluates all system and home configurations.
- **GitHub Actions**: Workflows in `.github/workflows/` are managed declaratively via `actions.nix`.
- **Pre-commit**: `pre-commit.nix` defines hooks for linting and formatting.

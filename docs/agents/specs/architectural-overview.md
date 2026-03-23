# Architectural Overview

This repository is a Nix-based "homelab" configuration that manages both NixOS systems and user environments (Home Manager) using a unified, modular approach.

## Core Pillars

1. **Nix Flakes**: The entire project is driven by `flake.nix`, providing reproducible inputs and outputs.
1. **Modular Configuration**: Instead of monolithic files, configuration is broken down into reusable modules located in `nix/modules/`.
1. **Automatic Discovery**: Systems and Home Manager configurations are automatically discovered and built based on the directory structure in `nix/systems/` and `nix/homes/`.
1. **Integrated Home Manager**: Home Manager is used both as a NixOS module (for integrated system/user management) and as a standalone configuration.
1. **Secure by Design**: Secret management is integrated using `sops-nix` and `agenix`.

## System Life Cycle

- **Inputs**: Defined in `flake.nix` (nixpkgs, home-manager, sops-nix, etc.).
- **Modules**: NixOS and Home Manager modules define "features" (e.g., `core.nixconf`, `userapps.firefox`).
- **Discovery**: `lib.discover` scans `nix/systems/` and `nix/homes/` to find entry points.
- **Construction**: `mkSystem` and `mkHome` functions in `flake.nix` assemble the modules and configurations.
- **Deployment**: Managed via standard Nix tools or `comin` for GitOps-style pulls.

# Homelab MOC (Map of Content)

Welcome to the documentation for my personal homelab and device configuration. This project uses a unified Nix flake to manage NixOS systems, Home Manager environments, and Nix-on-Droid configurations.

## 🏗️ Core Architecture

- [Architecture](./Architecture.md): Overview of the flake structure, builders, and discovery logic.
- [Development Experience](./DevExperience.md): Modularity with `flake-parts` and `agenix-shell`.
- [Security](./Security.md): Secrets management and system auditing.

## 🖥️ Systems & Homes

- [Systems](./Systems/Overview.md): Hardware specific configurations (Laptops, Proxmox nodes).
- [Homes](./Homes/Overview.md): User environments and specialized profiles.

## 🧱 Functional Modules

- [NixOS Modules](./Modules/NixOS.md): Core, Desktop, and Hosting features.
- [Home Modules](./Modules/Home.md): Shells, UserApps, and Dev tools.
- [Droid Modules](./Modules/Droid.md): Nix-on-Droid specific configurations.

## 📦 Packages & Overlays

- [Packages](./Packages.md): Custom packages like `gemini-cli-jules`.
- [Overlays](./Overlays/README.md): External package extensions.

______________________________________________________________________

*This documentation is automatically mirrored to the Obsidian vault for easy reference.*

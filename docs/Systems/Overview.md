# Systems Overview

This homelab consists of several physical and virtual systems, each categorized by their role and hardware capabilities.

## 💻 Laptops (Personal Devices)

- [zephyrus](./zephyrus.md): Primary development machine and repository testbench.
- [lg-laptop](./lg-laptop.md): Intel-based productivity machine for specialized users.

## 🛠️ Infrastructure & Virtualisation

- [moonlight](./moonlight.md): Proxmox node dedicated to running VMs and core homelab services.
- [node](./node.md): A template-based system used as a "sidecar" Docker runtime.

## 🛰️ Remote Systems

- **Droids**: Personal mobile devices running Nix-on-Droid.

Each system is defined in the `systems/` directory of the repository and is automatically discovered by the primary flake.

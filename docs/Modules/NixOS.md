# NixOS Modules

NixOS modules are organized into functional categories to allow for granular system configuration.

## 📂 Categories

### 🛠️ Core (`modules/nixos/core`)

Essential system settings required for every host:

- **Networking**: NetworkManager, Tailscale, and global firewall rules.
- **Hardware**: Firmwares, GPU drivers (Intel/AMD/NVIDIA), and HID support.
- **Security**: ClamAV integration and user management.
- **GitOps**: Automated system updates via GitHub repositories.

### 🖥️ Desktop (`modules/nixos/desktop`)

GUI-related configurations:

- **Environments**: Support for KDE Plasma.
- **Features**: Gaming optimizations, printing services, and virtualization.
- **Services**: Hardware-specific daemons like `asusd`.

### 🌐 Hosting (`modules/nixos/hosting`)

Infrastructure and container services:

- **Backends**: Support for Docker and Podman.
- **Blocks**: Pre-configured features like `docker-games-server`.

## 🧩 Usage

Modules are automatically discovered by the flake. Enable them in your system's `default.nix` using the standard category-based options:

```nix
core.clamav.enable = true;
desktop.environments.kde.enable = true;
```

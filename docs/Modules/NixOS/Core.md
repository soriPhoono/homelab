# NixOS Core Modules

The `modules/nixos/core` directory contains the foundational configuration for the system.

## Structure

- `default.nix`: Main entry point for core configuration.
- `hardware/`: Hardware-specific configurations (GPU, HID, etc.).
- `networking/`: Network stack configuration.

## Modules

### Root Files

- `boot.nix`: Bootloader (systemd-boot/grub) and kernel configuration.
- `users.nix`: User account definitions, groups, and permissions.
- `secrets.nix`: Secret management (sops/agenix) integration.
- `nixconf.nix`: Nix package manager settings (flakes, experimental features).
- `gitops.nix`: System auto-update and GitOps agent configuration (comin).

### `hardware`

- **Purpose**: managing physical hardware support.
- **Files**:
  - `gpu/`: Graphics card support (Nvidia, AMD).
  - `hid/`: Input devices (keyboards, mice).
  - `bluetooth.nix`: Bluetooth stack configuration.
  - `adb.nix`: Android Debug Bridge support.

### `networking`

- **Purpose**: managing network connectivity.
- **Files**:
  - `tailscale.nix`: Tailscale VPN mesh networking.
  - `openssh.nix`: SSH server and client configuration.
  - `network-manager.nix`: NetworkManager settings.

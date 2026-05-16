# NixOS Modules

This directory contains system-level NixOS modules organized into four functional groups: `core`, `desktop`, `hosting`, and `themes`. All modules are auto-discovered via `lib.homelab.core.discover` and exported through `default.nix`.

## Module Groups

### core

The foundational system configuration layer. Provides hardware abstraction, networking, boot management, user provisioning, and secret integration.

**Sub-modules:**

| Module | Purpose |
| :--- | :--- |
| `hardware/` | Hardware abstraction: CPU vendor selection, GPU driver stacks (AMD, Intel, NVIDIA), HID device support (keyboards, Logitech, tablet, Xbox), ADB, Bluetooth |
| `networking/` | NetworkManager, OpenSSH, Tailscale with Serve integration |
| `boot.nix` | Bootloader configuration (systemd-boot), Plymouth splash, kernel package selection |
| `clamav.nix` | ClamAV antivirus service |
| `gitops.nix` | GitOps deployment configuration via comin |
| `nixconf.nix` | Nix daemon configuration, Determinate Nix integration, build core limits |
| `secrets.nix` | sops-nix integration for system-level secret decryption |
| `security.nix` | System security hardening |
| `users.nix` | Declarative user provisioning with admin roles, SSH public keys, shell assignment, and per-user secret access |

**Key Options:**

- `core.enable` — Activates the core module group
- `core.context` — System-level context string for AI agent guidance
- `core.timeZone` — IANA time zone identifier
- `core.hardware.reportPath` — Path to `nixos-facter` hardware facts JSON
- `core.users.<name>` — Attribute set defining a user: `description`, `hashedPassword`, `admin`, `shell`, `publicKey`, `secrets`

**Dependencies:** This module is the base layer. All other NixOS modules depend on it implicitly through shared options and service prerequisites.

### desktop

Desktop environment stack gated behind `desktop.enable`. Provides window managers, display managers, peripheral services, and developer tooling.

**Sub-modules:**

| Module | Purpose |
| :--- | :--- |
| `environments/` | Display managers (SDDM with theming, greetd), window managers (Hyprland), desktop environments (KDE Plasma, Cosmic) |
| `features/` | Gaming profiles with Steam, Proton, and console support |
| `services/` | ASUS daemon, Flatpak, PipeWire audio, printing, virtualization services |
| `tools/` | Docker, VirtualBox, AppImage support, partition manager |

**Key Options:**

- `desktop.enable` — Master toggle for desktop configuration
- `desktop.environments.display_managers.sddm` — SDDM configuration with theme package and name
- `desktop.environments.managers.hyprland.enable` — Hyprland Wayland compositor
- `desktop.environments.kde.enable` — KDE Plasma desktop
- `desktop.environments.cosmic.enable` — COSMIC desktop
- `desktop.features.gaming.enable` — Gaming stack activation
- `desktop.features.gaming.console.enable` — Console controller support
- `desktop.services.asusd.enable` — ASUS laptop daemon
- `desktop.services.pipewire.enable` — PipeWire audio server
- `desktop.services.printing.enable` — CUPS printing service
- `desktop.services.flatpak.enable` — Flatpak package manager
- `desktop.services.virtualisation.enable` — Virtualization host services
- `desktop.tools.docker.enable` — Docker engine
- `desktop.tools.virtualbox.enable` — VirtualBox hypervisor
- `desktop.tools.appimage.enable` — AppImage runtime
- `desktop.tools.partition-manager.enable` — Disk partitioning GUI

**Activation Behavior:** When `desktop.enable = true`, the module automatically enables Bluetooth, NetworkManager, PipeWire, AppImage support, and `xdg.terminal-exec`.

### hosting

Self-hosted service infrastructure. Provides reverse proxy, media stack, and dashboard services.

**Sub-modules:**

| Module | Purpose |
| :--- | :--- |
| `proxy/` | Caddy reverse proxy with declarative route configuration and DNS management |
| `media/` | Media service stack: Jellyfin, Overseerr, Sonarr, Radarr, Prowlarr, FlareSolverr, qBittorrent |
| `homepage.nix` | Homepage dashboard service |

**Key Options:**

- `hosting.homepage.enable` — Homepage dashboard activation
- `hosting.media.enable` — Full media stack activation
- `hosting.proxy.dns.baseDomain` — Base domain for Caddy routes (e.g., `cryptic-coders.net`)
- `hosting.proxy.dns.email` — Contact email for Caddy ACME registration

**Service Paths:** Media storage is managed under `/mnt/local/media` with service-specific subdirectories for movies, shows, and downloads.

### themes

System-wide theming via Stylix with base16 color scheme support.

**Key Options:**

- `themes.enable` — Stylix activation
- `themes.base16Scheme` — Path to a base16 YAML scheme file (e.g., Catppuccin Macchiato)

**Integration Notes:** Stylix is configured with `homeManagerIntegration.followSystem = false` and `homeManagerIntegration.autoImport = false` to prevent automatic Home Manager theme propagation. Theme application to user environments is handled explicitly through Home Manager modules.

## Discovery Mechanism

All `.nix` files and directories containing `default.nix` in this directory are automatically imported by `nix/modules/nixos/default.nix` via `lib.homelab.core.discover`. The `default` export aggregates all modules into a single importable unit.

**Adding a new module:** Place a `.nix` file or a directory with `default.nix` in the appropriate subdirectory. No manual `imports` registration is required.

## Module Composition Pattern

Modules in this repository function as configuration overlays. Each module declares options and contributes configuration to the system state tree. When enabling a feature, the responsible module must handle all aspects of its configuration scope, including potential collisions with other modules.

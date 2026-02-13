# Desktop Modules

The `modules/nixos/desktop` directory manages desktop environments, window managers, and related services.

## Structure

- `default.nix`: Entry point for desktop configuration.
- `environments/`: specific DE/WM configurations.
- `features/`: Shared desktop features.
- `services/`: Desktop-related system services.

## Modules

### `environments`

- **Purpose**: managing the graphical session.
- **Files**:
  - `cosmic.nix`: COSMIC desktop environment.
  - `kde.nix`: KDE Plasma 6 environment.
  - `uwsm.nix`: Universal Wayland Session Manager integration.
  - `display_managers/`: GDM, SDDM, etc.
  - `managers/`: Window manager logic.

### `features`

- **Purpose**: Enhancing the desktop experience.
- **Files**:
  - `gaming.nix`: Steam, Gamemode, and related gaming optimizations.
  - `printing.nix`: CUPS and printer definitions.
  - `virtualisation.nix`: Podman/Docker host configuration (system-level).

### `services`

- **Purpose**: Background services for hardware or software support.
- **Files**:
  - `asusd.nix`: ASUS laptop tools (for Zephyrus).
  - `flatpak.nix`: Flatpak package management support.
  - `pipewire.nix`: Audio/Video pipeline configuration.

# Home Manager Desktop Modules

The `modules/home/desktop` directory configures the graphical user environment.

## Structure

- `default.nix`: Main entry point.
- `environments/`: Configuration for specific desktop environments / window managers.

## Modules

### `environments`

- **Purpose**: managing the user session.
- **Files**:
  - `hyprland/`: Hyprland Wayland compositor configuration (`hyprland.nix`, `binds.nix`, etc.).
  - `waybar/`: Status bar for Wayland.
  - `wofi/`: Application launcher.
  - `lockscripts.nix`: Screen locking scripts.

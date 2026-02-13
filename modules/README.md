# Modules Directory

This directory contains reusable NixOS and Home Manager modules.

## Structure

- **`nixos/`**: Modules for system-level configuration (services, hardware, etc.). These are imported into NixOS systems.
- **`home/`**: Modules for user-level configuration (shell, desktop apps, etc.). These are imported into Home Manager configurations.

## Usage

Modules are automatically exported via the flake and can be imported in your configurations.

### Import Strategy

Modules should be designed to be composable. Enable them via options (usually `enable = true;`) rather than just importing them.

Example:

```nix
{
  modules.nixos.services.docker.enable = true;
}
```

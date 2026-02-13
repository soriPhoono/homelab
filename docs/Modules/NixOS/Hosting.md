# Hosting Modules

The `modules/nixos/hosting` directory provides modules for self-hosted services and infrastructure blocks.

## Structure

- `default.nix`: Entry point for hosting modules.
- `blocks/`: Reusable service blocks.
- `blocks/default.nix`: Entry point for blocks.
- `blocks/features/`: Specific service implementations (e.g., containerized game servers).

## Modules

### `default.nix` (Main)

- **Purpose**: Enables the hosting capability for the system.
- **Options**:
  - `hosting.enable`: Boolean to enable hosting features.
  - `hosting.blocks.backends.type`: Selects the container backend (`docker` or `podman`).

### `blocks/backends`

- **Purpose**: managing container backends.
- **Files**:
  - `default.nix`: Configuration selector for container backend.
  - `docker.nix`: Docker backend configuration.
  - `podman.nix`: Podman backend configuration.

### `blocks/features`

- **Purpose**: Specific hosting features.
- **Files**:
  - `docker-games-server.nix`: Self-hosted game streaming server (Wolf/GamesOnWhales).
    - Options: `enable`, `openFirewall`, `dataDir`, `gpuRenderNode`.
  - `homarr.nix`: Dashboard for homelab services.
  - `default.nix`: Imports features.

### `blocks/reverse-proxy`

- **Purpose**: Reverse proxy configuration (e.g., Traefik/Nginx).

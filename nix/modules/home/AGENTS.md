# Home Manager Modules

This directory contains user-level Home Manager modules organized into two functional groups: `core` and `userapps`. All modules are auto-discovered via `lib.homelab.core.discover` and exported through `default.nix`.

## Module Groups

### core

The foundational user environment layer. Provides shell configuration, application defaults, email integration, SSH setup, and secret management.

**Sub-modules:**

| Module | Purpose |
| :--- | :--- |
| `shells/` | Shell environments: Bash, Fish (with Starship prompt), Fastfetch system information display |
| `apps/` | Core applications: Git configuration, Yazi terminal file manager |
| `email.nix` | Email client configuration |
| `gitops.nix` | GitOps workflow integration at the user level |
| `secrets.nix` | sops-nix integration for user-level secret decryption via age keys |
| `ssh.nix` | SSH client configuration, key management, and host definitions |

**Key Behaviors:**

- Enables `xdg` base directories and MIME application defaults
- Configures `nh` with automatic garbage collection (5-day retention)
- Sets `home.stateVersion` from the NixOS config when system-integrated, defaults to `26.05` for standalone
- Installs base utilities: `p7zip`, `unrar`

**Integration with NixOS:** When deployed as part of a NixOS system configuration, the `nixosConfig` argument is available, allowing conditional behavior based on system-level options (e.g., `xdg.userDirs.createDirectories` is gated by `nixosConfig.desktop.enable`).

### userapps

User-facing applications organized by functional category. Provides a comprehensive suite of desktop applications, development tools, personal data management utilities, and content creation software.

**Sub-module Groups:**

#### desktop

Desktop applications for general computing tasks.

| Sub-group | Modules |
| :--- | :--- |
| `browsers/` | Firefox, Zen Browser |
| `communication/` | Discord, Matrix, Signal, Telegram |
| `file-browser/` | Nautilus, PCManFM, Google Drive plugin |
| `office/` | LibreOffice, OnlyOffice, Slack, Zathura PDF viewer |
| `players/` | Strawberry (audio), VLC (video), imv (images), mpv |
| `tools/` | EasyEffects audio processing |
| `virtualization/` | Bottles (Windows compatibility), Distrobox |

#### development

Developer tooling and AI agent integration.

| Sub-group | Modules |
| :--- | :--- |
| `agentics/` | Agent context and MCP server configuration for system and editor layers |
| `agents/` | Cursor CLI, Gemini CLI, OpenCode agent configuration |
| `appliances/` | Bambu Studio (3D printing) |
| `editors/` | Cursor, Neovim (via nvf), VSCode, Zed |
| `inference/` | LM Studio for local model inference |
| `infrastructure/` | GitHub CLI and related tooling |
| `terminal/` | Ghostty, Kitty terminal emulators |

**Agent Configuration Architecture:**

AI agent context is managed through a tiered system:

- **System context** (`userapps.development.agents.context.system`): Host, hardware, OS, and platform details
- **User context** (`userapps.development.agents.context.user`): Operator identity, workflow preferences, aliases, personal tooling
- **Shared runtime context** (`userapps.development.agents.context.shared`): Derived context shared across agents

MCP server configuration uses the `homelab.types.ai.mcpServerSet` type, supporting both stdio and HTTP/SSE transports with environment variable injection from sops secrets.

#### data-fortress

Personal data management and synchronization.

| Sub-group | Modules |
| :--- | :--- |
| `auth/` | Bitwarden password manager |
| `cloud/` | Nextcloud client |
| `media/` | Grayjay media management |
| `notes/` | Obsidian knowledge base |
| `p2p/` | qBittorrent client |

#### content-creation

Creative and media production tools.

| Sub-group | Modules |
| :--- | :--- |
| `asset-creation/` | Blender, GIMP, Inkscape, Krita |
| `editors/` | Audacity (audio), Kdenlive (video) |
| `streaming/` | OBS Studio |

**Key Options:**

- `userapps.defaultApplications.enable` — Activates XDG MIME default application associations via Nix

## Discovery Mechanism

All `.nix` files and directories containing `default.nix` in this directory are automatically imported by `nix/modules/home/default.nix` via `lib.homelab.core.discover`. The `default` export aggregates all modules into a single importable unit.

**Adding a new module:** Place a `.nix` file or a directory with `default.nix` in the appropriate subdirectory. No manual `imports` registration is required.

## Module Activation Pattern

User application modules are typically gated behind enable flags evaluated in host-specific home configurations (`nix/homes/user@hostname/`). The base user configuration (`nix/homes/user/`) provides shared defaults, while host-specific layers activate the required application subsets.

## XDG Integration

When `userapps.defaultApplications.enable = true`, modules register their applications as XDG MIME defaults through `xdg.mimeApps`. This ensures consistent file type handling across the desktop environment without manual configuration.

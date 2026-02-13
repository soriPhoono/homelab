# Home Manager User Applications

The `modules/home/userapps` directory configures user-facing applications.

## Structure

- `default.nix`: Main entry point.
- `browsers/`: Web browser configurations.
- `development/`: Development tools and environments.

## Modules

### `browsers`

- **Purpose**: managing web browsers.
- **Files**:
  - `chrome.nix`: Google Chrome configuration.
  - `firefox.nix`: Firefox configuration.
  - `floorp.nix`: Floorp browser configuration.
  - `librewolf.nix`: Librewolf configuration.

### `development`

- **Purpose**: managing development workflows.
- **Files**:
  - `agents/`: AI agent configuration (Gemini, Claude, MCP servers).
  - `editors/`: Text editors and IDEs (VSCode, Neovim).
  - `terminal/`: Terminal emulators (Alacritty, Kitty).

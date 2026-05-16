# Nix Library

This directory contains the core Nix logic for the homelab flake, including the custom library extension and utility functions.

## lib.nix

Extends the standard `nixpkgs.lib` with homelab-specific functions and type definitions. The library is constructed via `nixpkgs.lib.extend` and is available throughout the flake as `lib`.

### homelab.core.discover

Automatic module discovery function. Performs filesystem introspection to identify and import Nix modules without manual `imports` lists.

**Signature:**

```nix
discover :: Path -> AttrSet
```

**Behavior:**

- Reads the contents of the provided directory via `builtins.readDir`
- Filters entries matching either:
  - A directory containing a `default.nix` file
  - A regular file with a `.nix` extension (excluding `default.nix` itself)
- Transforms matching entries into an attribute set where:
  - Keys are the file/directory name with `.nix` suffix removed
  - Values are the full path to the module

**Usage:**

```nix
{ lib, ... }:
let
  modules = lib.homelab.core.discover ./.;
in
  modules // {
    default = {
      imports = builtins.attrValues modules;
    };
  }
```

**Applied in:**

- `nix/modules/nixos/default.nix` — Auto-discovers all NixOS modules
- `nix/modules/home/default.nix` — Auto-discovers all Home Manager modules
- `nix/overlays/default.nix` — Auto-discovers all package overlays
- `flake.nix` — Auto-discovers all NixOS system configurations

### homelab.types.ai

Type definitions for AI agent and MCP server configuration. Provides structured types for declarative agent setup within NixOS and Home Manager modules.

#### envType

Defines environment variable configuration with optional secret injection.

**Sub-options:**

- `secret` — Sops secret name to load (e.g., `api/OPENROUTER_API_KEY`)
- `environmentVariable` — Target environment variable name (derived from secret basename if not specified)
- `prefix` — String prepended to the secret value (e.g., `Bearer `)
- `suffix` — String appended to the secret value

**Type:** `oneOf [ (submodule { ... }) str ]`

Accepts either a submodule with the above options or a plain string for non-secret environment values.

#### mcpServerSet

Defines a set of MCP (Model Context Protocol) server configurations.

**Sub-options:**

- `transport` — Protocol type: `stdio`, `http`, or `sse` (default: `http`)
- `command` — Executable path for stdio-backed servers
- `args` — Command-line arguments for stdio-backed servers
- `env` — Environment variables with `envType` injection
- `url` — Endpoint URL for remote HTTP/SSE servers
- `headers` — HTTP headers with `envType` injection

**Type:** `attrsOf (submodule { ... })`

**Integration:** Used in Home Manager modules for AI agent configuration (Cursor, Gemini, OpenCode) to declaratively define MCP server connections with secret-managed authentication.

## Directory Contents

| File/Directory | Purpose |
| :--- | :--- |
| `lib.nix` | Custom library extension: `homelab.core.discover`, `homelab.types.ai` |
| `homes/` | Home Manager user configurations |
| `modules/` | Reusable NixOS and Home Manager modules |
| `overlays/` | Package overlays for the global `pkgs` set |
| `pkgs/` | Custom package declarations |
| `systems/` | Top-level NixOS host configurations |
| `templates/` | Project scaffolding templates |
| `nvim/` | Neovim configuration (sphoono, via nvf) |
| `secrets/` | Encrypted secrets (sops-nix) |

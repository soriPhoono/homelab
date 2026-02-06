# AI Context & Instructions

**Primary Directive**: You are working on "The Data Fortress". Your goal is to maintain a stable, distinct, and declarative infrastructure.

## 1. Core Philosophy: Single Command Invocation

- **Fix the Flake, Don't Script**: Do not suggest creating bash scripts to work around issues. If a tool isn't in the path, add it to the `devShell`. If a config is wrong, fix the Nix module.
- **The Check is King**: `nix flake check` is the ultimate validator.

## 2. Code Conventions

- **Variables**: `snake_case` (e.g., `my_variable = "foo";`)
- **Functions**: `camelCase` (e.g., `mkSystem = ...`)
- **Module Structure**:
  ```nix
  { lib, config, pkgs, ... }: let
    cfg = config.path.to.module;
  in with lib; {
    options.path.to.module = {
      enable = mkEnableOption "Description";
    };
    config = mkIf cfg.enable {
      # Config here
    };
  }
  ```

## 3. Dynamic Discovery Logic

This repository uses a custom discovery mechanism in `flake.nix`.

- **Systems**: defined in `systems/<host>/default.nix`.
- **Homes**: defined in `homes/<user>@<host>/default.nix` or `homes/<user>/default.nix`.
- **Meta**: `meta.json` in the directory defines the architecture (e.g., `{"system": "x86_64-linux"}`).

## 4. Map of the Fortress

- `homes/` -> user-level configs (zsh, neovim, git).
- `modules/nixos/` -> system-level services (docker, k8s, ssh).
- `modules/home/` -> user-level configs (zsh, neovim, git).
- `overlays/` -> Patches to upstream nixpkgs.
- `pkgs/` -> Custom software compiled from source.
- `systems/` -> hardware specific configs.

______________________________________________________________________

## name: nix-editor-module description: "Author home-manager modules for text editors that bridge custom options (mkEditor) to upstream programs.\* HM modules." version: 1.0.0 author: Hermes Agent license: MIT platforms: [linux] metadata: hermes: tags: [nix, home-manager, editors, module, refactoring] related_skills: [nix-agent-module, plan, github-pr-workflow]

# Nix Editor Module Authoring

Pattern for writing home-manager modules for text editors that bridge
custom/homelab options (via `homelab.agentics.mkEditor`) to upstream
`programs.*` home-manager modules.

Analogous to `nix-agent-module` but for the editor category.

## Class structure

```
nix/modules/home/userapps/development/editors/<editor>.nix
```

Every editor module follows the same layout:

1. **Options** — use `homelab.agentics.mkEditor` for the common option set
1. **Config** — `mkMerge` + `mkIf cfg.enable` delegating to the upstream
   `programs.*` module

## Option shape from `mkEditor`

Provided automatically by `lib.nix`:

| Option | Type | Purpose |
|--------|------|---------|
| `enable` | `bool` | Enable the editor |
| `package` | `package` | The editor package |
| `secrets` | `listOf str` | Sops secrets for the editor env |
| `defaultEditor` | `bool` | Whether to set EDITOR/VISUAL |
| `priority` | `int` | Priority for MIME type associations (higher = wins) |
| `userSettings` | `attrs` | Freeform editor settings |
| `extraPackages` | `listOf package` | LSP servers, formatters, etc. |

Add editor-specific options via `extraOptions`.

## Basic pattern

```nix
{ lib, pkgs, config, ... }: let
  cfg = config.userapps.development.editors.<name>;
in with lib; {
  options.userapps.development.editors.<name> = homelab.agentics.mkEditor {
    name = "<name>";
    package = pkgs.<editor-package>;
    extraOptions = {
      # Editor-specific options only
      extensions = mkOption {
        type = with types; listOf str;
        default = [];
        description = "List of <Editor> extensions to install.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Delegate to upstream HM module
      programs.<editor> = {
        enable = true;
        inherit (cfg) package;
        inherit (cfg) extensions userSettings;
        # etc.
      };
    }
  ]);
};
```

## Layered interfaces (mkVscodeEditor)

For editor *families* (VS Code, VSCodium, etc.), create a specialized builder
on top of mkEditor. This is the Nix equivalent of interface inheritance:

```nix
mkVscodeEditor = {
  name ? "vscode",
  package ? pkgs.vscode,
  extraOptions ? {},
}:
  homelab.agentics.mkEditor {
    inherit name package;
    extraOptions = {
      extensionProfiles = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              extensions = mkOption {
                type = listOf package;
                default = [];
                description = "Extensions for this profile.";
              };
            };
          });
        default = {};
      };
      activeProfiles = mkOption {
        type = with types; listOf str;
        default = [ "default" ];
      };
    }
    // extraOptions;
  };
```

Then an editor module uses `mkVscodeEditor` instead of `mkEditor` directly:

```nix
options.userapps.development.editors.vscode = homelab.agentics.mkVscodeEditor {
  name = "vscode";
  package = pkgs.vscode;
};
```

This pattern can be extended for any editor family (mkJetbrainsEditor,
mkHelixEditor, etc.).

## defaultEditor handling

**CRITICAL**: Check whether the upstream `programs.*` module has its own
`defaultEditor` option BEFORE adding `home.sessionVariables.EDITOR` in the
config section. If the upstream handles it, delegate — do NOT duplicate:

- **Upstream handles it** (e.g. `programs.helix.defaultEditor`): use
  `inherit (cfg) defaultEditor;` in the programs.\* block. Do NOT set
  `home.sessionVariables.EDITOR` — it will conflict.
- **Upstream doesn't handle it** (e.g. `programs.zed-editor`): wire it
  manually via `home.sessionVariables = mkIf cfg.defaultEditor { ... }`.

Search the upstream module. Two approaches:

```bash
# Shell (devshell): find the module file
find /nix/store/*-source/modules/programs/ -name "<editor>.nix" 2>/dev/null
```

```nix
# Nix MCP tool (no shell needed): check for the option
mcp_nixos_nix action=search query="programs.<editor>.defaultEditor" type=options
```

Also verify by checking the NixOS config build — if removing the manual
`home.sessionVariables.EDITOR` and using `inherit (cfg) defaultEditor;`
fixes a "conflicting definition values" error, the upstream handles it.

## Backwards compat for renamed options

When `mkEditor` renames an option (e.g. `settings` → `userSettings`),
keep the old name as a per-editor `extraOptions` entry and merge both
in the config:

```nix
# In extraOptions:
settings = mkOption {
  type = types.attrs;
  default = {};
  description = "Deprecated: use userSettings instead.";
};

# In config:
settings = cfg.settings // cfg.userSettings;
```

This keeps existing user configs working while migrating to the shared option.

## Pitfalls

- **`extensions` is per-editor, not universal**: Do NOT add `extensions`
  to `mkEditor` base. Extension systems (VS Code, Zed, Helix) are all
  different — VS Code uses nixpkgs packages, Zed uses string names, Helix
  doesn't have traditional extensions. Each editor defines its own via
  `extraOptions`.
- **`priority` IS universal**: Every editor that registers MIME-type
  associations needs a priority. This belongs in the base `mkEditor`.
- **`extraPackages` + `listOf package` → `getSubModules` error**: When
  `cfg.extraPackages` (declared via overlay-defined mkEditor) is assigned
  to `home.packages` or `programs.*.extraPackages` (also `listOf package`),
  the module system's type-checking can fail with `attribute 'getSubModules' missing` inside NixOS+HM submodule context. **Fix**: Use fully-qualified
  types in the overlay — `types.listOf types.package` — instead of relying
  on `with types; listOf package` scope resolution. The `with` form fails
  to resolve `package` to the correct type in overlay context. Identity
  transformations (`builtins.map (x: x)`, `++ []`, `lib.flatten`) do NOT
  fix this — only fixing the type declaration at the source works.
- **`nix fmt` (alejandra) can rearrange attrs**: After writing an editor
  module, always `git diff` to check that alejandra didn't move option
  values between different program blocks. It has been observed to
  consolidate `inherit` lines across unrelated option groups.
- **Style/comments stripped by alejandra**: The formatter removes inline
  comments in some positions. Key comments should use the line-comment form
  (`# ...`) above the relevant code rather than inline (`/* ... */`).
- **`options` arg needed for stylix guard**: If the module optionally
  integrates with stylix, destructure `options` from the module arguments
  to safely check `options ? stylix && config.stylix.enable`.

## Verification

```bash
nix flake check --refresh            # eval — use --refresh to clear cached failures
nix flake check                      # subsequent runs can skip --refresh
nix build .#homeConfigurations.<user>.activationPackage
```

Use `--refresh` especially after fixing type errors, otherwise Nix returns
stale cached failures.

## Related skills

- `nix-agent-module` — same pattern for AI coding agents (analogous structure)
- `github-pr-workflow` — commit, push, PR workflow
- `plan` — planning before implementation

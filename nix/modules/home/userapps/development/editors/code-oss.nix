{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.code-oss;

  # Build VS Code profiles from extensionProfiles, filtered by activeProfiles.
  vscodeProfiles = let
    filtered = lib.filterAttrs (name: _: builtins.elem name cfg.activeProfiles) cfg.extensionProfiles;
  in
    lib.mapAttrs (_: profile: {
      inherit (profile) extensions;
    })
    filtered;
in
  with lib; {
    options.userapps.development.editors.code-oss = homelab.agentics.mkVscodeEditor {
      name = "code-oss";
      package = pkgs.vscodium;
    };

    config = mkIf cfg.enable {
      # Default editor — programs.vscode has no defaultEditor option
      home.sessionVariables = mkIf cfg.defaultEditor {
        EDITOR = "${lib.getExe cfg.package}";
        VISUAL = "${lib.getExe cfg.package}";
      };

      # Extra packages (LSP servers, formatters, linters)
      home.packages = cfg.extraPackages;

      # Delegate to upstream programs.vscode module (works with vscodium)
      programs.vscode = {
        enable = true;
        inherit (cfg) package;
        profiles = vscodeProfiles;
      };
    };
  }

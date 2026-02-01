{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.agents.gemini;
in
  with lib; {
    options.userapps.agents.gemini = {
      enable = mkEnableOption "Enable Gemini AI agent";

      overrideEditor = mkOption {
        type = types.bool;
        default = true;
        description = "Override the default editor (VSCode) with Antigravity.";
      };
    };

    config = mkMerge [
      (mkIf cfg.enable {
        home.packages = [
          pkgs.gemini-cli
        ];
      })
      (mkIf (cfg.enable && cfg.overrideEditor) {
        userapps.development.editors.vscode = {
          package = mkDefault pkgs.antigravity;
        };
      })
    ];
  }

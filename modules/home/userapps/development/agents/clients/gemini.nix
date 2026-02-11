{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.gemini;
in
  with lib; {
    options.userapps.development.agents.gemini = {
      enable = mkEnableOption "Enable Gemini AI agent";

      overrideEditor =
        mkEnableOption "Override the default editor (VSCode) with Antigravity."
        // {
          default = true;
        };
    };

    config = mkIf cfg.enable (
      mkMerge [
        {
          home.packages = [pkgs.gemini-cli];
        }
        (mkIf cfg.overrideEditor {
          # Override default editor with Antigravity
          userapps.development.editors.vscode = {
            package = mkDefault pkgs.antigravity;
          };
        })
      ]
    );
  }

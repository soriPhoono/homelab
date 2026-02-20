{
  lib,
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
          # programs.gemini-cli.enable = true;
        }
        (mkIf cfg.overrideEditor {
          # Enable Antigravity (VSCode fork with Gemini)
          # programs.antigravity.enable = true;

          # Override default editor with Antigravity
          userapps.development.editors.vscode = {
            # package = mkDefault pkgs.antigravity;
          };
        })
      ]
    );
  }

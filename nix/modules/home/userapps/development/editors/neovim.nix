/**
Neovim editor module
- Sets EDITOR/VISUAL environment variables for terminal priority
- Accepts a custom package as the neovim distribution ***

*** See: https://github.com/nix-community/kickstart-nix.nvim
*/
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.neovim;
in
  with lib; {
    options.userapps.development.editors.neovim = {
      enable = mkEnableOption "Enable neovim text editor (nvf-based)";

      package = mkOption {
        type = with types; nullOr package;
        default = null;
        description = "The neovim package to use (typically built via nvf). If null, uses pkgs.neovim-unwrapped.";
      };

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default editor. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority "nvim";
          VISUAL = mkOverride cfg.priority "nvim";
        };

        home.packages = [
          (
            if cfg.package == null
            then pkgs.neovim-unwrapped
            else cfg.package
          )
        ];
      }
    ]);
  }

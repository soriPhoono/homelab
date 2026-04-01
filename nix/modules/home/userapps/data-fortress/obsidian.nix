{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.obsidian;
in
  with lib; {
    options.userapps.data-fortress.obsidian = {
      enable = mkEnableOption "Enable Obsidian note-taking application";

      package = mkOption {
        type = types.package;
        default = pkgs.obsidian;
        description = "The Obsidian package to use.";
      };
    };

    config = mkIf cfg.enable {
      programs.obsidian.enable = true;
    };
  }

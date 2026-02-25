{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.knowledge-management.obsidian;
in
  with lib; {
    options.userapps.development.knowledge-management.obsidian = {
      enable = mkEnableOption "Enable Obsidian note-taking application";

      package = mkOption {
        type = types.package;
        default = pkgs.obsidian;
        description = "The Obsidian package to use.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [cfg.package];
    };
  }

{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.claude;
  skills = import ./skills.nix {inherit lib pkgs;};
in
  with lib; {
    options.userapps.development.agents.claude = {
      enable = mkEnableOption "Enable Claude AI agent";

      # Collections: git URLs containing skill directories
      collections = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Git URLs to skill collections (like overlays).";
      };
    };

    config = mkIf cfg.enable (
      let
        collectionSkills = foldl' (acc: url: acc // skills.fetchCollection url) {} cfg.collections;
      in {
        home.packages = [pkgs.claude-code];

        xdg.configFile =
          mapAttrs' (name: skill: {
            name = "claude-code/skills/${name}";
            value.source = skill.source;
          })
          collectionSkills;
      }
    );
  }

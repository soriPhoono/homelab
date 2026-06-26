{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;
  hermesStateDir = lib.removePrefix "~/" (
    config.programs.hermes-agent.stateDir or "~/.local/share/hermes"
  );
in
  with lib; {
    options.userapps.development.agents.hermes = builtins.removeAttrs (homelab.agentics.mkAgent {
      name = "hermes";
      package = pkgs.hermes-full;
      extraOptions = {
        enableDesktop = mkEnableOption "Enable the hermes desktop application (hermes-desktop)";

        soulDoc = mkOption {
          type = types.nullOr (types.either types.str types.path);
          default = null;
          description = ''
            Content or path to SOUL.md for the Hermes agent.
            Defines the agent's core personality and behavior.
          '';
        };

        userDoc = mkOption {
          type = types.nullOr (types.either types.str types.path);
          default = null;
          description = ''
            Content or path to USER.md for the Hermes agent.
            Provides user-specific context and preferences.
          '';
        };
      };
    }) ["context"];

    config = mkIf cfg.enable (mkMerge [
      {
        programs.hermes-agent.enable = true;

        home.packages = with pkgs; (optional cfg.enableDesktop hermes-desktop);

        xdg.desktopEntries.hermes-desktop = mkIf cfg.enableDesktop {
          name = "Hermes Desktop";
          comment = "Hermes AI Agent - Desktop UI";
          icon = "${pkgs.hermes-desktop}/share/hermes-desktop/dist/hermes.png";
          exec = "${pkgs.hermes-desktop}/bin/hermes-desktop";
          terminal = false;
          type = "Application";
          categories = ["Development" "Utility"];
          startupNotify = true;
        };

        home.file = mkMerge [
          (mkIf (cfg.soulDoc != null) {
            "${hermesStateDir}/.hermes/SOUL.md" =
              if builtins.typeOf cfg.soulDoc == "path"
              then {source = cfg.soulDoc;}
              else {text = cfg.soulDoc;};
          })

          (mkIf (cfg.userDoc != null) {
            "${hermesStateDir}/.hermes/USER.md" =
              if builtins.typeOf cfg.userDoc == "path"
              then {source = cfg.userDoc;}
              else {text = cfg.userDoc;};
          })

          (mkIf (cfg.skills != {}) (
            mapAttrs' (name: skill: {
              name = "${hermesStateDir}/.hermes/skills/${name}";
              value = {
                source = skill;
                recursive = true;
              };
            })
            cfg.skills
          ))
        ];
      }
      (mkIf (options ? sops) {})
    ]);
  }

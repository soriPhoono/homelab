{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;
  hermesStateDir = "${config.home.homeDirectory}/";
  hermesHome = "${config.home.homeDirectory}/.hermes";

  envEntries = lib.attrValues cfg.env;
  envSecrets = lib.filter (v: builtins.isAttrs v && v ? "secret") envEntries;
  envSecretNames = lib.catAttrs "secret" envSecrets;
in
  with lib; {
    options.userapps.development.agents.hermes = removeAttrs (homelab.agentics.mkAgent {
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

        env = mkOption {
          type = with types;
            attrsOf (oneOf [
              str
              (submodule {
                options = {
                  secret = mkOption {
                    type = str;
                    description = "Sops secret name to read (e.g. api/OPENROUTER_API_KEY)";
                  };
                };
              })
            ]);
          default = {};
          description = ''
            Environment variables written to ~/.hermes/.env.
            Each key is the env var name. Value is either a literal string
            or { secret = "api/SOMETHING"; } referencing a sops secret.
          '';
          example = {
            OPENROUTER_API_KEY.secret = "api/OPENROUTER_API_KEY";
            GH_TOKEN.secret = "api/GITHUB_API_KEY";
            TERMINAL_ENV = "docker";
          };
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

        home.activation.hermesEnv = config.lib.dag.entryAfter ["hermesAgentSetup"] (
          let
            managedKeys = lib.concatStringsSep "|" (lib.mapAttrsToList (name: _: "^${name}=") cfg.env);
            envLines =
              lib.mapAttrsToList (
                name: val:
                  if builtins.isAttrs val
                  then "echo \"${name}=$(cat \"${config.sops.secrets.${val.secret}.path}\")\""
                  else "echo \"${name}=${val}\""
              )
              cfg.env;
          in ''
            ${pkgs.coreutils}/bin/touch ${hermesHome}/.env
            ${pkgs.gnugrep}/bin/grep -v -E "${managedKeys}" ${hermesHome}/.env > ${hermesHome}/.env.tmp || true
            ${pkgs.coreutils}/bin/mv ${hermesHome}/.env.tmp ${hermesHome}/.env
            ${concatStringsSep "\n" envLines} >> ${hermesHome}/.env
          ''
        );
      }
      (mkIf (options ? sops && envSecretNames != []) {
        sops.secrets = genAttrs envSecretNames (_: {});
      })
    ]);
  }

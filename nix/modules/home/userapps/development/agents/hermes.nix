{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;
in
  with lib; {
    options.userapps.development.agents.hermes = homelab.agentics.mkAgent {
      name = "hermes";
      package = pkgs.hermes-full;
      extraOptions = {
        enableCli = mkEnableOption "Enable the hermes headless agent";
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

        providers = {
          opencode = {
            enable = mkEnableOption "Enable opencode zen/go providers in hermes";
          };

          search = {
            variant = mkOption {
              type = with types; enum ["exa"];
              default = "exa";
              description = ''
                The type of search provider backend
              '';
            };
          };
        };

        gateway = {
          telegram = {
            enable = mkEnableOption "Enable telegram messaging provider for hermes agent";
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops = {
          secrets =
            {
              "hermes/API_SERVER_KEY" = {};
              "api/OPENCODE_API_KEY" = mkIf cfg.providers.opencode.enable {};
              "api/EXA_API_KEY" = mkIf (cfg.providers.search.variant == "exa") {};
              "hermes/TELEGRAM_BOT_TOKEN" = mkIf cfg.gateway.telegram.enable {};
              "hermes/TELEGRAM_ALLOWED_USERS" = mkIf cfg.gateway.telegram.enable {};
            }
            // genAttrs (flatten (mapAttrsToList (_name: value: (mapAttrsToList (_name: value: value.secret) (filterAttrs (_name: value: value ? "secret") value.env)) ++ (mapAttrsToList (_name: value: value.secret) (filterAttrs (_name: value: value ? "secret") value.headers))) cfg.mcpServers)) (_name: {});
          templates."hermes/.env".content = builtins.concatStringsSep "\n" [
            ''
              API_SERVER_KEY=${config.sops.placeholder."hermes/API_SERVER_KEY"}
            ''
            (optionalString
              cfg.providers.opencode.enable
              ''
                OPENCODE_ZEN_API_KEY=${config.sops.placeholder."api/OPENCODE_API_KEY"}
                OPENCODE_GO_API_KEY=${config.sops.placeholder."api/OPENCODE_API_KEY"}
              '')
            (optionalString
              (cfg.providers.search.variant
                == "exa")
              ''
                EXA_API_KEY=${config.sops.placeholder."api/EXA_API_KEY"}
              '')
            (optionalString
              cfg.gateway.telegram.enable
              ''
                TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes/TELEGRAM_BOT_TOKEN"}
                TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."hermes/TELEGRAM_ALLOWED_USERS"}
              '')
            (concatStringsSep
              "\n"
              (map (name: ''
                  ${toUpper (baseNameOf name)}=${config.sops.placeholder.${name}}
                '')
                (flatten
                  (mapAttrsToList
                    (_name: value:
                      (mapAttrsToList
                        (_name: value: value.secret)
                        (filterAttrs
                          (_name: value: value ? "secret")
                          value.env))
                      ++ (mapAttrsToList
                        (_name: value: value.secret)
                        (filterAttrs
                          (_name: value: value ? "secret")
                          value.headers)))
                    cfg.mcpServers))))
          ];
        };

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

        programs.hermes-agent = {
          enable = cfg.enableCli;
          package = pkgs.hermes-full;
          settings = mkMerge [
            {
              worktree = true;

              streaming.enabled = true;
              stt.enabled = true;

              memory.provider = "holographic";
              web.backend = cfg.providers.search.variant;

              mcp_servers =
                mapAttrs
                (_name: desc: let
                  processedEnv =
                    mapAttrs
                    (name: value:
                      if (builtins.isAttrs value)
                      then "$${${lib.strings.toUpper name}}"
                      else value)
                    desc.env;
                  processedHeaders =
                    mapAttrs
                    (name: value:
                      if (builtins.isAttrs value)
                      then "$${${lib.strings.toUpper name}}"
                      else value)
                    desc.headers;
                in
                  removeAttrs
                  {
                    inherit (desc) command args url;
                    env = processedEnv;
                    headers = processedHeaders;
                  }
                  (
                    (
                      if desc.command == null
                      then ["command"]
                      else []
                    )
                    ++ (
                      if desc.args == []
                      then ["args"]
                      else []
                    )
                    ++ (
                      if processedEnv == {}
                      then ["env"]
                      else []
                    )
                    ++ (
                      if desc.url == null
                      then ["url"]
                      else []
                    )
                    ++ (
                      if processedHeaders == {}
                      then ["headers"]
                      else []
                    )
                  ))
                cfg.mcpServers;
            }
            (mkIf cfg.providers.opencode.enable {
              model = {
                default = "deepseek-v4-flash";
                provider = "opencode-go";
              };
            })
            cfg.userSettings
          ];
          environmentFiles = [
            config.sops.templates."hermes/.env".path
          ];
          environment = {
            API_SERVER_ENABLED = "true";
            HERMES_DESKTOP_REMOTE_URL = "http://localhost:8642";
          };
          documents = {
            "SOUL.md" = cfg.soulDoc;
            "USER.md" = cfg.userDoc;
          };
        };

        home.file = mkMerge [
          (mkIf (cfg.skills != {}) (
            mapAttrs' (name: skill: {
              name = "${config.programs.hermes-agent.stateDir}/.hermes/skills/${name}";
              value = {
                source = skill;
                recursive = true;
              };
            })
            cfg.skills
          ))
        ];
      }
    ]);
  }

{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;

  # Chromium without desktop entries — just the binary on PATH.
  # Hermes needs chromium for browser automation (agent-browser/Playwright),
  # but the full chromium package installs its .desktop file which registers
  # MIME types (x-scheme-handler/http, text/html, etc.) and can override the
  # user's chosen default browser (Zen/Firefox). We strip share/ so no
  # desktop entries or MIME associations leak into the user's session.
  chromiumNoDesktop = pkgs.runCommand "chromium-no-desktop" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.chromium}/bin/* $out/bin/
  '';

  # Profile submodule: reuses mkAgent options minus `package`
  # with soulDoc/userDoc extras (same as the main agent)
  profileOptions =
    removeAttrs (lib.homelab.agentics.mkAgent {
      name = "hermes agent profile";
      package = null;
    }) ["package"]
    // {
      soulDoc = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
        default = null;
        description = ''
          Content or path to SOUL.md for this profile.
          Defines the agent's domain-specific persona and behavior.
        '';
      };

      userDoc = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
        default = null;
        description = ''
          Content or path to USER.md for this profile.
          Provides profile-specific user context and preferences.
        '';
      };
    };

  # Derivation that generates a config.yaml for a profile, merging:
  #   1. Common MCP servers (personal/sequential-thinking, personal/obsidian)
  #   2. Profile-specific MCP servers
  #   3. Profile-specific settings
  mkProfileConfig = profileCfg:
    pkgs.writeText "config.yaml" (builtins.toJSON (
      lib.recursiveUpdate
      {
        mcp_servers =
          lib.mapAttrs
          (_name: desc: let
            processedEnv =
              lib.mapAttrs
              (name: value:
                if builtins.isAttrs value
                then "$${${lib.strings.toUpper name}}"
                else value)
              desc.env;
            processedHeaders =
              lib.mapAttrs
              (name: value:
                if builtins.isAttrs value
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
      (
        {
          mcp_servers =
            lib.mapAttrs
            (_name: desc: let
              processedEnv =
                lib.mapAttrs
                (name: value:
                  if builtins.isAttrs value
                  then "$${${lib.strings.toUpper name}}"
                  else value)
                desc.env;
              processedHeaders =
                lib.mapAttrs
                (name: value:
                  if builtins.isAttrs value
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
            profileCfg.mcpServers;
        }
        # Provider settings inherited from the main agent config
        // lib.optionalAttrs cfg.providers.opencode.enable {
          model = {
            default = "deepseek-v4-flash";
            provider = "opencode-go";
          };
        }
        // lib.optionalAttrs (cfg.providers.search.variant == "exa") {
          web.backend = "exa";
        }
      )
      // profileCfg.userSettings
    ));

  # Derivation for profile documents (SOUL.md, USER.md + any extra documents)
  mkProfileDocuments = profileCfg:
    pkgs.runCommand "hermes-profile-documents" {} (
      ''
        mkdir -p $out
      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList
        (name: value:
          if builtins.isPath value || lib.isStorePath value
          then "cp ${value} $out/${name}"
          else "cat > $out/${name} <<'HERMES_DOC_EOF'\n${value}\nHERMES_DOC_EOF")
        (lib.filterAttrs (_: v: v != null) (
          profileCfg.documents
          // (lib.optionalAttrs (profileCfg.soulDoc or null != null) {"SOUL.md" = profileCfg.soulDoc;})
          // (lib.optionalAttrs (profileCfg.userDoc or null != null) {"USER.md" = profileCfg.userDoc;})
        ))
      )
    );
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

          matrix = {
            enable = mkEnableOption "Enable matrix messaging provider for hermes agent";
          };
        };

        profiles = mkOption {
          type = types.attrsOf (types.submodule (_: {
            options = profileOptions;
          }));
          default = {};
          description = ''
            Additional Hermes agent profiles for domain-specific subagents.
            Each profile gets its own state directory under $HERMES_HOME/profiles/<name>/
            with config.yaml, .env, SOUL.md, memory, sessions, and skills.
            Common MCP servers (personal/sequential-thinking, personal/obsidian)
            are merged into every profile's config.yaml automatically.
          '';
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
              "hermes/TELEGRAM_HOME_CHANNEL" = mkIf cfg.gateway.telegram.enable {};
              "hermes/MATRIX_HOMESERVER" = mkIf cfg.gateway.matrix.enable {};
              "hermes/MATRIX_ACCESS_TOKEN" = mkIf cfg.gateway.matrix.enable {};
              "hermes/MATRIX_ALLOWED_USERS" = mkIf cfg.gateway.matrix.enable {};
              "hermes/MATRIX_ALLOWED_ROOMS" = mkIf cfg.gateway.matrix.enable {};
              "hermes/MATRIX_HOME_ROOM" = mkIf cfg.gateway.matrix.enable {};
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
                TELEGRAM_HOME_CHANNEL=${config.sops.placeholder."hermes/TELEGRAM_HOME_CHANNEL"}
              '')
            (optionalString
              cfg.gateway.matrix.enable
              ''
                MATRIX_HOMESERVER=${config.sops.placeholder."hermes/MATRIX_HOMESERVER"}
                MATRIX_ACCESS_TOKEN=${config.sops.placeholder."hermes/MATRIX_ACCESS_TOKEN"}
                MATRIX_ALLOWED_USERS=${config.sops.placeholder."hermes/MATRIX_ALLOWED_USERS"}
                MATRIX_ALLOWED_ROOMS=${config.sops.placeholder."hermes/MATRIX_ALLOWED_ROOMS"}
                MATRIX_HOME_ROOM=${config.sops.placeholder."hermes/MATRIX_HOME_ROOM"}
                MATRIX_E2EE_MODE=required
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

        # Chromium's desktop entry was intentionally omitted (chromiumNoDesktop
        # above has no share/ directory), but if any chromium desktop entry is
        # found via other paths (e.g. system packages), explicitly remove its
        # MIME associations so it can never compete for default browser.
        xdg.mimeApps.associations.removed = {
          "x-scheme-handler/http" = ["chromium-browser.desktop"];
          "x-scheme-handler/https" = ["chromium-browser.desktop"];
          "x-scheme-handler/chromium" = ["chromium-browser.desktop"];
          "text/html" = ["chromium-browser.desktop"];
          "application/xhtml+xml" = ["chromium-browser.desktop"];
        };

        programs.hermes-agent = {
          enable = cfg.enableCli;
          package = pkgs.hermes-full;
          extraPackages = [
            pkgs.agent-browser
            chromiumNoDesktop
          ];
          settings = mkMerge [
            {
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

            (mkIf cfg.gateway.telegram.enable {
              gateway.platforms.telegram.extra = {
                status_indicator = true;
                status_online = "🟢 Online";
                status_offline = "🔴 Offline";
              };
            })

            cfg.userSettings
          ];
          environmentFiles = [
            config.sops.templates."hermes/.env".path
          ];
          environment = {
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
      # Auto-generate a Hermes CLI skin from Stylix base16 colors
      (mkIf (options ? stylix && config.stylix.enable) {
        home.file."${config.programs.hermes-agent.stateDir}/.hermes/skins/stylix.yaml" = let
          c = config.lib.stylix.colors;
        in {
          text = ''
            name: stylix
            description: Auto-generated skin from Stylix base16 scheme

            colors:
              banner_border: "#${c.base0D}"
              banner_title: "#${c.base0D}"
              banner_accent: "#${c.base0A}"
              banner_dim: "#${c.base03}"
              banner_text: "#${c.base05}"
              ui_accent: "#${c.base0D}"
              ui_label: "#${c.base0C}"
              ui_ok: "#${c.base0B}"
              ui_error: "#${c.base08}"
              ui_warn: "#${c.base09}"
              prompt: "#${c.base05}"
              input_rule: "#${c.base03}"
              response_border: "#${c.base0D}"
              session_label: "#${c.base0A}"
              session_border: "#${c.base03}"
              status_bar_bg: "#${c.base01}"
              voice_status_bg: "#${c.base01}"
              selection_bg: "#${c.base02}"
              completion_menu_bg: "#${c.base00}"
              completion_menu_current_bg: "#${c.base02}"
              completion_menu_meta_bg: "#${c.base00}"
              completion_menu_meta_current_bg: "#${c.base02}"
          '';
        };

        programs.hermes-agent.settings.display.skin = mkDefault "stylix";
      })

      # ── Profile generation ────────────────────────────────────────────
      (mkIf (cfg.profiles != {}) (let
        profilesDir = "${config.programs.hermes-agent.stateDir}/.hermes/profiles";
      in
        mkMerge [
          # sops secrets: collect all MCP server secrets across profiles
          {
            sops.secrets = genAttrs (flatten (
              mapAttrsToList (_profileName: profileCfg:
                mapAttrsToList (_serverName: server:
                  (mapAttrsToList (_name: value: value.secret) (filterAttrs (_name: value: value ? "secret") server.env))
                  ++ (mapAttrsToList (_name: value: value.secret) (filterAttrs (_name: value: value ? "secret") server.headers)))
                profileCfg.mcpServers)
              (filterAttrs (_: p: p.enable) cfg.profiles)
            )) (_: {});
          }

          # sops templates: one .env per profile, deployed directly to profile dir
          {
            sops.templates = listToAttrs (
              mapAttrsToList (profileName: profileCfg:
                nameValuePair "hermes/profiles/${profileName}.env" {
                  content = builtins.concatStringsSep "\n" (
                    [
                      # Global provider keys inherited by all profiles
                      (optionalString cfg.providers.opencode.enable ''
                        OPENCODE_ZEN_API_KEY=${config.sops.placeholder."api/OPENCODE_API_KEY"}
                        OPENCODE_GO_API_KEY=${config.sops.placeholder."api/OPENCODE_API_KEY"}
                      '')
                      (optionalString (cfg.providers.search.variant == "exa") ''
                        EXA_API_KEY=${config.sops.placeholder."api/EXA_API_KEY"}
                      '')
                    ]
                    ++ flatten (
                      mapAttrsToList (_serverName: desc:
                        mapAttrsToList (envName: envValue:
                          if builtins.isAttrs envValue && envValue ? "secret"
                          then "${toUpper envName}=${config.sops.placeholder.${envValue.secret}}"
                          else "")
                        desc.env or {})
                      profileCfg.mcpServers
                    )
                  );
                  path = "${profilesDir}/${profileName}/.env";
                  mode = "0640";
                })
              (filterAttrs (_: p: p.enable) cfg.profiles)
            );
          }

          # home.file: profile config.yaml, SOUL.md, skills (not .env)
          {
            home.file = mkMerge (
              mapAttrsToList (profileName: profileCfg:
                mkMerge [
                  # config.yaml
                  {"${profilesDir}/${profileName}/config.yaml".source = mkProfileConfig profileCfg;}
                  # SOUL.md / USER.md + any documents
                  (let
                    allDocs =
                      (optionalAttrs (profileCfg.soulDoc or null != null) {"SOUL.md" = profileCfg.soulDoc;})
                      // (optionalAttrs (profileCfg.userDoc or null != null) {"USER.md" = profileCfg.userDoc;})
                      // profileCfg.documents;
                  in
                    mkIf (allDocs != {}) (
                      mapAttrs' (docName: _docValue: {
                        name = "${profilesDir}/${profileName}/${docName}";
                        value = {
                          source = "${mkProfileDocuments profileCfg}/${docName}";
                        };
                      })
                      allDocs
                    ))
                  # Skills
                  (mkIf (profileCfg.skills != {}) (
                    mapAttrs' (skillName: skill: {
                      name = "${profilesDir}/${profileName}/skills/${skillName}";
                      value = {
                        source = skill;
                        recursive = true;
                      };
                    })
                    profileCfg.skills
                  ))
                ]) (filterAttrs (_: p: p.enable) cfg.profiles)
            );
          }

          # home.activation: create required runtime directories for each profile
          {
            home.activation.hermesProfileDirs = lib.hm.dag.entryAfter ["writeBoundary"] (
              lib.concatStringsSep "\n" (
                mapAttrsToList (profileName: _profileCfg: ''
                  mkdir -p ${profilesDir}/${profileName}/{cron,sessions,logs,memories}
                '') (filterAttrs (_: p: p.enable) cfg.profiles)
              )
            );
          }
        ]))
    ]);
  }

{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.apps.development.agents.hermes;

  providerOptions = {
    models = {
      opencode = {
        zen = {
          enable = mkEnableOption "Enable OpenCode Zen AI provider integration";
          default = mkEnableOption ''
            Set this to true to enable OpenCode Zen AI provider integration as the default provider for hermes agents.
          '';
          model = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "gemini-3.5-flash";
            description = "The model to use for the OpenCode Zen AI provider.";
          };
        };
        go = {
          enable = mkEnableOption "Enable OpenCode Go AI provider integration";
          default = mkEnableOption ''
            Set this to true to enable OpenCode Go AI provider integration as the default provider for hermes agents.
          '';
          model = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "glm-5.2";
            description = "The model to use for the OpenCode Go AI provider.";
          };
        };
      };

      ollama = {
        enable = mkEnableOption "Enable ollama provider for hermes agents";
        useCloudModels = mkEnableOption "Enable ollama cloud provider api key integration for hermes agents";
      };
    };

    memory = {
      variant = mkOption {
        type = types.nullOr (types.enum ["honcho" "holographic"]);
        default = null;
        description = "The memory variant to use for hermes agent.";
      };
    }; # TODO: configure honcho memory server configuration

    search = {
      variant = mkOption {
        type = types.nullOr (types.enum ["firecrawl" "searxng" "brave-free" "ddgs" "tavily" "exa" "parallel" "xai"]);
        default = null;
        example = "brave";
        description = "The search engine to use for hermes agent.";
      };

      firecrawl.enable = mkEnableOption "Enable firecrawl search for hermes agent";
      searxng = {
        enable = mkEnableOption "Enable searxng search for hermes agent";
        baseUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The base url of the searxng instance for this profile";
        };
      };
      brave.enable = mkEnableOption "Enable brave search for hermes agent";
      ddgs.enable = mkEnableOption "Enable ddgs search for hermes agent";
      tavily.enable = mkEnableOption "Enable tavily search for hermes agent";
      exa.enable = mkEnableOption "Enable exa search for hermes agent";
      parallel.enable = mkEnableOption "Enable parallel search for hermes agent";
      xai.enable = mkEnableOption "Enable xAI search for hermes agent";
    };
  };

  hermesPackage = pkgs.symlinkJoin {
    name = "${cfg.package.name or "hermes"}-wrapped";
    paths = [cfg.package];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for bin in $out/bin/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          wrapArgs=(
            --set-default HERMES_HOME "${stateDir}"
            --set HERMES_MANAGED true
          )
          ${optionalString (cfg.extraPackages != []) ''
        wrapArgs+=(--prefix PATH : "${lib.makeBinPath cfg.extraPackages}")
      ''}
          wrapProgram "$bin" "''${wrapArgs[@]}"
        fi
      done
    '';
  };

  stateDir = "${config.home.homeDirectory}/.hermes";

  profileDir = profileName:
    if profileName == "default"
    then stateDir
    else "${stateDir}/profiles/${profileName}";

  # Create folder structure for hermes profiles
  mkProfileFolders = pDir: ''
    mkdir -p ${pDir}/
    mkdir -p ${pDir}/cron
    mkdir -p ${pDir}/sessions
    mkdir -p ${pDir}/logs
    mkdir -p ${pDir}/memories
  '';

  # Create profile config.yaml
  mkConfigFile = profileName: profileConfig:
    pkgs.writeText "hermes-config-${profileName}.yaml"
    (builtins.toJSON (cfg.userSettings // profileConfig.userSettings));

  mkConfig = profileName: profile: ''
    CONFIG_FILE="${profileDir profileName}/config.yaml"

    cp -rL ${mkConfigFile profileName profile} "$CONFIG_FILE"
    chmod 0640 "$CONFIG_FILE"
  '';

  baseEnvironment = _profileName: profileCfg:
    concatStringsSep
    "\n"
    (mapAttrsToList
      (key: value: "${key}=${value}")
      (cfg.environment // profileCfg.environment));

  mkEnvBase = profileName: profileCfg: ''
    # Set profile specific environment variables
    ENV_FILE="${profileDir profileName}/.env"
    install -m 0640 /dev/null "$ENV_FILE"
    cat > "$ENV_FILE" <<HERMES_NIX_ENV_${toUpper profileName}_EOF
    ${baseEnvironment profileName profileCfg}
    HERMES_NIX_ENV_${toUpper profileName}_EOF
  '';

  mkDocuments = profileName: profileCfg: let
    targetDir = profileDir profileName;
    docDestinations = {
      soul = "SOUL.md";
      user = "memories/USER.md";
      memory = "memories/MEMORY.md";
    };
  in
    concatStringsSep "\n"
    (mapAttrsToList
      (
        name: document:
          optionalString (document != null && document != "")
          "cp -rL ${document} ${targetDir}/${docDestinations.${name}}; chmod 0640 ${targetDir}/${docDestinations.${name}}"
      )
      profileCfg.documents);

  profileSubmodule = types.submodule ({
    name,
    config,
    ...
  }: {
    options =
      (removeAttrs (lib.homelab.developmentent.mkAgent {
        inherit name;
        package = null;
        extraOptions = {
          repo = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Optional path to the profile repository, if null declarative configuration will be used.";
            example = lib.literalExpression ''
              pkgs.fetchFromGitHub {
                owner = "<username>";
                repo = "<repository-name>";
                rev = "<revision>";
                hash = "<hash>";
              };
            '';
          };

          providers = providerOptions;

          gateway = {
            telegram = {
              enable = mkEnableOption "Enable telegram gateway for this profile";

              botToken = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "The sops secret name containing the telegram bot token for this profile.";
              };

              allowList = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "List of telegram chat ids to allow access to this profile";
              };
            };
          }; # TODO: Finish implementing this

          documents = {
            soul = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                Path to a soul file for the hermes agent, this will be symlinked to the agent workspace at 'SOUL.md'.
              '';
            };

            user = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                An optional initial USER.md file for the hermes agent, this will be copied to the agent workspace at 'memories/USER.md' in a form the agent can later alter.
              '';
            };

            memory = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                An optional initial MEMORY.md file for the hermes agent, this will be copied to the agent workspace at 'memories/MEMORY.md' in a form the agent can later alter.
              '';
            };
          };
        };
      }) ["enable" "package"])
      // {
        enable =
          (mkEnableOption "Enable this agent profile")
          // {
            default = true;
          };
      };

    config = mkMerge [
      (let
        mcpServers = cfg.mcpServers // config.mcpServers;
      in {
        secrets = let
          mcpSecrets = concatLists (mapAttrsToList (
              _: server:
                (mapAttrsToList (_: value: value.secret) (filterAttrs (_: value: value ? secret) (
                  if server.env != null
                  then server.env
                  else {}
                )))
                ++ (mapAttrsToList (_: value: value.secret) (filterAttrs (_: value: value ? secret) (
                  if server.headers != null
                  then server.headers
                  else {}
                )))
            )
            config.mcpServers);
          searchSecrets =
            optional config.providers.search.firecrawl.enable "api/FIRECRAWL_API_KEY"
            ++ optional config.providers.search.brave.enable "api/BRAVE_SEARCH_API_KEY"
            ++ optional config.providers.search.tavily.enable "api/TAVILY_API_KEY"
            ++ optional config.providers.search.exa.enable "api/EXA_API_KEY"
            ++ optional config.providers.search.parallel.enable "api/PARALLEL_API_KEY"
            ++ optional config.providers.search.xai.enable "api/XAI_API_KEY";
        in
          unique (mcpSecrets ++ searchSecrets);

        userSettings = {
          mcp_servers =
            lib.mapAttrs (
              _: server:
                (lib.optionalAttrs (server.command != null) {inherit (server) command;})
                // (lib.optionalAttrs (server.args != null) {inherit (server) args;})
                // (lib.optionalAttrs (server.env != null) {
                  env = mapAttrs (_: value:
                    if value ? secret
                    then "\${${baseNameOf value.secret}}"
                    else value)
                  server.env;
                })
                // (lib.optionalAttrs (server.url != null) {inherit (server) url;})
                // (lib.optionalAttrs (server.headers != null) {
                  headers = mapAttrs (_: value:
                    if value ? secret
                    then "\${${baseNameOf value.secret}}"
                    else value)
                  server.headers;
                })
            )
            mcpServers;

          streaming.enabled = true;
          stt.enabled = true;
        };
      })
      (mkIf (config.providers.memory.variant != null || cfg.providers.memory.variant != null) {
        userSettings = {
          memory.provider =
            if config.providers.memory.variant != null
            then config.providers.memory.variant
            else cfg.providers.memory.variant;
        };
      })
      (mkIf (config.providers.search.variant != null || cfg.providers.search.variant != null) {
        userSettings = {
          web.backend =
            if config.providers.search.default != null
            then config.providers.search.default
            else cfg.providers.search.default;
        };
      })
      (mkIf (config.providers.models.opencode.go.default || cfg.providers.models.opencode.go.default) {
        userSettings = {
          model = {
            provider = "opencode-go";
            model =
              if config.providers.models.opencode.go.model != null
              then config.providers.models.opencode.go.model
              else cfg.providers.models.opencode.go.model;
          };
        };
      })
      (mkIf (config.providers.models.opencode.zen.default || cfg.providers.models.opencode.zen.default) {
        userSettings = {
          model = {
            provider = "opencode-zen";
            model =
              if config.providers.models.opencode.zen.model != null
              then config.providers.models.opencode.zen.model
              else cfg.providers.models.opencode.zen.model;
          };
        };
      })
    ];
  });
in {
  # Installs cli tooling with global enable option, extra features get added with other options
  options.apps.development.agents.hermes = mkOption {
    type = types.submodule ({config, ...}: {
      options = homelab.development.mkAgent {
        name = "hermes";
        package = pkgs.hermes;
        extraOptions = {
          enableCli = mkEnableOption "Enable cli integration for hermes agent";
          enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

          providers = providerOptions;

          profiles = mkOption {
            type = types.attrsOf profileSubmodule;
            default = {};
            description = "Profiles for the Hermes agent.";
          };
        };
      };

      config = mkMerge [
        {
          secrets = unique (flatten ((mapAttrsToList (
                _: server:
                  (
                    mapAttrsToList (_: value: value.secret) (filterAttrs (_: value: value ? secret) (
                      if server.env != null
                      then server.env
                      else {}
                    ))
                  )
                  ++ (
                    mapAttrsToList (_: value: value.secret) (filterAttrs (_: value: value ? secret) (
                      if server.headers != null
                      then server.headers
                      else {}
                    ))
                  )
              )
              config.mcpServers)
            ++ (
              (optional config.providers.search.firecrawl.enable "api/FIRECRAWL_API_KEY")
              ++ (optional config.providers.search.brave.enable "api/BRAVE_SEARCH_API_KEY")
              ++ (optional config.providers.search.tavily.enable "api/TAVILY_API_KEY")
              ++ (optional config.providers.search.exa.enable "api/EXA_API_KEY")
              ++ (optional config.providers.search.parallel.enable "api/PARALLEL_API_KEY")
              ++ (optional config.providers.search.xai.enable "api/XAI_API_KEY")
            )));
        }
      ];
    });
  };

  config = mkIf cfg.enable (mkMerge [
    # Install core cli package and set environment variables
    (mkIf cfg.enableCli {
      home.packages = [hermesPackage];

      core.shells = {
        fish.interactiveShellInitExtra = ''
          # Set fish completions for hermes
          ${hermesPackage}/bin/hermes completion fish | source
        '';
      };
    })

    # Install desktop integration for hermes agent
    (mkIf cfg.enableDesktop {
      # Install hermes-desktop
      home.packages = [pkgs.hermes-desktop];

      # Setup desktop entry for hermes-desktop
      xdg.desktopEntries.hermes-desktop = {
        name = "Hermes Desktop";
        comment = "Hermes AI Agent - Desktop UI";
        icon = "${pkgs.hermes-desktop}/share/hermes-desktop/dist/hermes.png";
        exec = "${pkgs.hermes-desktop}/bin/hermes-desktop";
        terminal = false;
        type = "Application";
        categories = ["Development" "Utility"];
        startupNotify = true;
      };
    })

    # Load in all secrets from all profiles in central agent execution for simplicity
    {
      sops.secrets = let
        allSecrets = unique (cfg.secrets ++ (concatLists (mapAttrsToList (_name: profileCfg: profileCfg.secrets) cfg.profiles)));
      in
        genAttrs allSecrets (_: {});

      # Generate activation scripts for all enabled profiles
      home.activation = foldl' (
        acc: profileName: let
          profileCfg = cfg.profiles.${profileName};
        in
          if profileCfg.enable
          then
            acc
            // {
              "hermes-agent-${profileName}-setup" = lib.hm.dag.entryAfter ["writeBoundary"] ''
                # Ensure directories exist for hermes agent startup (${profileName} profile)
                ${mkProfileFolders (profileDir profileName)}

                # Write managed flag
                echo "" > ${profileDir profileName}/.managed

                # Install config.yaml for profile
                ${mkConfig profileName profileCfg}

                # Create base environment file
                ${mkEnvBase profileName profileCfg}

                # Link documents into profile
                ${mkDocuments profileName profileCfg}
              '';
            }
          else acc
      ) {} (attrNames cfg.profiles);

      # Generate skill files for all enabled profiles
      home.file = foldl' (
        acc: profileName: let
          profileCfg = cfg.profiles.${profileName};
        in
          if profileCfg.enable
          then
            acc
            // (mapAttrs' (name: skill: {
              name = "${profileDir profileName}/skills/${name}";
              value = {
                source = skill;
                recursive = true;
              };
            }) (cfg.skills // profileCfg.skills))
          else acc
      ) {} (attrNames cfg.profiles);

      # Generate systemd services for all enabled profiles (Linux only)
      systemd.user.services = foldl' (
        acc: profileName: let
          profileCfg = cfg.profiles.${profileName};
        in
          if profileCfg.enable && pkgs.stdenv.hostPlatform.isLinux
          then
            acc
            // {
              "hermes-agent-${profileName}" = {
                Unit = {
                  Description = "Hermes AI Agent (${profileName} profile)";
                  After = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || profileCfg.secrets != []) "sops-nix.service";
                  Wants = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || profileCfg.secrets != []) "sops-nix.service";
                };
                Service = let
                  servicePath = lib.makeBinPath [
                    hermesPackage
                    pkgs.bash
                    pkgs.coreutils
                    pkgs.git
                  ];

                  # This script writes this agent's secrets and all global secrets to the profile agent .env file
                  envSeedScript = pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
                    ENV_FILE="${profileDir profileName}/.env"
                    ${optionalString (cfg.providers.models.opencode.zen.enable || profileCfg.providers.models.opencode.zen.enable) ''
                      printf "OPENCODE_ZEN_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" | tee -a "$ENV_FILE"
                    ''}
                    ${optionalString (cfg.providers.models.opencode.go.enable || profileCfg.providers.models.opencode.go.enable) ''
                      printf "OPENCODE_GO_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" | tee -a "$ENV_FILE"
                    ''}
                    ${concatStringsSep "\n" (
                      map (f: ''
                        printf "${baseNameOf f}=%s\n" "$(cat ${config.sops.secrets."${f}".path})" | tee -a "$ENV_FILE"
                      '')
                      (unique (cfg.secrets ++ profileCfg.secrets))
                    )}
                  '';
                in
                  lib.mkMerge [
                    {
                      Environment = [
                        "HOME=${config.home.homeDirectory}"
                        "HERMES_HOME=${profileDir profileName}"
                        "HERMES_MANAGED=true"
                        ("PATH=" + servicePath + "\${PATH:+:$PATH}")
                      ];

                      ExecStart = lib.concatStringsSep " " [
                        "${hermesPackage}/bin/hermes"
                        "gateway"
                      ];

                      Restart = "always";
                      RestartSec = 5;
                    }
                    (lib.mkIf (cfg.secrets != [] || profileCfg.secrets != []) {
                      ExecStartPre = "${envSeedScript}";
                    })
                  ];
                Install.WantedBy = ["default.target"];
              };
            }
          else acc
      ) {} (attrNames cfg.profiles);
    }
  ]);
}

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
            --set-default HERMES_HOME "${foregroundStateDir}"
            --set HERMES_MANAGED true
            --set-default HERMES_DOCKER_BINARY "podman"
          )
          ${optionalString (cfg.extraPackages != []) ''
        wrapArgs+=(--prefix PATH : "${lib.makeBinPath cfg.extraPackages}")
      ''}
          wrapProgram "$bin" "''${wrapArgs[@]}"
        fi
      done
    '';
  };

  foregroundStateDir = "${config.home.homeDirectory}/.hermes";
  backgroundStateDir = "${config.home.homeDirectory}/.local/share/hermes";

  profileDir = profileName: let
    profile = cfg.profiles.${profileName};
    directory = prefix:
      if profileName == "default"
      then "${prefix}"
      else "${prefix}/profiles/${profileName}";
  in
    if (elem profile.type ["foreground" "hybrid"])
    then directory foregroundStateDir
    else directory backgroundStateDir;

  # Create folder structure for hermes profiles
  mkProfileFolders = pDir: ''
    mkdir -p ${pDir}/
    chmod 0700 ${pDir}/
    mkdir -p ${pDir}/cron
    mkdir -p ${pDir}/sessions
    mkdir -p ${pDir}/logs
    mkdir -p ${pDir}/memories
  '';

  # Create profile config.yaml
  mkConfigFile = profileName: profileCfg:
    pkgs.writeText "hermes-config-${profileName}.yaml"
    (builtins.toJSON (cfg.userSettings // profileCfg.userSettings));

  mkConfig = profileName: profileCfg: ''
    CONFIG_FILE="${profileDir profileName}/config.yaml"

    cp -rL ${mkConfigFile profileName profileCfg} "$CONFIG_FILE"
    chmod 0600 "$CONFIG_FILE"
  '';

  mapTerminalConfigToEnv = userSettings: let
    mapping = {
      backend = "TERMINAL_ENV";
      modal_mode = "TERMINAL_MODAL_MODE";
      cwd = "TERMINAL_CWD";
      timeout = "TERMINAL_TIMEOUT";
      lifetime_seconds = "TERMINAL_LIFETIME_SECONDS";
      docker_image = "TERMINAL_DOCKER_IMAGE";
      docker_forward_env = "TERMINAL_DOCKER_FORWARD_ENV";
      singularity_image = "TERMINAL_SINGULARITY_IMAGE";
      modal_image = "TERMINAL_MODAL_IMAGE";
      daytona_image = "TERMINAL_DAYTONA_IMAGE";
      ssh_host = "TERMINAL_SSH_HOST";
      ssh_user = "TERMINAL_SSH_USER";
      ssh_port = "TERMINAL_SSH_PORT";
      ssh_key = "TERMINAL_SSH_KEY";
      container_cpu = "TERMINAL_CONTAINER_CPU";
      container_memory = "TERMINAL_CONTAINER_MEMORY";
      container_disk = "TERMINAL_CONTAINER_DISK";
      container_persistent = "TERMINAL_CONTAINER_PERSISTENT";
      docker_volumes = "TERMINAL_DOCKER_VOLUMES";
      docker_env = "TERMINAL_DOCKER_ENV";
      docker_mount_cwd_to_workspace = "TERMINAL_DOCKER_MOUNT_CWD_TO_WORKSPACE";
      docker_network = "TERMINAL_DOCKER_NETWORK";
      docker_extra_args = "TERMINAL_DOCKER_EXTRA_ARGS";
      docker_run_as_host_user = "TERMINAL_DOCKER_RUN_AS_HOST_USER";
      docker_persist_across_processes = "TERMINAL_DOCKER_PERSIST_ACROSS_PROCESSES";
      docker_orphan_reaper = "TERMINAL_DOCKER_ORPHAN_REAPER";
      sandbox_dir = "TERMINAL_SANDBOX_DIR";
      persistent_shell = "TERMINAL_PERSISTENT_SHELL";
    };
    formatValue = val:
      if builtins.isList val || builtins.isAttrs val
      then builtins.toJSON val
      else if builtins.isBool val
      then
        (
          if val
          then "true"
          else "false"
        )
      else toString val;
    mapped = lib.mapAttrs' (key: envVar: {
      name = envVar;
      value = formatValue userSettings.${key};
    }) (lib.filterAttrs (key: _: userSettings ? ${key}) mapping);
  in
    mapped;

  baseEnvironment = _profileName: profileCfg: let
    terminalEnv = mapTerminalConfigToEnv (cfg.userSettings // profileCfg.userSettings);
    mergedEnv = cfg.environment // profileCfg.environment // terminalEnv;
  in
    concatStringsSep
    "\n"
    (mapAttrsToList
      (key: value: "${key}=${value}")
      mergedEnv);

  mkEnvBase = profileName: profileCfg: ''
    # Set profile specific environment variables
    ENV_FILE="${profileDir profileName}/.env"
    install -m 0600 /dev/null "$ENV_FILE"
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
      (removeAttrs (lib.homelab.development.mkAgent {
        inherit name;
        package = null;
        extraOptions = {
          type = mkOption {
            type = types.enum ["foreground" "hybrid" "background"];
            default = "foreground";
            description = ''
              This controls the agent's deployment mode:
                - `foreground`: The agent is deployed in the foreground,
                    will be available via the desktop/cli as a profile
                    accessable with a local execution environment (not sandboxed in podman).
                    HERMES_HOME will be set to ~/.hermes.
                - `hybrid`: The agent is deployed in the foreground,
                    will be available via the desktop/cli as a profile
                    accessable with a docker based execution environment (sandboxed in podman).
                    And will be available via a systemd service as a messaging gateway.
                - `background`: The agent is deployed in the background,
                    will not be available via the desktop/cli as a profile,
                    but instead will be run in podman as a standalone sandboxed
                    agent with a docker container as it's tool environment for persistence,
                    use this option if you want to hook a bot up to a messaging platform as a standalone autonomous agent.
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

          permissions = {
            accessDirectories = mkOption {
              type = types.listOf types.path;
              default = [];
              description = ''
                A list of directories that the hermes agent should have read-write access to.
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

        mcpServers.filesystem = mkIf (config.type == "foreground") (mkForce {
          command = "${pkgs.nodejs}/bin/npx";
          args =
            [
              "-y"
              "@modelcontextprotocol/server-filesystem"
            ]
            ++ config.permissions.accessDirectories;
        });

        userSettings = mkMerge [
          {
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
                      then "${value.prefix}\${${baseNameOf value.secret}}${value.suffix}"
                      else value)
                    server.headers;
                  })
              )
              mcpServers;

            streaming.enabled = true;
            stt.enabled = true;
          }
          (mkIf (config.type == "hybrid") {
            backend = "docker";
            docker_image = "nikolaik/python-nodejs:python3.11-nodejs20";
            docker_mount_cwd_to_workspace = true;
            docker_run_as_host_user = false;
            docker_forward_env = [
              "GITHUB_TOKEN"
            ];
            docker_env = {
              #
            };
            docker_volumes =
              map (
                value: "${value}:/workspace/${baseNameOf value}"
              )
              config.permissions.accessDirectories;
            docker_extra_args = [
              "--network=hermes-agent-${name}"
            ];
            docker_network = true;

            container_cpu = 0;
            container_memory = 8192;
            container_disk = 51200;
            container_persistent = true;

            docker_persist_across_processes = true;
            docker_orphan_reaper = true;

            timeout = 180;
            lifetime_seconds = 300;
          })
        ];
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

          profiles.default.type = "foreground";
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
      systemd.user.services =
        (foldl' (
          acc: profileName: let
            profileCfg = cfg.profiles.${profileName};
          in
            if profileCfg.enable && pkgs.stdenv.hostPlatform.isLinux
            then
              acc
              // {
                "hermes-agent-${profileName}" = {
                  Unit = {
                    Description = "Hermes AI Agent (${profileName} profile) (oneshot) - Generates environment variables from sops secrets";
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
                      set -euo pipefail
                      ENV_FILE="${profileDir profileName}/.env"
                      mkdir -p "$(dirname "$ENV_FILE")"
                      chmod 0700 "$(dirname "$ENV_FILE")"
                      : > "$ENV_FILE"
                      chmod 0600 "$ENV_FILE"
                      ${optionalString (cfg.providers.models.opencode.zen.enable || profileCfg.providers.models.opencode.zen.enable) ''
                        printf "OPENCODE_ZEN_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" >> "$ENV_FILE"
                      ''}
                      ${optionalString (cfg.providers.models.opencode.go.enable || profileCfg.providers.models.opencode.go.enable) ''
                        printf "OPENCODE_GO_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" >> "$ENV_FILE"
                      ''}
                      ${concatStringsSep "\n" (
                        map (f: ''
                          printf "${baseNameOf f}=%s\n" "$(cat ${config.sops.secrets."${f}".path})" >> "$ENV_FILE"
                        '')
                        (unique (cfg.secrets ++ profileCfg.secrets))
                      )}
                    '';
                  in {
                    Type = "oneshot";

                    Environment = [
                      "HOME=${config.home.homeDirectory}"
                      "HERMES_HOME=${profileDir profileName}"
                      "HERMES_MANAGED=true"
                      "PATH=${servicePath}"
                    ];

                    ExecStart = ''
                      ${envSeedScript}
                    '';

                    # Security hardening
                    UMask = "0077";
                    NoNewPrivileges = true;
                    RestrictSUIDSGID = true;
                    ProtectSystem = "full";
                  };
                  Install.WantedBy = ["default.target"];
                };
              }
            else acc
        ) {} (attrNames (filterAttrs (_name: profile: profile.type == "foreground") cfg.profiles)))
        // (foldl' (
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
                      pkgs.podman
                      "/run/wrappers"
                      "/run/current-system/sw"
                      config.home.profileDirectory
                    ];

                    # This script writes this agent's secrets and all global secrets to the profile agent .env file
                    envSeedScript = pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
                      set -euo pipefail
                      ENV_FILE="${profileDir profileName}/.env"
                      mkdir -p "$(dirname "$ENV_FILE")"
                      chmod 0700 "$(dirname "$ENV_FILE")"
                      cat << 'HERMES_NIX_ENV_EOF' > "$ENV_FILE"
                      ${baseEnvironment profileName profileCfg}
                      HERMES_NIX_ENV_EOF
                      chmod 0600 "$ENV_FILE"
                      ${optionalString (cfg.providers.models.opencode.zen.enable || profileCfg.providers.models.opencode.zen.enable) ''
                        printf "OPENCODE_ZEN_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" >> "$ENV_FILE"
                      ''}
                      ${optionalString (cfg.providers.models.opencode.go.enable || profileCfg.providers.models.opencode.go.enable) ''
                        printf "OPENCODE_GO_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" >> "$ENV_FILE"
                      ''}
                      ${concatStringsSep "\n" (
                        map (f: ''
                          printf "${baseNameOf f}=%s\n" "$(cat ${config.sops.secrets."${f}".path})" >> "$ENV_FILE"
                        '')
                        (unique (cfg.secrets ++ profileCfg.secrets))
                      )}

                      if ! podman network exists "hermes-agent-${profileName}"; then
                        podman network create "hermes-agent-${profileName}"
                      fi
                    '';
                  in
                    lib.mkMerge [
                      {
                        Environment = [
                          "HOME=${config.home.homeDirectory}"
                          "HERMES_HOME=${profileDir profileName}"
                          "HERMES_MANAGED=true"
                          "PATH=${servicePath}"
                        ];

                        ExecStart = lib.concatStringsSep " " [
                          "${hermesPackage}/bin/hermes"
                          "gateway"
                        ];

                        Restart = "always";
                        RestartSec = 5;

                        # Security hardening
                        UMask = "0077";
                      }
                      (lib.mkIf (cfg.secrets != [] || profileCfg.secrets != []) {
                        ExecStartPre = "${envSeedScript}";
                      })
                    ];
                  Install.WantedBy = ["default.target"];
                };
              }
            else acc
        ) {} (attrNames (filterAttrs (_name: profile: profile.type == "hybrid") cfg.profiles)));
    }
  ]);
}

{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.apps.development.agents.hermes;

  providerOptions = {
    sopsFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Used to create system specific agents, when set will override the default secrets
        file located in the user core configuration directory
      '';
    };

    models = {
      openrouter = {
        enable = mkEnableOption "Enable OpenRouter AI provider integration";
        default = mkEnableOption ''
          Set this to true to enable OpenRouter AI provider integration as the default provider for hermes agents.
        '';
        model = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "gemini-3.5-flash";
          description = "The model to use for the OpenRouter AI provider.";
        };
      };
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

      honcho = {
        workspace = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The workspace name to use for hermes agent.";
        };
      };
    };

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

  profileDir = profileName: let
    directory = prefix:
      if profileName == "default"
      then "${prefix}"
      else "${prefix}/profiles/${profileName}";
  in
    directory foregroundStateDir;

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

  mkConfig = profileName: ''
    CONFIG_FILE="${profileDir profileName}/config.yaml"
    rm -f "$CONFIG_FILE"
    cp -rL ${mkConfigFile profileName cfg.profiles.${profileName}} "$CONFIG_FILE"
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

  baseEnvironment = _profileName: let
    terminalEnv = mapTerminalConfigToEnv (cfg.userSettings // cfg.profiles.${_profileName}.userSettings);
    mergedEnv = cfg.environment // cfg.profiles.${_profileName}.environment // terminalEnv;
  in
    concatStringsSep
    "\n"
    (mapAttrsToList
      (key: value: "${key}=${value}")
      mergedEnv);

  mkEnvBase = profileName: ''
    # Set profile specific environment variables
    ENV_FILE="${profileDir profileName}/.env"
    install -m 0600 /dev/null "$ENV_FILE"
    cat > "$ENV_FILE" <<HERMES_NIX_ENV_${toUpper profileName}_EOF
    ${baseEnvironment profileName}
    HERMES_NIX_ENV_${toUpper profileName}_EOF
  '';

  mkDocuments = profileName: let
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
          optionalString (document != null && document != "") ''
            rm -rf "${targetDir}/${docDestinations.${name}}"
            mkdir -p "$(dirname "${targetDir}/${docDestinations.${name}}")"
            cp -rL ${document} "${targetDir}/${docDestinations.${name}}"
            chmod 0640 "${targetDir}/${docDestinations.${name}}"
          ''
      )
      cfg.profiles.${profileName}.documents);

  mkSkills = profileName: let
    targetDir = profileDir profileName;
    skills = cfg.skills // cfg.profiles.${profileName}.skills;
  in
    concatStringsSep "\n"
    (mapAttrsToList
      (name: skill:
        optionalString (skill != null) ''
          mkdir -p "${targetDir}/skills"
          cp -rL ${skill} "${targetDir}/skills/${name}"
          chmod -R u+w "${targetDir}/skills/${name}"
          find "${targetDir}/skills/${name}" -type d -exec chmod 0750 {} +
          find "${targetDir}/skills/${name}" -type f -exec chmod 0640 {} +
        '')
      skills);

  mkSupportingConfig = profileName: let
    profileCfg = cfg.profiles.${profileName};
  in ''
    ${optionalString (cfg.providers.memory.variant == "honcho" || profileCfg.providers.memory.variant == "honcho") ''
      # Configure honcho memory provider
      cat > ${profileDir profileName}/honcho.json <<HERMES_NIX_HONCHO_${toUpper profileName}_EOF
      ${builtins.toJSON (
        let
          workspace =
            if profileCfg.providers.memory.honcho.workspace != null
            then profileCfg.providers.memory.honcho.workspace
            else cfg.providers.memory.honcho.workspace;
        in {
          hosts = {
            "hermes_${profileName}" =
              {
                enabled = true;
                aiPeer = profileName;
                peerName = config.home.username;
              }
              // (optionalAttrs (workspace != null) {
                inherit workspace;
              });
          };
        }
      )}
      HERMES_NIX_HONCHO_${toUpper profileName}_EOF
    ''}
  '';

  getProfileSecrets = profileName:
    cfg.profiles.${profileName}.secrets;

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
            type = types.enum ["foreground" "hybrid"];
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
          };

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
                (mapAttrsToList (_: value: "hermes/${name}/${value.secret}") (filterAttrs (_: value: value ? secret) (
                  if server.env != null
                  then server.env
                  else {}
                )))
                ++ (mapAttrsToList (_: value: "hermes/${name}/${value.secret}") (filterAttrs (_: value: value ? secret) (
                  if server.headers != null
                  then server.headers
                  else {}
                )))
            )
            mcpServers);
          providerSecrets =
            optional (cfg.providers.models.openrouter.enable || config.providers.models.openrouter.enable) "hermes/${name}/api/OPENROUTER_API_KEY"
            ++ optional (cfg.providers.models.opencode.zen.enable || config.providers.models.opencode.zen.enable) "hermes/${name}/api/OPENCODE_ZEN_API_KEY"
            ++ optional (cfg.providers.models.opencode.go.enable || config.providers.models.opencode.go.enable) "hermes/${name}/api/OPENCODE_GO_API_KEY"
            ++ optional (cfg.providers.memory.variant == "honcho" || config.providers.memory.variant == "honcho") "hermes/${name}/api/HONCHO_API_KEY"
            ++ optional (cfg.providers.search.firecrawl.enable || config.providers.search.firecrawl.enable) "hermes/${name}/api/FIRECRAWL_API_KEY"
            ++ optional (cfg.providers.search.brave.enable || config.providers.search.brave.enable) "hermes/${name}/api/BRAVE_SEARCH_API_KEY"
            ++ optional (cfg.providers.search.tavily.enable || config.providers.search.tavily.enable) "hermes/${name}/api/TAVILY_API_KEY"
            ++ optional (cfg.providers.search.exa.enable || config.providers.search.exa.enable) "hermes/${name}/api/EXA_API_KEY"
            ++ optional (cfg.providers.search.parallel.enable || config.providers.search.parallel.enable) "hermes/${name}/api/PARALLEL_API_KEY"
            ++ optional (cfg.providers.search.xai.enable || config.providers.search.xai.enable) "hermes/${name}/api/XAI_API_KEY";
        in
          unique (mcpSecrets ++ providerSecrets);

        userSettings = mkMerge [
          {
            mcp_servers = mkMerge [
              (lib.mapAttrs (
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
                mcpServers)
              (mkIf (config.type == "foreground") {
                filesystem = mkForce {
                  command = "${pkgs.nodejs}/bin/npx";
                  args =
                    [
                      "-y"
                      "@modelcontextprotocol/server-filesystem"
                    ]
                    ++ config.permissions.accessDirectories;
                };
              })
            ];

            streaming.enabled = true;
            stt.enabled = true;
          }
          (mkIf (config.type == "hybrid") {
            backend = "docker";
            docker_image = "nikolaik/python-nodejs:python3.14-nodejs26";
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
          (mkIf (config.providers.memory.variant != null || cfg.providers.memory.variant != null) {
            memory.provider =
              if config.providers.memory.variant != null
              then config.providers.memory.variant
              else cfg.providers.memory.variant;
          })
          (mkIf (config.providers.search.variant != null || cfg.providers.search.variant != null) {
            web.backend =
              if config.providers.search.default != null
              then config.providers.search.default
              else cfg.providers.search.default;
          })
          (mkIf (config.providers.models.openrouter.default || cfg.providers.models.openrouter.default) {
            model = {
              provider = "openrouter";
              model =
                if config.providers.models.openrouter.model != null
                then config.providers.models.openrouter.model
                else cfg.providers.models.openrouter.model;
            };
          })
          (mkIf (config.providers.models.opencode.go.default || cfg.providers.models.opencode.go.default) {
            model = {
              provider = "opencode-go";
              model =
                if config.providers.models.opencode.go.model != null
                then config.providers.models.opencode.go.model
                else cfg.providers.models.opencode.go.model;
            };
          })
          (mkIf (config.providers.models.opencode.zen.default || cfg.providers.models.opencode.zen.default) {
            model = {
              provider = "opencode-zen";
              model =
                if config.providers.models.opencode.zen.model != null
                then config.providers.models.opencode.zen.model
                else cfg.providers.models.opencode.zen.model;
            };
          })
        ];
      })
    ];
  });
in {
  # Installs cli tooling with global enable option, extra features get added with other options
  options.apps.development.agents.hermes = mkOption {
    type = types.submodule (_: let
      name = "hermes";
    in {
      options = homelab.development.mkAgent {
        inherit name;
        package = pkgs.hermes;
        extraOptions = {
          enableCli = mkEnableOption "Enable cli integration for hermes agent";
          enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

          desktopPackage = mkOption {
            type = types.package;
            default = pkgs.hermes-desktop;
            description = ''
              The package to use for the desktop integration of the hermes agent.
            '';
          };

          providers = providerOptions;

          profiles = mkOption {
            type = types.attrsOf profileSubmodule;
            default = {};
            description = "Profiles for the Hermes agent.";
          };
        };
      };
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
      home.packages = [cfg.desktopPackage];

      # Setup desktop entry for hermes-desktop
      xdg.desktopEntries.hermes-desktop = {
        name = "Hermes Desktop";
        comment = "Hermes AI Agent - Desktop UI";
        icon = "${cfg.desktopPackage}/share/hermes-desktop/dist/hermes.png";
        exec = "${cfg.desktopPackage}/bin/hermes-desktop";
        terminal = false;
        type = "Application";
        categories = ["Development" "Utility"];
        startupNotify = true;
      };
    })

    # Load in all secrets from all profiles in central agent execution for simplicity
    {
      sops.secrets = let
        allSecrets = unique (
          cfg.secrets
          ++ (concatLists (map getProfileSecrets (attrNames cfg.profiles)))
        );

        secretToSopsFile =
          foldl' (
            acc: profileName: let
              profileCfg = cfg.profiles.${profileName};
              sopsFile = profileCfg.providers.sopsFile;
            in
              if sopsFile != null
              then acc // (genAttrs (getProfileSecrets profileName) (_: sopsFile))
              else acc
          ) (
            if cfg.providers.sopsFile != null
            then genAttrs cfg.secrets (_: cfg.providers.sopsFile)
            else {}
          );
      in
        genAttrs allSecrets (
          secret:
            optionalAttrs (secretToSopsFile ? ${secret}) {
              sopsFile = secretToSopsFile.${secret};
            }
        );

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
                ${mkConfig profileName}

                # Create base environment file
                ${mkEnvBase profileName}

                # Link documents into profile
                ${mkDocuments profileName}

                # Copy skill files
                ${mkSkills profileName}

                # Configure memory providers
                ${mkSupportingConfig profileName}
              '';
            }
          else acc
      ) {} (attrNames cfg.profiles);

      # Generate systemd services for all enabled profiles (Linux only)
      systemd.user.services = let
        agentsForType = type: (attrNames (filterAttrs (_name: profile: profile.type == type) cfg.profiles));

        # This script writes this agent's secrets and all global secrets to the profile agent .env file
        envSeedScript = profileName: let
          profileCfg = cfg.profiles.${profileName};
        in
          pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
            set -euo pipefail
            ENV_FILE="$HERMES_HOME/.env"
            mkdir -p "$(dirname "$ENV_FILE")"
            chmod 0700 "$(dirname "$ENV_FILE")"
            cat << 'HERMES_NIX_ENV_EOF' > "$ENV_FILE"
            ${baseEnvironment profileName}
            HERMES_NIX_ENV_EOF
            chmod 0600 "$ENV_FILE"
            ${concatStringsSep "\n" (
              map (f: ''
                printf "${baseNameOf f}=%s\n" "$(cat ${config.sops.secrets."${f}".path})" >> "$ENV_FILE"
              '')
              (unique (cfg.secrets ++ profileCfg.secrets))
            )}
          '';
      in
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
                    Description = "Hermes AI Agent (${profileName} profile)";
                    After = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || getProfileSecrets profileName != []) "sops-nix.service";
                    Wants = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || getProfileSecrets profileName != []) "sops-nix.service";
                  };
                  Service = let
                    servicePath = lib.makeBinPath [
                      hermesPackage
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.git
                      pkgs.jq
                      pkgs.podman
                      "/run/wrappers"
                      "/run/current-system/sw"
                      config.home.profileDirectory
                    ];
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
                          "if ! podman network exists \"hermes-agent-${profileName}\"; then"
                          "  podman network create \"hermes-agent-${profileName}\""
                          "fi"

                          "${hermesPackage}/bin/hermes"
                          "gateway"
                        ];

                        Restart = "always";
                        RestartSec = 5;

                        # Security hardening
                        UMask = "0077";
                      }
                      (lib.mkIf (cfg.secrets != [] || profileCfg.secrets != []) {
                        ExecStartPre = "${envSeedScript profileName}";
                      })
                    ];
                  Install.WantedBy = ["default.target"];
                };
              }
            else acc
        ) {} (agentsForType "hybrid"))
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
                    Description = "Hermes AI Agent (${profileName} profile) (oneshot) - Generates environment variables from sops secrets";
                    After = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || getProfileSecrets profileName != []) "sops-nix.service";
                    Wants = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || getProfileSecrets profileName != []) "sops-nix.service";
                  };
                  Service = let
                    servicePath = lib.makeBinPath [
                      hermesPackage
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.git
                      pkgs.jq
                    ];
                  in {
                    Type = "oneshot";

                    Environment = [
                      "HOME=${config.home.homeDirectory}"
                      "HERMES_HOME=${profileDir profileName}"
                      "HERMES_MANAGED=true"
                      "PATH=${servicePath}"
                    ];

                    ExecStart = ''
                      ${envSeedScript profileName}
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
        ) {} (agentsForType "foreground"));
    }
  ]);
}

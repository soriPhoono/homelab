{
  lib,
  pkgs,
  config,
  nixosConfig ? null,
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
      oauth = {
        enable = mkEnableOption "OAuth support for different AI providers";
        default = mkEnableOption "Enable OAuth provider as the default for hermes agents.";
        base_url = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://chatgpt.com/backend-api/codex";
          description = "The base url to use for inference";
        };
        provider = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "chatgpt";
          description = "The provider to use for the OAuth AI provider integration.";
        };
        model = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "gpt-5.5";
          description = "The model to use from the given provider";
        };
      };
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
        enable = mkEnableOption "Enable ollama local inference integration";
        enableCloud = mkEnableOption "Enable ollama cloud models";
        default = mkEnableOption ''
          Set this to true to enable Ollama local inference integration as the default provider for hermes agents.
        '';
        model = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "gemma4:e4b";
          description = "The model to use for the Ollama local inference provider.";
        };
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

  # Wrap the hermes binary to set default environment variables for foreground agents
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

  # Define state directories
  foregroundStateDir = "${config.home.homeDirectory}/.hermes";

  # Correctly set profile directory based on profile type
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
  mkConfigFile = profileName:
    pkgs.writeText "hermes-config-${profileName}.yaml"
    (builtins.toJSON (cfg.userSettings // cfg.profiles.${profileName}.userSettings));

  mkConfig = profileName: ''
    CONFIG_FILE="${profileDir profileName}/config.yaml"
    rm -f "$CONFIG_FILE"
    cp -rL ${mkConfigFile profileName} "$CONFIG_FILE"
    chmod 0600 "$CONFIG_FILE"
  '';

  # Generate base environment for a profile
  baseEnvironment = profileName: let
    mergedEnv = cfg.environment // cfg.profiles.${profileName}.environment;
  in
    concatStringsSep
    "\n"
    (mapAttrsToList
      (key: value: "${key}=${value}")
      mergedEnv);

  # Create environment file for a profile
  # Populating the file is the systemd oneshot's job (it needs decrypted sops
  # secrets, which don't exist yet at activation time). Activation only ensures
  # the file exists so a running agent doesn't crash before the oneshot runs.
  # Do NOT truncate here: doing so would wipe the oneshot's output on every
  # home-manager switch, and HM's unit-restart race means the oneshot does not
  # reliably re-run in the same pass.
  mkEnvBase = profileName: ''
    # Set profile specific environment variables
    ENV_FILE="${profileDir profileName}/.env"
    if [ ! -e "$ENV_FILE" ]; then
      install -m 0600 /dev/null "$ENV_FILE"
    fi
  '';

  # Copy documents to profile directory
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

  # Create skill directories for a profile
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

  # Create supporting configuration for a profile
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

    # Configure OAuth secret file for hermes profiles
    ${optionalString (cfg.providers.models.oauth.enable || profileCfg.providers.models.oauth.enable) ''
      if [[ ! -f ${profileDir profileName}/auth.json ]]; then
        cp ${config.sops.secrets."hermes/${profileName}/core/auth.json".path} \
          ${profileDir profileName}/auth.json
        chmod 0600 ${profileDir profileName}/auth.json
      fi
    ''}
  '';

  # Get secrets for a profile
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
          providers = providerOptions;

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
            ++ optional (cfg.providers.models.ollama.enableCloud || config.providers.models.ollama.enableCloud) "hermes/${name}/api/OLLAMA_API_KEY"
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
            mcp_servers =
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
                        then "${
                          if (value.prefix or null) != null
                          then value.prefix
                          else ""
                        }\${${baseNameOf value.secret}}${
                          if (value.suffix or null) != null
                          then value.suffix
                          else ""
                        }"
                        else value)
                      server.headers;
                    })
                )
                mcpServers)
              // {
                filesystem = {
                  command = "${pkgs.nodejs}/bin/npx";
                  args =
                    [
                      "-y"
                      "@modelcontextprotocol/server-filesystem"
                    ]
                    ++ config.permissions.accessDirectories;
                };
              };

            streaming.enabled = true;
            stt.enabled = true;
          }
          (mkIf (config.providers.memory.variant != null || cfg.providers.memory.variant != null) {
            memory.provider =
              if config.providers.memory.variant != null
              then config.providers.memory.variant
              else cfg.providers.memory.variant;
          })
          (mkIf (config.providers.search.variant != null || cfg.providers.search.variant != null) {
            web.backend =
              if config.providers.search.variant != null
              then config.providers.search.variant
              else cfg.providers.search.variant;
          })
          (mkIf (config.providers.models.oauth.default || cfg.providers.models.oauth.default) {
            model = {
              provider =
                if config.providers.models.oauth.provider != null
                then config.providers.models.oauth.provider
                else cfg.providers.models.oauth.provider;
              model =
                if config.providers.models.oauth.model != null
                then config.providers.models.oauth.model
                else cfg.providers.models.oauth.model;
            };
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
          (mkIf (config.providers.models.ollama.default || cfg.providers.models.ollama.default) {
            model = {
              provider = "custom";
              default =
                if config.providers.models.ollama.model != null
                then config.providers.models.ollama.model
                else cfg.providers.models.ollama.model;
              base_url = let
                nixosOllamaEnabled = nixosConfig != null && (nixosConfig.hosting.inference.ollama.enable or false);
                host =
                  if nixosOllamaEnabled
                  then (nixosConfig.hosting.inference.ollama.host or "127.0.0.1")
                  else "127.0.0.1";
                port =
                  if nixosOllamaEnabled
                  then (nixosConfig.hosting.inference.ollama.port or 11434)
                  else 11434;
              in "http://${host}:${toString port}/v1";
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
    (mkIf cfg.enableCli {
      # Install core cli package
      home.packages = [hermesPackage];
    })

    (mkIf cfg.enableDesktop {
      # Install hermes-desktop
      home.packages = [cfg.desktopPackage];
    })

    {
      # Load in all secrets from all profiles in central agent execution for simplicity
      sops.secrets = let
        allSecrets = unique (
          cfg.secrets
          ++ (concatLists (map (
              profile:
                (getProfileSecrets profile)
                ++ (optional (
                  cfg.providers.models.oauth.enable
                  || cfg.profiles.${profile}.providers.models.oauth.enable
                ) "hermes/${profile}/core/auth.json")
            )
            (attrNames cfg.profiles)))
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
        # This script writes this agent's secrets and all global secrets to the profile agent .env file
        envSeedScript = profileName: let
          profileCfg = cfg.profiles.${profileName};
        in
          pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
            set -euo pipefail
            HERMES_HOME="''${HERMES_HOME:-${profileDir profileName}}"
            ENV_FILE="$HERMES_HOME/.env"

            # Wait until sops-nix has finished decrypting AND populating every
            # secret this profile needs. sops-nix can materialize secret files as
            # zero-length before their content lands; reading them in that window
            # writes blank API keys into the .env. Retry briefly, then fail loudly
            # so systemd surface the error instead of silently minting an unusable
            # environment file.
            ${concatStringsSep "\n" (
              map (f: ''
                for _ in $(seq 1 30); do
                  [ -s "${config.sops.secrets."${f}".path}" ] && break
                  sleep 1
                done
                if [ ! -s "${config.sops.secrets."${f}".path}" ]; then
                  echo "hermes-agent-${profileName}: secret missing or empty: ${f}" >&2
                  exit 1
                fi
              '')
              (unique (cfg.secrets ++ profileCfg.secrets))
            )}

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
        foldl' (
          acc: profileName: let
            profileCfg = cfg.profiles.${profileName};
          in
            if profileCfg.enable && pkgs.stdenv.hostPlatform.isLinux
            then
              acc
              // {
                "hermes-agent-${profileName}" = {
                  Unit = let
                    hasSecrets = cfg.secrets != [] || getProfileSecrets profileName != [];
                  in {
                    Description = "Hermes AI Agent (${profileName} profile) (oneshot) - Generates environment variables from sops secrets";
                    After = ["network-online.target"] ++ lib.optional hasSecrets "sops-nix.service";
                    Wants = ["network-online.target"] ++ lib.optional hasSecrets "sops-nix.service";
                    # Hard dependency: if sops-nix fails to decrypt, fail this unit
                    # instead of running and minting an .env full of blank API keys.
                    Requires = lib.optional hasSecrets "sops-nix.service";
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
        ) {} (attrNames cfg.profiles);
    }
  ]);
}

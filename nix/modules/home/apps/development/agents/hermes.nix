{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.apps.development.agents.hermes;

  providerOptions = {
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

  hermesPackage = pkgs.symlinkJoin {
    name = "${cfg.package.name or "hermes"}-wrapped";
    paths = [cfg.package];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for bin in $out/bin/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          wrapArgs=(
            --set HERMES_HOME "${stateDir}"
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

  # Create folder structure for hermes profiles
  mkProfileFolders = profileDir: ''
    mkdir -p ${profileDir}/
    mkdir -p ${profileDir}/cron
    mkdir -p ${profileDir}/sessions
    mkdir -p ${profileDir}/logs
    mkdir -p ${profileDir}/memories
  '';

  # Create profile config.yaml
  mkConfigFile = profileName: profileConfig:
    pkgs.writeText "hermes-config-${profileName}.yaml"
    (builtins.toJSON (cfg.userSettings // profileConfig.userSettings));

  mkConfig = profileName: profile: ''
    CONFIG_FILE="${
      if profileName == "default"
      then stateDir
      else "${stateDir}/profiles/${profileName}"
    }/config.yaml"

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
    ENV_FILE="${
      if profileName == "default"
      then stateDir
      else "${stateDir}/profiles/${profileName}"
    }/.env"
    install -m 0640 /dev/null "$ENV_FILE"
    cat > "$ENV_FILE" <<HERMES_NIX_ENV_${toUpper profileName}_EOF
    ${baseEnvironment profileName profileCfg}
    HERMES_NIX_ENV_${toUpper profileName}_EOF
  '';

  mkDocuments = profileName: profileCfg: let
    targetDir =
      if profileName == "default"
      then stateDir
      else "${stateDir}/profiles/${profileName}";
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
in {
  # Installs cli tooling with global enable option, extra features get added with other options
  options.apps.development.agents.hermes = homelab.agentics.mkAgent {
    name = "hermes";
    package = pkgs.hermes;
    extraOptions = {
      enableCli = mkEnableOption "Enable cli integration for hermes agent";
      enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

      providers = providerOptions;

      profiles = mkOption {
        type = types.attrsOf (types.submodule
          (_: {
            options =
              (removeAttrs (lib.homelab.agentics.mkAgent {
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
          }));
        default = {};
        description = "Profiles for the Hermes agent.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkMerge [
      (let
        profileName = "default";
        profileCfg = cfg.profiles.${profileName};
      in {
        apps.development.agents.hermes.profiles.${profileName} = let
          mcpServers = cfg.mcpServers // profileCfg.mcpServers;
        in {
          secrets = unique (concatLists (mapAttrsToList (
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
            mcpServers));
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

            model =
              if (cfg.providers.opencode.go.default || profileCfg.providers.opencode.go.default)
              then {
                provider = "opencode-go";
                model =
                  if cfg.providers.opencode.go.model != null
                  then cfg.providers.opencode.go.model
                  else profileCfg.providers.opencode.go.model;
              }
              else if (cfg.providers.opencode.zen.default || profileCfg.providers.opencode.zen.default)
              then {
                provider = "opencode-zen";
                model =
                  if cfg.providers.opencode.zen.model != null
                  then cfg.providers.opencode.zen.model
                  else profileCfg.providers.opencode.zen.model;
              }
              else {};
          };
        };
      })

      (let
        profileName = "default";
        profileCfg = cfg.profiles.${profileName};
      in
        mkIf profileCfg.enable {
          home = {
            activation."hermes-agent-${profileName}-setup" = lib.hm.dag.entryAfter ["writeBoundary"] ''
              # Ensure directories exist for hermes agent startup (${profileName} profile)
              ${mkProfileFolders stateDir}

              # Write managed flag
              echo "" > ${stateDir}/.managed

              # NOTE: Removed auth seeding logic, instead auth.json is seeded by the hermes provider given it's oauth process bound or maintained by the agent

              # Install config.yaml for default profile
              ${mkConfig profileName profileCfg}

              # Create base environment file
              ${mkEnvBase profileName profileCfg}

              # Link documents into default agent
              ${mkDocuments profileName profileCfg}
            '';

            file =
              mapAttrs'
              (name: skill: {
                name = "${stateDir}/skills/${name}";
                value = {
                  source = skill;
                  recursive = true;
                };
              })
              (cfg.skills // profileCfg.skills);
          };

          sops.secrets = let
            allSecrets = unique (cfg.secrets ++ (concatLists (mapAttrsToList (_name: profileCfg: profileCfg.secrets) cfg.profiles)));
          in
            genAttrs allSecrets (_: {});
        })

      (let
        profileName = "default";
        profileCfg = cfg.profiles.${profileName};
      in
        mkIf (profileCfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
          systemd.user.services."hermes-agent-${profileName}" = {
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

              envSeedScript = pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
                ENV_FILE="${stateDir}/.env"
                ${optionalString (cfg.providers.opencode.zen.enable || profileCfg.providers.opencode.zen.enable) ''
                  printf "OPENCODE_ZEN_API_KEY=%s\n" "$(cat ${config.sops.secrets."api/OPENCODE_API_KEY".path})" | tee -a "$ENV_FILE"
                ''}
                ${optionalString (cfg.providers.opencode.go.enable || profileCfg.providers.opencode.go.enable) ''
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
                    "HERMES_HOME=${stateDir}"
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
        })
    ])

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
      })
  ]);
}

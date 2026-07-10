{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.apps.development.agents.hermes;

  providerOptions = {
    ollama = {
      enable = mkEnableOption "Enable ollama provider for hermes agents";
      useCloudModels = mkEnableOption "Enable ollama cloud provider api key integration for hermes agents";
    };
  };

  hermesPackage =
    if cfg.extraPackages == []
    then cfg.package
    else
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "hermes"}-wrapped";
        paths = [cfg.package];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          for bin in $out/bin/*; do
            if [ -f "$bin" ] && [ -x "$bin" ]; then
              wrapProgram "$bin" \
                --prefix PATH : ${lib.makeBinPath cfg.extraPackages}
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
    pkgs.writeText "hermes-${profileName}-config.yaml"
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
    {
      home = {
        sessionVariables = {
          HERMES_HOME = stateDir;
          HERMES_MANAGED = true;
        };

        activation.hermes-agent-default-setup = let
          profileName = "default";
        in
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            # Ensure directories exist for hermes agent startup (Default profile)
            ${mkProfileFolders stateDir}

            # Write managed flag
            echo "" > ${stateDir}/.managed

            # NOTE: Removed auth seeding logic, instead auth.json is seeded by the hermes provider given it's oauth process bound or maintained by the agent

            # Install config.yaml for default profile
            ${mkConfig profileName cfg.profiles.default}

            # Create base environment file
            ${mkEnvBase profileName cfg.profiles.default}

            # Link documents into default agent
            ${mkDocuments profileName cfg.profiles.default}
          '';
      };

      sops.secrets = let
        allSecrets = unique (cfg.secrets ++ (concatLists (mapAttrsToList (_name: profileCfg: profileCfg.secrets) cfg.profiles)));
      in
        genAttrs allSecrets (_: {});
    }

    (mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.hermes-agent-default = {
        Unit = {
          Description = "Hermes AI Agent (Default)";
          After = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || cfg.profiles.default.secrets != []) "sops-nix.service";
          Wants = ["network-online.target"] ++ lib.optional (cfg.secrets != [] || cfg.profiles.default.secrets != []) "sops-nix.service";
        };
        Service = let
          profileName = "default";
          servicePath = lib.makeBinPath [
            hermesPackage
            pkgs.bash
            pkgs.coreutils
            pkgs.git
          ];

          envSeedScript = pkgs.writeShellScript "hermes-seed-envfiles-${profileName}" ''
            ENV_FILE="${stateDir}/.env"
            ${concatStringsSep "\n" (
              map (f: ''
                echo "${baseNameOf f}=${config.sops.secrets."${f}".path}" | tee -a "$ENV_FILE"
              '')
              (unique (cfg.secrets ++ cfg.profiles.default.secrets))
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
            (lib.mkIf (cfg.secrets != []) {
              ExecStartPre = "${envSeedScript}";
            })
          ];
        Install.WantedBy = ["default.target"];
      };
    })

    # Install core cli package and set environment variables
    (mkIf cfg.enableCli {
      home.packages = [hermesPackage];
    })

    # Install desktop integration for hermes agent
    (mkIf cfg.enableDesktop {
      })

    (mkIf ((builtins.attrNames (removeAttrs cfg.profiles ["default"])) != []) {
      home.activation =
        mapAttrs'
        (name: profileCfg: {
          name = "hermes-agent-${name}-setup";
          value = lib.hm.dag.entryAfter ["hermes-agent-default-setup"] ''
            # Create folders for additional profiles
            ${mkProfileFolders (stateDir + "/profiles/${name}")}

            # Install config.yaml for profile
            ${mkConfig name profileCfg}

            # Create base environment file
            ${mkEnvBase name profileCfg}

            # Link documents into agent profile
            ${mkDocuments name profileCfg}
          '';
        }) (removeAttrs cfg.profiles ["default"]);
    })
  ]);
}

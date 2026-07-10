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

  profilesSchema =
    types.submodule
    (_: {
      options =
        (removeAttrs (lib.homelab.agentics.mkAgent {
          inherit name;
          package = null;
          extraOptions = {
            environment = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Environment variables for the hermes agent profile, NO SECRETS HERE";
            };

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
          };
        }) ["enable" "package"])
        // {
          enable =
            (mkEnableOption "Enable this agent profile")
            // {
              default = true;
            };
        };
    });

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
    (builtins.toJSON (profileConfig // cfg.userSettings));

  # Create auth.json from sops secrets
  mkAuthConfig = profileName: profileDir: let
    hasProfileAuth = hasAttr "hermes/${profileName}/auth.json" config.sops.secrets;
    hasGlobalAuth = hasAttr "hermes/global/auth.json" config.sops.secrets;
  in
    optionalString
    (hasProfileAuth || hasGlobalAuth)
    (
      if hasProfileAuth
      then "install -m 0600 ${config.sops.secrets."hermes/${profileName}/auth.json".path} ${profileDir}/auth.json"
      else "install -m 0600 ${config.sops.secrets."hermes/global/auth.json".path} ${profileDir}/auth.json"
    );

  baseEnvFile = _profileName: profileCfg:
    concatStringsSep
    "\n"
    (mapAttrsToList
      (key: value: "${key}=${value}")
      (cfg.environment // profileCfg.environment));

  mkEnvBase = profileName: profileCfg: ''
    # Set profile specific environment variables
    ENV_FILE="${stateDir}/.env"
    install -m 0640 /dev/null "$ENV_FILE"
    cat > "$ENV_FILE" <<HERMES_NIX_ENV_${toUpper profileName}_EOF
    ${baseEnvFile profileName profileCfg}
    HERMES_NIX_ENV_${toUpper profileName}_EOF
  '';
  # mkDocuments = profileCfg: pkgs.runCommand "hermes-documents" {} (
  #   ''
  #     mkdir -p $out
  #   ''
  #   + lib.concatStringsSep "\n" (
  #     lib.mapAttrsToList (
  #       name: value:
  #       if builtins.isPath value || lib.isStorePath value then
  #         "cp -rL ${value} $out/${name}"
  #       else
  #         "cat > $out/${name} <<'HERMES_DOC_EOF'\n${value}\nHERMES_DOC_EOF"
  #     ) (removeAttrs (cfg.documents // profileCfg.documents) ["SOUL.md" "USER.md"]))
  # );
in {
  # Installs cli tooling with global enable option, extra features get added with other options
  options.apps.development.agents.hermes = builtins.removeAttrs (homelab.agentics.mkAgent {
    name = "hermes";
    package = pkgs.hermes;
    extraOptions = {
      enableCli = mkEnableOption "Enable cli integration for hermes agent";
      enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Extra packages to install alongside the hermes agent";
      };

      providers = providerOptions;

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the hermes agent, NO SECRETS HERE";
      };

      profiles = mkOption {
        type = types.attrsOf profilesSchema;
        default = {};
        description = "Profiles for the Hermes agent.";
      };
    };
  }) ["documents"];

  config = mkIf cfg.enable (mkMerge [
    {
      home.sessionVariables = {
        HERMES_HOME = stateDir;
        HERMES_MANAGED = true;
      };

      home.activation.hermes-agent-default-setup = let
        profileName = "default";
      in
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          # Ensure directories exist for hermes agent startup (Default profile)
          ${mkProfileFolders stateDir}

          # Install config.yaml for default profile
          install -m 0640 -D ${mkConfigFile profileName cfg.profiles.default} ${stateDir}/config.yaml

          # Write managed flag
          echo "" > ${stateDir}/.managed

          # Seed auth file if provided
          ${mkAuthConfig profileName stateDir}

          # Create base environment file
          ${mkEnvBase profileName cfg.profiles.default}

          # Link documents into workspace
        '';
    }
    # Install core cli package and set environment variables
    (mkIf cfg.enableCli {
      home.packages = [hermesPackage];
    })
    (mkIf ((builtins.attrNames (removeAttrs cfg.profiles ["default"])) != []) {
      home.activation =
        mapAttrs
        (name: _config: {
          "hermes-agent-${name}-setup" = lib.hm.dag.entryAfter ["hermes-agent-default-setup"] ''
            # Create folders for additional profiles
            ${mkProfileFolders (stateDir + "/profiles/${name}")}
          '';
        }) (removeAttrs cfg.profiles ["default"]);
    })
  ]);
}

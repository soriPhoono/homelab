{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.pi-coding-agent;

  inherit
    (lib)
    concatStringsSep
    filterAttrs
    flatten
    genAttrs
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    unique
    ;

  # Reuse mcp secret extraction for consistency, though Pi upstream has no mcpServers;
  # keep generic so mkAgent's mcpServers can still inject secrets if user sets them.
  mcpSecretNames = flatten (mapAttrsToList (_name: server:
    mapAttrsToList (_: value: value.secret)
    (filterAttrs
      (_: value: builtins.isAttrs value && value ? "secret")
      (
        if server.env != null
        then server.env
        else if server.headers != null
        then server.headers
        else {}
      )))
  cfg.mcpServers);

  allSecrets = unique (
    cfg.secrets
    ++ mcpSecretNames
  );

  hasRuntimeEnvironment = cfg.environment != {} || allSecrets != [];

  runtimeEnvironment = concatStringsSep "\n" (
    (mapAttrsToList (name: value: "${name}=${value}") cfg.environment)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") cfg.secrets)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") mcpSecretNames)
  );

  runtimeEnvironmentFile = config.sops.templates."pi-coding-agent/environment".path;

  piPackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "pi-coding-agent"}-managed";
        paths = [cfg.package];
        meta =
          (cfg.package.meta or {})
          // {
            mainProgram = cfg.package.meta.mainProgram or "pi";
          };
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "pi"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;

  # Pi hackability: userSettings is merged into settings, exposing full upstream settings surface
  mergedSettings = lib.recursiveUpdate cfg.settings cfg.userSettings;

  renderDocument = name: document: ''
    # ${name}

    ${
      if builtins.isPath document
      then builtins.readFile document
      else document
    }
  '';

  contextFile = builtins.toPath (toString (pkgs.writeText "pi-context.md" (
    concatStringsSep "\n" (
      map (name: renderDocument name cfg.documents.${name})
      (builtins.sort builtins.lessThan (builtins.attrNames cfg.documents))
    )
  )));

  effectiveContext =
    if cfg.documents != {}
    then contextFile
    else cfg.context;
in
  with lib; {
    options.apps.development.agents.pi-coding-agent = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "pi-coding-agent";
          package = pkgs.pi-coding-agent;
          extraOptions = {
            settings = mkOption {
              type = options.programs.pi-coding-agent.settings.type;
              default = {};
              description = "Settings forwarded to programs.pi-coding-agent.settings (settings.json). Merged with userSettings for hackability.";
            };

            keybindings = mkOption {
              type = options.programs.pi-coding-agent.keybindings.type;
              default = {};
              description = "Keybindings forwarded to programs.pi-coding-agent.keybindings.";
            };

            models = mkOption {
              type = options.programs.pi-coding-agent.models.type;
              default = {};
              description = "Model providers forwarded to programs.pi-coding-agent.models.";
            };

            context = mkOption {
              type = options.programs.pi-coding-agent.context.type;
              default = "";
              description = "Global context forwarded to programs.pi-coding-agent.context (AGENTS.md). Overridden by documents if set.";
            };

            configDir = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Directory holding Pi config files. Null defers to upstream default (~/.pi/agent) or programs.pi-coding-agent.configDir.";
            };
          };
        };
      });
      description = "Declarative Pi coding agent configuration. Minimal wrapper exposing userSettings + custom packages for hackability.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets = genAttrs allSecrets (_: {});

        sops.templates."pi-coding-agent/environment" = mkIf hasRuntimeEnvironment {
          content = runtimeEnvironment;
        };

        programs.pi-coding-agent =
          {
            enable = true;
            package = piPackage;

            # Directly expose upstream extraPackages + hackability surface
            inherit (cfg) extraPackages;

            settings = mergedSettings;
            inherit (cfg) keybindings;
            inherit (cfg) models;
            context = effectiveContext;
          }
          // optionalAttrs (cfg.configDir != null) {
            inherit (cfg) configDir;
          };
      }
    ]);
  }

{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.codex;

  inherit
    (lib)
    concatStringsSep
    filterAttrs
    genAttrs
    mapAttrs
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    unique
    flatten
    ;

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
    # codex-specific: no web password; keep generic
  );

  hasRuntimeEnvironment = cfg.environment != {} || allSecrets != [];

  renderMcpEnvironment = mapAttrs (_: value:
    if builtins.isAttrs value && value ? "secret"
    then "{file:${config.sops.secrets.${value.secret}.path}}"
    else value);

  renderMcpHeaders = mapAttrs (_: value:
    if builtins.isAttrs value && value ? "secret"
    then "${value.prefix or ""}{env:${baseNameOf value.secret}}${value.suffix or ""}"
    else value);

  renderedMcpServers =
    mapAttrs (
      name: server:
        if server.url != null && server.command == null
        then {
          type = "remote";
          inherit (server) url;
          headers = renderMcpHeaders (
            if server.headers != null
            then server.headers
            else {}
          );
        }
        else if server.command != null && server.url == null
        then {
          type = "local";
          command =
            [server.command]
            ++ (
              if server.args != null
              then server.args
              else []
            );
          environment = renderMcpEnvironment (
            if server.env != null
            then server.env
            else {}
          );
        }
        else throw "Codex MCP server ${name} must have either url or command"
    )
    cfg.mcpServers;

  # Codex expects mcp_servers in TOML settings; map our rendered servers there
  mcpServersSettings = optionalAttrs (renderedMcpServers != {}) {
    mcp_servers = renderedMcpServers;
  };

  renderDocument = name: document: ''
    # ${name}

    ${
      if builtins.isPath document
      then builtins.readFile document
      else document
    }
  '';

  contextFile = builtins.toPath (toString (pkgs.writeText "codex-context.md" (
    concatStringsSep "\n" (
      map (name: renderDocument name cfg.documents.${name})
      (builtins.sort builtins.lessThan (builtins.attrNames cfg.documents))
    )
  )));

  # Resolve effective context: documents take precedence; else empty context
  effectiveContext =
    if cfg.documents != {}
    then contextFile
    else "";

  runtimeEnvironment = concatStringsSep "\n" (
    (mapAttrsToList (name: value: "${name}=${value}") cfg.environment)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") cfg.secrets)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") mcpSecretNames)
  );

  runtimeEnvironmentFile = config.sops.templates."codex/environment".path;

  codexPackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "codex"}-managed";
        paths = [cfg.package];
        meta =
          (cfg.package.meta or {})
          // {
            mainProgram = cfg.package.meta.mainProgram or "codex";
          };
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "codex"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;

  mergedSettings =
    lib.recursiveUpdate cfg.userSettings mcpServersSettings;
in
  with lib; {
    options.apps.development.agents.codex = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "codex";
          package = pkgs.codex or pkgs.codex-cli or null;
          extraOptions = {
            profiles = mkOption {
              type = options.programs.codex.profiles.type;
              default = {};
              description = "Named profiles forwarded to programs.codex.profiles.";
            };

            hooks = mkOption {
              type = options.programs.codex.hooks.type;
              default = {};
              description = "Lifecycle hooks forwarded to programs.codex.hooks.";
            };

            plugins = mkOption {
              type = options.programs.codex.plugins.type;
              default = [];
              description = "Plugins forwarded to programs.codex.plugins.";
            };

            marketplaces = mkOption {
              type = options.programs.codex.marketplaces.type;
              default = {};
              description = "Marketplaces forwarded to programs.codex.marketplaces.";
            };
          };
        };
      });
      description = "Declarative Codex agent configuration.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets = genAttrs allSecrets (_: {});

        sops.templates."codex/environment" = mkIf hasRuntimeEnvironment {
          content = runtimeEnvironment;
        };

        programs.codex = {
          enable = true;
          package = codexPackage;

          inherit
            (cfg)
            plugins
            marketplaces
            hooks
            profiles
            skills
            ;

          settings = mergedSettings;

          context = effectiveContext;
        };
      }
    ]);
  }

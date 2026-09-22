{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.claude;

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
    # claude-code-specific: no web password; keep generic
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
        else throw "Claude Code MCP server ${name} must have either url or command"
    )
    cfg.mcpServers;

  renderDocument = name: document: ''
    # ${name}

    ${
      if builtins.isPath document
      then builtins.readFile document
      else document
    }
  '';

  contextFile = builtins.toPath (toString (pkgs.writeText "claude-code-context.md" (
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

  runtimeEnvironmentFile = config.sops.templates."claude/environment".path;

  claudePackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "claude-code"}-managed";
        paths = [cfg.package];
        meta =
          (cfg.package.meta or {})
          // {
            mainProgram = cfg.package.meta.mainProgram or "claude-code";
          };
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "claude-code"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;
in
  with lib; {
    options.apps.development.agents.claude = lib.homelab.development.mkAgent {
      name = "claude-code";
      package = pkgs.claude-code;
      extraOptions = {
        hooks = mkOption {
          type = options.programs.claude-code.hooks.type;
          default = {};
          description = "Lifecycle hooks forwarded to programs.claude-code.hooks.";
        };

        plugins = mkOption {
          type = options.programs.claude-code.plugins.type;
          default = [];
          description = "Plugins forwarded to programs.claude-code.plugins.";
        };

        marketplaces = mkOption {
          type = options.programs.claude-code.marketplaces.type;
          default = {};
          description = "Marketplaces forwarded to programs.claude-code.marketplaces.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets = genAttrs allSecrets (_: {});

        sops.templates."claude-code/environment" = mkIf hasRuntimeEnvironment {
          content = runtimeEnvironment;
        };

        programs.claude-code = {
          enable = true;
          package = claudePackage;

          inherit
            (cfg)
            plugins
            marketplaces
            hooks
            skills
            ;

          context = effectiveContext;
          mcpServers = renderedMcpServers;

          settings = cfg.userSettings;
        };
      }
    ]);
  }

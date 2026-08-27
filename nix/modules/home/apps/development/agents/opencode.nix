{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.opencode;

  inherit
    (lib)
    concatStringsSep
    filterAttrs
    flatten
    genAttrs
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalAttrs
    unique
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
    ++ optional cfg.web.enable "opencode/server_password"
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
        else throw "OpenCode MCP server ${name} must have either url or command"
    )
    cfg.mcpServers;

  mergedMcpServers = (cfg.userSettings.mcp or {}) // renderedMcpServers;

  renderDocument = name: document: ''
    # ${name}

    ${
      if builtins.isPath document
      then builtins.readFile document
      else document
    }
  '';

  contextFile = builtins.toPath (toString (pkgs.writeText "opencode-context.md" (
    concatStringsSep "\n" (
      map (name: renderDocument name cfg.documents.${name})
      (builtins.sort builtins.lessThan (builtins.attrNames cfg.documents))
    )
  )));

  runtimeEnvironment = concatStringsSep "\n" (
    (mapAttrsToList (name: value: "${name}=${value}") cfg.environment)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") cfg.secrets)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") mcpSecretNames)
    ++ optional cfg.web.enable "OPENCODE_SERVER_PASSWORD=${config.sops.placeholder."opencode/server_password"}"
  );

  runtimeEnvironmentFile = config.sops.templates."opencode/environment".path;

  opencodePackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "opencode"}-managed";
        paths = [cfg.package];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "opencode"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;
in
  with lib; {
    options.apps.development.agents.opencode = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "opencode";
          package = pkgs.opencode;
          extraOptions = {
            tui = mkOption {
              type = options.programs.opencode.tui.type;
              default = {};
              description = "TUI configuration forwarded to programs.opencode.tui.";
            };

            commands = mkOption {
              type = options.programs.opencode.commands.type;
              default = {};
              description = "Custom commands forwarded to programs.opencode.commands.";
            };

            agents = mkOption {
              type = options.programs.opencode.agents.type;
              default = {};
              description = "Custom subagents forwarded to programs.opencode.agents.";
            };

            tools = mkOption {
              type = options.programs.opencode.tools.type;
              default = {};
              description = "Custom tools forwarded to programs.opencode.tools.";
            };

            themes = mkOption {
              type = options.programs.opencode.themes.type;
              default = {};
              description = "Custom themes forwarded to programs.opencode.themes.";
            };

            web = {
              enable = mkEnableOption "the OpenCode web service";

              extraArgs = mkOption {
                type = options.programs.opencode.web.extraArgs.type;
                default = [];
                description = "Arguments forwarded to opencode serve.";
              };
            };
          };
        };
      });
      description = "Declarative OpenCode agent configuration.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets = genAttrs allSecrets (_: {});

        sops.templates."opencode/environment" = mkIf hasRuntimeEnvironment {
          content = runtimeEnvironment;
        };

        programs.opencode = {
          enable = true;
          package = opencodePackage;

          inherit (cfg) extraPackages tui commands agents tools themes skills;

          context =
            if cfg.documents == {}
            then ""
            else contextFile;

          settings =
            (removeAttrs cfg.userSettings ["mcp"])
            // optionalAttrs (mergedMcpServers != {}) {
              mcp = mergedMcpServers;
            };

          web =
            {
              enable = cfg.web.enable;
              inherit (cfg.web) extraArgs;
            }
            // optionalAttrs cfg.web.enable {
              environmentFile = runtimeEnvironmentFile;
            };
        };
      }
    ]);
  }

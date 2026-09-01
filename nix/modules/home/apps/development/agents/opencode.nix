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
    then "${
      if value.prefix != null
      then value.prefix
      else ""
    }{env:${baseNameOf value.secret}}${
      if value.suffix != null
      then value.suffix
      else ""
    }"
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

  ollamaProviderSettings = optionalAttrs cfg.ollama.enable {
    provider.ollama = {
      npm = cfg.ollama.package;
      name = cfg.ollama.name;
      options.baseURL = cfg.ollama.baseUrl;
      models = cfg.ollama.models;
    };
  };

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
        meta =
          (cfg.package.meta or {})
          // {
            mainProgram = cfg.package.meta.mainProgram or "opencode";
          };
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "opencode"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;

  opencodeDesktopPackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "opencode-desktop-managed";
        paths = [pkgs.opencode-desktop];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/opencode-desktop" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else pkgs.opencode-desktop;
in
  with lib; {
    options.apps.development.agents.opencode = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "opencode";
          package = pkgs.opencode;
          extraOptions = {
            desktop = mkEnableOption "Enable opencode desktop application";

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

            ollama = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to configure Ollama as an OpenCode provider. Requires user-level opt-in.";
              };

              baseUrl = mkOption {
                type = types.str;
                default = "http://127.0.0.1:11434/v1";
                description = "The OpenAI-compatible base URL for the Ollama server.";
              };

              package = mkOption {
                type = types.str;
                default = "@ai-sdk/openai-compatible";
                description = "The npm package OpenCode uses to connect to Ollama.";
              };

              name = mkOption {
                type = types.str;
                default = "Ollama (Tailscale)";
                description = "The display name for the Ollama OpenCode provider.";
              };

              models = mkOption {
                type = types.attrs;
                default = {};
                description = "Models to expose through the Ollama OpenCode provider.";
              };
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
      (mkIf cfg.desktop {
        home.packages = with pkgs; [
          opencodeDesktopPackage
        ];
      })
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
            (recursiveUpdate ollamaProviderSettings (removeAttrs cfg.userSettings ["mcp"]))
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

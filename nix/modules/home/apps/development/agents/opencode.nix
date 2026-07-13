# OpenCode home-manager module.
#
# Bridges our homelab agent config (homelab.development.mkAgent) to the
# upstream programs.opencode home-manager module.
#
# What the upstream handles:
#   settings (opencode.json), tui, context (AGENTS.md), commands,
#   agents, skills, themes, tools, web service, extraPackages
#
# What we keep custom:
#   translateMcpServer — generates writeShellScriptBin wrappers for
#     MCP servers with sops secret env/headers, resolving at runtime
#   enableDesktop — installs opencode-desktop alongside the CLI
#   Secret injection — wraps the opencode binary via symlinkJoin +
#     makeWrapper --run to export sops secrets into the environment
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.opencode;

  # ---- Gather all secret names from MCP servers ----
  mcpSecrets = let
    extractSecretNames = attrs:
      if attrs == null
      then []
      else
        lib.filter (v: v != null) (
          lib.mapAttrsToList (
            _: val:
              if builtins.isAttrs val && val ? "secret"
              then val.secret
              else null
          )
          attrs
        );
  in
    lib.flatten (
      lib.mapAttrsToList (
        _name: srv:
          extractSecretNames srv.env
          ++ extractSecretNames srv.headers
      )
      cfg.mcpServers
    );

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # ---- Predicates for secret detection ----
  hasEnvSecret = srv:
    srv.env != null && lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues srv.env);

  hasHeaderSecret = srv:
    srv.headers != null && lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues srv.headers);

  # ---- MCP server translation ----
  #
  # Converts homelab's MCP server config format to the format expected
  # by programs.opencode.settings.mcp.
  #
  # Servers with secrets in env/headers get wrapper scripts that resolve
  # at runtime from the environment (set by makeWrapper on the opencode
  # binary).
  translateMcpServer = name: rawSrv: let
    srv =
      rawSrv
      // {
        env =
          if rawSrv.env != null
          then rawSrv.env
          else {};
        headers =
          if rawSrv.headers != null
          then rawSrv.headers
          else {};
        args =
          if rawSrv.args != null
          then rawSrv.args
          else [];
      };
  in
    if (srv.url != null)
    then
      # ── HTTP / SSE transport ──
      if hasHeaderSecret srv
      then
        # Headers contain secrets → wrap via mcp-proxy with runtime expansion
        let
          wrapperName = "opencode-mcp-proxy-${name}";
          mkHeaderFlag = hname: val:
            if val ? "secret"
            then "--headers '${hname}' \"\${${baseNameOf val.secret}}\""
            else "--headers '${hname}' '${lib.escapeShellArg val}'";
          headerFlags = lib.concatStringsSep " \\\n                " (
            lib.mapAttrsToList mkHeaderFlag srv.headers
          );
          transportFlag =
            if srv.transport or "http" == "sse"
            then ""
            else "--transport streamablehttp";
          wrapper = pkgs.writeShellScriptBin wrapperName ''
            exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
              ${transportFlag} \
              ${headerFlags} \
              '${srv.url}'
          '';
        in {
          type = "local";
          command = ["${wrapper}/bin/${wrapperName}"];
          enabled = true;
        }
      else
        ({
            type = "remote";
            inherit (srv) url;
            enabled = true;
          }
          // (lib.optionalAttrs (rawSrv.headers != null) {
            inherit (srv) headers;
          }))
    else
      # ── Stdio transport ──
      if hasEnvSecret srv
      then
        # Env contains secrets → wrap via shell script that re-exports
        # the env vars (set by makeWrapper on opencode binary) before
        # exec-ing the actual MCP command.
        let
          wrapperName = "opencode-mcp-stdio-${name}";
          envExports = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              envName: value:
                if value ? "secret"
                then "export ${baseNameOf value.secret}=\"\$${baseNameOf value.secret}\""
                else "export ${envName}=${lib.escapeShellArg value}"
            )
            srv.env
          );
          argsStr = lib.concatStringsSep " " (map lib.escapeShellArg srv.args);
          wrapper = pkgs.writeShellScriptBin wrapperName ''
            ${envExports}
            exec ${lib.escapeShellArg srv.command} ${argsStr}
          '';
        in {
          type = "local";
          command = ["${wrapper}/bin/${wrapperName}"];
          enabled = true;
        }
      else
        ({
            type = "local";
            command = [srv.command] ++ srv.args;
            enabled = true;
          }
          // (lib.optionalAttrs (rawSrv.env != null) {
            inherit (srv) env;
          }));
in
  with lib; {
    options.apps.development.agents.opencode = homelab.development.mkAgent {
      name = "opencode";
      package = pkgs.opencode;
      extraOptions = {
        enableDesktop = mkEnableOption "Enable the OpenCode desktop application (opencode-desktop)";

        providers = {
          ollama = {
            enable = mkEnableOption "Use local Ollama instance as an LLM provider in OpenCode";

            models = mkOption {
              type = types.listOf types.str;
              default = ["ornith:9b"];
              description = ''
                Ollama model tag to use as the default model. Set to any model
                you have pulled locally, e.g. "llama3.2:3b" or "codellama:13b-instruct".
                OpenCode formats this as "ollama/<model>" in its config.
              '';
            };
          };
        };

        plugins = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            npm package names to register as OpenCode plugins. Each name is added
            to the `plugin` array in opencode.json, causing OpenCode to
            auto-install and load them from npm at startup.

            e.g.: [ "opencode-swarm-plugin" ]
          '';
          example = ["opencode-swarm-plugin"];
        };

        settings = mkOption {
          type = with types; attrs;
          default = {};
          description = ''
            Extra settings to merge into the OpenCode JSON config.
            Merged on top of base defaults, userSettings, MCP servers,
            and plugins. Keys here override everything.

            See https://opencode.ai/docs/config/ for the full schema.
          '';
          example = {
            model = "anthropic/claude-sonnet-4-5";
            autoupdate = true;
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Base config: delegate to upstream HM module ──
      {
        home.packages = mkIf cfg.enableDesktop [pkgs.opencode-desktop];

        programs.opencode = {
          enable = true;
          package = mkDefault cfg.package;

          context =
            cfg.documents."AGENTS.md" or "";

          settings = mkMerge [
            {
              autoupdate = mkDefault false;
            }
            (cfg.userSettings or {})
            (optionalAttrs (cfg.mcpServers != {}) {
              mcp = builtins.mapAttrs translateMcpServer cfg.mcpServers;
            })
            (optionalAttrs (cfg.plugins != []) {
              plugin = cfg.plugins;
            })
            (mkIf cfg.providers.ollama.enable {
              provider = {
                ollama = {
                  npm = "@ai-sdk/openai-compatible";
                  name = "Ollama (local)";
                  options = {
                    baseURL = "http://localhost:11434/v1";
                  };
                  models = genAttrs cfg.providers.ollama.models (model: {
                    name = model;
                  });
                };
              };
            })
            cfg.settings
          ];

          skills = mapAttrs (_name: pkg: pkg) cfg.skills;
        };
      }

      # ── Secrets variant (sops + wrapped opencode binary) ──
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        programs.opencode.package = let
          pkg = cfg.package;
        in
          with pkgs;
            symlinkJoin {
              name = "${pkg.name}-wrapped";
              paths = [pkg] ++ optional cfg.enableDesktop pkgs.opencode-desktop;
              buildInputs = [makeWrapper];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      ${concatStringsSep " \\\n                  " (
                  map (
                    secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${
                      config.sops.secrets.${secret}.path
                    })\"'"
                  )
                  allSecrets
                )}
                  fi
                done
              '';
            };
      })
    ]);
  }

# Pi Coding Agent home-manager module.
#
# Bridges our homelab agent config (homelab.agentics.mkAgent) to the
# upstream programs.pi-coding-agent home-manager module.
#
# What the upstream handles:
#   settings (settings.json), context (AGENTS.md), package,
#   configDir (with PI_CODING_AGENT_DIR auto-export), keybindings, models
#
# What we keep custom:
#   translateMcpServer — generates writeShellScriptBin wrappers for
#     MCP servers with sops secret env/headers, resolving at runtime
#   mcp.json — writes MCP server config in pi's format
#   skills — symlinked to .pi/agent/skills/ (upstream has no skills option)
#   Secret injection — wraps the pi binary via symlinkJoin +
#     makeWrapper --run to export sops secrets into the environment
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.pi;

  # ---- Gather all secret names from MCP servers ----
  mcpSecrets = let
    extractSecretNames = attrs:
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
          extractSecretNames (srv.env or {})
          ++ extractSecretNames (srv.headers or {})
      )
      cfg.mcpServers
    );

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  hasMcpServers = cfg.mcpServers != {};

  # ---- Predicates for secret detection ----
  hasEnvSecret = srv:
    lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues (srv.env or {}));

  # ---- MCP server translation ----
  #
  # Converts homelab's MCP server config format to pi's mcp.json format:
  #   { mcpServers: { name: { transport, lifecycle, command, args, env } } }
  #
  # Servers with secrets in env/headers get wrapper scripts that resolve
  # at runtime from the environment (set by makeWrapper on the pi binary).
  translateMcpServer = name: srv:
    {
      transport = "stdio";
      lifecycle = "eager";
    }
    // (
      if (srv.url != null)
      then
        # HTTP/SSE transport → wrap via mcp-proxy
        let
          wrapperName = "pi-mcp-proxy-${name}";
          mkHeaderFlag = hname: val:
            if val ? "secret"
            then "--headers '${hname}' \"\${${baseNameOf val.secret}}\""
            else "--headers '${hname}' '${lib.escapeShellArg val}'";
          headerFlags = lib.concatStringsSep " \\\n                " (
            lib.mapAttrsToList mkHeaderFlag (srv.headers or {})
          );
          wrapper = pkgs.writeShellScriptBin wrapperName ''
            exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
              --transport streamablehttp \
              ${headerFlags} \
              '${srv.url}'
          '';
        in {
          command = "${wrapper}/bin/${wrapperName}";
          args = [];
        }
      else
        # Stdio transport
        if hasEnvSecret srv
        then
          # Env contains secrets → wrap via shell script that re-exports
          # the env vars (set by makeWrapper on pi binary) before exec-ing
          # the actual MCP command.
          let
            wrapperName = "pi-mcp-stdio-${name}";
            envExports = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                envName: value:
                  if value ? "secret"
                  then "export ${baseNameOf value.secret}=\"\$${baseNameOf value.secret}\""
                  else "export ${envName}=${lib.escapeShellArg value}"
              ) (srv.env or {})
            );
            argsStr = lib.concatStringsSep " " (map lib.escapeShellArg (srv.args or []));
            wrapper = pkgs.writeShellScriptBin wrapperName ''
              ${envExports}
              exec ${lib.escapeShellArg srv.command} ${argsStr}
            '';
          in {
            command = "${wrapper}/bin/${wrapperName}";
            args = [];
          }
        else {
          inherit (srv) command;
          args = srv.args or [];
          env = srv.env or {};
        }
    );
in
  with lib; {
    options.userapps.development.agents.pi = homelab.agentics.mkAgent {
      name = "pi";
      package = pkgs.pi-coding-agent;
      extraOptions = {
        packages = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            The packages to install for the pi agent (npm package names).
            Each name is added to the `packages` array in settings.json.
          '';
        };

        defaultProvider = mkOption {
          type = types.str;
          default = "opencode-go";
          description = "The name of the provider to register as default";
          example = "openrouter";
        };

        defaultModel = mkOption {
          type = types.str;
          default = "deepseek-v4-flash";
          description = "The name of the model to use as the default";
          example = "deepseek-v4-pro";
        };

        defaultThinkingLevel = mkOption {
          type = types.enum [
            "off"
            "minimal"
            "low"
            "medium"
            "high"
            "xhigh"
          ];
          default = "high";
          description = "The thinking level of the model";
          example = "low";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Base config: delegate to upstream HM module ──
      {
        programs.pi-coding-agent = {
          enable = true;
          package = mkDefault cfg.package;

          context =
            cfg.documents."AGENTS.md" or "";

          settings =
            {
              inherit (cfg) packages defaultProvider defaultModel defaultThinkingLevel;
            }
            // (cfg.userSettings or {});
        };

        # Extra files: MCP servers and skills (upstream doesn't handle these)
        home.file = mkMerge [
          (mkIf hasMcpServers {
            ".pi/agent/mcp.json".text = builtins.toJSON {
              mcpServers = builtins.mapAttrs translateMcpServer cfg.mcpServers;
            };
          })

          (mkIf (cfg.skills != {}) (
            mapAttrs' (name: skill: {
              name = ".pi/agent/skills/${name}";
              value = {
                source = skill;
                recursive = true;
              };
            })
            cfg.skills
          ))
        ];
      }

      # ── Secrets variant (sops + wrapped pi binary) ──
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        programs.pi-coding-agent.package = let
          pkg = cfg.package;
        in
          with pkgs;
            symlinkJoin {
              name = "${pkg.name}-wrapped";
              paths = [pkg];
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

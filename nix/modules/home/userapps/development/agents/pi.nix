{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.pi;
  shared = config.userapps.development.agents.agentics or {};

  # Merge shared agentics MCP servers with per-agent overrides (per-agent wins)
  mcpServers = {
    stdio = (shared.mcpServers.stdio or {}) // cfg.mcpServers.stdio;
    http = (shared.mcpServers.http or {}) // cfg.mcpServers.http;
  };
  skills = (shared.skills or {}) // cfg.skills;
  subagents =
    if builtins.isAttrs cfg.subagents && cfg.subagents != {}
    then cfg.subagents
    else shared.subagents or {};
  commands = (shared.commands or {}) // cfg.commands;
  agentContext =
    if cfg.context != ""
    then cfg.context
    else shared.context or "";

  hasMcpServers = mcpServers.stdio != {} || mcpServers.http != {};

  createContext = ctx: ''
    # Pi Runtime Context

    This file provides machine-level and user-level context for the Pi coding agent.
    Project-level repository guidance stays in the repository root
    `AGENTS.md`.

    ${ctx}
  '';

  # Shared MCP utilities
  mcpLib = lib.homelab.agentics.mcp;
  inherit
    (mcpLib)
    renderEnvValue
    renderHeaderValue
    ;

  # Translate agentics MCP server config to standard MCP config format
  # (compatible with pi-mcp-extension and omp's built-in MCP).
  mcpServerConfig = let
    renderServer = name: srv:
      {
        transport = "stdio";
        lifecycle = "eager";
      }
      // (
        if (srv ? "url" && srv ? "headers")
        then let
          wrapperName = "pi-mcp-proxy-${name}";
          headerFlags = lib.concatStringsSep " \\\n        " (
            lib.mapAttrsToList (
              hname: val:
                if val ? "secret"
                then "--headers '${hname}' \"${renderHeaderValue val}\""
                else "--headers '${hname}' '${val}'"
            ) (srv.headers or {})
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
          {
            inherit (srv) command args;
          }
          // (lib.optionalAttrs (srv.env or {} != {}) {
            env = lib.mapAttrs (_: renderEnvValue) srv.env;
          })
      );
  in {
    mcpServers = builtins.mapAttrs renderServer (mcpServers.stdio // mcpServers.http);
  };
in
  with lib; {
    options.userapps.development.agents.pi = homelab.agentics.mkAgent {
      name = "pi";
      package = pkgs.pi;
      extraOptions = {
        packages = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            The packages to install for the pi agent.
          '';
        };

        defaultProvider = mkOption {
          type = types.str;
          default = "opencode-go";
          description = ''
            The name of the provider to register as default
          '';
          example = "openrouter";
        };

        defaultModel = mkOption {
          type = types.str;
          default = "deepseek-v4-flash";
          description = ''
            The name of the model to use as the default
          '';
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
          description = ''
            The thinking level of the model
          '';
          example = "low";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # Provide a default empty context so `cfg.context` is always safe to read.
      # Users override via `userapps.development.agents.pi.context` or
      # `userapps.development.agents.agentics.context`.
      {userapps.development.agents.pi.context = mkDefault "";}

      {
        userapps.development.agents.pi = {
          secrets = mcpLib.extractSecrets {
            inherit (mcpServers) stdio http;
          };

          packages = mkIf hasMcpServers [
            "npm:pi-mcp-extension"
          ];
        };

        home = {
          packages = mkIf (cfg.secrets == []) [
            pkgs.pi
          ];

          file = mkMerge [
            {
              ".pi/agent/settings.json" = {
                text = builtins.toJSON (
                  {
                    inherit
                      (cfg)
                      packages
                      defaultProvider
                      defaultModel
                      defaultThinkingLevel
                      ;
                  }
                  // cfg.userSettings
                );
              };
            }
            (mkMerge [
              (mkIf (builtins.typeOf agentContext == "path") {
                "${config.home.homeDirectory}/.pi/agent/AGENTS.md".text = createContext (builtins.readFile agentContext);
              })
              (mkIf (builtins.typeOf agentContext == "str") {
                "${config.home.homeDirectory}/.pi/agent/AGENTS.md".text = createContext agentContext;
              })
            ])
            # Link skills from the shared agentics skills registry.
            (mkIf (skills != {}) (
              lib.mapAttrs' (name: skill: {
                name = ".pi/agent/skills/${name}";
                value = {
                  source = skill;
                  recursive = true;
                };
              })
              skills
            ))
            # Wire MCP servers.
            (mkIf hasMcpServers {
              ".pi/agent/mcp.json".text = builtins.toJSON mcpServerConfig;
            })

            # Wire subagents as markdown files.
            (mkIf (builtins.isAttrs subagents && subagents != {}) (
              lib.mapAttrs' (name: value: {
                name = ".pi/agent/subagents/${name}.md";
                value = {
                  text =
                    if builtins.isPath value
                    then builtins.readFile value
                    else value;
                };
              })
              subagents
            ))

            # Wire commands as a JSON file.
            (mkIf (commands != {}) {
              ".pi/agent/commands.json".text = builtins.toJSON commands;
            })
          ];
        };
      }
      (mkIf (cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "${cfg.package.name}-wrapped";
            paths = [cfg.package];
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
                cfg.secrets
              )}
                fi
              done
            '';
          })
        ];
      })
    ]);
  }

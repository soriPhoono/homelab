{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.pi;

  hasMcpServers = cfg.mcpServers.stdio != {} || cfg.mcpServers.http != {};

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

  # Translate MCP server config to pi MCP config format
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
    mcpServers = builtins.mapAttrs renderServer (cfg.mcpServers.stdio // cfg.mcpServers.http);
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
      {userapps.development.agents.pi.context = mkDefault "";}

      {
        userapps.development.enable = true;
        userapps.development.agents.pi = {
          secrets = mcpLib.extractSecrets {
            inherit (cfg.mcpServers) stdio http;
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
              (mkIf (builtins.typeOf cfg.context == "path") {
                "${config.home.homeDirectory}/.pi/agent/AGENTS.md".text = createContext (
                  builtins.readFile cfg.context
                );
              })
              (mkIf (builtins.typeOf cfg.context == "str") {
                "${config.home.homeDirectory}/.pi/agent/AGENTS.md".text = createContext cfg.context;
              })
            ])
            (mkIf (cfg.skills != {}) (
              lib.mapAttrs' (name: skill: {
                name = ".pi/agent/skills/${name}";
                value = {
                  source = skill;
                  recursive = true;
                };
              })
              cfg.skills
            ))
            # Wire MCP servers.
            (mkIf hasMcpServers {
              ".pi/agent/mcp.json".text = builtins.toJSON mcpServerConfig;
            })

            (mkIf (builtins.isAttrs cfg.subagents && cfg.subagents != {}) (
              lib.mapAttrs' (name: value: {
                name = ".pi/agent/subagents/${name}.md";
                value = {
                  text =
                    if builtins.isPath value
                    then builtins.readFile value
                    else value;
                };
              })
              cfg.subagents
            ))

            (mkIf (cfg.commands != {}) {
              ".pi/agent/commands.json".text = builtins.toJSON cfg.commands;
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

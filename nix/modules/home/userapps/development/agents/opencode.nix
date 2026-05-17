{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.opencode;

  cmdFromEntry = _name: value:
    if builtins.isPath value
    then builtins.readFile value
    else value;
in
  with lib; {
    options.userapps.development.agents.opencode = {
      enable = mkEnableOption ''
        Enable the OpenCode agent runtime and write shared system/user context
        to `~/.config/opencode/AGENTS.md`.
      '';
      enableDesktop = mkEnableOption "Enable OpenCode desktop application (requires opencode-desktop package)";

      secrets = mkOption {
        type = with types; listOf str;
        description = ''
          List of secrets to be injected into OpenCode runtime environment. Each secret
          will be defined in `config.sops.secrets` and will be made available as an
          environment variable with the same name as the secret key.
          e.g.: api/GITHUB_API_TOKEN will be available as {env:GITHUB_API_TOKEN} in OpenCode runtime.
        '';
        default = [];
      };

      plugins = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          npm package names to register as OpenCode plugins. Each name is added
          to the `plugin` array in OpenCode's config, causing OpenCode to
          auto-install and load them from npm at startup.

          e.g.: [ "opencode-swarm-plugin" ]
        '';
        example = ["opencode-swarm-plugin"];
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Attrs to express extra settings passed to opencode that do not belong to any other specific category. Also allows for advanced configuration via direct setting of configuration options
        '';
        example = {
          model = "opencode/deepseek-v4-flash";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs;
          mkIf cfg.enableDesktop [
            opencode-desktop
          ];

        home.file =
          lib.mapAttrs' (name: pkg: {
            name = ".config/opencode/skills/${name}";
            value = {
              source = pkg;
              recursive = true;
            };
          })
          agentsCfg.skills;

        programs.opencode = {
          enable = true;
          context = ''
            # OpenCode Runtime Context

            This file provides machine-level and user-level context for OpenCode.
            Project-level repository guidance stays in the repository root
            `AGENTS.md` and `.agents/AGENTS.md`.

            ${agentsCfg.context {}}
          '';
          commands =
            mapAttrs cmdFromEntry
            agentsCfg.commands.registry;
          settings =
            {
              mcp =
                builtins.mapAttrs (
                  _: mcpServer:
                    if (mcpServer.transport == "stdio")
                    then {
                      enabled = true;
                      type = "local";
                      command =
                        [
                          "${mcpServer.command}"
                        ]
                        ++ (mcpServer.args or []);
                      env =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${env:${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }"
                            else value
                        )
                        mcpServer.env;
                    }
                    else if (mcpServer.transport == "http")
                    then {
                      inherit (mcpServer) url;
                      enabled = true;
                      type = "remote";
                      headers =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${env:${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }"
                            else value
                        )
                        mcpServer.headers;
                    }
                    else if (mcpServer.transport == "sse")
                    then {
                      inherit (mcpServer) url;
                      enabled = true;
                      type = "remote";
                      headers =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${env:${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }"
                            else value
                        )
                        mcpServer.headers;
                    }
                    else throw "Unsupported transport protocol: ${mcpServer.transport}"
                )
                agentsCfg.mcp;
            }
            // lib.optionalAttrs (cfg.plugins != []) {
              plugin = cfg.plugins;
            };
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.opencode.package = pkgs.symlinkJoin {
          name = "opencode-wrapped";
          paths = [pkgs.opencode];
          buildInputs = [pkgs.makeWrapper];

          postBuild = ''
            for bin in $out/bin/*; do
              # Ensure it is actually a file and is executable before wrapping
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                # Pass ALL --run commands into a SINGLE wrapProgram invocation
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
        };
      })
    ]);
  }

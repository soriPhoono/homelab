{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.gemini;
in
  with lib; {
    options.userapps.development.agents.gemini = {
      enable = mkEnableOption ''
        Enable the Gemini CLI agent runtime and write shared system/user
        context to `~/.gemini/GEMINI.md`.
      '';

      secrets = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          A list of secrets to be made available to the `gemini-cli` environment.
          Each secret will be exposed as an environment variable with the same name as the secret, and its value will be sourced from a file specified in the `sops` configuration.
          For example, if you have a secret named `MY_SECRET` that corresponds to a file at `config.sops.secrets.MY_SECRET.path`, it will be available in the `gemini-cli` environment as an environment variable `MY_SECRET` with the contents of that file.
        '';
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Extra settings outside of critical integrations that are automatically handled, or MCP servers that are handled via the agentics library. This is intended for more advanced users who want to customize their Gemini CLI experience beyond the standard configuration options provided by this module.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.file =
          lib.mapAttrs'
          (name: pkg: {
            name = ".gemini/skills/${name}";
            value = {
              source = pkg;
              recursive = true;
            };
          })
          agentsCfg.skills;

        programs.gemini-cli = {
          enable = true;

          context = {
            AGENTS = ''
              # Gemini CLI Context

              This file provides machine-level and user-level context for Gemini CLI.
              Project-level repository guidance stays in the repository root
              `AGENTS.md` and `.agents/AGENTS.md`.

              ${agentsCfg.context {}}
            '';
          };

          settings =
            {
              ide = {
                enabled = true;
              };
              privacy = {
                usageStatisticsEnabled = false;
              };
              security = {
                auth = {
                  selectedType = "oauth-personal";
                };
              };
              tools = {
                autoAccept = false;
              };
              mcpServers =
                builtins.mapAttrs (
                  _: mcpServer:
                    if (mcpServer.transport == "stdio")
                    then {
                      inherit (mcpServer) command args;
                      env =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\$${value.environmentVariable}${
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
                      httpUrl = mcpServer.url;
                      headers =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\$${value.environmentVariable}${
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
                    }
                    else throw "Unsupported transport protocol: ${mcpServer.transport}"
                )
                agentsCfg.mcp;
            }
            // cfg.settings;
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.gemini-cli.package = pkgs.symlinkJoin {
          name = "gemini-wrapped";
          paths = [pkgs.gemini-cli];
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

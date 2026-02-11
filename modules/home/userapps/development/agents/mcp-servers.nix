{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agents;

  inherit (cfg) gemini;
in
  with lib; {
    options.userapps.development.agents.mcp-servers = mkOption {
      type = with types;
        attrsOf (submodule {
          options = {
            command = mkOption {
              type = str;
              description = "The command to run";
            };
            args = mkOption {
              type = listOf str;
              default = [];
              description = "The arguments to pass to the command";
            };
            env = mkOption {
              type = attrsOf str;
              default = {};
              description = "The environment variables to set";
            };
          };
        });
      default = {};
      description = "The MCP servers to run";
    };

    config = mkMerge [
      (mkIf gemini.enable {
        home.file.".gemini/settings.json" = {
          text = builtins.toJSON {
            mcpServers = mapAttrs (_: srv:
              {inherit (srv) command;}
              // optionalAttrs (srv.args != []) {inherit (srv) args;}
              // optionalAttrs (srv.env != {}) {inherit (srv) env;})
            cfg.mcp-servers;
          };
        };
      })
    ];
  }

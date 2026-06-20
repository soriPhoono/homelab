{lib, ...}: let
  inherit (lib) types;
in
  with lib; {
    options.userapps.development.agentics = {
      mcpServers = {
        stdio = mkOption {
          type = with types; attrsOf homelab.types.ai.stdioMcpServer;
          default = {};
          description = ''
            Shared stdio MCP servers available to all agent runtimes.
            Per-agent mcpServers are merged on top of these.
          '';
        };
        http = mkOption {
          type = with types; attrsOf homelab.types.ai.httpMcpServer;
          default = {};
          description = ''
            Shared HTTP MCP servers available to all agent runtimes.
            Per-agent mcpServers are merged on top of these.
          '';
        };
      };

      skills = mkOption {
        type = with types; attrsOf types.package;
        default = {};
        description = ''
          Shared skills available to all agent runtimes.
          Per-agent skills are merged on top of these.
        '';
      };

      subagents = mkOption {
        type = with types;
          oneOf [
            (attrsOf (oneOf [
              str
              path
            ]))
            path
          ];
        default = {};
        description = ''
          Shared subagents available to all agent runtimes.
          Per-agent subagents are merged on top of these.
        '';
      };

      commands = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = ''
          Shared commands available to all agent runtimes.
          Per-agent commands are merged on top of these.
        '';
      };

      context = mkOption {
        type = with types;
          oneOf [
            str
            path
          ];
        default = "";
        description = ''
          Shared agent context written to all agent runtimes.
          Per-agent context overrides this when set.
        '';
      };
    };
  }

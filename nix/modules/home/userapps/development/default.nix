{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.mcpServers;
in
  with lib; {
    imports = [
      ./agents
      ./editors
      ./terminal
    ];

    options.userapps.development.mcpServers = let
      jsonFormat = pkgs.formats.json {};
    in {
      enable = mkEnableOption "Enable Model Context Protocol (MCP) servers for AI agents (Globally)";

      servers = mkOption {
        inherit (jsonFormat) type;
        description = "MCP servers configuration to be shared across supported editors (e.g., OpenCode, ClaudeCode, Zed, etc.)";
        default = {};
        example = literalExpression ''
          {
            everything = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-everything"
              ];
            };
          }
        '';
      };
    };

    config = mkIf cfg.enable {
      programs.mcp = {
        enable = true;
        inherit (cfg) servers;
      };
    };
  }

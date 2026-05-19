{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agentics.mcp;
in
  with lib; {
    options.userapps.development.agentics.mcp = with types;
    with lib.homelab.types;
      mkOption {
        type = ai.mcpServerSet;
        default = {};
        description = "MCP servers to expose to consumers.";
      };

    config = {
      userapps.development.agentics = {
        agents.mcp = cfg;
      };
    };
  }

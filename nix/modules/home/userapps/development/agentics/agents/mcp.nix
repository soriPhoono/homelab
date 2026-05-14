{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agentics.agents.mcp;
  agentsCfg = config.userapps.development.agents;
in
  with lib; {
    options.userapps.development.agentics.agents.mcp = with types;
    with lib.homelab.types;
      mkOption {
        type = ai.mcpServerSet;
        default = {};
        description = "MCP servers to expose to consumers.";
      };

    config = let
      secrets = filter (name: name != null) (
        flatten (
          mapAttrsToList (
            _: server:
              mapAttrsToList (_: value:
                if value ? "secret"
                then value.secret
                else null) (
                server.env or {} // server.headers or {}
              )
          )
          cfg
        )
      );
    in {
      sops.secrets = genAttrs secrets (_: {});

      # TODO: this is a bit hacky, but it allows us to avoid having to duplicate the logic for extracting secrets from the harnesses config in each agent module (CHECK FOR INFINITE RECURSION)
      userapps.development.agents =
        mapAttrs (
          _: agent:
            if agent ? "secrets"
            then {
              inherit secrets;
            }
            else {}
        )
        agentsCfg;
    };
  }

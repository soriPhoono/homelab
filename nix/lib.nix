final: prev:
with prev; {
  homelab = {
    core = {
      discover = dir:
        prev.mapAttrs'
        (name: _: {
          name = prev.removeSuffix ".nix" name;
          value = dir + "/${name}";
        })
        (
          prev.filterAttrs (
            name: type:
              (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
              || (type == "regular" && name != "default.nix" && prev.hasSuffix ".nix" name)
          ) (builtins.readDir dir)
        );
    };

    agentics = {
      mkAgent = {
        name,
        package,
        extraOptions ? {},
      }:
        {
          enable = mkEnableOption "Enable the ${name} coding agent.";

          package = mkOption {
            type = types.package;
            description = "Package providing the ${name} agent.";
            default = package;
          };

          secrets = mkOption {
            type = with types; listOf str;
            default = [];
            description = "List of secrets to inject into the ${name} agent.";
          };

          userSettings = mkOption {
            type = with types;
              attrsOf (oneOf [
                # NOTE: Can grow as needed
                str
                int
                bool
              ]);
            default = {};
            description = "";
          };

          context = mkOption {
            type = with types;
              oneOf [
                str
                path
              ];
            description = ''
              The general AGENTS.md content for the ${name} agent.
              This provides the agent with user-specific context, such as preferences,
              project details, or other relevant information that can help the agent
              better understand and serve the user's needs.
            '';
          };

          skills = mkOption {
            type = with types; attrsOf types.package;
            default = {};
            description = ''
              The packages to symlink into the skills directory for the ${name} agent.
              Each package should contain a SKILL.md at its root.
            '';
          };

          mcpServers = {
            stdio = mkOption {
              type = with types; attrsOf final.homelab.types.ai.stdioMcpServer;
              default = {};
              description = ''
                The MCP servers to use for the ${name} agent that are backed by stdio communication.
              '';
            };
            http = mkOption {
              type = with types; attrsOf final.homelab.types.ai.httpMcpServer;
              default = {};
              description = ''
                The MCP servers to use for the ${name} agent that are backed by HTTP communication.
                Will be processed down to mcp-proxy configuration scripts.
              '';
            };
          };

          commands = mkOption {
            type = with types; attrsOf str;
            default = {};
            description = ''
              The commands to use for the ${name} agent.
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
              The subagents to use for the ${name} agent.
            '';
          };
        }
        // extraOptions;

      mcp = {
        # Render an env value (secret → $VAR, literal → value)
        renderEnvValue = value:
          if value ? "secret"
          then "$" + value.name
          else value;

        # Render a header value (secret → prefix + $VAR, literal → value)
        renderHeaderValue = value:
          if value ? "secret"
          then (value.prefix or "") + "$" + value.name
          else value;

        # Check if a server has secrets in its env
        hasEnvSecrets = srv:
          prev.any (v: builtins.isAttrs v && v ? "secret") (prev.attrValues (srv.env or {}));

        # Check if a server has secrets in its headers
        hasHeaderSecrets = srv:
          prev.any (v: builtins.isAttrs v && v ? "secret") (prev.attrValues (srv.headers or {}));

        # Extract secret names from MCP server env/headers.
        # Returns a flat list of secret name strings.
        extractSecrets = {
          stdio ? {},
          http ? {},
        }: let
          extractEnv = srv:
            prev.filter (v: v != null) (
              prev.mapAttrsToList (_: val:
                if val ? "secret"
                then val.secret
                else null) (srv.env or {})
            );
          extractHeaders = srv:
            prev.filter (v: v != null) (
              prev.mapAttrsToList (_: val:
                if val ? "secret"
                then val.secret
                else null) (srv.headers or {})
            );
        in
          prev.flatten (
            (prev.mapAttrsToList (_: extractEnv) stdio)
            ++ (prev.mapAttrsToList (_: extractHeaders) http)
          );
      };
    };

    types = with types; {
      ai = rec {
        env = oneOf [
          (submodule (sub: {
            options = {
              secret = mkOption {
                type = with types; str;
                default = null;
                description = "Sops secret name to load.";
                example = "api/OPENROUTER_API_KEY";
              };
              name = mkOption {
                type = with types; str;
                default =
                  if sub.config.secret != null
                  then "${baseNameOf sub.config.secret}"
                  else null;
                description = "Environment variable name to set.";
                example = "OPENROUTER_API_KEY";
              };
            };
          }))
          str
        ];

        stdioMcpServer = submodule {
          options = {
            command = mkOption {
              type = with types; str;
              description = "Executable path for stdio-backed MCP server.";
            };
            args = mkOption {
              type = with types; listOf str;
              default = [];
              description = "Arguments for stdio-backed MCP server.";
            };
            env = mkOption {
              type = with types; attrsOf env;
              default = {};
              description = "Environment variables passed to stdio-backed MCP server.";
            };
          };
        };

        header = oneOf [
          (submodule (sub: {
            options = {
              secret = mkOption {
                type = with types; str;
                default = null;
                description = "Sops secret name to load.";
                example = "api/OPENROUTER_API_KEY";
              };
              name = mkOption {
                type = with types; str;
                default =
                  if sub.config.secret != null
                  then "${baseNameOf sub.config.secret}"
                  else null;
                description = "Header name to set.";
                example = "OPENROUTER_API_KEY";
              };
              prefix = mkOption {
                type = with types; str;
                default = "";
                description = "Prefix to prepend to the header value (e.g. 'Bearer ').";
                example = "Bearer ";
              };
              suffix = mkOption {
                type = with types; str;
                default = "";
                description = "Suffix to append to the header value.";
                example = "";
              };
            };
          }))
          str
        ];

        httpMcpServer = submodule {
          options = {
            url = mkOption {
              type = with types; str;
              description = "Endpoint URL for remote MCP server.";
            };
            headers = mkOption {
              type = with types; attrsOf header;
              default = {};
              description = "Headers sent to remote MCP server.";
            };
          };
        };
      };
    };
  };
}

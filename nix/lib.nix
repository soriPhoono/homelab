_final: prev: {
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

    types = with prev;
    with types; {
      ai = rec {
        /**
        Editors will load the secret as a sops placeholder in template
        settings files, and the environmentVariable will be used by cli agents
        to read in environment variables baked in via sops, until a better solution
        can be found for editors to use the same mechanic as opposed to hardcoding
        secrets at rest in MCP config files.
        */
        envType = oneOf [
          (submodule (sub: {
            options = {
              secret = mkOption {
                type = with types; str;
                default = null;
                description = "Sops secret name to load.";
                example = "api/OPENROUTER_API_KEY";
              };
              environmentVariable = mkOption {
                type = with types; str;
                default =
                  if sub.config.secret != null
                  then "${baseNameOf sub.config.secret}"
                  else null;
                description = "Environment variable name to set.";
                example = "OPENROUTER_API_KEY";
              };
              prefix = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Prefix to add to the secret value.";
                example = "Bearer ";
              };
              suffix = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Suffix to add to the secret value.";
                example = "token";
              };
            };
          }))
          str
        ];

        mcpServerSet = attrsOf (
          submodule (_: {
            options = {
              transport = mkOption {
                type = with types;
                  enum [
                    "stdio"
                    "http"
                    "sse"
                  ];
                default = "http";
                description = "Transport protocol for the MCP server.";
              };

              # Stdio server options
              command = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Executable path for stdio-backed MCP servers.";
              };
              args = mkOption {
                type = with types; listOf str;
                default = [];
                description = "Arguments for stdio-backed MCP servers.";
              };
              env = mkOption {
                type = with types; attrsOf envType;
                default = {};
                description = "Environment variables passed to stdio-backed MCP servers.";
              };

              # HTTP server options
              url = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Endpoint URL for remote MCP servers.";
              };
              headers = mkOption {
                type = with types; attrsOf envType;
                default = {};
                description = "Headers sent to remote MCP servers.";
              };
            };
          })
        );
      };
    };
  };
}

_final: prev:
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

          documents = mkOption {
            type = with types; attrsOf either str path;
            default = {};
            description = ''
              The documents to symlink to the agents configuration directory for per session loading
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

          mcpServers = mkOption {
            type = with types;
              attrsOf (
                submodule (_: {
                  options = {
                    command = mkOption {
                      type = nullOr str;
                      default = null;
                      description = ''
                        The command for a stdio transport mcp server
                      '';
                    };
                    args = mkOption {
                      type = listOf str;
                      default = [];
                      description = ''
                        The list of command line args to give to this mcp server
                      '';
                    };
                    env = mkOption {
                      type = attrsOf (either str (submodule {
                        options = {
                          secret = mkOption {
                            type = str;
                            description = ''
                              The name of the sops secret to load in
                            '';
                          };
                        };
                      }));
                      default = {};
                      description = ''
                        The environment to pass to this mcp server
                      '';
                    };
                    url = mkOption {
                      type = nullOr str;
                      default = null;
                      description = ''
                        The url for a http transport mcp server
                      '';
                    };
                    headers = mkOption {
                      type = attrsOf (either str (submodule {
                        options = {
                          secret = mkOption {
                            type = str;
                            description = ''
                              The name of the sops secret to load in
                            '';
                          };
                        };
                      }));
                      default = {};
                      description = ''
                        The headers to pass to this mcp server
                      '';
                    };
                  };
                })
              );
          };
        }
        // extraOptions;
    };
  };
}

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
      mkEditor = {
        name,
        package,
        extraOptions ? {},
      }:
        {
          enable = mkEnableOption "Enable the ${name} text editor";

          package = mkOption {
            type = types.package;
            default = package;
            description = ''
              Package providing the ${name} editor.
            '';
          };

          secrets = mkOption {
            type = with types; listOf str;
            default = [];
            description = ''
              List of secrets to be injected into the ${name} editor.
            '';
          };

          defaultEditor = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether ${name} should be configured as the default editor
              via EDITOR and VISUAL environment variables.
            '';
          };

          priority = mkOption {
            type = types.int;
            default = 20;
            description = ''
              Priority for ${name} when registering MIME type associations
              and default application handlers. Higher values take precedence
              over lower ones.
            '';
          };

          userSettings = mkOption {
            type = types.attrs;
            default = {};
            description = ''
              Freeform user settings for the ${name} editor. The structure
              depends on the specific editor's configuration format (e.g.
              JSON for VS Code and Zed, TOML for Helix).
            '';
          };

          extraPackages = mkOption {
            type = types.listOf types.package;
            default = [];
            description = ''
              Extra packages to make available alongside the ${name} editor,
              such as LSP servers, formatters, or linters.
            '';
          };
        }
        // extraOptions;

      # mkVscodeEditor: merges mkEditor + mkAgent into one option namespace.
      # Editor options (common profiles, extensionProfiles, activeProfiles)
      # come from mkEditor. Agent options (documents, skills, mcpServers)
      # come from mkAgent and sit alongside editor options at the top level.
      # Shared keys (enable, package, secrets, userSettings) are editor-focused.
      mkVscodeEditor = {
        name,
        package,
        extraOptions ? {},
      }: let
        editorOpts = final.homelab.agentics.mkEditor {
          inherit name package;
          extraOptions = {
            common = mkOption {
              type = with types;
                submodule {
                  options = {
                    extensions = mkOption {
                      type = types.listOf types.package;
                      default = [];
                      description = "Extensions added to every profile.";
                    };
                    userTasks = mkOption {
                      type = attrs;
                      default = {};
                      description = "Tasks merged into every profile.";
                    };
                    keybindings = mkOption {
                      type = listOf attrs;
                      default = [];
                      description = "Keybindings added to every profile.";
                    };
                    languageSnippets = mkOption {
                      type = attrs;
                      default = {};
                      description = "Language snippets added to every profile.";
                    };
                    globalSnippets = mkOption {
                      type = attrs;
                      default = {};
                      description = "Global snippets added to every profile.";
                    };
                  };
                };
              default = {};
              description = "Common VS Code config merged into every active profile.";
            };

            extensionProfiles = mkOption {
              type = with types;
                attrsOf (submodule {
                  options = {
                    extensions = mkOption {
                      type = types.listOf types.package;
                      default = [];
                      description = "Extensions for this profile.";
                    };
                    userSettings = mkOption {
                      type = attrs;
                      default = {};
                      description = "Profile-specific settings on top of common.";
                    };
                    userTasks = mkOption {
                      type = attrs;
                      default = {};
                      description = "Profile-specific tasks on top of common.";
                    };
                    keybindings = mkOption {
                      type = listOf attrs;
                      default = [];
                      description = "Profile-specific keybindings.";
                    };
                    languageSnippets = mkOption {
                      type = attrs;
                      default = {};
                      description = "Profile-specific language snippets.";
                    };
                    globalSnippets = mkOption {
                      type = attrs;
                      default = {};
                      description = "Profile-specific global snippets.";
                    };
                  };
                });
              default = {};
              description = "Named VS Code profiles.";
            };

            activeProfiles = mkOption {
              type = with types; listOf str;
              default = ["default"];
              description = "Profiles to activate.";
            };

            agent = removeAttrs (final.homelab.agentics.mkAgent {
              name = "${name} agent";
              package = null;
            }) ["package" "secrets" "userSettings"];
          };
        };
      in
        # Merge editor base + agent extras.
        # For shared keys (enable, package, secrets, userSettings), editor wins.
        prev.recursiveUpdate editorOpts extraOptions;

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

          extraPackages = mkOption {
            type = types.listOf types.package;
            default = [];
            description = "Extra packages to install alongside the hermes agent";
          };

          environment = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Environment variables for the hermes agent, NO SECRETS HERE";
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

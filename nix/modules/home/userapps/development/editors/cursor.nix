/**
Cursor editor module
- Requires dynamically enabling github desktop (DONE)
- Requires setting mime associations for text (DONE)
- Configure settings for editor (e.g. font, theme) (DONE)
- Install editor extensions (DONE)
- Configure stylix for editor (optional) (DONE)
- Requires setting cursor rules for editor agent context (DONE)
- Requires dynamically generating cursor mcp config (DONE)
*/
{
  inputs,
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  editorCfg = config.userapps.development.agentics.editors;
  cfg = config.userapps.development.editors.cursor;

  stylixVscodeModule = inputs.stylix + "/modules/vscode";

  codeMimeTypes = [
    "inode/x-empty"
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "text/javascript"
    "text/css"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-cmake"
    "text/x-diff"
    "text/x-go"
    "text/x-java"
    "text/x-kotlin"
    "text/x-lua"
    "text/x-makefile"
    "text/x-nix"
    "text/x-python"
    "text/x-ruby"
    "text/x-rust"
    "text/x-script.python"
    "text/x-shellscript"
    "text/x-sql"
    "text/x-toml"
    "text/x-typescript"
    "text/x-typescript-jsx"
    "text/x-yaml"
    "application/json"
    "application/ld+json"
    "application/javascript"
    "application/toml"
    "application/xml"
    "application/x-shellscript"
    "application/x-yaml"
  ];
in
  with lib; {
    options.userapps.development.editors.cursor = {
      enable = mkEnableOption "Enable cursor text editor";

      priority = mkOption {
        type = types.int;
        default = 30;
        description = "Priority for being the default editor. Lower is higher priority.";
      };

      extensions = mkOption {
        type = with types; listOf package;
        default = [];
        description = "List of VSCode extensions to install.";
      };

      userSettings = mkOption {
        type = with types; attrs;
        default = {};
        description = "User settings for VSCode.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.file = {
          ".cursor/rules/editor-agent-context.mdc" = {
            text = ''
              ---
              alwaysApply: true
              ---

              ${editorCfg.context {}}
            '';
          };
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe config.programs.cursor.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) codeMimeTypes)
            )
        );

        userapps.development = {
          infrastructure.github = {
            enable = true;
            enableDesktop = true;
          };
          agents.cursor = {
            enable = true;
          };
        };

        programs.cursor = {
          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      }
      (mkIf config.stylix.enable (
        let
          inherit (config.stylix.targets.vscode) profileNames;
        in {
          warnings =
            optional (profileNames == [])
            "stylix (cursor editor): `config.stylix.targets.vscode.profileNames` is empty. No Stylix theming will be applied to Cursor; set profile names (e.g. [ \"default\" ]).";

          stylix.targets.vscode.enable = mkDefault false;

          programs.cursor.profiles = genAttrs profileNames (_: {
            extensions = singleton (
              pkgs.runCommandLocal "stylix-vscode"
              {
                vscodeExtUniqueId = "stylix.stylix";
                vscodeExtPublisher = "stylix";
                version = "0.0.0";
                theme = builtins.toJSON (
                  import (stylixVscodeModule + "/templates/theme.nix") config.lib.stylix.colors
                );
                passAsFile = ["theme"];
              }
              ''
                mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId/themes"
                ln -s ${
                  stylixVscodeModule + "/package.json"
                } "$out/share/vscode/extensions/$vscodeExtUniqueId/package.json"
                cp "$themePath" "$out/share/vscode/extensions/$vscodeExtUniqueId/themes/stylix.json"
              ''
            );

            userSettings = import (stylixVscodeModule + "/templates/settings.nix") config.stylix.fonts;
          });
        }
      ))
      (mkIf (options ? sops) {
        sops.templates."cursor/mcp.json" = {
          path = "${config.home.homeDirectory}/.cursor/mcp.json";
          content = builtins.toJSON {
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
                          }${config.sops.placeholder.${value.secret}}${
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
                    inherit (mcpServer) url;
                    headers =
                      builtins.mapAttrs (
                        _: value:
                          if value ? "secret"
                          then "${
                            if value.prefix != null
                            then value.prefix
                            else ""
                          }${config.sops.placeholder.${value.secret}}${
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
                    inherit (mcpServer) url;
                    headers =
                      builtins.mapAttrs (
                        _: value:
                          if value ? "secret"
                          then "${
                            if value.prefix != null
                            then value.prefix
                            else ""
                          }${config.sops.placeholder.${value.secret}}${
                            if value.suffix != null
                            then value.suffix
                            else ""
                          }"
                          else value
                      )
                      mcpServer.headers;
                  }
                  else throw "Unsupported MCP transport: ${mcpServer.transport}"
              )
              editorCfg.mcp;
          };
        };
      })
    ]);
  }

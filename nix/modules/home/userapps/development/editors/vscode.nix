# TODO: finish implementing mcp servers for antigravity to comply with immutable extension dirs
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;

  # Must not be named `package`: that shadows `types.package` in `listOf package` below.
  editorPackage =
    if cfg.vendor == "vscode"
    then pkgs.vscode
    else if cfg.vendor == "cursor"
    then pkgs.code-cursor
    else if cfg.vendor == "oss-code"
    then pkgs.vscodium
    else null;

  # Stylix only ships programs.vscode integration (nix-community/stylix modules/vscode/hm.nix).
  stylixVscodeModule = inputs.stylix + "/modules/vscode";
in
  with lib; {
    options.userapps.development.editors.vscode = {
      enable = mkEnableOption "Enable vscode text editor";

      vendor = mkOption {
        type = with types; enum ["oss-code" "vscode" "cursor"];
        default = "oss-code";
        description = ''
          Which VSCode-family editor vendor to use.
          - "oss-code" -> default (pkgs.vscodium)
          - "vscode" -> pkgs.vscode
          - "cursor" -> pkgs.code-cursor
        '';
      };

      priority = mkOption {
        type = types.int;
        default = 40;
        description = "Priority for being the default editor. Lower is higher priority.";
      };

      extensions = mkOption {
        type = with types; listOf types.package;
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
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority (lib.getExe editorPackage);
          VISUAL = mkOverride cfg.priority (lib.getExe editorPackage);
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
          editor = ["${baseNameOf (lib.getExe editorPackage)}.desktop"];
        in
          mkOverride cfg.priority {
            "text/plain" = editor;
            "text/markdown" = editor;
            "application/x-shellscript" = editor;
          });
      }
      (mkIf (cfg.vendor != "oss-code") {
        userapps.development.infrastructure.github = {
          enable = mkDefault true;
          enableDesktop = mkDefault true;
        };
      })
      (mkIf (cfg.vendor == "oss-code") {
        programs.vscode = {
          package = editorPackage;

          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      })
      (mkIf (cfg.vendor == "vscode") {
        userapps.development.agents.github-copilot = {
          enable = mkDefault true;
        };

        programs.vscode = {
          package = editorPackage;

          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      })
      (mkIf (cfg.vendor == "cursor") (mkMerge [
        {
          userapps.development.agents.cursor = {
            enable = mkDefault true;
          };

          programs.cursor = {
            package = editorPackage;

            enable = true;
            mutableExtensionsDir = false;

            profiles.default = {
              inherit (cfg) extensions userSettings;

              enableExtensionUpdateCheck = false;
              enableUpdateCheck = false;
            };
          };
        }
        (mkIf (config.stylix.enable && config.programs.cursor.enable) (let
          inherit (config.stylix.targets.vscode) profileNames;
        in
          mkMerge [
            {
              stylix.targets.vscode.enable = mkDefault false;
            }
            {
              warnings =
                optional
                (profileNames == [])
                "stylix (cursor editor): `config.stylix.targets.vscode.profileNames` is empty. No Stylix theming will be applied to Cursor; set profile names (e.g. [ \"default\" ]).";
            }
            {
              programs.cursor.profiles = genAttrs profileNames (_: {
                extensions = singleton (
                  pkgs.runCommandLocal "stylix-vscode"
                  {
                    vscodeExtUniqueId = "stylix.stylix";
                    vscodeExtPublisher = "stylix";
                    version = "0.0.0";
                    theme = builtins.toJSON (import (stylixVscodeModule + "/templates/theme.nix") config.lib.stylix.colors);
                    passAsFile = ["theme"];
                  }
                  ''
                    mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId/themes"
                    ln -s ${stylixVscodeModule + "/package.json"} "$out/share/vscode/extensions/$vscodeExtUniqueId/package.json"
                    cp "$themePath" "$out/share/vscode/extensions/$vscodeExtUniqueId/themes/stylix.json"
                  ''
                );
              });
            }
            {
              programs.cursor.profiles = genAttrs profileNames (_: {
                userSettings = import (stylixVscodeModule + "/templates/settings.nix") config.stylix.fonts;
              });
            }
          ]))
      ]))
    ]);
  }

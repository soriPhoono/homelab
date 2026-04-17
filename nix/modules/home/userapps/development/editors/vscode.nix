# TODO: finish implementing mcp servers for antigravity to comply with immutable extension dirs
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;
in
  with lib; {
    options.userapps.development.editors.vscode = {
      enable = mkEnableOption "Enable vscode text editor";

      package = mkOption {
        type = types.package;
        default = pkgs.vscodium;
        description = "The vscode package to use.";
      };

      priority = mkOption {
        type = types.int;
        default = 40;
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

    config =
      mkIf cfg.enable
      {
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority (lib.getExe cfg.package);
          VISUAL = mkOverride cfg.priority (lib.getExe cfg.package);
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
          editor = ["${baseNameOf (lib.getExe cfg.package)}.desktop"];
        in
          mkOverride cfg.priority {
            "text/plain" = editor;
            "text/markdown" = editor;
            "application/x-shellscript" = editor;
          });

        programs.vscode = {
          inherit (cfg) package;

          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      };
  }

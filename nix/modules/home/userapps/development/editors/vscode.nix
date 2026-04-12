# TODO: finish fixes here
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
        # NOTE: Lower priority than terminal editors
        #   by default, zed still gets priority given
        #   it's advanced features in combination with
        #   it's light weight nature.
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

    config = mkIf cfg.enable {
      home.sessionVariables = {
        EDITOR = mkOverride cfg.priority (lib.getExe cfg.package);
        VISUAL = mkOverride cfg.priority (lib.getExe cfg.package);
      };

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        editor = ["${lib.getExe cfg.package}.desktop"];
      in
        mkOverride cfg.priority {
          "text/plain" = editor;
          "text/markdown" = editor;
          "application/x-shellscript" = editor;
        });

      programs.vscode = {
        enable = true;
        inherit (cfg) package;

        profiles.default = {
          inherit (cfg) extensions userSettings;

          enableExtensionUpdateCheck = false;
          enableUpdateCheck = false;
        };
      };
    };
  }

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

      desktop = mkOption {
        type = types.str;
        default = let
          appsDir = "${cfg.package}/share/applications";
        in
          if pathExists appsDir
          then let
            entries = builtins.readDir appsDir;
            desktopFiles = filter (name: hasSuffix ".desktop" name) (attrNames entries);
          in
            if desktopFiles != []
            then head desktopFiles
            else "code.desktop"
          else "code.desktop";
        description = "The desktop file name for the editor.";
      };

      priority = mkOption {
        type = types.int;
        default = 30; # Lower priority than terminal editors by default
        description = "Priority for being the default editor. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        EDITOR = mkOverride cfg.priority (getExe cfg.package);
        VISUAL = mkOverride cfg.priority (getExe cfg.package);
      };

      xdg.mimeApps.defaultApplications = let
        editor = [cfg.desktop];
      in
        mkOverride cfg.priority {
          "text/plain" = editor;
          "text/markdown" = editor;
          "application/x-shellscript" = editor;
        };

      programs.vscode = {
        enable = true;
        package = mkDefault cfg.package;
      };
    };
  }

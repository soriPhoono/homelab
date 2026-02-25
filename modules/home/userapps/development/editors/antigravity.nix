{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.antigravity;
in
  with lib; {
    options.userapps.development.editors.antigravity = {
      enable = mkEnableOption "Enable antigravity text editor";

      package = mkOption {
        type = types.package;
        default = pkgs.antigravity;
        description = "The antigravity package to use.";
      };

      desktop = mkOption {
        type = types.str;
        default = "antigravity.desktop";
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
        EDITOR = mkOverride cfg.priority (lib.getExe cfg.package);
        VISUAL = mkOverride cfg.priority (lib.getExe cfg.package);
      };

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        editor = [cfg.desktop];
      in
        mkOverride cfg.priority {
          "text/plain" = editor;
          "text/markdown" = editor;
          "application/x-shellscript" = editor;
        });

      home.packages = [
        cfg.package
      ];
    };
  }

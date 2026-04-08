{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.micro;
in
  with lib; {
    options.userapps.development.editors.micro.priority = mkOption {
      type = types.int;
      default = 10;
      description = "Priority for being the default editor. Lower is higher priority.";
    };

    config = {
      home.sessionVariables = {
        EDITOR = mkOverride cfg.priority "micro";
        VISUAL = mkOverride cfg.priority "micro";
      };

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        editor = ["micro.desktop"];
      in
        mkOverride cfg.priority {
          "text/plain" = editor;
          "text/markdown" = editor;
          "application/x-shellscript" = editor;
        });

      programs.micro.enable = true;
    };
  }

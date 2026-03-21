{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.neovim;
in
  with lib; {
    options.userapps.development.editors.neovim = {
      enable = mkEnableOption "Enable neovim";

      priority = mkOption {
        type = types.int;
        default = 20;
        description = "Priority for being the default editor. Lower is higher priority.";
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Neovim settings";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        EDITOR = mkOverride cfg.priority "nvim";
        VISUAL = mkOverride cfg.priority "nvim";
      };

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        editor = ["nvim.desktop"];
      in
        mkOverride cfg.priority {
          "text/plain" = editor;
          "text/markdown" = editor;
          "application/x-shellscript" = editor;
        });

      programs.nvf = {
        enable = true;

        settings.vim = cfg.settings;
      };
    };
  }

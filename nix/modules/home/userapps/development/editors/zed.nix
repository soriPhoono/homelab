{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.zed;
in
  with lib; {
    options.userapps.development.editors.zed = let
      jsonFormat = pkgs.formats.json {};
    in {
      enable = mkEnableOption "Enable zed editors";

      userDebug = mkOption {
        inherit (jsonFormat) type;
        description = "User debug settings for zed editor";
        default = {};
      };

      userKeymaps = mkOption {
        inherit (jsonFormat) type;
        description = "User keymaps for zed editor";
        default = {};
      };

      userSettings = mkOption {
        inherit (jsonFormat) type;
        description = "User settings for zed editor";
        default = {};
      };

      userTasks = mkOption {
        inherit (jsonFormat) type;
        description = "User tasks for zed editor";
        default = {};
      };

      extensions = mkOption {
        type = with types; listOf str;
        description = "Names of extensions to auto install from [the master list](https://github.com/zed-industries/extensions/tree/main/extensions)";
        default = [];
      };
    };

    config = mkIf cfg.enable {
      programs.zed-editor = {
        inherit
          (cfg)
          userDebug
          userKeymaps
          userSettings
          userTasks
          extensions
          ;

        enable = true;
        enableMcpIntegration = true;

        mutableUserDebug = false;
        mutableUserKeymaps = false;
        mutableUserSettings = false;
        mutableUserTasks = false;
      };
    };
  }

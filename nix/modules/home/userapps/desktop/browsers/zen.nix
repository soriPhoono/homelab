{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.browsers.zen;
  baseConfig = {
    enable = true;
    nativeMessagingHosts = with pkgs; [firefoxpwa];
  };
in
  with lib; {
    imports = [
      inputs.zen-browser.homeModules.twilight
    ];

    options.userapps.desktop.browsers.zen = {
      enable =
        mkEnableOption "Enable Zen Browser"
        // {
          default = true;
        };

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default browser. Lower is higher priority.";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Extra configuration to pass to programs.zen-browser.
          This can be used to override or extend the default configuration.
        '';
      };

      profileConfig = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = ''
          Per-profile configuration that gets merged into extraConfig.
          Each attribute represents a profile name (e.g., "default").
          Use this for cleaner organization in user configs.
        '';
      };
    };

    config = mkIf cfg.enable {
      stylix.targets.zen-browser.enable = false;

      home.sessionVariables.BROWSER = "zen-twilight";

      userapps.desktop.browsers.enable = true;

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        browser = ["zen-twilight.desktop"];
      in
        mkOverride cfg.priority {
          "text/html" = browser;
          "text/xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        });

      programs.zen-browser = recursiveUpdate baseConfig (
        recursiveUpdate
        cfg.extraConfig
        {profiles = cfg.profileConfig;}
      );
    };
  }

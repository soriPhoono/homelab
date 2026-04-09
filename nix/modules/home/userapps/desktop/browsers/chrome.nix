{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.browsers.chrome;
in
  with lib; {
    options.userapps.desktop.browsers.chrome = {
      enable =
        mkEnableOption "Enable Google Chrome.";

      priority = mkOption {
        type = types.int;
        default = 40;
        description = "Priority for being the default browser. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      userapps.desktop.browsers = {
        enable = true;
        zen.enable = mkDefault false;
      };

      home = {
        sessionVariables.BROWSER = mkOverride cfg.priority "google-chrome";
        packages = with pkgs; [
          google-chrome
        ];
      };

      xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications.enable (let
        browser = ["google-chrome.desktop"];
      in
        mkOverride cfg.priority {
          "text/html" = browser;
          "text/xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        });
    };
  }

{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.userapps.browsers.zen;
in
  with lib; {
    imports =
      if cfg.enable
      then
        if cfg.beta
        then optionals inputs.zen-browser.homeModules.beta
        else optionals inputs.zen-browser.homeModules.twilight
      else []; # CHECK THIS

    options.userapps.browsers.zen = {
      enable = mkEnableOption "Enable Zen Browser";

      beta = mkEnableOption "Use the beta version of Zen Browser instead of twilight";

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default browser. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      userapps.browsers.enable = true;
      userapps.browsers.chrome.enable = mkDefault false;

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        browser = [
          (
            if cfg.beta
            then "zen-beta.desktop"
            else "zen-twilight.desktop"
          )
        ];
      in
        lib.mkOverride cfg.priority {
          "text/html" = browser;
          "text/xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        });

      programs.zen-browser = {
      };
    };
  }

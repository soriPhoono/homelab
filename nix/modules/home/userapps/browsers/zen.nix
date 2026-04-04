{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.userapps.browsers.zen;
in {
  options.userapps.browsers.zen = {
    enable = lib.mkEnableOption "Enable Zen Browser";

    beta = lib.mkEnableOption "Use the beta version of Zen Browser instead of twilight";

    priority = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Priority for being the default browser. Lower is higher priority.";
    };
  };

  config = lib.mkIf cfg.enable {
    userapps.browsers.enable = true;
    userapps.browsers.chrome.enable = lib.mkDefault false;

    home.packages = [
      (
        if cfg.beta
        then inputs.zen-browser.packages."${pkgs.system}".beta
        else inputs.zen-browser.packages."${pkgs.system}".twilight
      )
    ];

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
  };
}

{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.browsers.chrome;
in {
  options.userapps.browsers.chrome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Google Chrome. Defaults to true if no other browsers are enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    userapps.browsers.enable = true;

    home.packages = with pkgs; [
      google-chrome
    ];

    xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
      browser = ["google-chrome.desktop"];
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

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
      default = let
        otherBrowsers = lib.filterAttrs (name: _: name != "chrome") config.userapps.browsers;
      in
        !lib.any (b: b.enable) (lib.attrValues otherBrowsers);
      description = "Enable Google Chrome. Defaults to true if no other browsers are enabled.";
    };
    priority = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Priority for being the default browser. Lower is higher priority.";
    };
  };

  config = lib.mkIf cfg.enable {
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

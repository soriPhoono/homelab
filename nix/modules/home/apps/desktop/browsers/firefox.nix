{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.browsers.firefox;
in
  with lib; {
    options.apps.desktop.browsers.firefox = {
      enable = lib.mkEnableOption "Enable Firefox";
      priority = lib.mkOption {
        type = lib.types.int;
        default = 20;
        description = "Priority for being the default browser. Lower is higher priority.";
      };
    };

    config = lib.mkIf cfg.enable {
      home.sessionVariables.BROWSER = mkOverride cfg.priority "firefox";

      apps.desktop.browsers = {
        enable = true;
        zen.enable = lib.mkDefault false;
      };

      xdg.mimeApps.defaultApplications = lib.mkIf config.apps.defaultApplications.enable (let
        browser = ["firefox.desktop"];
      in
        lib.mkOverride cfg.priority {
          "text/html" = browser;
          "text/xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        });

      programs = {
        firefox = {
          enable = true;
          package = pkgs.firefox-bin;

          profiles.default = {
            id = 0;
            name = "default";
            isDefault = true;

            search = {
              force = true;
              order = ["ddg"];
              default = "ddg";
              engines = {
                "google".metaData.hidden = true;
                "bing".metaData.hidden = true;
              };
            };

            extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
              ublock-origin
              privacy-badger
              bitwarden
            ];

            settings = {
              extensions.autoDisableScopes = 0;
              browser = {
                search = {
                  defaultenginename = "DuckDuckGo";
                  "order.1" = "DuckDuckGo";
                };
              };
              "browser.startup.page" = 1;
              "browser.startup.homepage" = "http://127.0.0.1:8082";
              "browser.newtabpage.enabled" = false;
            };
          };

          policies = {
            DisableTelementry = true;
            DisplayBookmarksToolbar = "never";
          };
        };
      };

      stylix.targets.firefox.profileNames = ["default"];
    };
  }

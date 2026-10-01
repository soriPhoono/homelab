{ inputs, ... }: {
  flake-file.inputs.zen-browser.url = "github:0xc000022070/zen-browser-flake";
  den.aspects.sphoono.homeManager = { pkgs, ... }: {
    imports = [
      inputs.zen-browser.homeModules.twilight
    ];
    xdg.mimeApps.defaultApplications =
      let
        browser = [ "zen-twilight.desktop" ];
      in
      {
        "text/html" = browser;
        "text/xml" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
      };
    programs.zen-browser = {
      enable = true;
      nativeMessagingHosts = [ pkgs.firefoxpwa ];
      setAsDefaultBrowser = true;
      enablePrivateDesktopEntry = false;
      profiles.default = {
        id = 0;
        isDefault = true;
        # keyboardShortcutsVersion = 20;
        keyboardShortcuts = [
          {
            id = "zen-compact-mode-toggle";
            key = "c";
            modifiers.control = true;
            modifiers.alt = true;
          }
          {
            id = "zen-toggle-sidebar";
            key = "x";
            modifiers.control = true;
            modifiers.alt = true;
          }
          {
            id = "key_savePage";
            key = "s";
            modifiers.control = true;
          }
          {
            id = "key_quitApplication";
            disabled = true;
          }
        ];
        spacesForce = true;
        spaces = {
          Personal = {
            id = "f1a2b3c4-d5e6-7890-abcd-ef1234567801";
            icon = "🏠";
            container = 1;
            position = 1000;
            theme = {
              type = "gradient";
              colors = [
                {
                  algorithm = "floating";
                  type = "explicit-lightness";
                  red = 69;
                  green = 107;
                  blue = 188;
                  lightness = 35;
                  position = {
                    x = 51;
                    y = 97;
                  };
                }
              ];
              opacity = 0.4;
            };
          };
          Work = {
            id = "a1b2c3d4-e5f6-7890-bcde-f12345678901";
            icon = "💼";
            container = 2;
            position = 2000;
            theme = {
              type = "gradient";
              colors = [
                {
                  algorithm = "floating";
                  type = "explicit-lightness";
                  red = 121;
                  green = 94;
                  blue = 171;
                  lightness = 35;
                  position = {
                    x = 68;
                    y = 137;
                  };
                }
              ];
              opacity = 0.4;
            };
          };
          Development = {
            id = "b2c3d4e5-f6a7-8901-cdef-012345678902";
            icon = "🛠️";
            container = 3;
            position = 3000;
            theme = {
              type = "gradient";
              colors = [
                {
                  algorithm = "floating";
                  type = "explicit-lightness";
                  red = 99;
                  green = 147;
                  blue = 133;
                  lightness = 35;
                  position = {
                    x = 100;
                    y = 100;
                  };
                }
              ];
              opacity = 0.4;
            };
          };
          School = {
            id = "c3d4e5f6-a7b8-9012-defa-123456789013";
            icon = "📚";
            container = 4;
            position = 4000;
            theme = {
              type = "gradient";
              colors = [
                {
                  algorithm = "floating";
                  type = "explicit-lightness";
                  red = 167;
                  green = 109;
                  blue = 87;
                  lightness = 35;
                  position = {
                    x = 80;
                    y = 120;
                  };
                }
              ];
              opacity = 0.4;
            };
          };
          Shopping = {
            id = "d4e5f6a7-b8c9-0123-efab-234567890124";
            icon = "🛒";
            container = 5;
            position = 5000;
            theme = {
              type = "gradient";
              colors = [
                {
                  algorithm = "floating";
                  type = "explicit-lightness";
                  red = 164;
                  green = 138;
                  blue = 99;
                  lightness = 35;
                  position = {
                    x = 60;
                    y = 110;
                  };
                }
              ];
              opacity = 0.4;
            };
          };
        };
        containersForce = true;
        containers = {
          Personal = {
            color = "blue";
            icon = "chill";
            id = 1;
          };
          Work = {
            color = "purple";
            icon = "briefcase";
            id = 2;
          };
          Development = {
            color = "green";
            icon = "circle";
            id = 3;
          };
          School = {
            color = "orange";
            icon = "tree";
            id = 4;
          };
          Shopping = {
            color = "yellow";
            icon = "cart";
            id = 5;
          };
        };
      };
    };
    services.psd = {
      enable = true;
      resyncTimer = "10m";
    };
    stylix.targets.zen-browser.enable = false;
  };
}

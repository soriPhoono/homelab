{ den, ... }: {
  den.aspects.spookyskelly = {
    includes = [
      (den.batteries.unfree [
        "discord"
        "discord-unwrapped"
        "obsidian"
        "firefox-bin-unwrapped"
        "firefox-bin"
      ])
    ];
    homeManager = { pkgs, ... }: {
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
              order = [ "ddg" ];
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
              "extensions.autoDisableScopes" = 0;
              "browser.search.defaultenginename" = "DuckDuckGo";
              "browser.search.order.1" = "DuckDuckGo";
              "browser.startup.page" = 1;
              "browser.startup.homepage" = "http://127.0.0.1:8082";
              "browser.newtabpage.enabled" = false;
            };
          };
          policies = {
            DisableTelemetry = true;
            DisplayBookmarksToolbar = "never";
          };
        };
        discord.enable = true;
        element-desktop.enable = true;
        obsidian.enable = true;
        obs-studio.enable = true;
      };

      home.packages = with pkgs; [
        # Communication
        telegram-desktop
        signal-desktop
        # Office
        libreoffice-stable
        hunspell
        hunspellDicts.en_US
        onlyoffice-desktopeditors
        # Data
        nextcloud-client
        bitwarden-desktop
        qbittorrent
        # Content creation
        krita
        gimp
        darktable
        blender
        audacity
        kdePackages.kdenlive
      ];
    };
  };
}

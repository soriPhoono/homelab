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

{
  core = {
    secrets.enable = true;

    shells = {
      starship.enable = true;
      fastfetch.enable = true;
    };
  };

  userapps = {
    defaultApplications.enable = true;
    desktop = {
      browsers = {
        firefox.enable = true;
        zen.enable = true;
      };
      communication = {
        discord.enable = true;
        signal.enable = true;
        matrix.enable = true;
      };
      office.onlyoffice.enable = true;
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
      qbittorrent.enable = true;
    };
    content-creation = {
      asset-creation = {
        krita.enable = true;
        gimp.enable = true;
        blender.enable = true;
      };
      editors = {
        audacity.enable = true;
        kdenlive.enable = true;
      };
      streaming = {
        obs-studio.enable = true;
      };
    };
  };
}

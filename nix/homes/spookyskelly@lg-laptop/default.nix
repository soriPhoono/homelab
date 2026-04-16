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
      cloud.nextcloud.enable = true;
      auth.bitwarden.enable = true;
      notes.obsidian.enable = true;
      p2p.qbittorrent.enable = true;
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

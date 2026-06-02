_: {
  userapps = {
    defaultApplications.enable = true;
    desktop = {
      file-browser = {
        plugins.gdrive.enable = true;
        nautilus.enable = true;
      };
      players = {
        imv.enable = true;
        mpv.enable = true;
        audio.strawberry.enable = true;
        video.vlc.enable = true;
      };
      browsers.zen.enable = true;
      tools.easyeffects.enable = true;
      communication = {
        discord.enable = true;
        telegram.enable = true;
        signal.enable = true;
        matrix.enable = true;
      };
      office = {
        zathura.enable = true;
        libreoffice.enable = true;
        slack.enable = true;
      };
      virtualization = {
        distrobox.enable = true;
        # bottles.enable = true;
      };
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      agents.pi-agent = {
        enable = true;
        flavor = "omp";
      };
      editors = {
        zed.enable = true;
      };
      appliances.bambu-studio.enable = true;
    };
    data-fortress = {
      cloud.nextcloud.enable = true;
      auth.bitwarden.enable = true;
      notes.obsidian.enable = true;
      p2p.qbittorrent.enable = true;
    };
    content-creation = {
      asset-creation = {
        gimp.enable = true;
        blender.enable = true;
      };
      streaming.obs-studio.enable = true;
      editors = {
        audacity.enable = true;
        kdenlive.enable = true;
      };
    };
  };
}

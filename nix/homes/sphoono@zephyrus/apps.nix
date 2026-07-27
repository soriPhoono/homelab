_: {
  apps = {
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
        calibre.enable = true;
        libreoffice.enable = true;
        slack.enable = true;
      };
      virtualization = {
        distrobox.enable = true;
        bottles.enable = true;
      };
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      agents = {
        antigravity.enableCli = true;
        hermes = {
          enableCli = true;
          enableDesktop = true;
        };
      };
      editors.antigravity.enable = true;
    };
    data-fortress = {
      p2p.qbittorrent.enable = true;
      notes.obsidian.enable = true;
    };
  };
}

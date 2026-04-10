{
  userapps = {
    defaultApplications.enable = true;
    desktop = {
      file-browser.nautilus.enable = true;
      players = {
        mpv.enable = true;
        audio.rhythmbox.enable = true;
        video.vlc.enable = true;
      };
      browsers.zen.enable = true;
      communication = {
        discord.enable = true;
        telegram.enable = true;
        signal.enable = true;
        matrix.enable = true;
      };
      office = {
        onlyoffice.enable = true;
        slack.enable = true;
      };
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      agents.opencode.enable = true;
      editors = {
        neovim.enable = true;
        zed.enable = true;
      };
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
      grayjay.enable = true;
      qbittorrent.enable = true;
    };
    content-creation = {
      audacity.enable = true;
      gimp.enable = true;
      blender.enable = true;
      obs-studio.enable = true;
      kdenlive.enable = true;
    };
  };
}

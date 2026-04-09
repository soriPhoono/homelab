{
  userapps = {
    defaultApplications.enable = true;
    desktop = {
      file-browser.dolphin.enable = true;
      video-players.vlc.enable = true;
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
      obs-studio.enable = true;
      kdenlive.enable = true;
    };
  };
}

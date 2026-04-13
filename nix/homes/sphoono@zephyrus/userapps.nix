_: {
  userapps = {
    defaultApplications.enable = true;
    desktop = {
      file-browser.pcmanfm.enable = true;
      players = {
        mpv.enable = true;
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
      agents.gemini.enable = true;
      editors.vscode.enable = true;
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
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

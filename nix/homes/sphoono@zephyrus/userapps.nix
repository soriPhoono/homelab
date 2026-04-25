_: {
  userapps = {
    defaultApplications.enable = true;
    desktop = {
      file-browser = {
        plugins.gdrive.enable = true;
        pcmanfm.enable = true;
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
        bottles.enable = true;
      };
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      editors = {
        zed.enable = true;
        vscode.enable = true;
      };
      inference.lmstudio.enable = true;
      agents = {
        opencode.enable = true;
        gemini.enable = true;
      };
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
        inkscape.enable = true;
        blender.enable = true;
      };
      editors = {
        audacity.enable = true;
        kdenlive.enable = true;
      };
      streaming.obs-studio.enable = true;
    };
  };
}

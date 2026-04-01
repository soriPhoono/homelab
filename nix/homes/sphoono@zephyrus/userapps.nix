{pkgs, ...}: {
  userapps = {
    defaultApplications.enable = true;
    browsers = {
      firefox.enable = true;
      chrome.enable = true;
    };
    communication = {
      discord.enable = true;
      telegram.enable = true;
      signal.enable = true;
      matrix.enable = true;
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      agents.gemini.enable = true;
      editors = {
        neovim.enable = true;
        vscode = {
          enable = true;
          package = pkgs.antigravity;
        };
      };
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
    };
    office = {
      onlyoffice.enable = true;
      slack.enable = true;
    };
    content-creation = {
      obs-studio.enable = true;
      davinci-resolve.enable = true;
    };
  };
}

{
  imports = [
    ./zen
    ./zed
  ];

  userapps = {
    defaultApplications.enable = true;
    development = {
      agents.opencode.enable = true;
      terminal.ghostty.enable = true;
    };
    file-browser.dolphin.enable = true;
    browsers = {
      zen.enable = true;
      chrome.enable = true;
    };
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
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
      grayjay.enable = true;
    };
    content-creation = {
      obs-studio.enable = true;
      kdenlive.enable = true;
    };
  };
}

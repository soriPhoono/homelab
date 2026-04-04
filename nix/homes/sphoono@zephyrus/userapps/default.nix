{...}: {
  imports = [
    ./opencode
    ./zed
  ];

  userapps = {
    defaultApplications.enable = true;
    development = {
      terminal.ghostty.enable = true;
      mcpServers = {
        GitHub = {
          command = "";
        };
      };
    };
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
      davinci-resolve.enable = true;
    };
  };
}

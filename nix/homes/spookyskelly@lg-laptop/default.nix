{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };
  };

  userapps = {
    defaultApplications.enable = true;
    browsers = {
      firefox.enable = true;
      chrome.enable = true;
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
    };
    office.onlyoffice.enable = true;
    communication = {
      discord.enable = true;
      signal.enable = true;
      matrix.enable = true;
    };
    content-creation = {
      obs-studio.enable = true;
      davinci-resolve.enable = true;
      blender.enable = true;
    };
  };
}

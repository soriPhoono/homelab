{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    shells.fish.generateCompletions = true;
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
    };
    office.onlyoffice.enable = true;
    communication.discord.enable = true;
    development.knowledge-management.obsidian.enable = true;
    content-creation.blender.enable = true;
  };
}

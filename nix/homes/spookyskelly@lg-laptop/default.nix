{
  core = {
    secrets.enable = true;

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };
  };

  userapps = {
    defaultApplications.enable = true;
    desktop = {
      browsers = {
        firefox.enable = true;
        zen.enable = true;
      };
      communication = {
        discord.enable = true;
        signal.enable = true;
        matrix.enable = true;
      };
      office.onlyoffice.enable = true;
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
      obsidian.enable = true;
    };
    content-creation = {
      obs-studio.enable = true;
      kdenlive.enable = true;
      blender.enable = true;
    };
  };
}

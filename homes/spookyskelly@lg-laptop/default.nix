{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    shells.fish.generateCompletions = true;
  };

  userapps = {
    enable = true;
    browsers = {
      librewolf.enable = true;
      firefox.enable = true;
    };
  };
}

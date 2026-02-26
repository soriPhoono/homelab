{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    shell.fish.generateCompletions = true;
  };

  userapps = {
    enable = true;
    browsers = {
      librewolf.enable = true;
      firefox.enable = true;
    };
  };
}

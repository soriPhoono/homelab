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
      firefox.enable = true;
    };
  };
}

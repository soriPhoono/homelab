{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };
  };

  userapps = {
    enable = true;
    browsers = {
      librewolf.enable = true;
      firefox.enable = true;
    };
  };
}

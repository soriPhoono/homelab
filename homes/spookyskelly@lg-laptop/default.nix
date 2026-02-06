{
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    git = {
      userName = "spookyskelly";
      userEmail = "karoshi1975@gmail.com";
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

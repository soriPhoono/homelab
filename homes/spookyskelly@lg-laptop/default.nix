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

  userapps.enable = true;
}

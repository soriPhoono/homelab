{
  imports = [
    ./hypr.nix
    ./userapps.nix
  ];

  core = {
    secrets.enable = true;

    email = {
      enable = true;
      accounts = {
        personal = {
          address = "soriphoono@gmail.com";
          primary = true;
        };
      };
    };

    shells = {
      starship.enable = true;
      fastfetch.enable = true;
      shellAliases = {
        d = "docker";
        dc = "docker compose";
        lzd = "lazydocker";
      };
    };

    apps.git.enable = true;
  };
}

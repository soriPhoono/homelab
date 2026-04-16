{
  imports = [
    ./hypr.nix
    ./userapps.nix
  ];

  core = {
    secrets.enable = true;

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

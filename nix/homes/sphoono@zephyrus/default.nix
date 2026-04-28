{
  imports = [
    ./hypr.nix
    ./agents.nix
    ./userapps.nix
  ];

  core = {
    secrets.enable = true;

    shells = {
      shellAliases = {
        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gch = "git checkout -b";
        gp = "git push";
        gpl = "git pull";

        lzg = "lazygit";

        d = "docker";
        dc = "docker compose";
        lzd = "lazydocker";
      };
      starship.enable = true;
      fastfetch.enable = true;
    };

    apps.git.enable = true;
  };
}

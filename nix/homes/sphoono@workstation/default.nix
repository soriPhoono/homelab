{
  imports = [
    # Desktop-specific configs (moved from base sphoono/configs/ for CI optimization)
    ../sphoono/configs/zen
    ../sphoono/configs/hypr
    ../sphoono/theme.nix

    ./hypr.nix
    ./userapps.nix
  ];

  core = {
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

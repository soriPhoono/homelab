{
  den.aspects.sphoono = {
    homeManager = { pkgs, ... }: {
      home.shellAliases = {
        ls = "${pkgs.eza}/bin/eza --git --icons auto --group-directories-first";
        l = "ls -l";
        la = "ls -a";
        ll = "ls -l";
        lla = "ls -la";
        lt = "ls -TL 3";
        lta = "ls -aTL 3";

        cat = "${pkgs.bat}/bin/bat";

        cd = "z";
        ".." = "cd ..";
        "..." = "cd ../..";

        df = "${pkgs.duf}/bin/duf";

        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gch = "git checkout -b";
        gp = "git push";
        gpl = "git pull";
      };
      programs = {
        starship = {
          enable = true;

          settings = {
            add_newline = true;

            format = "$character";
            right_format = "$all";

            character = {
              success_symbol = "[➜](bold green) ";
              error_symbol = "[➜](bold red) ";
            };
          };
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        zoxide.enable = true;
        ripgrep.enable = true;
        fzf.enable = true;
        fd.enable = true;
        btop.enable = true;
      };
    };
  };
}

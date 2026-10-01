{
  den.aspects.sphoono = {
    homeManager = { pkgs, config, ... }: {
      home.shellAliases = {
        ls = "${config.programs.eza.package}/bin/eza";
        l = "ls -l";
        la = "ls -a";
        ll = "ls -l";
        lla = "ls -la";
        lt = "ls -TL 3";
        lta = "ls -aTL 3";

        cat = "${config.programs.bat.package}/bin/bat";

        cd = "z";
        ".." = "cd ..";
        "..." = "cd ../..";

        du = "${pkgs.dust}/bin/dust";
        find = "${config.programs.fzf.package}/bin/fzf";
        grep = "${config.programs.ripgrep.package}/bin/rg";

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
        eza = {
          enable = true;
          git = true;
          icons = "auto";
          extraOptions = [
            "--group-directories-first"
          ];
        };
        zoxide.enable = true;
        bat.enable = true;
        fzf.enable = true;
        ripgrep.enable = true;
        btop.enable = true;
      };
    };
  };
}

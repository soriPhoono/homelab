{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./fish.nix

    ./starship.nix
    ./fastfetch.nix
  ];

  options.core.shells = {
    shellAliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {
        rm = "${pkgs.trash-cli}/bin/trash";

        ls = "${pkgs.eza}/bin/eza";
        l = "ls -l";
        la = "ls -a";
        ll = "ls -l";
        lla = "ls -la";
        lt = "ls -TL 3";
        lta = "ls -aTL 3";

        cat = "${pkgs.bat}/bin/bat --style=plain --paging=never";

        cd = "z";
        ".." = "cd ..";
        "..." = "cd ../..";

        du = "${pkgs.dust}/bin/dust";
        find = "${pkgs.fd}/bin/fd";
        grep = "${pkgs.ripgrep}/bin/rg";

        top = "${pkgs.btop}/bin/btop";
        gtop = "${pkgs.nvtopPackages.full}/bin/nvtop";
        df = "${pkgs.duf}/bin/duf";

        gs = "${pkgs.git}/bin/git status";
        ga = "${pkgs.git}/bin/git add";
        gc = "${pkgs.git}/bin/git commit -m";
        gp = "${pkgs.git}/bin/git push";
        gpl = "${pkgs.git}/bin/git pull";

        v = "nvim";
      };
      description = "Shell command aliases";
    };

    sessionVariables = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Environment variables to set for the user";
    };
  };

  config = {
    home.packages = with pkgs; [
      trash-cli
    ];

    programs = {
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

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batman
          prettybat
        ];
      };

      fd = {
        enable = true;
        hidden = true;
      };

      fzf = {
        enable = true;
      };

      ripgrep.enable = true;

      btop.enable = true;
    };
  };
}

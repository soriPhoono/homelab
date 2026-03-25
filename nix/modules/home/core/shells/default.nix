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
        rm = "trash";

        ls = "eza";
        l = "eza -l";
        la = "eza -a";
        ll = "eza -l";
        lla = "eza -la";
        lt = "eza -TL 3";
        lta = "eza -aTL 3";

        cat = "bat --style=plain --paging=never";

        cd = "z";
        ".." = "cd ..";
        "..." = "cd ../..";

        du = "dust";
        find = "fd";
        grep = "rg";

        top = "btop";
        gtop = "nvtop";
        df = "duf";

        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gp = "git push";
        gpl = "git pull";

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

      btop
      nvtopPackages.full
      duf

      dust
      fd
      ripgrep
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

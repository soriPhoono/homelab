{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  imports = [
    ./bash.nix
    ./fish.nix

    ./starship.nix
    ./fastfetch.nix
  ];

  options.core.shells = {
    shellAliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Shell command aliases";
    };

    sessionVariables = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Environment variables to set for the user";
    };
  };

  config = {
    core.shells.shellAliases = {
      rm = "${pkgs.trashy}/bin/trash";

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
      find = "${config.programs.fd.package}/bin/fd";
      grep = "${config.programs.ripgrep.package}/bin/rg";

      df = "${pkgs.duf}/bin/duf";
    };

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
        extraPackages = [
        ];
      };

      fd.enable = true;
      fzf.enable = true;
      ripgrep.enable = true;

      btop.enable = true;
    };
  };
}

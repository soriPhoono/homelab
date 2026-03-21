{
  lib,
  pkgs,
  nixosConfig ? null,
  ...
}: {
  imports = [
    ./shells
    ./git.nix
    ./gitops.nix
    ./secrets.nix
    ./ssh.nix
    ./checks.nix
  ];

  home.packages = with pkgs; [
    p7zip
    unrar

    carlito
    liberation_ttf
    nerd-fonts.aurulent-sans-mono
    nerd-fonts.sauce-code-pro
  ];

  xdg = {
    enable = true;
    userDirs = {
      enable = true;

      createDirectories = true;
    };
  };

  programs = {
    home-manager.enable = true;

    nh = {
      enable = true;

      clean = {
        enable = true;
        extraArgs = "--keep-since 5d";
      };
    };
  };

  home.stateVersion = lib.mkDefault (
    if nixosConfig != null
    then nixosConfig.system.stateVersion
    else "24.11"
  );

  core.checks.enable = lib.mkDefault true;
}

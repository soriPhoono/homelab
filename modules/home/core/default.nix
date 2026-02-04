{
  lib,
  pkgs,
  nixosConfig ? null,
  ...
}: {
  imports = [
    ./secrets.nix
    ./ssh.nix
    ./git.nix
    ./gitops.nix
    ./shells
  ];

  home.packages = with pkgs; [
    p7zip
    unrar

    carlito
    liberation_ttf
    nerd-fonts.sauce-code-pro
    nerd-fonts.aurulent-sans-mono
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
}

{
  lib,
  pkgs,
  nixosConfig ? null,
  ...
}: {
  imports = [
    ./shells
    ./apps

    ./git.nix
    ./gitops.nix
    ./secrets.nix
    ./ssh.nix
  ];

  home.packages = with pkgs; [
    p7zip
    unrar

    carlito
    liberation_ttf
  ];

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
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
    else "26.05"
  );
}

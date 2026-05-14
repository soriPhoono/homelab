{lib, ...}:
with lib; {
  imports = [
    ./display_managers
    ./managers

    ./cosmic.nix
    ./kde.nix
  ];

  options.desktop.environments = {
    selectedEnvironment = lib.mkOption {
      type = with types; nullOr (enum ["cosmic" "kde" "hyprland-uwsm"]);
      default = null;
      description = "The desktop environment to be installed.";
    };
  };
}

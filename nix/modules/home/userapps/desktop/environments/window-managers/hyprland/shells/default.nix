{...}: {
  imports = [
    ./noctalia.nix
  ];

  options.userapps.desktop.environments.window-managers.hyprland.shells = {
    # Aggregate option for enabling any shell
  };
}

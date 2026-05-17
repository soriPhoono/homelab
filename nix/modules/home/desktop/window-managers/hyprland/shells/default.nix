{...}: {
  imports = [
    ./noctalia.nix
  ];

  options.desktop.window-managers.hyprland.shells = {
    # Aggregate option for enabling any shell
  };
}

{config, ...}: {
  imports = [
    ./userapps.nix
    ./theme.nix
  ];

  core = {
    secrets.enable = true;

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };

    git.projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, 1920x1080@144, 0x0, 1.5"
    ];

    bind = [
      "SUPER, B, exec, uwsm app -s a xdg-open https://duckduckgo.com"
      "SUPER, C, exec, uwsm app -s a antigravity"
    ];
  };
}

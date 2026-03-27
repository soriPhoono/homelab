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
    };

    git.projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
  };

  desktop.hyprland.hotkeys = {
    chrome = {
      mods = [
        "SUPER"
      ];
      trigger = "B";
      executor = "exec";
      command = "google-chrome";
    };
    antigravity = {
      mods = [
        "SUPER"
      ];
      trigger = "C";
      executor = "exec";
      command = "antigravity";
    };
  };
}

{
  pkgs,
  config,
  ...
}: {
  core = {
    secrets.enable = true;

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };

    git.projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
  };

  userapps = {
    defaultApplications.enable = true;
    browsers = {
      firefox.enable = true;
      chrome.enable = true;
    };
    communication = {
      discord.enable = true;
      telegram.enable = true;
      signal.enable = true;
      matrix.enable = true;
    };
    development = {
      enable = true;
      terminal.ghostty.enable = true;
      knowledge-management.obsidian.enable = true;
      agents.gemini.enable = true;
      editors = {
        neovim.enable = true;
        vscode = {
          enable = true;
          package = pkgs.antigravity;
        };
      };
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
    };
    office = {
      onlyoffice.enable = true;
      slack.enable = true;
    };
    content-creation = {
      obs-studio.enable = true;
      davinci-resolve.enable = true;
    };
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

  themes.enable = true;
}

_: {
  core = {
    shells.fish.generateCompletions = true;
  };

  userapps = {
    enable = true;
    browsers = {
      chrome.enable = true;
      librewolf.enable = true;
    };
    data-fortress = {
      bitwarden.enable = true;
    };
    development = {
      enable = true;
      terminal = {
        ghostty.enable = true;
      };
      editors = {
        neovim.enable = true;
        antigravity.enable = true;
      };
      agents.gemini = {
        enable = true;
        enableJules = true;
      };
    };
  };
}

_: {
  core = {
    shells.fish.generateCompletions = true;
  };

  userapps = {
    enable = true;
    browsers.chrome.enable = true;
    data-fortress.bitwarden.enable = true;
    development = {
      terminal.ghostty.enable = true;
      editors.neovim.enable = true;
    };
  };
}

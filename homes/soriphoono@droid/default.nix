{lib, ...}: {
  # Android/Termux specifics
  xdg.userDirs.enable = lib.mkForce false;

  core = {
    shells.shellAliases = {
      pbcopy = "termux-clipboard-set";
      pbpaste = "termux-clipboard-get";
    };
  };

  userapps = {
    # Explicitly disable desktop-only defaults
    browsers.chrome.enable = lib.mkForce false;

    development = {
      editors.neovim.enable = true;
      agents = {
        gemini.enable = true;
        claude.enable = true;
      };
    };
  };
}

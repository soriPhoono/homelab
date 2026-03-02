{lib, ...}: {
  # Android/Termux specifics
  xdg.userDirs.enable = lib.mkForce false;

  core = {
    shells = {
      fish.generateCompletions = true;
      shellAliases = {
        #  TODO: fix this for nix-on-droid
        pbcopy = "termux-clipboard-set";
        pbpaste = "termux-clipboard-get";
      };

      shellAliases.v = "nvim";
    };
  };

  userapps = {
    browsers.chrome.enable = lib.mkForce false;
    development = {
      editors.neovim.enable = true;
      agents = {
        gemini = {
          enable = true;
          enableJules = true;
        };
      };
    };
  };
}

{lib, ...}: {
  # Android/Termux specifics
  xdg.userDirs.enable = lib.mkForce false;

  core = {
    shells = {
      fish.generateCompletions = true;
      shellAliases = {
        pbcopy = "termux-clipboard-set";
        pbpaste = "termux-clipboard-get";
      };
    };
  };

  userapps = {
    browsers.chrome.enable = lib.mkForce false;
  };
}

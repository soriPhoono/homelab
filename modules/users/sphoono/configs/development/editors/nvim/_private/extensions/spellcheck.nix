_: {
  programs.nvf.settings.vim.spellcheck = {
    enable = true;
    languages = [ "en" ];
    # Read-only and picker buffers are not prose.
    ignoredFiletypes = [
      "toggleterm"
      "alpha"
      "neo-tree"
      "TelescopePrompt"
      "Trouble"
      "lazy"
      "mason"
    ];
    extraSpellWords."en.utf-8" = [
      "nvf"
      "sphoono"
      "homelab"
      "tailnet"
      "neovim"
      "nixpkgs"
      "NixOS"
      "sops"
      "treefmt"
      "direnv"
      "Obsidian"
      "markdownlint"
    ];
  };
}

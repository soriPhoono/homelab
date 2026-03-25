{pkgs, ...}: let
  inherit (pkgs) lib;

  utilities = import ./plugins/utilities.nix;
  languages = import ./plugins/languages.nix;
  ui = import ./plugins/ui.nix;

  baseSettings = {
    viAlias = true;
    vimAlias = true;

    hideSearchHighlight = true;
    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
    };
    extraPackages = with pkgs; [
      ripgrep
      tree-sitter
      bacon
    ];

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_python3_provider = 0;
      loaded_ruby_provider = 0;
      loaded_perl_provider = 0;
      loaded_node_provider = 0;
    };

    options = {
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;

      foldenable = false;
      wrap = false;

      # Line numbers
      number = true;
      relativenumber = true;

      # Visual aids
      cursorline = true;
      scrolloff = 8;
      sidescrolloff = 8;
      signcolumn = "yes";

      # Split behavior
      splitright = true;
      splitbelow = true;

      # Search
      ignorecase = true;
      smartcase = true;

      # Mouse support
      mouse = "a";
    };

    git.enable = true;
    undoFile.enable = true;
    theme.enable = true;
  };
in
  lib.foldl' lib.recursiveUpdate baseSettings [
    utilities
    languages
    ui
  ]

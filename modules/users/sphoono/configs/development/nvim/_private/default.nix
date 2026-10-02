{ pkgs, ... }: {
  imports = [
    ./extensions/blink-cmp.nix
    ./extensions/bufferline.nix
    ./extensions/colorful-menu.nix
    ./extensions/colorizer.nix
    ./extensions/dashboard.nix
    ./extensions/gitsigns.nix
    ./extensions/illuminate.nix
    ./extensions/indent-blankline.nix
    ./extensions/keybinds.nix
    ./extensions/lualine.nix
    ./extensions/neo-tree.nix
    ./extensions/noice.nix
    ./extensions/notify.nix
    ./extensions/rainbow-delimiters.nix
    ./extensions/scrollbar.nix
    ./extensions/smooth-scroll.nix
    ./extensions/telescope.nix
    ./extensions/theme.nix
    ./extensions/treesitter.nix
    ./languages/bash.nix
    ./languages/clang.nix
    ./languages/common.nix
    ./languages/css.nix
    ./languages/go.nix
    ./languages/html.nix
    ./languages/json.nix
    ./languages/nix.nix
    ./languages/python.nix
    ./languages/rust.nix
    ./languages/terraform.nix
    ./languages/toml.nix
    ./languages/typescript.nix
    ./languages/vue.nix
    ./languages/xml.nix
    ./languages/yaml.nix
    ./languages/zig.nix
  ];
  programs.nvf.settings = {
    mnw.extraBinPath = [ pkgs.tree-sitter ];
    vim = {
      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      viAlias = true;
      vimAlias = true;

      lsp.enable = true;

      opts = {
        # Appearance settings
        number = true; # Show absolute line numbers
        relativenumber = true; # Show relative line numbers
        cursorline = true; # Highlight the line of the cursor
        cursorcolumn = false; # Highlight the column of the cursor
        wrap = false; # Disable line wrapping
        signcolumn = "auto"; # Show sign column when needed
        conceallevel = 2; # Hide text in certain contexts
        spell = false; # Enable spell checking
        mouse = "a"; # Enable mouse support
        clipboard = "unnamedplus"; # System clipboard

        # Backup and undo settings
        backup = false; # Disable backup files
        writebackup = false; # Disable write backup files
        swapfile = true; # Enable swap files
        undofile = true; # Enable persistent undo

        # Editor settings
        tabstop = 2; # Number of spaces that a <Tab> in the file counts for
        shiftwidth = 2; # Number of spaces to use for each step of (auto)indent
        expandtab = true; # Use spaces instead of tabs
        autoindent = true; # Copy indent from current line
        breakindent = true; # Wrap lines at a word boundary
        smartindent = true; # Use smart indenting
        smarttab = false; # Use smart tab behavior
        smartcase = true; # Ignore case when all characters are lowercase
        ignorecase = true; # Ignore case when searching
        hlsearch = true; # Highlight search results
        incsearch = true; # Show search results as you type
        showmode = false; # Show mode in status line
        showcmd = true; # Show command in status line
        ruler = true; # Show line and column numbers
        numberwidth = 4; # Width of the number column
        scrolloff = 8; # Number of lines to keep above/below the cursor
        sidescrolloff = 8; # Number of columns to keep left/right of the cursor
        splitbelow = true; # Split windows below the current window
        splitright = true; # Split windows right of the current window
        equalalways = true; # Make all windows equal size
        updatetime = 250; # Time in milliseconds to wait before updating the screen
        timeoutlen = 500; # Time in milliseconds to wait for a key code sequence
      };
      autopairs.nvim-autopairs.enable = true;
      visuals.nvim-web-devicons.enable = true;
    };
  };
}

{lib, ...}:
with lib; {
  vim.terminal.toggleterm = {
    enable = true;
    mappings.open = "<leader>tt";

    # LazyGit integration (lazygit keybind is wired via luaConfigRC
    # in plugins/toggleterm-keymaps.nix)
    lazygit = {
      enable = true;
      direction = "float";
    };

    setupOpts = {
      # Default direction when opening a new terminal
      direction = "float";

      # Reasonable default size for floating terminals
      float_opts = {
        border = "rounded";
        width = 0.8;
        height = 0.7;
        winblend = 0;
      };

      # Disable winbar in terminal windows (less visual clutter)
      winbar.enabled = false;

      # Persistent shell session (better UX than fresh shells each time)
      persistent = true;

      # Close terminal cleanly when it exits
      close_on_exit = true;

      # Use a slightly shaded background for floating terminals
      shading_factor = 1;
    };
  };
}

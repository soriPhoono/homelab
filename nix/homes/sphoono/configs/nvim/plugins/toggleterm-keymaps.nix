_: {
  # Additional toggleterm keymaps wired through lazy.nvim's `after` hook.
  # nvf only exposes vim.terminal.toggleterm.mappings.open (a single string),
  # so we register <leader>tt, <leader>th, <leader>tv, and <leader>gl here
  # using the plugin's own load lifecycle — guarantees toggleterm is loaded.
  vim.lazy.plugins.toggleterm-nvim = {
    package = "toggleterm-nvim";

    after = ''
      local opts = { noremap = true, silent = true }
      local Terminal = require("toggleterm.terminal").Terminal

      vim.keymap.set("n", "<leader>tt", function()
        local term = Terminal:new({ direction = "float" })
        term:toggle()
      end, vim.tbl_extend("force", opts, { desc = "Terminal: float" }))

      vim.keymap.set("n", "<leader>th", function()
        local term = Terminal:new({ direction = "horizontal" })
        term:toggle()
      end, vim.tbl_extend("force", opts, { desc = "Terminal: horizontal" }))

      vim.keymap.set("n", "<leader>tv", function()
        local term = Terminal:new({ direction = "vertical" })
        term:toggle()
      end, vim.tbl_extend("force", opts, { desc = "Terminal: vertical" }))

      vim.keymap.set("n", "<leader>gl", function()
        local lazygit = Terminal:new({
          cmd = "lazygit",
          direction = "float",
          close_on_exit = true,
        })
        lazygit:toggle()
      end, vim.tbl_extend("force", opts, { desc = "LazyGit" }))
    '';
  };
}

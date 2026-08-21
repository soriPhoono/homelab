_: {
  vim.autocomplete.blink-cmp = {
    enable = true;

    friendly-snippets.enable = true;

    mappings = {
      close = "<C-e>";
      complete = "<C-Space>";
      confirm = "<CR>";
      next = "<Tab>";
      previous = "<S-Tab>";
      scrollDocsDown = "<C-f>";
      scrollDocsUp = "<C-d>";
    };

    sourcePlugins = {
      emoji.enable = true;
      ripgrep.enable = true;
      spell.enable = true;
    };

    setupOpts = {
      keymap.preset = "default";

      cmdline = {
        keymap.preset = "cmdline";
        sources = ["path" "cmdline"];
      };

      sources.default = [
        "lsp"
        "path"
        "snippets"
        "buffer"
        "emoji"
        "ripgrep"
        "spell"
      ];

      completion = {
        menu.auto_show = true;
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
        };
      };

      fuzzy = {
        implementation = "prefer_rust";
        prebuilt_binaries.download = false;
      };
    };
  };

  vim.snippets.luasnip.enable = true;
}

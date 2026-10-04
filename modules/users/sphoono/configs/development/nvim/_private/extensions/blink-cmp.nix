{ lib, ... }:
{
  programs.nvf.settings.vim = {
    autocomplete.blink-cmp = {
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
          sources = [
            "path"
            "cmdline"
          ];
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
          # Hands label rendering to colorful-menu-nvim (colorful-menu.nix).
          # Delete this block if it's too noisy next to blink-cmp's icons.
          menu.draw.components.label = {
            text = lib.generators.mkLuaInline "function(ctx) return require('colorful-menu').blink_components_text(ctx) end";
            highlight = lib.generators.mkLuaInline "function(ctx) return require('colorful-menu').blink_components_highlight(ctx) end";
          };
        };
        fuzzy = {
          implementation = "prefer_rust";
          prebuilt_binaries.download = false;
        };
      };
    };
    snippets.luasnip.enable = true;
  };
}

{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    mini.map = {
      enable = true;
      setupOpts = {
        # Marks for git hunks, diagnostics and search matches beside the map.
        integrations = [
          (mkLuaInline "require('mini.map').gen_integration.builtin_search()")
          (mkLuaInline "require('mini.map').gen_integration.gitsigns()")
          (mkLuaInline "require('mini.map').gen_integration.diagnostic()")
        ];
        window.winblend = 0;
      };
    };

    # <leader>m is the Multicursor group.
    keymaps = [
      {
        mode = "n";
        key = "<leader>Mm";
        action = "<cmd>lua MiniMap.toggle()<CR>";
        desc = "Toggle minimap";
      }
      {
        mode = "n";
        key = "<leader>Mf";
        action = "<cmd>lua MiniMap.toggle_focus()<CR>";
        desc = "Focus minimap";
      }
    ];

    binds.whichKey.register."<leader>M" = "+Minimap";
  };
}

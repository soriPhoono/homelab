{ lib, ... }:
{
  programs.nvf.settings.vim = {
    diagnostics = {
      enable = true;
      config = {
        underline = true;
        virtual_text = false;
        update_in_insert = false;
        severity_sort = true;
        signs.text = lib.generators.mkLuaInline ''
          {
            [vim.diagnostic.severity.ERROR] = "\u{f057}",
            [vim.diagnostic.severity.WARN] = "\u{f071}",
            [vim.diagnostic.severity.INFO] = "\u{f05a}",
            [vim.diagnostic.severity.HINT] = "\u{f0eb}",
          }
        '';
        float = {
          border = "rounded";
          source = true;
          focusable = false;
        };
      };
    };

    # updatetime is 250ms, so the float appears after a short pause on a
    # diagnostic and never opens while typing.
    autocmds = [
      {
        event = [ "CursorHold" ];
        desc = "Show diagnostics under the cursor";
        callback = lib.generators.mkLuaInline ''
          function()
            vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
          end
        '';
      }
    ];

    lsp.trouble = {
      enable = true;
      # The defaults sit under <leader>l and collide with the telescope LSP
      # pickers, so the whole list family lives under <leader>x.
      mappings = {
        documentDiagnostics = "<leader>xx";
        workspaceDiagnostics = "<leader>xX";
        lspReferences = "<leader>xr";
        symbols = "<leader>xs";
        quickfix = "<leader>xq";
        locList = "<leader>xl";
      };
    };
  };
}

{ lib, pkgs, ... }:
let
  inherit (lib.hm.dag) entryAfter;
in
{
  # nvf has no DAP option for TypeScript, so the Microsoft js-debug adapter is
  # registered by hand. neotest-vitest and neotest-jest use the same "pwa-node"
  # adapter for <leader>tD.
  programs.nvf.settings.vim.pluginRC.nvim-dap-javascript = entryAfter [ "nvim-dap" ] ''
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "''${port}",
      executable = {
        command = "${pkgs.vscode-js-debug}/bin/js-debug",
        args = { "''${port}" },
      },
    }

    for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" }) do
      dap.configurations[ft] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "''${file}",
          cwd = "''${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to process",
          processId = require("dap.utils").pick_process,
          cwd = "''${workspaceFolder}",
        },
      }
    end
  '';
}

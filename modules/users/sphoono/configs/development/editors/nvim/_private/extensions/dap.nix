{ lib, pkgs, ... }:
let
  inherit (lib.hm.dag) entryAfter;
in
{
  programs.nvf.settings.vim = {
    languages = {
      rust.dap = {
        enable = true;
        debugger = [ "codelldb" ];
      };
      clang.dap = {
        enable = true;
        debugger = [ "lldb" ];
      };
      zig.dap = {
        enable = true;
        debugger = [ "lldb" ];
      };
      python.dap = {
        enable = true;
        debugger = [ "debugpy" ];
      };
      go.dap = {
        enable = true;
        debugger = "delve";
      };
    };

    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
      # Lets project .vscode/launch.json files that name "codelldb" resolve for
      # C, C++, Zig and Rust alongside the lldb default configuration.
      presets.codelldb.enable = true;
    };

    # Loaded on the first debug session so plain editing never pays for it.
    lazy.plugins.nvim-dap-virtual-text = {
      package = pkgs.vimPlugins.nvim-dap-virtual-text;
      lazy = true;
      setupModule = "nvim-dap-virtual-text";
      setupOpts.virt_text_pos = "eol";
    };

    pluginRC.nvim-dap-extras = entryAfter [ "nvim-dap" ] ''
      for name, icon in pairs({
        DapBreakpoint = { "\u{f111}", "DiagnosticError" },
        DapBreakpointCondition = { "\u{f059}", "DiagnosticWarn" },
        DapLogPoint = { "\u{f05a}", "DiagnosticInfo" },
        DapStopped = { "\u{f061}", "DiagnosticOk" },
        DapBreakpointRejected = { "\u{f06a}", "DiagnosticHint" },
      }) do
        vim.fn.sign_define(name, { text = icon[1], texthl = icon[2], linehl = "", numhl = "" })
      end

      dap.listeners.after.event_initialized["virtual_text"] = function()
        require("lz.n").trigger_load("nvim-dap-virtual-text")
      end

      -- Per-project launch configs: ./.vscode/launch.json, read once per cwd.
      local launchjs_loaded = {}
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvf_dap_launchjs", { clear = true }),
        pattern = { "c", "cpp", "rust", "zig", "python", "go" },
        callback = function()
          local cwd = vim.fn.getcwd()
          if launchjs_loaded[cwd] then
            return
          end
          launchjs_loaded[cwd] = true
          if vim.fn.filereadable(cwd .. "/.vscode/launch.json") == 1 then
            require("dap.ext.vscode").load_launchjs(nil, {
              codelldb = { "c", "cpp", "rust", "zig" },
              lldb = { "c", "cpp", "rust", "zig" },
              cppdbg = { "c", "cpp" },
              debugpy = { "python" },
              python = { "python" },
              delve = { "go" },
              go = { "go" },
            })
          end
        end,
      })

      vim.keymap.set("n", "<leader>dB", function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Conditional breakpoint" })
    '';

    binds.whichKey.register."<leader>d" = "+Debug";
  };
}

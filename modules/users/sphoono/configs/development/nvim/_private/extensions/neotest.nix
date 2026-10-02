{ lib, pkgs, ... }:
let
  inherit (lib.generators) mkLuaInline;

  adapters = {
    neotest-python = "require('neotest-python')({ runner = 'pytest' })";
    neotest-rust = "require('neotest-rust')({ dap_adapter = 'codelldb' })";
    neotest-golang = "require('neotest-golang')({})";
    neotest-zig = "require('neotest-zig')({})";
    neotest-gtest = "require('neotest-gtest').setup({})";
    neotest-ctest = "require('neotest-ctest').setup({})";
  };

  key = lhs: desc: action: {
    key = "<leader>t${lhs}";
    mode = "n";
    lua = true;
    inherit desc action;
  };
in
{
  programs.nvf.settings = {
    # neotest-rust shells out to nextest; the rest run on the project's own toolchain.
    mnw.extraBinPath = [ pkgs.cargo-nextest ];

    vim = {
      lazy.plugins = {
        neotest = {
          package = pkgs.vimPlugins.neotest;
          beforeSetup = "require('lz.n').trigger_load({ ${
            lib.concatMapStringsSep ", " (n: "'${n}'") (builtins.attrNames adapters)
          } })";
          setupModule = "neotest";
          setupOpts = mkLuaInline ''
            {
              adapters = {
                ${lib.concatStringsSep ",\n    " (builtins.attrValues adapters)}
              },
              status = { virtual_text = true },
              output = { open_on_run = false },
              quickfix = { open = false },
            }
          '';
          keys = [
            (key "t" "Run nearest test" "function() require('neotest').run.run() end")
            (key "f" "Run file tests" "function() require('neotest').run.run(vim.fn.expand('%')) end")
            (key "l" "Run last test" "function() require('neotest').run.run_last() end")
            (key "D" "Debug nearest test" "function() require('neotest').run.run({ strategy = 'dap' }) end")
            (key "x" "Stop test" "function() require('neotest').run.stop() end")
            (key "s" "Toggle test summary" "function() require('neotest').summary.toggle() end")
            (key "o" "Show test output" "function() require('neotest').output.open({ enter = true }) end")
            (key "O" "Toggle output panel" "function() require('neotest').output_panel.toggle() end")
          ];
        };
      }
      // lib.mapAttrs (name: _: {
        # Dropping nixpkgs' dependency on neotest keeps the adapters from pulling it onto the start path.
        package = pkgs.vimPlugins.${name}.overrideAttrs {
          dependencies = [ ];
          doCheck = false;
        };
        lazy = true;
      }) adapters;

      binds.whichKey.register."<leader>t" = "+Test";
    };
  };
}

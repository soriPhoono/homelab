{
  debugger.nvim-dap.enable = true;
  lsp = {
    enable = true;
    formatOnSave = true;
    lspkind = {
      enable = true;
      setupOpts.mode = "symbol";
    };
    trouble.enable = true;
  };

  autocomplete.blink-cmp = {
    enable = true;
    friendly-snippets.enable = true;
    setupOpts.completion.sources.default = ["lsp" "path" "snippets" "buffer"];
  };

  languages = {
    enableExtraDiagnostics = true;
    enableFormat = true;
    enableTreesitter = true;

    nix = {
      enable = true;
      lsp.servers = ["nixd"];
    };

    clang = {
      enable = true;
      dap.debugger = "lldb-dap";
    };

    bash.enable = true;

    python = {
      enable = true;
      format.type = ["black" "isort"];
      lsp.servers = ["python-lsp-server"];
    };

    yaml.enable = true;
    terraform.enable = true;
    css.enable = true;
    html.enable = true;
    rust = {
      enable = true;
      lsp.opts = ''
        ['rust-analyzer'] = {
          cargo = { allFeatures = true },
          checkOnSave = {
            command = "bacon",
          },
        },
      '';
    };
    zig.enable = true;
    csharp = {
      enable = true;
      lsp = {
        enable = true;
        servers = ["omnisharp"];
      };
    };
    java = {
      enable = true;
      lsp = {
        enable = true;
        servers = ["jdtls"];
      };
    };
    nu.enable = true;

    markdown = {
      enable = true;
      format.type = ["prettierd"];
      extensions = {
        render-markdown-nvim = {
          enable = true;
          setupOpts = {
            html.enabled = true;
            latex.enabled = true;
          };
        };
      };
    };
  };
}

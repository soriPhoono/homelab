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

{
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      lspkind = {
        enable = true;
        setupOpts.mode = "symbol";
      };
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
        lsp.server = "nixd";
      };
      bash.enable = true;

      python = {
        enable = true;
        format.type = "black-and-isort";
        lsp.server = "python-lsp-server";
      };

      yaml.enable = true;
      terraform.enable = true;

      markdown = {
        enable = true;
        format.type = "prettierd";
        extensions = {
          render-markdown-nvim.enable = true;
        };
      };
    };
  };
}

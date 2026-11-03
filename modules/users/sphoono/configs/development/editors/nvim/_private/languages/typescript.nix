_: {
  programs.nvf.settings.vim = {
    languages = {
      typescript = {
        enable = true;
        lsp.servers = [ "typescript-language-server" ];
        format = {
          enable = true;
          type = [ "prettier" ];
        };
        extraDiagnostics = {
          enable = true;
          types = [ "eslint_d" ];
        };
      };
      tsx = {
        enable = true;
        lsp.servers = [ "typescript-language-server" ];
        format = {
          enable = true;
          type = [ "prettier" ];
        };
        extraDiagnostics.enable = false;
      };
    };
    # vtsls runs alongside typescript-language-server. The vtsls preset is enabled
    # by languages.vue (vue.nix) and carries the Vue tsserver plugin; it is
    # attached to the plain TS/JS filetypes here (vue.nix adds "vue").
    lsp.servers.vtsls.filetypes = [
      "javascript"
      "javascriptreact"
      "typescript"
      "typescriptreact"
    ];
  };
}

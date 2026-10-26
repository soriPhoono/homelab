{
  programs.nvf.settings.vim.languages.vue = {
    enable = true;
    # vue-language-server delegates TypeScript requests to vtsls.
    lsp.servers = [
      "vue-language-server"
      "vtsls"
    ];
    format = {
      enable = true;
      type = [ "prettier" ];
    };
    # nvf only offers biome for Vue; eslint_d is attached to typescript only.
    extraDiagnostics.enable = false;
  };
}

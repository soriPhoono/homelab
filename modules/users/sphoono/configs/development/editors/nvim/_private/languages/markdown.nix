{
  programs.nvf.settings.vim.languages.markdown = {
    enable = true;
    # marksman for links and headings; the repo lints with markdownlint and
    # its treefmt runs prettier over markdown, so the editor matches both.
    lsp.servers = [ "marksman" ];
    format = {
      enable = true;
      type = [ "prettier" ];
    };
    extraDiagnostics = {
      enable = true;
      types = [ "markdownlint-cli2" ];
    };
    # Disables obsidian.nvim's own ui in favour of this renderer.
    extensions.render-markdown-nvim.enable = true;
  };
}

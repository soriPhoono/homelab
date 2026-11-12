{ lib, pkgs, ... }:
{
  programs.nvf = {
    # The project templates format YAML with yamlfmt in treefmt, so the editor
    # uses it too; the project's own yamlfmt wins when direnv puts it on PATH.
    settings.mnw.extraBinPath = [ pkgs.yamlfmt ];

    settings.vim = {
      languages.yaml = {
        enable = true;
        lsp.servers = [ "yaml-language-server" ];
        # nvf only offers prettier and deno, so conform is wired directly.
        format.enable = false;
      };
      formatter.conform-nvim.setupOpts.formatters_by_ft.yaml = lib.mkForce [ "yamlfmt" ];
    };
  };
}

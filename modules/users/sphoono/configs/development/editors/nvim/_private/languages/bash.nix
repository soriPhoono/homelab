{ lib, ... }:
{
  programs.nvf.settings.vim = {
    languages.bash = {
      enable = true;
      lsp.servers = [ "bash-language-server" ];
      format = {
        enable = true;
        type = [ "shfmt" ];
      };
      extraDiagnostics = {
        enable = true;
        types = [ "shellcheck" ];
      };
    };
    # The preset also lists "ash" and "dash", which are not Neovim filetypes
    # and make :checkhealth vim.lsp warn.
    lsp.servers.bash-language-server.filetypes = lib.mkForce [
      "sh"
      "bash"
    ];
  };
}

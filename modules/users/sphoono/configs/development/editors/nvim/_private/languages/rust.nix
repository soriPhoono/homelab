{ lib, pkgs, ... }:
{
  # nvf starts rust-analyzer by store path, which ignores the toolchain pinned
  # in a project's rust-toolchain.toml. Resolving it from PATH lets the direnv
  # shell win, with the nixpkgs one as the suffix fallback outside a project.
  programs.nvf.settings = {
    mnw.extraBinPath = [ pkgs.rust-analyzer ];

    vim = {
      languages.rust = {
        enable = true;
        lsp.servers = [ "rust-analyzer" ];
        format = {
          enable = true;
          type = [ "rustfmt" ];
        };
        # rustaceanvim is off: nvf asserts it is mutually exclusive with dap.enable.
        extensions.crates-nvim.enable = true;
      };
      lsp.servers.rust-analyzer.cmd = lib.mkForce [ "rust-analyzer" ];
    };
  };
}

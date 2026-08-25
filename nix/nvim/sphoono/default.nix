{
  lib,
  pkgs,
  ...
}: let
  mkSettingsModule = path: {
    programs.nvf.settings = import path {inherit lib pkgs;};
  };
in {
  imports = map mkSettingsModule [
    ./core/appearance.nix
    ./core/editing.nix
    ./core/backups.nix
    ./core/keymaps.nix
    ./core/binpath.nix
    ./plugins/default.nix
    ./plugins/whichkey-icons.nix
    ./plugins/telescope.nix
    ./plugins/lualine.nix
    ./plugins/bufferline.nix
    ./plugins/project.nix
    ./plugins/treesitter.nix
    ./plugins/blink-cmp.nix
    ./plugins/neo-tree.nix
    ./plugins/toggleterm-keymaps.nix
    ./plugins/dashboard.nix
    ./ui.nix
    ./languages.nix
  ];
}

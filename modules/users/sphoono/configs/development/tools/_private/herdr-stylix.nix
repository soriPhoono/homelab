# A manual stylix target: `mkTarget` is only injected into modules
# autoloaded from inside the stylix flake itself (see stylix/autoload.nix),
# so a third-party target replicates its enable/guard behaviour by hand,
# per stylix's own "Adding modules" doc.
{ config, lib, ... }:
let
  cfg = config.stylix.targets.herdr;
  colors = config.lib.stylix.colors;
in
{
  options.stylix.targets.herdr.enable = config.lib.stylix.mkEnableTarget "Herdr" true;

  config = lib.mkIf (config.stylix.enable && cfg.enable) {
    programs.herdr.settings = with colors.withHashtag; {
      theme = {
        name = "catppuccin";
        auto_switch = false;
        custom = {
          # Transparent panes/sidebar, matching nvim's theme.transparent and
          # stylix's terminal opacity, instead of a solid base00 fill.
          panel_bg = "reset";
          sidebar_bg = "reset";
          active_row_bg = base01;
          selection_bg = base02;
          accent = base0D;
          red = base08;
          green = base0B;
          blue = base0D;
          yellow = base0A;
          text = base05;
        };
      };
      ui.accent = base0D;
    };
  };
}

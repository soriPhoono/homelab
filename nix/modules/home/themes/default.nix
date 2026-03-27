{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.themes;
in
  with lib; {
    options.themes = {
      enable = mkEnableOption "Enable home manager theming";
    };

    config = mkIf cfg.enable {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";

        fonts = let
          serif = {
            package = pkgs.nerd-fonts.sauce-code-pro;
            name = "Sauce Code Pro Nerd Font";
          };
        in {
          inherit serif;

          sansSerif = serif;

          monospace = {
            package = pkgs.nerd-fonts.aurulent-sans-mono;
            name = "Aurulent Sans Mono Nerd Font";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
    };
  }

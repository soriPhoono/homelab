{
  config,
  pkgs,
  ...
}: {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    fonts = let
      serif = {
        package = pkgs.nerd-fonts.sauce-code-pro;
        name = "SauceCodePro Nerd Font Propo";
      };
    in {
      inherit serif;

      sansSerif = serif;

      monospace = {
        package = pkgs.nerd-fonts.aurulent-sans-mono;
        name = "AurulentSansM Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 14;
        desktop = 12;
        terminal = 14;
      };
    };
  };

  # Dynamically generate ~/.termux/colors.properties from the Stylix color palette
  home.file.".termux/colors.properties".text = ''
    background=#${config.lib.stylix.colors.base00}
    foreground=#${config.lib.stylix.colors.base05}
    cursor=#${config.lib.stylix.colors.base05}
    color0=#${config.lib.stylix.colors.base00}
    color1=#${config.lib.stylix.colors.base08}
    color2=#${config.lib.stylix.colors.base0B}
    color3=#${config.lib.stylix.colors.base0A}
    color4=#${config.lib.stylix.colors.base0D}
    color5=#${config.lib.stylix.colors.base0E}
    color6=#${config.lib.stylix.colors.base0C}
    color7=#${config.lib.stylix.colors.base05}
    color8=#${config.lib.stylix.colors.base03}
    color9=#${config.lib.stylix.colors.base08}
    color10=#${config.lib.stylix.colors.base0B}
    color11=#${config.lib.stylix.colors.base0A}
    color12=#${config.lib.stylix.colors.base0D}
    color13=#${config.lib.stylix.colors.base0E}
    color14=#${config.lib.stylix.colors.base0C}
    color15=#${config.lib.stylix.colors.base07}
  '';
}

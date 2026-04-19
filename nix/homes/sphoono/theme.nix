{pkgs, ...}: {
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    cursor = {
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      name = "Catppuccin-Macchiato-Blue-Cursors";
      size = 24;
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      light = "Papirus";
      dark = "Papirus-Dark";
    };

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
      };
    };

    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.9;
    };
  };
}

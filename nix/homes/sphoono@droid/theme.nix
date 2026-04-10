{config, ...}: {
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

{pkgs, ...}: {
  personal.hyprland = {
    enable = true;
    monitors = [
      {
        name = "eDP-1";
        hyprConfig = "1920x1080@144Hz, 0x0, 1.25";
        primary = true;
      }
    ];
    extraSettings = {
      bind = [
        # Zephyrus G14 Specific
        # ROG Key
        ", XF86Launch1, exec, noctalia-shell ipc call settings toggle"
        # Fan Mode
        ", XF86Launch4, exec, noctalia-shell ipc call powerProfile cycle"
        # Airplane Mode
        ", XF86Launch5, exec, noctalia-shell ipc call airplaneMode toggle"
      ];

      binde = [
        # Keyboard Brightness
        ", XF86KbdBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%-"
        ", XF86KbdBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%+"
      ];
    };
  };
}

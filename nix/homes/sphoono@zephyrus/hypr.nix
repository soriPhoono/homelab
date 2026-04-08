{pkgs, ...}: {
  personal.hyprland = {
    enable = true;
    monitors = [
      "eDP-1"
    ];
  };

  wayland.windowManagers.hyprland = {
    enable = true;
    settings = {
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

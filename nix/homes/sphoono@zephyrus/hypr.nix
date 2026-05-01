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
        # Touchpad Toggle
        ", XF86TouchpadToggle, exec, ${pkgs.bash}/bin/bash -lc 'tp=\"$(hyprctl -j devices | ${pkgs.jq}/bin/jq -r \".touchpads[0].name // empty\")\"; [ -n \"$tp\" ] || exit 0; enabled=\"$(hyprctl -j devices | ${pkgs.jq}/bin/jq -r --arg tp \"$tp\" \".touchpads[] | select(.name == \\$tp) | .enabled\")\"; if [ \"$enabled\" = \"true\" ]; then hyprctl keyword \"device[$tp]:enabled\" false; else hyprctl keyword \"device[$tp]:enabled\" true; fi'"
      ];

      binde = [
        # Keyboard Brightness
        ", XF86KbdBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%-"
        ", XF86KbdBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%+"
      ];
    };
  };
}

{
  lib,
  pkgs,
  ...
}: {
  personal.hyprland = {
    enable = true;
    monitors = [
      {
        name = "eDP-1";
        primary = true;
        modeline = {
          width = 1920;
          height = 1080;
          refreshRate = 144;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.25;
      }
    ];
    extraSettings = {
      bind = [
        # Zephyrus G14 Specific
        # ROG Key
        {
          _args = [
            "XF86Launch1"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call settings toggle\")")
          ];
        }
        # Fan Mode
        {
          _args = [
            "XF86Launch4"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call powerProfile cycle\")")
          ];
        }
        # Airplane Mode
        {
          _args = [
            "XF86Launch5"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call airplaneMode toggle\")")
          ];
        }
        # Touchpad Toggle FIX THIS

        # Keyboard Brightness
        {
          _args = [
            "XF86KbdBrightnessDown"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%-\")")
          ];
        }
        {
          _args = [
            "XF86KbdBrightnessUp"
            (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%+\")")
          ];
        }
      ];
    };
  };
}

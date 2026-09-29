{ den, lib, ... }: {
  den.aspects.desktop.components.audio = { host, ... }: {
    nixos = lib.mkMerge [
      {
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          pulse.enable = true;
          jack.enable = true;
          alsa = {
            enable = true;
            enable32Bit = true;
          };
        };
      }
      (lib.mkIf (host.hasAspect den.aspects.core.hardware.bluetooth) {
        services.pipewire.wireplumber.extraConfig."10-bluetooth-auto-switch" = {
          "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = true;
          "monitor.bluez.rules" = [
            {
              matches = [
                {
                  "device.name" = "~bluez_card.*";
                }
              ];
              actions."update-props"."bluez5.auto-connect" = [
                "hfp_hf"
                "hsp_hs"
                "a2dp_sink"
              ];
            }
          ];
        };
      })
    ];
  };
}
